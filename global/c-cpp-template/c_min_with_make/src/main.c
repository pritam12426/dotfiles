#include <stdio.h>
#include <string.h>

#include "log.h"
#include "project_config.h"
#include "command_line.h"

static struct argp_option options[] = {
	{ "log-level",     'L', "LEVEL",   0, "Set log level: [off|fatal|error|warn|info|debug|trace] (default: info)" },
	{ "log-file",      'F', "FILE",    0, "Set logging file"                                                       },
	{ "print-request", 'R', 0,         0, "Log each client request and headers"                                    },
	{ "host",          'H', "HOST",    0, "Set the listener host (default: localhost)"                             },
	{ "browser",       'B', "BROWSER", 0, "Open page in this browser on startup"                                   },
	{ "dir",           'I', "DIR",     0, "Directory to serve (default: .)"                                        },

	{ 0 }
};


static error_t parse_opt(int key, char *arg, struct argp_state *state)
{
	switch (key) {
		case 'R': G_Args.print_request = true; break;
		case 'H': G_Args.host          = arg;  break;
		case 'F': G_Args.log_file      = arg;  break;
		case 'B': G_Args.browser       = arg;  break;
		case 'I': G_Args.dir           = arg;  break;
		case 'L': {
			if      (strcmp(arg, "off")   == 0) G_Args.log_level = LOG_LEVEL_OFF;
			else if (strcmp(arg, "fatal") == 0) G_Args.log_level = LOG_LEVEL_FATAL;
			else if (strcmp(arg, "error") == 0) G_Args.log_level = LOG_LEVEL_ERROR;
			else if (strcmp(arg, "warn")  == 0) G_Args.log_level = LOG_LEVEL_WARN;
			else if (strcmp(arg, "info")  == 0) G_Args.log_level = LOG_LEVEL_INFO;
			else if (strcmp(arg, "debug") == 0) G_Args.log_level = LOG_LEVEL_DEBUG;
			else if (strcmp(arg, "trace") == 0) G_Args.log_level = LOG_LEVEL_TRACE;
			else     argp_error(state, "Invalid log level: '%s'. Use: off, fatal, error, warn, info, debug, trace.", arg);
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
	log_init(G_Args.log_file, G_Args.log_level);

	if (LOG_LEVEL_IS_ENABLED(LOG_LEVEL_DEBUG)) {
		LOG_CUSTOM(LOG_LEVEL_DEBUG, false, "Command-line args: [");
		for (int i = 0; i < argc; i++) {
			fprintf(log_get_file(), "\"%s\"", argv[i]);
			if (i != argc - 1) fputs(", ", log_get_file());
		}
		fputs("]\n", log_get_file());
	}

	return 0;
}
