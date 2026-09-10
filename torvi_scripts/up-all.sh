#brings all containers made in home up nicely
#!/bin/bash
for d in */; do
  if [ -f "$d/docker-compose.yml" ] || [ -f "$d/compose.yml" ]; then
    echo "=== $d ==="
    (cd "$d" && docker compose up -d)
  fi
done
