#!/bin/bash

# Set where the Markdown files should go
OUTPUT_DIR=~/wiki-docker-ymls
mkdir -p "$OUTPUT_DIR"

# Find all docker-compose.yml files across BOTH stack roots (/home/chris and /mnt),
# bounded to a sane depth and pruning network mounts / backup / vcs dirs so the scan
# does not hang on the CIFS NAS mount or descend into bulk data.
find /home/chris /mnt -maxdepth 4 \
  \( -path '*/nas4-immich-backup/*' -o -path '*/oldstuff/*' -o -path '*/.git/*' \) -prune -o \
  -type f -name "docker-compose.yml" -print 2>/dev/null | while read -r compose; do
  dir=$(dirname "$compose")
  name=$(basename "$dir")
  md_file="$OUTPUT_DIR/$name.md"

  echo "📄 Creating $md_file"

  {
    echo "# $name"
    echo
    echo "## Docker Compose"
    echo '```yaml'
    cat "$compose"
    echo '```'

    # NOTE: .env contents are deliberately NOT included — they hold secrets and must
    # never be written into generated docs (see CLAUDE.md). List the .env path only.
    if [[ -f "$dir/.env" ]]; then
      echo
      echo "## Environment"
      echo "_An \`.env\` file exists at \`$dir/.env\` (contents omitted — holds secrets)._"
    fi
  } > "$md_file"
done

echo "✅ All Markdown files written to: $OUTPUT_DIR"
