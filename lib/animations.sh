#!/usr/bin/env bash
# lib/animations.sh - ASCII animation system for burnrate
# Simple, composable animations that adapt to config

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core.sh"
source "$SCRIPT_DIR/config.sh"

# ============================================================================
# Animation Configuration
# ============================================================================

# Animation speeds (milliseconds per frame)
readonly ANIM_SPEED_SLOW=200
readonly ANIM_SPEED_NORMAL=100
readonly ANIM_SPEED_FAST=50
readonly ANIM_SPEED_INSTANT=0

# Get animation delay based on config
get_anim_delay() {
    local speed="${CONFIG_ANIMATION_SPEED:-normal}"

    case "$speed" in
        slow) echo "$ANIM_SPEED_SLOW" ;;
        normal) echo "$ANIM_SPEED_NORMAL" ;;
        fast) echo "$ANIM_SPEED_FAST" ;;
        instant) echo "$ANIM_SPEED_INSTANT" ;;
        *) echo "$ANIM_SPEED_NORMAL" ;;
    esac
}

# Check if animations enabled
animations_enabled() {
    [[ "${CONFIG_ANIMATIONS_ENABLED:-true}" == "true" ]]
}

# ============================================================================
# Animation Primitives
# ============================================================================

# Show single frame
show_frame() {
    local frame="$1"
    echo -ne "\r$frame"
}

# Clear current line
clear_line() {
    echo -ne "\r\033[K"
}

# Sleep for animation delay
anim_sleep() {
    local delay=$(get_anim_delay)
    if (( delay > 0 )); then
        sleep "0.$(printf "%03d" $delay)"
    fi
}

# Animate sequence of frames
animate_frames() {
    local -n frames_ref=$1
    local cycles=${2:-1}

    if ! animations_enabled; then
        # Just show first frame if animations disabled
        echo "${frames_ref[0]}"
        return
    fi

    for ((c=0; c<cycles; c++)); do
        for frame in "${frames_ref[@]}"; do
            show_frame "$frame"
            anim_sleep
        done
    done
    echo "" # New line after animation
}

# ============================================================================
# Spinner Animations
# ============================================================================

# Classic spinner
spinner_classic() {
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    animate_frames frames "${1:-3}"
}

# Dots spinner
spinner_dots() {
    local frames=("⠋" "⠙" "⠚" "⠞" "⠖" "⠦" "⠴" "⠲" "⠳" "⠓")
    animate_frames frames "${1:-3}"
}

# Simple spinner
spinner_simple() {
    local frames=("|" "/" "-" "\\")
    animate_frames frames "${1:-4}"
}

# Arrow spinner
spinner_arrow() {
    local frames=("←" "↖" "↑" "↗" "→" "↘" "↓" "↙")
    animate_frames frames "${1:-2}"
}

# ============================================================================
# Loading Animations
# ============================================================================

# Loading dots
loading_dots() {
    local message="${1:-Loading}"
    local cycles=${2:-3}

    if ! animations_enabled; then
        echo "$message..."
        return
    fi

    for ((i=0; i<cycles; i++)); do
        show_frame "$message   "
        anim_sleep
        show_frame "$message.  "
        anim_sleep
        show_frame "$message.. "
        anim_sleep
        show_frame "$message..."
        anim_sleep
    done
    echo ""
}

# Progress animation
progress_anim() {
    local message="${1:-Processing}"
    local steps=${2:-10}

    if ! animations_enabled; then
        echo "$message [##########] 100%"
        return
    fi

    for ((i=0; i<=steps; i++)); do
        local filled=$((i * 2))
        local empty=$((20 - filled))
        local bar=$(printf "█%.0s" $(seq 1 $filled))$(printf "░%.0s" $(seq 1 $empty))
        local percent=$((i * 100 / steps))
        show_frame "$message [$bar] $percent%"
        anim_sleep
    done
    echo ""
}

# ============================================================================
# Theme-Specific Animations (Placeholders)
# ============================================================================

# Ice melting animation (for Glacial theme)
anim_ice_melt() {
    local stages=("❄️  ████████" "❄️  ███████▓" "🧊 ██████▓░" "💧 ████▓░░░" "💧 ██▓░░░░░" "🌊 ▓░░░░░░░")

    if ! animations_enabled; then
        echo "${stages[-1]}"
        return
    fi

    for stage in "${stages[@]}"; do
        show_frame "$stage"
        anim_sleep
        anim_sleep  # Double delay for dramatic effect
    done
    echo ""
}

# Fire animation (for Ember theme)
anim_fire() {
    local frames=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂")

    if ! animations_enabled; then
        echo "🔥 ████"
        return
    fi

    echo -n "🔥 "
    for frame in "${frames[@]}"; do
        show_frame "🔥 $frame$frame$frame$frame"
        anim_sleep
    done
    echo ""
}

# Lightning flash (for cache hits)
anim_lightning() {
    if ! animations_enabled; then
        echo "⚡"
        return
    fi

    show_frame "   "
    anim_sleep
    show_frame "⚡ "
    anim_sleep
    show_frame "━━━"
    anim_sleep
    show_frame "⚡ "
    anim_sleep
    show_frame "   "
    echo ""
}

# Snowflake falling (for Glacial theme)
anim_snowflake() {
    local frames=("❄" "❅" "❆" "❄" "❅" "❆")

    if ! animations_enabled; then
        echo "❄"
        return
    fi

    animate_frames frames 2
}

# ============================================================================
# Status Animations
# ============================================================================

# Success animation
anim_success() {
    local message="${1:-Success}"

    if ! animations_enabled; then
        echo "✓ $message"
        return
    fi

    show_frame "  $message"
    anim_sleep
    show_frame "→ $message"
    anim_sleep
    show_frame "✓ $message"
    anim_sleep
    echo ""
}

# Error animation
anim_error() {
    local message="${1:-Error}"

    if ! animations_enabled; then
        echo "✗ $message"
        return
    fi

    show_frame "  $message"
    anim_sleep
    show_frame "✗ $message"
    anim_sleep
    show_frame "  $message"
    anim_sleep
    show_frame "✗ $message"
    echo ""
}

# Warning pulse
anim_warning() {
    local message="${1:-Warning}"

    if ! animations_enabled; then
        echo "⚠️  $message"
        return
    fi

    for ((i=0; i<3; i++)); do
        show_frame "⚠️  $message"
        anim_sleep
        show_frame "   $message"
        anim_sleep
    done
    echo "⚠️  $message"
}

# ============================================================================
# Progress Indicators
# ============================================================================

# Animated progress bar
progress_bar_anim() {
    local current=$1
    local total=$2
    local label="${3:-Progress}"

    if ! animations_enabled; then
        local percentage=$((current * 100 / total))
        echo "$label: $percentage%"
        return
    fi

    # Animate from 0 to current
    local steps=20
    for ((i=0; i<=current; i+=(total/steps))); do
        local percentage=$((i * 100 / total))
        local filled=$((percentage * 20 / 100))
        local empty=$((20 - filled))
        local bar=$(printf "█%.0s" $(seq 1 $filled))$(printf "░%.0s" $(seq 1 $empty))
        show_frame "$label: [$bar] $percentage%"
        anim_sleep
    done

    # Final frame
    local percentage=$((current * 100 / total))
    local filled=$((percentage * 20 / 100))
    local empty=$((20 - filled))
    local bar=$(printf "█%.0s" $(seq 1 $filled))$(printf "░%.0s" $(seq 1 $empty))
    echo "$label: [$bar] $percentage%"
}

# ============================================================================
# Background Task Animation
# ============================================================================

# Show spinner while command runs
with_spinner() {
    local message="$1"
    shift
    local command="$@"

    if ! animations_enabled; then
        echo "$message..."
        eval "$command"
        return $?
    fi

    # Run command in background
    eval "$command" &>/dev/null &
    local pid=$!

    # Show spinner while running
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0

    while kill -0 $pid 2>/dev/null; do
        show_frame "$message ${frames[$i]}"
        anim_sleep
        i=$(( (i + 1) % ${#frames[@]} ))
    done

    wait $pid
    local exit_code=$?

    clear_line
    if [[ $exit_code -eq 0 ]]; then
        echo "✓ $message"
    else
        echo "✗ $message"
    fi

    return $exit_code
}

# ============================================================================
# Utility Functions
# ============================================================================

# Test all animations
test_animations() {
    echo "Testing animations (speed: ${CONFIG_ANIMATION_SPEED:-normal})"
    echo ""

    echo "Spinners:"
    echo -n "  Classic: "; spinner_classic 2
    echo -n "  Dots: "; spinner_dots 2
    echo -n "  Simple: "; spinner_simple 2
    echo -n "  Arrow: "; spinner_arrow 1
    echo ""

    echo "Loading:"
    loading_dots "Loading" 2
    progress_anim "Processing" 5
    echo ""

    echo "Theme animations:"
    echo -n "  Ice melt: "; anim_ice_melt
    echo -n "  Fire: "; anim_fire
    echo -n "  Lightning: "; anim_lightning
    echo -n "  Snowflake: "; anim_snowflake
    echo ""

    echo "Status:"
    anim_success "Operation complete"
    anim_warning "Check your budget"
    anim_error "Connection failed"
    echo ""

    echo "Progress:"
    progress_bar_anim 75 100 "Cache efficiency"
}

log_debug "Animation system loaded (enabled: ${CONFIG_ANIMATIONS_ENABLED:-true}, speed: ${CONFIG_ANIMATION_SPEED:-normal})"
