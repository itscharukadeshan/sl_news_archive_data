#!/bin/bash

# Directory paths
DATA_DIR="../"                   # Directory containing JSON files
OUTPUT_DIR="../archive"         # Directory for separated output
ARCHIVE_DIR="../processed_data" # Directory for storing processed files
LOG_FILE="../process_log.txt"   # Log file for command logs

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

# Function to decode and format URLs
decode_and_format_url() {
    url="$1"
    decoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$url'))" 2>/dev/null)

    if [ $? -eq 0 ]; then
        # You can add additional URL formatting here if needed
        echo "$decoded_url"
    else
        echo "Failed to decode URL: $url"
        return 1
    fi
}

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
            data_array=$(echo "$entry" | jq -c '.value.data[]')

            # Create a subdirectory for each unique key if it does not already exist
            key_dir="$OUTPUT_DIR/$key"
            mkdir -p "$key_dir"

            # Key-level checksum and URLs files
            key_checksum_file="$key_dir/checksum.txt"
            key_urls_file="$key_dir/urls.txt"

            # Loop through each item in the data array
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

                # Decode and format URL
                formatted_url=$(decode_and_format_url "$url")
                if [ $? -ne 0 ]; then
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
                date_key_dir="$key_dir/$date"
                mkdir -p "$date_key_dir"

                # Output file for articles on specific dates
                output_file="$date_key_dir/articles.json"

                # If the output file does not exist, create it with an empty JSON array
                if [ ! -f "$output_file" ]; then
                    echo "[]" > "$output_file"
                fi

                # Ensure checksum file is limited to the most recent 600 entries
                if [ -f "$key_checksum_file" ]; then
                    # Keep only the last 600 lines
                    tail -n 600 "$key_checksum_file" > "$key_checksum_file.tmp"
                    mv "$key_checksum_file.tmp" "$key_checksum_file"
                fi

                # Check for duplicate by checking key-level checksum file
                if ! grep -q "$checkSum" "$key_checksum_file" 2>/dev/null; then
                    # Append new entry if not duplicated
                    existing_data=$(cat "$output_file")
                    new_entry=$(jq -n \
                        --arg title "$title" \
                        --arg href "$href" \
                        --arg byline "$byline" \
                        --arg timestamp "$timestamp" \
                        --arg formatted_url "$formatted_url" \
                        --arg url "$url" \
                        --arg isoTimestamp "$isoTimestamp" \
                        --arg baseUrl "$baseUrl" \
                        --arg checkSum "$checkSum" \
                        '{title: $title, href: $href, byline: $byline, timestamp: $timestamp, url: $formatted_url, isoTimestamp: $isoTimestamp, baseUrl: $baseUrl, checkSum: $checkSum}')
                    updated_data=$(echo "$existing_data" | jq ". += [$new_entry]")
                    echo "$updated_data" > "$output_file"

                    # Append checksum and URL to the key-level files
                    echo "$checkSum" >> "$key_checksum_file"
                    echo "$formatted_url" >> "$key_urls_file"
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

# Summary report
echo "Process completed at $(date)" >> "$LOG_FILE"
echo "Summary:" >> "$LOG_FILE"
echo "Added articles: $added_articles" >> "$LOG_FILE"
echo "Duplicate entries: $duplicate_count" >> "$LOG_FILE"
echo "Skipped entries due to missing data: $skip_count" >> "$LOG_FILE"
echo "Missing data fields:" >> "$LOG_FILE"
for key in "${!missing_data_keys[@]}"; do
    echo "  $key: ${missing_data_keys[$key]}" >> "$LOG_FILE"
done

echo "Processing complete! Data separated by keys and dates in '$OUTPUT_DIR'. Logs saved to '$LOG_FILE'."
