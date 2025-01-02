#!/bin/bash

# Define log file
LOG_FILE="trigger_log_$(date +%Y%m%d%H%M%S).log"

# Function to run a script and log its output
run_script() {
    local script_name=$1
    echo "Running $script_name..." | tee -a "$LOG_FILE"
    bash "$script_name" >> "$LOG_FILE" 2>&1

    # Check if the script executed successfully
    if [ $? -eq 0 ]; then
        echo "$script_name completed successfully." | tee -a "$LOG_FILE"
    else
        echo "$script_name failed. Check the logs for details." | tee -a "$LOG_FILE"
    fi
}

# List of scripts to execute in order
SCRIPTS=(
    "process_json.sh"
    "combined_urls.sh"
    "generate_summary.sh"
    "extract_todays_urls.sh"
    # Add more scripts here
)

# Loop through each script and execute it
for script in "${SCRIPTS[@]}"; do
    run_script "$script"
done

echo "All scripts have been executed. Logs saved to $LOG_FILE."
