#ifndef _CONFIG_H_
#define _CONFIG_H_

#include <stdbool.h>

typedef struct {
	char username[128];
	char theme[4];
	int  threads;
	bool  debug;
} arg_Arguments;

static void load_config(arg_Arguments *cfg, bool verbose);

#endif /* _CONFIG_H_ */
