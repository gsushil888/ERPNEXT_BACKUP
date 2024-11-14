#!/bin/bash

# Full paths to required commands
LS_CMD="/bin/ls"
AWK_CMD="/usr/bin/awk"
GREP_CMD="/bin/grep"
SED_CMD="/bin/sed"
SORT_CMD="/usr/bin/sort"
COMM_CMD="/usr/bin/comm"

# Directory where backups are stored
DIR="/home/frappe/frappe-bench/sites/jio/private/backups/"
LOG_FILE="/etc/filebeat/job_app_logs.log"
DEBUG_LOG="/etc/filebeat/job_app_debug.log"

echo "Running script at $(date '+%Y/%m/%d %H:%M:%S')" >> "$DEBUG_LOG"

# Change to backup directory, exit if it fails
cd "$DIR" || { echo "Failed to change directory to $DIR" >> "$DEBUG_LOG"; exit 1; }

# Generate the current file list with detailed information using ls
CURRENT_FILE_LIST=$($LS_CMD -lrth)

# Process each line to append formatted timestamps
FORMATTED_FILE_LIST=""

# Use a while loop to read the current file list
while IFS= read -r line; do
    filename=$(echo "$line" | $AWK_CMD '{print $NF}')

    # Only process files with .sql.gz extension
    if [[ "$filename" == *.sql.gz ]]; then
        # Extract the date and time from the filename (assumes filename contains YYYYMMDD_HHmmSS)
        file_timestamp=$(echo "$filename" | $GREP_CMD -oP '\d{8}_\d{6}')
        if [[ $file_timestamp ]]; then
            # Convert the timestamp from filename to dd-mm-yyyy format
            file_date=$(echo "$file_timestamp" | cut -c1-8 | $SED_CMD 's/\(....\)\(..\)\(..\)/\3-\2-\1/')
            sequence=$(echo "$file_timestamp" | cut -c10-)

            # Append the original line with the formatted date and sequence
            formatted_line="$line $file_date $sequence"
            FORMATTED_FILE_LIST+="$formatted_line"$'\n'
        fi
    fi
done <<< "$CURRENT_FILE_LIST"

# Echo the formatted file list for debugging
echo -e "Formatted List:\n$FORMATTED_FILE_LIST" >> "$DEBUG_LOG"

# Sort the formatted file list for use with comm
SORTED_CURRENT_FILE_LIST=$(echo -e "$FORMATTED_FILE_LIST" | $SORT_CMD)

# Check if the log file exists and read its content
if [[ -f "$LOG_FILE" ]]; then
    LOGGED_FILE_LIST=$(cat "$LOG_FILE" | $SORT_CMD)  # Sort the logged file list
else
    LOGGED_FILE_LIST=""
fi

# Compare current files with logged files and find any new ones
NEW_FILES=$($COMM_CMD -13 <(echo "$LOGGED_FILE_LIST") <(echo "$SORTED_CURRENT_FILE_LIST"))

# Log new files if found
if [[ -n "$NEW_FILES" ]]; then
    echo -e "$NEW_FILES" >> "$LOG_FILE"
    echo "New files added to log:" >> "$DEBUG_LOG"
    echo -e "$NEW_FILES" >> "$DEBUG_LOG"
else
    echo "No new files to log." >> "$DEBUG_LOG"
fi
