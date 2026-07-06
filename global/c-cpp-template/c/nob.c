#define NOB_EXPERIMENTAL_DELETE_OLD
#define NOB_IMPLEMENTATION
#include "nob.h"

#define BUILD_DIR "build/"
#define SROUCE_DIR "src/"

#define PROJECT_VERSION       "0.1.0"
#define PROJECT_NAME          "Sample project"
#define MAIN_BINARY_NAME      "main"
#define PROJECT_HOME_PAGE     "https://github.com/pritam12426/" MAIN_BINARY_NAME
#define PROJECT_DESCRIPTION   "Small Project"

#define MAIN_FUNCTION_FILE SROUCE_DIR "main.c"
#define MAIN_BINARY_PATH BUILD_DIR MAIN_BINARY_NAME

#define C_STANDARD "c17"
const char *conf_path = BUILD_DIR "config.h";

bool nob_glob(Nob_File_Paths *paths, const char *pattern);

int main(int argc, char **argv)
{
	GO_REBUILD_URSELF(argc, argv);
	if (!nob_mkdir_if_not_exists(BUILD_DIR)) return 1;

	Cmd                cmd = {0};
	Nob_String_Builder sb  = {0};

	int exists = file_exists(conf_path);
	if (exists < 0) return 1;
	if (exists == 0) {
		nob_log(INFO, "Generating initial %s", conf_path);
		sb_append_cstr(&sb, "#ifndef _CONFIG_H_\n");
		sb_append_cstr(&sb, "#define _CONFIG_H_\n\n\n");

		sb_append_cstr(&sb, "#define PROJECT_NAME           \"" PROJECT_NAME "\"\n\n");
		sb_append_cstr(&sb, "#define MAIN_BINARY_NAME       \"" MAIN_BINARY_NAME "\"\n\n");
		sb_append_cstr(&sb, "#define PROJECT_VERSION        \"" PROJECT_VERSION "\"\n\n");
		sb_append_cstr(&sb, "#define PROJECT_HOMEPAGE_URL   \"" PROJECT_HOME_PAGE "\"\n\n");
		sb_append_cstr(&sb, "#define PROJECT_DESCRIPTION    \"" PROJECT_DESCRIPTION "\"\n");

		sb_append_cstr(&sb, "\n\n#endif  // _CONFIG_H_\n");
		if (!nob_write_entire_file(conf_path, sb.items, sb.count)) return 1;

		sb.count = 0;
		nob_log(INFO, "==================================");
		nob_log(INFO, "EDIT %s TO CONFIGURE YOUR BUILD!!!", conf_path);
		nob_log(INFO, "==================================");
	}

	// ====================== Collect all .c files ======================
	Nob_File_Paths sources = {0};
	if (!nob_glob(&sources, "*.c")) {
		nob_log(NOB_ERROR, "Failed to glob source files"); return 1;
	}

	nob_log(NOB_INFO, "Found %zu source files", sources.count);

	// ====================== Create object file paths ======================
	Nob_File_Paths objects = {0};
	for (size_t i = 0; i < sources.count; ++i) {
		const char *src      = sources.items[i];
		// e.g. src/main.c  →  build/main.o
		const char *obj_name = nob_temp_sprintf("%s.o", nob_path_name(src));
		const char *obj_path = nob_temp_sprintf("%s%s", BUILD_DIR, obj_name);
		nob_da_append(&objects, obj_path);
	}

	// ====================== Compile sources to objects (incremental) ======================
	bool any_rebuilt = false;

	for (size_t i = 0; i < sources.count; ++i) {
		const char *src = sources.items[i];
		const char *obj = objects.items[i];

		if (nob_needs_rebuild(obj, &src, 1)) {
			any_rebuilt = true;

			Nob_Cmd cmd = {0};
			nob_cmd_append(&cmd, "cc", "-Wall", "-Wextra");
			nob_cmd_append(&cmd, "-std=" C_STANDARD);
			nob_cmd_append(&cmd, "-I", "build");
			nob_cmd_append(&cmd,"-O2", "-c");
			nob_cmd_append(&cmd, src, "-o", obj);

			nob_log(NOB_INFO, "Compiling %s", src);
			if (!nob_cmd_run(&cmd)) return 1;
		}
	}

	// ====================== Link all objects into final binary  ======================
	if (any_rebuilt || nob_needs_rebuild(MAIN_BINARY_PATH, objects.items, objects.count)) {
		Nob_Cmd cmd = {0};
		nob_cmd_append(&cmd, "cc", "-o", MAIN_BINARY_PATH);
		nob_da_append_many(&cmd, objects.items, objects.count);

		// Add your libraries here
		// nob_cmd_append(&cmd, "-lraylib");

		nob_log(NOB_INFO, "Linking %s", MAIN_BINARY_NAME);
		if (!nob_cmd_run(&cmd)) return 1;
	} else {
		nob_log(NOB_INFO, "%s is up to date!", MAIN_BINARY_NAME);
	}

	return 0;
}

bool nob_glob(Nob_File_Paths *paths, const char *pattern)
{
	if (strcmp(pattern, "*.c") == 0) {
		Nob_File_Paths dir = {0};

		// Use your macro
		if (!nob_read_entire_dir(SROUCE_DIR, &dir)) {
			nob_log(NOB_ERROR, "Failed to read directory: %s", SROUCE_DIR);
			return false;
		}

		for (size_t i = 0; i < dir.count; ++i) {
			const char *name = dir.items[i];

			if (nob_sv_ends_with_cstr(nob_sv_from_cstr(name), ".c")) {
				// Store FULL path: "src/main.c"
				const char *full_path = nob_temp_sprintf("%s%s", SROUCE_DIR, name);
				nob_da_append(paths, full_path);
			}
		}
		return true;
	}

	nob_log(NOB_ERROR, "nob_glob: Pattern '%s' not supported yet", pattern);
	return false;
}
