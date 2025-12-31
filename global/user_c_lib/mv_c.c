#include <dirent.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>
#include <stdarg.h>


// ANSI color codes
#define COLOR_RESET   "\033[0m"
#define COLOR_BLACK   "\033[30m"  // Black
#define COLOR_RED     "\033[31m"  // Red
#define COLOR_GREEN   "\033[32m"  // Green
#define COLOR_YELLOW  "\033[33m"  // Yellow
#define COLOR_BLUE    "\033[34m"  // Blue
#define COLOR_MAGENTA "\033[35m"  // Magenta
#define COLOR_CYAN    "\033[36m"  // Cyan
#define COLOR_WHITE   "\033[37m"  // White


typedef enum {
    LOG_WHATAPP,
    LOG_IMAGE,
    LOG_DOC,
    LOG_DONE
} LogLevel;

const char* level_to_string(LogLevel level) {
    switch (level) {
        case LOG_WHATAPP:  return "WhatApp";
        case LOG_IMAGE:    return "Image";
        case LOG_DOC:      return "Doc";
        case LOG_DONE:     return "Done";
        default:           return "UNKNOWN";
    }
}

const char* level_to_color(LogLevel level) {
    switch (level) {
        case LOG_WHATAPP:  return COLOR_GREEN;
        case LOG_IMAGE:    return COLOR_MAGENTA;
        case LOG_DOC:      return COLOR_CYAN;
        case LOG_DONE:     return COLOR_RED;
        default:           return COLOR_RESET;
    }
}

void log_message(LogLevel level, const char *format, ...) {
    time_t t;
    struct tm *tm_info;
    char time_buf[20];

    // Get current time
    time(&t);
    tm_info = localtime(&t);
    strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S", tm_info);

    // Print timestamp + colored log level
    fprintf(stderr, "[%s] [%s%s%s] ",
            time_buf,
            level_to_color(level),      // Start color
            level_to_string(level),     // Text
            COLOR_RESET);               // Reset

    // Handle variable arguments
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);

    fprintf(stderr, "\n");
}

#define TARGET_DIRECT "/Users/pritam/Downloads/"

static char full_path[PATH_MAX] = { '\0' };

bool endsWith(const char *str, const char *suffix);
bool strStartsWtith(const char *pre, const char *str);
void createDirs(void);

int main(void) {
	chdir(TARGET_DIRECT);
	createDirs();
	DIR *dp           = NULL;
	struct dirent *ep = NULL;
	dp = opendir(".");

	if (dp != NULL) {
		while ((ep = readdir(dp)) != NULL) {
			if (ep->d_type == DT_REG) {
				if (strStartsWtith("WhatsApp", ep->d_name)) {
					snprintf(full_path, PATH_MAX, "whatsapp/%s", ep->d_name);
					log_message(LOG_WHATAPP,  ep->d_name);
					rename(ep->d_name, full_path);
				}
				else if   (endsWith(ep->d_name, ".png")  ||
				           endsWith(ep->d_name, ".jpeg") ||
				           endsWith(ep->d_name, ".heic") ||
				           endsWith(ep->d_name, ".svg")  ||
				           endsWith(ep->d_name, ".jpg")) {
					snprintf(full_path, PATH_MAX, "image/%s", ep->d_name);
					rename(ep->d_name, full_path);
					log_message(LOG_IMAGE,  ep->d_name);
				}
				else if   (endsWith(ep->d_name, ".pdf")  ||
				           endsWith(ep->d_name, ".docx") ||
				           endsWith(ep->d_name, ".doc")) {
					snprintf(full_path, PATH_MAX, "doc/%s", ep->d_name);
					rename(ep->d_name, full_path);
					log_message(LOG_IMAGE,  ep->d_name);
				}
				else if (endsWith(ep->d_name, ".pptx") ||
				         endsWith(ep->d_name, ".ppt")) {
					snprintf(full_path, PATH_MAX, "doc/ppt/%s", ep->d_name);
					rename(ep->d_name, full_path);
					log_message(LOG_DOC,  ep->d_name);
				}
			}
		}
	}
	else {
		perror("Couldn't open the directory { " TARGET_DIRECT " }");
		return -1;
	}
	log_message(LOG_DONE,  "");
	closedir(dp);
	return 0;
}

bool strStartsWtith(const char *pre, const char *str) {
	return strncmp(pre, str, strlen(pre)) == 0;
}

bool endsWith(const char *str, const char *suffix) {
	if (!str || !suffix) return 0;
	size_t lenstr    = strlen(str);
	size_t lensuffix = strlen(suffix);
	if (lensuffix > lenstr) return 0;
	return strncmp(str + lenstr - lensuffix, suffix, lensuffix) == 0;
}

void createDirs(void) {
	const char *const folders[] = { "whatsapp", "image", "doc", "doc/ppt", NULL };

	for (size_t i = 0; folders[i]; i++) {
		if (access(folders[i], F_OK) != 0) {
			mkdir(folders[i], 0755);
		}
	}
}
