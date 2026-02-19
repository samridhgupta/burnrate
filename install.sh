#!/usr/bin/env bash
# Burnrate Installer
# curl -fsSL https://raw.githubusercontent.com/user/burnrate/main/install.sh | bash
# Or locally: ./install.sh [--reinstall] [--skip-setup]

set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly REPO_URL="https://github.com/yourusername/burnrate"
readonly INSTALL_DIR="${BURNRATE_INSTALL_DIR:-$HOME/.local/bin}"
readonly SOURCE_DIR="$HOME/.local/share/burnrate"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/burnrate"

# ============================================================================
# Colors
# ============================================================================

_IC='\033[0m'
_ICY='\033[1;36m'
_IGN='\033[0;32m'
_IYL='\033[0;33m'
_IRD='\033[0;31m'

info() { echo -e "${_ICY}❄️  $*${_IC}"; }
success() { echo -e "${_IGN}✓ $*${_IC}"; }
warn() { echo -e "${_IYL}⚠ $*${_IC}"; }
error() { echo -e "${_IRD}✗ $*${_IC}"; exit 1; }

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
    local ok=true

    # Check bash version
    local bash_major
    bash_major=$(echo "$BASH_VERSION" | cut -d. -f1)
    if [[ "$bash_major" -lt 4 ]]; then
        warn "Bash 4+ recommended (you have $BASH_VERSION) - will still work on 3.2+"
    else
        success "Bash $BASH_VERSION"
    fi

    # Check Claude directory
    if [[ ! -d "$HOME/.claude" ]]; then
        error "Claude Code not found. Install Claude Code first: https://claude.ai/download"
    fi
    success "Claude Code installed"

    # Check stats file
    if [[ ! -f "$HOME/.claude/stats-cache.json" ]]; then
        warn "Stats file not found - run Claude Code at least once to generate it"
    else
        success "Stats file found"
    fi

    # Check bc
    if command -v bc >/dev/null 2>&1; then
        success "bc calculator installed"
    else
        error "bc not found. Install it: apt-get install bc / brew install bc"
    fi

    # Check for git (optional, for remote install)
    if command -v git >/dev/null 2>&1; then
        success "Git installed"
        return 0
    else
        warn "Git not found (will use curl for remote install)"
        return 1
    fi
}

# ============================================================================
# Installation
# ============================================================================

install_from_local() {
    local src_dir="$1"
    info "Installing from local directory: $src_dir"

    # Copy to source dir
    rm -rf "$SOURCE_DIR"
    mkdir -p "$(dirname "$SOURCE_DIR")"
    cp -r "$src_dir" "$SOURCE_DIR" || error "Failed to copy files"

    success "Installed to $SOURCE_DIR"
}

install_from_git() {
    info "Installing from git..."

    # Clone or update
    if [[ -d "$SOURCE_DIR/.git" ]]; then
        info "Updating existing installation..."
        (cd "$SOURCE_DIR" && git pull origin main) || error "Failed to update"
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

configure_budgets() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/burnrate"
    local config_file="$config_dir/burnrate.conf"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${_ICY}  💰 Budget Setup  (press Enter to skip)${_IC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Set spending limits to get alerts before you go over budget."
    echo "  Leave blank or type 'u' for unlimited (no alerts)."
    echo ""

    # Parse a budget input: number, 0, blank, or "unlimited"/"u" → returns 0.00 or the amount
    _parse_budget() {
        local raw="$1"
        raw=$(echo "${raw:-}" | tr -d '$, ' | tr '[:upper:]' '[:lower:]')
        case "$raw" in
            ""|u|unlimited|none|inf|∞) echo "0.00" ;;
            *)
                if [[ "$raw" =~ ^[0-9]*\.?[0-9]+$ ]]; then
                    printf "%.2f" "$raw" 2>/dev/null || echo "0.00"
                else
                    echo "0.00"
                fi
                ;;
        esac
    }

    # Daily budget
    local daily_raw=""
    read -rp "  Daily budget    \$ [Enter = unlimited]: " daily_raw
    local daily
    daily=$(_parse_budget "$daily_raw")

    # Monthly budget
    local monthly_raw=""
    read -rp "  Monthly budget  \$ [Enter = unlimited]: " monthly_raw
    local monthly
    monthly=$(_parse_budget "$monthly_raw")

    echo ""

    # Write to config file
    mkdir -p "$config_dir"

    if [[ -f "$config_file" ]]; then
        local tmp
        tmp=$(mktemp)
        grep -v "^DAILY_BUDGET=\|^MONTHLY_BUDGET=" "$config_file" > "$tmp" || true
        echo "DAILY_BUDGET=$daily"   >> "$tmp"
        echo "MONTHLY_BUDGET=$monthly" >> "$tmp"
        mv "$tmp" "$config_file"
    else
        cat > "$config_file" <<CONF
# Burnrate configuration
# Generated by installer - edit freely!

# Budgets (0 = no limit / unlimited)
DAILY_BUDGET=$daily
MONTHLY_BUDGET=$monthly

# Alert when spending reaches this % of budget
BUDGET_ALERT=90
CONF
    fi

    if [[ "$daily" == "0.00" && "$monthly" == "0.00" ]]; then
        warn "♾️  Unlimited mode — living like the arctic wind! (set limits anytime: burnrate config)"
    else
        [[ "$daily"   != "0.00" ]] && success "Daily budget:   \$$daily"
        [[ "$monthly" != "0.00" ]] && success "Monthly budget: \$$monthly"
        [[ "$daily"   == "0.00" ]] && info    "Daily:   unlimited 🌊"
        [[ "$monthly" == "0.00" ]] && info    "Monthly: unlimited 🌍"
    fi
    echo ""
}

run_setup_wizard() {
    if ask_yn "Run full setup wizard?" "n"; then
        info "Starting setup wizard..."
        "$INSTALL_DIR/burnrate" setup
    else
        info "Skipped — run 'burnrate setup' anytime to configure themes & integrations"
    fi
}

show_completion_message() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${_ICY}  ✨ Burnrate installed successfully! ✨${_IC}"
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
        case "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# ============================================================================
# Main Installation Flow
# ============================================================================

detect_existing_install() {
    [[ -L "$INSTALL_DIR/burnrate" || -f "$INSTALL_DIR/burnrate" ]]
}

main() {
    local reinstall=false
    local skip_setup=false

    # Parse args
    for arg in "$@"; do
        case "$arg" in
            --reinstall|-r) reinstall=true ;;
            --skip-setup|-s) skip_setup=true ;;
            --help|-h)
                echo "Usage: $0 [--reinstall] [--skip-setup]"
                echo "  --reinstall   Force reinstall even if already installed"
                echo "  --skip-setup  Skip the setup wizard prompt"
                exit 0
                ;;
        esac
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${_ICY}  🔥 Burnrate Installer${_IC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Track Claude Code token costs with zero API calls!"
    echo ""

    # Detect system
    local os
    os=$(detect_os)
    info "OS: $os"

    local detected_shell
    detected_shell=$(detect_shell)
    info "Shell: $detected_shell"
    echo ""

    # Check if already installed
    if detect_existing_install && [[ "$reinstall" == "false" ]]; then
        local installed_ver
        installed_ver=$("$INSTALL_DIR/burnrate" --version 2>/dev/null | head -1 || echo "unknown")
        info "Existing install detected: $installed_ver"
        if ask_yn "Update existing installation?" "y"; then
            reinstall=true
        else
            info "Keeping existing install. Use --reinstall to force update."
            exit 0
        fi
        echo ""
    fi

    # Check prerequisites
    check_prerequisites
    echo ""

    # Install - prefer local if running from repo directory
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ -f "$script_dir/burnrate" && -d "$script_dir/lib" ]]; then
        install_from_local "$script_dir"
    elif command -v git >/dev/null 2>&1; then
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

    # Budget setup (skip on reinstall to preserve existing config)
    if [[ "$skip_setup" == "false" && "$reinstall" == "false" ]]; then
        configure_budgets
    elif [[ "$reinstall" == "true" ]]; then
        info "Reinstall complete. Config preserved at: $CONFIG_DIR"
    fi

    # Run setup wizard (skip on reinstall unless explicitly wanted)
    if [[ "$skip_setup" == "false" && "$reinstall" == "false" ]]; then
        run_setup_wizard
    fi
    echo ""

    # Show completion
    show_completion_message
}

# Run installer
main "$@"
