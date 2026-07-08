#include "config_array.h"

#include <stdbool.h>
#include <stddef.h>

#define ARRAY_LEN(X) (sizeof((X)) / sizeof(*(X)))

Config_entity G_all_configs[] = {
	{
		.target_name          = ".zshenv_config",
		.local_path           = "/Users/pritam/.zshenv",
		.remote_location      = "Gdrive:/rclone/Dhanno/zshenv",

		.exclude_file_pattern = NULL,
		.mode                 = "copy",
		.bwlimit              = NULL,
		.delete_on_remote     = false,
		.checksum             = false,
		.description          = "Configuration of Z shell",
		/* ._type assigned by validate_config() */
	},

	{
		.target_name          = "Keepassxc",
		.local_path           = "/Users/pritam/.local/share/keepassxc",
		.remote_location      = "Gdrive:/rclone/Dhanno/",

		.exclude_file_pattern = NULL,
		.mode                 = "copy",
		.bwlimit              = NULL,
		.delete_on_remote     = false,
		.checksum             = false,
		.description          = "Passwords of keepassxc",
		/* ._type assigned by validate_config() */
	},

	/* Add more entries here.  The empty sentinel below must stay last. */
	{ 0 }
};

/* Subtract 1 to exclude the empty sentinel entry. */
size_t G_all_configs_len = ARRAY_LEN(G_all_configs) - 1;
