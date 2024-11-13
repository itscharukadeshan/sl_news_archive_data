#!/bin/bash

# Define the output file path in the root directory
output_file="../combined_urls.txt"

# Clear the output file if it already exists
> "$output_file"

# Find and concatenate all urls.txt files in subdirectories of /archive/
find ../archive -type f -name "urls.txt" -exec cat {} + >> "$output_file"

echo "Combined URLs saved to $output_file"
