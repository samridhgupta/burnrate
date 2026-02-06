#!/usr/bin/env bash
# lib/date-utils.sh - Cross-platform date utilities
# Handles date arithmetic for macOS (BSD date) and Linux (GNU date)

[[ -n "${BURNRATE_DATE_UTILS_LOADED:-}" ]] && return 0
readonly BURNRATE_DATE_UTILS_LOADED=1

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"

# Detect date command capabilities
_detect_date_command() {
    # Check if GNU date (Linux) or BSD date (macOS)
    if date --version >/dev/null 2>&1; then
        echo "gnu"
    else
        echo "bsd"
    fi
}

# Cache detection result
readonly DATE_COMMAND_TYPE=$(_detect_date_command)

# Get current date in YYYY-MM-DD format
# Returns: date string
get_current_date() {
    date +%Y-%m-%d
}

# Get date N days ago
# Args: days_ago
# Returns: date string in YYYY-MM-DD format
get_date_days_ago() {
    local days_ago="$1"

    if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
        # GNU date (Linux)
        date -d "$days_ago days ago" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d
    else
        # BSD date (macOS, FreeBSD)
        date -v-${days_ago}d +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d
    fi
}

# Get date N days from now
# Args: days_ahead
# Returns: date string in YYYY-MM-DD format
get_date_days_ahead() {
    local days_ahead="$1"

    if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
        # GNU date (Linux)
        date -d "$days_ahead days" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d
    else
        # BSD date (macOS, FreeBSD)
        date -v+${days_ahead}d +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d
    fi
}

# Get first day of current month
# Returns: date string in YYYY-MM-DD format
get_first_day_of_month() {
    local today
    today=$(date +%Y-%m-%d)
    echo "${today%-*}-01"
}

# Get last day of current month
# Returns: date string in YYYY-MM-DD format
get_last_day_of_month() {
    local today
    today=$(date +%Y-%m-%d)
    local year month
    year=$(echo "$today" | cut -d- -f1)
    month=$(echo "$today" | cut -d- -f2)

    # Get first day of next month, then go back one day
    if [[ "$month" == "12" ]]; then
        # December -> next year January
        if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
            date -d "$((year + 1))-01-01 -1 day" +%Y-%m-%d 2>/dev/null || echo "$year-12-31"
        else
            date -v1d -v+1m -v-1d -j -f "%Y-%m-%d" "$year-12-01" +%Y-%m-%d 2>/dev/null || echo "$year-12-31"
        fi
    else
        # Any other month
        local next_month=$(printf "%02d" $((10#$month + 1)))
        if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
            date -d "$year-$next_month-01 -1 day" +%Y-%m-%d 2>/dev/null || echo "$today"
        else
            date -v1d -v+1m -v-1d -j -f "%Y-%m-%d" "$year-$month-01" +%Y-%m-%d 2>/dev/null || echo "$today"
        fi
    fi
}

# Get Monday of current week (ISO 8601 week starts on Monday)
# Returns: date string in YYYY-MM-DD format
get_monday_of_week() {
    local today
    today=$(date +%Y-%m-%d)

    # Get day of week (1=Monday, 7=Sunday)
    local dow
    if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
        dow=$(date -d "$today" +%u 2>/dev/null || echo "1")
    else
        dow=$(date -j -f "%Y-%m-%d" "$today" +%u 2>/dev/null || echo "1")
    fi

    # Calculate days since Monday
    local days_since_monday=$((dow - 1))

    # Get Monday's date
    if [[ "$days_since_monday" == "0" ]]; then
        echo "$today"
    else
        get_date_days_ago "$days_since_monday"
    fi
}

# Get Sunday of current week
# Returns: date string in YYYY-MM-DD format
get_sunday_of_week() {
    local today
    today=$(date +%Y-%m-%d)

    # Get day of week (1=Monday, 7=Sunday)
    local dow
    if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
        dow=$(date -d "$today" +%u 2>/dev/null || echo "1")
    else
        dow=$(date -j -f "%Y-%m-%d" "$today" +%u 2>/dev/null || echo "1")
    fi

    # Calculate days until Sunday
    local days_until_sunday=$((7 - dow))

    # Get Sunday's date
    if [[ "$dow" == "7" ]]; then
        echo "$today"
    else
        get_date_days_ahead "$days_until_sunday"
    fi
}

# Compare two dates
# Args: date1 date2
# Returns: 0 if date1 < date2, 1 if date1 >= date2
date_less_than() {
    local date1="$1"
    local date2="$2"

    # Simple string comparison works for YYYY-MM-DD format
    [[ "$date1" < "$date2" ]]
}

# Compare two dates
# Args: date1 date2
# Returns: 0 if date1 <= date2, 1 if date1 > date2
date_less_than_or_equal() {
    local date1="$1"
    local date2="$2"

    # Simple string comparison works for YYYY-MM-DD format
    [[ "$date1" < "$date2" || "$date1" == "$date2" ]]
}

# Check if date is in range (inclusive)
# Args: date start_date end_date
# Returns: 0 if in range, 1 otherwise
date_in_range() {
    local date="$1"
    local start_date="$2"
    local end_date="$3"

    date_less_than_or_equal "$start_date" "$date" && \
    date_less_than_or_equal "$date" "$end_date"
}

# Get date from epoch timestamp
# Args: epoch_seconds
# Returns: date string in YYYY-MM-DD format
epoch_to_date() {
    local epoch="$1"

    if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
        date -d "@$epoch" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d
    else
        date -r "$epoch" +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d
    fi
}

# Get epoch timestamp from date
# Args: date (YYYY-MM-DD)
# Returns: epoch seconds
date_to_epoch() {
    local date_str="$1"

    if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
        date -d "$date_str" +%s 2>/dev/null || date +%s
    else
        date -j -f "%Y-%m-%d" "$date_str" +%s 2>/dev/null || date +%s
    fi
}

# Calculate days between two dates
# Args: start_date end_date
# Returns: number of days
days_between() {
    local start_date="$1"
    local end_date="$2"

    local start_epoch end_epoch
    start_epoch=$(date_to_epoch "$start_date")
    end_epoch=$(date_to_epoch "$end_date")

    local diff_seconds=$((end_epoch - start_epoch))
    local diff_days=$((diff_seconds / 86400))

    echo "$diff_days"
}

# Format date for display
# Args: date format
# Returns: formatted date string
format_date() {
    local date_str="$1"
    local format="${2:-%B %d, %Y}"  # Default: "January 01, 2026"

    if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
        date -d "$date_str" +"$format" 2>/dev/null || echo "$date_str"
    else
        date -j -f "%Y-%m-%d" "$date_str" +"$format" 2>/dev/null || echo "$date_str"
    fi
}

# Validate date format (YYYY-MM-DD)
# Args: date_string
# Returns: 0 if valid, 1 if invalid
validate_date_format() {
    local date_str="$1"

    # Check format with regex
    if [[ ! "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 1
    fi

    # Try to parse it
    if [[ "$DATE_COMMAND_TYPE" == "gnu" ]]; then
        date -d "$date_str" >/dev/null 2>&1
    else
        date -j -f "%Y-%m-%d" "$date_str" >/dev/null 2>&1
    fi
}

# Get relative date description
# Args: date
# Returns: human-friendly description
get_relative_date_description() {
    local target_date="$1"
    local today
    today=$(get_current_date)

    local diff
    diff=$(days_between "$target_date" "$today")

    if [[ "$diff" == "0" ]]; then
        echo "today"
    elif [[ "$diff" == "1" ]]; then
        echo "yesterday"
    elif [[ "$diff" == "-1" ]]; then
        echo "tomorrow"
    elif [[ "$diff" -gt 1 && "$diff" -le 7 ]]; then
        echo "$diff days ago"
    elif [[ "$diff" -lt -1 && "$diff" -ge -7 ]]; then
        echo "in ${diff#-} days"
    else
        echo "$target_date"
    fi
}
