#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PROJECT_NAME    "pathCopy"
#define PROJECT_VERSION "1.1.0"

void print_full_help(void);
void print_usage(void);

bool single_path = false;

int main(int argc, char *argv[]) {
	const char *pwd = getenv("PWD");

	if (!pwd) {
		fprintf(stderr, "Error: PWD environment variable not set.\n");
		return EXIT_FAILURE;
	}

	if (argc == 1) {
		fprintf(stderr, "Error: No file, directory, or glob pattern provided.\n");
		print_usage();
		fprintf(stderr, "Try '%s --help' for more information.\n", PROJECT_NAME);
		return EXIT_FAILURE;
	}

	if (argc == 2 &&
	    (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0)) {
		print_full_help();
		return 0;
	}

	if (argc == 2 &&
	    (strcmp(argv[1], "-v") == 0 || strcmp(argv[1], "--version") == 0)) {
		printf("%s %s\n", PROJECT_NAME, PROJECT_VERSION);
		return 0;
	}

	if (argc == 2) {
		single_path = true;
	}

	for (int i = 1; i < argc; i++) {
		bool needs_quotes = false;

		for (int j = 0; argv[i][j] != '\0'; j++) {
			char c = argv[i][j];

			/* Safe characters */
			if (isalnum((unsigned char)c) || c == '_' || c == '-' || c == '+' ||
			    c == '=' || c == '.') {
				continue;
			}

			/* Any other character requires quotes */
			needs_quotes = true;
			break;
		}

		if (needs_quotes) {
			if (single_path) {
				printf("\"%s/%s\"", pwd, argv[i]);
			} else {
				printf("\"%s/%s\" ", pwd, argv[i]);
			}
		} else {
			if (single_path) {
				printf("%s/%s", pwd, argv[i]);
			} else {
				printf("%s/%s ", pwd, argv[i]);
			}
		}
	}

	return 0;
}

void print_usage(void) {
	printf("Usage: %s [OPTIONS] [PATH...]\n", PROJECT_NAME);
}

void print_full_help(void) {
	print_usage();

	puts("\nPositional arguments:");
	puts("  PATH...    File(s), directory(s), or glob pattern(s)");

	puts("\nOptions:");
	puts("  -h, --help       Display this help message");
	puts("  -v, --version    Display program version");

	puts("\nExamples:");
	puts("  pathCopy file.txt");
	puts("  pathCopy src/");
	puts("  pathCopy *.c");
	puts("  pathCopy file1 file2 dir/");
}
