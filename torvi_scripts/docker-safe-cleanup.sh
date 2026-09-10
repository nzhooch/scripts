#!/bin/bash

# Location of the log file
LOGFILE="/home/chris/docker-cleanup-$(date +%Y-%m-%d).log"

echo "🧹 Starting safe Docker cleanup: $(date)" | tee -a "$LOGFILE"
echo "Log file: $LOGFILE"

# Show disk usage before
echo -e "\n📦 Docker disk usage BEFORE:" | tee -a "$LOGFILE"
docker system df | tee -a "$LOGFILE"

# Prune unused images only (safe)
echo -e "\n🗑 Removing unused images (not used by any container)..." | tee -a "$LOGFILE"
docker image prune -a --force | tee -a "$LOGFILE"

# Optional: prune unused volumes (safe, only if you want this)
# echo -e "\n💾 Removing unused volumes..." | tee -a "$LOGFILE"
# docker volume prune --force | tee -a "$LOGFILE"

# Show disk usage after
echo -e "\n📦 Docker disk usage AFTER:" | tee -a "$LOGFILE"
docker system df | tee -a "$LOGFILE"

echo -e "\n✅ Cleanup complete: $(date)" | tee -a "$LOGFILE"
