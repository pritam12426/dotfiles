#ifndef _CONFIG_ARRAY_H_
#define _CONFIG_ARRAY_H_

#include <stddef.h>
#include <stdbool.h>

#include "config.h"

/* Upper bound for all config-related arrays.
 * Increase this if you add more entries to G_all_configs[]. */
#define MAX_CONFIGS 64

/* Defined in config_array.c */
extern Config_entity G_all_configs[];
extern size_t        G_all_configs_len;

/* Populated by validate_config() — defined in config.c */
extern Config_entity *G_all_valid_configs[MAX_CONFIGS];
extern char          *G_all_valid_configs_target[MAX_CONFIGS];
extern size_t         G_all_valid_len;

#endif  // _CONFIG_ARRAY_H_
