#!/usr/bin/env bash
# lib/config.sh - Configuration management for burnrate
# Handles loading, parsing, validation, and defaults

# Source core utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/core.sh"

# ============================================================================
# Configuration Paths (Priority Order)
# ============================================================================

# Config file locations (checked in order)
get_config_paths() {
    local paths=()

    # 1. CLI argument (--config <file>)
    if [[ -n "${BURNRATE_CONFIG_FILE:-}" ]]; then
        paths+=("$BURNRATE_CONFIG_FILE")
    fi

    # 2. Environment variable
    if [[ -n "${BURNRATE_CONFIG:-}" ]]; then
        paths+=("$BURNRATE_CONFIG")
    fi

    # 3. XDG config (preferred)
    local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
    paths+=("$xdg_config/burnrate/burnrate.conf")

    # 4. Legacy home directory
    paths+=("$HOME/.burnrate.conf")

    # 5. System-wide config
    paths+=("/etc/burnrate/burnrate.conf")

    printf '%s\n' "${paths[@]}"
}

# Find first existing config file
find_config_file() {
    local path
    while IFS= read -r path; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done < <(get_config_paths)

    return 1
}

# ============================================================================
# Default Configuration Values
# ============================================================================

set_config_defaults() {
    # Display settings
    CONFIG_COLORS_ENABLED="${CONFIG_COLORS_ENABLED:-auto}"
    CONFIG_THEME="${CONFIG_THEME:-glacial}"
    CONFIG_EMOJI_ENABLED="${CONFIG_EMOJI_ENABLED:-true}"
    CONFIG_ANIMATIONS_ENABLED="${CONFIG_ANIMATIONS_ENABLED:-true}"
    CONFIG_ANIMATION_SPEED="${CONFIG_ANIMATION_SPEED:-normal}"
    CONFIG_OUTPUT_FORMAT="${CONFIG_OUTPUT_FORMAT:-detailed}"
    CONFIG_NUMBER_FORMAT="${CONFIG_NUMBER_FORMAT:-commas}"
    CONFIG_CURRENCY_DECIMALS="${CONFIG_CURRENCY_DECIMALS:-2}"
    CONFIG_DATE_FORMAT="${CONFIG_DATE_FORMAT:-iso}"
    CONFIG_TIME_FORMAT="${CONFIG_TIME_FORMAT:-24h}"
    CONFIG_TIMEZONE="${CONFIG_TIMEZONE:-system}"

    # Paths & data
    CONFIG_CLAUDE_DIR="${CONFIG_CLAUDE_DIR:-$HOME/.claude}"
    CONFIG_STATS_FILE="${CONFIG_STATS_FILE:-$CONFIG_CLAUDE_DIR/stats-cache.json}"
    CONFIG_DATA_DIR="${CONFIG_DATA_DIR:-$HOME/.local/share/burnrate}"
    CONFIG_CACHE_DIR="${CONFIG_CACHE_DIR:-$HOME/.cache/burnrate}"
    CONFIG_LOG_FILE="${CONFIG_LOG_FILE:-}"

    # Model pricing (per 1M tokens)
    CONFIG_SONNET_INPUT_PRICE="${CONFIG_SONNET_INPUT_PRICE:-3.00}"
    CONFIG_SONNET_OUTPUT_PRICE="${CONFIG_SONNET_OUTPUT_PRICE:-15.00}"
    CONFIG_SONNET_CACHE_WRITE_PRICE="${CONFIG_SONNET_CACHE_WRITE_PRICE:-3.75}"
    CONFIG_SONNET_CACHE_READ_PRICE="${CONFIG_SONNET_CACHE_READ_PRICE:-0.30}"

    CONFIG_OPUS_INPUT_PRICE="${CONFIG_OPUS_INPUT_PRICE:-15.00}"
    CONFIG_OPUS_OUTPUT_PRICE="${CONFIG_OPUS_OUTPUT_PRICE:-75.00}"
    CONFIG_OPUS_CACHE_WRITE_PRICE="${CONFIG_OPUS_CACHE_WRITE_PRICE:-18.75}"
    CONFIG_OPUS_CACHE_READ_PRICE="${CONFIG_OPUS_CACHE_READ_PRICE:-1.50}"

    CONFIG_HAIKU_INPUT_PRICE="${CONFIG_HAIKU_INPUT_PRICE:-0.25}"
    CONFIG_HAIKU_OUTPUT_PRICE="${CONFIG_HAIKU_OUTPUT_PRICE:-1.25}"
    CONFIG_HAIKU_CACHE_WRITE_PRICE="${CONFIG_HAIKU_CACHE_WRITE_PRICE:-0.31}"
    CONFIG_HAIKU_CACHE_READ_PRICE="${CONFIG_HAIKU_CACHE_READ_PRICE:-0.03}"

    CONFIG_CURRENCY_SYMBOL="${CONFIG_CURRENCY_SYMBOL:-\$}"
    CONFIG_CURRENCY_RATE="${CONFIG_CURRENCY_RATE:-1.0}"

    # Budget settings
    CONFIG_DAILY_BUDGET="${CONFIG_DAILY_BUDGET:-0.00}"
    CONFIG_WEEKLY_BUDGET="${CONFIG_WEEKLY_BUDGET:-0.00}"
    CONFIG_MONTHLY_BUDGET="${CONFIG_MONTHLY_BUDGET:-0.00}"
    CONFIG_BUDGET_ALERT_THRESHOLDS="${CONFIG_BUDGET_ALERT_THRESHOLDS:-50,75,90,100}"
    CONFIG_BUDGET_ALERT_METHOD="${CONFIG_BUDGET_ALERT_METHOD:-console}"
    CONFIG_CACHE_HIT_WARNING="${CONFIG_CACHE_HIT_WARNING:-80}"

    # Notifications
    CONFIG_DESKTOP_NOTIFICATIONS="${CONFIG_DESKTOP_NOTIFICATIONS:-false}"
    CONFIG_NOTIFICATION_TOOL="${CONFIG_NOTIFICATION_TOOL:-auto}"
    CONFIG_SLACK_WEBHOOK_URL="${CONFIG_SLACK_WEBHOOK_URL:-}"
    CONFIG_DISCORD_WEBHOOK_URL="${CONFIG_DISCORD_WEBHOOK_URL:-}"
    CONFIG_CUSTOM_WEBHOOK_URL="${CONFIG_CUSTOM_WEBHOOK_URL:-}"
    CONFIG_EMAIL_NOTIFICATIONS="${CONFIG_EMAIL_NOTIFICATIONS:-false}"
    CONFIG_EMAIL_TO="${CONFIG_EMAIL_TO:-}"
    CONFIG_EMAIL_FROM="${CONFIG_EMAIL_FROM:-burnrate@localhost}"
    CONFIG_EMAIL_SUBJECT_PREFIX="${CONFIG_EMAIL_SUBJECT_PREFIX:-[burnrate]}"

    # Features & behavior
    CONFIG_AUTO_UPDATE_CHECK="${CONFIG_AUTO_UPDATE_CHECK:-true}"
    CONFIG_SHOW_TIPS="${CONFIG_SHOW_TIPS:-true}"
    CONFIG_CONFIRM_ACTIONS="${CONFIG_CONFIRM_ACTIONS:-true}"
    CONFIG_DEBUG="${CONFIG_DEBUG:-false}"
    CONFIG_QUIET="${CONFIG_QUIET:-false}"
    CONFIG_SHOW_TOKEN_DISCLAIMER="${CONFIG_SHOW_TOKEN_DISCLAIMER:-true}"

    # Export & reporting
    CONFIG_DEFAULT_EXPORT_FORMAT="${CONFIG_DEFAULT_EXPORT_FORMAT:-csv}"
    CONFIG_EXPORT_DIR="${CONFIG_EXPORT_DIR:-$HOME/Documents/burnrate-exports}"
    CONFIG_REPORT_INCLUDE_CHARTS="${CONFIG_REPORT_INCLUDE_CHARTS:-false}"
    CONFIG_REPORT_TEMPLATE="${CONFIG_REPORT_TEMPLATE:-}"
    CONFIG_EXPORT_ARCHIVE_DAYS="${CONFIG_EXPORT_ARCHIVE_DAYS:-30}"

    # Experimental
    CONFIG_EXPERIMENTAL="${CONFIG_EXPERIMENTAL:-false}"
    CONFIG_TUI_ENABLED="${CONFIG_TUI_ENABLED:-false}"
    CONFIG_PREDICTIONS_ENABLED="${CONFIG_PREDICTIONS_ENABLED:-false}"
    CONFIG_PROJECT_TRACKING="${CONFIG_PROJECT_TRACKING:-false}"

    log_debug "Configuration defaults set"
}

# ============================================================================
# Configuration File Parsing
# ============================================================================

# Parse configuration file (bash variable format)
parse_config_file() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        log_debug "Config file not found: $config_file"
        return 1
    fi

    log_debug "Loading config from: $config_file"

    # Source config file in subshell to avoid pollution
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Trim whitespace
        key=$(trim "$key")
        value=$(trim "$value")

        # Remove quotes from value
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
        log_info "Using config: $config_file"
        parse_config_file "$config_file" || log_warn "Failed to parse config file"
    else
        log_debug "No config file found, using defaults"
    fi

    # Step 3: Environment variables override
    # (CONFIG_* vars from environment take precedence)

    log_debug "Configuration loaded successfully"
}

# ============================================================================
# Configuration Validation
# ============================================================================

# Validate configuration values
validate_config() {
    log_debug "Validating configuration..."

    # Validate paths exist (create if needed)
    if [[ ! -d "$CONFIG_CLAUDE_DIR" ]]; then
        die_config "Claude directory not found: $CONFIG_CLAUDE_DIR\n  Run Claude Code at least once"
    fi

    if [[ ! -f "$CONFIG_STATS_FILE" ]]; then
        die_config "Stats file not found: $CONFIG_STATS_FILE\n  Run Claude Code to generate stats"
    fi

    # Create data directories if needed
    mkdir -p "$CONFIG_DATA_DIR" 2>/dev/null || true
    mkdir -p "$CONFIG_CACHE_DIR" 2>/dev/null || true

    # Validate numeric values
    validate_range "$CONFIG_CURRENCY_DECIMALS" 0 6 "CURRENCY_DECIMALS"

    if ! is_number "$CONFIG_DAILY_BUDGET"; then
        die_config "DAILY_BUDGET must be a number, got: $CONFIG_DAILY_BUDGET"
    fi

    if ! is_number "$CONFIG_WEEKLY_BUDGET"; then
        die_config "WEEKLY_BUDGET must be a number, got: $CONFIG_WEEKLY_BUDGET"
    fi

    if ! is_number "$CONFIG_MONTHLY_BUDGET"; then
        die_config "MONTHLY_BUDGET must be a number, got: $CONFIG_MONTHLY_BUDGET"
    fi

    # Validate enum values
    case "$CONFIG_THEME" in
        glacial|ember|battery|hourglass|garden|ocean|space) ;;
        *) die_config "Invalid theme: $CONFIG_THEME" ;;
    esac

    case "$CONFIG_OUTPUT_FORMAT" in
        compact|detailed|minimal|json) ;;
        *) die_config "Invalid output format: $CONFIG_OUTPUT_FORMAT" ;;
    esac

    case "$CONFIG_ANIMATION_SPEED" in
        slow|normal|fast|instant) ;;
        *) die_config "Invalid animation speed: $CONFIG_ANIMATION_SPEED" ;;
    esac

    log_debug "Configuration validated successfully"
}

# ============================================================================
# Configuration Generation
# ============================================================================

# Generate example configuration file
generate_config_example() {
    cat <<'EOF'
# Burnrate Configuration File
# Copy to ~/.config/burnrate/burnrate.conf and customize

# ============================================================================
# DISPLAY SETTINGS
# ============================================================================

# Enable colored output (true/false/auto)
COLORS_ENABLED=auto

# Theme: glacial, ember, battery, hourglass, garden, ocean, space
THEME=glacial

# Show emoji (true/false)
EMOJI_ENABLED=true

# Enable animations (true/false)
ANIMATIONS_ENABLED=true

# Animation speed: slow, normal, fast, instant
ANIMATION_SPEED=normal

# Output format: compact, detailed, minimal, json
OUTPUT_FORMAT=detailed

# Number format: commas, spaces, none
NUMBER_FORMAT=commas

# Currency decimal places (0-6)
CURRENCY_DECIMALS=2

# Date format: iso, us, eu, unix
DATE_FORMAT=iso

# Time format: 12h, 24h
TIME_FORMAT=24h

# Timezone: system, utc, or IANA (America/New_York)
TIMEZONE=system

# ============================================================================
# PATHS & DATA
# ============================================================================

# Claude directory
CLAUDE_DIR=$HOME/.claude

# Stats cache file
STATS_FILE=$CLAUDE_DIR/stats-cache.json

# Burnrate data directory
DATA_DIR=$HOME/.local/share/burnrate

# Cache directory
CACHE_DIR=$HOME/.cache/burnrate

# Log file (empty = no logging)
LOG_FILE=

# ============================================================================
# MODEL PRICING (per 1M tokens)
# ============================================================================

# Claude Sonnet 4.5
SONNET_INPUT_PRICE=3.00
SONNET_OUTPUT_PRICE=15.00
SONNET_CACHE_WRITE_PRICE=3.75
SONNET_CACHE_READ_PRICE=0.30

# Claude Opus 4
OPUS_INPUT_PRICE=15.00
OPUS_OUTPUT_PRICE=75.00
OPUS_CACHE_WRITE_PRICE=18.75
OPUS_CACHE_READ_PRICE=1.50

# Claude Haiku 4
HAIKU_INPUT_PRICE=0.25
HAIKU_OUTPUT_PRICE=1.25
HAIKU_CACHE_WRITE_PRICE=0.31
HAIKU_CACHE_READ_PRICE=0.03

# Currency
CURRENCY_SYMBOL=$
CURRENCY_RATE=1.0

# ============================================================================
# BUDGET SETTINGS
# ============================================================================

# Budget limits (0 = no limit)
DAILY_BUDGET=0.00
WEEKLY_BUDGET=0.00
MONTHLY_BUDGET=0.00

# Alert thresholds (percentages)
BUDGET_ALERT_THRESHOLDS=50,75,90,100

# Alert method: none, console, desktop, email, webhook
BUDGET_ALERT_METHOD=console

# Cache hit warning threshold (%)
CACHE_HIT_WARNING=80

# ============================================================================
# NOTIFICATIONS
# ============================================================================

# Desktop notifications
DESKTOP_NOTIFICATIONS=false
NOTIFICATION_TOOL=auto

# Webhooks
SLACK_WEBHOOK_URL=
DISCORD_WEBHOOK_URL=
CUSTOM_WEBHOOK_URL=

# Email
EMAIL_NOTIFICATIONS=false
EMAIL_TO=
EMAIL_FROM=burnrate@localhost
EMAIL_SUBJECT_PREFIX=[burnrate]

# ============================================================================
# FEATURES & BEHAVIOR
# ============================================================================

AUTO_UPDATE_CHECK=true
SHOW_TIPS=true
CONFIRM_ACTIONS=true
DEBUG=false
QUIET=false
SHOW_TOKEN_DISCLAIMER=true

# ============================================================================
# EXPORT & REPORTING
# ============================================================================

DEFAULT_EXPORT_FORMAT=csv
EXPORT_DIR=$HOME/Documents/burnrate-exports
REPORT_INCLUDE_CHARTS=false
REPORT_TEMPLATE=
EXPORT_ARCHIVE_DAYS=30

# ============================================================================
# EXPERIMENTAL FEATURES
# ============================================================================

EXPERIMENTAL=false
TUI_ENABLED=false
PREDICTIONS_ENABLED=false
PROJECT_TRACKING=false
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
    log_info "Created config file: $config_file"
    return 0
}

# ============================================================================
# Configuration Display
# ============================================================================

# Show current configuration
show_config() {
    echo "Burnrate Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Display:"
    echo "  Theme:      $CONFIG_THEME"
    echo "  Colors:     $CONFIG_COLORS_ENABLED"
    echo "  Emoji:      $CONFIG_EMOJI_ENABLED"
    echo "  Animations: $CONFIG_ANIMATIONS_ENABLED"
    echo "  Format:     $CONFIG_OUTPUT_FORMAT"
    echo ""
    echo "Paths:"
    echo "  Claude:     $CONFIG_CLAUDE_DIR"
    echo "  Stats:      $CONFIG_STATS_FILE"
    echo "  Data:       $CONFIG_DATA_DIR"
    echo ""
    echo "Budget:"
    echo "  Daily:      $(format_currency "$CONFIG_DAILY_BUDGET")"
    echo "  Weekly:     $(format_currency "$CONFIG_WEEKLY_BUDGET")"
    echo "  Monthly:    $(format_currency "$CONFIG_MONTHLY_BUDGET")"
    echo ""
    echo "Config file:"
    local config_file
    if config_file=$(find_config_file); then
        echo "  $config_file"
    else
        echo "  (using defaults)"
    fi
}
