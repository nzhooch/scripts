#!/bin/bash
echo "Searching and starting all Docker stacks..."
sudo find /home /mnt -type f \( -name "docker-compose.yml" -o -name "compose.yml" \) \
  -execdir bash -c 'echo "Starting stack in: $(pwd)"; docker compose up -d' \;
