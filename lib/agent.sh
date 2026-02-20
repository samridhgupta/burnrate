#!/usr/bin/env bash
# lib/agent.sh - Agent/orchestrator output format and RECOMMENDATION engine
# Zero-decoration, structured output designed for AI agent consumption.

# Source guard
[[ -n "${BURNRATE_AGENT_LOADED:-}" ]] && return 0
readonly BURNRATE_AGENT_LOADED=1

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/core.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/stats.sh"
source "$LIB_DIR/session.sh"
source "$LIB_DIR/budget.sh"

# ============================================================================
# Agent Context Detection
# ============================================================================

# Detect whether burnrate is running inside an orchestrator/agent context.
# Sets BURNRATE_AGENT_CONTEXT=true and adjusts CONFIG_OUTPUT_FORMAT to "agent"
# and CONFIG_MESSAGE_SET to "agent" silently.
# Checks: non-TTY stdout, known orchestrator env vars.
detect_agent_context() {
    [[ "${BURNRATE_AGENT_CONTEXT:-false}" == "true" ]] && return 0

    local detected=false

    # Non-interactive / piped output
    if [[ ! -t 1 ]]; then
        detected=true
    fi

    # Known orchestrator / MCP / multi-agent env vars
    for var in OPENCLAW_SESSION_ID AGENT_ORCHESTRATOR MCP_SESSION CLAUDE_HOOK \
                CLAUDE_CODE_ENTRYPOINT ANTHROPIC_AGENT MULTIAGENT_MODE; do
        if [[ -n "${!var:-}" ]]; then
            detected=true
            break
        fi
    done

    if [[ "$detected" == "true" ]]; then
        BURNRATE_AGENT_CONTEXT=true
        # Apply agent defaults only when the user hasn't explicitly set them
        [[ -z "${CONFIG_OUTPUT_FORMAT:-}" ]] && CONFIG_OUTPUT_FORMAT="agent"
        [[ -z "${CONFIG_MESSAGE_SET:-}" ]]   && CONFIG_MESSAGE_SET="agent"
        [[ -z "${CONFIG_COLOR_SCHEME:-}" ]]  && CONFIG_COLOR_SCHEME="none"
        [[ -z "${CONFIG_ICON_SET:-}" ]]      && CONFIG_ICON_SET="none"
    fi
}

# ============================================================================
# RECOMMENDATION Engine
# ============================================================================

# Returns a single recommendation code based on current session state.
# Priority (highest first):
#   compact_context_urgent  — context > 90%
#   stop_session            — budget > 95%
#   compact_context         — context > 80%
#   reduce_spend            — budget > 80%
#   improve_cache           — cache hit rate < 50%
#   none                    — all good
#
# Args: [context_pct] [budget_pct] [cache_hit_pct]
#   If not supplied, values are fetched from session/stats/budget.
get_recommendation() {
    local context_pct="${1:-}"
    local budget_pct="${2:-}"
    local cache_hit="${3:-}"

    # --- Fetch context % if not supplied ---
    if [[ -z "$context_pct" ]]; then
        local ctx_raw
        if ctx_raw=$(get_session_context 2>/dev/null); then
            context_pct=$(echo "$ctx_raw" | cut -d'|' -f3)
        else
            context_pct="0"
        fi
    fi
    local ctx_int
    ctx_int=$(echo "$context_pct" | cut -d. -f1)
    ctx_int="${ctx_int:-0}"

    # --- Fetch budget % if not supplied ---
    if [[ -z "$budget_pct" ]]; then
        budget_pct="0"
        local daily_budget
        daily_budget=$(echo "${CONFIG_DAILY_BUDGET:-0}" | tr -d '$, ')
        if [[ $(echo "$daily_budget > 0" | bc 2>/dev/null) == "1" ]]; then
            local daily_spent
            daily_spent=$(get_daily_cost 2>/dev/null || echo "0")
            daily_spent=$(echo "$daily_spent" | tr -d '$, ')
            budget_pct=$(echo "scale=1; ($daily_spent / $daily_budget) * 100" | bc 2>/dev/null || echo "0")
        fi
    fi
    local bud_int
    bud_int=$(echo "$budget_pct" | cut -d. -f1)
    bud_int="${bud_int:-0}"

    # --- Fetch cache hit rate if not supplied ---
    if [[ -z "$cache_hit" ]]; then
        cache_hit=$(get_cache_efficiency 2>/dev/null || echo "0")
    fi
    local cache_int
    cache_int=$(echo "$cache_hit" | cut -d. -f1)
    cache_int="${cache_int:-0}"

    # --- Priority chain ---
    if   [[ "$ctx_int" -ge 90 ]]; then echo "compact_context_urgent"
    elif [[ "$bud_int" -ge 95 ]]; then echo "stop_session"
    elif [[ "$ctx_int" -ge 80 ]]; then echo "compact_context"
    elif [[ "$bud_int" -ge 80 ]]; then echo "reduce_spend"
    elif [[ "$cache_int" -lt 50 ]]; then echo "improve_cache"
    else echo "none"
    fi
}

# ============================================================================
# Agent Format Rendering
# ============================================================================

# Render structured key=value output for agent consumption.
# Args: model total_tokens total_cost cache_hit_pct context_pct budget_pct savings recommendation
render_agent_kv() {
    local model="${1:-unknown}"
    local total_tokens="${2:-0}"
    local total_cost="${3:-0.000000}"
    local cache_hit="${4:-0}"
    local context_pct="${5:-0}"
    local budget_pct="${6:-0}"
    local savings="${7:-0.000000}"
    local recommendation="${8:-none}"

    cat <<EOF
model=${model}
tokens=${total_tokens}
cost_usd=${total_cost}
cache_hit_pct=${cache_hit}
cache_savings_usd=${savings}
context_pct=${context_pct}
budget_pct=${budget_pct}
recommendation=${recommendation}
EOF
}

# Render JSON output for agent/pipeline consumption.
# Args: same as render_agent_kv
render_agent_json_output() {
    local model="${1:-unknown}"
    local total_tokens="${2:-0}"
    local total_cost="${3:-0.000000}"
    local cache_hit="${4:-0}"
    local context_pct="${5:-0}"
    local budget_pct="${6:-0}"
    local savings="${7:-0.000000}"
    local recommendation="${8:-none}"

    cat <<EOF
{
  "model": "${model}",
  "tokens": ${total_tokens},
  "cost_usd": ${total_cost},
  "cache_hit_pct": ${cache_hit},
  "cache_savings_usd": ${savings},
  "context_pct": ${context_pct},
  "budget_pct": ${budget_pct},
  "recommendation": "${recommendation}"
}
EOF
}

# ============================================================================
# Agent Summary — main entry point
# ============================================================================

# Emit a full agent summary in the configured format (agent or agent-json).
# Pulls live data from stats/session/budget modules.
cmd_agent_summary() {
    local stats_file="${CONFIG_STATS_FILE:-}"

    # --- Tokens & cost ---
    local tokens
    tokens=$(get_total_tokens "$stats_file" 2>/dev/null || echo "0 0 0 0")
    local input_tokens output_tokens cache_write cache_read
    read -r input_tokens output_tokens cache_write cache_read <<< "$tokens"
    input_tokens="${input_tokens:-0}"
    output_tokens="${output_tokens:-0}"
    cache_write="${cache_write:-0}"
    cache_read="${cache_read:-0}"
    local total_tokens=$(( input_tokens + output_tokens + cache_write + cache_read ))

    local model
    model=$(get_model_from_stats "$stats_file" 2>/dev/null || echo "unknown")

    # Cost via pricing module
    local total_cost
    total_cost=$(get_usage_breakdown "$stats_file" 2>/dev/null \
        | grep '"total"' | grep -o '[0-9.]*' | head -1 || echo "0")
    total_cost="${total_cost:-0}"

    # --- Cache ---
    local cache_hit
    cache_hit=$(get_cache_efficiency "$stats_file" 2>/dev/null || echo "0")

    local savings
    savings=$(get_cache_savings "$stats_file" "$model" 2>/dev/null || echo "0")

    # --- Context ---
    local context_pct="0"
    local ctx_raw
    if ctx_raw=$(get_session_context 2>/dev/null); then
        context_pct=$(echo "$ctx_raw" | cut -d'|' -f3)
    fi

    # --- Budget % ---
    local budget_pct="0"
    local daily_budget
    daily_budget=$(echo "${CONFIG_DAILY_BUDGET:-0}" | tr -d '$, ')
    if [[ $(echo "$daily_budget > 0" | bc 2>/dev/null) == "1" ]]; then
        local daily_spent
        daily_spent=$(get_daily_cost 2>/dev/null || echo "0")
        daily_spent=$(echo "$daily_spent" | tr -d '$, ')
        budget_pct=$(echo "scale=1; ($daily_spent / $daily_budget) * 100" | bc 2>/dev/null || echo "0")
    fi

    # --- Recommendation ---
    local recommendation
    recommendation=$(get_recommendation "$context_pct" "$budget_pct" "$cache_hit")

    # --- Render ---
    case "${CONFIG_OUTPUT_FORMAT:-agent}" in
        agent-json)
            render_agent_json_output "$model" "$total_tokens" "$total_cost" \
                "$cache_hit" "$context_pct" "$budget_pct" "$savings" "$recommendation"
            ;;
        *)
            render_agent_kv "$model" "$total_tokens" "$total_cost" \
                "$cache_hit" "$context_pct" "$budget_pct" "$savings" "$recommendation"
            ;;
    esac
}
