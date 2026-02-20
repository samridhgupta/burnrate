#!/usr/bin/env bash
# lib/core.sh - Core utilities for burnrate
# Robust, composable functions for logging, error handling, and system info

# Source guard (prevent double-sourcing)
[[ -n "${BURNRATE_CORE_LOADED:-}" ]] && return 0
readonly BURNRATE_CORE_LOADED=1

set -euo pipefail

# Version and metadata
readonly BURNRATE_VERSION="0.8.1"
readonly BURNRATE_NAME="burnrate"
readonly BURNRATE_DESCRIPTION="Track your Claude token burn"

# Exit codes (standard conventions)
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_USAGE=2
readonly EXIT_CONFIG=3
readonly EXIT_NOTFOUND=4
readonly EXIT_PERMISSION=5

# Global state
BURNRATE_DEBUG="${BURNRATE_DEBUG:-false}"
BURNRATE_QUIET="${BURNRATE_QUIET:-false}"
BURNRATE_LOG_FILE="${BURNRATE_LOG_FILE:-}"
BURNRATE_COLOR="${BURNRATE_COLOR:-auto}"

# ============================================================================
# Color Functions (theme-agnostic base colors)
# ============================================================================

# Detect color support
has_color_support() {
    [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]
}

# Initialize colors based on settings
init_colors() {
    if [[ "$BURNRATE_COLOR" == "never" ]] || { [[ "$BURNRATE_COLOR" == "auto" ]] && ! has_color_support; }; then
        # No color
        C_RESET=""
        C_BOLD=""
        C_DIM=""
        C_RED=""
        C_GREEN=""
        C_YELLOW=""
        C_BLUE=""
        C_CYAN=""
        C_WHITE=""
    else
        # Color enabled
        C_RESET='\033[0m'
        C_BOLD='\033[1m'
        C_DIM='\033[2m'
        C_RED='\033[0;31m'
        C_GREEN='\033[0;32m'
        C_YELLOW='\033[1;33m'
        C_BLUE='\033[0;34m'
        C_CYAN='\033[0;36m'
        C_WHITE='\033[1;37m'
    fi
}

# ============================================================================
# Logging Functions
# ============================================================================

# Log levels
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3

# Get log level name
log_level_name() {
    case "$1" in
        $LOG_DEBUG) echo "DEBUG" ;;
        $LOG_INFO)  echo "INFO"  ;;
        $LOG_WARN)  echo "WARN"  ;;
        $LOG_ERROR) echo "ERROR" ;;
        *) echo "UNKNOWN" ;;
    esac
}

# Core logging function
_log() {
    local level=$1
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Skip debug logs unless debug mode
    if [[ $level -eq $LOG_DEBUG ]] && [[ "$BURNRATE_DEBUG" != "true" ]]; then
        return 0
    fi

    # Skip all logs in quiet mode except errors
    if [[ "$BURNRATE_QUIET" == "true" ]] && [[ $level -lt $LOG_ERROR ]]; then
        return 0
    fi

    # Format message
    local level_name
    level_name=$(log_level_name "$level")
    local color=""
    local reset="$C_RESET"

    case "$level" in
        $LOG_DEBUG) color="$C_DIM" ;;
        $LOG_INFO)  color="$C_CYAN" ;;
        $LOG_WARN)  color="$C_YELLOW" ;;
        $LOG_ERROR) color="$C_RED" ;;
    esac

    # Output to stderr for warnings and errors
    local output_fd=1
    [[ $level -ge $LOG_WARN ]] && output_fd=2

    # Console output
    if [[ "$BURNRATE_QUIET" != "true" ]] || [[ $level -eq $LOG_ERROR ]]; then
        echo -e "${color}[${level_name}]${reset} ${message}" >&$output_fd
    fi

    # File logging
    if [[ -n "$BURNRATE_LOG_FILE" ]]; then
        echo "[${timestamp}] [${level_name}] ${message}" >> "$BURNRATE_LOG_FILE"
    fi
}

# Public logging functions
log_debug() { _log $LOG_DEBUG "$@"; }
log_info() { _log $LOG_INFO "$@"; }
log_warn() { _log $LOG_WARN "$@"; }
log_error() { _log $LOG_ERROR "$@"; }

# ============================================================================
# Error Handling
# ============================================================================

# Die with error message
die() {
    log_error "$@"
    exit $EXIT_ERROR
}

# Die with usage error
die_usage() {
    log_error "$@"
    exit $EXIT_USAGE
}

# Die with config error
die_config() {
    log_error "$@"
    exit $EXIT_CONFIG
}

# Assert condition
assert() {
    local condition=$1
    shift
    local message="$*"

    if ! eval "$condition"; then
        die "Assertion failed: $message"
    fi
}

# Require command exists
require_command() {
    local cmd=$1
    local hint="${2:-Install $cmd to continue}"

    if ! command -v "$cmd" &>/dev/null; then
        die "Required command not found: $cmd\n  Hint: $hint"
    fi
}

# Require file exists
require_file() {
    local file=$1
    local hint="${2:-File is required}"

    if [[ ! -f "$file" ]]; then
        die "Required file not found: $file\n  Hint: $hint"
    fi
}

# Require directory exists
require_directory() {
    local dir=$1
    local hint="${2:-Directory is required}"

    if [[ ! -d "$dir" ]]; then
        die "Required directory not found: $dir\n  Hint: $hint"
    fi
}

# ============================================================================
# Formatting Utilities
# ============================================================================

# Format cost to configured decimal places
# Usage: format_cost "123.456789"
# Output: "123.46" (if CONFIG_COST_DECIMALS=2)
format_cost() {
    local cost="$1"
    local decimals="${CONFIG_COST_DECIMALS:-2}"

    # Handle empty or invalid input
    if [[ -z "$cost" ]] || [[ ! "$cost" =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
        printf "0.%0${decimals}d" 0
        return 0
    fi

    # Use printf to format to specified decimal places
    printf "%.${decimals}f" "$cost" 2>/dev/null || echo "0.00"
}

# ============================================================================
# System Detection
# ============================================================================

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux) echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

# Detect shell
detect_shell() {
    basename "$SHELL"
}

# Check if running in CI
is_ci() {
    [[ -n "${CI:-}" ]] || [[ -n "${CONTINUOUS_INTEGRATION:-}" ]]
}

# Check if running in terminal
is_terminal() {
    [[ -t 1 ]]
}

# ============================================================================
# Path Utilities
# ============================================================================

# Get script directory
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [[ -h "$source" ]]; do
        local dir
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

# Get burnrate root directory
get_burnrate_root() {
    local script_dir
    script_dir="$(get_script_dir)"
    cd "$script_dir/.." && pwd
}

# Expand path (resolve ~, ., ..)
expand_path() {
    local path="$1"

    # Expand tilde
    path="${path/#\~/$HOME}"

    # Resolve to absolute path
    if [[ -e "$path" ]]; then
        cd "$(dirname "$path")" && pwd -P
        echo "/$(basename "$path")"
    else
        echo "$path"
    fi
}

# ============================================================================
# String Utilities
# ============================================================================

# Trim whitespace
trim() {
    local str="$1"
    # Remove leading whitespace
    str="${str#"${str%%[![:space:]]*}"}"
    # Remove trailing whitespace
    str="${str%"${str##*[![:space:]]}"}"
    echo "$str"
}

# Convert to lowercase
to_lower() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Convert to uppercase
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Check if string starts with prefix
starts_with() {
    [[ "$1" == "$2"* ]]
}

# Check if string ends with suffix
ends_with() {
    [[ "$1" == *"$2" ]]
}

# Check if string contains substring
contains() {
    [[ "$1" == *"$2"* ]]
}

# ============================================================================
# Number Utilities
# ============================================================================

# Check if string is a number
is_number() {
    [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]
}

# Check if string is an integer
is_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# Format number with commas (12345 -> 12,345)
format_number() {
    printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# Format currency ($1.2345 -> $1.23)
format_currency() {
    local amount=$1
    local decimals=${2:-2}
    printf "\$%.${decimals}f" "$amount"
}

# ============================================================================
# Boolean Utilities
# ============================================================================

# Parse boolean string
parse_bool() {
    local val
    val=$(to_lower "$1")
    case "$val" in
        true|yes|y|1|on|enabled) echo "true" ;;
        false|no|n|0|off|disabled) echo "false" ;;
        *) echo "false" ;;
    esac
}

# Check if value is truthy
is_true() {
    [[ "$(parse_bool "$1")" == "true" ]]
}

# ============================================================================
# Validation
# ============================================================================

# Validate required variables
validate_required() {
    local var_name=$1
    local var_value="${!var_name:-}"

    if [[ -z "$var_value" ]]; then
        die_config "Required configuration missing: $var_name"
    fi
}

# Validate number in range
validate_range() {
    local value=$1
    local min=$2
    local max=$3
    local name="${4:-value}"

    if ! is_number "$value"; then
        die_config "$name must be a number, got: $value"
    fi

    if (( $(echo "$value < $min" | bc -l) )); then
        die_config "$name must be >= $min, got: $value"
    fi

    if (( $(echo "$value > $max" | bc -l) )); then
        die_config "$name must be <= $max, got: $value"
    fi
}

# ============================================================================
# Initialization
# ============================================================================

# Initialize core system
init_core() {
    init_colors
    log_debug "Core initialized (v$BURNRATE_VERSION)"
    log_debug "OS: $(detect_os), Shell: $(detect_shell)"
    log_debug "Terminal: $(is_terminal && echo yes || echo no)"
    log_debug "CI: $(is_ci && echo yes || echo no)"
}

# Run initialization if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    init_core
fi
