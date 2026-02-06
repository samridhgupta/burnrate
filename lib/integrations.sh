#!/usr/bin/env bash
# lib/integrations.sh - Shell integration functions for burnrate
# Easy functions for bash/zsh profiles

# ============================================================================
# Shell Integration Functions
# ============================================================================

# Quick burnrate summary (for prompt or aliases)
burnrate_summary() {
    local burnrate_cmd="${BURNRATE_CMD:-burnrate}"
    "$burnrate_cmd" --quiet --no-anim 2>/dev/null || echo "burnrate not found"
}

# Show burnrate in compact format
burnrate_compact() {
    local burnrate_cmd="${BURNRATE_CMD:-burnrate}"
    "$burnrate_cmd" --format compact --no-anim 2>/dev/null
}

# Quick budget check
burnrate_budget_check() {
    local burnrate_cmd="${BURNRATE_CMD:-burnrate}"
    "$burnrate_cmd" budget --quiet --no-anim 2>/dev/null
}

# Add to PS1 prompt (shows budget status emoji)
burnrate_prompt() {
    # Returns emoji based on budget status
    # Usage: PS1='$(burnrate_prompt) \u@\h:\w\$ '
    local burnrate_cmd="${BURNRATE_CMD:-burnrate}"

    # Get budget percentage (simplified - would parse actual output)
    local status
    status=$("$burnrate_cmd" budget --format json 2>/dev/null | grep -o '"percentage":[0-9]*' | cut -d: -f2)

    if [[ -n "$status" ]]; then
        if (( status >= 90 )); then
            echo "❄️ "  # Good
        elif (( status >= 75 )); then
            echo "🧊 "  # OK
        elif (( status >= 50 )); then
            echo "💧 "  # Warning
        else
            echo "🔥 "  # Critical
        fi
    fi
}

# Post-Claude hook (shows summary after Claude exits)
burnrate_post_claude() {
    local burnrate_cmd="${BURNRATE_CMD:-burnrate}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Token Burn Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    "$burnrate_cmd" --format compact
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Daily summary (for profile load or login)
burnrate_daily() {
    local burnrate_cmd="${BURNRATE_CMD:-burnrate}"
    "$burnrate_cmd" show --format detailed
}

# ============================================================================
# Shell Integration Snippets
# ============================================================================

# Generate bash/zsh integration snippet
generate_shell_integration() {
    local install_path="${1:-/usr/local/bin/burnrate}"

    cat <<EOF
# ============================================================================
# Burnrate Integration
# Add to ~/.bashrc or ~/.zshrc
# ============================================================================

# Set burnrate command path
export BURNRATE_CMD="$install_path"

# Aliases
alias burn='burnrate'
alias burnshow='burnrate show'
alias burnbudget='burnrate budget'
alias burnthemes='burnrate themes'

# Quick summary alias
alias tokencost='burnrate --format compact'

# Show summary on shell startup (optional - comment out if too slow)
# burnrate --quiet --no-anim 2>/dev/null

# Add budget status to prompt (optional)
# For bash:
# PS1='\$(burnrate_prompt)\u@\h:\w\$ '
# For zsh:
# PROMPT='%{\$(burnrate_prompt)%}%n@%m:%~%# '

# Daily summary (shows detailed report once per day)
# if [[ ! -f ~/.burnrate_shown_today ]] || [[ "\$(date +%Y%m%d)" != "\$(cat ~/.burnrate_shown_today)" ]]; then
#     burnrate show --format detailed
#     date +%Y%m%d > ~/.burnrate_shown_today
# fi

EOF
}

# ============================================================================
# Profile Installation
# ============================================================================

# Add to bash profile
install_bash_integration() {
    local install_path="${1:-/usr/local/bin/burnrate}"
    local profile_file="$HOME/.bashrc"

    if [[ -f "$HOME/.bash_profile" ]]; then
        profile_file="$HOME/.bash_profile"
    fi

    echo ""
    echo "Installing bash integration..."
    echo "Profile: $profile_file"

    # Check if already installed
    if grep -q "# Burnrate Integration" "$profile_file" 2>/dev/null; then
        echo "✗ Burnrate integration already exists in $profile_file"
        return 1
    fi

    # Backup
    cp "$profile_file" "$profile_file.backup.$(date +%s)" 2>/dev/null || true

    # Append integration
    echo "" >> "$profile_file"
    generate_shell_integration "$install_path" >> "$profile_file"

    echo "✓ Bash integration installed"
    echo "  Run: source $profile_file"
    return 0
}

# Add to zsh profile
install_zsh_integration() {
    local install_path="${1:-/usr/local/bin/burnrate}"
    local profile_file="$HOME/.zshrc"

    echo ""
    echo "Installing zsh integration..."
    echo "Profile: $profile_file"

    # Check if already installed
    if grep -q "# Burnrate Integration" "$profile_file" 2>/dev/null; then
        echo "✗ Burnrate integration already exists in $profile_file"
        return 1
    fi

    # Backup
    cp "$profile_file" "$profile_file.backup.$(date +%s)" 2>/dev/null || true

    # Append integration
    echo "" >> "$profile_file"
    generate_shell_integration "$install_path" >> "$profile_file"

    echo "✓ Zsh integration installed"
    echo "  Run: source $profile_file"
    return 0
}

# Auto-detect shell and install
install_shell_integration() {
    local install_path="${1:-/usr/local/bin/burnrate}"

    case "$SHELL" in
        */bash)
            install_bash_integration "$install_path"
            ;;
        */zsh)
            install_zsh_integration "$install_path"
            ;;
        *)
            echo "✗ Unknown shell: $SHELL"
            echo ""
            echo "Manual integration snippet:"
            generate_shell_integration "$install_path"
            return 1
            ;;
    esac
}

# ============================================================================
# Usage Examples
# ============================================================================

show_integration_examples() {
    cat <<'EOF'
Burnrate Shell Integration Examples:

1. Quick alias:
   alias burn='burnrate'

2. Show after each Claude session:
   # Add to ~/.claude/hooks.json:
   {
     "postExecute": "burnrate --format compact"
   }

3. Add to shell prompt:
   PS1='$(burnrate_prompt)\u@\h:\w\$ '

4. Daily summary on login:
   # Add to ~/.bashrc:
   burnrate show --format detailed

5. Budget check alias:
   alias budget='burnrate budget'

6. Custom function:
   burncheck() {
       echo "Token Burn Check:"
       burnrate --format compact --no-anim
   }

For automatic integration:
   burnrate setup   # Includes shell integration

EOF
}
