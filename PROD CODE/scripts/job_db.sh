DIR="/proddb/db_bkp/"
LOG_FILE="/etc/filebeat/job_db_logs.log"
DEBUG_LOG="/etc/filebeat/job_db_debug.log"

echo "Running script at $(date '+%Y/%m/%d %H:%M:%S')" >> "$DEBUG_LOG"

cd "$DIR" || { echo "Failed to change directory" >> "$DEBUG_LOG"; exit; }

# Generate the current file list with detailed information using ls
CURRENT_FILE_LIST=$(ls -lrth)

# Process each line to append formatted timestamps
FORMATTED_FILE_LIST=""

# Use a while loop to read the current file list
while IFS= read -r line; do
    filename=$(echo "$line" | awk '{print $NF}')

    # Only process files with .sql.gz extension
    if [[ "$filename" == *.sql.gz ]]; then
        # Extract the date part and sequence number from the filename
        file_timestamp=$(echo "$filename" | grep -oP '\d{2}_\d{2}_\d{2}')
        sequence=$(echo "$filename" | grep -oP '(?<=-)\d{6}(?=\.sql\.gz)')

        # Convert the timestamp from filename to dd-mm-yyyy format
        if [[ $file_timestamp && $sequence ]]; then
            # Add '20' before the last two digits of the year
            file_date=$(echo "$file_timestamp" | sed 's/_/-/g' | sed 's/\([0-9]\{2\}\)$/20\1/')
            formatted_line="$line $file_date $sequence"
            # Append the formatted line to the output
            FORMATTED_FILE_LIST+="$formatted_line"$'\n'
        fi
    fi
done <<< "$CURRENT_FILE_LIST"

# Echo the formatted file list for debugging
#echo -e "Formatted List:\n$FORMATTED_FILE_LIST" >> "$DEBUG_LOG"

# Sort the formatted file list for use with comm
SORTED_CURRENT_FILE_LIST=$(echo -e "$FORMATTED_FILE_LIST" | sort)
# Check if the log file exists and read its content
if [[ -f "$LOG_FILE" ]]; then
    LOGGED_FILE_LIST=$(cat "$LOG_FILE" | sort)  # Sort the logged file list
else
    LOGGED_FILE_LIST=""
fi

# Compare current files with logged files and find any new ones
NEW_FILES=$(comm -13 <(echo "$LOGGED_FILE_LIST") <(echo "$SORTED_CURRENT_FILE_LIST"))

# Log new files if found
if [[ -n "$NEW_FILES" ]]; then
    echo -e "$NEW_FILES" >> "$LOG_FILE"
    echo "New files added to log:" >> "$DEBUG_LOG"
    echo -e "$NEW_FILES" >> "$DEBUG_LOG"
else
    echo "No new files to log." >> "$DEBUG_LOG"
fi
