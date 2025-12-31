.mode box
.open "/Users/pritam/.local/share/aria2/aria2_downloads.sqlite3"

SELECT
    gid,
    (
        CASE
            strftime('%w', datetime(date, 'unixepoch', 'localtime'))
            WHEN '0' THEN 'SUN'
            WHEN '1' THEN 'MON'
            WHEN '2' THEN 'TUE'
            WHEN '3' THEN 'WED'
            WHEN '4' THEN 'THU'
            WHEN '5' THEN 'FRI'
            WHEN '6' THEN 'SAT'
        END
    ) || ' ' || (
        CASE
            strftime('%m', datetime(date, 'unixepoch', 'localtime'))
            WHEN '01' THEN 'Jan'
            WHEN '02' THEN 'Feb'
            WHEN '03' THEN 'Mar'
            WHEN '04' THEN 'Apr'
            WHEN '05' THEN 'May'
            WHEN '06' THEN 'Jun'
            WHEN '07' THEN 'Jul'
            WHEN '08' THEN 'Aug'
            WHEN '09' THEN 'Sep'
            WHEN '10' THEN 'Oct'
            WHEN '11' THEN 'Nov'
            WHEN '12' THEN 'Dec'
        END
    ) || '-' || strftime(
        '%d-%Y %I:%M:%S %p',
        datetime(date, 'unixepoch', 'localtime')
    ) AS date,
    -- total_files,
    CASE
        WHEN size_bytes < 1024 THEN size_bytes || ' B'
        WHEN size_bytes < 1024 * 1024 THEN ROUND(size_bytes / 1024.0, 2) || ' KB'
        WHEN size_bytes < 1024 * 1024 * 1024 THEN ROUND(size_bytes / 1024.0 / 1024.0, 2) || ' MB'
        WHEN size_bytes < 1024 * 1024 * 1024 * 1024 THEN ROUND(size_bytes / 1024.0 / 1024.0 / 1024.0, 2) || ' GB'
        ELSE ROUND(
            size_bytes / 1024.0 / 1024.0 / 1024.0 / 1024.0,
            2
        ) || ' TB'
    END AS size_human,
    base_name,
    path
FROM
    DOWNLOAD_HISTORY
ORDER BY
    date DESC;
