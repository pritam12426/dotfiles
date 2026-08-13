#ifndef _VFS__H_
#define _VFS__H_


#include <stddef.h>
#include <stdint.h>

/* ============================================================
 * Configuration
 * ============================================================ */
#ifndef VFS_MAX_FILES
#define VFS_MAX_FILES 20 // set this to at least the number of embedded files
#endif

/* ============================================================
 * FNV‑1a hash (public, inline, header‑only)
 * ============================================================ */
static inline uint32_t fnv1a_str(const char *s)
{
	uint32_t h = 2166136261u;
	for (; *s; ++s) {
		h ^= (unsigned char) *s;
		h *= 16777619u;
	}
	return h;
}

static inline uint32_t fnv1a_data(const unsigned char *data, size_t len)
{
	uint32_t h = 2166136261u;
	for (size_t i = 0; i < len; ++i) {
		h ^= data[i];
		h *= 16777619u;
	}
	return h;
}

/* ============================================================
 * Data structures & public API
 * ============================================================ */
typedef struct {
	const char          *file_path;
	const unsigned char *file_start;
	const size_t         file_len;
	uint32_t             content_hash;
} vfs_entry;

extern vfs_entry __G_vfs_table[];

void vfs_hash_init(void);
const vfs_entry *vfs_lookup(const char *path);


#endif  // _VFS__H_
