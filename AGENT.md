# burnrate — Agent & Orchestrator Reference

> Machine-readable token cost data for Claude Code agents, hooks, and pipelines.

---

**→** [Quick start](#quick-start) · [Structured output](#structured-output) · [Recommendation engine](#recommendation-engine) · [Query interface](#query-interface) · [Context window](#context-window) · [Auto-detection](#auto-detection) · [Setup](#setup) · [Configuration](#configuration) · [Signal interpretation](#signal-interpretation) · [Integration patterns](#integration-patterns)

---

## Quick start

```bash
# Install burnrate
curl -fsSL https://raw.githubusercontent.com/samridhgupta/burnrate/main/install.sh | bash

# Configure for agent use (non-interactive)
burnrate setup --agent

# Run — structured key=value output
burnrate --format agent
```

Output:
```
model=claude-sonnet-4-6
tokens=142800
cost_usd=0.021420
cache_hit_pct=83.00
cache_savings_usd=0.004200
context_pct=47.3
budget_pct=21.4
recommendation=none
```

---

## Structured output

burnrate supports two machine-readable formats.

### `--format agent` — key=value

```bash
burnrate --format agent
```

```
model=claude-sonnet-4-6
tokens=142800
cost_usd=0.021420
cache_hit_pct=83.00
cache_savings_usd=0.004200
context_pct=47.3
budget_pct=21.4
recommendation=none
```

Parse in bash:

```bash
eval "$(burnrate --format agent | sed 's/^/BR_/')"
# Now $BR_model, $BR_cost_usd, $BR_recommendation, etc.
```

### `--format agent-json` — JSON

```bash
burnrate --format agent-json
```

```json
{
  "model": "claude-sonnet-4-6",
  "tokens": 142800,
  "cost_usd": 0.021420,
  "cache_hit_pct": 83.00,
  "cache_savings_usd": 0.004200,
  "context_pct": 47.3,
  "budget_pct": 21.4,
  "recommendation": "none"
}
```

### Field reference

| Field | Type | Description |
|-------|------|-------------|
| `model` | string | Claude model identifier from stats file |
| `tokens` | integer | Total tokens (input + output + cache write + cache read) |
| `cost_usd` | float | Estimated session cost in USD |
| `cache_hit_pct` | float | Cache efficiency — `cache_read / (input + cache_read) * 100` |
| `cache_savings_usd` | float | Estimated savings from cache hits vs. paying full input price |
| `context_pct` | float | Context window fill — `used_tokens / max_tokens * 100` |
| `budget_pct` | float | Daily budget consumed — `0` if no budget configured |
| `recommendation` | string | Action code (see Recommendation engine) |

---

## Recommendation engine

The `recommendation` field returns a single action code. Only the highest-priority condition fires.

| Value | Trigger | Suggested action |
|-------|---------|-----------------|
| `compact_context_urgent` | context_pct ≥ 90 | Run `/compact` or open a new session immediately |
| `stop_session` | budget_pct ≥ 95 | Budget nearly exhausted — stop spending tokens |
| `compact_context` | context_pct ≥ 80 | Run `/compact` before starting the next large task |
| `reduce_spend` | budget_pct ≥ 80 | Budget is high — be token-conscious |
| `improve_cache` | cache_hit_pct < 50 | Sessions too fragmented — cache warmup needed |
| `none` | — | All signals nominal. Continue. |

Priority chain (highest wins):

```
context ≥ 90 → compact_context_urgent
budget  ≥ 95 → stop_session
context ≥ 80 → compact_context
budget  ≥ 80 → reduce_spend
cache   < 50 → improve_cache
              → none
```

### Acting on recommendations

```bash
rec=$(burnrate query recommendation)
case "$rec" in
    compact_context_urgent)
        # Signal the orchestrator to compact or rotate session
        ;;
    stop_session)
        # Halt token-consuming tasks until next budget window
        ;;
    compact_context)
        # Suggest /compact before loading new large files
        ;;
    reduce_spend)
        # Prefer targeted reads, avoid broad scans
        ;;
    improve_cache)
        # Suggest CLAUDE.md warmup or longer session continuity
        ;;
    none)
        # Continue normally
        ;;
esac
```

---

## Query interface

`burnrate query <metric>` returns a single raw value on stdout — no color, no formatting, no banner. Zero parsing overhead.

```bash
burnrate query cost              # total spend (float: 7.42)
burnrate query cache_rate        # cache efficiency % (float: 83.00)
burnrate query tokens            # total token count (integer)
burnrate query model             # model name (string)
burnrate query trend             # week-over-week % change (negative = improving)
burnrate query monthly_cost      # spend this calendar month (float)
burnrate query daily_cost        # spend today (float)
burnrate query context_pct       # % of context window used (float)
burnrate query context_tokens    # raw tokens in current context (integer)
burnrate query context_remaining # tokens remaining (integer)
burnrate query recommendation    # action code (string)
burnrate query budget_pct        # daily budget consumed % (float)
burnrate query savings           # cache savings USD (float)
```

### Inline usage

```bash
cost=$(burnrate query cost)
cache=$(burnrate query cache_rate)
ctx=$(burnrate query context_pct)
rec=$(burnrate query recommendation)

echo "Cost: \$${cost} | Cache: ${cache}% | Context: ${ctx}% | Action: ${rec}"
```

### Threshold checks

```bash
ctx=$(burnrate query context_pct)
ctx_int=${ctx%.*}

if   [[ "$ctx_int" -ge 90 ]]; then echo "URGENT: compact now"
elif [[ "$ctx_int" -ge 75 ]]; then echo "WARN: avoid loading large files"
elif [[ "$ctx_int" -ge 50 ]]; then echo "NOTE: context is filling up"
fi
```

---

## Context window

burnrate reads the current session context from `~/.claude/stats-cache.json`.

### Context metrics

| Metric | Query | Description |
|--------|-------|-------------|
| `context_pct` | `burnrate query context_pct` | Fill % (0–100) |
| `context_tokens` | `burnrate query context_tokens` | Tokens currently in window |
| `context_remaining` | `burnrate query context_remaining` | Tokens left before window full |

### Decision thresholds

```
context_pct  ≥ 90   → /compact or new session urgently
context_pct  ≥ 80   → /compact before next heavy task
context_pct  ≥ 75   → warn user, avoid loading large new files
context_pct  ≥ 50   → note it, prefer targeted reads

context_remaining < 20000  → avoid multi-file scans
context_remaining <  5000  → wrap up task, don't start new subtasks
```

### Full context breakdown

```bash
burnrate context --full    # shows input vs cache_read vs cache_write
burnrate context           # summary gauge + token count
```

---

## Auto-detection

burnrate auto-detects agent/orchestrator context and applies machine-readable defaults silently — without requiring explicit `--format agent` flags.

### Detection signals

| Signal | Description |
|--------|-------------|
| Non-TTY stdout (`! -t 1`) | Piped or redirected output |
| `OPENCLAW_SESSION_ID` | OpenClaw orchestrator |
| `AGENT_ORCHESTRATOR` | Generic orchestrator marker |
| `MCP_SESSION` | MCP pipeline context |
| `CLAUDE_HOOK` | Claude Code Stop hook |
| `CLAUDE_CODE_ENTRYPOINT` | Claude Code subprocess |
| `ANTHROPIC_AGENT` | Anthropic agent runtime |
| `MULTIAGENT_MODE` | Multi-agent framework |

### Applied defaults (when detected)

```
OUTPUT_FORMAT   → agent        (key=value structured output)
MESSAGE_SET     → agent        (terse, factual, no metaphor)
COLOR_SCHEME    → none         (no ANSI escape codes)
ICON_SET        → none         (no emoji)
```

Only applied if the user hasn't explicitly set these values. Explicit flags and config file values always win.

### Bypass for testing

```bash
BURNRATE_NO_AGENT_DETECT=true burnrate | cat   # force human output in a pipe
```

---

## Setup

### Non-interactive agent preset

```bash
burnrate setup --agent
```

Writes `~/.config/burnrate/burnrate.conf` with:

```
THEME=glacial
ANIMATIONS_ENABLED=false
EMOJI_ENABLED=false
COLORS_ENABLED=never
COLOR_SCHEME=none
ICON_SET=none
MESSAGE_SET=agent
OUTPUT_FORMAT=agent
CONTEXT_WARN=true
CONTEXT_WARN_THRESHOLD=70
```

Also aliases: `--openclaw`, `--multiagent`, `--orchestrator`

### Claude Code Stop hook

burnrate can run automatically at the end of every Claude Code session via the Stop hook:

```bash
burnrate setup --hook-only    # adds hook, nothing else
```

In `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "burnrate --format agent"
          }
        ]
      }
    ]
  }
}
```

The Stop hook fires when the session ends. Output goes to stdout — pipe it to a log or let the orchestrator capture it.

### Validate setup

```bash
burnrate doctor    # checks config, stats file, paths
burnrate version   # confirms installed version
```

---

## Configuration

All configuration can be set in `~/.config/burnrate/burnrate.conf` or via environment variables (`CONFIG_*` prefix).

### Agent-relevant options

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `OUTPUT_FORMAT` | `agent` `agent-json` `detailed` `compact` `minimal` `json` | `detailed` | Output format |
| `MESSAGE_SET` | `agent` `roast` `coach` `zen` `<name>` | _(theme default)_ | Message style |
| `COLOR_SCHEME` | `none` `amber` `green` `red` `pink` | _(theme default)_ | Color scheme override |
| `ICON_SET` | `none` `minimal` `<name>` | _(theme default)_ | Icon set override |
| `DAILY_BUDGET` | float (USD) | `0.00` (unlimited) | Daily spend limit |
| `MONTHLY_BUDGET` | float (USD) | `0.00` (unlimited) | Monthly spend limit |
| `BUDGET_ALERT` | 0–100 | `90` | Alert threshold % |
| `CONTEXT_WARN` | `true` `false` | `true` | Warn on high context |
| `CONTEXT_WARN_THRESHOLD` | 0–100 | `85` | Context warn threshold % |
| `CLAUDE_DIR` | path | `~/.claude` | Claude Code data directory |
| `STATS_FILE` | path | `~/.claude/stats-cache.json` | Stats file path |

### Environment variable overrides

Any config key can be overridden at runtime with a `CONFIG_` prefix:

```bash
CONFIG_OUTPUT_FORMAT=agent-json burnrate
CONFIG_DAILY_BUDGET=5.00 burnrate query budget_pct
```

### Minimal agent config

```ini
# ~/.config/burnrate/burnrate.conf
OUTPUT_FORMAT=agent
COLOR_SCHEME=none
ICON_SET=none
MESSAGE_SET=agent
CONTEXT_WARN_THRESHOLD=70
```

---

## Signal interpretation

### Cache hit rate

Cache efficiency is the single most useful signal for cost optimization.

| Range | Signal | Action |
|-------|--------|--------|
| ≥ 85% | Excellent — workflow is cache-friendly | Continue as-is |
| 70–84% | Good — some redundancy | Minor optimization possible |
| 50–69% | Fair — sessions too fragmented | Suggest CLAUDE.md warmup |
| < 50% | Poor — each turn paying full input price | `recommendation=improve_cache` |

**High cache write cost is not a problem.** It means context is being cached for reuse. Check `cache_savings_usd` to confirm the cache paid off.

### Cost trend

```bash
trend=$(burnrate query trend)
# Negative = week-over-week improvement (spending less)
# Positive = week-over-week increase (spending more)
# N/A      = not enough data yet
```

### Context window

Context fill tells you what's computationally possible in the remaining session:

```bash
left=$(burnrate query context_remaining)
# < 20000 → avoid multi-file scans, be selective
# <  5000 → wrap up current task, don't start new subtasks
# N/A     → no session data (first run, or outside Claude Code session)
```

### `N/A` values

`N/A` means the metric is unavailable — either no stats file found, no active session, or no budget configured. Treat as a safe-to-ignore non-signal. Never treat `N/A` as 0.

---

## Integration patterns

### In a Claude Code Stop hook

```bash
# ~/.claude/settings.json hook command:
# "command": "burnrate --format agent >> ~/.local/share/burnrate/session.log"

# Or pipe to your orchestrator:
# "command": "burnrate --format agent | my-orchestrator-listener"
```

### In a shell wrapper script

```bash
#!/usr/bin/env bash
# Run task, then check burnrate signals before next step

run_task() {
    # ... your task here ...
    :
}

check_signals() {
    local rec ctx cost
    rec=$(burnrate query recommendation 2>/dev/null || echo "none")
    ctx=$(burnrate query context_pct 2>/dev/null || echo "0")
    cost=$(burnrate query cost 2>/dev/null || echo "0")

    echo "cost=\$${cost} context=${ctx}% rec=${rec}"

    case "$rec" in
        compact_context_urgent) return 1 ;;  # halt — must compact
        stop_session)           return 2 ;;  # halt — budget
        *)                      return 0 ;;  # continue
    esac
}

run_task
check_signals || exit $?
```

### In OpenClaw / multi-agent orchestrator

```bash
# Preset applies no decoration, agent message set, low context threshold
burnrate setup --openclaw

# Per-run check
state=$(burnrate --format agent-json)
rec=$(echo "$state" | grep '"recommendation"' | cut -d'"' -f4)

# Act on recommendation
[[ "$rec" == "compact_context_urgent" ]] && compact_session
[[ "$rec" == "stop_session" ]]           && pause_agents
```

### In CI/CD

```bash
# Non-interactive, zero decoration
BURNRATE_NO_AGENT_DETECT=false burnrate --format agent-json > burnrate-report.json

# Budget guard
budget_pct=$(burnrate query budget_pct)
if [[ "${budget_pct%.*}" -ge 90 ]]; then
    echo "::warning::Token budget at ${budget_pct}%"
fi
```

### Capture all metrics at once

```bash
# Parse agent kv format into local vars
while IFS='=' read -r key value; do
    case "$key" in
        model)              BR_MODEL="$value" ;;
        tokens)             BR_TOKENS="$value" ;;
        cost_usd)           BR_COST="$value" ;;
        cache_hit_pct)      BR_CACHE="$value" ;;
        cache_savings_usd)  BR_SAVINGS="$value" ;;
        context_pct)        BR_CONTEXT="$value" ;;
        budget_pct)         BR_BUDGET="$value" ;;
        recommendation)     BR_REC="$value" ;;
    esac
done < <(burnrate --format agent 2>/dev/null)

echo "Model: $BR_MODEL | Cost: \$$BR_COST | Cache: $BR_CACHE% | Action: $BR_REC"
```

---

## Security and data

burnrate reads only one file: `~/.claude/stats-cache.json`. It makes zero network calls, spawns no daemons, and never writes to the stats file. It is safe to run from hooks, pipelines, and sandboxed environments.

**Permissions required:**
- Read: `~/.claude/stats-cache.json`
- Read/write: `~/.config/burnrate/` (config), `~/.cache/burnrate/` (cache), `~/.local/share/burnrate/` (data)

→ [Full security policy → SECURITY.md](SECURITY.md)

---

*burnrate v0.8.0 · [README.md](README.md) · [CLI.md](CLI.md) · [THEMES.md](THEMES.md) · [INSTALL.md](INSTALL.md)*
