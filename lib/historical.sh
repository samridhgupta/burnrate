#!/usr/bin/env bash
# lib/historical.sh - Historical token usage tracking
# Parse dailyModelTokens from stats-cache.json for trends and aggregates

[[ -n "${BURNRATE_HISTORICAL_LOADED:-}" ]] && return 0
readonly BURNRATE_HISTORICAL_LOADED=1

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/stats.sh"
source "$LIB_DIR/pricing.sh"
source "$LIB_DIR/date-utils.sh"

# Get daily token history from stats file
# Returns: Array of "date:model:tokens" entries
get_daily_history() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"

    [[ ! -f "$stats_file" ]] && return 1

    local content
    content=$(cat "$stats_file")

    # Extract dailyModelTokens array
    local daily_section
    daily_section=$(echo "$content" | sed -n '/"dailyModelTokens":/,/^  \]/p')

    [[ -z "$daily_section" ]] && return 1

    # Parse each daily entry (bash 3 compatible - no awk regex captures)
    local current_date=""
    while IFS= read -r line; do
        if echo "$line" | grep -q '"date"'; then
            current_date=$(echo "$line" | grep -o '"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"' | tr -d '"')
        elif echo "$line" | grep -q '"claude-'; then
            local model tokens
            model=$(echo "$line" | grep -o '"claude-[^"]*"' | tr -d '"')
            tokens=$(echo "$line" | grep -o '[0-9]*$' | grep -o '[0-9]*')
            if [[ -n "$current_date" && -n "$model" && -n "$tokens" ]]; then
                echo "$current_date:$model:$tokens"
            fi
        fi
    done <<< "$(echo "$daily_section" | grep -E '"date"|"claude-')"
}

# Calculate daily cost from tokens
# Args: tokens, model_name
# Returns: cost in dollars
calculate_daily_cost() {
    local tokens="$1"
    local model="${2:-claude-sonnet-4-5}"

    # Validate input
    [[ -z "$tokens" || "$tokens" == "0" ]] && echo "0.00" && return 0

    # Get cumulative usage to estimate proportions
    local usage_json
    usage_json=$(get_usage_breakdown 2>/dev/null)

    [[ -z "$usage_json" ]] && echo "0.00" && return 0

    # Extract cumulative totals from JSON (pure bash parsing)
    local total_input total_output total_cache_write total_cache_read
    total_input=$(echo "$usage_json" | grep '"input"' | head -1 | grep -o '[0-9]*' | head -1)
    total_output=$(echo "$usage_json" | grep '"output"' | head -1 | grep -o '[0-9]*' | head -1)
    total_cache_write=$(echo "$usage_json" | grep '"cache_write"' | head -1 | grep -o '[0-9]*' | head -1)
    total_cache_read=$(echo "$usage_json" | grep '"cache_read"' | head -1 | grep -o '[0-9]*' | head -1)

    # Default to 0 if empty
    total_input=${total_input:-0}
    total_output=${total_output:-0}
    total_cache_write=${total_cache_write:-0}
    total_cache_read=${total_cache_read:-0}

    # Calculate total and proportions
    local total_tokens_cumulative
    total_tokens_cumulative=$(echo "$total_input + $total_output + $total_cache_write + $total_cache_read" | bc 2>/dev/null || echo "0")

    if [[ "$total_tokens_cumulative" == "0" || -z "$total_tokens_cumulative" ]]; then
        echo "0.00"
        return 0
    fi

    # Estimate token type breakdown based on cumulative proportions
    local prop_input prop_output prop_cache_write prop_cache_read
    prop_input=$(echo "scale=6; $total_input / $total_tokens_cumulative" | bc 2>/dev/null || echo "0")
    prop_output=$(echo "scale=6; $total_output / $total_tokens_cumulative" | bc 2>/dev/null || echo "0")
    prop_cache_write=$(echo "scale=6; $total_cache_write / $total_tokens_cumulative" | bc 2>/dev/null || echo "0")
    prop_cache_read=$(echo "scale=6; $total_cache_read / $total_tokens_cumulative" | bc 2>/dev/null || echo "0")

    # Apply proportions to daily tokens
    local daily_input daily_output daily_cache_write daily_cache_read
    daily_input=$(echo "scale=0; $tokens * $prop_input / 1" | bc 2>/dev/null || echo "0")
    daily_output=$(echo "scale=0; $tokens * $prop_output / 1" | bc 2>/dev/null || echo "0")
    daily_cache_write=$(echo "scale=0; $tokens * $prop_cache_write / 1" | bc 2>/dev/null || echo "0")
    daily_cache_read=$(echo "scale=0; $tokens * $prop_cache_read / 1" | bc 2>/dev/null || echo "0")

    # Calculate cost using pricing (returns JSON)
    local cost_json
    cost_json=$(calculate_cost "$daily_input" "$daily_output" "$daily_cache_write" "$daily_cache_read" "$model" 2>/dev/null)

    # Extract total from JSON
    local cost
    cost=$(echo "$cost_json" | grep '"total"' | grep -o '[0-9.]*' | head -1)
    cost=${cost:-0.00}

    # Format to configured decimal places
    format_cost "$cost"
}

# Get daily breakdown with dates, tokens, and costs
# Returns: Multi-line "date|model|tokens|cost"
get_daily_breakdown() {
    local history
    history=$(get_daily_history)

    [[ -z "$history" ]] && return 1

    while IFS=: read -r date model tokens; do
        local cost
        cost=$(calculate_daily_cost "$tokens" "$model")
        echo "$date|$model|$tokens|$cost"
    done <<< "$history"
}

# Get aggregate for a date range
# Args: start_date end_date
# Returns: total_tokens|total_cost
get_date_range_aggregate() {
    local start_date="$1"
    local end_date="$2"

    local breakdown
    breakdown=$(get_daily_breakdown)

    [[ -z "$breakdown" ]] && echo "0|0.00" && return 0

    local total_tokens=0
    local total_cost=0

    while IFS='|' read -r date model tokens cost; do
        # Check if date is in range (string comparison works for YYYY-MM-DD format)
        if [[ "$date" > "$start_date" || "$date" == "$start_date" ]] && \
           [[ "$date" < "$end_date" || "$date" == "$end_date" ]]; then
            # Skip if values are empty
            [[ -z "$tokens" || -z "$cost" ]] && continue
            total_tokens=$(echo "$total_tokens + $tokens" | bc 2>/dev/null || echo "$total_tokens")
            total_cost=$(echo "scale=2; $total_cost + $cost" | bc 2>/dev/null || echo "$total_cost")
        fi
    done <<< "$breakdown"

    # Format output
    total_tokens=${total_tokens:-0}
    total_cost=${total_cost:-0.00}

    echo "$total_tokens|$total_cost"
}

# Get this week's aggregate (Monday to Sunday)
get_week_aggregate() {
    local today monday
    today=$(get_current_date)
    monday=$(get_monday_of_week)

    get_date_range_aggregate "$monday" "$today"
}

# Get this month's aggregate
get_month_aggregate() {
    local today first_of_month
    today=$(get_current_date)
    first_of_month=$(get_first_day_of_month)

    get_date_range_aggregate "$first_of_month" "$today"
}

# Get last N days aggregate
# Args: days
get_last_n_days_aggregate() {
    local days="$1"

    local today start_date
    today=$(get_current_date)
    start_date=$(get_date_days_ago "$days")

    get_date_range_aggregate "$start_date" "$today"
}

# Format daily breakdown for display
# Args: format (table|json|csv)
format_daily_breakdown() {
    local format="${1:-table}"

    local breakdown
    breakdown=$(get_daily_breakdown)

    [[ -z "$breakdown" ]] && return 1

    case "$format" in
        table)
            # Responsive column widths based on terminal width
            # date=10, model varies, tokens=11 ("740,107,049"), cost=7 ("$449.97")
            local tw
            tw=$(term_width)
            local t_date t_model t_tokens t_cost show_model=true
            if (( tw >= 75 )); then
                t_date=12; t_model=22; t_tokens=13; t_cost=10
            elif (( tw >= 60 )); then
                t_date=12; t_model=14; t_tokens=12; t_cost=10
            elif (( tw >= 48 )); then
                t_date=10; t_model=11; t_tokens=11; t_cost=9
            else
                # Drop model column entirely on very narrow terminals
                t_date=10; t_model=0;  t_tokens=11; t_cost=9; show_model=false
            fi

            # Build separator strings
            local sd sm st sc
            # shellcheck disable=SC2046
            sd="$(printf '─%.0s' $(seq 1 "$t_date"))"
            # shellcheck disable=SC2046
            [[ "$show_model" == "true" ]] && sm="$(printf '─%.0s' $(seq 1 "$t_model"))"
            # shellcheck disable=SC2046
            st="$(printf '─%.0s' $(seq 1 "$t_tokens"))"
            # shellcheck disable=SC2046
            sc="$(printf '─%.0s' $(seq 1 "$t_cost"))"

            local d="\033[2m" r="\033[0m"
            if [[ "$show_model" == "true" ]]; then
                printf "${d}%-${t_date}s  %-${t_model}s  %${t_tokens}s  %${t_cost}s${r}\n" "DATE" "MODEL" "TOKENS" "COST"
                printf "${d}%-${t_date}s  %-${t_model}s  %${t_tokens}s  %${t_cost}s${r}\n" "$sd" "$sm" "$st" "$sc"
            else
                printf "${d}%-${t_date}s  %${t_tokens}s  %${t_cost}s${r}\n" "DATE" "TOKENS" "COST"
                printf "${d}%-${t_date}s  %${t_tokens}s  %${t_cost}s${r}\n" "$sd" "$st" "$sc"
            fi

            while IFS='|' read -r date model tokens cost; do
                local short_model
                short_model=$(echo "$model" | sed 's/claude-//; s/-20[0-9]*$//')
                # Truncate model name to fit column when narrow
                if [[ "$show_model" == "true" ]] && (( ${#short_model} > t_model )); then
                    short_model="${short_model:0:$((t_model - 1))}…"
                fi
                if [[ "$show_model" == "true" ]]; then
                    printf "%-${t_date}s  %-${t_model}s  %${t_tokens}s  %${t_cost}s\n" \
                        "$date" "$short_model" \
                        "$(printf "%'d" "$tokens" 2>/dev/null || echo "$tokens")" \
                        "\$$(printf "%.2f" "$cost" 2>/dev/null || echo "$cost")"
                else
                    printf "%-${t_date}s  %${t_tokens}s  %${t_cost}s\n" \
                        "$date" \
                        "$(printf "%'d" "$tokens" 2>/dev/null || echo "$tokens")" \
                        "\$$(printf "%.2f" "$cost" 2>/dev/null || echo "$cost")"
                fi
            done <<< "$breakdown"
            ;;

        json)
            echo "["
            local first=true
            while IFS='|' read -r date model tokens cost; do
                [[ "$first" == "false" ]] && echo ","
                first=false
                cat <<-EOF
				  {
				    "date": "$date",
				    "model": "$model",
				    "tokens": $tokens,
				    "cost": $cost
				  }
				EOF
            done <<< "$breakdown"
            echo "]"
            ;;

        csv)
            echo "date,model,tokens,cost"
            while IFS='|' read -r date model tokens cost; do
                echo "$date,$model,$tokens,$cost"
            done <<< "$breakdown"
            ;;
    esac
}

# Get spending trend (comparing periods)
# Returns: previous_week|current_week|change_percent
get_spending_trend() {
    # This week
    local this_week
    this_week=$(get_week_aggregate)
    local this_week_cost
    this_week_cost=$(echo "$this_week" | cut -d'|' -f2)

    # Last week (7-13 days ago)
    local last_week_start last_week_end
    last_week_start=$(get_date_days_ago 13)
    last_week_end=$(get_date_days_ago 7)

    local last_week
    last_week=$(get_date_range_aggregate "$last_week_start" "$last_week_end")
    local last_week_cost
    last_week_cost=$(echo "$last_week" | cut -d'|' -f2)

    # Calculate change
    local change_percent
    if [[ "$last_week_cost" == "0" || "$last_week_cost" == "0.00" ]]; then
        change_percent="N/A"
    else
        change_percent=$(echo "scale=1; ($this_week_cost - $last_week_cost) / $last_week_cost * 100" | bc 2>/dev/null || echo "0")
    fi

    echo "$last_week_cost|$this_week_cost|$change_percent"
}

# Show historical summary
show_historical_summary() {
    echo "📅 Historical Token Usage"
    echo ""

    # Last 7 days
    local last_7
    last_7=$(get_last_n_days_aggregate 7)
    local last_7_tokens last_7_cost
    last_7_tokens=$(echo "$last_7" | cut -d'|' -f1)
    last_7_cost=$(echo "$last_7" | cut -d'|' -f2)

    printf "Last 7 days:  %15s tokens    \$%s\n" \
        "$(printf "%'d" "$last_7_tokens" 2>/dev/null || echo "$last_7_tokens")" \
        "$last_7_cost"

    # This week
    local this_week
    this_week=$(get_week_aggregate)
    local week_tokens week_cost
    week_tokens=$(echo "$this_week" | cut -d'|' -f1)
    week_cost=$(echo "$this_week" | cut -d'|' -f2)

    printf "This week:    %15s tokens    \$%s\n" \
        "$(printf "%'d" "$week_tokens" 2>/dev/null || echo "$week_tokens")" \
        "$week_cost"

    # This month
    local this_month
    this_month=$(get_month_aggregate)
    local month_tokens month_cost
    month_tokens=$(echo "$this_month" | cut -d'|' -f1)
    month_cost=$(echo "$this_month" | cut -d'|' -f2)

    printf "This month:   %15s tokens    \$%s\n" \
        "$(printf "%'d" "$month_tokens" 2>/dev/null || echo "$month_tokens")" \
        "$month_cost"

    # Trend
    local trend
    trend=$(get_spending_trend)
    local last_w this_w change
    last_w=$(echo "$trend" | cut -d'|' -f1)
    this_w=$(echo "$trend" | cut -d'|' -f2)
    change=$(echo "$trend" | cut -d'|' -f3)

    echo ""
    echo "📈 Weekly Trend"
    printf "Last week:    \$%s\n" "$last_w"
    printf "This week:    \$%s" "$this_w"

    if [[ "$change" != "N/A" ]]; then
        local sign=""
        if echo "$change" | grep -q "^-"; then
            sign=""  # Already has minus
            echo " (${change}% 📉)"
        else
            sign="+"
            echo " (${sign}${change}% 📈)"
        fi
    else
        echo " (first week)"
    fi
}
