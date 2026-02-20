#!/usr/bin/env bash
# lib/colors.sh - Color and theme foundation for burnrate
# Provides color utilities and base theme system

# Source guard (prevent double-sourcing)
[[ -n "${BURNRATE_COLORS_LOADED:-}" ]] && return 0
readonly BURNRATE_COLORS_LOADED=1

# Source dependencies
_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_LIB_DIR/core.sh"

# ============================================================================
# ANSI Color Codes
# ============================================================================

# Basic colors
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'
readonly COLOR_UNDERLINE='\033[4m'
readonly COLOR_BLINK='\033[5m'
readonly COLOR_REVERSE='\033[7m'

# Foreground colors
readonly FG_BLACK='\033[0;30m'
readonly FG_RED='\033[0;31m'
readonly FG_GREEN='\033[0;32m'
readonly FG_YELLOW='\033[0;33m'
readonly FG_BLUE='\033[0;34m'
readonly FG_MAGENTA='\033[0;35m'
readonly FG_CYAN='\033[0;36m'
readonly FG_WHITE='\033[0;37m'

# Bright foreground colors
readonly FG_BRIGHT_BLACK='\033[1;30m'
readonly FG_BRIGHT_RED='\033[1;31m'
readonly FG_BRIGHT_GREEN='\033[1;32m'
readonly FG_BRIGHT_YELLOW='\033[1;33m'
readonly FG_BRIGHT_BLUE='\033[1;34m'
readonly FG_BRIGHT_MAGENTA='\033[1;35m'
readonly FG_BRIGHT_CYAN='\033[1;36m'
readonly FG_BRIGHT_WHITE='\033[1;37m'

# Background colors
readonly BG_BLACK='\033[40m'
readonly BG_RED='\033[41m'
readonly BG_GREEN='\033[42m'
readonly BG_YELLOW='\033[43m'
readonly BG_BLUE='\033[44m'
readonly BG_MAGENTA='\033[45m'
readonly BG_CYAN='\033[46m'
readonly BG_WHITE='\033[47m'

# ============================================================================
# Color Utilities
# ============================================================================

# Strip ANSI color codes from string
strip_colors() {
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# Get string length without ANSI codes
strlen_no_ansi() {
    local str
    str=$(strip_colors "$1")
    echo "${#str}"
}

# Apply color to text
colorize() {
    local color="$1"
    local text="$2"
    echo -e "${color}${text}${COLOR_RESET}"
}

# Color shortcuts
red() { colorize "$FG_RED" "$1"; }
green() { colorize "$FG_GREEN" "$1"; }
yellow() { colorize "$FG_YELLOW" "$1"; }
blue() { colorize "$FG_BLUE" "$1"; }
cyan() { colorize "$FG_CYAN" "$1"; }
magenta() { colorize "$FG_MAGENTA" "$1"; }
bold() { colorize "$COLOR_BOLD" "$1"; }
dim() { colorize "$COLOR_DIM" "$1"; }

# ============================================================================
# Theme Color Variables
# ============================================================================

# These will be set by theme system
THEME_PRIMARY=""
THEME_SUCCESS=""
THEME_WARNING=""
THEME_ERROR=""
THEME_INFO=""
THEME_HIGHLIGHT=""
THEME_DIM=""

# Theme icons
THEME_ICON_LOADING=""
THEME_ICON_SUCCESS=""
THEME_ICON_WARNING=""
THEME_ICON_ERROR=""
THEME_ICON_BUDGET=""
THEME_ICON_CACHE=""

# Theme indicators
THEME_INDICATOR_EXCELLENT=""
THEME_INDICATOR_GOOD=""
THEME_INDICATOR_WARNING=""
THEME_INDICATOR_CRITICAL=""
THEME_INDICATOR_DANGER=""

# Theme messages
THEME_MSG_EXCELLENT=""
THEME_MSG_GOOD=""
THEME_MSG_WARNING=""
THEME_MSG_CRITICAL=""
THEME_MSG_DANGER=""

# ============================================================================
# Theme Application
# ============================================================================

# Apply semantic colors
primary() { echo -e "${THEME_PRIMARY}$1${COLOR_RESET}"; }
success() { echo -e "${THEME_SUCCESS}$1${COLOR_RESET}"; }
warning() { echo -e "${THEME_WARNING}$1${COLOR_RESET}"; }
error() { echo -e "${THEME_ERROR}$1${COLOR_RESET}"; }
info() { echo -e "${THEME_INFO}$1${COLOR_RESET}"; }
highlight() { echo -e "${THEME_HIGHLIGHT}$1${COLOR_RESET}"; }

# ============================================================================
# Progress Bars
# ============================================================================

# Draw progress bar
# Usage: progress_bar <current> <total> [width] [filled_char] [empty_char]
progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-40}
    local filled_char="${4:-█}"
    local empty_char="${5:-░}"

    local percentage
    percentage=$(echo "scale=0; ($current * 100) / $total" | bc)

    local filled
    filled=$(echo "scale=0; ($current * $width) / $total" | bc)

    local empty=$((width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do
        bar+="$filled_char"
    done
    for ((i=0; i<empty; i++)); do
        bar+="$empty_char"
    done

    echo -n "[$bar] ${percentage}%"
}

# ============================================================================
# Box Drawing
# ============================================================================

# Box drawing characters
readonly BOX_H="━"  # Horizontal
readonly BOX_V="┃"  # Vertical
readonly BOX_TL="┏" # Top-left
readonly BOX_TR="┓" # Top-right
readonly BOX_BL="┗" # Bottom-left
readonly BOX_BR="┛" # Bottom-right
readonly BOX_VR="┣" # Vertical-right
readonly BOX_VL="┫" # Vertical-left
readonly BOX_HU="┻" # Horizontal-up
readonly BOX_HD="┳" # Horizontal-down
readonly BOX_PLUS="╋" # Cross

# Draw horizontal line
hline() {
    local width=${1:-40}
    local char="${2:-$BOX_H}"
    printf "%${width}s" | tr ' ' "$char"
}

# Draw box
# Usage: box <title> <content> [width]
draw_box() {
    local title="$1"
    local content="$2"
    local width=${3:-60}

    local title_len=${#title}
    local padding=$(( (width - title_len - 2) / 2 ))

    # Top border with title
    echo -n "$BOX_TL"
    for ((i=0; i<padding; i++)); do echo -n "$BOX_H"; done
    echo -n " $title "
    for ((i=0; i<padding; i++)); do echo -n "$BOX_H"; done
    # Adjust for odd widths
    if (( (width - title_len) % 2 != 0 )); then
        echo -n "$BOX_H"
    fi
    echo "$BOX_TR"

    # Content
    echo "$BOX_V $content"

    # Bottom border
    echo -n "$BOX_BL"
    for ((i=0; i<width; i++)); do echo -n "$BOX_H"; done
    echo "$BOX_BR"
}

# ============================================================================
# Table Drawing
# ============================================================================

# Draw table separator
table_separator() {
    local widths=("$@")
    echo -n "$BOX_VR"
    for width in "${widths[@]}"; do
        hline "$width" "$BOX_H"
        echo -n "$BOX_PLUS"
    done
    echo "$BOX_VL"
}

# Draw table row
table_row() {
    local widths=("$@")
    shift "${#widths[@]}"
    local values=("$@")

    echo -n "$BOX_V"
    for i in "${!widths[@]}"; do
        printf " %-${widths[$i]}s $BOX_V" "${values[$i]}"
    done
    echo ""
}

# ============================================================================
# Status Indicators
# ============================================================================

# Get status indicator based on percentage
get_status_indicator() {
    local percentage=$1

    if (( $(echo "$percentage >= 90" | bc -l) )); then
        echo "$THEME_INDICATOR_EXCELLENT"
    elif (( $(echo "$percentage >= 75" | bc -l) )); then
        echo "$THEME_INDICATOR_GOOD"
    elif (( $(echo "$percentage >= 50" | bc -l) )); then
        echo "$THEME_INDICATOR_WARNING"
    elif (( $(echo "$percentage >= 25" | bc -l) )); then
        echo "$THEME_INDICATOR_CRITICAL"
    else
        echo "$THEME_INDICATOR_DANGER"
    fi
}

# Get status message based on percentage
get_status_message() {
    local percentage=$1

    if (( $(echo "$percentage >= 90" | bc -l) )); then
        echo "$THEME_MSG_EXCELLENT"
    elif (( $(echo "$percentage >= 75" | bc -l) )); then
        echo "$THEME_MSG_GOOD"
    elif (( $(echo "$percentage >= 50" | bc -l) )); then
        echo "$THEME_MSG_WARNING"
    elif (( $(echo "$percentage >= 25" | bc -l) )); then
        echo "$THEME_MSG_CRITICAL"
    else
        echo "$THEME_MSG_DANGER"
    fi
}

# ============================================================================
# Formatting Helpers
# ============================================================================

# Center text in a given width
center_text() {
    local text="$1"
    local width="$2"
    local text_len
    text_len=$(strlen_no_ansi "$text")
    local padding=$(( (width - text_len) / 2 ))

    printf "%${padding}s" ""
    echo -n "$text"
    printf "%$((width - text_len - padding))s" ""
}

# Pad text to width (left-aligned)
pad_left() {
    local text="$1"
    local width="$2"
    local text_len
    text_len=$(strlen_no_ansi "$text")

    echo -n "$text"
    printf "%$((width - text_len))s" ""
}

# Pad text to width (right-aligned)
pad_right() {
    local text="$1"
    local width="$2"
    local text_len
    text_len=$(strlen_no_ansi "$text")

    printf "%$((width - text_len))s" ""
    echo -n "$text"
}

# ============================================================================
# Header/Footer
# ============================================================================

# Draw header
draw_header() {
    local title="$1"
    local width=${2:-60}
    local char="${3:-$BOX_H}"

    echo -n "$char$char "
    echo -n "$title"
    echo -n " "
    hline $((width - ${#title} - 4)) "$char"
}

# Draw footer
draw_footer() {
    local width=${1:-60}
    local char="${2:-$BOX_H}"

    hline "$width" "$char"
}

log_debug "Colors library loaded"
