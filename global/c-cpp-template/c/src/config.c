#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <sys/syslimits.h>

#include "config.h"
#include "CmakeConfig.h"  // PROJECT_NAME

static void trim_newline(char *s)
{
	s[strcspn(s, "\r\n")] = '\0';
}

static void trim_whitespace(char *s)
{
    // Trim trailing whitespace
    char *end = s + strlen(s) - 1;
    while (end > s && isspace((unsigned char)*end)) {
        *end = '\0';
        end--;
    }

    // Trim leading whitespace
    char *start = s;
    while (isspace((unsigned char)*start)) start++;

    if (start != s) {
        memmove(s, start, strlen(start) + 1);
    }
}

static bool parse_int(const char *s, int *dest)
{
    char *endptr;
    long val = strtol(s, &endptr, 10);

    if (*endptr != '\0' || endptr == s) {
        fprintf(stderr, "Invalid integer: %s\n", s);
        return false;
    }

    *dest = (int)val;
    return true;
}

static bool parse_bool(const char *s, bool *dest)
{
    if (strcasecmp(s, "true") == 0 || strcasecmp(s, "1") == 0 ||
        strcasecmp(s, "yes") == 0 || strcasecmp(s, "on") == 0) {
        *dest = true;
        return true;
    }
    if (strcasecmp(s, "false") == 0 || strcasecmp(s, "0") == 0 ||
        strcasecmp(s, "no") == 0 || strcasecmp(s, "off") == 0) {
        *dest = false;
        return true;
    }

    fprintf(stderr, "Invalid boolean: %s\n", s);
    return false;
}

void load_config(arg_Arguments *cfg, bool verbose)
{
    char path[PATH_MAX];
    const char *home = getenv("HOME");
    if (!home) {
        fprintf(stderr, "Warning: HOME environment variable not set\n");
        return;
    }

    snprintf(path, sizeof(path), "%s/.config/" PROJECT_NAME "/config", home);

    FILE *fp = fopen(path, "r");
    if (!fp) {
        if (verbose) {
            perror("Failed to open config file");
            fprintf(stderr, "Config path: %s\n", path);
        }
        return;  // Silently fail is usually acceptable for config
    }

    if (verbose) {
        printf("Loaded config from: %s\n", path);
    }

    char line[512];
    while (fgets(line, sizeof(line), fp)) {
        trim_newline(line);
        trim_whitespace(line);

        if (line[0] == '#' || line[0] == '\0')
            continue;

        char *eq = strchr(line, '=');
        if (!eq)
            continue;

        *eq = '\0';
        char *key = line;
        char *value = eq + 1;

        trim_whitespace(key);
        trim_whitespace(value);

        if (strcmp(key, "username") == 0) {
            strncpy(cfg->username, value, sizeof(cfg->username) - 1);
            cfg->username[sizeof(cfg->username) - 1] = '\0';
        }
        else if (strcmp(key, "theme") == 0) {
            strncpy(cfg->theme, value, sizeof(cfg->theme) - 1);
            cfg->theme[sizeof(cfg->theme) - 1] = '\0';
        }
        else if (strcmp(key, "threads") == 0) {
            parse_int(value, &cfg->threads);
        }
        else if (strcmp(key, "debug") == 0) {
            parse_bool(value, &cfg->debug);
        }
        else {
            fprintf(stderr, "Unknown config key: %s\n", key);
        }
    }

    fclose(fp);
}
