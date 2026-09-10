#!/bin/bash

echo "🔥 Starting safe container updates (excluding Immich)..."
LOGFILE="/home/chris/docker-update-log.txt"
echo "" > "$LOGFILE"

find /home/chris -type f -name docker-compose.yml | while read -r yml; do
    stack_dir=$(dirname "$yml")

    if [[ "$stack_dir" == *immich* ]]; then
        echo "⏭️  Skipping IMMICH stack: $stack_dir"
        continue
    fi

    echo "🔄 Updating stack in: $stack_dir" | tee -a "$LOGFILE"
    cd "$stack_dir" || continue

    docker compose pull >> "$LOGFILE" 2>&1
    docker compose up -d >> "$LOGFILE" 2>&1

    echo "✅ Finished: $stack_dir" | tee -a "$LOGFILE"
    echo "-------------------------------" >> "$LOGFILE"
done

echo "🎉 All done. Check $LOGFILE for details."
