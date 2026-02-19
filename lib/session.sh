#!/usr/bin/env bash
# lib/session.sh - JSONL session parser for context window tracking
# Reads local ~/.claude/projects/ files only — zero API calls

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/pricing.sh"

# ============================================================================
# Session File Discovery
# ============================================================================

# Find the most recently modified JSONL session file.
# Excludes /subagents/ subdirectories (those are subagent sessions).
# Returns: absolute path, or exits non-zero if not found.
find_current_session() {
    local projects_dir="${CONFIG_CLAUDE_DIR:-$HOME/.claude}/projects"
    [[ ! -d "$projects_dir" ]] && return 1

    # Find all non-subagent .jsonl files, return the newest by mtime
    local f
    f=$(find "$projects_dir" -name "*.jsonl" ! -path "*/subagents/*" 2>/dev/null \
        | xargs ls -t 2>/dev/null | head -1)

    [[ -z "$f" ]] && return 1
    echo "$f"
}

# ============================================================================
# Context Extraction
# ============================================================================

# Extract context usage from the last assistant message that carries usage data.
# Uses tail -n 200 for performance (session files can be 4000+ lines).
# Returns: "context_used|model_id" or exits non-zero on failure.
_extract_last_context() {
    local session_file="$1"
    [[ ! -f "$session_file" ]] && return 1

    # Grab the last assistant line that contains a "usage" block
    local last_line
    last_line=$(tail -n 200 "$session_file" 2>/dev/null \
        | grep '"type":"assistant"' \
        | grep '"usage"' \
        | tail -1)

    [[ -z "$last_line" ]] && return 1

    # Context used = input + cache_creation + cache_read (what fills the window)
    local inp cw cr
    inp=$(echo "$last_line" | grep -o '"input_tokens":[0-9]*'                  | grep -o '[0-9]*$')
    cw=$(echo  "$last_line" | grep -o '"cache_creation_input_tokens":[0-9]*'   | grep -o '[0-9]*$')
    cr=$(echo  "$last_line" | grep -o '"cache_read_input_tokens":[0-9]*'       | grep -o '[0-9]*$')

    inp="${inp:-0}"; cw="${cw:-0}"; cr="${cr:-0}"

    local context_used=$(( inp + cw + cr ))
    [[ "$context_used" -eq 0 ]] && return 1

    # Model ID (e.g. claude-sonnet-4-5-20251001)
    local model_id
    model_id=$(echo "$last_line" | grep -o '"model":"[^"]*"' | cut -d'"' -f4)
    model_id="${model_id:-unknown}"

    # Also capture breakdown for --full mode
    local out
    out=$(echo "$last_line" | grep -o '"output_tokens":[0-9]*' | grep -o '[0-9]*$')
    out="${out:-0}"

    echo "${context_used}|${model_id}|${inp}|${cw}|${cr}|${out}"
}

# ============================================================================
# Public API
# ============================================================================

# Get current session context window stats.
# Returns: "context_used|context_window|context_pct|model_id|inp|cw|cr|out"
# Exits non-zero if no session data is available.
get_session_context() {
    local session_file
    if ! session_file=$(find_current_session); then
        log_debug "session.sh: no session file found"
        return 1
    fi

    local raw
    if ! raw=$(_extract_last_context "$session_file"); then
        log_debug "session.sh: no usage data in: $session_file"
        return 1
    fi

    local context_used model_id inp cw cr out
    context_used=$(echo "$raw" | cut -d'|' -f1)
    model_id=$(echo "$raw"     | cut -d'|' -f2)
    inp=$(echo "$raw"          | cut -d'|' -f3)
    cw=$(echo "$raw"           | cut -d'|' -f4)
    cr=$(echo "$raw"           | cut -d'|' -f5)
    out=$(echo "$raw"          | cut -d'|' -f6)

    local context_window
    context_window=$(get_model_context_window "$model_id")

    local context_pct
    context_pct=$(awk "BEGIN { printf \"%.1f\", ($context_used / $context_window) * 100 }")

    echo "${context_used}|${context_window}|${context_pct}|${model_id}|${inp}|${cw}|${cr}|${out}"
}

log_debug "Session parser loaded"
