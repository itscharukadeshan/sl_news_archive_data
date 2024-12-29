#!/bin/bash

# Define the base directory
BASE_DIR="../archive"

echo "Generating checksums for all categories in $BASE_DIR"

# Iterate over each category directory (e.g., news/, sports/, technology/)
find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r category_dir; do
    echo "Processing category: $category_dir"

    # Define the checksum file for this category
    CHECKSUM_FILE="$category_dir/checksum.txt"

    # Initialize the checksum file
    echo "Generating checksum file: $CHECKSUM_FILE"
    > "$CHECKSUM_FILE" # Clear the file if it already exists

    # Iterate over all `articles.json` files in this category
    find "$category_dir" -type f -name "articles.json" | while read -r articles_file; do
        echo "  Processing file: $articles_file"

        # Extract the checksums from the JSON file
        jq -r '.[] | "\(.title)\t\(.url)"' "$articles_file" | while IFS=$'\t' read -r title url; do
            if [[ -n "$title" && -n "$url" ]]; then
                # Generate MD5 checksum for title and URL combination
                checksum=$(echo -n "$title$url" | md5sum | awk '{print $1}')
                echo "$checksum" >> "$CHECKSUM_FILE"
            else
                echo "    Skipping entry with missing title or URL in $articles_file"
            fi
        done
    done

    # Remove duplicate checksums from the file
    sort -u "$CHECKSUM_FILE" -o "$CHECKSUM_FILE"
    echo "Checksum file updated: $CHECKSUM_FILE"
done

echo "Checksum generation completed for all categories."
