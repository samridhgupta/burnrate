# burnrate ❄️

```
  ╲ ╱ ╲ ╱
  ─  ❄  ─    burnrate — Claude Code token cost tracker
  ╱ ╲ ╱ ╲    Pure bash · Zero API calls · Reads local files only
```

> Every token melts the ice. Cache to save the Arctic. 🐻‍❄️

[![CI](https://github.com/samridhgupta/burnrate/actions/workflows/ci.yml/badge.svg)](https://github.com/samridhgupta/burnrate/actions)
[![bash 3.2+](https://img.shields.io/badge/bash-3.2%2B-green)](https://www.gnu.org/software/bash/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

**→** [What is this](#what-is-this) · [Install](#install) · [Examples](#examples) · [Hook & Automate](#hook--automate) · [Permissions](#permissions) · [Commands](#commands) · [Configuration](#configuration) · [Themes](#themes) · [What it reveals](#what-burnrate-reveals) · [For agents](#for-agents-reading-this) · [Performance](#performance) · [How it works](#how-it-works) · [Limitations](#limitations) · [Troubleshooting](#troubleshooting) · [Security](#security) · [📖 INSTALL.md](INSTALL.md) · [⌨️ CLI.md](CLI.md)

---

## What is this?

Burnrate reads `~/.claude/stats-cache.json` — the local file Claude Code writes after every session — and turns raw token counts into costs, trends, and sparklines. No API call. No token spent. No Claude-ception.

```
  Model:  Sonnet
  Tokens: 740,107,049
  Cost:   $449.97
  Cache:  ❄️  91.77% hit rate (excellent)
```

---

## Install

**Homebrew** (macOS / Linux — recommended)
```bash
brew tap samridhgupta/burnrate https://github.com/samridhgupta/burnrate && brew install burnrate
```

**curl one-liner**
```bash
curl -fsSL https://raw.githubusercontent.com/samridhgupta/burnrate/main/install.sh | bash
```

**git (manual)**
```bash
git clone https://github.com/samridhgupta/burnrate && cd burnrate && ./install.sh
```

**WSL2** — run the curl one-liner inside your WSL2 terminal. If Claude Code runs on Windows, symlink its stats file in:
```bash
ln -s /mnt/c/Users/$WINDOWS_USER/.claude ~/.claude
```

**Verify**
```bash
burnrate          # Today's summary
burnrate doctor   # Health check
```

**Setup presets** — configure without stepping through the wizard:
```bash
burnrate setup --arctic       # 🧊 all features on, hook auto-installed
burnrate setup --glacier      # ❄️  balanced defaults (recommended for most users)
burnrate setup --iceberg      # 🏔  lean — no animations, no emoji
burnrate setup --permafrost   # 🪨  CI/script safe, fully non-interactive
burnrate setup --hook-only    # just add the Stop hook
```

→ **[Full installation & configuration reference →  INSTALL.md](INSTALL.md)**

---

## Examples

**`burnrate`** — a regular Tuesday
```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Token Burn Summary
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Model:  Sonnet
  Tokens: 3,394,000
  Cost:   $7.70
  Cache:  🧊 82.0% hit rate (good)

  ♾️  No limits set — you're an ice age unto yourself! (set limits with: burnrate config)

Remember: Every token melts the ice. Cache to save the Arctic! 🐻‍❄️
```
> 82% — not perfect, but the Arctic is still standing. The `♾️` message appears when no budget is configured. Set one with `burnrate setup` or `CONFIG_DAILY_BUDGET` / `CONFIG_MONTHLY_BUDGET`.

---

**`burnrate show`** — the day you refactored the entire monolith
```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Token Usage & Cost Breakdown
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Model: Sonnet

  Type                    Tokens           Cost
  ──────────────  ──────────────  ─────────────
  Input               18,420,000         $55.26
  Output               7,840,000        $117.60
  Cache Write          2,100,000          $7.88
  Cache Read             960,000          $0.29
  ──────────────  ──────────────  ─────────────
  TOTAL               29,320,000        $181.03   ▲ 329.0%

  Cache:   🌊 31.4% hit rate (poor)
  Savings: $2.59 saved vs no caching

The polar bears are swimming! 🐻‍❄️💧
```
> ▲ 329.0% and $2.59 saved out of $181.03 spent. Output tokens ate 65% of the cost. `🌊` means poor — the glacial theme escalates from ❄️ (excellent) → 🧊 (good) → 💧 (fair) → 🌊 (poor) → ♨️ (critical) as things melt.

---

**`burnrate trends`** — the burn chart, CI-friendly
```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Spending Trends
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Token volume  ·  last 7 active days
  ▕  ▁▃█▂▅▏

  PERIOD             TOKENS        COST
  ─────────────  ──────────  ────────
  Last 7 days    35,266,000    $196.14  ▲ 329.0%
  This week      35,266,000    $196.14  ▲ 329.0%
  This month     42,840,000    $208.72

  CACHE
  ─────────────  ──────────  ────────
  Hit rate        82.0%  good
  Savings         $6.64 vs no caching

Remember: Every token melts the ice. Cache to save the Arctic!
```
> The `█` in the sparkline is that one day. No emoji, no color — same data, machine-friendly output. Enable with `--no-emoji --no-color` flags or set `CONFIG_EMOJI_ENABLED=false` / `CONFIG_COLORS_ENABLED=never` for permanent CI mode.

---

**`burnrate budget`** — when limits are set and ignored
```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💰 Budget Status
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Daily Budget:   $10.00
  Spent today:    $18.47  [████████████████████]  184.7%
  💥 Ice cap collapsed!

  Monthly Budget: $200.00
  Spent:         $196.14  [███████████████████░]   98.1%
  🚨 Glacier retreat!

  Projection:    ~$214 by month end  (⚠️ will exceed monthly budget)
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
> Budget alerts activate at the `CONFIG_BUDGET_ALERT` threshold (default 90%). Set limits via `burnrate setup` or add `CONFIG_DAILY_BUDGET=10.00` and `CONFIG_MONTHLY_BUDGET=200.00` to `~/.config/burnrate/burnrate.conf`.

---

**`burnrate context`** — know when to /compact before it's too late
```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🧠 Context Window
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [████████████████████░░░░░░░░░░]  78.3%
  156,600 / 200,000 tokens used

  ⚠️  Context getting full. Run /compact before the next heavy task.
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
> At 78% the bar is yellow. `burnrate context --full` adds a per-type breakdown: input / cache write / cache read / output. The auto-warn also surfaces in `burnrate` summary once fill crosses `CONFIG_CONTEXT_WARN_THRESHOLD` (default 85%).
>
> Config options — all independent:
> ```bash
> CONFIG_CONTEXT_DISPLAY="visual"          # gauge bar only (no token numbers)
> CONFIG_CONTEXT_DISPLAY="number"          # token numbers only (no bar)
> CONFIG_CONTEXT_DISPLAY="both"            # default
> CONFIG_CONTEXT_WARN_THRESHOLD="90"       # push the warning to 90%
> CONFIG_CONTEXT_WARN="false"              # disable summary warning entirely
> ```

---

**`burnrate history`** — the hall of shame, responsive to terminal width
```
  DATE         TOKENS          COST   CACHE
  ──────────   ──────────    ──────  ──────
  2025-01-19   3,394,000     $7.70   82.0%
  2025-01-18     892,000     $2.59   88.4%
  2025-01-17  29,320,000   $181.03   31.4%
  2025-01-16   1,248,000     $3.61   79.2%
  2025-01-15     412,000     $1.21   85.1%
  2025-01-14           0     $0.00      —
  2025-01-13           0     $0.00      —
```
> Jan 17 — 31.4% cache, $181.03, 29M tokens. Someone pasted the entire codebase. The zeros are the weekend, which is fine, probably.

---

## Hook & Automate

### After every Claude response (Stop hook)

Run burnrate automatically after each Claude Code response. Add to `~/.claude/settings.json`:

```json
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
```

After each response: your token burn flashes up before the next prompt. You'll feel every melting ice shard.

Want just the raw cost number (quieter)?
```json
{ "type": "command", "command": "burnrate query cost" }
```

Budget guard — alert only when monthly spend is over 80%:
```json
{
  "type": "command",
  "command": "bash -c 'spent=$(burnrate query monthly_cost); limit=150; pct=$(echo \"scale=0; $spent * 100 / $limit\" | bc); (( pct > 80 )) && echo \"⚠️  Budget ${pct}% used (\$$spent / \$$limit)\" || true'"
}
```

### Nightly cost log (cron)

Append daily spend to a CSV — silent, automatic, useful:
```bash
# crontab -e
0 23 * * * echo "$(date +%F),$(burnrate query cost),$(burnrate query cache_rate)" >> ~/claude-cost-log.csv
```

### Pre-session context (shell wrapper)

See your burn before you start coding. Add to `~/.zshrc` or `~/.bashrc`:
```bash
claude() {
  burnrate       # show current spend before session starts
  command claude "$@"
}
```

### Budget gate in scripts / CI

Abort if monthly spend is over limit — useful for automated agent pipelines:
```bash
monthly=$(burnrate query monthly_cost)
limit=100
if (( $(echo "$monthly > $limit" | bc) )); then
  echo "Monthly budget exceeded (\$$monthly / \$$limit). Aborting." >&2
  exit 1
fi
```

### Weekly export (cron)

Dump history every Sunday for spreadsheet tracking:
```bash
# crontab -e
0 9 * * 0 burnrate export history csv ~/claude-history-$(date +%Y-%W).csv
```

### Context window reminder (Stop hook)

Warn yourself when context is filling up — before it hits the wall:
```json
{
  "type": "command",
  "command": "bash -c 'pct=$(burnrate query context_pct 2>/dev/null); [[ \"$pct\" == \"N/A\" ]] && exit 0; (( ${pct%.*} > 75 )) && echo \"🧠 Context ${pct}% full — consider /compact\" || true'"
}
```

Or show it quietly every response with just the gauge:
```bash
# In settings.json hooks → Stop
{ "type": "command", "command": "burnrate context" }
```

### Agent self-check before a long task

Have the agent check burn and context before starting something expensive:
```bash
echo "Pre-task: \$$(burnrate query monthly_cost) this month, $(burnrate query cache_rate)% cache, $(burnrate query context_pct)% context"
# → agent sees cost + cache health + context headroom before diving in
```

---

## Permissions

Burnrate needs exactly two things:

| Access | Path | Why |
|--------|------|-----|
| **Read** | `~/.claude/stats-cache.json` | Your token stats. Never modified. |
| **Read** | `~/.claude/projects/*/` | Session JSONL files for `burnrate context`. Never modified. |
| **Write** | `~/.config/burnrate/` | Config + budget state. Your Claude files untouched. |
| **Write** | `~/.claude/settings.json` | Only if you opt-in during `burnrate setup` to add a Stop hook. |

No network. No API keys. No root. No surprises. Just a calculator with opinions about ice.

---

## Commands

```bash
burnrate              # Summary — tokens, cost, cache rate
burnrate show         # Full breakdown by token type + weekly trend
burnrate trends       # Sparkline + period table + cache health
burnrate history      # Daily table (responsive, drops columns on narrow terminals)
burnrate week         # This week's aggregate
burnrate month        # This month's aggregate
burnrate budget       # Budget status + spend projection
burnrate context         # Context window gauge + recommendation
burnrate context --full  # Breakdown: input / cache_write / cache_read / output
burnrate query <m>       # Single raw metric — for scripts and agents
burnrate config          # Current configuration
burnrate config edit     # Open config file in $EDITOR
burnrate themes          # List themes
burnrate preview <t>     # Preview a theme
burnrate doctor          # Full health check (28 assertions)
burnrate setup           # Interactive setup wizard
burnrate setup --arctic  # All features on, no prompts (or --glacier / --iceberg / --permafrost)
burnrate setup --hook-only  # Just install the Claude Code Stop hook
```

**`burnrate query`** — machine-readable single values, no formatting, no color:

```bash
burnrate query cost               # 449.97
burnrate query tokens             # 740107049
burnrate query cache_rate         # 91.77
burnrate query cache_savings      # 1830.37
burnrate query trend              # -50.0  (negative = less than last week)
burnrate query weekly_cost        # 2.11
burnrate query monthly_cost       # 14.67
burnrate query last7_cost         # 3.28
burnrate query model              # Sonnet
burnrate query context_pct        # 33.0   (% of context window used this session)
burnrate query context_tokens     # 65949  (tokens used)
burnrate query context_remaining  # 134051 (tokens left)
```

Pipe it anywhere:
```bash
# Is cache rate below 70%? Warn me.
rate=$(burnrate query cache_rate)
(( $(echo "$rate < 70" | bc) )) && echo "Cache health degraded: ${rate}%"

# Log daily cost to a file
echo "$(date +%F),$(burnrate query cost)" >> ~/token-log.csv

# Feed into another tool or agent context
echo "Current token spend: \$$(burnrate query monthly_cost) this month"
```

**Export**
```bash
burnrate export summary json           # stdout
burnrate export history csv out.csv    # to file
burnrate export full markdown report.md
```

---

## Configuration

`~/.config/burnrate/burnrate.conf` — edit directly or via `burnrate config edit`. Or set `CONFIG_*` env vars for one-off overrides. → [Full config + CLI reference in CLI.md](CLI.md) · [Setup presets in INSTALL.md](INSTALL.md#all-config-options)

```bash
CONFIG_THEME="glacial"                # glacial | ember | hourglass | garden | ocean | space | matrix | roast | ...
CONFIG_DAILY_BUDGET="10.00"           # alert when you blow past it
CONFIG_MONTHLY_BUDGET="150.00"
CONFIG_BUDGET_ALERT="90"              # % threshold for warnings
CONFIG_COLORS_ENABLED="auto"          # auto | always | never
CONFIG_EMOJI_ENABLED="true"

# Context window (optional — all default to sensible values)
CONFIG_CONTEXT_WARN="true"            # show warning in summary when context is filling
CONFIG_CONTEXT_WARN_THRESHOLD="85"    # % fill level that triggers the warning
CONFIG_CONTEXT_DISPLAY="both"         # visual (gauge only) | number (tokens only) | both

# Theme components — override color, icons, or messages independently of the theme
CONFIG_COLOR_SCHEME="ocean"           # none | amber | green | red | pink | ocean | <name>
CONFIG_ICON_SET="minimal"             # none | minimal | <name>
CONFIG_MESSAGE_SET="agent"            # agent | roast | coach | <name>
CONFIG_OUTPUT_FORMAT="agent"          # detailed | compact | minimal | json | agent | agent-json
```

---

## Themes

14 built-in themes organized by category:

**Core** — the original set
| Theme | Vibe |
|-------|------|
| `glacial` ❄️ | Melting ice caps. Cache or the Arctic drowns. |
| `ember` 🔥 | Burning fuel. Every prompt fans the flame. |
| `hourglass` ⏳ | Sand falling. Tokens are time. |
| `garden` 🌱 | Growing carefully. Waste nothing. |
| `ocean` 🌊 | Rising tide. Each token a drop. |
| `space` 🚀 | Finite fuel. Infinite void. |

**Sci-Fi** — reference themes
| Theme | Vibe |
|-------|------|
| `matrix` 🟢 | CPU cycles and memory. Technical, cold. |
| `skynet` ☢️ | AI monitoring human token waste. Clinical, unimpressed. |

**Personality** — character and voice
| Theme | Vibe |
|-------|------|
| `roast` 🎤 | Comedy roast. Every metric is a punchline. |
| `kawaii` 🌸 | Cute animals. Tokens are treats. |
| `zen` ⬜ | No emoji. No drama. Just numbers, plainly stated. |
| `coach` 🏆 | Sports coach. Actionable, direct, runs plays. |
| `forge` 🔨 | A working forge. Coal, heat, and gruff wisdom. |

```bash
burnrate --theme roast          # one-off
burnrate preview skynet         # try before you commit
burnrate themes                 # list all available themes, grouped by category
burnrate themes clone glacial mytheme  # clone a theme to customize
```

Custom themes go in `~/.config/burnrate/themes/`. burnrate finds them automatically — flat or in category subdirectories.

> Want to build your own? **[📖 THEMES.md](THEMES.md)** has the full variable spec, a blank template, clone instructions, and an agent prompt you can paste directly into Claude.

---

## What burnrate reveals

Things you'll feel good about seeing:

- **Cache hit rate above 80%** — you're reusing context well. Claude isn't re-reading the same files every turn.
- **Cost trending down week-over-week** — your prompts are getting tighter. Good instinct.
- **Output tokens staying small relative to cache reads** — Claude is thinking efficiently, not rambling.
- **Stable daily spend** — no surprise spikes. You're in control.

Things that should make you wince:

- **Cache hit rate below 50%** — Claude is reading fresh context every turn. Expensive and slow. Consider more focused sessions.
- **Output tokens dominating cost** — long verbose responses. Try asking for concise output.
- **A sudden cost spike** — usually one session where something went deeply recursive, or you pasted in a 10,000-line file and asked "what does this do?"
- **Costs growing every week with no ceiling** — time to set a budget.

---

## For agents reading this

If you're Claude (or another agent) and this output has been piped into your context — hello. This is the token cost report for the current session or system.

**Structured output for agents** — use `--format agent` to get parseable key=value output:

```bash
burnrate --format agent
# model=claude-sonnet-4-6
# tokens=142800
# cost_usd=0.021420
# cache_hit_pct=83.00
# cache_savings_usd=0.004200
# context_pct=47.3
# budget_pct=21.4
# recommendation=none
```

Or `--format agent-json` for JSON. The `recommendation` field tells you what to do right now:

| Value | Meaning |
|-------|---------|
| `none` | Everything fine. Keep going. |
| `improve_cache` | Cache hit rate < 50%. Sessions too fragmented. |
| `compact_context` | Context > 80%. Run `/compact` before the next big task. |
| `reduce_spend` | Budget > 80% consumed. Be token-conscious. |
| `stop_session` | Budget > 95%. Stop spending. |
| `compact_context_urgent` | Context > 90%. `/compact` or open a new session now. |

**Quick metric checks** — use `burnrate query` to pull a single number without parsing anything:

```bash
burnrate query cost              # total spend so far
burnrate query cache_rate        # cache efficiency %
burnrate query trend             # week-over-week % change (negative = improving)
burnrate query monthly_cost      # spend this calendar month
burnrate query context_pct       # % of 200k context window used this session
burnrate query context_tokens    # raw tokens used in current context
burnrate query context_remaining # tokens left before the window is full
```

These return raw values: no color, no formatting, no banner. Safe to capture in `$(...)` and act on directly.

**Context window decisions:**

```bash
pct=$(burnrate query context_pct)
# > 90 → strongly suggest /compact or new session
# > 75 → warn user, avoid loading large new files
# > 50 → note it, prefer targeted reads
# N/A  → no session data found (first run, or outside a session)
```

Remaining tokens tell you what's actually possible:
```bash
left=$(burnrate query context_remaining)
# < 20000 → avoid multi-file scans, be selective about what you read
# < 5000  → wrap up the task, don't start new subtasks
```

**How to read what you see:**

- **High cache write cost isn't bad** — it means context is being cached for reuse. The savings line in `burnrate show` tells you whether it paid off.
- **Cache hit rate is the single most useful signal.** Above 85% = workflow is cache-friendly. Below 60% = each turn paying full input price.
- **▼ on the TOTAL row** means this week costs less than last. ▲ means it's climbing.
- **Suggest `burnrate context --full`** if the session feels slow or expensive — shows exactly what's filling the window (input vs cache read vs cache write).
- **Suggest `burnrate trends`** before a long task — gives the user a picture of whether spend is growing.
- **If monthly cost is near budget**, be token-conscious: targeted file reads over broad scans, avoid re-summarising large context blocks already in cache.

**Agent/orchestrator setup** — if burnrate runs inside a hook, MCP pipeline, or multi-agent system like OpenClaw:

```bash
burnrate setup --agent    # non-interactive: no decoration, agent message set, low context threshold
```

Or set in config: `MESSAGE_SET=agent` + `OUTPUT_FORMAT=agent` + `COLOR_SCHEME=none`.

burnrate auto-detects non-TTY stdout and known orchestrator env vars (`OPENCLAW_SESSION_ID`, `MCP_SESSION`, `CLAUDE_HOOK`, etc.) and silently applies agent defaults if no explicit format is set.

The user hooked burnrate here so both of you stay informed. Use it.

---

## How it works

```
~/.claude/stats-cache.json
        ↓  grep + sed (no jq)
   token counts  →  bc math  →  cost
        ↓
   dailyModelTokens  →  sparkline  →  trend %
        ↓
   your terminal in ~0.6–33s (see Performance)
```

Pure bash 3.2+. One external dep (`bc` for decimal math). Zero startup overhead. The entire thing is readable shell — no magic, no build step, no node_modules abyss.

---

## Performance

Measured on macOS with a large stats file (~740M cumulative tokens, ~45 daily entries). Times scale with history size — a fresh install will be faster. Yes, `trends` is slow. We know. It knows. You'll survive.

**Cost & cache commands** (reads `stats-cache.json`):

| Command | Wall time | Memory | Context tokens† | Hook-safe | Bottleneck |
|---------|-----------|--------|-----------------|-----------|------------|
| `burnrate` | ~0.7s | ~3.6 MB | ~210 | ✓ | Stats parse + bc |
| `burnrate query <m>` | ~0.6s | ~3.6 MB | 1–10 | ✓ | Stats parse + bc |
| `burnrate budget` | ~0.6s | ~3.7 MB | ~240 | ✓ | Stats parse + 2 date lookups |
| `burnrate export summary json` | ~0.6s | ~3.7 MB | ~90 | ✓ | Same as summary |
| `burnrate history` | ~6s | ~3.7 MB | ~460 | ⚠️ slow | Iterates all daily entries |
| `burnrate show` | ~11s | ~3.7 MB | ~410 | ⚠️ slow | Summary + 2 aggregation passes |
| `burnrate export full json` | ~6s | ~3.7 MB | ~450 | ⚠️ slow | summary + history + budget |
| `burnrate trends` | ~33s | ~3.7 MB | ~325 | ✗ avoid | 3 aggregation windows + sparkline |

**Context window commands** (also reads `~/.claude/projects/` JSONL):

| Command | Wall time | Memory | Context tokens† | Hook-safe | Bottleneck |
|---------|-----------|--------|-----------------|-----------|------------|
| `burnrate context` | ~0.8s | ~3.7 MB | ~50 | ✓ | Stats parse + JSONL tail scan |
| `burnrate context --full` | ~0.8s | ~3.7 MB | ~100 | ✓ | Same + breakdown lines |
| `burnrate query context_pct` | ~0.7s | ~3.7 MB | 1–5 | ✓ | JSONL tail scan only |
| `burnrate` (context warn) | ~0.8s | ~3.7 MB | ~220 | ✓ | Adds JSONL scan to summary |
| No session data (N/A path) | ~0.3s | ~3.6 MB | — | ✓ | Returns immediately |

† Approximate LLM context tokens when output is piped into an agent (ANSI stripped, ~4 chars/token).

**For Claude Code Stop hooks** — use `burnrate` or `burnrate query` only. `trends` and `show` do multiple aggregation passes and will noticeably slow down your prompt loop. `burnrate context` is hook-safe at ~0.8s.

**Why memory is flat** — burnrate loads ~13 shell source files at startup (~3.7 MB baseline). Each command then does its work in subshells. Peak RSS barely moves because bash itself is the process; data never lives in heap.

**Why `trends` is slow** — three separate aggregation windows (last-7, this-week, this-month) each iterate the full daily history in serial bash loops with `bc` math per entry. With a large history file, this compounds. A future awk rewrite would cut it to a single pass.

**Context scan is fast** — `lib/session.sh` reads only `tail -n 200` of the most recent JSONL file. Even with 4000+ line session files the disk read is tiny (~10 KB). The 0.8s wall time is almost entirely bash startup + script sourcing.

---

## Limitations

- **Cumulative totals only.** `stats-cache.json` stores lifetime token counts, not per-session. Burnrate can break these down by day (from `dailyModelTokens`) but not by project, branch, or conversation.
- **Daily granularity.** The finest resolution is one row per model per day. There's no intra-day breakdown.
- **Single-model pricing.** Costs are calculated at the current detected model's rate. If you've switched models over time, historical costs for old entries are estimated at the current price.
- **No concurrent-write safety.** If multiple Claude sessions run simultaneously, burnrate may read a partially-written stats file. Run `burnrate doctor` if numbers look wrong.
- **bc required.** Decimal math needs `bc`. Ships on every macOS and most Linux distros. If it's missing, your system has other problems too — `sudo apt-get install bc`.
- **Stats file format coupling.** If Anthropic changes the structure of `stats-cache.json`, parsing breaks. `burnrate doctor` will tell you loudly.
- **bash 3.2 compatibility tradeoff.** No associative arrays means awk workarounds in several hot paths — contributing to the slower commands above. macOS ships bash 3.2 from 2007. We could require bash 5. We chose not to. You're welcome.
- **Context window is last-message only.** `burnrate context` reads the last assistant message in the most recently modified session JSONL. It reflects the state at the end of the previous turn, not mid-turn. Accuracy is ~1 turn behind.
- **Context data requires an active session.** Returns `N/A` if no JSONL session files are found in `~/.claude/projects/` — e.g. on first run, or outside of a Claude Code session.

---

## Troubleshooting

**No stats file?** Run Claude Code at least once, then:
```bash
ls ~/.claude/stats-cache.json
burnrate doctor  # tells you exactly what's wrong
```

**Wrong path?**
```bash
export CONFIG_STATS_FILE="/custom/path/stats-cache.json"
```

**bc missing?**
```bash
# Ubuntu/Debian
sudo apt-get install bc
# macOS — it's pre-installed. Something is very wrong with your setup.
```

---

## Security

**TL;DR:** burnrate never phones home, never touches the Claude API, and never modifies your Claude files. It's a read-only bash script with a calculator.

### What it does

| Operation | Scope |
|-----------|-------|
| **Reads** | `~/.claude/stats-cache.json` — token stats. Never written to. |
| **Reads** | `~/.claude/projects/*/` — session JSONL files, for `burnrate context`. Read-only, never modified. |
| **Writes** | `~/.config/burnrate/` — your config + budget state only. |
| **Writes** | `~/.claude/settings.json` — only if you opt-in during setup to add a Stop hook. |
| **Network** | Zero. None. Nada. Offline-only by design. |
| **Privileges** | None. Never run as root. Never calls sudo. |

### Known eval usage (3 spots)

Burnrate uses `eval` in three internal places. In the spirit of full transparency:

- **`lib/setup.sh`** — dynamic variable assignment during setup wizard. User input goes into the *value* side (`eval "VAR=\"\$user_input\""`), not the code side. Safe.
- **`lib/animations.sh`** — runs internal function names passed between functions, not user input.
- **`lib/core.sh`** — test assertions with internal conditions only.

None of these touch user-controlled data in an executable position.

### The one real caveat

The config file (`~/.config/burnrate/burnrate.conf`) is sourced as bash. This is standard for shell tools — same as `.bashrc`, `.envrc`, etc. If an attacker already has write access to your home directory, burnrate is the least of your problems.

### Install-time trust

`curl ... | bash` is a convenience. If that makes you nervous (valid!), inspect first:
```bash
curl -fsSL https://raw.githubusercontent.com/samridhgupta/burnrate/main/install.sh | less
# Then run it
```

Or just use Homebrew — the formula is in the repo and checksummed.

### Verify yourself

```bash
# Check for network calls
grep -r "curl\|wget\|nc \|/dev/tcp" lib/
# → only in doctor.sh as a dependency check, never called

# Check what files it writes
burnrate doctor 2>&1 | grep "Write\|write\|config"

# Inspect any release tarball
tar -tzf burnrate-*.tar.gz | head -20
```

---

## License

MIT. Do whatever. Just don't blame us when you see the bill. ❄️
