#!/bin/bash

# Script to extract URLs from JSON files in all subdirectories of ../archive/
# If --regen flag is passed, it processes all available dates
# Otherwise, it only processes today's date

INPUT_PATH="../archive/"
REGEN_ALL=false

# Check for --regen flag
if [[ "$1" == "--regen" ]]; then
  REGEN_ALL=true
fi

# Clear old errors
> error_log.txt

if [ "$REGEN_ALL" = true ]; then
  echo "Regenerating URLs for all available dates in $INPUT_PATH..."
  # Loop over all articles.json files
  find "$INPUT_PATH" -type f -name "articles.json" | while read -r FILE; do
    DATE_DIR=$(basename "$(dirname "$FILE")")
    OUTPUT_DIR="../processed_data/${DATE_DIR}"
    mkdir -p "$OUTPUT_DIR"
    OUTPUT_FILE="${OUTPUT_DIR}/extracted_urls_${DATE_DIR}.txt"
    echo "Processing $FILE -> $OUTPUT_FILE"
    jq -r '.[].url' "$FILE" >> "$OUTPUT_FILE" 2>/dev/null || echo "Failed to process $FILE" >> error_log.txt
  done
else
  TODAYS_DATE=$(date +%Y-%m-%d)
  OUTPUT_DIR="../processed_data/${TODAYS_DATE}"
  OUTPUT_FILE="${OUTPUT_DIR}/extracted_urls_${TODAYS_DATE}.txt"
  echo "Extracting URLs for today's date: $TODAYS_DATE"
  echo "Output: $OUTPUT_FILE"
  mkdir -p "$OUTPUT_DIR"
  > "$OUTPUT_FILE"

  find "${INPUT_PATH}" -type f -path "*/${TODAYS_DATE}/articles.json" | while read -r FILE; do
    echo "Processing file: $FILE"
    jq -r '.[].url' "$FILE" >> "$OUTPUT_FILE" 2>/dev/null || echo "Failed to process $FILE" >> error_log.txt
  done
fi

echo "URL extraction complete."
