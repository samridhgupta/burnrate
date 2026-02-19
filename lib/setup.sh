#!/usr/bin/env bash
# lib/setup.sh - Interactive setup wizard for burnrate
# Guides user through first-time configuration

# Source dependencies
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/colors.sh"
source "$LIB_DIR/animations.sh"
source "$LIB_DIR/themes.sh"
source "$LIB_DIR/integrations.sh"

# ============================================================================
# Setup State
# ============================================================================

SETUP_QUICK_MODE=false
SETUP_PRESET=""           # full | medium | minimal | ci  (empty = interactive)
SETUP_NONINTERACTIVE=false
SETUP_CONFIG=()
SETUP_THEME="glacial"
SETUP_ANIMATIONS="true"
SETUP_ANIMATION_SPEED="normal"
SETUP_ANIMATION_STYLE="standard"
SETUP_EMOJI="true"
SETUP_COLORS="auto"
SETUP_DAILY_BUDGET="0.00"
SETUP_MONTHLY_BUDGET="0.00"
SETUP_BUDGET_ALERT="90"
SETUP_HOOK="ask"          # yes | no | ask
SETUP_CONTEXT_WARN="true"
SETUP_CONTEXT_THRESHOLD="85"
SETUP_CONTEXT_DISPLAY="both"

# ============================================================================
# Presets
# ============================================================================

# Apply a named preset — sets all SETUP_* vars, skips interactive prompts.
# Presets:
#   full    — every feature on, hook auto-installed, context threshold 75%
#   medium  — balanced defaults (matches interactive defaults)
#   minimal — no animations, no emoji, no hook, bare numbers
#   ci      — fully non-interactive: no color/emoji/animations, no hook
_apply_preset() {
    local preset="$1"
    SETUP_PRESET="$preset"

    case "$preset" in
        # ── Fun themed names (glacial theme) ──────────────────────────────────
        arctic|full|max)
            # 🧊 Arctic — full feature set, hook auto-installed, lower warn threshold
            SETUP_THEME="glacial"
            SETUP_ANIMATIONS="true"
            SETUP_ANIMATION_SPEED="normal"
            SETUP_ANIMATION_STYLE="standard"
            SETUP_EMOJI="true"
            SETUP_COLORS="auto"
            SETUP_HOOK="yes"
            SETUP_CONTEXT_WARN="true"
            SETUP_CONTEXT_THRESHOLD="75"
            SETUP_CONTEXT_DISPLAY="both"
            SETUP_QUICK_MODE=true
            ;;
        glacier|medium|default)
            # ❄️  Glacier — balanced defaults, hook recommended
            SETUP_THEME="glacial"
            SETUP_ANIMATIONS="true"
            SETUP_ANIMATION_SPEED="normal"
            SETUP_ANIMATION_STYLE="standard"
            SETUP_EMOJI="true"
            SETUP_COLORS="auto"
            SETUP_HOOK="yes"
            SETUP_CONTEXT_WARN="true"
            SETUP_CONTEXT_THRESHOLD="85"
            SETUP_CONTEXT_DISPLAY="both"
            SETUP_QUICK_MODE=true
            ;;
        iceberg|minimal|min)
            # 🏔  Iceberg — lean, no animations, bare stats (just the tip showing)
            SETUP_THEME="glacial"
            SETUP_ANIMATIONS="false"
            SETUP_ANIMATION_SPEED="instant"
            SETUP_ANIMATION_STYLE="minimal"
            SETUP_EMOJI="false"
            SETUP_COLORS="auto"
            SETUP_HOOK="no"
            SETUP_CONTEXT_WARN="true"
            SETUP_CONTEXT_THRESHOLD="90"
            SETUP_CONTEXT_DISPLAY="number"
            SETUP_QUICK_MODE=true
            ;;
        permafrost|ci|script|headless)
            # 🪨  Permafrost — rock solid, no display, CI/script use
            SETUP_THEME="glacial"
            SETUP_ANIMATIONS="false"
            SETUP_ANIMATION_SPEED="instant"
            SETUP_ANIMATION_STYLE="minimal"
            SETUP_EMOJI="false"
            SETUP_COLORS="never"
            SETUP_HOOK="no"
            SETUP_CONTEXT_WARN="false"
            SETUP_CONTEXT_THRESHOLD="100"
            SETUP_CONTEXT_DISPLAY="number"
            SETUP_QUICK_MODE=true
            SETUP_NONINTERACTIVE=true
            ;;
        *)
            echo "Unknown preset: $preset" >&2
            echo "Available presets:" >&2
            echo "  arctic      (alias: full)     — all features on, hook auto-installed" >&2
            echo "  glacier     (alias: medium)   — balanced defaults" >&2
            echo "  iceberg     (alias: minimal)  — no animations/emoji, bare stats" >&2
            echo "  permafrost  (alias: ci)       — non-interactive, CI/script safe" >&2
            exit 1
            ;;
    esac
}

# Print preset summary table
_show_preset_summary() {
    local preset="$1"
    local r='\033[0m' b='\033[1m' c='\033[1;36m' d='\033[2m'
    printf "\n  ${c}Preset: %s${r}\n\n" "$preset"
    printf "  ${d}%-22s${r}  %s\n" "Theme"              "$SETUP_THEME"
    printf "  ${d}%-22s${r}  %s\n" "Animations"         "$SETUP_ANIMATIONS ($SETUP_ANIMATION_SPEED)"
    printf "  ${d}%-22s${r}  %s\n" "Emoji"              "$SETUP_EMOJI"
    printf "  ${d}%-22s${r}  %s\n" "Colors"             "$SETUP_COLORS"
    printf "  ${d}%-22s${r}  %s\n" "Claude Code hook"   "$SETUP_HOOK"
    printf "  ${d}%-22s${r}  %s\n" "Context warn"       "$SETUP_CONTEXT_WARN (threshold: ${SETUP_CONTEXT_THRESHOLD}%)"
    printf "  ${d}%-22s${r}  %s\n" "Context display"    "$SETUP_CONTEXT_DISPLAY"
    printf "  ${d}%-22s${r}  %s\n" "Budget"             "$([ "$SETUP_DAILY_BUDGET" = "0.00" ] && echo "unlimited (edit later)" || echo "\$$SETUP_DAILY_BUDGET daily / \$$SETUP_MONTHLY_BUDGET monthly")"
    echo ""
}

# Parse setup CLI arguments
# Returns preset name or empty for interactive
# Parse setup CLI arguments.
# Presets set SETUP_QUICK_MODE=true and skip interactive prompts.
# Individual flags can be mixed with presets for fine-tuning.
_parse_setup_args() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            # ── Themed preset shortcuts ──────────────────────────────────────
            --arctic|--full|--max)          _apply_preset arctic      ;;
            --glacier|--medium|--default)   _apply_preset glacier     ;;
            --iceberg|--minimal|--min)      _apply_preset iceberg     ;;
            --permafrost|--ci|--script)     _apply_preset permafrost  ;;
            --preset=*)                     _apply_preset "${arg#--preset=}" ;;

            # ── Theme ────────────────────────────────────────────────────────
            --theme=*)
                SETUP_THEME="${arg#--theme=}"
                ;;

            # ── Individual feature flags (mix with preset or standalone) ─────
            --no-animations)    SETUP_ANIMATIONS="false"  ;;
            --animations)       SETUP_ANIMATIONS="true"   ;;
            --no-emoji)         SETUP_EMOJI="false"       ;;
            --emoji)            SETUP_EMOJI="true"        ;;
            --no-hook)          SETUP_HOOK="no"           ;;
            --hook)             SETUP_HOOK="yes"          ;;
            --no-color|--no-colour)  SETUP_COLORS="never" ;;
            --color)            SETUP_COLORS="auto"       ;;
            --context-warn=*)   SETUP_CONTEXT_THRESHOLD="${arg#--context-warn=}" ;;
            --no-context-warn)  SETUP_CONTEXT_WARN="false" ;;
            --context-display=*) SETUP_CONTEXT_DISPLAY="${arg#--context-display=}" ;;
            --animation-speed=*) SETUP_ANIMATION_SPEED="${arg#--animation-speed=}" ;;

            # ── Fast paths ────────────────────────────────────────────────────
            --hook-only)
                SETUP_PRESET="hook-only"
                return 0
                ;;
            --budget-only)
                SETUP_PRESET="budget-only"
                return 0
                ;;
            --help|-h)
                cat <<'HELP'
burnrate setup [OPTIONS]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Preset shortcuts (no prompts)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  --arctic        🧊  All features on, hook auto-installed (full/max)
  --glacier       ❄️   Balanced defaults, hook recommended (medium)
  --iceberg       🏔   Lean — no animations, no emoji (minimal)
  --permafrost    🪨   CI/script safe — no color, no emoji, no hook

  --preset=NAME   Named: arctic | glacier | iceberg | permafrost

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Individual flags (mix with preset or standalone)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  --theme=NAME             glacial|ember|battery|hourglass|garden|ocean|space
  --animations             enable animations
  --no-animations          disable animations
  --emoji / --no-emoji
  --hook / --no-hook
  --color / --no-color
  --context-warn=N         warn threshold % (default 85)
  --no-context-warn        disable context window warning
  --context-display=MODE   visual | number | both
  --animation-speed=SPEED  slow | normal | fast | instant

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Fast paths
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  --hook-only              Just install the Claude Code Stop hook
  --budget-only            Just configure daily/monthly budgets

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Examples:
  burnrate setup                           # interactive wizard
  burnrate setup --arctic                  # all features on, no prompts
  burnrate setup --permafrost              # CI safe, fully non-interactive
  burnrate setup --glacier --theme=ember   # medium + ember theme
  burnrate setup --iceberg --hook          # minimal + add hook anyway
  burnrate setup --arctic --context-warn=90  # full but higher warn threshold
  burnrate setup --hook-only               # just the Stop hook
  burnrate config edit                     # edit config file directly

See INSTALL.md for the full configuration reference.
HELP
                exit 0
                ;;
            --*)
                echo "Unknown option: $arg" >&2
                echo "Run: burnrate setup --help" >&2
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# UI Helpers
# ============================================================================

# Clear screen and show header
setup_header() {
    clear
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔥 Burnrate Setup Wizard"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Show step indicator
setup_step() {
    local step="$1"
    local total="$2"
    local title="$3"

    echo ""
    echo -e "\033[1;36m[$step/$total]\033[0m $title"
    echo "─────────────────────────────────────────────────────────────────"
    echo ""
}

# Ask yes/no question
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

# Ask for input with default
ask_input() {
    local question="$1"
    local default="$2"
    local var_name="$3"

    read -p "$question [$default]: " answer
    answer="${answer:-$default}"
    eval "$var_name=\"\$answer\""
}

# Show menu and get selection
ask_menu() {
    local prompt="$1"
    shift
    local options=("$@")

    echo "$prompt"
    echo ""
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    echo ""

    while true; do
        read -p "Select [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            echo "$((choice-1))"
            return 0
        fi
        echo "Invalid choice. Try again."
    done
}

# ============================================================================
# Setup Steps
# ============================================================================

# Step 0: Welcome
setup_welcome() {
    [[ "$SETUP_NONINTERACTIVE" == "true" ]] && return 0

    setup_header

    if [[ -n "$SETUP_PRESET" ]]; then
        echo "⚠️  ZERO TOKENS USED - Pure script, reads local files only"
        _show_preset_summary "$SETUP_PRESET"
        if [[ "$SETUP_NONINTERACTIVE" != "true" ]]; then
            read -rp "Press Enter to apply, or Ctrl-C to cancel..."
        fi
        return 0
    fi

    cat <<'EOF'
Welcome to Burnrate! 🔥

Burnrate helps you track Claude Code token costs with zero API calls.
It reads your local stats file and shows you:
  • Token usage (input, output, cache)
  • Cost breakdown and cache efficiency
  • Context window gauge (current session)
  • Budget alerts
  • Beautiful terminal UI with themes

Let's get you set up!

EOF

    echo "⚠️  ZERO TOKENS USED - Pure script, reads local files only"
    echo ""

    if ask_yn "Quick setup with defaults?" "y"; then
        echo ""
        info "Using smart defaults..."
        SETUP_QUICK_MODE=true
    else
        echo ""
        info "Custom setup - you'll be asked about each option"
        SETUP_QUICK_MODE=false
    fi

    echo ""
    read -rp "Press Enter to continue..."
}

# Step 1: Check prerequisites
setup_prerequisites() {
    setup_header
    setup_step 1 6 "Checking Prerequisites"

    echo "Checking if Claude Code is installed..."
    echo ""

    # Check for Claude directory
    if [[ -d "$HOME/.claude" ]]; then
        echo "✓ Claude directory found: $HOME/.claude"
    else
        echo "✗ Claude directory not found: $HOME/.claude"
        echo ""
        echo "Burnrate requires Claude Code to be installed."
        echo "Please install Claude Code first:"
        echo "  https://claude.ai/download"
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi

    # Check for stats file
    if [[ -f "$HOME/.claude/stats-cache.json" ]]; then
        echo "✓ Stats file found: $HOME/.claude/stats-cache.json"
    else
        echo "✗ Stats file not found: $HOME/.claude/stats-cache.json"
        echo ""
        echo "Run Claude Code at least once to generate stats."
        echo ""
        read -p "Press Enter to exit..."
        exit 1
    fi

    echo ""
    echo "✓ All prerequisites met!"
    echo ""
    read -p "Press Enter to continue..."
}

# Step 2: Choose theme
setup_theme() {
    # Skip in quick mode
    if [[ "$SETUP_QUICK_MODE" == "true" ]]; then
        return 0
    fi

    setup_header
    setup_step 2 6 "Choose Your Theme"

    cat <<'EOF'
Themes give burnrate personality and style!

Available themes:
  1) ❄️  Glacial - Environmental impact (ice melting) [DEFAULT]
  2) 🔥 Ember - Token burning (fire & heat)
  3) 🔋 Battery - Power consumption
  4) ⏳ Hourglass - Time & resources
  5) 🌱 Garden - Growth & cultivation
  6) 🌊 Ocean - Waves & tides
  7) 🚀 Space - Fuel & exploration

EOF

    local themes=("glacial" "ember" "battery" "hourglass" "garden" "ocean" "space")
    local choice=$(ask_menu "Which theme?" "Glacial (Environmental)" "Ember (Fire & Heat)" "Battery (Power)" "Hourglass (Time)" "Garden (Growth)" "Ocean (Waves)" "Space (Fuel)")

    SETUP_THEME="${themes[$choice]}"

    echo ""
    echo "Selected: ${themes[$choice]}"
    echo ""

    if ask_yn "Preview this theme?" "n"; then
        echo ""
        preview_theme "${themes[$choice]}" 2>/dev/null || echo "(Run 'burnrate preview ${themes[$choice]}' after install)"
        echo ""
        read -p "Press Enter to continue..."
    fi
}

# Step 3: Configure animations
setup_animations() {
    # Skip in quick mode (use defaults: enabled, normal speed, standard style)
    if [[ "$SETUP_QUICK_MODE" == "true" ]]; then
        return 0
    fi

    setup_header
    setup_step 3 6 "Configure Animations"

    cat <<'EOF'
Burnrate can show ASCII animations for a fun experience!
Default: Enabled, Normal speed, Standard style

EOF

    if ask_yn "Enable animations?" "y"; then
        SETUP_ANIMATIONS="true"
        echo ""
        echo "Animation speed:"
        local speed=$(ask_menu "Choose speed:" "Instant (no delay)" "Fast (50ms)" "Normal (100ms) [DEFAULT]" "Slow (200ms)")
        case $speed in
            0) SETUP_ANIMATION_SPEED="instant" ;;
            1) SETUP_ANIMATION_SPEED="fast" ;;
            2) SETUP_ANIMATION_SPEED="normal" ;;
            3) SETUP_ANIMATION_SPEED="slow" ;;
        esac

        echo ""
        echo "Animation style:"
        local style=$(ask_menu "Choose style:" "Standard (balanced) [DEFAULT]" "Minimal (simple)" "Fancy (elaborate)")
        case $style in
            0) SETUP_ANIMATION_STYLE="standard" ;;
            1) SETUP_ANIMATION_STYLE="minimal" ;;
            2) SETUP_ANIMATION_STYLE="fancy" ;;
        esac
    else
        SETUP_ANIMATIONS="false"
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# Step 4: Configure emoji
setup_emoji() {
    # Skip in quick mode (use default: enabled)
    if [[ "$SETUP_QUICK_MODE" == "true" ]]; then
        return 0
    fi

    setup_header
    setup_step 4 6 "Configure Emoji"

    cat <<'EOF'
Burnrate uses emoji to make output more visual and fun!
Default: Enabled

Examples:
  ❄️  Ice status indicators
  🔥 Token burning
  💰 Budget status
  ✨ Cache hits

EOF

    if ask_yn "Enable emoji?" "y"; then
        SETUP_EMOJI="true"
    else
        SETUP_EMOJI="false"
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# Step 5: Configure budgets
setup_budgets() {
    # Skip in quick mode (use defaults: no budgets)
    if [[ "$SETUP_QUICK_MODE" == "true" ]]; then
        return 0
    fi

    setup_header
    setup_step 5 6 "Configure Budgets (Optional)"

    cat <<'EOF'
Set budget limits to get alerts when spending approaches your limits.
Default: No budgets (0.00 = unlimited)

EOF

    ask_input "Daily budget (USD)" "0.00" SETUP_DAILY_BUDGET
    ask_input "Monthly budget (USD)" "0.00" SETUP_MONTHLY_BUDGET

    echo ""
    echo "Alert threshold (% of budget before alerting):"
    ask_input "Alert at" "90" SETUP_BUDGET_ALERT

    echo ""
    echo "Budget summary:"
    echo "  Daily:   \$${SETUP_DAILY_BUDGET}"
    echo "  Monthly: \$${SETUP_MONTHLY_BUDGET}"
    echo "  Alert:   ${SETUP_BUDGET_ALERT}%"

    echo ""
    read -p "Press Enter to continue..."
}

# Step 6: Shell profile + Claude Code hook
setup_shell_integration() {
    setup_header
    setup_step 6 6 "Shell Profile + Claude Code Hook (Optional)"

    cat <<'EOF'
Add burnrate to your shell profile for quick access.

This adds:
  • Aliases (burn, burnshow, burnbudget)
  • Quick summary functions

EOF

    if ask_yn "Add to shell profile?" "y"; then
        echo ""
        local burnrate_path
        burnrate_path="$(cd "$LIB_DIR/.." && pwd)/burnrate"

        install_shell_integration "$burnrate_path"

        echo ""
        echo "Reload your shell:"
        case "$SHELL" in
            */bash) echo "  source ~/.bashrc" ;;
            */zsh)  echo "  source ~/.zshrc" ;;
        esac
    else
        echo ""
        echo "Skipped shell integration."
    fi

    # Claude Code hook (inline, still step 6)
    _setup_claude_hook

    echo ""
    read -p "Press Enter to continue..."
}

# Write the Stop hook entry to settings.json (shared by interactive + auto paths)
_do_install_hook() {
    local settings_file="$1"

    if [[ ! -f "$settings_file" ]]; then
        mkdir -p "$HOME/.claude"
        cat > "$settings_file" <<'HOOK'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "burnrate" }
        ]
      }
    ]
  }
}
HOOK
        success "Created $settings_file with burnrate Stop hook"
        return 0
    fi

    if grep -q '"burnrate"' "$settings_file" 2>/dev/null; then
        success "burnrate hook already present in $settings_file"
        return 0
    fi

    # settings.json exists but no hook — show snippet
    warn "settings.json already exists. Merge this block into it manually:"
    echo ""
    cat <<'SNIPPET'
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "burnrate" }
        ]
      }
    ]
  }
SNIPPET
    echo ""
    echo "  File: $settings_file"
    echo "  Or: burnrate setup --hook-only  (re-run after editing)"
}

# Claude Code Stop hook helper (called from setup_shell_integration)
_setup_claude_hook() {
    local settings_file="$HOME/.claude/settings.json"

    # Non-interactive / preset: auto-decide
    if [[ "$SETUP_HOOK" == "yes" ]]; then
        _do_install_hook "$settings_file"
        return 0
    elif [[ "$SETUP_HOOK" == "no" ]]; then
        info "Hook skipped (preset: $SETUP_PRESET)"
        return 0
    fi

    # Interactive — strongly recommended
    cat <<'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ⭐  Recommended: Claude Code Stop hook
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Burnrate shows your token cost after every Claude response.
This is the best way to stay aware of spend as you work.

  "After every response, I know my burn rate."

Adds one line to ~/.claude/settings.json. Fully reversible.

EOF

    if ! ask_yn "Add burnrate Stop hook? (highly recommended)" "y"; then
        echo ""
        echo "Skipped. Add it later: burnrate setup --hook-only"
        return 0
    fi

    echo ""

    # If settings.json doesn't exist, create it cleanly
    if [[ ! -f "$settings_file" ]]; then
        mkdir -p "$HOME/.claude"
        cat > "$settings_file" <<'HOOK'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "burnrate" }
        ]
      }
    ]
  }
}
HOOK
        echo "✓ Created $settings_file with burnrate Stop hook"
        return 0
    fi

    # settings.json exists — check if hook already present
    if grep -q '"burnrate"' "$settings_file" 2>/dev/null; then
        echo "✓ burnrate hook already present in $settings_file"
        return 0
    fi

    # settings.json exists but no hook — show snippet, don't auto-merge
    echo "  settings.json already exists. Add this to it manually:"
    echo ""
    cat <<'SNIPPET'
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "burnrate" }
        ]
      }
    ]
  }
SNIPPET
    echo ""
    echo "  File: $settings_file"
    echo "  Or run 'burnrate setup' again after editing."
}

# Step 8: Review configuration
setup_review() {
    setup_header
    setup_step 6 6 "Review Configuration"

    cat <<EOF

Your configuration:

  Theme:              $SETUP_THEME
  Animations:         $SETUP_ANIMATIONS
  Animation Speed:    $SETUP_ANIMATION_SPEED
  Animation Style:    $SETUP_ANIMATION_STYLE
  Emoji:              $SETUP_EMOJI
  Daily Budget:       \$${SETUP_DAILY_BUDGET}
  Monthly Budget:     \$${SETUP_MONTHLY_BUDGET}
  Budget Alert:       ${SETUP_BUDGET_ALERT}%

EOF

    if ! ask_yn "Save this configuration?" "y"; then
        echo ""
        echo "Setup cancelled."
        exit 0
    fi
}

# Step 9: Save configuration
setup_save() {
    setup_header
    setup_step 6 6 "Saving Configuration"

    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/burnrate"
    local config_file="$config_dir/burnrate.conf"

    echo "Creating configuration directory..."
    mkdir -p "$config_dir" || die "Failed to create directory: $config_dir"
    echo "✓ Directory created: $config_dir"
    echo ""

    echo "Writing configuration file..."
    local preset_label="${SETUP_PRESET:-interactive}"
    cat > "$config_file" <<EOF
# Burnrate Configuration
# Generated by burnrate setup ($preset_label) on $(date)
# Edit anytime: burnrate config edit

# ── Display ──────────────────────────────────────────────────────────────────
THEME=$SETUP_THEME
COLORS_ENABLED=$SETUP_COLORS
EMOJI_ENABLED=$SETUP_EMOJI
OUTPUT_FORMAT=detailed

# ── Animations ───────────────────────────────────────────────────────────────
ANIMATIONS_ENABLED=$SETUP_ANIMATIONS
ANIMATION_SPEED=$SETUP_ANIMATION_SPEED
ANIMATION_STYLE=$SETUP_ANIMATION_STYLE

# ── Paths ─────────────────────────────────────────────────────────────────────
CLAUDE_DIR=\$HOME/.claude
STATS_FILE=\$CLAUDE_DIR/stats-cache.json
DATA_DIR=\$HOME/.local/share/burnrate
CACHE_DIR=\$HOME/.cache/burnrate

# ── Budget ────────────────────────────────────────────────────────────────────
DAILY_BUDGET=$SETUP_DAILY_BUDGET
MONTHLY_BUDGET=$SETUP_MONTHLY_BUDGET
BUDGET_ALERT=$SETUP_BUDGET_ALERT

# ── Behavior ──────────────────────────────────────────────────────────────────
DEBUG=false
QUIET=false
SHOW_DISCLAIMER=true

# ── Context window ────────────────────────────────────────────────────────────
CONTEXT_WARN=$SETUP_CONTEXT_WARN
CONTEXT_WARN_THRESHOLD=$SETUP_CONTEXT_THRESHOLD
CONTEXT_DISPLAY=$SETUP_CONTEXT_DISPLAY
EOF

    echo "✓ Configuration saved: $config_file"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✨ Setup Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Burnrate is ready to use!"
    echo ""
    echo "Try these commands:"
    echo "  burnrate             # Show today's summary"
    echo "  burnrate show        # Detailed report"
    echo "  burnrate context     # Context window gauge"
    echo "  burnrate budget      # Budget status"
    echo "  burnrate themes      # List themes"
    echo "  burnrate --help      # Show help"
    echo ""
    echo "⚠️  ZERO TOKENS USED - Pure script, reads local files only"
    echo ""
}

# ============================================================================
# Main Setup Flow
# ============================================================================

run_setup() {
    # Parse CLI args — sets SETUP_PRESET and/or individual SETUP_* vars
    _parse_setup_args "$@"

    # Fast path: --hook-only
    if [[ "${SETUP_PRESET:-}" == "hook-only" ]]; then
        SETUP_HOOK="yes"
        _do_install_hook "$HOME/.claude/settings.json"
        return 0
    fi

    # Fast path: --budget-only
    if [[ "${SETUP_PRESET:-}" == "budget-only" ]]; then
        setup_header
        setup_budgets
        _save_budget_to_config
        return 0
    fi

    setup_welcome
    setup_prerequisites
    setup_theme
    setup_animations
    setup_emoji
    setup_budgets
    setup_shell_integration
    setup_review
    setup_save
}

# Save just the budget values to an existing config (used by --budget-only)
_save_budget_to_config() {
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/burnrate"
    local config_file="$config_dir/burnrate.conf"
    mkdir -p "$config_dir"

    if [[ -f "$config_file" ]]; then
        local tmp
        tmp=$(mktemp)
        grep -v "^DAILY_BUDGET=\|^MONTHLY_BUDGET=\|^BUDGET_ALERT=" "$config_file" > "$tmp" || true
        printf "DAILY_BUDGET=%s\nMONTHLY_BUDGET=%s\nBUDGET_ALERT=%s\n" \
            "$SETUP_DAILY_BUDGET" "$SETUP_MONTHLY_BUDGET" "$SETUP_BUDGET_ALERT" >> "$tmp"
        mv "$tmp" "$config_file"
        success "Budget updated in $config_file"
    else
        printf "DAILY_BUDGET=%s\nMONTHLY_BUDGET=%s\nBUDGET_ALERT=%s\n" \
            "$SETUP_DAILY_BUDGET" "$SETUP_MONTHLY_BUDGET" "$SETUP_BUDGET_ALERT" > "$config_file"
        success "Budget saved to $config_file"
    fi
}

# Allow sourcing without auto-run
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_setup
fi
