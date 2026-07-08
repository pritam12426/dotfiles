#ifndef _CONFIG_STRUCT_H_
#define _CONFIG_STRUCT_H_

#include <stdbool.h>

typedef enum {
	ENTITY_TYPE_UNKNOWN      = 0,
	ENTITY_TYPE_DIRECTORY    = 1,
	ENTITY_TYPE_REGULAR_FILE = 2,
} Entity_type;

typedef struct {
	char       *target_name;
	char       *local_path;
	char       *remote_location;
	char       *exclude_file_pattern;  /* path to a file containing patterns */
	char       *mode;
	char       *bwlimit;

	bool        delete_on_remote;
	bool        checksum;

	char       *description;
	Entity_type _type;  /* assigned by validate_config() */
} Config_entity;

/*
 * validate_config() walks G_all_configs[], stat()s each local_path,
 * determines _type (directory / regular file), checks that
 * exclude_file_pattern (if set) exists, then populates
 * G_all_valid_configs[] and G_all_valid_len.
 */
void validate_config(void);

/*
 * print_config() / print_config_detailed() — list helpers used by
 * the --list and --detailed CLI flags.
 */
void print_config(void);
void print_config_detailed(void);


#endif  // _CONFIG_STRUCT_H_
