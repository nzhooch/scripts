#!/bin/bash

DOWNLOAD_ROOT="/mnt/data2/dockers/qbittorrent/downloads"

# Find .rar and .zip files
find "$DOWNLOAD_ROOT" -type f \( -iname '*.rar' -o -iname '*.zip' \) | while read -r archive; do
    dir=$(dirname "$archive")
    echo "Processing: $archive"

    # Skip if we already see an .mkv or .mp4 in that folder
    if find "$dir" -maxdepth 1 \( -iname '*.mkv' -o -iname '*.mp4' \) | grep -q .; then
        echo " -> Already extracted. Skipping."
        continue
    fi

    case "$archive" in
        *.rar)
            unrar x -o+ "$archive" "$dir"
            ;;
        *.zip)
            unzip -o "$archive" -d "$dir"
            ;;
    esac
done
