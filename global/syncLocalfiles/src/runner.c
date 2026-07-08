#include "runner.h"
#include "log.h"
#include "project_config.h"

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

/*
 * Maximum number of argv slots for the rclone command we build.
 * Generous upper bound: base args + optional flags, all statically bounded.
 */
#define MAX_RCLONE_ARGS 32

int run_rclone_IPC(const Config_entity *entity, bool dry_run, const char *bwlimit)
{
	if (!entity) {
		LOG_ERROR("run_rclone_IPC: entity is NULL");
		return -1;
	}

	LOG_INFO("Preparing rclone %s for '%s'", entity->mode, entity->target_name);
	LOG_DEBUG("  local  : %s", entity->local_path);
	LOG_DEBUG("  remote : %s", entity->remote_location);

	/* ----------------------------------------------------------------
	 * Build argv[]
	 *   rclone sync <src> <dst>
	 *     [--dry-run]
	 *     [--bwlimit <limit>]
	 *     [--checksum]
	 *     [--delete-during]        (when delete_on_remote is set)
	 *     [--exclude-from <file>]  (when exclude_file_pattern is set)
	 *     [--progress]
	 *     [RCLONE_OPT ...]         (global extra opts from project_config.h)
	 * ---------------------------------------------------------------- */
	const char *argv[MAX_RCLONE_ARGS];
	int         argc = 0;

	argv[argc++] = "rclone";

	/* Append any global extra rclone options from project_config.h.
	 * RCLONE_OPT is a string like "--transfers 4 --retries 3"; we split on
	 * spaces with strtok so each token becomes its own argv element. */
	static char rclone_opt_buf[500];  /* static: persists across the execvp */
	if (RCLONE_OPT && RCLONE_OPT[0] != '\0') {
		strncpy(rclone_opt_buf, RCLONE_OPT, sizeof(rclone_opt_buf) - 1);
		rclone_opt_buf[sizeof(rclone_opt_buf) - 1] = '\0';
		char *tok = strtok(rclone_opt_buf, " ");
		while (tok && argc < MAX_RCLONE_ARGS - 1) {
			argv[argc++] = tok;
			tok = strtok(NULL, " ");
		}
	}

	argv[argc++] = entity->mode; // FIXME: this should be taken fum the config
	argv[argc++] = entity->local_path;
	argv[argc++] = entity->remote_location;

	if (dry_run) {
		argv[argc++] = "--dry-run";
		LOG_INFO("  dry-run mode enabled");
	}

	/* CLI --bwlimit overrides the per-entity value */
	const char *effective_bwlimit = bwlimit ? bwlimit : entity->bwlimit;
	if (effective_bwlimit) {
		argv[argc++] = "--bwlimit";
		argv[argc++] = effective_bwlimit;
		LOG_DEBUG("  bwlimit: %s", effective_bwlimit);
	}

	if (entity->checksum) {
		argv[argc++] = "--checksum";
		LOG_DEBUG("  checksum enabled");
	}

	if (entity->delete_on_remote) {
		argv[argc++] = "--delete-during";
		LOG_DEBUG("  delete-during enabled");
	}

	if (entity->exclude_file_pattern) {
		argv[argc++] = "--exclude-from";
		argv[argc++] = entity->exclude_file_pattern;
		LOG_DEBUG("  exclude-from: %s", entity->exclude_file_pattern);
	}

	// argv[argc++] = "--progress";

	argv[argc] = NULL;  /* execvp sentinel */

	/* ----------------------------------------------------------------
	 * Log the full command at DEBUG level
	 * ---------------------------------------------------------------- */
	{
		char cmd_buf[1024] = {0};
		size_t pos = 0;
		for (int i = 0; i < argc && pos < sizeof(cmd_buf) - 2; i++) {
			if (i > 0) cmd_buf[pos++] = ' ';
			size_t len = strlen(argv[i]);
			if (pos + len >= sizeof(cmd_buf) - 1) break;
			memcpy(cmd_buf + pos, argv[i], len);
			pos += len;
		}
		cmd_buf[pos] = '\0';
		LOG_DEBUG("Executing: %s", cmd_buf);
	}

	/* ----------------------------------------------------------------
	 * fork + execvp
	 * ---------------------------------------------------------------- */
	pid_t pid = fork();
	if (pid < 0) {
		LOG_ERROR("fork() failed for '%s'", entity->target_name);
		return -1;
	}

	if (pid == 0) {
		/* Child: replace image with rclone */
		putc('\n', stderr);
		execvp("rclone", (char *const *)argv);
		/* execvp returns only on error */
		perror("execvp(rclone)");
		_exit(127);
	}

	/* Parent: wait for child */
	int status = 0;
	if (waitpid(pid, &status, 0) < 0) {
		LOG_ERROR("waitpid() failed for '%s'", entity->target_name);
		return -1;
	}

	int exit_code = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
	if (exit_code == 0) {
		LOG_INFO("rclone sync for '%s' completed successfully", entity->target_name);
	} else {
		LOG_ERROR("rclone sync for '%s' failed (exit code %d)",
		          entity->target_name, exit_code);
	}

	return exit_code;
}
