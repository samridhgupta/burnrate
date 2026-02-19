#!/usr/bin/env bash
# lib/stats.sh - Parse Claude stats-cache.json
# Extracts token usage and costs by model

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/pricing.sh"
source "$LIB_DIR/charts.sh"

# ============================================================================
# Stats File Parsing (Pure Bash - No jq!)
# ============================================================================

# Extract JSON value by key (simple parser)
json_value() {
    local json="$1"
    local key="$2"

    # Extract value using grep and sed
    echo "$json" | grep -o "\"$key\"[[:space:]]*:[[:space:]]*[^,}]*" | sed 's/.*:[[:space:]]*//' | tr -d '"'
}

# Extract nested JSON value
json_nested_value() {
    local json="$1"
    local path="$2"  # e.g., "usage.input_tokens"

    # Split path
    local parts
    IFS='.' read -ra parts <<< "$path"

    local current="$json"
    local part
    for part in "${parts[@]}"; do
        current=$(json_value "$current" "$part")
    done

    echo "$current"
}

# ============================================================================
# Stats File Reading
# ============================================================================

# Read stats file
read_stats_file() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"

    if [[ ! -f "$stats_file" ]]; then
        die "Stats file not found: $stats_file"
    fi

    cat "$stats_file"
}

# ============================================================================
# Token Usage Extraction
# ============================================================================

# Get total tokens from stats
get_total_tokens() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"

    if [[ ! -f "$stats_file" ]]; then
        echo "0 0 0 0"  # input output cache_write cache_read
        return 1
    fi

    local content
    content=$(cat "$stats_file")

    # Extract token counts (try both field name formats)
    local input_tokens
    input_tokens=$(echo "$content" | grep -o '"inputTokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
    if [[ "$input_tokens" == "0" ]]; then
        input_tokens=$(echo "$content" | grep -o '"input_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
    fi

    local output_tokens
    output_tokens=$(echo "$content" | grep -o '"outputTokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
    if [[ "$output_tokens" == "0" ]]; then
        output_tokens=$(echo "$content" | grep -o '"output_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
    fi

    local cache_creation_tokens
    cache_creation_tokens=$(echo "$content" | grep -o '"cacheCreationInputTokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
    if [[ "$cache_creation_tokens" == "0" ]]; then
        cache_creation_tokens=$(echo "$content" | grep -o '"cache_creation_input_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
    fi

    local cache_read_tokens
    cache_read_tokens=$(echo "$content" | grep -o '"cacheReadInputTokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
    if [[ "$cache_read_tokens" == "0" ]]; then
        cache_read_tokens=$(echo "$content" | grep -o '"cache_read_input_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$' || echo "0")
    fi

    echo "$input_tokens $output_tokens $cache_creation_tokens $cache_read_tokens"
}

# Get model name from stats
get_model_from_stats() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"

    if [[ ! -f "$stats_file" ]]; then
        echo "sonnet"
        return 1
    fi

    local content
    content=$(cat "$stats_file")

    # Extract model name
    local model
    model=$(echo "$content" | grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4 || echo "sonnet")

    echo "$model"
}

# ============================================================================
# Usage Breakdown
# ============================================================================

# Get usage breakdown with costs
get_usage_breakdown() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"

    if [[ ! -f "$stats_file" ]]; then
        echo "{\"error\": \"Stats file not found\"}"
        return 1
    fi

    # Get tokens
    local tokens
    tokens=$(get_total_tokens "$stats_file")
    read -r input_tokens output_tokens cache_write cache_read <<< "$tokens"

    # Get model
    local model
    model=$(get_model_from_stats "$stats_file")

    # Calculate costs
    local cost_json
    cost_json=$(calculate_cost "$input_tokens" "$output_tokens" "$cache_write" "$cache_read" "$model")

    # Extract total cost
    local total_cost
    total_cost=$(echo "$cost_json" | grep '"total"' | cut -d: -f2 | tr -d ' ,')

    # Build breakdown JSON
    cat <<EOF
{
  "model": "$model",
  "model_friendly": "$(get_friendly_model_name "$model")",
  "tokens": {
    "input": $input_tokens,
    "output": $output_tokens,
    "cache_write": $cache_write,
    "cache_read": $cache_read,
    "total": $((input_tokens + output_tokens + cache_write + cache_read))
  },
  "costs": $cost_json
}
EOF
}

# ============================================================================
# Cache Efficiency Metrics
# ============================================================================

# Calculate cache efficiency
get_cache_efficiency() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"

    local tokens
    tokens=$(get_total_tokens "$stats_file")
    read -r input_tokens output_tokens cache_write cache_read <<< "$tokens"

    # Calculate cache hit ratio
    local total_cache=$((cache_write + cache_read))
    if (( total_cache == 0 )); then
        echo "0"
        return 0
    fi

    local hit_ratio
    hit_ratio=$(echo "scale=2; ($cache_read * 100) / $total_cache" | bc)

    echo "$hit_ratio"
}

# Calculate cache savings
get_cache_savings() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"
    local model="${2:-sonnet}"

    local tokens
    tokens=$(get_total_tokens "$stats_file")
    read -r input_tokens output_tokens cache_write cache_read <<< "$tokens"

    # Get pricing
    local cache_write_price cache_read_price
    cache_write_price=$(get_model_price "$model" "cache_write")
    cache_read_price=$(get_model_price "$model" "cache_read")

    # Calculate what cache reads would have cost without caching
    local input_price
    input_price=$(get_model_price "$model" "input")

    local without_cache_cost
    without_cache_cost=$(echo "scale=6; ($cache_read / 1000000) * $input_price" | bc)

    local with_cache_cost
    with_cache_cost=$(echo "scale=6; ($cache_read / 1000000) * $cache_read_price" | bc)

    local savings
    savings=$(echo "scale=6; $without_cache_cost - $with_cache_cost" | bc)

    echo "$savings"
}

# ============================================================================
# Summary Display
# ============================================================================

# Show simple summary
show_summary() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"

    local breakdown
    breakdown=$(get_usage_breakdown "$stats_file")

    local model
    model=$(echo "$breakdown" | grep '"model_friendly"' | cut -d'"' -f4)

    local total_tokens
    local tokens_section
    tokens_section=$(echo "$breakdown" | sed -n '/"tokens":/,/}/p')
    total_tokens=$(echo "$tokens_section" | grep '"total"' | grep -o '[0-9]*' | head -1)

    local total_cost
    local costs_section
    costs_section=$(echo "$breakdown" | sed -n '/"costs":/,/}/p')
    total_cost=$(echo "$costs_section" | grep '"total"' | grep -o '[0-9.]*' | head -1)
    total_cost=$(clean_number "${total_cost:-0}")

    local cache_efficiency
    cache_efficiency=$(get_cache_efficiency "$stats_file")

    # Color-code cache efficiency using theme levels
    local cache_icon cache_color cache_label reset="\033[0m"
    local ce_int
    ce_int=$(echo "$cache_efficiency" | cut -d. -f1)
    if [[ "$ce_int" -ge 90 ]]; then
        cache_icon="${THEME_CACHE_EXCELLENT:-❄️ }"
        cache_color="${THEME_SUCCESS:-\033[0;36m}"
        cache_label="excellent"
    elif [[ "$ce_int" -ge 75 ]]; then
        cache_icon="${THEME_CACHE_GOOD:-🧊}"
        cache_color="${THEME_SUCCESS:-\033[0;36m}"
        cache_label="good"
    elif [[ "$ce_int" -ge 50 ]]; then
        cache_icon="${THEME_STATUS_WARNING:-💧}"
        cache_color="${THEME_WARNING:-\033[0;33m}"
        cache_label="ok"
    elif [[ "$ce_int" -ge 25 ]]; then
        cache_icon="${THEME_STATUS_CRITICAL:-🌊}"
        cache_color="${THEME_WARNING:-\033[0;33m}"
        cache_label="low"
    else
        cache_icon="${THEME_CACHE_POOR:-🔥}"
        cache_color="${THEME_ERROR:-\033[0;31m}"
        cache_label="poor — consider caching more!"
    fi

    echo "Model:  $model"
    echo "Tokens: $(format_number $total_tokens)"
    echo "Cost:   \$$(format_cost $total_cost)"
    echo -e "Cache:  ${cache_color}${cache_icon} ${cache_efficiency}% hit rate (${cache_label})${reset}"

    # Budget remaining — only show if budgets are configured
    local daily_budget monthly_budget
    daily_budget=$(echo "${CONFIG_DAILY_BUDGET:-0}" | tr -d '$, ')
    monthly_budget=$(echo "${CONFIG_MONTHLY_BUDGET:-0}" | tr -d '$, ')
    local alert_pct="${CONFIG_BUDGET_ALERT:-90}"

    # Budget display helper — uses loaded theme variables when available
    _budget_line() {
        local label="$1" budget="$2" spent="$3"
        [[ $(echo "$budget > 0" | bc 2>/dev/null) != "1" ]] && return

        local remaining pct
        remaining=$(printf "%.2f" "$(echo "scale=2; $budget - $spent" | bc 2>/dev/null || echo "0")")
        pct=$(printf "%.1f" "$(echo "scale=1; $spent / $budget * 100" | bc 2>/dev/null || echo "0")")
        local pct_int
        pct_int=$(echo "$pct" | cut -d. -f1)

        local reset="\033[0m"

        # Pick icon + color + message from theme (with plain fallbacks)
        local icon color msg
        if [[ "$pct_int" -ge 100 ]]; then
            icon="${THEME_BUDGET_EXCEEDED:-💥}"
            color="${THEME_ERROR:-\033[0;31m}"
            msg="${THEME_BUDGET_MSG_EXCEEDED:-Over budget!}"
        elif [[ "$pct_int" -ge "${alert_pct%.*}" ]]; then
            icon="${THEME_BUDGET_CRITICAL:-🚨}"
            color="${THEME_WARNING:-\033[0;33m}"
            msg="${THEME_BUDGET_MSG_CRITICAL:-Approaching limit}"
        elif [[ "$pct_int" -ge 50 ]]; then
            icon="${THEME_BUDGET_WARNING:-⚠️ }"
            color="${THEME_WARNING:-\033[0;33m}"
            msg="${THEME_BUDGET_MSG_WARNING:-Halfway there}"
        else
            icon="${THEME_BUDGET_SAFE:-🐻‍❄️ }"
            color="${THEME_SUCCESS:-\033[0;32m}"
            msg="${THEME_BUDGET_MSG_OK:-On track}"
        fi

        # Ice-level bar (30 chars wide): filled = spent, empty = remaining
        local bar_width=20
        local filled=0
        if [[ "$pct_int" -ge 100 ]]; then
            filled=$bar_width
        else
            filled=$(echo "$pct_int * $bar_width / 100" | bc 2>/dev/null || echo "0")
        fi
        local empty=$(( bar_width - filled ))

        local fill_char="${THEME_PROGRESS_CHAR:-█}"
        local empty_char="${THEME_EMPTY_CHAR:-░}"
        local bar=""
        local i=0
        while [[ $i -lt $filled ]]; do bar="${bar}${fill_char}"; i=$((i+1)); done
        i=0
        while [[ $i -lt $empty  ]]; do bar="${bar}${empty_char}"; i=$((i+1)); done

        local abs_remaining="${remaining#-}"
        local amount_str
        if [[ $(echo "$remaining < 0" | bc 2>/dev/null) == "1" ]]; then
            amount_str="OVER \$$(format_cost $abs_remaining)"
        else
            amount_str="\$$(format_cost $remaining) left"
        fi

        echo -e "  ${icon} ${label} ${color}[${bar}]${reset} ${color}${amount_str} (${pct}%)${reset}"
        echo -e "         ${color}${msg}${reset}"
    }

    local has_daily=false has_monthly=false
    [[ $(echo "$daily_budget > 0"   | bc 2>/dev/null) == "1" ]] && has_daily=true
    [[ $(echo "$monthly_budget > 0" | bc 2>/dev/null) == "1" ]] && has_monthly=true

    if [[ "$has_daily" == "true" || "$has_monthly" == "true" ]]; then
        echo ""
        _budget_line "Daily  " "$daily_budget"   "$total_cost"
        _budget_line "Monthly" "$monthly_budget" "$total_cost"
    else
        # No budgets — show funny unlimited message from theme
        local unlimited_msg="${THEME_BUDGET_UNLIMITED_BOTH:-♾️  No limits set — you\'re living dangerously! (burnrate config to set budgets)}"
        echo ""
        echo -e "  ${unlimited_msg}"
    fi
}

# Show detailed breakdown
show_detailed_breakdown() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"
    local weekly_trend="${2:-}"   # optional: signed % change from get_spending_trend()

    local breakdown
    breakdown=$(get_usage_breakdown "$stats_file")

    # Parse breakdown (pure bash!)
    local model
    model=$(echo "$breakdown" | grep '"model_friendly"' | cut -d'"' -f4)

    local input_tokens output_tokens cache_write cache_read
    input_tokens=$(echo "$breakdown" | grep '"input"' | head -1 | grep -o '[0-9]*')
    output_tokens=$(echo "$breakdown" | grep '"output"' | head -1 | grep -o '[0-9]*')
    cache_write=$(echo "$breakdown" | grep '"cache_write"' | head -1 | grep -o '[0-9]*')
    cache_read=$(echo "$breakdown" | grep '"cache_read"' | head -1 | grep -o '[0-9]*')

    local input_cost output_cost cache_write_cost cache_read_cost total_cost

    # Extract from costs section (after "costs":)
    local costs_section
    costs_section=$(echo "$breakdown" | sed -n '/"costs":/,/}/p')

    input_cost=$(echo "$costs_section" | grep '"input"' | cut -d: -f2 | tr -d ' ,')
    output_cost=$(echo "$costs_section" | grep '"output"' | cut -d: -f2 | tr -d ' ,')
    cache_write_cost=$(echo "$costs_section" | grep '"cache_write"' | cut -d: -f2 | tr -d ' ,')
    cache_read_cost=$(echo "$costs_section" | grep '"cache_read"' | cut -d: -f2 | tr -d ' ,')
    total_cost=$(echo "$costs_section" | grep '"total"' | cut -d: -f2 | tr -d ' ,')

    # Theme colors
    local h b d r
    h="${THEME_PRIMARY:-\033[1;36m}"
    b="\033[1m"
    d="\033[2m"
    r="\033[0m"

    _themed_hr
    echo -e "  ${h}Token Usage & Cost Breakdown${r}"
    _themed_hr
    echo ""
    echo -e "  Model: ${b}${model}${r}"
    echo ""

    # Responsive column widths based on terminal width
    # Minimum data widths: type=11 ("Cache Write"), tokens=11 ("740,107,049"), cost=7 ("$449.97")
    local tw
    tw=$(term_width)
    local t_type t_tokens t_cost ind
    if (( tw >= 70 )); then
        t_type=20; t_tokens=15; t_cost=12; ind=2   # total visible: 55
    elif (( tw >= 54 )); then
        t_type=14; t_tokens=13; t_cost=10; ind=1   # total visible: 42
    elif (( tw >= 42 )); then
        t_type=12; t_tokens=12; t_cost=9;  ind=0   # total visible: 37
    else
        t_type=0;  t_tokens=0;  t_cost=0;  ind=0   # stacked mode
    fi

    local pad
    pad="$(printf '%*s' "$ind" '')"

    local total_toks=$((input_tokens + output_tokens + cache_write + cache_read))

    if (( t_type > 0 )); then
        # Build separator strings matching each column width exactly
        local sep1 sep2 sep3
        # shellcheck disable=SC2046
        sep1="$(printf '─%.0s' $(seq 1 "$t_type"))"
        # shellcheck disable=SC2046
        sep2="$(printf '─%.0s' $(seq 1 "$t_tokens"))"
        # shellcheck disable=SC2046
        sep3="$(printf '─%.0s' $(seq 1 "$t_cost"))"

        printf "${d}${pad}%-${t_type}s  %${t_tokens}s  %${t_cost}s${r}\n" "Type" "Tokens" "Cost"
        printf "${d}${pad}%-${t_type}s  %${t_tokens}s  %${t_cost}s${r}\n" "$sep1" "$sep2" "$sep3"
        printf "${pad}%-${t_type}s  %${t_tokens}s  %${t_cost}s\n" "Input"       "$(format_number "$input_tokens")"  "\$$(format_cost "$input_cost")"
        printf "${pad}%-${t_type}s  %${t_tokens}s  %${t_cost}s\n" "Output"      "$(format_number "$output_tokens")" "\$$(format_cost "$output_cost")"
        printf "${pad}%-${t_type}s  %${t_tokens}s  %${t_cost}s\n" "Cache Write" "$(format_number "$cache_write")"   "\$$(format_cost "$cache_write_cost")"
        printf "${pad}%-${t_type}s  %${t_tokens}s  %${t_cost}s\n" "Cache Read"  "$(format_number "$cache_read")"    "\$$(format_cost "$cache_read_cost")"
        printf "${d}${pad}%-${t_type}s  %${t_tokens}s  %${t_cost}s${r}\n" "$sep1" "$sep2" "$sep3"
        # TOTAL row — append inline trend badge after cost if available
        echo -en "${b}${pad}$(printf "%-${t_type}s  %${t_tokens}s  %${t_cost}s" \
            "TOTAL" "$(format_number "$total_toks")" "\$$(format_cost "$total_cost")")${r}"
        if [[ -n "$weekly_trend" ]]; then printf "   "; trend_inline "$weekly_trend"; fi
        echo ""
    else
        # Stacked layout for very narrow terminals (<42 cols)
        local _sr
        _sr() { echo -e "${d}$1${r}"; printf "  %-8s  %s\n" "Tokens:" "$2"; printf "  %-8s  %s\n" "Cost:" "$3"; echo ""; }
        _sr "Input"       "$(format_number "$input_tokens")"  "\$$(format_cost "$input_cost")"
        _sr "Output"      "$(format_number "$output_tokens")" "\$$(format_cost "$output_cost")"
        _sr "Cache Write" "$(format_number "$cache_write")"   "\$$(format_cost "$cache_write_cost")"
        _sr "Cache Read"  "$(format_number "$cache_read")"    "\$$(format_cost "$cache_read_cost")"
        echo -e "${d}──────────────────${r}"
        echo -en "${b}TOTAL${r}"
        if [[ -n "$weekly_trend" ]]; then printf "   "; trend_inline "$weekly_trend"; fi
        echo ""
        printf "  %-8s  %s\n" "Tokens:" "$(format_number "$total_toks")"
        printf "  %-8s  %s\n" "Cost:"   "\$$(format_cost "$total_cost")"
    fi
    echo ""

    # Cache efficiency — themed, same treatment as show_summary
    local cache_efficiency
    cache_efficiency=$(get_cache_efficiency "$stats_file")

    local cache_savings
    cache_savings=$(get_cache_savings "$stats_file" "$model")

    local cache_icon cache_color cache_label
    local ce_int
    ce_int=$(echo "$cache_efficiency" | cut -d. -f1)
    if [[ "$ce_int" -ge 90 ]]; then
        cache_icon="${THEME_CACHE_EXCELLENT:-❄️ }"; cache_color="${THEME_SUCCESS:-\033[0;36m}"; cache_label="excellent"
    elif [[ "$ce_int" -ge 75 ]]; then
        cache_icon="${THEME_CACHE_GOOD:-🧊}";       cache_color="${THEME_SUCCESS:-\033[0;36m}"; cache_label="good"
    elif [[ "$ce_int" -ge 50 ]]; then
        cache_icon="${THEME_STATUS_WARNING:-💧}";   cache_color="${THEME_WARNING:-\033[0;33m}"; cache_label="ok"
    elif [[ "$ce_int" -ge 25 ]]; then
        cache_icon="${THEME_STATUS_CRITICAL:-🌊}";  cache_color="${THEME_WARNING:-\033[0;33m}"; cache_label="low"
    else
        cache_icon="${THEME_CACHE_POOR:-🔥}";       cache_color="${THEME_ERROR:-\033[0;31m}";   cache_label="poor"
    fi

    echo -e "  Cache:   ${cache_color}${cache_icon} ${cache_efficiency}% hit rate (${cache_label})${r}"
    echo -e "  Savings: ${cache_color}\$$(format_cost "$cache_savings") saved vs no caching${r}"
    echo ""
}

# ============================================================================
# Number Formatting
# ============================================================================

# Format number with commas
format_number() {
    local num="$1"
    printf "%'d" "$num" 2>/dev/null || echo "$num"
}

log_debug "Stats parser loaded"
