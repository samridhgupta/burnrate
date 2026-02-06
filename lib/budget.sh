#!/usr/bin/env bash
# lib/budget.sh - Budget tracking and alerts
# Track spending against daily/monthly budgets

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/pricing.sh"
source "$LIB_DIR/stats.sh"

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
        cat > "$state_file" <<EOF
{
  "daily": {
    "date": "$(date +%Y-%m-%d)",
    "spent": 0.0,
    "budget": ${CONFIG_DAILY_BUDGET}
  },
  "monthly": {
    "month": "$(date +%Y-%m)",
    "spent": 0.0,
    "budget": ${CONFIG_MONTHLY_BUDGET}
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

    local state_file
    state_file=$(get_budget_state_file)

    cat > "$state_file" <<EOF
{
  "daily": {
    "date": "$(date +%Y-%m-%d)",
    "spent": $daily_spent,
    "budget": ${CONFIG_DAILY_BUDGET}
  },
  "monthly": {
    "month": "$(date +%Y-%m)",
    "spent": $monthly_spent,
    "budget": ${CONFIG_MONTHLY_BUDGET}
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
    breakdown=$(get_usage_breakdown "$CONFIG_STATS_FILE")

    # Extract total cost
    local costs_section
    costs_section=$(echo "$breakdown" | sed -n '/"costs":/,/}/p')

    local total_cost
    total_cost=$(echo "$costs_section" | grep '"total"' | cut -d: -f2 | tr -d ' ,')

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
    state_date=$(echo "$state" | grep '"date"' | cut -d'"' -f4)
    state_month=$(echo "$state" | grep '"month"' | cut -d'"' -f4)

    local daily_spent monthly_spent

    # Reset daily if new day
    if [[ "$current_date" != "$state_date" ]]; then
        log_debug "New day detected, resetting daily budget"
        daily_spent=0.0
    else
        daily_spent=$(echo "$state" | grep -A1 '"daily"' | grep '"spent"' | cut -d: -f2 | tr -d ' ,')
    fi

    # Reset monthly if new month
    if [[ "$current_month" != "$state_month" ]]; then
        log_debug "New month detected, resetting monthly budget"
        monthly_spent=0.0
    else
        monthly_spent=$(echo "$state" | grep -A1 '"monthly"' | grep '"spent"' | cut -d: -f2 | tr -d ' ,')
    fi

    echo "$daily_spent $monthly_spent"
}

# Calculate spending for current period
calculate_spending() {
    local current_cost
    current_cost=$(get_current_cost)

    local state
    state=$(read_budget_state)

    local last_cost
    last_cost=$(echo "$state" | grep '"last_cost"' | cut -d: -f2 | tr -d ' ,')

    # Calculate delta (new spending since last check)
    local delta
    delta=$(echo "scale=6; $current_cost - $last_cost" | bc)

    # Handle negative delta (stats reset)
    if (( $(echo "$delta < 0" | bc -l) )); then
        delta=0
    fi

    # Get current spent amounts
    local spent
    spent=$(check_and_reset_budgets)
    read -r daily_spent monthly_spent <<< "$spent"

    # Add delta to spent
    daily_spent=$(echo "scale=6; $daily_spent + $delta" | bc)
    monthly_spent=$(echo "scale=6; $monthly_spent + $delta" | bc)

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

    local spent budget
    if [[ "$budget_type" == "daily" ]]; then
        spent="$daily_spent"
        budget="${CONFIG_DAILY_BUDGET}"
    else
        spent="$monthly_spent"
        budget="${CONFIG_MONTHLY_BUDGET}"
    fi

    # If budget is 0, return 0% (no limit)
    if (( $(echo "$budget == 0" | bc -l) )); then
        echo "0 $spent $budget"
        return 0
    fi

    # Calculate percentage
    local percentage
    percentage=$(echo "scale=2; ($spent * 100) / $budget" | bc)

    echo "$percentage $spent $budget"
}

# Get budget status indicator (emoji/text)
get_budget_indicator() {
    local percentage="$1"

    if (( $(echo "$percentage >= 100" | bc -l) )); then
        echo "${THEME_BUDGET_EXCEEDED}"
    elif (( $(echo "$percentage >= ${CONFIG_BUDGET_ALERT}" | bc -l) )); then
        echo "${THEME_BUDGET_CRITICAL}"
    elif (( $(echo "$percentage >= 75" | bc -l) )); then
        echo "${THEME_BUDGET_WARNING}"
    else
        echo "${THEME_BUDGET_SAFE}"
    fi
}

# Get budget message
get_budget_message() {
    local percentage="$1"

    if (( $(echo "$percentage >= 100" | bc -l) )); then
        echo "${THEME_BUDGET_MSG_EXCEEDED}"
    elif (( $(echo "$percentage >= ${CONFIG_BUDGET_ALERT}" | bc -l) )); then
        echo "${THEME_BUDGET_MSG_CRITICAL}"
    elif (( $(echo "$percentage >= 75" | bc -l) )); then
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

    if (( $(echo "$percentage >= $threshold" | bc -l) )); then
        return 0
    else
        return 1
    fi
}

# Trigger budget alert
trigger_alert() {
    local budget_type="$1"
    local percentage="$2"
    local spent="$3"
    local budget="$4"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🚨 BUDGET ALERT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Budget Type: $(echo "$budget_type" | tr '[:lower:]' '[:upper:]')"
    echo "Spent: \$$(format_cost "$spent")"
    echo "Budget: \$$(format_cost "$budget")"
    echo "Used: ${percentage}%"
    echo ""
    echo "$(get_budget_message "$percentage")"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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

    # If budget is 0, no projection needed
    if (( $(echo "$budget == 0" | bc -l) )); then
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
            echo "Projected: \$$(format_cost "$spent") (just started)"
            return 0
        fi

        local rate_per_hour
        rate_per_hour=$(echo "scale=6; $spent / $hours_elapsed" | bc)

        local projected_total
        projected_total=$(echo "scale=2; $rate_per_hour * 24" | bc)

        if (( $(echo "$projected_total > $budget" | bc -l) )); then
            echo "⚠️  Projected: \$$(format_cost "$projected_total") (will exceed by \$$(format_cost "$(echo "$projected_total - $budget" | bc)"))"
        else
            echo "✓ Projected: \$$(format_cost "$projected_total") (under budget)"
        fi
    else
        # Project to end of month
        local days_in_month
        days_in_month=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%d 2>/dev/null || echo 30)

        local days_elapsed=$((10#$current_day))

        if (( days_elapsed == 0 )); then
            echo "Projected: \$$(format_cost "$spent") (just started)"
            return 0
        fi

        local rate_per_day
        rate_per_day=$(echo "scale=6; $spent / $days_elapsed" | bc)

        local projected_total
        projected_total=$(echo "scale=2; $rate_per_day * $days_in_month" | bc)

        if (( $(echo "$projected_total > $budget" | bc -l) )); then
            echo "⚠️  Projected: \$$(format_cost "$projected_total") (will exceed by \$$(format_cost "$(echo "$projected_total - $budget" | bc)"))"
        else
            echo "✓ Projected: \$$(format_cost "$projected_total") (under budget)"
        fi
    fi
}

# ============================================================================
# Budget Display
# ============================================================================

# Show budget summary
show_budget_summary() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  💰 Budget Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Daily budget
    if (( $(echo "${CONFIG_DAILY_BUDGET} > 0" | bc -l) )); then
        echo "Daily Budget:"
        local status
        status=$(get_budget_status "daily")
        read -r percentage spent budget <<< "$status"

        local indicator
        indicator=$(get_budget_indicator "$percentage")

        printf "  %s Spent: \$%.2f / \$%.2f (%.1f%%)\n" "$indicator" "$spent" "$budget" "$percentage"

        # Progress bar
        local bar_width=30
        local filled
        filled=$(echo "scale=0; ($percentage * $bar_width) / 100" | bc)
        filled=$(( filled > bar_width ? bar_width : filled ))
        local empty=$((bar_width - filled))

        echo -n "  ["
        printf "${THEME_WARNING}█%.0s${COLOR_RESET}" $(seq 1 $filled) 2>/dev/null
        printf "░%.0s" $(seq 1 $empty) 2>/dev/null
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
    if (( $(echo "${CONFIG_MONTHLY_BUDGET} > 0" | bc -l) )); then
        echo "Monthly Budget:"
        local status
        status=$(get_budget_status "monthly")
        read -r percentage spent budget <<< "$status"

        local indicator
        indicator=$(get_budget_indicator "$percentage")

        printf "  %s Spent: \$%.2f / \$%.2f (%.1f%%)\n" "$indicator" "$spent" "$budget" "$percentage"

        # Progress bar
        local bar_width=30
        local filled
        filled=$(echo "scale=0; ($percentage * $bar_width) / 100" | bc)
        filled=$(( filled > bar_width ? bar_width : filled ))
        local empty=$((bar_width - filled))

        echo -n "  ["
        printf "${THEME_WARNING}█%.0s${COLOR_RESET}" $(seq 1 $filled) 2>/dev/null
        printf "░%.0s" $(seq 1 $empty) 2>/dev/null
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

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

log_debug "Budget tracking loaded"
