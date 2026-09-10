#!/bin/bash

# -------------------------------------------------------------------
# Script: find_docker_compose_files.sh
# Purpose: Find all Docker Compose YAMLs across known locations
# Areas searched: /home and all /mnt mounts
# Includes: spinner for eye candy
# -------------------------------------------------------------------

OUTPUT=~/all_compose_files.txt

echo -n "🔍 Searching for Docker Compose files..."

# Spinner function (cosmetic)
spin() {
  local -a marks=('|' '/' '-' '\')
  while :; do
    for m in "${marks[@]}"; do
      printf "\r🔍 Searching for Docker Compose files... %s" "$m"
      sleep 0.1
    done
  done
}

# Start spinner in background
spin & SPIN_PID=$!

# Actual search — thanks to sudoers, no password needed
sudo find /home /mnt \
  -type f \
  \( -iname "docker-compose.yml" \
     -o -iname "compose.yml" \
     -o -iname "*.docker.yml" \
     -o -iname "docker-compose.yaml" \
     -o -iname "compose.yaml" \) \
  > "$OUTPUT"

# Kill spinner
kill "$SPIN_PID" >/dev/null 2>&1
wait "$SPIN_PID" 2>/dev/null

# Final output
echo -e "\r✅ Done! Found $(wc -l < "$OUTPUT") files."
echo "📄 Output saved to: $OUTPUT"






