#include "vfs.h"

#include <stdlib.h>
#include <string.h>

#include "log.h"


/* ============================================================
 * Hash table sizing (unchanged)
 * ============================================================ */
#define VFS__PO2_1(x)    ((x) | ((x) >> 1))
#define VFS__PO2_2(x)    (VFS__PO2_1(x) | (VFS__PO2_1(x) >> 2))
#define VFS__PO2_4(x)    (VFS__PO2_2(x) | (VFS__PO2_2(x) >> 4))
#define VFS__PO2_8(x)    (VFS__PO2_4(x) | (VFS__PO2_4(x) >> 8))
#define VFS__PO2_16(x)   (VFS__PO2_8(x) | (VFS__PO2_8(x) >> 16))
#define VFS_NEXT_POW2(x) (VFS__PO2_16((x) - 1) + 1)

#define VFS_HASH_CAP VFS_NEXT_POW2(VFS_MAX_FILES * 2)

/* ============================================================
 * Static hash table
 * ============================================================ */
static const vfs_entry *slots[VFS_HASH_CAP];

/* ============================================================
 * Initialisation (now uses fnv1a_data from the header)
 * ============================================================ */
void vfs_hash_init(void)
{
	memset(slots, 0, sizeof(slots));

	size_t inserted = 0;
	for (size_t i = 0; __G_vfs_table[i].file_path != NULL; ++i) {
		const vfs_entry *entry = &__G_vfs_table[i];

		if (entry->file_len > 0 && entry->file_start != NULL) {
			((vfs_entry *) entry)->content_hash = fnv1a_data(entry->file_start, entry->file_len);
		}

		if (inserted >= VFS_HASH_CAP) {
			LOG_FATAL("vfs_hash: %zu embedded files exceed VFS_HASH_CAP=%d; "
			          "raise VFS_MAX_FILES in vfs.h",
			          inserted + 1,
			          VFS_HASH_CAP);
		}

		uint32_t idx    = fnv1a_str(entry->file_path) & (VFS_HASH_CAP - 1);
		size_t   probes = 0;
		while (slots[idx] != NULL) {
			idx = (idx + 1) & (VFS_HASH_CAP - 1);
			++probes;
			if (probes >= VFS_HASH_CAP) {
				LOG_FATAL("vfs_hash: hash table full while inserting \"%s\"; "
				          "raise VFS_MAX_FILES in vfs.h",
				          entry->file_path);
			}
		}
		slots[idx] = entry;
		LOG_TRACE("vfs_hash: inserted \"%s\" at slot %u (%zu probes)",
		          entry->file_path,
		          idx,
		          probes);
		++inserted;
	}

	if (inserted * 2 >= VFS_HASH_CAP) {
		LOG_WARN("vfs_hash: load factor at or above 50%% (%zu files in %d slots); "
		         "consider raising VFS_MAX_FILES for better lookup performance",
		         inserted,
		         VFS_HASH_CAP);
	}

	LOG_TRACE("vfs_hash: initialized with %zu files in %d slots (load factor %.0f%%)",
	          inserted,
	          VFS_HASH_CAP,
	          (double) inserted * 100.0 / VFS_HASH_CAP);
}

/* ============================================================
 * Lookup (unchanged)
 * ============================================================ */
const vfs_entry *vfs_lookup(const char *path)
{
	uint32_t idx = fnv1a_str(path) & (VFS_HASH_CAP - 1);
	for (size_t i = 0; i < VFS_HASH_CAP; ++i) {
		const vfs_entry *e = slots[idx];
		if (e == NULL) {
			LOG_TRACE("vfs_hash: lookup \"%s\" -> miss (%zu probes)", path, i);
			return NULL;
		}
		if (strcmp(e->file_path, path) == 0) {
			LOG_TRACE("vfs_hash: lookup \"%s\" -> hit (%zu probes)", path, i);
			return e;
		}
		idx = (idx + 1) & (VFS_HASH_CAP - 1);
	}

	LOG_DEBUG("vfs_hash: lookup \"%s\" -> miss (table exhausted)", path);

	return NULL;
}
