#!/usr/bin/env bash
# lib/charts.sh - Sparklines and inline trend indicators

[[ -n "${BURNRATE_CHARTS_LOADED:-}" ]] && return 0
readonly BURNRATE_CHARTS_LOADED=1

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"

# ============================================================================
# Sparkline  (single row, 8-level Unicode block chars ▁▂▃▄▅▆▇█)
# ============================================================================

# Generate a single-line sparkline from newline-separated integer values.
# Zero values are rendered as a space (gap).
# Args: newline-separated integers via stdin or as "$1"
# Output: sparkline string (no trailing newline)
sparkline() {
    local values="${1:-}"
    [[ -z "$values" ]] && echo "" && return 0

    echo "$values" | awk '
    BEGIN { max = 1 }
    { v = $1 + 0; if (v > max) max = v; vals[NR] = v; n = NR }
    END {
        split("▁ ▂ ▃ ▄ ▅ ▆ ▇ █", ch, " ")
        spark = ""
        for (i = 1; i <= n; i++) {
            v = vals[i]
            if (v == 0) {
                spark = spark " "
            } else {
                lv = int(v * 8 / max)
                if (lv < 1) lv = 1
                if (lv > 8) lv = 8
                spark = spark ch[lv]
            }
        }
        printf "%s", spark
    }'
}

# ============================================================================
# Inline trend indicator  ▲ +X% / ▼ X% / ─
# ============================================================================

# Output a short colored trend indicator (no trailing newline).
# Decreasing cost = green (good), increasing = red (spending more).
# Args: change_percent (signed decimal from bc, or "N/A")
# Usage with printf: printf "  %s  " "$(trend_inline "$change")"  — but since
#         ANSI codes confuse printf width, use echo -e or print then echo "".
trend_inline() {
    local change="${1:-}"
    local green="\033[0;32m"
    local red="\033[0;31m"
    local dim="\033[2m"
    local r="\033[0m"

    if [[ -z "$change" || "$change" == "N/A" ]]; then
        printf "%b" "${dim}─  new${r}"
        return 0
    fi

    local is_neg=false
    echo "$change" | grep -q "^-" && is_neg=true
    local abs="${change#-}"
    abs=$(printf "%.1f" "$abs" 2>/dev/null || echo "$abs")

    if [[ "$abs" == "0" || "$abs" == "0.0" ]]; then
        printf "%b" "${dim}─  flat${r}"
    elif [[ "$is_neg" == "true" ]]; then
        printf "%b" "${green}▼ ${abs}%${r}"
    else
        printf "%b" "${red}▲ +${abs}%${r}"
    fi
}

log_debug "Charts loaded"
