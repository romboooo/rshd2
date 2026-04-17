set -e
DATE=$(date +%Y-%m-%d-%H-%M-%S)
TEMP_DIR="/tmp/backup.$DATE"
mkdir -p "$TEMP_DIR"

pg_basebackup \
-h "127.0.0.1" \
-D $TEMP_DIR \
-F tar \
-p 9867 \
-U "postgres2" \
-P \
-z \
-v 

ssh postgres1@pg104 "mkdir -p /var/db/postgres1/backup/full/$DATE"

scp -r "$TEMP_DIR"/* postgres1@pg104:/var/db/postgres1/backup/full/$DATE

mkdir -p /var/db/postgres2/backup/full/$DATE
cp -r "$TEMP_DIR"/* "/var/db/postgres2/backup/full/$DATE/"
rm -rf "$TEMP_DIR"

echo "ok!"

