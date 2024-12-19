#!/bin/bash

# Define paths
ARCHIVE_DIR="../archive"
README_FILE="../README.md"
CURRENT_DATE=$(date +"%a %b %d %T %z %Y")

# Initialize summary content
SUMMARY_CONTENT="## News Archive Summary\n\n"
SUMMARY_CONTENT+="Summary Report as of $CURRENT_DATE\n\n"
SUMMARY_CONTENT+="| Language           | Today's Articles | Total Articles |\n"
SUMMARY_CONTENT+="|--------------------|------------------|----------------|\n"

# Initialize totals
total_today=0
total_articles=0

# Loop through each key directory in the archive
for key_dir in "$ARCHIVE_DIR"/*/; do
  key=$(basename "$key_dir")
  today_count=0
  total_count=0

  # Loop through each date folder inside the key directory
  for date_dir in "$key_dir"*/; do
    # Count articles.json entries if it exists
    if [[ -f "$date_dir/articles.json" ]]; then
      articles_today=$(jq '. | length' "$date_dir/articles.json")
      total_count=$((total_count + articles_today))
      
      # Check if the directory matches today's date
      if [[ $(basename "$date_dir") == $(date +"%Y-%m-%d") ]]; then
        today_count=$((today_count + articles_today))
      fi
    fi
  done

  # Add to totals
  total_today=$((total_today + today_count))
  total_articles=$((total_articles + total_count))

  # Add row to summary content
  SUMMARY_CONTENT+="| $key               | $today_count          | $total_count        |\n"
done

# Add total row to summary content
SUMMARY_CONTENT+="| **Total**          | **$total_today**      | **$total_articles** |\n"

# Update README.md
if [[ -f "$README_FILE" ]]; then
  # Replace the summary section in README.md
  sed -i "/## News Archive Summary/,\$d" "$README_FILE" # Remove old summary
  echo -e "$SUMMARY_CONTENT" >> "$README_FILE"         # Append new summary
else
  # Create README.md if it doesn't exist
  echo -e "$SUMMARY_CONTENT" > "$README_FILE"
fi

echo "README.md updated with the latest News Archive Summary."
