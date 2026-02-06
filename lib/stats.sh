#!/usr/bin/env bash
# lib/stats.sh - Parse Claude stats-cache.json
# Extracts token usage and costs by model

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/pricing.sh"

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
    total_tokens=$(echo "$breakdown" | grep '"total"' | tail -1 | grep -o '[0-9]*')

    local total_cost
    total_cost=$(echo "$breakdown" | grep '"total"' | head -1 | cut -d: -f2 | tr -d ' ,')

    local cache_efficiency
    cache_efficiency=$(get_cache_efficiency "$stats_file")

    echo "Model: $model"
    echo "Tokens: $(format_number $total_tokens)"
    echo "Cost: \$$(format_cost $total_cost)"
    echo "Cache Hit: ${cache_efficiency}%"
}

# Show detailed breakdown
show_detailed_breakdown() {
    local stats_file="${1:-$CONFIG_STATS_FILE}"

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

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Token Usage & Cost Breakdown"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Model: $model"
    echo ""
    printf "%-20s %15s %12s\n" "Type" "Tokens" "Cost"
    printf "%-20s %15s %12s\n" "────" "──────" "────"
    printf "%-20s %15s \$%11s\n" "Input" "$(format_number $input_tokens)" "$(format_cost $input_cost)"
    printf "%-20s %15s \$%11s\n" "Output" "$(format_number $output_tokens)" "$(format_cost $output_cost)"
    printf "%-20s %15s \$%11s\n" "Cache Write" "$(format_number $cache_write)" "$(format_cost $cache_write_cost)"
    printf "%-20s %15s \$%11s\n" "Cache Read" "$(format_number $cache_read)" "$(format_cost $cache_read_cost)"
    printf "%-20s %15s %12s\n" "────" "──────" "────────"
    printf "%-20s %15s \$%11s\n" "TOTAL" "$(format_number $((input_tokens + output_tokens + cache_write + cache_read)))" "$(format_cost $total_cost)"
    echo ""

    # Cache efficiency
    local cache_efficiency
    cache_efficiency=$(get_cache_efficiency "$stats_file")

    local cache_savings
    cache_savings=$(get_cache_savings "$stats_file" "$model")

    echo "Cache Efficiency: ${cache_efficiency}%"
    echo "Cache Savings: \$$(format_cost $cache_savings)"
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
