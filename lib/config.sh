#!/usr/bin/env bash
# lib/config.sh - Simple configuration management for burnrate
# Minimal config with sensible defaults

# Source core utilities
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"

# ============================================================================
# Configuration Paths
# ============================================================================

# Config file locations (checked in order)
get_config_paths() {
    local paths=()

    # 1. Environment variable
    [[ -n "${BURNRATE_CONFIG:-}" ]] && paths+=("$BURNRATE_CONFIG")

    # 2. XDG config (preferred)
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
    paths+=("$xdg_config/burnrate/burnrate.conf")

    # 3. Home directory
    paths+=("$HOME/.burnrate.conf")

    # 4. System-wide
    paths+=("/etc/burnrate/burnrate.conf")

    printf '%s\n' "${paths[@]}"
}

# Find first existing config file
find_config_file() {
    local path
    while IFS= read -r path; do
        [[ -f "$path" ]] && echo "$path" && return 0
    done < <(get_config_paths)
    return 1
}

# ============================================================================
# Core Configuration Defaults (Minimal)
# ============================================================================

set_config_defaults() {
    # Display
    CONFIG_THEME="${CONFIG_THEME:-glacial}"
    CONFIG_COLORS_ENABLED="${CONFIG_COLORS_ENABLED:-auto}"
    CONFIG_EMOJI_ENABLED="${CONFIG_EMOJI_ENABLED:-true}"
    CONFIG_OUTPUT_FORMAT="${CONFIG_OUTPUT_FORMAT:-detailed}"  # detailed, compact, minimal, json

    # Animation System (Global - applies to all themes)
    CONFIG_ANIMATIONS_ENABLED="${CONFIG_ANIMATIONS_ENABLED:-true}"
    CONFIG_ANIMATION_SPEED="${CONFIG_ANIMATION_SPEED:-normal}"  # slow, normal, fast, instant
    CONFIG_ANIMATION_STYLE="${CONFIG_ANIMATION_STYLE:-standard}"  # standard, minimal, fancy

    # Paths
    CONFIG_CLAUDE_DIR="${CONFIG_CLAUDE_DIR:-$HOME/.claude}"
    CONFIG_STATS_FILE="${CONFIG_STATS_FILE:-$CONFIG_CLAUDE_DIR/stats-cache.json}"
    CONFIG_DATA_DIR="${CONFIG_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/burnrate}"
    CONFIG_CACHE_DIR="${CONFIG_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/burnrate}"

    # Budget (Simple)
    CONFIG_DAILY_BUDGET="${CONFIG_DAILY_BUDGET:-0.00}"
    CONFIG_MONTHLY_BUDGET="${CONFIG_MONTHLY_BUDGET:-0.00}"
    CONFIG_BUDGET_ALERT="${CONFIG_BUDGET_ALERT:-90}"  # Single threshold percentage

    # Behavior
    CONFIG_DEBUG="${CONFIG_DEBUG:-false}"
    CONFIG_QUIET="${CONFIG_QUIET:-false}"
    CONFIG_SHOW_DISCLAIMER="${CONFIG_SHOW_DISCLAIMER:-true}"

    # Formatting
    CONFIG_COST_DECIMALS="${CONFIG_COST_DECIMALS:-2}"  # Number of decimal places for cost display

    log_debug "Configuration defaults set"
}

# ============================================================================
# Configuration File Parsing
# ============================================================================

# Parse configuration file (bash variable format)
parse_config_file() {
    local config_file="$1"

    [[ ! -f "$config_file" ]] && return 1

    log_debug "Loading config from: $config_file"

    # Parse line by line
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Trim whitespace and quotes
        key=$(trim "$key")
        value=$(trim "$value")
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"

        # Export as CONFIG_ prefixed variable
        if [[ "$key" =~ ^[A-Z_]+$ ]]; then
            export "CONFIG_$key=$value"
            log_debug "  $key=$value"
        fi
    done < "$config_file"

    return 0
}

# ============================================================================
# Configuration Loading
# ============================================================================

# Load configuration (defaults + file + env overrides)
load_config() {
    log_debug "Loading configuration..."

    # Step 1: Set defaults
    set_config_defaults

    # Step 2: Load from file if exists
    local config_file
    if config_file=$(find_config_file); then
        log_debug "Using config: $config_file"
        parse_config_file "$config_file" || log_warn "Failed to parse config file"
    else
        log_debug "No config file found, using defaults"
    fi

    # Step 3: Environment variables override (CONFIG_* from env take precedence)

    log_debug "Configuration loaded successfully"
}

# ============================================================================
# Configuration Validation
# ============================================================================

# Validate configuration values
validate_config() {
    log_debug "Validating configuration..."

    # Validate paths exist
    [[ ! -d "$CONFIG_CLAUDE_DIR" ]] && die_config "Claude directory not found: $CONFIG_CLAUDE_DIR"
    [[ ! -f "$CONFIG_STATS_FILE" ]] && die_config "Stats file not found: $CONFIG_STATS_FILE"

    # Create data directories if needed
    mkdir -p "$CONFIG_DATA_DIR" "$CONFIG_CACHE_DIR" 2>/dev/null || true

    # Validate budgets are numbers
    is_number "$CONFIG_DAILY_BUDGET" || die_config "DAILY_BUDGET must be a number"
    is_number "$CONFIG_MONTHLY_BUDGET" || die_config "MONTHLY_BUDGET must be a number"

    # Validate enums
    case "$CONFIG_OUTPUT_FORMAT" in
        compact|detailed|minimal|json) ;;
        *) die_config "Invalid output format: $CONFIG_OUTPUT_FORMAT" ;;
    esac

    case "$CONFIG_ANIMATION_SPEED" in
        slow|normal|fast|instant) ;;
        *) die_config "Invalid animation speed: $CONFIG_ANIMATION_SPEED" ;;
    esac

    case "$CONFIG_ANIMATION_STYLE" in
        standard|minimal|fancy) ;;
        *) die_config "Invalid animation style: $CONFIG_ANIMATION_STYLE" ;;
    esac

    log_debug "Configuration validated successfully"
}

# ============================================================================
# Configuration Generation
# ============================================================================

# Generate example configuration file
generate_config_example() {
    cat <<'EOF'
# Burnrate Configuration
# ~/.config/burnrate/burnrate.conf

# ============================================================================
# DISPLAY
# ============================================================================

# Theme: glacial, ember, battery, hourglass, garden, ocean, space
THEME=glacial

# Enable colored output (true/false/auto)
COLORS_ENABLED=auto

# Show emoji (true/false)
EMOJI_ENABLED=true

# Output format: detailed, compact, minimal, json
OUTPUT_FORMAT=detailed

# ============================================================================
# ANIMATION SYSTEM (Global - applies to all themes)
# ============================================================================

# Enable animations (true/false)
ANIMATIONS_ENABLED=true

# Animation speed: slow, normal, fast, instant
ANIMATION_SPEED=normal

# Animation style: standard, minimal, fancy
ANIMATION_STYLE=standard

# ============================================================================
# PATHS
# ============================================================================

# Claude directory
CLAUDE_DIR=$HOME/.claude

# Stats cache file
STATS_FILE=$CLAUDE_DIR/stats-cache.json

# Data directory
DATA_DIR=$HOME/.local/share/burnrate

# Cache directory
CACHE_DIR=$HOME/.cache/burnrate

# ============================================================================
# BUDGET
# ============================================================================

# Daily budget (0 = no limit)
DAILY_BUDGET=0.00

# Monthly budget (0 = no limit)
MONTHLY_BUDGET=0.00

# Alert threshold percentage (0-100)
BUDGET_ALERT=90

# ============================================================================
# BEHAVIOR
# ============================================================================

# Enable debug logging
DEBUG=false

# Quiet mode (minimal output)
QUIET=false

# Show "zero tokens used" disclaimer
SHOW_DISCLAIMER=true
EOF
}

# Create default config file
create_default_config() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/burnrate"
    local config_file="$config_dir/burnrate.conf"

    if [[ -f "$config_file" ]]; then
        log_warn "Config file already exists: $config_file"
        return 1
    fi

    mkdir -p "$config_dir"
    generate_config_example > "$config_file"
    log_debug "Created config file: $config_file"
    return 0
}

# ============================================================================
# Configuration Display
# ============================================================================

# Show current configuration (themed output)
show_config() {
    local h="${THEME_PRIMARY:-\033[1;36m}"
    local b="\033[1m"
    local d="\033[2m"
    local y="${THEME_WARNING:-\033[0;33m}"
    local r="\033[0m"

    echo -e "${h}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${r}"
    echo -e "  ${h}Burnrate Configuration${r}"
    echo -e "${h}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${r}"
    echo ""

    echo -e "  ${b}Display${r}"
    printf "  ${d}%-12s${r}  %s\n" "Theme"   "$CONFIG_THEME"
    printf "  ${d}%-12s${r}  %s\n" "Colors"  "$CONFIG_COLORS_ENABLED"
    printf "  ${d}%-12s${r}  %s\n" "Emoji"   "$CONFIG_EMOJI_ENABLED"
    printf "  ${d}%-12s${r}  %s\n" "Format"  "$CONFIG_OUTPUT_FORMAT"
    echo ""

    echo -e "  ${b}Animation${r}"
    printf "  ${d}%-12s${r}  %s\n" "Enabled" "$CONFIG_ANIMATIONS_ENABLED"
    printf "  ${d}%-12s${r}  %s\n" "Speed"   "$CONFIG_ANIMATION_SPEED"
    printf "  ${d}%-12s${r}  %s\n" "Style"   "$CONFIG_ANIMATION_STYLE"
    echo ""

    echo -e "  ${b}Paths${r}"
    printf "  ${d}%-12s${r}  %s\n" "Claude"  "$CONFIG_CLAUDE_DIR"
    printf "  ${d}%-12s${r}  %s\n" "Stats"   "$CONFIG_STATS_FILE"
    printf "  ${d}%-12s${r}  %s\n" "Data"    "$CONFIG_DATA_DIR"
    echo ""

    echo -e "  ${b}Budget${r}"
    if [[ "${CONFIG_DAILY_BUDGET:-0.00}" == "0.00" || "${CONFIG_DAILY_BUDGET:-0.00}" == "0" ]]; then
        printf "  ${d}%-12s${r}  ${d}unlimited${r}\n" "Daily"
    else
        printf "  ${d}%-12s${r}  ${y}\$%s${r}\n" "Daily" "$CONFIG_DAILY_BUDGET"
    fi
    if [[ "${CONFIG_MONTHLY_BUDGET:-0.00}" == "0.00" || "${CONFIG_MONTHLY_BUDGET:-0.00}" == "0" ]]; then
        printf "  ${d}%-12s${r}  ${d}unlimited${r}\n" "Monthly"
    else
        printf "  ${d}%-12s${r}  ${y}\$%s${r}\n" "Monthly" "$CONFIG_MONTHLY_BUDGET"
    fi
    printf "  ${d}%-12s${r}  %s\n" "Alert"   "${CONFIG_BUDGET_ALERT}%"
    echo ""

    echo -e "  ${b}Config file${r}"
    local config_file
    if config_file=$(find_config_file); then
        printf "  ${d}%-12s${r}  %s\n" "Location" "$config_file"
    else
        printf "  ${d}%-12s${r}  %s\n" "Location" "(defaults — run: burnrate setup)"
    fi
    echo ""
}

log_debug "Config system loaded (15 core options)"
