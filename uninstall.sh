#!/usr/bin/env bash
# Burnrate Uninstaller
# Usage: ./uninstall.sh [--purge]
#   --purge  Also remove config and data files

set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly INSTALL_DIR="${BURNRATE_INSTALL_DIR:-$HOME/.local/bin}"
readonly SOURCE_DIR="$HOME/.local/share/burnrate"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/burnrate"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/burnrate"
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/burnrate"

# ============================================================================
# Colors
# ============================================================================

_IC='\033[0m'
_ICY='\033[1;36m'
_IGN='\033[0;32m'
_IYL='\033[0;33m'
_IRD='\033[0;31m'

info()    { echo -e "${_ICY}❄️  $*${_IC}"; }
success() { echo -e "${_IGN}✓ $*${_IC}"; }
warn()    { echo -e "${_IYL}⚠ $*${_IC}"; }
error()   { echo -e "${_IRD}✗ $*${_IC}"; exit 1; }

# ============================================================================
# UI Helpers
# ============================================================================

ask_yn() {
    local question="$1"
    local default="${2:-n}"
    local prompt
    [[ "$default" == "y" ]] && prompt="[Y/n]" || prompt="[y/N]"

    while true; do
        read -rp "$question $prompt " answer
        answer="${answer:-$default}"
        case "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# ============================================================================
# Removal Functions
# ============================================================================

remove_binary() {
    local bin="$INSTALL_DIR/burnrate"
    if [[ -L "$bin" ]]; then
        rm -f "$bin"
        success "Removed symlink: $bin"
    elif [[ -f "$bin" ]]; then
        rm -f "$bin"
        success "Removed binary: $bin"
    else
        warn "Binary not found: $bin"
    fi
}

remove_source() {
    if [[ -d "$SOURCE_DIR" ]]; then
        rm -rf "$SOURCE_DIR"
        success "Removed source: $SOURCE_DIR"
    else
        warn "Source not found: $SOURCE_DIR"
    fi
}

remove_config() {
    if [[ -d "$CONFIG_DIR" ]]; then
        rm -rf "$CONFIG_DIR"
        success "Removed config: $CONFIG_DIR"
    else
        warn "Config not found: $CONFIG_DIR"
    fi
}

remove_cache() {
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        success "Removed cache: $CACHE_DIR"
    else
        warn "Cache not found: $CACHE_DIR"
    fi
}

remove_shell_integration() {
    local profiles=("$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.profile")
    local found=false

    for profile in "${profiles[@]}"; do
        [[ ! -f "$profile" ]] && continue

        if grep -q "burnrate" "$profile" 2>/dev/null; then
            # Remove burnrate lines (PATH addition + comment)
            local tmp
            tmp=$(mktemp)
            grep -v "burnrate\|Burnrate" "$profile" > "$tmp"
            mv "$tmp" "$profile"
            success "Cleaned shell integration from: $profile"
            found=true
        fi
    done

    [[ "$found" == "false" ]] && warn "No shell integration found"
}

remove_claude_hook() {
    local settings_file="$HOME/.claude/settings.json"
    [[ ! -f "$settings_file" ]] && return 0

    if grep -q '"burnrate"' "$settings_file" 2>/dev/null; then
        warn "Claude Code hook found in $settings_file"
        warn "Remove the burnrate entry from the hooks.Stop section manually."
        warn "Or delete the entire hooks block if burnrate was the only hook."
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    local purge=false

    # Parse args
    for arg in "$@"; do
        case "$arg" in
            --purge|-p) purge=true ;;
            --help|-h)
                echo "Usage: $0 [--purge]"
                echo "  --purge  Also remove config, data, and cache files"
                exit 0
                ;;
        esac
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${_ICY}  🧊 Burnrate Uninstaller${_IC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This will remove burnrate from your system."
    echo ""

    if [[ "$purge" == "true" ]]; then
        echo -e "${_IYL}⚠  --purge mode: config and data will also be deleted${_IC}"
        echo ""
    fi

    # Show what will be removed
    echo "Will remove:"
    echo "  • $INSTALL_DIR/burnrate (symlink)"
    echo "  • $SOURCE_DIR (source files)"
    echo "  • Shell integration (PATH entry)"
    if [[ "$purge" == "true" ]]; then
        echo "  • $CONFIG_DIR (config + budget data)"
        echo "  • $CACHE_DIR (cache)"
    fi
    echo ""

    if ! ask_yn "Proceed with uninstall?" "n"; then
        info "Uninstall cancelled. See you around! ❄️"
        exit 0
    fi
    echo ""

    # Remove binary/symlink
    remove_binary

    # Remove source
    remove_source

    # Remove shell integration
    remove_shell_integration

    # Note about Claude Code hook (manual removal required)
    remove_claude_hook

    # Purge config/data if requested
    if [[ "$purge" == "true" ]]; then
        echo ""
        remove_config
        remove_cache
    else
        echo ""
        warn "Config kept at: $CONFIG_DIR"
        warn "Run with --purge to remove config and budget data too"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    success "Burnrate uninstalled."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The Arctic will miss you. 🐻‍❄️"
    echo ""
    echo "Reinstall anytime:"
    echo "  git clone https://github.com/samridhgupta/burnrate"
    echo "  cd burnrate && ./install.sh"
    echo ""
}

main "$@"
