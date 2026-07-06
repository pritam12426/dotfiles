// cc pathenv.c -o ~/.local/bin/envinspector && strip ~/.local/bin/envinspector && envinspector

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define COLOR_GREEN   "\x1b[32m"
#define COLOR_RED     "\x1b[31m"
#define COLOR_YELLOW  "\x1b[33m"
#define COLOR_BLUE    "\x1b[34m"
#define COLOR_MAGENTA "\x1b[35m"
#define COLOR_CYAN    "\x1b[36m"
#define COLOR_RESET   "\x1b[0m"

static void print_help_mess(void);
static void print_var(const char *var_name);
static void print_summary(size_t path_count);

int main(int argc, char *argv[])
{

	if ((argc == 2) && strcmp(argv[1], "--help") == 0) {
		print_help_mess();
		return 0;
	}

	if (argc == 1) {
		// No arguments: use ENVPATH_VARS
		const char *env_list = getenv("ENVPATH_VARS");
		if (env_list == NULL) {
			fprintf(stderr, COLOR_RED "ERROR:" COLOR_RESET " ENVPATH_VARS is not set and no variables were specified.\n");
			fprintf(stderr, "Usage: %s [VAR1 [VAR2 ...]]\n", argv[0]);
			return 1;
		}

		char *copy = strdup(env_list);
		if (copy == NULL) {
			perror("strdup");
			return 1;
		}

		char *token = strtok(copy, ";");
		while (token != NULL) {
			print_var(token);
			token = strtok(NULL, ";");
		}
		free(copy);
	} else {
		// Variables passed as command-line arguments
		for (int i = 1; i < argc; i++) {
			print_var(argv[i]);
		}
	}

	return 0;
}

static void print_var(const char *var_name)
{
	const char *value = getenv(var_name);
	if (value == NULL) {
		printf(COLOR_RED " [NULL]" COLOR_RESET " $%s\n\n", var_name);
		return;
	}

	printf(COLOR_GREEN "=== " COLOR_RESET "$%s" COLOR_GREEN " ===\n" COLOR_RESET, var_name);

	size_t      path_count = 0;
	const char *p          = value;

	while (*p) {
		// Skip empty entries (e.g. trailing or double colons)
		while (*p == ':')
			p++;

		if (*p == '\0')
			break;

		path_count++;

		// Print path until ':' or end
		while (*p && *p != ':') {
			putchar(*p);
			p++;
		}

		putchar('\n');
	}

	print_summary(path_count);
}

static void print_summary(size_t path_count)
{
	if (path_count == 0) {
		printf(COLOR_YELLOW " Summary:" COLOR_RESET " No paths found.\n\n");
	} else {
		printf(COLOR_YELLOW " Summary:" COLOR_MAGENTA " %zu distinct path%s.\n\n" COLOR_RESET,
		       path_count,
		       path_count == 1 ? "" : "s");
	}
}

static void print_help_mess(void) {
	fprintf(stderr, "Usage: envinspector [--help] [VAR1 [VAR2 ...]]\n\n");
	puts("Positional arguments:");
	puts("  VAR1 [VAR2 ...]  Variables to inspect (default: ENVPATH_VARS env)\n");
	puts("Options:");
	puts("  --help          Display this help message");
}
