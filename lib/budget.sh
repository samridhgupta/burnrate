#!/usr/bin/env bash
# lib/budget.sh - Budget tracking and alerts
# Track spending against daily/monthly budgets

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/pricing.sh"
source "$LIB_DIR/stats.sh"
source "$LIB_DIR/layout.sh"

# ============================================================================
# Helper Functions
# ============================================================================

# Clean numeric value for bc
# Removes $, commas, spaces, validates number
# Args: value
# Returns: clean number or 0
clean_number() {
    local value="$1"

    # Remove $, commas, spaces
    value=$(echo "$value" | tr -d '$, ')

    # Validate it's a number
    if [[ "$value" =~ ^[0-9]*\.?[0-9]+$ ]]; then
        echo "$value"
    else
        echo "0"
    fi
}

# Safe bc calculation
# Args: expression
# Returns: result or 0 on error
safe_bc() {
    local expr="$1"
    local result

    result=$(echo "$expr" | bc 2>/dev/null)

    if [[ -z "$result" || ! "$result" =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
        echo "0"
    else
        echo "$result"
    fi
}

# Compare floats
# Args: value1 operator value2
# Returns: 0 if true, 1 if false
compare_float() {
    local val1="$1"
    local op="$2"
    local val2="$3"

    val1=$(clean_number "$val1")
    val2=$(clean_number "$val2")

    case "$op" in
        "<"|"lt")
            [[ $(echo "$val1 < $val2" | bc 2>/dev/null) == "1" ]]
            ;;
        "<="|"le")
            [[ $(echo "$val1 <= $val2" | bc 2>/dev/null) == "1" ]]
            ;;
        ">"|"gt")
            [[ $(echo "$val1 > $val2" | bc 2>/dev/null) == "1" ]]
            ;;
        ">="|"ge")
            [[ $(echo "$val1 >= $val2" | bc 2>/dev/null) == "1" ]]
            ;;
        "=="|"eq")
            [[ $(echo "$val1 == $val2" | bc 2>/dev/null) == "1" ]]
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================================================
# Budget State Management
# ============================================================================

# Get budget state file
get_budget_state_file() {
    echo "${CONFIG_DATA_DIR}/budget-state.json"
}

# Initialize budget state
init_budget_state() {
    local state_file
    state_file=$(get_budget_state_file)

    mkdir -p "$(dirname "$state_file")"

    if [[ ! -f "$state_file" ]]; then
        local daily_budget monthly_budget
        daily_budget=$(clean_number "${CONFIG_DAILY_BUDGET}")
        monthly_budget=$(clean_number "${CONFIG_MONTHLY_BUDGET}")

        cat > "$state_file" <<EOF
{
  "daily": {
    "date": "$(date +%Y-%m-%d)",
    "spent": 0.0,
    "budget": $daily_budget
  },
  "monthly": {
    "month": "$(date +%Y-%m)",
    "spent": 0.0,
    "budget": $monthly_budget
  },
  "last_cost": 0.0,
  "last_update": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
        log_debug "Initialized budget state: $state_file"
    fi
}

# Read budget state
read_budget_state() {
    local state_file
    state_file=$(get_budget_state_file)

    if [[ ! -f "$state_file" ]]; then
        init_budget_state
    fi

    cat "$state_file"
}

# Update budget state
update_budget_state() {
    local daily_spent="$1"
    local monthly_spent="$2"
    local current_cost="$3"

    # Clean all values
    daily_spent=$(clean_number "$daily_spent")
    monthly_spent=$(clean_number "$monthly_spent")
    current_cost=$(clean_number "$current_cost")

    local daily_budget monthly_budget
    daily_budget=$(clean_number "${CONFIG_DAILY_BUDGET}")
    monthly_budget=$(clean_number "${CONFIG_MONTHLY_BUDGET}")

    local state_file
    state_file=$(get_budget_state_file)

    cat > "$state_file" <<EOF
{
  "daily": {
    "date": "$(date +%Y-%m-%d)",
    "spent": $daily_spent,
    "budget": $daily_budget
  },
  "monthly": {
    "month": "$(date +%Y-%m)",
    "spent": $monthly_spent,
    "budget": $monthly_budget
  },
  "last_cost": $current_cost,
  "last_update": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# ============================================================================
# Budget Calculation
# ============================================================================

# Get current total cost from stats
get_current_cost() {
    local breakdown
    breakdown=$(get_usage_breakdown "$CONFIG_STATS_FILE" 2>/dev/null)

    if [[ -z "$breakdown" ]]; then
        echo "0.00"
        return 0
    fi

    # Extract total cost from costs section specifically
    local costs_section total_cost
    costs_section=$(echo "$breakdown" | sed -n '/"costs":/,/}/p')
    total_cost=$(echo "$costs_section" | grep '"total"' | grep -o '[0-9.]*' | head -1)

    total_cost=$(clean_number "$total_cost")
    echo "$total_cost"
}

# Check if new day/month and reset if needed
check_and_reset_budgets() {
    local state
    state=$(read_budget_state)

    local current_date current_month
    current_date=$(date +%Y-%m-%d)
    current_month=$(date +%Y-%m)

    local state_date state_month
    state_date=$(echo "$state" | grep '"date"' | grep -o '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | head -1)
    state_month=$(echo "$state" | grep '"month"' | grep -o '[0-9][0-9][0-9][0-9]-[0-9][0-9]' | head -1)

    local daily_spent monthly_spent

    # Reset daily if new day
    if [[ "$current_date" != "$state_date" ]]; then
        log_debug "New day detected, resetting daily budget"
        daily_spent="0.0"
    else
        daily_spent=$(echo "$state" | grep -A1 '"daily"' | grep '"spent"' | grep -o '[0-9.]*' | head -1)
        daily_spent=$(clean_number "$daily_spent")
    fi

    # Reset monthly if new month
    if [[ "$current_month" != "$state_month" ]]; then
        log_debug "New month detected, resetting monthly budget"
        monthly_spent="0.0"
    else
        monthly_spent=$(echo "$state" | grep -A1 '"monthly"' | grep '"spent"' | grep -o '[0-9.]*' | head -1)
        monthly_spent=$(clean_number "$monthly_spent")
    fi

    echo "$daily_spent $monthly_spent"
}

# Calculate spending for current period
calculate_spending() {
    local current_cost
    current_cost=$(get_current_cost)
    current_cost=$(clean_number "$current_cost")

    local state
    state=$(read_budget_state)

    local last_cost
    last_cost=$(echo "$state" | grep '"last_cost"' | grep -o '[0-9.]*' | head -1)
    last_cost=$(clean_number "$last_cost")

    # Calculate delta (new spending since last check)
    local delta
    delta=$(safe_bc "scale=6; $current_cost - $last_cost")

    # Handle negative delta (stats reset)
    if compare_float "$delta" "<" "0"; then
        delta="0"
    fi

    # Get current spent amounts
    local spent daily_spent monthly_spent
    spent=$(check_and_reset_budgets)
    read -r daily_spent monthly_spent <<< "$spent"

    daily_spent=$(clean_number "$daily_spent")
    monthly_spent=$(clean_number "$monthly_spent")

    # Add delta to spent
    daily_spent=$(safe_bc "scale=6; $daily_spent + $delta")
    monthly_spent=$(safe_bc "scale=6; $monthly_spent + $delta")

    # Update state
    update_budget_state "$daily_spent" "$monthly_spent" "$current_cost"

    echo "$daily_spent $monthly_spent"
}

# ============================================================================
# Budget Status
# ============================================================================

# Get budget status (percentage used)
get_budget_status() {
    local budget_type="${1:-daily}"  # daily or monthly

    local spending
    spending=$(calculate_spending)
    read -r daily_spent monthly_spent <<< "$spending"

    daily_spent=$(clean_number "$daily_spent")
    monthly_spent=$(clean_number "$monthly_spent")

    local spent budget
    if [[ "$budget_type" == "daily" ]]; then
        spent="$daily_spent"
        budget=$(clean_number "${CONFIG_DAILY_BUDGET}")
    else
        spent="$monthly_spent"
        budget=$(clean_number "${CONFIG_MONTHLY_BUDGET}")
    fi

    # If budget is 0, return 0% (no limit)
    if compare_float "$budget" "==" "0"; then
        echo "0 $spent $budget"
        return 0
    fi

    # Calculate percentage
    local percentage
    percentage=$(safe_bc "scale=2; ($spent * 100) / $budget")

    echo "$percentage $spent $budget"
}

# Get budget status indicator (emoji/text)
get_budget_indicator() {
    local percentage="$1"

    percentage=$(clean_number "$percentage")
    local alert_threshold=$(clean_number "${CONFIG_BUDGET_ALERT}")

    if compare_float "$percentage" ">=" "100"; then
        echo "${THEME_BUDGET_EXCEEDED}"
    elif compare_float "$percentage" ">=" "$alert_threshold"; then
        echo "${THEME_BUDGET_CRITICAL}"
    elif compare_float "$percentage" ">=" "75"; then
        echo "${THEME_BUDGET_WARNING}"
    else
        echo "${THEME_BUDGET_SAFE}"
    fi
}

# Get budget message
get_budget_message() {
    local percentage="$1"

    percentage=$(clean_number "$percentage")
    local alert_threshold=$(clean_number "${CONFIG_BUDGET_ALERT}")

    if compare_float "$percentage" ">=" "100"; then
        echo "${THEME_BUDGET_MSG_EXCEEDED}"
    elif compare_float "$percentage" ">=" "$alert_threshold"; then
        echo "${THEME_BUDGET_MSG_CRITICAL}"
    elif compare_float "$percentage" ">=" "75"; then
        echo "${THEME_BUDGET_MSG_WARNING}"
    else
        echo "${THEME_BUDGET_MSG_OK}"
    fi
}

# ============================================================================
# Budget Alerts
# ============================================================================

# Check if alert should fire
should_alert() {
    local percentage="$1"
    local threshold="${CONFIG_BUDGET_ALERT}"

    percentage=$(clean_number "$percentage")
    threshold=$(clean_number "$threshold")

    compare_float "$percentage" ">=" "$threshold"
}

# Trigger budget alert
trigger_alert() {
    local budget_type="$1"
    local percentage="$2"
    local spent="$3"
    local budget="$4"

    echo ""
    _themed_hr
    echo "  🚨 BUDGET ALERT"
    _themed_hr
    echo ""
    echo "Budget Type: $(echo "$budget_type" | tr '[:lower:]' '[:upper:]')"
    printf "Spent: \$%s\n" "$(format_cost $(clean_number "$spent"))"
    printf "Budget: \$%s\n" "$(format_cost $(clean_number "$budget"))"
    printf "Used: %.1f%%\n" "$(clean_number "$percentage")"
    echo ""
    echo "$(get_budget_message "$percentage")"
    echo ""
    _themed_hr
}

# ============================================================================
# Budget Projection
# ============================================================================

# Project budget usage
project_budget() {
    local budget_type="${1:-daily}"

    local status
    status=$(get_budget_status "$budget_type")
    read -r percentage spent budget <<< "$status"

    percentage=$(clean_number "$percentage")
    spent=$(clean_number "$spent")
    budget=$(clean_number "$budget")

    # If budget is 0, no projection needed
    if compare_float "$budget" "==" "0"; then
        echo "No budget limit set"
        return 0
    fi

    # Calculate projection based on current rate
    local current_hour current_day
    current_hour=$(date +%H)
    current_day=$(date +%d)

    if [[ "$budget_type" == "daily" ]]; then
        # Project to end of day
        local hours_elapsed=$((10#$current_hour + 1))
        local hours_remaining=$((24 - hours_elapsed))

        if (( hours_elapsed == 0 )); then
            printf "Projected: \$%s (just started)" "$(format_cost $spent)"
            return 0
        fi

        local rate_per_hour
        rate_per_hour=$(safe_bc "scale=6; $spent / $hours_elapsed")

        local projected_total
        projected_total=$(safe_bc "scale=2; $rate_per_hour * 24")

        if compare_float "$projected_total" ">" "$budget"; then
            local excess
            excess=$(safe_bc "scale=2; $projected_total - $budget")
            printf "⚠️  Projected: \$%s (will exceed by \$%s)" "$(format_cost $projected_total)" "$(format_cost $excess)"
        else
            printf "✓ Projected: \$%s (under budget)" "$(format_cost $projected_total)"
        fi
    else
        # Project to end of month
        local days_in_month
        if [[ "$OSTYPE" == "darwin"* ]]; then
            days_in_month=$(date -v1d -v+1m -v-1d +%d 2>/dev/null || echo "30")
        else
            days_in_month=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%d 2>/dev/null || echo "30")
        fi

        local days_elapsed=$((10#$current_day))

        if (( days_elapsed == 0 )); then
            printf "Projected: \$%s (just started)" "$(format_cost $spent)"
            return 0
        fi

        local rate_per_day
        rate_per_day=$(safe_bc "scale=6; $spent / $days_elapsed")

        local projected_total
        projected_total=$(safe_bc "scale=2; $rate_per_day * $days_in_month")

        if compare_float "$projected_total" ">" "$budget"; then
            local excess
            excess=$(safe_bc "scale=2; $projected_total - $budget")
            printf "⚠️  Projected: \$%s (will exceed by \$%s)" "$(format_cost $projected_total)" "$(format_cost $excess)"
        else
            printf "✓ Projected: \$%s (under budget)" "$(format_cost $projected_total)"
        fi
    fi
}

# ============================================================================
# Budget Display
# ============================================================================

# Show budget summary
show_budget_summary() {
    _themed_hr
    echo "  💰 Budget Status"
    _themed_hr
    echo ""

    # Daily budget
    local daily_budget
    daily_budget=$(clean_number "${CONFIG_DAILY_BUDGET}")

    if compare_float "$daily_budget" ">" "0"; then
        echo "Daily Budget:"
        local status
        status=$(get_budget_status "daily")
        read -r percentage spent budget <<< "$status"

        percentage=$(clean_number "$percentage")
        spent=$(clean_number "$spent")
        budget=$(clean_number "$budget")

        local indicator
        indicator=$(get_budget_indicator "$percentage")

        printf "  %s Spent: \$%s / \$%s (%.1f%%)\n" "$indicator" "$(format_cost $spent)" "$(format_cost $budget)" "$percentage"

        # Progress bar
        local bar_width=30
        local filled
        filled=$(safe_bc "scale=0; ($percentage * $bar_width) / 100")
        filled=$(clean_number "$filled")
        filled=$((filled > bar_width ? bar_width : filled))
        local empty=$((bar_width - filled))

        echo -n "  ["
        if (( filled > 0 )); then
            printf "${THEME_WARNING}█%.0s${COLOR_RESET}" $(seq 1 "$filled") 2>/dev/null
        fi
        if (( empty > 0 )); then
            printf "░%.0s" $(seq 1 "$empty") 2>/dev/null
        fi
        echo "]"

        # Projection
        echo "  $(project_budget "daily")"

        # Alert if needed
        if should_alert "$percentage"; then
            echo "  $(get_budget_message "$percentage")"
        fi
        echo ""
    else
        echo "Daily Budget: Not set (unlimited)"
        echo ""
    fi

    # Monthly budget
    local monthly_budget
    monthly_budget=$(clean_number "${CONFIG_MONTHLY_BUDGET}")

    if compare_float "$monthly_budget" ">" "0"; then
        echo "Monthly Budget:"
        local status
        status=$(get_budget_status "monthly")
        read -r percentage spent budget <<< "$status"

        percentage=$(clean_number "$percentage")
        spent=$(clean_number "$spent")
        budget=$(clean_number "$budget")

        local indicator
        indicator=$(get_budget_indicator "$percentage")

        printf "  %s Spent: \$%s / \$%s (%.1f%%)\n" "$indicator" "$(format_cost $spent)" "$(format_cost $budget)" "$percentage"

        # Progress bar
        local bar_width=30
        local filled
        filled=$(safe_bc "scale=0; ($percentage * $bar_width) / 100")
        filled=$(clean_number "$filled")
        filled=$((filled > bar_width ? bar_width : filled))
        local empty=$((bar_width - filled))

        echo -n "  ["
        if (( filled > 0 )); then
            printf "${THEME_WARNING}█%.0s${COLOR_RESET}" $(seq 1 "$filled") 2>/dev/null
        fi
        if (( empty > 0 )); then
            printf "░%.0s" $(seq 1 "$empty") 2>/dev/null
        fi
        echo "]"

        # Projection
        echo "  $(project_budget "monthly")"

        # Alert if needed
        if should_alert "$percentage"; then
            echo "  $(get_budget_message "$percentage")"
        fi
        echo ""
    else
        echo "Monthly Budget: Not set (unlimited)"
        echo ""
    fi

    _themed_hr
}

log_debug "Budget tracking loaded"
