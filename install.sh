#!/usr/bin/env bash
# Burnrate One-Line Installer
# curl -fsSL https://raw.githubusercontent.com/user/burnrate/main/install.sh | bash

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly REPO_URL="https://github.com/yourusername/burnrate"
readonly INSTALL_DIR="${BURNRATE_INSTALL_DIR:-$HOME/.local/bin}"
readonly SOURCE_DIR="$HOME/.local/share/burnrate"

# ============================================================================
# Colors
# ============================================================================

COLOR_RESET='\033[0m'
COLOR_CYAN='\033[1;36m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_RED='\033[0;31m'

info() { echo -e "${COLOR_CYAN}❄️  $*${COLOR_RESET}"; }
success() { echo -e "${COLOR_GREEN}✓ $*${COLOR_RESET}"; }
warn() { echo -e "${COLOR_YELLOW}⚠ $*${COLOR_RESET}"; }
error() { echo -e "${COLOR_RED}✗ $*${COLOR_RESET}"; exit 1; }

# ============================================================================
# System Detection
# ============================================================================

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*) echo "linux" ;;
        *) error "Unsupported OS: $(uname -s)" ;;
    esac
}

detect_shell() {
    case "$SHELL" in
        */bash) echo "bash" ;;
        */zsh) echo "zsh" ;;
        *) echo "unknown" ;;
    esac
}

# ============================================================================
# Prerequisites
# ============================================================================

check_prerequisites() {
    info "Checking prerequisites..."

    # Check bash version
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        warn "Bash 4+ recommended (you have $BASH_VERSION)"
    fi

    # Check Claude directory
    if [[ ! -d "$HOME/.claude" ]]; then
        error "Claude Code not found. Install Claude Code first:\n  https://claude.ai/download"
    fi
    success "Claude Code installed"

    # Check stats file
    if [[ ! -f "$HOME/.claude/stats-cache.json" ]]; then
        warn "Stats file not found. Run Claude Code at least once."
    else
        success "Stats file found"
    fi

    # Check for git (optional, for git install)
    if command -v git >/dev/null 2>&1; then
        success "Git installed"
        return 0
    else
        warn "Git not found (will use curl download)"
        return 1
    fi
}

# ============================================================================
# Installation
# ============================================================================

install_from_git() {
    info "Installing from git..."

    # Clone or update
    if [[ -d "$SOURCE_DIR/.git" ]]; then
        info "Updating existing installation..."
        cd "$SOURCE_DIR"
        git pull origin main || error "Failed to update"
    else
        info "Cloning repository..."
        rm -rf "$SOURCE_DIR"
        git clone "$REPO_URL" "$SOURCE_DIR" || error "Failed to clone"
    fi

    success "Downloaded to $SOURCE_DIR"
}

install_from_curl() {
    info "Installing from curl..."

    # Download tarball
    local temp_file
    temp_file="$(mktemp)"
    curl -fsSL "${REPO_URL}/archive/refs/heads/main.tar.gz" -o "$temp_file" || error "Failed to download"

    # Extract
    rm -rf "$SOURCE_DIR"
    mkdir -p "$SOURCE_DIR"
    tar -xzf "$temp_file" -C "$SOURCE_DIR" --strip-components=1 || error "Failed to extract"
    rm "$temp_file"

    success "Downloaded to $SOURCE_DIR"
}

create_symlink() {
    info "Creating symlink..."

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Remove old symlink if exists
    rm -f "$INSTALL_DIR/burnrate"

    # Create symlink
    ln -s "$SOURCE_DIR/burnrate" "$INSTALL_DIR/burnrate" || error "Failed to create symlink"

    success "Symlink created: $INSTALL_DIR/burnrate"
}

add_to_path() {
    # Check if install dir is in PATH
    if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        success "Install directory already in PATH"
        return 0
    fi

    warn "Install directory not in PATH"

    local shell
    shell=$(detect_shell)

    case "$shell" in
        bash)
            local profile="$HOME/.bashrc"
            [[ -f "$HOME/.bash_profile" ]] && profile="$HOME/.bash_profile"
            ;;
        zsh)
            local profile="$HOME/.zshrc"
            ;;
        *)
            warn "Unknown shell. Add manually to PATH:"
            echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
            return 1
            ;;
    esac

    if ask_yn "Add $INSTALL_DIR to PATH in $profile?" "y"; then
        echo "" >> "$profile"
        echo "# Burnrate PATH (added by installer)" >> "$profile"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$profile"
        success "Added to PATH in $profile"
        info "Reload your shell: source $profile"
    fi
}

# ============================================================================
# Post-Install
# ============================================================================

run_setup_wizard() {
    if ask_yn "Run setup wizard?" "y"; then
        info "Starting setup wizard..."
        "$INSTALL_DIR/burnrate" setup
    else
        info "Skipped setup wizard"
        info "Run later with: burnrate setup"
    fi
}

show_completion_message() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${COLOR_CYAN}  ✨ Burnrate installed successfully! ✨${COLOR_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Quick start:"
    echo "  burnrate          # Show today's summary"
    echo "  burnrate show     # Detailed report"
    echo "  burnrate themes   # List themes"
    echo "  burnrate --help   # Show help"
    echo ""
    echo "Documentation:"
    echo "  $SOURCE_DIR/README.md"
    echo ""
    echo "⚠️  ZERO TOKENS USED - Pure script, reads local files only"
    echo ""
}

# ============================================================================
# UI Helpers
# ============================================================================

ask_yn() {
    local question="$1"
    local default="${2:-y}"

    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    while true; do
        read -p "$question $prompt " answer
        answer="${answer:-$default}"
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${COLOR_CYAN}  🔥 Burnrate Installer${COLOR_RESET}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Track Claude Code token costs with zero API calls!"
    echo ""

    # Detect system
    local os
    os=$(detect_os)
    info "OS: $os"

    local shell
    shell=$(detect_shell)
    info "Shell: $shell"
    echo ""

    # Check prerequisites
    if ! check_prerequisites; then
        error "Prerequisites not met"
    fi
    echo ""

    # Install
    if command -v git >/dev/null 2>&1; then
        install_from_git
    else
        install_from_curl
    fi
    echo ""

    # Create symlink
    create_symlink
    echo ""

    # Add to PATH
    add_to_path
    echo ""

    # Run setup wizard
    run_setup_wizard
    echo ""

    # Show completion
    show_completion_message
}

# Run installer
main "$@"
