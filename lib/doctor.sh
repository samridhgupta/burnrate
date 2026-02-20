#!/usr/bin/env bash
# lib/doctor.sh - Health check and diagnostics for burnrate
#
# Usage: burnrate doctor [--fix] [--verbose]
#   --fix      Attempt to auto-fix found issues
#   --verbose  Show extra detail on each check

source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"

# ============================================================================
# Doctor State
# ============================================================================

_DOCTOR_PASS=0
_DOCTOR_WARN=0
_DOCTOR_FAIL=0

_pass() {
    _DOCTOR_PASS=$((_DOCTOR_PASS + 1))
    echo -e "  \033[0;32m✓\033[0m  $*"
}

_warn() {
    _DOCTOR_WARN=$((_DOCTOR_WARN + 1))
    echo -e "  \033[0;33m⚠\033[0m  $*"
}

_fail() {
    _DOCTOR_FAIL=$((_DOCTOR_FAIL + 1))
    echo -e "  \033[0;31m✗\033[0m  $*"
}

_info() {
    echo -e "  \033[1;36m→\033[0m  $*"
}

_section() {
    echo ""
    echo -e "\033[1;37m$*\033[0m"
    echo "  ─────────────────────────────────────────"
}

# ============================================================================
# Checks
# ============================================================================

check_system() {
    _section "System"

    # OS
    local os
    os=$(uname -s)
    _pass "OS: $os $(uname -r | cut -d- -f1)"

    # Bash version
    local bash_major
    bash_major=$(echo "$BASH_VERSION" | cut -d. -f1)
    if [[ "$bash_major" -ge 4 ]]; then
        _pass "Bash $BASH_VERSION (full compatibility)"
    elif [[ "$bash_major" -ge 3 ]]; then
        _warn "Bash $BASH_VERSION (3.2 mode - works but bash 4+ is ideal)"
        _info "macOS: brew install bash"
    else
        _fail "Bash $BASH_VERSION is too old (need 3.2+)"
    fi

    # Terminal
    if [[ -t 1 ]]; then
        local cols
        cols=$(tput cols 2>/dev/null || echo "unknown")
        _pass "Terminal: ${cols} columns"
    else
        _pass "Terminal: non-interactive (piped/redirected output)"
    fi
}

check_dependencies() {
    _section "Dependencies"

    # bc (required)
    if command -v bc >/dev/null 2>&1; then
        local bc_test
        bc_test=$(echo "scale=2; 1.23 * 4.56" | bc 2>/dev/null || echo "")
        if [[ "$bc_test" == "5.60" ]]; then
            _pass "bc $(bc --version 2>/dev/null | head -1 | grep -o '[0-9.]*' | head -1) - math OK"
        else
            _warn "bc installed but math test returned: '$bc_test' (expected 5.60)"
        fi
    else
        _fail "bc not found (REQUIRED for cost calculations)"
        _info "Install: brew install bc  OR  apt-get install bc"
    fi

    # date (required)
    if command -v date >/dev/null 2>&1; then
        # Test BSD vs GNU
        if date -v-1d +%Y-%m-%d >/dev/null 2>&1; then
            _pass "date: BSD mode (macOS)"
        elif date -d "yesterday" +%Y-%m-%d >/dev/null 2>&1; then
            _pass "date: GNU mode (Linux)"
        else
            _warn "date: unknown variant - historical commands may fail"
        fi
    else
        _fail "date not found (required)"
    fi

    # grep (required)
    if command -v grep >/dev/null 2>&1; then
        _pass "grep $(grep --version 2>/dev/null | head -1 | grep -o '[0-9.]*' | head -1)"
    else
        _fail "grep not found (required)"
    fi

    # sed (required)
    if command -v sed >/dev/null 2>&1; then
        _pass "sed available"
    else
        _fail "sed not found (required)"
    fi

    # cut, tr, printf (standard)
    for cmd in cut tr printf; do
        command -v "$cmd" >/dev/null 2>&1 && _pass "$cmd available" || _fail "$cmd not found"
    done

    # Optional
    command -v jq >/dev/null 2>&1 && _pass "jq available (optional, not used)" || true
    command -v curl >/dev/null 2>&1 && _pass "curl available (for remote install)" || _warn "curl not found (needed for remote install)"
    command -v git >/dev/null 2>&1 && _pass "git available" || _warn "git not found (needed for updates)"
}

check_claude() {
    _section "Claude Code"

    # Claude binary
    if command -v claude >/dev/null 2>&1; then
        _pass "claude CLI found: $(command -v claude)"
    else
        _warn "claude CLI not in PATH (burnrate still works if stats file exists)"
    fi

    # Claude directory
    if [[ -d "$HOME/.claude" ]]; then
        _pass "~/.claude directory exists"
    else
        _fail "~/.claude not found - is Claude Code installed?"
        _info "Install: https://claude.ai/download"
        return
    fi

    # Stats file
    local stats_file="${CONFIG_STATS_FILE:-$HOME/.claude/stats-cache.json}"
    if [[ -f "$stats_file" ]]; then
        local size
        size=$(du -h "$stats_file" 2>/dev/null | cut -f1)
        local age
        age=$(( ($(date +%s) - $(date -r "$stats_file" +%s 2>/dev/null || date +%s)) / 60 ))
        _pass "Stats file found: $stats_file ($size, ${age}m ago)"

        # Validate JSON structure (accept any of these known fields)
        if grep -qE '"version"|"model"|"tokens"|"dailyModelTokens"|"totalTokens"' "$stats_file" 2>/dev/null; then
            _pass "Stats file JSON structure OK"
        elif [[ $(wc -c < "$stats_file") -lt 10 ]]; then
            _warn "Stats file is empty - run Claude Code to populate it"
        else
            _warn "Stats file exists but unexpected format (burnrate may still work)"
        fi
    else
        _warn "Stats file not found: $stats_file"
        _info "Run Claude Code at least once to generate it"
        _info "Or set: export CONFIG_STATS_FILE=/path/to/stats-cache.json"
    fi
}

check_burnrate_install() {
    _section "Burnrate Installation"

    local install_dir="${BURNRATE_INSTALL_DIR:-$HOME/.local/bin}"
    local source_dir="$HOME/.local/share/burnrate"
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/burnrate"

    # Binary/symlink
    if [[ -L "$install_dir/burnrate" ]]; then
        local target
        target=$(readlink "$install_dir/burnrate")
        if [[ -f "$target" ]]; then
            _pass "Symlink: $install_dir/burnrate → $target"
        else
            _fail "Broken symlink: $install_dir/burnrate → $target (target missing)"
            _info "Fix: ./install.sh --reinstall"
        fi
    elif [[ -f "$install_dir/burnrate" ]]; then
        _pass "Binary: $install_dir/burnrate"
    else
        _warn "burnrate not found in $install_dir"
        _info "Run: ./install.sh"
    fi

    # Source directory
    if [[ -d "$source_dir" ]]; then
        local lib_count
        lib_count=$(ls "$source_dir/lib/"*.sh 2>/dev/null | wc -l | tr -d ' ')
        _pass "Source: $source_dir (${lib_count} lib files)"
    else
        _warn "Source directory not found: $source_dir"
    fi

    # PATH
    if [[ ":$PATH:" == *":$install_dir:"* ]]; then
        _pass "$install_dir in PATH"
    else
        _warn "$install_dir not in PATH"
        _info "Add to ~/.zshrc: export PATH=\"$install_dir:\$PATH\""
    fi

    # Config directory
    if [[ -d "$config_dir" ]]; then
        _pass "Config dir: $config_dir"
        [[ -f "$config_dir/burnrate.conf" ]] && _pass "Config file found" || _info "No config file (using defaults)"
    else
        _info "Config dir not yet created (will be created on first setup)"
    fi

    # Version
    local ver
    ver=$(burnrate --version 2>/dev/null | head -1 || echo "not runnable")
    _pass "Version: $ver"
}

check_burnrate_functions() {
    _section "Burnrate Functionality"

    # Test: read stats
    if burnrate show >/dev/null 2>&1; then
        _pass "burnrate show - OK"
    else
        _fail "burnrate show - FAILED"
        _info "Run: burnrate show  to see the full error"
    fi

    # Test: budget command
    if burnrate budget >/dev/null 2>&1; then
        _pass "burnrate budget - OK"
    else
        _fail "burnrate budget - FAILED"
    fi

    # Test: history command
    if burnrate history >/dev/null 2>&1; then
        _pass "burnrate history - OK"
    else
        _warn "burnrate history - returned non-zero (may be no history yet)"
    fi

    # Test: export json
    if burnrate export summary json >/dev/null 2>&1; then
        _pass "burnrate export summary json - OK"
    else
        _fail "burnrate export summary json - FAILED"
    fi

    # Test: export csv
    if burnrate export summary csv >/dev/null 2>&1; then
        _pass "burnrate export summary csv - OK"
    else
        _fail "burnrate export summary csv - FAILED"
    fi

    # Test: cost math
    local math_result
    math_result=$(echo "scale=2; 1.50 * 2.00" | bc 2>/dev/null || echo "")
    if [[ "$math_result" == "3.00" ]]; then
        _pass "Cost calculations - bc math OK"
    else
        _fail "bc math returned '$math_result' (expected '3.00')"
    fi
}

check_config() {
    _section "Configuration"

    # Load config
    set_config_defaults 2>/dev/null || true

    _info "Stats file:    ${CONFIG_STATS_FILE}"
    _info "Theme:         ${CONFIG_THEME}"
    _info "Colors:        ${CONFIG_COLORS_ENABLED}"
    _info "Animations:    ${CONFIG_ANIMATIONS_ENABLED}"
    _info "Output format: ${CONFIG_OUTPUT_FORMAT:-detailed}"
    _info "Daily budget:  \$${CONFIG_DAILY_BUDGET}"
    _info "Monthly budget: \$${CONFIG_MONTHLY_BUDGET}"
    _info "Cost decimals: ${CONFIG_COST_DECIMALS}"

    # Theme component overrides
    local _cs="${CONFIG_COLOR_SCHEME:-<theme default>}"
    local _is="${CONFIG_ICON_SET:-<theme default>}"
    local _ms="${CONFIG_MESSAGE_SET:-<theme default>}"
    _info "Color scheme:  ${_cs}"
    _info "Icon set:      ${_is}"
    _info "Message set:   ${_ms}"
    echo ""

    # Validate values
    if [[ "${CONFIG_DAILY_BUDGET}" != "0.00" && "${CONFIG_DAILY_BUDGET}" != "0" ]]; then
        _pass "Daily budget set: \$${CONFIG_DAILY_BUDGET}"
    else
        _warn "No daily budget set (set CONFIG_DAILY_BUDGET to track spending)"
    fi

    if [[ "${CONFIG_MONTHLY_BUDGET}" != "0.00" && "${CONFIG_MONTHLY_BUDGET}" != "0" ]]; then
        _pass "Monthly budget set: \$${CONFIG_MONTHLY_BUDGET}"
    else
        _warn "No monthly budget set (set CONFIG_MONTHLY_BUDGET to track spending)"
    fi

    # Check component files exist if explicitly set
    local _lib_dir
    _lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local _proj_dir
    _proj_dir="$(dirname "$_lib_dir")"

    if [[ -n "${CONFIG_COLOR_SCHEME:-}" && "$CONFIG_COLOR_SCHEME" != "none" ]]; then
        if ls "$_proj_dir"/config/colors/"${CONFIG_COLOR_SCHEME}".colors &>/dev/null \
        || ls "$HOME"/.config/burnrate/colors/"${CONFIG_COLOR_SCHEME}".colors &>/dev/null; then
            _pass "Color scheme '${CONFIG_COLOR_SCHEME}' found"
        else
            _fail "Color scheme '${CONFIG_COLOR_SCHEME}' not found (check config/colors/)"
        fi
    fi

    if [[ -n "${CONFIG_ICON_SET:-}" && "$CONFIG_ICON_SET" != "none" ]]; then
        if ls "$_proj_dir"/config/icons/"${CONFIG_ICON_SET}".icons &>/dev/null \
        || ls "$HOME"/.config/burnrate/icons/"${CONFIG_ICON_SET}".icons &>/dev/null; then
            _pass "Icon set '${CONFIG_ICON_SET}' found"
        else
            _fail "Icon set '${CONFIG_ICON_SET}' not found (check config/icons/)"
        fi
    fi

    if [[ -n "${CONFIG_MESSAGE_SET:-}" ]]; then
        if ls "$_proj_dir"/config/messages/"${CONFIG_MESSAGE_SET}".msgs &>/dev/null \
        || ls "$HOME"/.config/burnrate/messages/"${CONFIG_MESSAGE_SET}".msgs &>/dev/null; then
            _pass "Message set '${CONFIG_MESSAGE_SET}' found"
        else
            _fail "Message set '${CONFIG_MESSAGE_SET}' not found (check config/messages/)"
        fi
    fi
}

# ============================================================================
# Summary
# ============================================================================

show_doctor_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local total=$((_DOCTOR_PASS + _DOCTOR_WARN + _DOCTOR_FAIL))

    echo -e "  \033[0;32m✓ Passed: $_DOCTOR_PASS\033[0m   \033[0;33m⚠ Warnings: $_DOCTOR_WARN\033[0m   \033[0;31m✗ Failed: $_DOCTOR_FAIL\033[0m"
    echo ""

    if [[ "$_DOCTOR_FAIL" -eq 0 && "$_DOCTOR_WARN" -eq 0 ]]; then
        echo -e "  \033[0;32m🎉 Everything looks great! Burnrate is healthy. ❄️\033[0m"
    elif [[ "$_DOCTOR_FAIL" -eq 0 ]]; then
        echo -e "  \033[0;33m⚠  Minor warnings found. Burnrate should still work fine.\033[0m"
    else
        echo -e "  \033[0;31m✗  Issues found. Run 'burnrate doctor' for details.\033[0m"
        echo -e "  \033[1;36m→  Try: ./install.sh --reinstall\033[0m"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Exit code based on failures
    return "$_DOCTOR_FAIL"
}

# ============================================================================
# Entry Point
# ============================================================================

run_doctor() {
    local verbose=false
    local fix=false

    for arg in "$@"; do
        case "$arg" in
            --verbose|-v) verbose=true ;;
            --fix|-f)     fix=true ;;
        esac
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "\033[1;36m  🩺 Burnrate Doctor\033[0m"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    check_system
    check_dependencies
    check_claude
    check_burnrate_install
    check_burnrate_functions
    check_config

    show_doctor_summary
}
