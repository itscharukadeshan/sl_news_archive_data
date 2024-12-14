#!/bin/bash

# Directory paths
DATA_DIR="../"                   # Directory containing JSON files
OUTPUT_DIR="../archive"          # Directory for separated output
ARCHIVE_DIR="../processed_data"  # Directory for storing processed files
LOG_FILE="../process_log.txt"    # Log file for command logs
README_FILE="../README.md"       # README file for summary

# Get the current date for organizing processed data by day
current_date=$(date +"%Y-%m-%d")
date_dir="$ARCHIVE_DIR/$current_date"

# Ensure output and archive directories exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$date_dir"

# Start logging
echo "Process started at $(date)" >> "$LOG_FILE"

# Initialize counters for the summary
added_articles=0
duplicate_count=0
skip_count=0
declare -A missing_data_keys

# Loop over each JSON file in the data directory
for file in "$DATA_DIR"/*.json; do
    filename=$(basename "$file")
    echo "Processing file: $filename" >> "$LOG_FILE"

    # Parse the JSON file for each unique key
    jq -c 'to_entries[]' "$file" | while read -r entry; do
        key=$(echo "$entry" | jq -r '.key')
        success=$(echo "$entry" | jq -r '.value.success')

        # Only process if success is true
        if [ "$success" = "true" ]; then
            # Validate that the 'data' key exists and is not null
            data_array=$(echo "$entry" | jq -c '.value.data // empty')
            if [ -z "$data_array" ] || [ "$data_array" = "[]" ]; then
                echo "No data to process for key: $key" >> "$LOG_FILE"
                continue
            fi

            # Process each item in the data array
            echo "$data_array" | while read -r item; do
                # Remove null or empty key-value pairs
                item=$(echo "$item" | jq 'del(.[] | select(. == null or . == ""))')

                title=$(echo "$item" | jq -r '.title // empty')
                url=$(echo "$item" | jq -r '.url // empty')
                checkSum=$(echo "$item" | jq -r '.checkSum // empty')

                # Check for missing fields and track missing keys
                if [ -z "$title" ] || [ -z "$url" ] || [ -z "$checkSum" ]; then
                    ((skip_count++))
                    [[ -z "$title" ]] && ((missing_data_keys["title"]++))
                    [[ -z "$url" ]] && ((missing_data_keys["url"]++))
                    [[ -z "$checkSum" ]] && ((missing_data_keys["checkSum"]++))
                    echo "Skipped entry with missing title, url, or checksum." >> "$LOG_FILE"
                    continue
                fi

                # Extract other fields with defaults to avoid null
                href=$(echo "$item" | jq -r '.href // empty')
                timestamp=$(echo "$item" | jq -r '.timestamp // empty')
                isoTimestamp=$(echo "$item" | jq -r '.isoTimestamp // empty')
                byline=$(echo "$item" | jq -r '.byline // empty')
                baseUrl=$(echo "$item" | jq -r '.baseUrl // empty')

                # Extract date from isoTimestamp to create date-based folder
                date=$(echo "$isoTimestamp" | cut -d'T' -f1)
                date_key_dir="$OUTPUT_DIR/$key/$date"
                mkdir -p "$date_key_dir"

                # Output file for articles on specific dates
                output_file="$date_key_dir/articles.json"

                # If the output file does not exist, create it with an empty JSON array
                if [ ! -f "$output_file" ]; then
                    echo "[]" > "$output_file"  # Create an empty JSON array
                fi

                # Check for duplicate by checking key-level checksum file
                key_checksum_file="$OUTPUT_DIR/$key/checksum.txt"
                if ! grep -q "$checkSum" "$key_checksum_file" 2>/dev/null; then
                    # Append new entry if not duplicated
                    existing_data=$(cat "$output_file")
                    new_entry=$(jq -n \
                        --arg title "$title" \
                        --arg href "$href" \
                        --arg byline "$byline" \
                        --arg timestamp "$timestamp" \
                        --arg url "$url" \
                        --arg isoTimestamp "$isoTimestamp" \
                        --arg baseUrl "$baseUrl" \
                        --arg checkSum "$checkSum" \
                        '{title: $title, href: $href, byline: $byline, timestamp: $timestamp, url: $url, isoTimestamp: $isoTimestamp, baseUrl: $baseUrl, checkSum: $checkSum}')
                    updated_data=$(echo "$existing_data" | jq ". += [$new_entry]")
                    echo "$updated_data" > "$output_file"

                    # Append checksum to key-level file
                    echo "$checkSum" >> "$key_checksum_file"

                    ((added_articles++))
                    echo "Added new entry for date: $date in key: $key" >> "$LOG_FILE"
                else
                    ((duplicate_count++))
                    echo "Duplicate entry skipped for checksum: $checkSum" >> "$LOG_FILE"
                fi
            done
        else
            echo "Skipping key: $key (success is false)" >> "$LOG_FILE"
        fi
    done

    # Move the processed JSON file to the date-based archive directory
    mv "$file" "$date_dir/$filename"
    echo "Moved $filename to archive in $date_dir" >> "$LOG_FILE"
done

# Generate README.md with a summary
echo "# News Archive Summary" > "$README_FILE"
echo "## Summary Report as of $(date)" >> "$README_FILE"

# Generate total and today's counts by key
echo "| Newspaper | Today's Articles | Total Articles |" >> "$README_FILE"
echo "|-----------|------------------|----------------|" >> "$README_FILE"
for key_dir in "$OUTPUT_DIR"/*; do
    if [ -d "$key_dir" ]; then
        key=$(basename "$key_dir")
        today_count=$(find "$key_dir" -type f -path "*/$current_date/articles.json" -exec jq '. | length' {} + | awk '{s+=$1} END {print s}')
        total_count=$(find "$key_dir" -type f -name "articles.json" -exec jq '. | length' {} + | awk '{s+=$1} END {print s}')
        echo "| $key | $today_count | $total_count |" >> "$README_FILE"
    fi
done

# Log completion
echo "Process completed at $(date)" >> "$LOG_FILE"
echo "Added articles: $added_articles" >> "$LOG_FILE"
echo "Duplicate entries: $duplicate_count" >> "$LOG_FILE"
echo "Skipped entries due to missing data: $skip_count" >> "$LOG_FILE"
echo "Processing complete! Summary saved to '$README_FILE'. Logs saved to '$LOG_FILE'."
