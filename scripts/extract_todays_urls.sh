#!/bin/bash

# Script to extract URLs from JSON files in all subdirectories of ../archive/ for today's date

# Define base path
INPUT_PATH="../archive/"
TODAYS_DATE=$(date +%Y-%m-%d)  # Ensures format is YYYY-MM-DD
OUTPUT_FILE="../processed_data/${TODAYS_DATE}/extracted_urls_${TODAYS_DATE}.txt"

echo "Scanning directory: $INPUT_PATH for files matching */${TODAYS_DATE}/articles.json"
echo "Extracted URLs will be saved to: $OUTPUT_FILE"

# Ensure the output file is cleared before use
> "$OUTPUT_FILE"

# Check if input directory exists
if [ ! -d "$INPUT_PATH" ]; then
    echo "Error: Directory $INPUT_PATH does not exist."
    exit 1
fi

# Recursively find all JSON files matching the pattern
find "${INPUT_PATH}" -type f -path "*/${TODAYS_DATE}/articles.json" | while read -r FILE; do
  echo "Processing file: $FILE"
  # Extract URLs from the JSON file, skip files with errors
  jq -r '.[].url' "$FILE" >> "$OUTPUT_FILE" 2>/dev/null || echo "Failed to process $FILE" >> error_log.txt
done

echo "URL extraction complete. Results saved to $OUTPUT_FILE."
