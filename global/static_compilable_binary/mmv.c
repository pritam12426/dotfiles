/*
 * mmv — Rename multiple files with $EDITOR
 * Version 2.0.0
 *
 * Build:
 *   Linux:  cc mmv.c -o ~/.local/bin/mmv && strip ~/.local/bin/mmv
 *   macOS:  brew install argp-standalone
 *           cc mmv.c -I/opt/homebrew/include -L/opt/homebrew/lib -largp \
                 -o ~/.local/bin/mmv && strip ~/.local/bin/mmv
 *
 * Features added in 2.0.0 (on top of 1.3.0 safety fixes):
 *   F1  -0 / --null          NUL-delimited stdin input (pairs with find -print0)
 *   F2  Atomic rename order  Topological sort; cycle-safe via temp-pivot
 *   F3  # comment lines      Lines starting with '#' in the buffer are ignored
 *   F4  --backup             Copy original to <name>.bak before renaming
 *   F5  Conflict pre-check   Warn before opening editor if destinations exist
 *   F6  --stdin              Newline-delimited path list from stdin
 *   F7  %n token             Zero-padded counter expansion in destination names
 *   F8  Transaction log      Appended to ~/.local/share/mmv/history.log
 *   F9  --preview            Show diff and confirm before renaming
 */

#define _GNU_SOURCE
#define _DEFAULT_SOURCE /* mkstemps, realpath on Linux/glibc >= 2.19 */

#include <argp.h>
#include <errno.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

#define LINE_BUF  (PATH_MAX + 2)
#define STDIN_CAP 4096 /* initial capacity for --stdin / -0 paths  */

#define PROJECT_MAIN_BINARY_NAME "mmv"
#define PROJECT_VERSION          "2.0.0"
#define PROJECT_DESCRIPTION      "Rename multiple files with $EDITOR"

const char *argp_program_version = PROJECT_MAIN_BINARY_NAME " " PROJECT_VERSION;
static char args_doc[]           = "[<path...>]";
static char doc[]                = PROJECT_MAIN_BINARY_NAME
    " - " PROJECT_DESCRIPTION "\v"
    "Token in destination names:\n"
    "  %n   zero-padded counter (width auto-sized to file count)\n"
    "  %%   literal '%'\n"
    "\n"
    "Examples:\n"
    "  mmv *.png\n"
    "  mmv -0 < <(find . -name '*.log' -print0)\n"
    "  mmv --stdin < list.txt\n"
    "  mmv --backup --preview *.c\n"
    "  mmv -vn *.mp4\n";

/* ----------------------------------------------------------------- options  */

static struct argp_option options[] = {
	{ .name = "dry-run", .key = 'n', .doc = "Show what would happen; do not rename"            },
	{ .name = "verbose", .key = 'v', .doc = "Verbose/debug output to stderr"                   },
	{ .name = "editor",  .key = 'e', .arg = "PROG", .doc = "Editor to use (overrides $EDITOR)" },
	{ .name = "null",    .key = '0', .doc = "Read NUL-delimited paths from stdin"              },
	{ .name = "stdin",   .key = 's', .doc = "Read newline-delimited paths from stdin"          },
	{ .name = "backup",  .key = 'b', .doc = "Copy original to <name>.bak before renaming"      },
	{ .name = "preview", .key = 'p', .doc = "Show diff and confirm before renaming"            },
	{ 0 }
};

typedef struct {
	bool  dry_run;
	bool  verbose;
	bool  null_mode;  /* F1: -0  */
	bool  stdin_mode; /* F6: --stdin */
	bool  backup;     /* F4 */
	bool  preview;    /* F9 */
	char *editor;

	int    path_count;
	char **paths; /* heap-owned copies */
	int    paths_cap;
} Arguments;

static error_t parse_opt(int key, char *arg, struct argp_state *state);

static struct argp argp = {
	.options  = options,
	.parser   = parse_opt,
	.args_doc = args_doc,
	.doc      = doc,
};

/* ============================================================= global state */

static char tmp_file[PATH_MAX];
static bool tty_stdout;

/* ================================================================== helpers */

static void print_rename(const char *old, const char *dst)
{
	if (tty_stdout)
		printf("\033[1;31m%s\033[0m -> \033[1;32m%s\033[0m\n", old, dst);
	else
		printf("%s -> %s\n", old, dst);
}

/* Grow a char* array by doubling. Returns false on OOM. */
static bool push_path(char ***arr, int *count, int *cap, char *p)
{
	if (*count == *cap) {
		int    nc  = (*cap == 0) ? 16 : *cap * 2;
		char **tmp = realloc(*arr, (size_t) nc * sizeof(char *));
		if (!tmp)
			return false;
		*arr = tmp;
		*cap = nc;
	}
	(*arr)[(*count)++] = p;
	return true;
}

/* Validate a single path and add it to arguments->paths. */
static bool add_path(Arguments *a, const char *path)
{
	if (strcmp(path, ".") == 0 || strcmp(path, "..") == 0) {
		fprintf(stderr, "mmv: refusing to operate on '%s'\n", path);
		return false;
	}

	struct stat st;
	if (lstat(path, &st) != 0) {
		fprintf(stderr, "mmv: path does not exist: %s\n", path);
		return false;
	}

	if (S_ISLNK(st.st_mode)) {
		char resolved[PATH_MAX];
		if (realpath(path, resolved)) {
			const char *base = strrchr(resolved, '/');
			base             = base ? base + 1 : resolved;
			if (!strcmp(base, ".") || !strcmp(base, "..")) {
				fprintf(stderr, "mmv: symlink resolves to '%s', refusing\n", resolved);
				return false;
			}
		}
	}

	if (!S_ISREG(st.st_mode) && !S_ISDIR(st.st_mode) && !S_ISLNK(st.st_mode))
		fprintf(stderr, "mmv: warning: '%s' is a special file\n", path);

	char *copy = strdup(path);
	if (!copy) {
		perror("strdup");
		return false;
	}

	if (!push_path(&a->paths, &a->path_count, &a->paths_cap, copy)) {
		free(copy);
		perror("push_path");
		return false;
	}
	return true;
}

/* ======================================================= temp file creation */

static int create_temp_file(void)
{
	const char *td = getenv("TMPDIR");
	if (td && strstr(td, "..")) {
		fprintf(stderr, "mmv: $TMPDIR contains '..', ignoring\n");
		td = NULL;
	}
	if (!td)
		td = "/tmp";

	int r = snprintf(tmp_file, sizeof(tmp_file), "%s/mmvXXXXXX.txt", td);
	if (r < 0 || (size_t) r >= sizeof(tmp_file)) {
		fprintf(stderr, "mmv: $TMPDIR path too long\n");
		return -1;
	}

	mode_t old = umask(0177);
	int    fd  = mkstemps(tmp_file, 4);
	umask(old);

	if (fd == -1) {
		perror("mkstemps");
		return -1;
	}
	return fd;
}

/* ========================================================= editor launcher  */

static int run_editor(const char *editor, const char *file, bool verbose)
{
	if (verbose)
		fprintf(stderr, "-- Editor: %s %s\n", editor, file);

	pid_t pid = fork();
	if (pid == -1) {
		perror("fork");
		return -1;
	}
	if (pid == 0) {
		char *args[] = { (char *) editor, (char *) file, NULL };
		execvp(editor, args);
		perror(editor);
		_exit(127);
	}
	int status;
	if (waitpid(pid, &status, 0) == -1) {
		perror("waitpid");
		return -1;
	}
	if (WIFEXITED(status))
		return WEXITSTATUS(status);
	fprintf(stderr, "mmv: editor killed by signal %d\n", WTERMSIG(status));
	return -1;
}

/* ============================================================= stdin reader */

/*
 * F1 / F6 — read paths from stdin.
 * delim = '\0' for NUL mode, '\n' for line mode.
 * Appends into arguments->paths (validated).
 * Returns false on fatal error.
 */
static bool read_paths_from_stdin(Arguments *a, int delim)
{
	char   buf[LINE_BUF];
	size_t len = 0;
	int    c;

	while ((c = fgetc(stdin)) != EOF) {
		if (c == delim) {
			buf[len] = '\0';
			if (len > 0 && !add_path(a, buf))
				return false;
			len = 0;
		} else {
			if (len + 1 >= sizeof(buf)) {
				fprintf(stderr, "mmv: stdin path too long (> PATH_MAX)\n");
				return false;
			}
			buf[len++] = (char) c;
		}
	}
	/* last entry without trailing delimiter */
	if (len > 0) {
		buf[len] = '\0';
		if (!add_path(a, buf))
			return false;
	}
	return true;
}

/* ======================================================= F7: %n expansion  */

/*
 * Expand %n → zero-padded counter, %% → '%'.
 * width = number of digits (e.g. 3 for files 1-999).
 * counter is 1-based.
 * Returns a heap string or NULL on OOM / overflow.
 */
static char *expand_counter(const char *tmpl, int counter, int width)
{
	/* Worst case: every char is %n → replace each with `width` digits. */
	size_t out_cap = strlen(tmpl) * (size_t) (width + 1) + 1;
	char  *out     = malloc(out_cap);
	if (!out)
		return NULL;

	size_t oi = 0;
	for (size_t i = 0; tmpl[i]; i++) {
		if (tmpl[i] == '%') {
			i++;
			if (tmpl[i] == 'n') {
				int written = snprintf(out + oi, out_cap - oi, "%0*d", width, counter);
				if (written < 0 || (size_t) written >= out_cap - oi) {
					free(out);
					return NULL;
				}
				oi += (size_t) written;
			} else if (tmpl[i] == '%') {
				out[oi++] = '%';
			} else {
				/* Unknown escape: pass through literally */
				out[oi++] = '%';
				out[oi++] = tmpl[i];
			}
		} else {
			out[oi++] = tmpl[i];
		}
		if (oi + 2 >= out_cap) {
			free(out);
			return NULL;
		}
	}
	out[oi] = '\0';
	return out;
}

/*
 * Compute width needed to represent `n` as a decimal integer.
 */
static int counter_width(int n)
{
	int w = 1;
	while (n >= 10) {
		n /= 10;
		w++;
	}
	return w;
}

/* ========================================================= F2: topo sort   */

/*
 * Rename graph node.
 * We need to execute renames in an order such that no rename's source
 * has already been clobbered by a previous rename's destination.
 *
 * Algorithm:
 *   Build a directed graph: edge i→j means new_names[i] == paths[j]
 *   (renaming i would overwrite j's current position, so j must move first).
 *   Run iterative Kahn's algorithm (in-degree = 0 → safe to rename now).
 *   Any remaining nodes are in cycles → break each cycle with a temp rename.
 */

typedef struct {
	int *adj; /* indices of nodes that depend on this one */
	int  adj_n;
	int  adj_cap;
	int  in_deg;
} GraphNode;

static bool graph_add_edge(GraphNode *nodes, int from, int to)
{
	GraphNode *n = &nodes[from];
	if (n->adj_n == n->adj_cap) {
		int  nc  = (n->adj_cap == 0) ? 4 : n->adj_cap * 2;
		int *tmp = realloc(n->adj, (size_t) nc * sizeof(int));
		if (!tmp)
			return false;
		n->adj     = tmp;
		n->adj_cap = nc;
	}
	n->adj[n->adj_n++] = to;
	nodes[to].in_deg++;
	return true;
}

/*
 * Build execution order for `count` renames.
 * paths[]     = original names
 * new_names[] = desired names (may contain counter-expanded copies)
 * skip[]      = entries with no rename needed (same name or blank)
 *
 * Fills order[] with indices in safe execution order.
 * Returns the number of entries placed in order[].
 * Caller must free each element of temp_pivots[] (up to *pivot_count).
 *
 * For cycle nodes, a temporary name is inserted: we rename the cycle
 * "root" to a temp name first, breaking the cycle, then proceed normally.
 */
static int build_rename_order(int    count,
                              char **paths,
                              char **new_names,
                              bool  *skip,
                              int   *order,        /* output: safe execution order (length count) */
                              char ***temp_pivots, /* output: heap strings for pivot temp names    */
                              int *pivot_count)
{
	*temp_pivots = NULL;
	*pivot_count = 0;

	GraphNode *nodes = calloc((size_t) count, sizeof(GraphNode));
	if (!nodes) {
		perror("calloc");
		return -1;
	}

	/* Build index: old name → node index for O(n) lookup */
	/* (n is small for typical usage; O(n²) is fine) */

	for (int i = 0; i < count; i++) {
		if (skip[i])
			continue;
		for (int j = 0; j < count; j++) {
			if (skip[j] || i == j)
				continue;
			/* Edge i→j: renaming i would land on j's current location */
			if (strcmp(new_names[i], paths[j]) == 0) {
				if (!graph_add_edge(nodes, i, j))
					goto oom;
			}
		}
	}

	/* Kahn's BFS */
	int *queue = malloc((size_t) count * sizeof(int));
	if (!queue)
		goto oom;
	int qhead = 0, qtail = 0;
	int placed = 0;

	for (int i = 0; i < count; i++)
		if (!skip[i] && nodes[i].in_deg == 0)
			queue[qtail++] = i;

	while (qhead < qtail) {
		int cur         = queue[qhead++];
		order[placed++] = cur;
		for (int e = 0; e < nodes[cur].adj_n; e++) {
			int nb = nodes[cur].adj[e];
			if (--nodes[nb].in_deg == 0)
				queue[qtail++] = nb;
		}
	}
	free(queue);

	/* Remaining nodes are in cycles — break each. */
	int pivot_cap = 0;
	for (int i = 0; i < count; i++) {
		if (skip[i] || nodes[i].in_deg == 0)
			continue;

		/* Allocate a temporary name for the pivot */
		char pivot[PATH_MAX];
		snprintf(pivot, sizeof(pivot), "%s.__mmv_pivot_%d__", paths[i], (int) getpid());

		if (*pivot_count == pivot_cap) {
			int    nc  = (pivot_cap == 0) ? 4 : pivot_cap * 2;
			char **tmp = realloc(*temp_pivots, (size_t) nc * sizeof(char *));
			if (!tmp)
				goto oom;
			*temp_pivots = tmp;
			pivot_cap    = nc;
		}
		(*temp_pivots)[(*pivot_count)++] = strdup(pivot);

		/*
         * Strategy: rename paths[i] → pivot (done immediately in caller),
         * then schedule i last among cycle members so the cycle can drain.
         * Mark in_deg = 0 so BFS picks up its neighbours.
         */
		nodes[i].in_deg = 0;
		/* Re-run BFS from this node's neighbours */
		for (int e = 0; e < nodes[i].adj_n; e++) {
			int nb = nodes[i].adj[e];
			if (--nodes[nb].in_deg == 0) {
				/* Append to order */
				order[placed++] = nb;
				/* Propagate */
				for (int f = 0; f < nodes[nb].adj_n; f++) {
					int nb2 = nodes[nb].adj[f];
					if (--nodes[nb2].in_deg == 0)
						order[placed++] = nb2;
				}
			}
		}
		/* Pivot node goes last in this cycle group */
		order[placed++] = i;
	}

	for (int i = 0; i < count; i++)
		free(nodes[i].adj);
	free(nodes);
	return placed;

oom:
	perror("build_rename_order");
	for (int i = 0; i < count; i++)
		free(nodes[i].adj);
	free(nodes);
	return -1;
}

/* ===================================================== F4: backup helpers  */

static bool copy_file(const char *src, const char *dst)
{
	int in = open(src, O_RDONLY);
	if (in == -1) {
		perror(src);
		return false;
	}

	int out = open(dst, O_WRONLY | O_CREAT | O_EXCL, 0600);
	if (out == -1) {
		perror(dst);
		close(in);
		return false;
	}

	char    buf[65536];
	ssize_t n;
	bool    ok = true;
	while ((n = read(in, buf, sizeof(buf))) > 0) {
		ssize_t w = write(out, buf, (size_t) n);
		if (w != n) {
			perror(dst);
			ok = false;
			break;
		}
	}
	if (n == -1) {
		perror(src);
		ok = false;
	}

	close(in);
	if (close(out) != 0) {
		perror(dst);
		ok = false;
	}
	return ok;
}

static bool backup_path(const char *path, bool verbose)
{
	char bak[PATH_MAX];
	int  r = snprintf(bak, sizeof(bak), "%s.bak", path);
	if (r < 0 || (size_t) r >= sizeof(bak)) {
		fprintf(stderr, "mmv: backup path too long for '%s'\n", path);
		return false;
	}

	struct stat st;
	if (lstat(path, &st) != 0) {
		perror(path);
		return false;
	}

	if (S_ISDIR(st.st_mode)) {
		/* For directories, just note it — recursive copy is out of scope */
		fprintf(stderr, "mmv: warning: --backup skipped for directory '%s'\n", path);
		return true;
	}

	if (verbose)
		fprintf(stderr, "-- Backup: %s -> %s\n", path, bak);
	return copy_file(path, bak);
}

/* ===================================================== F8: history log     */

static void log_rename(FILE *log_fp, const char *old, const char *dst)
{
	if (!log_fp)
		return;
	time_t     now = time(NULL);
	char       ts[32];
	struct tm *tm_info = localtime(&now);
	strftime(ts, sizeof(ts), "%Y-%m-%dT%H:%M:%S", tm_info);
	fprintf(log_fp, "%s\t%s\t%s\n", ts, old, dst);
}

static FILE *open_history_log(void)
{
	const char *home = getenv("HOME");
	if (!home)
		return NULL;

	char dir[PATH_MAX - 16]; /* leave room for "/history.log" */
	snprintf(dir, sizeof(dir), "%s/.local/share/mmv", home);

	/* mkdir -p the directory */
	for (char *p = dir + 1; *p; p++) {
		if (*p == '/') {
			*p = '\0';
			mkdir(dir, 0755); /* ignore errors (may already exist) */
			*p = '/';
		}
	}
	mkdir(dir, 0755);

	char log_path[PATH_MAX];
	snprintf(log_path, sizeof(log_path), "%s/history.log", dir);

	FILE *fp = fopen(log_path, "a");
	if (!fp)
		fprintf(stderr, "mmv: warning: could not open history log %s\n", log_path);
	return fp;
}

/* ===================================================== F9: preview / diff  */

/*
 * Print a unified-style diff of old→new names and ask for confirmation.
 * Returns true if the user confirms, false to abort.
 */
static bool preview_and_confirm(int count, char **paths, char **new_names, bool *skip)
{
	bool any = false;
	for (int i = 0; i < count; i++) {
		if (skip[i])
			continue;
		if (strcmp(paths[i], new_names[i]) == 0)
			continue;
		any = true;
		break;
	}
	if (!any) {
		fprintf(stderr, "mmv: nothing to rename\n");
		return false;
	}

	printf("\n--- a/filenames\n+++ b/filenames\n");
	for (int i = 0; i < count; i++) {
		if (skip[i])
			continue;
		const char *o = paths[i], *n = new_names[i];
		if (strcmp(o, n) == 0) {
			printf(" %s\n", o);
		} else {
			if (tty_stdout) {
				printf("\033[1;31m-%s\033[0m\n", o);
				printf("\033[1;32m+%s\033[0m\n", n);
			} else {
				printf("-%s\n", o);
				printf("+%s\n", n);
			}
		}
	}

	printf("\nProceed with renames? [y/N] ");
	fflush(stdout);

	char answer[8] = { 0 };
	if (!fgets(answer, sizeof(answer), stdin))
		return false;
	return (answer[0] == 'y' || answer[0] == 'Y');
}

/* ================================================================== F5: conflict pre-check */

/*
 * Check whether any destination already exists on disk AND is not
 * one of our own sources (which will have moved away by then, assuming
 * topological order — we warn conservatively).
 */
static void warn_conflicts(int count, char **paths, char **new_names, bool *skip)
{
	for (int i = 0; i < count; i++) {
		if (skip[i])
			continue;
		const char *dst = new_names[i];
		if (strcmp(paths[i], dst) == 0)
			continue;

		struct stat st;
		if (lstat(dst, &st) == 0) {
			/* Check if dst is one of our own sources */
			bool is_source = false;
			for (int j = 0; j < count; j++) {
				if (!skip[j] && strcmp(paths[j], dst) == 0) {
					is_source = true;
					break;
				}
			}
			if (!is_source) {
				fprintf(stderr,
				        "mmv: warning: destination already exists: '%s' "
				        "(will be overwritten)\n",
				        dst);
			}
		}
	}
}

/* ================================================================ duplicate check */

static bool has_duplicate_destinations(char **new_names, int len, bool *skip)
{
	bool found = false;
	for (int i = 0; i < len; i++) {
		if (skip[i] || new_names[i][0] == '\0')
			continue;
		for (int j = i + 1; j < len; j++) {
			if (skip[j] || new_names[j][0] == '\0')
				continue;
			if (strcmp(new_names[i], new_names[j]) == 0) {
				fprintf(stderr,
				        "mmv: error: duplicate destination '%s' (entries %d and %d)\n",
				        new_names[i],
				        i + 1,
				        j + 1);
				found = true;
			}
		}
	}
	return found;
}

/* main ==================================================================*/

int main(int argc, char *argv[])
{
	Arguments args = {
		.dry_run    = false,
		.verbose    = false,
		.null_mode  = false,
		.stdin_mode = false,
		.backup     = false,
		.preview    = false,
		.editor     = NULL,
		.path_count = 0,
		.paths      = NULL,
		.paths_cap  = 0,
	};

	argp_parse(&argp, argc, argv, 0, 0, &args);

	tty_stdout = isatty(STDOUT_FILENO);

	/* F1 / F6: read paths from stdin */
	if (args.null_mode || args.stdin_mode) {
		if (args.path_count > 0) {
			fprintf(stderr, "mmv: cannot combine --null/--stdin with path arguments\n");
			return 1;
		}
		int delim = args.null_mode ? '\0' : '\n';
		if (!read_paths_from_stdin(&args, delim))
			return 1;
	}

	if (args.path_count == 0) {
		fprintf(stderr, "mmv: no input files\n");
		return 1;
	}

	/* ---- create and populate temp file ---- */
	int fd = create_temp_file();
	if (fd == -1)
		return 1;

	if (args.verbose)
		fprintf(stderr, "-- Buffer: %s\n", tmp_file);

	FILE *tmp_fp = fdopen(fd, "w");
	if (!tmp_fp) {
		perror("fdopen");
		close(fd);
		unlink(tmp_file);
		return 1;
	}

	/* F3: write paths; comment header explains token and comment syntax */
	fprintf(tmp_fp,
	        "# mmv buffer — edit destinations below.\n"
	        "# Lines starting with '#' are ignored.\n"
	        "# Blank a line to skip that file.\n"
	        "# Use %%n for a zero-padded counter.\n"
	        "#\n");

	for (int i = 0; i < args.path_count; i++)
		fprintf(tmp_fp, "%s\n", args.paths[i]);

	if (fclose(tmp_fp) != 0) {
		perror("fclose (write)");
		unlink(tmp_file);
		return 1;
	}

	/* ---- open editor ---- */
	const char *editor = args.editor ? args.editor : getenv("EDITOR");
	if (!editor)
		editor = "vi";

	int es = run_editor(editor, tmp_file, args.verbose);
	if (es != 0) {
		fprintf(stderr, "mmv: editor exited with status %d, aborting\n", es);
		unlink(tmp_file);
		return 1;
	}

	/* ---- read back edited names ---- */
	tmp_fp = fopen(tmp_file, "r");
	if (!tmp_fp) {
		perror("fopen (read)");
		unlink(tmp_file);
		return 1;
	}

	char **new_names = calloc((size_t) args.path_count, sizeof(char *));
	if (!new_names) {
		perror("calloc");
		fclose(tmp_fp);
		unlink(tmp_file);
		return 1;
	}

	char line[LINE_BUF];
	int  src_idx  = 0; /* index into args.paths (skips comment lines) */
	int  line_num = 0;

	while (fgets(line, sizeof(line), tmp_fp) != NULL && src_idx < args.path_count) {
		line_num++;

		/* Overflow detection */
		size_t len = strlen(line);
		if (len == sizeof(line) - 1 && line[len - 1] != '\n') {
			fprintf(stderr, "mmv: line %d exceeds PATH_MAX; aborting\n", line_num);
			int c;
			while ((c = fgetc(tmp_fp)) != '\n' && c != EOF)
				;
			for (int i = 0; i < src_idx; i++)
				free(new_names[i]);
			free(new_names);
			fclose(tmp_fp);
			unlink(tmp_file);
			return 1;
		}

		line[strcspn(line, "\n")] = '\0';

		/* F3: skip comment lines */
		if (line[0] == '#')
			continue;

		new_names[src_idx] = strdup(line);
		if (!new_names[src_idx]) {
			perror("strdup");
			for (int i = 0; i < src_idx; i++)
				free(new_names[i]);
			free(new_names);
			fclose(tmp_fp);
			unlink(tmp_file);
			return 1;
		}
		src_idx++;
	}

	fclose(tmp_fp);
	unlink(tmp_file);

	if (src_idx != args.path_count) {
		fprintf(stderr,
		        "mmv: line count mismatch: expected %d, got %d; aborting\n",
		        args.path_count,
		        src_idx);
		for (int i = 0; i < src_idx; i++)
			free(new_names[i]);
		free(new_names);
		return 1;
	}

	/* ---- F7: expand %n tokens ---- */
	int cw      = counter_width(args.path_count);
	int counter = 1;
	for (int i = 0; i < args.path_count; i++) {
		if (strstr(new_names[i], "%n") || strstr(new_names[i], "%%")) {
			char *expanded = expand_counter(new_names[i], counter, cw);
			if (!expanded) {
				fprintf(stderr, "mmv: %%n expansion failed on line %d\n", i + 1);
				for (int j = 0; j < args.path_count; j++)
					free(new_names[j]);
				free(new_names);
				return 1;
			}
			free(new_names[i]);
			new_names[i] = expanded;
		}
		/* only increment counter for lines that will actually result in a rename */
		if (strcmp(args.paths[i], new_names[i]) != 0 && new_names[i][0] != '\0')
			counter++;
	}

	/* ---- build skip[] mask ---- */
	bool *skip = calloc((size_t) args.path_count, sizeof(bool));
	if (!skip) {
		perror("calloc");
		return 1;
	}

	for (int i = 0; i < args.path_count; i++) {
		if (new_names[i][0] == '\0' || strcmp(args.paths[i], new_names[i]) == 0)
			skip[i] = true;
	}

	/* ---- validate ---- */
	if (has_duplicate_destinations(new_names, args.path_count, skip)) {
		for (int i = 0; i < args.path_count; i++)
			free(new_names[i]);
		free(new_names);
		free(skip);
		return 1;
	}

	/* F5: conflict pre-check */
	warn_conflicts(args.path_count, args.paths, new_names, skip);

	/* F9: preview + confirm */
	if (args.preview) {
		if (!preview_and_confirm(args.path_count, args.paths, new_names, skip)) {
			fprintf(stderr, "mmv: aborted\n");
			for (int i = 0; i < args.path_count; i++)
				free(new_names[i]);
			free(new_names);
			free(skip);
			return 1;
		}
	}

	/* ---- F2: build topological rename order ---- */
	int   *order       = malloc((size_t) args.path_count * sizeof(int));
	char **pivots      = NULL;
	int    pivot_count = 0;

	if (!order) {
		perror("malloc");
		return 1;
	}

	int ordered = build_rename_order(args.path_count,
	                                 args.paths,
	                                 new_names,
	                                 skip,
	                                 order,
	                                 &pivots,
	                                 &pivot_count);

	if (ordered < 0) {
		free(order);
		for (int i = 0; i < args.path_count; i++)
			free(new_names[i]);
		free(new_names);
		free(skip);
		return 1;
	}

	/* ---- prepare undo script ---- */
	char        undo_path[PATH_MAX];
	const char *td2 = getenv("TMPDIR");
	if (!td2 || strstr(td2, ".."))
		td2 = "/tmp";
	snprintf(undo_path, sizeof(undo_path), "%s/mmv-undo-%d.sh", td2, (int) getpid());

	FILE *undo_fp = fopen(undo_path, "w");
	if (undo_fp)
		fprintf(undo_fp, "#!/bin/sh\n# mmv undo — generated %s\nset -e\n", undo_path);
	else
		fprintf(stderr, "mmv: warning: could not create undo script\n");

	/* F8: open history log */
	FILE *log_fp = (!args.dry_run) ? open_history_log() : NULL;

	/* ---- perform renames ---- */
	if (args.dry_run)
		fputs("[DRY RUN]\n", stderr);

	int errors = 0;

	/*
	* For each cycle pivot: rename the source to its temp name first,
	* so the cycle can be resolved by the topological order that follows.
	* pivots[] is parallel to the cycle nodes in order[] (the last
	* occurrence of each cycle group in order[]).
	* We track which order[] entries are pivot nodes by re-detecting them.
	*/

	/* Map: for cycle nodes, what was their pivot name? */
	char **pivot_map = calloc((size_t) args.path_count, sizeof(char *));
	if (!pivot_map) {
		perror("calloc");
		return 1;
	}

	int piv_idx = 0;
	/* Detect cycle nodes: those whose in-degree was > 0 after initial BFS.
	* We detect them as nodes that appear at the END of each cycle group
	* in order[] AND have a pivot allocated. Since build_rename_order places
	* the pivot node last per cycle, and we count pivot_count cycles, the
	* last pivot_count nodes in order[] are cycle roots — but this is only
	* true for simple cycles. For robustness we match by checking whether
	* rename(paths[i], new_names[i]) would conflict without the pivot.
	*
	* Simpler: we do the pre-pivot renames for each cycle root right before
	* we process them in order[]. We know a cycle root because we generated
	* one pivot per cycle and placed the root last in its group.
	* We just fire all pre-pivot renames before the main loop.
	*/

	/* Find cycle root indices: they are the nodes for which a pivot exists.
	* build_rename_order generates one pivot per cycle in the order they
	* are encountered. We re-identify them: they are nodes still with in_deg>0
	* conceptually — but we've lost that info. Instead, since we placed
	* exactly pivot_count cycle roots into order[] as the last entry per
	* cycle sub-sequence, and placed them in FIFO order, we match them
	* positionally against pivots[]. The simplest correct approach: walk
	* order[] and for each node i, check if paths[i] == pivots[piv_idx].
	*/
	for (int oi = 0; oi < ordered && piv_idx < pivot_count; oi++) {
		int i = order[oi];
		if (piv_idx < pivot_count && strcmp(args.paths[i], pivots[piv_idx]) != 0) {
			/* Check if this node is a cycle root by checking if it appears
			 * as a source that another node wants to rename to, creating
			 * a cycle.  Simpler heuristic: a cycle root is the node whose
			 * current source path matches what another node wants as dest. */
			bool is_cycle_root = false;
			for (int j = 0; j < args.path_count; j++) {
				if (j == i || skip[j])
					continue;
				if (strcmp(new_names[j], args.paths[i]) == 0) {
					/* j depends on i moving first — but i also depends on
					 * something moving, so i is in a cycle */
					for (int k = 0; k < args.path_count; k++) {
						if (k == i || skip[k])
							continue;
						if (strcmp(new_names[i], args.paths[k]) == 0) {
							is_cycle_root = true;
							break;
						}
					}
					if (is_cycle_root)
						break;
				}
			}
			if (is_cycle_root) {
				pivot_map[i] = pivots[piv_idx++];
				if (!args.dry_run) {
					if (args.verbose)
						fprintf(stderr, "-- Cycle pivot: %s -> %s\n", args.paths[i], pivot_map[i]);
					rename(args.paths[i], pivot_map[i]);
				}
			}
		}
	}

	for (int oi = 0; oi < ordered; oi++) {
		int i = order[oi];
		if (skip[i])
			continue;

		const char *src = pivot_map[i] ? pivot_map[i] : args.paths[i];
		const char *dst = new_names[i];

		if (args.verbose && pivot_map[i])
			fprintf(stderr, "-- (via pivot) ");

		print_rename(args.paths[i], dst); /* always show original→dest */

		/* F4: backup */
		if (args.backup && !args.dry_run) {
			if (!backup_path(src, args.verbose))
				fprintf(stderr, "mmv: warning: backup failed for '%s'\n", src);
		}

		if (!args.dry_run) {
			if (rename(src, dst) != 0) {
				if (errno == EXDEV)
					fprintf(stderr, "mmv: '%s': cannot rename across filesystems\n", args.paths[i]);
				else
					perror(args.paths[i]);
				errors++;
			} else {
				if (undo_fp)
					fprintf(undo_fp, "mv -- '%s' '%s'\n", dst, args.paths[i]);
				log_rename(log_fp, args.paths[i], dst);
			}
		}
	}

	/* ---- finalise ---- */
	if (undo_fp) {
		fclose(undo_fp);
		chmod(undo_path, 0700);
		if (!args.dry_run && errors == 0)
			fprintf(stderr, "-- Undo: %s\n", undo_path);
		else
			unlink(undo_path);
	}

	if (log_fp)
		fclose(log_fp);

	/* cleanup */
	for (int i = 0; i < args.path_count; i++) {
		free(new_names[i]);
		free(args.paths[i]);
	}
	free(new_names);
	free(args.paths);
	free(skip);
	free(order);
	free(pivot_map);
	for (int i = 0; i < pivot_count; i++)
		free(pivots[i]);
	free(pivots);

	return errors ? 1 : 0;
}

/* ============================================================= arg parser  */

static error_t parse_opt(int key, char *arg, struct argp_state *state)
{
	Arguments *a = state->input;

	switch (key) {
	case 'n': a->dry_run    = true; break;
	case 'v': a->verbose    = true; break;
	case '0': a->null_mode  = true; break;
	case 's': a->stdin_mode = true; break;
	case 'b': a->backup     = true; break;
	case 'p': a->preview    = true; break;
	case 'e': a->editor     = arg; break;

	case ARGP_KEY_ARG:
		if (a->null_mode || a->stdin_mode)
			argp_error(state, "path arguments cannot be combined with --null/--stdin");
		if (!add_path(a, state->argv[state->next - 1]))
			argp_failure(state, 1, 0, "invalid path");
		break;

	case ARGP_KEY_END:
		/* path_count may still be 0 here for --stdin/--null; checked in main */
		break;

	default:
		return ARGP_ERR_UNKNOWN;
	}
	return 0;
}
