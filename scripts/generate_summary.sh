#!/bin/bash

ARCHIVE_DIR="../archive"
README_FILE="../README.md"
CURRENT_DATE=$(date +"%a %b %d %T %z %Y")

PREVIEW_URL="https://itscharukadeshan.github.io/sl_news_archive_data/news_chart_by_newspaper.html"

# Summary table first
SUMMARY_CONTENT="## News Archive Summary\n\n"
SUMMARY_CONTENT+="Summary Report as of $CURRENT_DATE\n\n"
SUMMARY_CONTENT+="| News paper         | Today's Articles | Total Articles |\n"
SUMMARY_CONTENT+="|--------------------|------------------|----------------|\n"

total_today=0
total_articles=0

for key_dir in "$ARCHIVE_DIR"/*/; do
  key=$(basename "$key_dir")
  today_count=0
  total_count=0

  for date_dir in "$key_dir"*/; do
    if [[ -f "$date_dir/articles.json" ]]; then
      articles_today=$(jq '. | length' "$date_dir/articles.json")
      total_count=$((total_count + articles_today))
      if [[ $(basename "$date_dir") == $(date +"%Y-%m-%d") ]]; then
        today_count=$((today_count + articles_today))
      fi
    fi
  done

  total_today=$((total_today + today_count))
  total_articles=$((total_articles + total_count))

  SUMMARY_CONTENT+="| $key               | $today_count          | $total_count        |\n"
done

SUMMARY_CONTENT+="| **Total**          | **$total_today**      | **$total_articles** |\n\n"

# Now add the preview URL section AFTER the summary table
SUMMARY_CONTENT+="### Interactive Chart Preview\n"
SUMMARY_CONTENT+="🔗 [View Interactive Chart]($PREVIEW_URL)\n"

if [[ -f "$README_FILE" ]]; then
  # Remove existing News Archive Summary section and everything after it
  sed -i "/## News Archive Summary/,\$d" "$README_FILE"
  # Append updated summary + preview URL at the bottom
  echo -e "$SUMMARY_CONTENT" >> "$README_FILE"
else
  echo -e "$SUMMARY_CONTENT" > "$README_FILE"
fi

echo "README.md updated with News Archive Summary and preview URL at the bottom."
