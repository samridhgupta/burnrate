#!/usr/bin/env bash
# lib/themes.sh - Theme management and loading system
# Supports crowdsourced themes with TUI preview

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"

# ============================================================================
# Theme Paths
# ============================================================================

# Theme directories (in priority order)
get_theme_paths() {
    local theme_dirs=(
        "${XDG_CONFIG_HOME:-$HOME/.config}/burnrate/themes"  # User themes
        "$HOME/.burnrate/themes"                              # Legacy user themes
        "$LIB_DIR/../config/themes"                        # Bundled themes
    )
    printf '%s\n' "${theme_dirs[@]}"
}

# Component directories searched for color/icon/message component files
get_component_paths() {
    local component_type="$1"   # colors | icons | messages
    local paths=(
        "${XDG_CONFIG_HOME:-$HOME/.config}/burnrate/${component_type}"  # User components
        "$LIB_DIR/../config/${component_type}"                           # Bundled components
    )
    printf '%s\n' "${paths[@]}"
}

# Find a component file by name (colors/icons/messages)
# Searches: component dirs, then theme dirs (themes can double as components)
find_component() {
    local component_type="$1"   # colors | icons | messages
    local component_name="$2"   # e.g. "amber", "none", "agent"

    # Try dedicated component directories first
    local cdir
    while IFS= read -r cdir; do
        [[ ! -d "$cdir" ]] && continue
        local f
        # Match: name.colors / name.icons / name.msgs / name.theme
        for f in "$cdir/${component_name}.${component_type%s}" \
                  "$cdir/${component_name}.msgs" \
                  "$cdir/${component_name}.${component_type}" \
                  "$cdir/${component_name}.theme"; do
            [[ -f "$f" ]] && echo "$f" && return 0
        done
    done < <(get_component_paths "$component_type")

    # Fallback: search theme dirs (a theme file can act as any component)
    local f
    if f=$(find_theme "$component_name" 2>/dev/null); then
        echo "$f"
        return 0
    fi

    return 1
}

# Find theme file by name (searches top level and one level of subdirectories)
find_theme() {
    local theme_name="$1"
    local theme_file="${theme_name}.theme"

    local dir
    while IFS= read -r dir; do
        [[ ! -d "$dir" ]] && continue

        # Check top level
        if [[ -f "$dir/$theme_file" ]]; then
            echo "$dir/$theme_file"
            return 0
        fi

        # Check one level of subdirectories (category folders)
        local subdir
        while IFS= read -r subdir; do
            if [[ -f "$subdir/$theme_file" ]]; then
                echo "$subdir/$theme_file"
                return 0
            fi
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
    done < <(get_theme_paths)

    log_error "Theme not found: $theme_name"
    return 1
}

# ============================================================================
# Theme Loading
# ============================================================================

# Load theme file — then apply optional component overlays in priority order:
#   base theme → message set → icon set → color scheme
#
# Each overlay only sets the vars it defines; others from the base theme persist.
# A message set may declare THEME_DEFAULT_ICON_SET / THEME_DEFAULT_COLOR_SCHEME
# as suggestions — used only when the user hasn't explicitly set those components.
load_theme() {
    local theme_name="${1:-$CONFIG_THEME}"
    local theme_file

    log_debug "Loading theme: $theme_name"

    # ── Step 1: Base theme ────────────────────────────────────────────────────
    if ! theme_file=$(find_theme "$theme_name"); then
        log_error "Failed to load theme: $theme_name"
        return 1
    fi
    source "$theme_file"
    log_debug "Base theme loaded: $THEME_DISPLAY_NAME"

    # ── Step 2: Message set overlay ───────────────────────────────────────────
    local msg_set="${CONFIG_MESSAGE_SET:-}"
    if [[ -n "$msg_set" ]]; then
        local msg_file
        if msg_file=$(find_component "messages" "$msg_set" 2>/dev/null); then
            source "$msg_file"
            log_debug "Message set applied: $msg_set ($msg_file)"
            # Capture any suggestions the message set exposes
            # (THEME_DEFAULT_ICON_SET / THEME_DEFAULT_COLOR_SCHEME set by the file)
        else
            log_debug "Message set not found: $msg_set — using base theme messages"
        fi
    fi

    # ── Step 3: Icon set overlay ──────────────────────────────────────────────
    # Resolve: explicit CONFIG_ICON_SET > message set's suggestion > nothing
    local icon_set="${CONFIG_ICON_SET:-${THEME_DEFAULT_ICON_SET:-}}"
    if [[ -n "$icon_set" ]]; then
        local icon_file
        if icon_file=$(find_component "icons" "$icon_set" 2>/dev/null); then
            source "$icon_file"
            log_debug "Icon set applied: $icon_set ($icon_file)"
        else
            log_debug "Icon set not found: $icon_set — using base theme icons"
        fi
    fi

    # ── Step 4: Color scheme overlay ──────────────────────────────────────────
    # Resolve: explicit CONFIG_COLOR_SCHEME > message set's suggestion > nothing
    local color_scheme="${CONFIG_COLOR_SCHEME:-${THEME_DEFAULT_COLOR_SCHEME:-}}"
    if [[ -n "$color_scheme" ]]; then
        local color_file
        if color_file=$(find_component "colors" "$color_scheme" 2>/dev/null); then
            source "$color_file"
            log_debug "Color scheme applied: $color_scheme ($color_file)"
        else
            log_debug "Color scheme not found: $color_scheme — using base theme colors"
        fi
    fi

    log_debug "Theme resolution complete: $THEME_DISPLAY_NAME + msg=${msg_set:-base} + icons=${icon_set:-base} + colors=${color_scheme:-base}"
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

    # Scan theme directories (top level + one level of category subdirs)
    local dir
    while IFS= read -r dir; do
        [[ ! -d "$dir" ]] && continue

        # Collect .theme files from top level and one level of subdirs
        local scan_dirs=("$dir")
        local subdir
        while IFS= read -r subdir; do
            scan_dirs+=("$subdir")
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

        local scan_dir
        for scan_dir in "${scan_dirs[@]}"; do
            local theme_file
            while IFS= read -r theme_file; do
                local theme_name
                theme_name=$(basename "$theme_file" .theme)

                # Skip if already seen (priority: first found wins)
                [[ " ${seen[@]+"${seen[@]}"} " =~ " ${theme_name} " ]] && continue
                seen+=("$theme_name")

                # Derive category from parent dir name (empty if at root level)
                local category=""
                local parent_dir
                parent_dir=$(basename "$(dirname "$theme_file")")
                [[ "$parent_dir" != "$(basename "$dir")" ]] && category="$parent_dir"

                # Load theme metadata in a subshell and capture as a single line
                local t_meta
                t_meta=$(
                    source "$theme_file" 2>/dev/null
                    printf '%s|%s|%s|%s|%s|%s|%s\n' \
                        "$theme_name" \
                        "${THEME_DISPLAY_NAME:-$theme_name}" \
                        "${THEME_EMOJI:- }" \
                        "${THEME_DESCRIPTION:-No description}" \
                        "${THEME_AUTHOR:-Unknown}" \
                        "${THEME_VERSION:-1.0.0}" \
                        "$category"
                )
                themes+=("$t_meta")
            done < <(find "$scan_dir" -maxdepth 1 -name "*.theme" 2>/dev/null)
        done
    done < <(get_theme_paths)

    # Check if any themes found
    if (( ${#themes[@]} == 0 )); then
        echo "No themes found"
        return 1
    fi

    # Output based on format
    case "$format" in
        simple)
            for theme in "${themes[@]}"; do
                IFS='|' read -r name display emoji desc author version category <<< "$theme"
                echo "$emoji $display"
            done
            ;;
        detailed)
            # Group by category for prettier output
            local last_category="__none__"
            for theme in "${themes[@]}"; do
                IFS='|' read -r name display emoji desc author version category <<< "$theme"
                if [[ "$category" != "$last_category" ]]; then
                    [[ "$last_category" != "__none__" ]] && echo ""
                    if [[ -n "$category" ]]; then
                        echo "── ${category} ──────────────────────────"
                    fi
                    last_category="$category"
                fi
                echo "$emoji $display"
                echo "  Name:        $name"
                echo "  Description: $desc"
                echo ""
            done
            ;;
        json)
            echo "["
            local first=true
            for theme in "${themes[@]}"; do
                IFS='|' read -r name display emoji desc author version category <<< "$theme"
                $first || echo ","
                cat <<JSON
  {
    "name": "$name",
    "display_name": "$display",
    "emoji": "$emoji",
    "description": "$desc",
    "author": "$author",
    "version": "$version",
    "category": "$category"
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
