#include <argp.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "log.h"
#include "project_config.h"
#include "config.h"
#include "config_array.h"
#include "runner.h"

const char *argp_program_version     = PUSH_FILE " " PUSH_FILE_VERSION;
const char *argp_program_bug_address = PUSH_FILE_HOMEPAGE_URL;

static char doc[]      = PUSH_FILE_SHORT_DESCRIPTION " - " PUSH_FILE_DESCRIPTION;
static char args_doc[] = "[TARGET(s)...]";

static struct argp_option options[] = {
    { "log-level",   'L', "LEVEL",   0, "Set log level (error|warn|info|debug), default: info" },
    { "index",       'I', "INDEX",   0, "Sync only the item at INDEX" },
    { "bwlimit",     'B', "LIMIT",   0, "Limit bandwidth (rclone --bwlimit value)" },

    { "list",        'l', 0,         0, "List valid sync targets" },
    { "detailed",    'd', 0,         0, "List valid sync targets in detail" },

    { "dry-run",     'n', 0,         0, "Show what would be synced without making changes" },
    { "only-dir",    'D', 0,         0, "Sync directories only" },
    { "only-file",   'F', 0,         0, "Sync files only" },
    { "interactive", 'i', 0,         0, "Prompt before each sync" },

    { 0 }
};

typedef struct {
	bool   list;
	bool   detailed;
	bool   dry_run;
	bool   only_dir;
	bool   only_file;
	bool   interactive;

	char  *bwlimit;
	size_t index;          /* 0 means "all" */
	bool   index_set;

	Log_level_t log_level;
} Arguments;

static Arguments G_Arguments = {
	.list        = false,
	.detailed    = false,
	.dry_run     = false,
	.only_dir    = false,
	.only_file   = false,
	.interactive = false,

	.bwlimit     = NULL,
	.index       = 0,
	.index_set   = false,

	.log_level   = LOG_LEVEL_INFO,
};

static error_t parse_opt(int key, char *arg, struct argp_state *state)
{
	Arguments *arguments = state->input;

	switch (key) {
	case 'L':
		if      (strcmp(arg, "error") == 0) log_set_level(LOG_LEVEL_ERROR);
		else if (strcmp(arg, "warn")  == 0) log_set_level(LOG_LEVEL_WARN);
		else if (strcmp(arg, "info")  == 0) log_set_level(LOG_LEVEL_INFO);
		else if (strcmp(arg, "debug") == 0) log_set_level(LOG_LEVEL_DEBUG);
		else argp_error(state, "unknown log level: '%s'", arg);
		arguments->log_level = log_get_level();
		break;

	case 'I':
		arguments->index     = (size_t)strtoull(arg, NULL, 10);
		arguments->index_set = true;
		break;

	case 'B':
		arguments->bwlimit = arg;
		break;

	case 'l':
		arguments->list = true;
		break;

	case 'd':
		arguments->detailed = true;
		break;

	case 'n':
		arguments->dry_run = true;
		break;

	case 'D':
		arguments->only_dir = true;
		break;

	case 'F':
		arguments->only_file = true;
		break;

	case 'i':
		arguments->interactive = true;
		break;

	default:
		return ARGP_ERR_UNKNOWN;
	}

	return 0;
}

static struct argp argp = {
	.options  = options,
	.parser   = parse_opt,
	.doc      = doc,
	.args_doc = args_doc,
};

/* ------------------------------------------------------------------ */
/* Helpers                                                              */
/* ------------------------------------------------------------------ */

/* Ask the user "Sync <name>? [y/N]" and return true if they say yes. */
static bool prompt_yes(const char *target_name)
{
	char buf[8];
	fprintf(stderr, "Sync '%s'? [y/N] ", target_name);
	fflush(stderr);
	if (!fgets(buf, sizeof(buf), stdin))
		return false;
	return (buf[0] == 'y' || buf[0] == 'Y');
}

/* Apply --only-dir / --only-file filter.  Returns true if entity should
 * be included in the sync run. */
static bool entity_passes_filter(const Config_entity *e, const Arguments *a)
{
	if (a->only_dir  && e->_type != ENTITY_TYPE_DIRECTORY)    return false;
	if (a->only_file && e->_type != ENTITY_TYPE_REGULAR_FILE) return false;
	return true;
}

/* ------------------------------------------------------------------ */
/* main                                                                 */
/* ------------------------------------------------------------------ */
int main(int argc, char *argv[])
{
	/* Parse CLI arguments first so log level is set before any logging. */
	argp_parse(&argp, argc, argv, 0, 0, &G_Arguments);

	LOG_INFO("Starting " PUSH_FILE " " PUSH_FILE_VERSION);

	/* Validate the static config array; fills G_all_valid_configs[]. */
	validate_config();

	if (G_all_valid_len == 0) {
		LOG_WARN("No valid sync targets found — nothing to do.");
		return 0;
	}

	/* --list / --detailed: just print and exit. */
	if (G_Arguments.list) {
		print_config();
		return 0;
	}
	if (G_Arguments.detailed) {
		print_config_detailed();
		return 0;
	}

	/* --index: validate the requested index. */
	if (G_Arguments.index_set) {
		if (G_Arguments.index >= G_all_valid_len) {
			LOG_ERROR("Index %zu out of range (max %zu)",
			          G_Arguments.index, G_all_valid_len - 1);
			return 1;
		}
	}

	/* Warn about conflicting filter flags. */
	if (G_Arguments.only_dir && G_Arguments.only_file)
		LOG_WARN("--only-dir and --only-file are both set — nothing will match");

	if (G_Arguments.dry_run)
		LOG_INFO("Dry-run mode: no changes will be made");

	/* ----------------------------------------------------------------
	 * Main sync loop
	 * ---------------------------------------------------------------- */
	int failures = 0;

	size_t start = G_Arguments.index_set ? G_Arguments.index : 0;
	size_t end   = G_Arguments.index_set ? G_Arguments.index + 1 : G_all_valid_len;

	for (size_t i = start; i < end; i++) {
		Config_entity *e = G_all_valid_configs[i];

		if (!entity_passes_filter(e, &G_Arguments)) {
			LOG_DEBUG("Skipping '%s' (filtered by --only-dir/--only-file)",
			          e->target_name);
			continue;
		}

		if (G_Arguments.interactive && !prompt_yes(e->target_name)) {
			LOG_INFO("Skipping '%s' (user declined)", e->target_name);
			continue;
		}

		int rc = run_rclone_IPC(e, G_Arguments.dry_run, G_Arguments.bwlimit);
		if (rc != 0) {
			failures++;
			LOG_ERROR("Sync failed for '%s' (rc=%d)", e->target_name, rc);
		}
	}

	if (failures > 0) {
		LOG_WARN("%d sync(s) failed", failures);
		return 1;
	}

	LOG_INFO("All syncs completed successfully");
	return 0;
}
