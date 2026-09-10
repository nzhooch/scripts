#!/bin/bash

TV="/mnt/data2/dockers/qbittorrent/downloads/tv"
MOVIES="/mnt/data2/dockers/qbittorrent/downloads/movies"

for DIR in "$TV" "$MOVIES"; do
    if [[ -d "$DIR" ]]; then
        echo "Cleaning: $DIR"
        find "$DIR" -mindepth 1 -maxdepth 1 -mtime +21 -print -exec rm -rf -- {} +
        echo "Finished: $DIR"
    else
        echo "WARNING: Directory not found: $DIR"
    fi
done

echo "Cleanup complete."
