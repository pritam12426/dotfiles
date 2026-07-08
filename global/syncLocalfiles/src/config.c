#include <stddef.h>
#include <stdio.h>
#include <sys/stat.h>   /* stat(), S_ISDIR, S_ISREG */
#include <string.h>

#include "config.h"
#include "config_array.h"
#include "log.h"

/* Populated by validate_config() */
Config_entity *G_all_valid_configs[MAX_CONFIGS];
char          *G_all_valid_configs_target[MAX_CONFIGS];
size_t         G_all_valid_len = 0;    /* was wrongly "size_t *" before */

/* ------------------------------------------------------------------ */
/* Internal helpers                                                     */
/* ------------------------------------------------------------------ */

/* Returns the Entity_type for path, or ENTITY_TYPE_UNKNOWN on error. */
static Entity_type detect_type(const char *path)
{
	struct stat st;
	if (stat(path, &st) != 0)
		return ENTITY_TYPE_UNKNOWN;

	if (S_ISDIR(st.st_mode))
		return ENTITY_TYPE_DIRECTORY;
	if (S_ISREG(st.st_mode))
		return ENTITY_TYPE_REGULAR_FILE;

	return ENTITY_TYPE_UNKNOWN;
}

/* Returns true if path exists (regular file or directory). */
static bool path_exists(const char *path)
{
	struct stat st;
	return stat(path, &st) == 0;
}

/* ------------------------------------------------------------------ */
/* validate_config                                                      */
/* ------------------------------------------------------------------ */
void validate_config(void)
{
	G_all_valid_len = 0;

	LOG_DEBUG("Starting config validation (%zu entries)\n", G_all_configs_len);

	for (size_t i = 0; i < G_all_configs_len; i++) {
		Config_entity *e = &G_all_configs[i];

		/* Skip completely empty sentinel entries (target_name is NULL). */
		if (!e->target_name || e->target_name[0] == '\0') {
			LOG_DEBUG("Entry %zu: empty sentinel — skipping", i);
			continue;
		}

		LOG_DEBUG("Validating entry %zu: '%s'", i, e->target_name);

		/* --- local_path must exist ----------------------------------- */
		if (!e->local_path) {
			LOG_WARN("'%s': local_path is NULL — skipping", e->target_name);
			continue;
		}

		Entity_type t = detect_type(e->local_path);
		if (t == ENTITY_TYPE_UNKNOWN) {
			LOG_WARN("'%s': local_path '%s' does not exist or is not a "
			         "regular file/directory — skipping",
			         e->target_name, e->local_path);
			continue;
		}

		e->_type = t;
		LOG_DEBUG("'%s': local_path '%s' type=%s",
		          e->target_name, e->local_path,
		          (t == ENTITY_TYPE_DIRECTORY) ? "directory" : "file");

		/* --- remote_location must be set ----------------------------- */
		if (!e->remote_location || e->remote_location[0] == '\0') {
			LOG_WARN("'%s': remote_location is NULL or empty — skipping",
			         e->target_name);
			continue;
		}

		/* --- exclude_file_pattern: if set, the file must exist ------- */
		if (e->exclude_file_pattern) {
			if (!path_exists(e->exclude_file_pattern)) {
				LOG_WARN("'%s': exclude_file_pattern '%s' does not exist — skipping",
				         e->target_name, e->exclude_file_pattern);
				continue;
			}
			LOG_DEBUG("'%s': exclude_file_pattern '%s' OK",
			          e->target_name, e->exclude_file_pattern);
		}

		/* --- All checks passed; register this entry ------------------ */
		G_all_valid_configs[G_all_valid_len]        = e;
		G_all_valid_configs_target[G_all_valid_len] = e->target_name;
		G_all_valid_len++;

		LOG_DEBUG("Config '%s' validated OK (remote: %s)",
		         e->target_name, e->remote_location);
	}

	LOG_INFO("Config validation complete: %zu/%zu entries valid",
	         G_all_valid_len, G_all_configs_len);
}

/* ------------------------------------------------------------------ */
/* Listing helpers                                                       */
/* ------------------------------------------------------------------ */

void print_config(void)
{
	if (G_all_valid_len == 0) {
		printf("No valid sync targets found.\n");
		return;
	}

	printf("Sync targets (%zu):\n", G_all_valid_len);
	for (size_t i = 0; i < G_all_valid_len; i++) {
		Config_entity *e = G_all_valid_configs[i];
		printf("  [%zu] %s MODE=(%s) '%s' \n", i, e->target_name, e->mode, e->description);
	}
}

void print_config_detailed(void)
{
	if (G_all_valid_len == 0) {
		printf("No valid sync targets found.\n");
		return;
	}

	printf("Sync targets (%zu):\n\n", G_all_valid_len);
	for (size_t i = 0; i < G_all_valid_len; i++) {
		Config_entity *e = G_all_valid_configs[i];
		const char *type_str =
			(e->_type == ENTITY_TYPE_DIRECTORY)    ? "directory" :
			(e->_type == ENTITY_TYPE_REGULAR_FILE) ? "file"      : "unknown";

		printf("  [%zu] %s\n", i, e->target_name);
		if (e->description)
			printf("       description    : %s\n", e->description);
		printf(    "       type           : %s\n", type_str);
		printf(    "       local_path     : %s\n", e->local_path);
		printf(    "       remote         : %s\n", e->remote_location);
		printf(    "       delete_remote  : %s\n", e->delete_on_remote ? "yes" : "no");
		printf(    "       checksum       : %s\n", e->checksum          ? "yes" : "no");
		if (e->bwlimit)
			printf("       bwlimit        : %s\n", e->bwlimit);
		if (e->exclude_file_pattern)
			printf("       exclude_file   : %s\n", e->exclude_file_pattern);
		printf("\n");
	}
}
