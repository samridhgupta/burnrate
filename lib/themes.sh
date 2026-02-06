#!/usr/bin/env bash
# lib/themes.sh - Theme management and loading system
# Supports crowdsourced themes with TUI preview

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core.sh"
source "$SCRIPT_DIR/config.sh"

# ============================================================================
# Theme Paths
# ============================================================================

# Theme directories (in priority order)
get_theme_paths() {
    local theme_dirs=(
        "${XDG_CONFIG_HOME:-$HOME/.config}/burnrate/themes"  # User themes
        "$HOME/.burnrate/themes"                              # Legacy user themes
        "$SCRIPT_DIR/../config/themes"                        # Bundled themes
    )
    printf '%s\n' "${theme_dirs[@]}"
}

# Find theme file by name
find_theme() {
    local theme_name="$1"
    local theme_file="${theme_name}.theme"

    local dir
    while IFS= read -r dir; do
        if [[ -f "$dir/$theme_file" ]]; then
            echo "$dir/$theme_file"
            return 0
        fi
    done < <(get_theme_paths)

    log_error "Theme not found: $theme_name"
    return 1
}

# ============================================================================
# Theme Loading
# ============================================================================

# Load theme file
load_theme() {
    local theme_name="${1:-$CONFIG_THEME}"
    local theme_file

    log_debug "Loading theme: $theme_name"

    # Find theme file
    if ! theme_file=$(find_theme "$theme_name"); then
        log_error "Failed to load theme: $theme_name"
        return 1
    fi

    # Source theme file
    source "$theme_file"

    log_debug "Theme loaded: $THEME_DISPLAY_NAME ($theme_file)"
    return 0
}

# ============================================================================
# Theme Discovery
# ============================================================================

# List all available themes
list_themes() {
    local format="${1:-simple}"  # simple, detailed, json

    local themes=()
    local seen=()

    # Scan theme directories
    local dir
    while IFS= read -r dir; do
        [[ ! -d "$dir" ]] && continue

        # Find all .theme files
        local theme_file
        while IFS= read -r theme_file; do
            local theme_name=$(basename "$theme_file" .theme)

            # Skip if already seen (priority: first found wins)
            [[ " ${seen[@]} " =~ " ${theme_name} " ]] && continue
            seen+=("$theme_name")

            # Load theme metadata
            local display_name emoji description author version
            (
                source "$theme_file"
                echo "$theme_name"
                echo "${THEME_DISPLAY_NAME:-$theme_name}"
                echo "${THEME_EMOJI:- }"
                echo "${THEME_DESCRIPTION:-No description}"
                echo "${THEME_AUTHOR:-Unknown}"
                echo "${THEME_VERSION:-1.0.0}"
            ) | {
                read theme_name
                read display_name
                read emoji
                read description
                read author
                read version

                themes+=("$theme_name|$display_name|$emoji|$description|$author|$version")
            }
        done < <(find "$dir" -maxdepth 1 -name "*.theme" 2>/dev/null)
    done < <(get_theme_paths)

    # Output based on format
    case "$format" in
        simple)
            for theme in "${themes[@]}"; do
                IFS='|' read -r name display emoji desc author version <<< "$theme"
                echo "$emoji $display"
            done
            ;;
        detailed)
            for theme in "${themes[@]}"; do
                IFS='|' read -r name display emoji desc author version <<< "$theme"
                echo "$emoji $display"
                echo "  Name:        $name"
                echo "  Description: $desc"
                echo "  Author:      $author"
                echo "  Version:     $version"
                echo ""
            done
            ;;
        json)
            echo "["
            local first=true
            for theme in "${themes[@]}"; do
                IFS='|' read -r name display emoji desc author version <<< "$theme"
                $first || echo ","
                cat <<JSON
  {
    "name": "$name",
    "display_name": "$display",
    "emoji": "$emoji",
    "description": "$desc",
    "author": "$author",
    "version": "$version"
  }
JSON
                first=false
            done
            echo "]"
            ;;
    esac
}

# ============================================================================
# Theme Preview
# ============================================================================

# Show theme preview
preview_theme() {
    local theme_name="$1"
    local theme_file

    # Find and load theme
    if ! theme_file=$(find_theme "$theme_name"); then
        echo "Theme not found: $theme_name"
        return 1
    fi

    # Load theme in subshell
    (
        source "$theme_file"

        # Preview header
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${THEME_PRIMARY}${THEME_EMOJI} ${THEME_DISPLAY_NAME}${COLOR_RESET}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "$THEME_DESCRIPTION"
        echo ""

        # Status indicators
        echo "Status Indicators:"
        echo -e "  ${THEME_SUCCESS}${THEME_STATUS_EXCELLENT} Excellent${COLOR_RESET} (90-100%)"
        echo -e "  ${THEME_SUCCESS}${THEME_STATUS_GOOD} Good${COLOR_RESET} (75-89%)"
        echo -e "  ${THEME_WARNING}${THEME_STATUS_WARNING} Warning${COLOR_RESET} (50-74%)"
        echo -e "  ${THEME_ERROR}${THEME_STATUS_CRITICAL} Critical${COLOR_RESET} (25-49%)"
        echo -e "  ${THEME_ERROR}${THEME_STATUS_DANGER} Danger${COLOR_RESET} (0-24%)"
        echo ""

        # Budget indicators
        echo "Budget Status:"
        echo -e "  ${THEME_SUCCESS}${THEME_BUDGET_SAFE} Safe${COLOR_RESET}"
        echo -e "  ${THEME_WARNING}${THEME_BUDGET_WARNING} Warning${COLOR_RESET}"
        echo -e "  ${THEME_ERROR}${THEME_BUDGET_CRITICAL} Critical${COLOR_RESET}"
        echo -e "  ${THEME_ERROR}${THEME_BUDGET_EXCEEDED} Exceeded${COLOR_RESET}"
        echo ""

        # Sample message
        echo "Sample Output:"
        echo -e "  ${THEME_PRIMARY}${THEME_ICON_COST} Token Cost: \$0.15${COLOR_RESET}"
        echo -e "  ${THEME_SUCCESS}${THEME_ICON_CACHE} Cache Hit: 85%${COLOR_RESET}"
        echo -e "  ${THEME_INFO}${THEME_ICON_BUDGET} Budget: 75% remaining${COLOR_RESET}"
        echo ""

        # Footer
        echo -e "${THEME_DIM}${THEME_FOOTER}${COLOR_RESET}"
        echo ""
    )
}

# ============================================================================
# Theme Validation
# ============================================================================

# Validate theme file has required variables
# Note: Themes can have MANY more variables than required!
# Only validates minimum required fields - themes are encouraged to add:
# - Fun messages (THEME_CACHE_HIT_1, THEME_CACHE_HIT_2, etc.)
# - Tips (THEME_TIP_1, THEME_TIP_2, etc.)
# - Custom reactions (THEME_BURN_LOW, THEME_BURN_HIGH, etc.)
# - Anything creative!
validate_theme() {
    local theme_file="$1"

    # Minimum required variables (just the essentials)
    local required_vars=(
        "THEME_NAME"
        "THEME_DISPLAY_NAME"
        "THEME_PRIMARY"
        "THEME_SUCCESS"
        "THEME_WARNING"
        "THEME_ERROR"
        "THEME_STATUS_EXCELLENT"
        "THEME_STATUS_GOOD"
        "THEME_STATUS_WARNING"
        "THEME_STATUS_CRITICAL"
        "THEME_STATUS_DANGER"
    )

    local missing=()

    # Load theme and check variables
    (
        source "$theme_file"
        for var in "${required_vars[@]}"; do
            if [[ -z "${!var}" ]]; then
                echo "$var"
            fi
        done
    ) | while read -r missing_var; do
        missing+=("$missing_var")
    done

    if (( ${#missing[@]} > 0 )); then
        log_error "Theme validation failed for $theme_file"
        log_error "Missing required variables: ${missing[*]}"
        return 1
    fi

    log_debug "Theme validated (required fields present, optional fields allowed)"
    return 0
}

# ============================================================================
# Theme Creation Helper
# ============================================================================

# Generate theme template
generate_theme_template() {
    local theme_name="${1:-mytheme}"

    cat <<EOF
#!/usr/bin/env bash
# $theme_name Theme

# ============================================================================
# THEME METADATA
# ============================================================================

THEME_NAME="$theme_name"
THEME_DISPLAY_NAME="My Theme"
THEME_EMOJI="🎨"
THEME_DESCRIPTION="Your theme description"
THEME_AUTHOR="Your Name"
THEME_VERSION="1.0.0"

# ============================================================================
# COLORS
# ============================================================================

THEME_PRIMARY='\\033[1;35m'      # Bright magenta
THEME_SUCCESS='\\033[0;32m'      # Green
THEME_WARNING='\\033[0;33m'      # Yellow
THEME_ERROR='\\033[0;31m'        # Red
THEME_INFO='\\033[0;34m'         # Blue
THEME_DIM='\\033[2;37m'          # Dim white

# ============================================================================
# STATUS INDICATORS (MUST BE UNIQUE!)
# ============================================================================

THEME_STATUS_EXCELLENT="✨"      # 90-100%
THEME_STATUS_GOOD="👍"           # 75-89%
THEME_STATUS_WARNING="⚠️"        # 50-74%
THEME_STATUS_CRITICAL="🚨"       # 25-49%
THEME_STATUS_DANGER="💀"         # 0-24%

THEME_BUDGET_SAFE="💰"
THEME_BUDGET_WARNING="⚠️"
THEME_BUDGET_CRITICAL="🚨"
THEME_BUDGET_EXCEEDED="💥"

THEME_CACHE_EXCELLENT="✨"
THEME_CACHE_GOOD="👍"
THEME_CACHE_POOR="🔥"

# ============================================================================
# ICONS
# ============================================================================

THEME_ICON_LOADING="⏳"
THEME_ICON_SUCCESS="✓"
THEME_ICON_ERROR="✗"
THEME_ICON_WARNING="⚠"
THEME_ICON_INFO="ℹ"
THEME_ICON_COST="💲"
THEME_ICON_TOKENS="🔥"
THEME_ICON_CACHE="💾"
THEME_ICON_BUDGET="💰"

# ============================================================================
# MESSAGES
# ============================================================================

THEME_MSG_EXCELLENT="Excellent!"
THEME_MSG_GOOD="Looking good"
THEME_MSG_WARNING="Warning"
THEME_MSG_CRITICAL="Critical"
THEME_MSG_DANGER="Danger!"

THEME_FOOTER="Your custom footer message"

# ============================================================================
# LABELS
# ============================================================================

THEME_LABEL_COST="Cost"
THEME_LABEL_SAVINGS="Savings"
THEME_LABEL_TOKENS="Tokens"
THEME_LABEL_STATUS="Status"

# ============================================================================
# OPTIONAL: Add as many fun messages as you want!
# ============================================================================

# Tips
THEME_TIP_1="💡 Your first tip"
THEME_TIP_2="💡 Your second tip"
# Add THEME_TIP_3, THEME_TIP_4, etc...

# Fun reactions to token burns
# THEME_BURN_LOW="Small burn reaction"
# THEME_BURN_HIGH="Big burn reaction"

# Cache hit celebrations
# THEME_CACHE_HIT_1="Yay, cached!"
# THEME_CACHE_HIT_2="Another cache hit!"

# Cache miss warnings
# THEME_CACHE_MISS_1="Oh no, cache miss"

# Daily summary messages
# THEME_SUMMARY_EFFICIENT="You're doing great!"
# THEME_SUMMARY_WASTEFUL="Try to cache more!"

# Startup messages
# THEME_STARTUP_1="Loading your theme..."

# Get creative! The library handles any THEME_* variables you add
EOF
}

# Create new theme file
create_theme() {
    local theme_name="$1"

    if [[ -z "$theme_name" ]]; then
        log_error "Theme name required"
        return 1
    fi

    local theme_dir="${XDG_CONFIG_HOME:-$HOME/.config}/burnrate/themes"
    local theme_file="$theme_dir/${theme_name}.theme"

    if [[ -f "$theme_file" ]]; then
        log_error "Theme already exists: $theme_file"
        return 1
    fi

    mkdir -p "$theme_dir"
    generate_theme_template "$theme_name" > "$theme_file"
    chmod +x "$theme_file"

    log_info "Created theme: $theme_file"
    log_info "Edit the file to customize your theme"
    return 0
}

log_debug "Theme system loaded"
