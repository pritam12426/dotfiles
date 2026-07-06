#ifndef _RUNNER_H_
#define _RUNNER_H_

#include <stdbool.h>
#include "config.h"

/*
 * run_rclone_IPC — build and exec an rclone sync/copy command for the
 * given config entry via fork+execvp (IPC = subprocess).
 *
 * Parameters:
 *   entity   : validated Config_entity to sync
 *   dry_run  : pass --dry-run to rclone when true
 *   bwlimit  : override entity->bwlimit when non-NULL (CLI --bwlimit wins)
 *
 * Returns:
 *    0  on success (rclone exited 0)
 *   -1  on fork/exec error
 *   >0  rclone exit code on rclone failure
 */
int run_rclone_IPC(const Config_entity *entity, bool dry_run, const char *bwlimit);

#endif  // _RUNNER_H_
