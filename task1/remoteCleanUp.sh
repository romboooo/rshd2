find /var/db/postgres1/backup/full -maxdepth 1 -type d -name "20*" -mtime +28 -exec rm -rf {} \; -print
find /var/db/postgres1/backup/wal_archive -type f -mtime +28 -delete -print