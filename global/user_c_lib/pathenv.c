#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_WHITE   "\x1b[97m"
#define ANSI_COLOR_RESET   "\x1b[0m"

static const char *const envName[] = { "PATH", "MANPATH", "CMAKE_PREFIX_PATH", "PKG_CONFIG_PATH", "DYLD_LIBRARY_PATH", NULL };

uint32_t print_var(const char *var);
void after_print(const uint32_t n);


int main(void) {
	for (int i =0; envName[i]; i++) {
		print_var(envName[i]);
	}
	return 0;
}

uint32_t print_var(const char *var) {
	const char *var_data = getenv(var);

	if (var_data == NULL) {
		printf(ANSI_COLOR_RED " [ NULL -> $%s ]" ANSI_COLOR_RESET "\n", var);
		return 0;
	}

	printf(ANSI_COLOR_GREEN "Printing variable: " ANSI_COLOR_RED "%s\n" ANSI_COLOR_RESET, var);

	int j = 2;
	for (int i = 0; var_data[i]; i++) {
		if (var_data[i] == ':' && var_data[i + 1] == '\0') {
			continue;
		} else if (var_data[i] == ':') {
			putchar('\n');
			j++;
			continue;
		}
		putchar(var_data[i]);
	};

	printf("\n");
	after_print(--j);
	return --j;
}

void after_print(const uint32_t n) {
	printf(ANSI_COLOR_YELLOW "    Summary: " ANSI_COLOR_MAGENTA "The variable contains " ANSI_COLOR_CYAN "%u" ANSI_COLOR_MAGENTA " distinct paths.\n\n" ANSI_COLOR_RESET, n);
}
