#!/bin/bash

# Define input and output files
input_file="../combined_urls.txt"
output_file="../decoded_urls.txt"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo "Error: Input file '$input_file' not found."
  exit 1
fi

# Clear the output file
> "$output_file"

# Process each URL in the input file
while IFS= read -r url; do
  if [ -n "$url" ]; then
    # Decode the URL using Python and append to the output file
    decoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.unquote('$url'))" 2>/dev/null)

    if [ $? -eq 0 ]; then
      # Append the decoded URL to the output file
      echo "$decoded_url" >> "$output_file"
    else
      echo "Failed to decode URL: $url" >> "$output_file"
    fi
  fi
done < "$input_file"

echo "Processed URLs have been saved to '$output_file'."
