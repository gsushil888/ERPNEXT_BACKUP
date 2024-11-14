#!/bin/bash

# Define the full paths to all required commands
SUPERVISORCTL_CMD="/usr/bin/supervisorctl"
TAIL_CMD="/usr/bin/tail"
DATE_CMD="/bin/date"

# Define log file paths
LOG_FILE="/etc/filebeat/redis_status.log"
DEBUG_FILE="/etc/filebeat/redis_debug.log"

# Log the current date and time in the debug file
echo "$($DATE_CMD '+%Y/%m/%d %H:%M:%S')" > "$DEBUG_FILE"

# Get the current status of Redis using supervisorctl
REDIS_STATUS=$(sudo $SUPERVISORCTL_CMD status)

# Check if the log file exists
if [[ -f "$LOG_FILE" ]]; then
    # Read the last logged status from the log file
    PREV_STATUS=$($TAIL_CMD -n 1 "$LOG_FILE")

    # Compare the current status with the last logged status
    if [[ "$REDIS_STATUS" != "$PREV_STATUS" ]]; then
        # If the status has changed, log the new status with a timestamp
        echo "$REDIS_STATUS" >> "$LOG_FILE"
        echo "Redis status changed, logged new status." >> "$DEBUG_FILE"
    else
        echo "Redis status has not changed." >> "$DEBUG_FILE"
    fi
else
    # If the log file doesn't exist, log the status for the first time
    echo "$REDIS_STATUS" > "$LOG_FILE"
    echo "Log file did not exist, created new log file with current status." >> "$DEBUG_FILE"
fi
