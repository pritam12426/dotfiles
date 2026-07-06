// cc mv_c.c -o $DOT_FILE/binary_exe/xxc && strip $DOT_FILE/binary_exe/xxc

#include <dirent.h>
#include <limits.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

// ANSI color codes
#define COLOR_RESET   "\033[0m"
#define COLOR_RED     "\033[31m"        // Red
#define COLOR_GREEN   "\e[1;92m"        // Green
#define COLOR_YELLOW  "\033[33m"        // Yellow
#define COLOR_BLUE    "\033[34m"        // Blue
#define COLOR_MAGENTA "\033[35m"        // Magenta
#define COLOR_CYAN    "\033[36m"        // Cyan
#define COLOR_WHITE   "\033[37m"        // White
#define COLOR_ORANGE  "\033[38;5;208m"  // Orange

typedef enum {
    LOG_WHATAPP,
    LOG_IMAGE,
    LOG_DOC,
    LOG_DONE,
    LOG_CH_DIR,
    LOG_MKDIR
} LogLevel;


const char *level_to_string(LogLevel level);
const char *level_to_color(LogLevel level);
bool endsWith(const char *str, const char *suffix);
void createDirs(bool with_whatsapp, bool dry_run);
bool strStartsWtith(const char *pre, const char *str);
void log_message(LogLevel level, const char *format, ...);

static char full_path[PATH_MAX] = { '\0' };
static bool WorkWrithWhatsApp   = false;
static bool DryRun              = false;

int main(int argc, char *argv[])
{
	if ((argc == 2) && ((strcmp(argv[1], "-h") == 0) || (strcmp(argv[1], "--help") == 0))) {
		puts("Usage: xxc [options]");
		puts("Options:");
		puts("  -h, --help      Show this help message on stdout and exit 0");
		puts("  -n, --dry-run   Dry run mode");
		return 0;
	}

	if ((argc == 2) && ((strcmp(argv[1], "-n") == 0) || (strcmp(argv[1], "--dry-run") == 0))) {
		puts("[" COLOR_CYAN "==== Mode ====" COLOR_RESET "] Dry run enabled\n");
		DryRun = true;
	}

	DIR           *dp       = NULL;
	struct dirent *ep       = NULL;
	char          *xxc_dirs = getenv("XXC_DIRS");

	if (xxc_dirs == NULL) {
		printf("[" COLOR_RED "ERROR" COLOR_RESET "] XXC_DIRS not set\n");
		return 1;
	}

	// Make a copy (important!)
	char *copy = strdup(xxc_dirs);

	char *token = strtok(copy, ";");
	while (token != NULL) {
		chdir(token);
		WorkWrithWhatsApp = (strstr(token, "/Downloads") != NULL);
		createDirs(WorkWrithWhatsApp, DryRun);
		dp = opendir(".");

		log_message(LOG_CH_DIR, "cd => '%s'", token);

		if (dp != NULL) {
			while ((ep = readdir(dp)) != NULL) {
				if (ep->d_type == DT_REG) {
					if ((WorkWrithWhatsApp) && (strStartsWtith("WhatsApp", ep->d_name))) {
						log_message(LOG_WHATAPP, ep->d_name);
						if (DryRun) continue;
						snprintf(full_path, PATH_MAX, "whatsapp/%s", ep->d_name);
						rename(ep->d_name, full_path);
					} else if (endsWith(ep->d_name, ".png")  ||
							   endsWith(ep->d_name, ".jpeg") ||
							   endsWith(ep->d_name, ".heic") ||
							   endsWith(ep->d_name, ".svg")  ||
							   endsWith(ep->d_name, ".jpg")) {
						log_message(LOG_IMAGE, ep->d_name);
						if (DryRun) continue;
						snprintf(full_path, PATH_MAX, "image/%s", ep->d_name);
						rename(ep->d_name, full_path);
					} else if (endsWith(ep->d_name, ".pdf")  ||
							   endsWith(ep->d_name, ".docx") ||
							   endsWith(ep->d_name, ".doc")) {
						log_message(LOG_DOC, ep->d_name);
						if (DryRun) continue;
						snprintf(full_path, PATH_MAX, "doc/%s", ep->d_name);
						rename(ep->d_name, full_path);
					} else if (endsWith(ep->d_name, ".pptx") ||
						       endsWith(ep->d_name, ".ppt")) {
						log_message(LOG_DOC, ep->d_name);
						if (DryRun) continue;
						snprintf(full_path, PATH_MAX, "doc/ppt/%s", ep->d_name);
						rename(ep->d_name, full_path);
					}
				}
			}
		} else {
			// perror("Couldn't open the directory { " TARGET_DIRECT " }");
			fprintf(stderr, "Couldn't open the directory { 'cd %s' }\n", token);
			return -1;
		}
		closedir(dp);
		token = strtok(NULL, ";");
	}

	log_message(LOG_DONE, "");
	free(copy);
	return 0;
}

bool strStartsWtith(const char *pre, const char *str)
{
	return strncmp(pre, str, strlen(pre)) == 0;
}

bool endsWith(const char *str, const char *suffix)
{
	if (!str || !suffix) return 0;
	size_t lenstr    = strlen(str);
	size_t lensuffix = strlen(suffix);
	if (lensuffix > lenstr) return 0;
	return strncmp(str + lenstr - lensuffix, suffix, lensuffix) == 0;
}

void createDirs(bool with_whatsapp, bool dry_run)
{
	const char *const folders[] = { "whatsapp", "image", "doc", "doc/ppt", NULL };

	for (size_t i = 0; folders[i]; i++) {
		if ((!with_whatsapp) && (strcmp(folders[i], "whatsapp") == 0)) continue;
		if (access(folders[i], F_OK) != 0) {
			if (!dry_run) mkdir(folders[i], 0755);
			log_message(LOG_MKDIR, "=> '%s'", folders[i]);
		}
	}
}

void log_message(LogLevel level, const char *format, ...)
{
	time_t     t;
	struct tm *tm_info;
	char       time_buf[20];

	// Get current time
	// time(&t);
	// tm_info = localtime(&t);
	// strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S", tm_info);

	// Print timestamp + colored log level
	fprintf(stderr,
	        "[%s%s%s] ",
	        // time_buf,
	        level_to_color(level),   // Start color
	        level_to_string(level),  // Text
	        COLOR_RESET);            // Reset

	// Handle variable arguments
	va_list args;
	va_start(args, format);
	vfprintf(stderr, format, args);
	va_end(args);

	fprintf(stderr, "\n");
}

const char *level_to_color(LogLevel level)
{
	switch (level) {
		case LOG_WHATAPP:  return COLOR_GREEN;
		case LOG_IMAGE:    return COLOR_MAGENTA;
		case LOG_DOC:      return COLOR_CYAN;
		case LOG_DONE:     return COLOR_RED;
		case LOG_MKDIR:    return COLOR_BLUE;
		case LOG_CH_DIR:   return COLOR_ORANGE;
		default:           return COLOR_RESET;
	}
}

const char *level_to_string(LogLevel level)
{
	switch (level) {
		case LOG_WHATAPP: return "WhatApp";
		case LOG_IMAGE:   return "Image";
		case LOG_DOC:     return "Doc";
		case LOG_CH_DIR:  return "Dir";
		case LOG_DONE:    return "Done";
		case LOG_MKDIR:   return "Mkdir";
		default:          return "UNKNOWN";
	}
}
