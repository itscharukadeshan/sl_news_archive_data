#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="../processed_data"
STATE_FILE=".fix_processed_data_state"
DAYS_BACK=14

# Allow full rescan
FULL_RESCAN=false
if [[ "${1:-}" == "--full" ]]; then
  FULL_RESCAN=true
  echo "⚠️  Running full rescan of all files..."
else
  echo "🔍 Checking only last $DAYS_BACK days of files..."
fi

# Create state file if it doesn’t exist
touch "$STATE_FILE"

# Read already checked files into an associative array
declare -A CHECKED
while IFS= read -r f; do
  [[ -n "$f" ]] && CHECKED["$f"]=1
done < "$STATE_FILE"

# Get date range
if $FULL_RESCAN; then
  FILES=$(find "$BASE_DIR" -type f -name "*.json")
else
  FILES=$(find "$BASE_DIR" -type f -name "*.json" -newermt "$(date -d "-$DAYS_BACK days" +%Y-%m-%d)")
fi

declare -a FIXED_FILES=()
declare -a SKIPPED_FILES=()

for f in $FILES; do
  # Skip if already checked
  if [[ -n "${CHECKED["$f"]+x}" ]]; then
    SKIPPED_FILES+=("$f")
    continue
  fi

  filename=$(basename "$f")
  # Extract date from name (e.g., archive-2024-10-29-17-35-all.json → 2024-10-29)
  if [[ "$filename" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    file_date="${BASH_REMATCH[1]}"
    correct_dir="$BASE_DIR/$file_date"
    correct_path="$correct_dir/$filename"

    if [[ "$f" != "$correct_path" ]]; then
      mkdir -p "$correct_dir"
      echo "📦 Moving: $f → $correct_path"
      mv "$f" "$correct_path"
      FIXED_FILES+=("$correct_path")
    fi
  else
    echo "⚠️  Skipping file with no valid date: $f"
  fi

  # Mark as checked
  echo "$correct_path" >> "$STATE_FILE"
done

echo
echo "✅ Done!"
echo "Fixed: ${#FIXED_FILES[@]} files"
echo "Skipped (already checked): ${#SKIPPED_FILES[@]} files"
