#!/bin/bash

# Paths
UPLOAD_SRC="/home/chris/immich-uploads/"
UPLOAD_DEST="/mnt/data2/immich-backup/uploads"
DB_CONTAINER="immich_postgres"
DB_USER="postgres"
DB_NAME="immich"
DB_DEST="/mnt/data2/immich-backup/db_dumps"
LOGDIR="/mnt/data1/immich_logs"
LOGBASE="${LOGDIR}/immich-backup.log"

# Ensure dirs exist
mkdir -p "$LOGDIR" "$DB_DEST" "$UPLOAD_DEST"

# Rotate logs (keep 7 days)
for i in {6..1}; do
    if [ -f "${LOGBASE}.${i}" ]; then
        mv "${LOGBASE}.${i}" "${LOGBASE}.$((i+1))"
    fi
done
[ -f "$LOGBASE" ] && mv "$LOGBASE" "${LOGBASE}.1"

LOGFILE="$LOGBASE"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] Starting Immich backup..." >> "$LOGFILE"

# 1. Backup uploads
rsync -avh --delete --no-times --no-perms --no-group "$UPLOAD_SRC" "$UPLOAD_DEST" >> "$LOGFILE" 2>&1
UPLOAD_STATUS=$?

# 2. Backup Postgres database (dump to SQL file with timestamp)
DB_DUMP_FILE="${DB_DEST}/immich-db-$(date +%F_%H-%M-%S).sql.gz"
docker exec -t $DB_CONTAINER pg_dump -U $DB_USER $DB_NAME | gzip > "$DB_DUMP_FILE" 2>>"$LOGFILE"
DB_STATUS=$?

# 3. Keep only last 7 dumps
ls -1t ${DB_DEST}/immich-db-*.sql.gz | tail -n +8 | xargs -r rm --

# 4. Log result
if [ $UPLOAD_STATUS -eq 0 ] && [ $DB_STATUS -eq 0 ]; then
    echo "[$TIMESTAMP] Backup completed successfully." >> "$LOGFILE"
else
    echo "[$TIMESTAMP] Backup FAILED (uploads=$UPLOAD_STATUS, db=$DB_STATUS)." >> "$LOGFILE"
fi

