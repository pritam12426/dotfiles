#include <argp.h>
#include <stdio.h>
#include <string.h>

#include "log.h"
#include "project_config.h"

const char *argp_program_version     = MAIN_BINARY " " PROJECT_VERSION;
const char *argp_program_bug_address = PROJECT_HOMEPAGE_URL "/issues" "\n" AUTH_MESSAGE;
static char doc[]                    = MAIN_BINARY " - " PROJECT_SHORT_DESC;

static struct argp_option options[] = {
	{ "log-level",     'L', "LEVEL",   0, "Set log level: [error|warn|info|debug] (default: info)" },
	{ "log-file",      'F', "FILE",    0, "Set logging file"                                       },
	{ "print-request", 'R', 0,         0, "Log each client request and headers"                    },
	{ "host",          'H', "HOST",    0, "Set the listener host (default: localhost)"             },
	{ "browser",       'B', "BROWSER", 0, "Open page in this browser on startup"                   },
	{ "dir",           'I', "DIR",     0, "Directory to serve (default: .)"                        },

	{ 0 }
};

typedef struct {
	bool        print_request;
	const char *dir;
	const char *browser;
	const char *host;
	const char *log_file;

	Log_level_t log_level;
} Arguments;

static Arguments G_Arguments = {
	.print_request = false,
	.dir           = ".",
	.browser       = NULL,
	.log_file      = NULL,
	.host          = "localhost",

	.log_level     = LOG_LEVEL_INFO
};

static error_t parse_opt(int key, char *arg, struct argp_state *state)
{
	switch (key) {
		case 'R': G_Arguments.print_request = true; break;
		case 'H': G_Arguments.host          = arg;  break;
		case 'F': G_Arguments.log_file      = arg;  break;
		case 'B': G_Arguments.browser       = arg;  break;
		case 'I': G_Arguments.dir           = arg;  break;
		case 'L': {
			if      (strcmp(arg, "error") == 0) log_set_level(LOG_LEVEL_ERROR);
			else if (strcmp(arg, "warn")  == 0) log_set_level(LOG_LEVEL_WARN);
			else if (strcmp(arg, "info")  == 0) log_set_level(LOG_LEVEL_INFO);
			else if (strcmp(arg, "debug") == 0) log_set_level(LOG_LEVEL_DEBUG);
			else     argp_error(state, "Invalid log level: '%s'. Use: error, warn, info, debug.", arg);
			G_Arguments.log_level = log_get_level();
			break;
		}
		case ARGP_KEY_END: break;
		default: return ARGP_ERR_UNKNOWN;
	}
	return 0;
}

static struct argp argp = { .options = options, .parser = parse_opt, .doc = doc };

int main(int argc, char *argv[])
{
	argp_parse(&argp, argc, argv, 0, 0, 0);
	log_init(G_Arguments.log_file);

	if (log_get_level() == LOG_LEVEL_DEBUG) {
		LOG_CUSTOM(LOG_LEVEL_DEBUG, false, "Command-line args: [");
		for (int i = 0; i < argc; i++) {
			fprintf(log_get_file(), "\"%s\"", argv[i]);
			if (i != argc - 1) fputs(", ", log_get_file());
		}
		fputs("]\n", log_get_file());
	}

	return 0;
}
