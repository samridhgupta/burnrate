#!/usr/bin/env bash
# lib/layout.sh - Simple responsive terminal layout
# Keeps it minimal - terminal does most of the work

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core.sh"

# ============================================================================
# Terminal Size (Simple)
# ============================================================================

# Get terminal width
term_width() {
    tput cols 2>/dev/null || echo "${COLUMNS:-80}"
}

# Get terminal height
term_height() {
    tput lines 2>/dev/null || echo "${LINES:-24}"
}

# ============================================================================
# Responsive Breakpoints (Simple)
# ============================================================================

# Determine size category
term_size() {
    local width=$(term_width)

    if (( width >= 100 )); then
        echo "wide"
    elif (( width >= 70 )); then
        echo "normal"
    elif (( width >= 50 )); then
        echo "narrow"
    else
        echo "minimal"
    fi
}

# Check if wide enough
is_wide() {
    [[ $(term_size) == "wide" ]]
}

# Check if narrow
is_narrow() {
    local size=$(term_size)
    [[ "$size" == "narrow" ]] || [[ "$size" == "minimal" ]]
}

# ============================================================================
# Responsive Width (Simple)
# ============================================================================

# Get content width (90% of terminal, max 120)
content_width() {
    local width=$(term_width)
    local content=$((width * 9 / 10))  # 90%

    # Cap at 120 for readability
    if (( content > 120 )); then
        echo 120
    else
        echo "$content"
    fi
}

# Get width for element type
element_width() {
    local type="${1:-content}"
    local width=$(term_width)

    case "$type" in
        full)
            echo "$width"
            ;;
        content)
            content_width
            ;;
        narrow)
            echo $((width * 7 / 10))  # 70%
            ;;
        half)
            echo $((width / 2))
            ;;
        *)
            echo "$width"
            ;;
    esac
}

# ============================================================================
# Simple Line Drawing
# ============================================================================

# Horizontal line that fits terminal
hline() {
    local char="${1:-━}"
    local width=${2:-$(content_width)}
    printf "%${width}s" | tr ' ' "$char"
}

# ============================================================================
# Simple Text Formatting
# ============================================================================

# Truncate to fit width
fit_text() {
    local text="$1"
    local width="${2:-$(content_width)}"

    if (( ${#text} > width )); then
        echo "${text:0:$((width-3))}..."
    else
        echo "$text"
    fi
}

# Simple center
center() {
    local text="$1"
    local width=$(content_width)
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%${padding}s%s\n" "" "$text"
}

# ============================================================================
# Responsive Header (Simple)
# ============================================================================

# Header adapts to terminal
header() {
    local text="$1"
    local size=$(term_size)

    case "$size" in
        minimal)
            echo "$text"
            ;;
        *)
            echo "$text"
            hline "━"
            ;;
    esac
}

# ============================================================================
# Responsive Row Display
# ============================================================================

# Show key-value pair responsively
row() {
    local key="$1"
    local value="$2"
    local size=$(term_size)

    case "$size" in
        minimal)
            echo "$key: $value"
            ;;
        narrow)
            printf "%-15s %s\n" "$key:" "$value"
            ;;
        *)
            printf "%-20s %s\n" "$key:" "$value"
            ;;
    esac
}

# Show two columns if wide enough, else stack
two_col() {
    local left="$1"
    local right="$2"

    if is_narrow; then
        echo "$left"
        echo "$right"
    else
        local width=$(content_width)
        local col_width=$((width / 2 - 2))
        printf "%-${col_width}s  %s\n" "$left" "$right"
    fi
}

# ============================================================================
# Progress Bar (Simple)
# ============================================================================

# Progress bar adapts to width
progress() {
    local current=$1
    local total=$2
    local size=$(term_size)

    # Bar width based on terminal
    local bar_width
    case "$size" in
        minimal) bar_width=10 ;;
        narrow)  bar_width=20 ;;
        normal)  bar_width=30 ;;
        wide)    bar_width=40 ;;
    esac

    local percentage=$((current * 100 / total))
    local filled=$((current * bar_width / total))
    local empty=$((bar_width - filled))

    printf "["
    printf "█%.0s" $(seq 1 $filled)
    printf "░%.0s" $(seq 1 $empty)
    printf "] %d%%" "$percentage"
}

log_debug "Responsive layout loaded ($(term_width)x$(term_height), $(term_size))"
