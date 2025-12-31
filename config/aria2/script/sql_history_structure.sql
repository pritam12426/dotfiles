-- Basic table structure for aria2 download history
-- Do not modify this file directly. Use appropriate migration scripts instead.
-- Database: aria2_downloads.db

CREATE TABLE IF NOT EXISTS "DOWNLOAD_HISTORY" (
	"gid"          TEXT,
	"date"         INTEGER DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),  -- Unix timestamp
	"total_files"  INTEGER,
	"size_bytes"   INTEGER,
	"base_name"    TEXT,
	"path"         TEXT
);
