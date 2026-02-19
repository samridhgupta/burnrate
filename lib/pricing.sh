#!/usr/bin/env bash
# lib/pricing.sh - Model pricing and cost calculation
# Supports multiple Claude models with automatic detection

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"

# ============================================================================
# Model Pricing Database (per 1M tokens in USD)
# ============================================================================

# Get pricing for a model (bash 3 compatible - no associative arrays)
# Returns: "input output cache_write cache_read"
_get_pricing_by_model() {
    local model="$1"

    case "$model" in
        # Claude 4.5 Models (Latest)
        *"claude-sonnet-4-5"*|*"sonnet-4-5"*|*"sonnet"*)
            echo "3.00 15.00 3.75 0.30" ;;
        *"claude-haiku-4-5"*|*"haiku-4-5"*)
            echo "0.25 1.25 0.31 0.03" ;;

        # Claude 4 Models
        *"claude-opus-4"*|*"opus-4"*|*"opus"*)
            echo "15.00 75.00 18.75 1.50" ;;
        *"claude-sonnet-4"*|*"sonnet-4"*)
            echo "3.00 15.00 3.75 0.30" ;;
        *"claude-haiku-4"*|*"haiku-4"*|*"haiku"*)
            echo "0.25 1.25 0.31 0.03" ;;

        # Claude 3.5 Models (Legacy)
        *"3-5-sonnet"*|*"3.5-sonnet"*)
            echo "3.00 15.00 3.75 0.30" ;;
        *"3-5-haiku"*|*"3.5-haiku"*)
            echo "1.00 5.00 1.25 0.10" ;;

        # Claude 3 Models (Legacy)
        *"3-opus"*)
            echo "15.00 75.00 18.75 1.50" ;;
        *"3-sonnet"*)
            echo "3.00 15.00 3.75 0.30" ;;
        *"3-haiku"*)
            echo "0.25 1.25 0.31 0.03" ;;

        # Default to Sonnet if unknown
        *)
            echo "3.00 15.00 3.75 0.30" ;;
    esac
}

# ============================================================================
# Model Name Mapping
# ============================================================================

# Map long model names to friendly names
get_friendly_model_name() {
    local model="$1"

    case "$model" in
        *"opus-4"*) echo "Opus 4" ;;
        *"sonnet-4-5"*) echo "Sonnet 4.5" ;;
        *"sonnet-4"*) echo "Sonnet 4" ;;
        *"haiku-4-5"*) echo "Haiku 4.5" ;;
        *"haiku-4"*) echo "Haiku 4" ;;
        *"3-5-sonnet"*) echo "Sonnet 3.5" ;;
        *"3-5-haiku"*) echo "Haiku 3.5" ;;
        *"3-opus"*) echo "Opus 3" ;;
        *"3-sonnet"*) echo "Sonnet 3" ;;
        *"3-haiku"*) echo "Haiku 3" ;;
        *"opus"*) echo "Opus" ;;
        *"sonnet"*) echo "Sonnet" ;;
        *"haiku"*) echo "Haiku" ;;
        *) echo "$model" ;;
    esac
}

# Get model tier (for sorting/grouping)
get_model_tier() {
    local model="$1"

    case "$model" in
        *"opus"*) echo "1-opus" ;;
        *"sonnet"*) echo "2-sonnet" ;;
        *"haiku"*) echo "3-haiku" ;;
        *) echo "9-unknown" ;;
    esac
}

# ============================================================================
# Pricing Lookup
# ============================================================================

# Get pricing for a model
# Returns: "input output cache_write cache_read" (per 1M tokens)
get_model_pricing() {
    local model="$1"
    _get_pricing_by_model "$model"
}

# Get specific price component
get_model_price() {
    local model="$1"
    local type="$2"  # input, output, cache_write, cache_read

    local pricing
    pricing=$(get_model_pricing "$model")

    case "$type" in
        input) echo "$pricing" | awk '{print $1}' ;;
        output) echo "$pricing" | awk '{print $2}' ;;
        cache_write) echo "$pricing" | awk '{print $3}' ;;
        cache_read) echo "$pricing" | awk '{print $4}' ;;
        *) echo "0" ;;
    esac
}

# ============================================================================
# Cost Calculation
# ============================================================================

# Calculate cost for token usage
# Usage: calculate_cost <input_tokens> <output_tokens> <cache_write_tokens> <cache_read_tokens> <model>
calculate_cost() {
    local input_tokens="${1:-0}"
    local output_tokens="${2:-0}"
    local cache_write_tokens="${3:-0}"
    local cache_read_tokens="${4:-0}"
    local model="${5:-sonnet}"

    local pricing
    pricing=$(get_model_pricing "$model")

    local input_price output_price cache_write_price cache_read_price
    read -r input_price output_price cache_write_price cache_read_price <<< "$pricing"

    # bc omits leading zero for values < 1 (e.g. ".79" instead of "0.79")
    # _bc_fix ensures valid JSON numbers with leading zeros
    _bc_fix() { local v="$1"; [[ "$v" == .* ]] && v="0${v}"; [[ "$v" == -.* ]] && v="-0${v:1}"; echo "$v"; }

    # Calculate costs (tokens / 1M * price)
    local input_cost
    input_cost=$(_bc_fix "$(echo "scale=6; ($input_tokens / 1000000) * $input_price" | bc)")

    local output_cost
    output_cost=$(_bc_fix "$(echo "scale=6; ($output_tokens / 1000000) * $output_price" | bc)")

    local cache_write_cost
    cache_write_cost=$(_bc_fix "$(echo "scale=6; ($cache_write_tokens / 1000000) * $cache_write_price" | bc)")

    local cache_read_cost
    cache_read_cost=$(_bc_fix "$(echo "scale=6; ($cache_read_tokens / 1000000) * $cache_read_price" | bc)")

    # Total cost
    local total_cost
    total_cost=$(_bc_fix "$(echo "scale=6; $input_cost + $output_cost + $cache_write_cost + $cache_read_cost" | bc)")

    # Return cost breakdown
    cat <<EOF
{
  "total": $total_cost,
  "input": $input_cost,
  "output": $output_cost,
  "cache_write": $cache_write_cost,
  "cache_read": $cache_read_cost,
  "model": "$model"
}
EOF
}

# ============================================================================
# Cost Formatting
# ============================================================================

# Format cost as currency string with $ prefix (for display use only)
format_cost_str() {
    local amount="$1"
    local decimals="${2:-${CONFIG_COST_DECIMALS:-2}}"

    # Format with proper decimal places and $ prefix
    printf "\$%.${decimals}f" "$amount"
}

# Format cost with color based on amount
format_cost_colored() {
    local amount="$1"
    local threshold_low="${2:-0.01}"
    local threshold_high="${3:-1.00}"

    local formatted
    formatted=$(format_cost_str "$amount" 2)

    # Color based on thresholds
    if (( $(echo "$amount < $threshold_low" | bc -l) )); then
        echo -e "${THEME_SUCCESS}${formatted}${COLOR_RESET}"
    elif (( $(echo "$amount < $threshold_high" | bc -l) )); then
        echo -e "${THEME_WARNING}${formatted}${COLOR_RESET}"
    else
        echo -e "${THEME_ERROR}${formatted}${COLOR_RESET}"
    fi
}

# ============================================================================
# Model Comparison
# ============================================================================

# Compare costs across models
compare_model_costs() {
    local input_tokens="${1:-1000000}"
    local output_tokens="${2:-1000000}"
    local cache_write="${3:-0}"
    local cache_read="${4:-0}"

    echo "Cost comparison for:"
    echo "  Input: $(format_number $input_tokens) tokens"
    echo "  Output: $(format_number $output_tokens) tokens"
    if (( cache_write > 0 )); then
        echo "  Cache write: $(format_number $cache_write) tokens"
    fi
    if (( cache_read > 0 )); then
        echo "  Cache read: $(format_number $cache_read) tokens"
    fi
    echo ""

    # Calculate for each major model
    local models=("opus" "sonnet" "haiku")
    local model
    for model in "${models[@]}"; do
        local cost_json
        cost_json=$(calculate_cost "$input_tokens" "$output_tokens" "$cache_write" "$cache_read" "$model")

        local total
        total=$(echo "$cost_json" | grep '"total"' | cut -d: -f2 | tr -d ' ,')

        local friendly_name
        friendly_name=$(get_friendly_model_name "$model")

        printf "  %-15s \$%s\n" "$friendly_name:" "$(format_cost "$total")"
    done
}

# ============================================================================
# Pricing Table Generation
# ============================================================================

# Generate pricing table for all models
show_pricing_table() {
    echo "Claude Model Pricing (per 1M tokens)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    printf "%-20s %10s %10s %12s %12s\n" "Model" "Input" "Output" "Cache Write" "Cache Read"
    printf "%-20s %10s %10s %12s %12s\n" "─────" "─────" "──────" "───────────" "──────────"

    # Show current models
    local models=(
        "claude-opus-4:Opus 4"
        "claude-sonnet-4-5:Sonnet 4.5"
        "claude-haiku-4-5:Haiku 4.5"
    )

    local model_spec
    for model_spec in "${models[@]}"; do
        local model="${model_spec%%:*}"
        local name="${model_spec##*:}"

        local pricing
        pricing=$(get_model_pricing "$model")

        local input output cache_write cache_read
        read -r input output cache_write cache_read <<< "$pricing"

        printf "%-20s \$%9.2f \$%9.2f \$%11.2f \$%11.2f\n" \
            "$name" "$input" "$output" "$cache_write" "$cache_read"
    done

    echo ""
    echo "Note: Prices in USD. Subject to change - check Anthropic's pricing page."
}

# ============================================================================
# Custom Pricing
# ============================================================================

# Set custom pricing for a model (in config or override)
set_custom_pricing() {
    local model="$1"
    local input="$2"
    local output="$3"
    local cache_write="$4"
    local cache_read="$5"

    # TODO: Implement custom pricing storage
    log_info "Custom pricing not yet implemented for $model"
}

# Load custom pricing from config
load_custom_pricing() {
    # Check for custom pricing in config
    if [[ -n "${CONFIG_CUSTOM_PRICING:-}" ]]; then
        log_debug "Loading custom pricing from config"
        # Format: "model:input,output,cache_write,cache_read;model2:..."
        # TODO: Parse and set custom pricing
    fi
}

# ============================================================================
# Context Window Sizes
# ============================================================================

# All current Claude models share a 200k context window.
# Returns: token count as integer string.
get_model_context_window() {
    # All Claude 3.5+ and 4.x models: 200,000 tokens
    echo "200000"
}

log_debug "Pricing system loaded"
