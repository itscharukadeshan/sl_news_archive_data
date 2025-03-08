#!/bin/bash

# Output file for the table
output_file="../archive/news_article_counts.csv"

# Temporary file to store intermediate results
temp_file=$(mktemp)

# Recursively find all articles.json files in the archive folder
find ../archive -name "articles.json" | while read -r filepath; do
    # Extract the newspaper and date from the file path
    # Example path: ../archive/ada/2024-10-29/articles.json
    newspaper=$(echo "$filepath" | awk -F'/' '{print $(NF-2)}')  # Extract newspaper name (ada)
    date=$(echo "$filepath" | awk -F'/' '{print $(NF-1)}')       # Extract date (2024-10-29)

    # Count the number of JSON objects in the file using jq
    article_count=$(jq '. | length' "$filepath")

    # Write the intermediate result to the temp file
    echo "$date,$newspaper,$article_count" >> "$temp_file"
done

# Summarize the counts by date and newspaper
awk -F, '
{
    key = $1 "," $2  # Combine date and newspaper as the key
    count[key] += $3 # Sum the article counts
}
END {
    for (key in count) {
        print key "," count[key]
    }
}
' "$temp_file" | sort > "$output_file"

# Add header to the output file
echo "Date,Newspaper,ArticleCount" > header.csv
cat header.csv "$output_file" > temp_output && mv temp_output "$output_file"

# Clean up
rm "$temp_file" header.csv

echo "Table generated and saved to $output_file"