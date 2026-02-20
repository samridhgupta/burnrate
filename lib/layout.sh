#!/usr/bin/env bash
# lib/layout.sh - Simple responsive terminal layout
# Keeps it minimal - terminal does most of the work

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"

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

# ============================================================================
# Startup Banner
# ============================================================================

# Single-width center icon per theme (emoji-safe: all BMP single-width chars)
_banner_icon() {
    case "${CONFIG_THEME:-glacial}" in
        glacial)   echo "❄" ;;
        ember)     echo "✦" ;;
        ocean)     echo "≋" ;;
        space)     echo "★" ;;
        garden)    echo "✿" ;;
        battery)   echo "▮" ;;
        hourglass) echo "⧖" ;;
        *)         echo "❄" ;;
    esac
}

# Show startup banner — snowflake pattern, theme-coloured, version/dir on right
# Skipped when: --quiet, piped/redirected output, or --no-color (graceful plain fallback)
show_banner() {
    [[ "${CONFIG_QUIET:-false}" == "true" ]] && return 0
    [[ ! -t 1 ]] && return 0  # non-TTY: piped/redirected — skip logo

    local version="${BURNRATE_VERSION:-1.0.0}"
    local theme="${CONFIG_THEME:-glacial}"
    local icon
    icon=$(_banner_icon)

    # Capitalise theme name (bash 3.2 compatible — no ${var^})
    local theme_cap
    theme_cap="$(echo "$theme" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

    # Colors: use theme vars if loaded, else cyan fallback; respect --no-color
    local c d b r
    if [[ "${CONFIG_COLORS_ENABLED:-auto}" == "false" ]]; then
        c="" d="" b="" r=""
    else
        c="${THEME_PRIMARY-\033[1;36m}"
        d="${THEME_DIM-\033[2;36m}"
        b="\033[1m"
        r="\033[0m"
    fi

    local tw
    tw=$(term_width)

    echo ""
    if (( tw >= 50 )); then
        # Full snowflake art — 3 rows of art, version + tagline on right
        #   art col: 10 visible chars wide
        #   text col: starts at position 14 (art + 4 spaces on narrow art rows)
        echo -e "${c}  ╲ ╱ ╲ ╱${r}"
        echo -e "${c}  ─  ${icon}  ─${r}    ${b}burnrate v${version}${r}"
        echo -e "${c}  ╱ ╲ ╱ ╲${r}   ${d}${theme_cap} · Zero API Calls${r}"
    else
        # Compact single-line for narrow terminals
        echo -e "  ${c}${icon}${r}  ${b}burnrate v${version}${r}  ${d}${theme_cap}${r}"
    fi
    echo ""
}

# Responsive themed horizontal rule (capped at 80 cols for readability)
# Usage: _themed_hr [width]
_themed_hr() {
    local w="${1:-}"
    if [[ -z "$w" ]]; then
        w=$(term_width)
        (( w > 80 )) && w=80
    fi
    local h="${THEME_PRIMARY-\033[1;36m}"
    local r=""
    [[ -n "$h" ]] && r="\033[0m"
    # printf '━%.0s' consumes one arg per ━ — handles multi-byte correctly
    # shellcheck disable=SC2046
    echo -e "${h}$(printf '━%.0s' $(seq 1 "$w"))${r}"
}

log_debug "Responsive layout loaded ($(term_width)x$(term_height), $(term_size))"
