#include "command_line.h"

Command_line_options G_Args = {
	.print_request = false,
	.dir           = ".",
	.browser       = NULL,
	.host          = "localhost",
	.log_file      = NULL,
	.log_level     = LOG_LEVEL_INFO,
};
