# burnrate CLI Reference

> Complete command and configuration reference. Every flag, every option, every metric. No guessing.
>
> Agent/orchestrator integration → **[AGENT.md](AGENT.md)**

---

## Contents

- [Commands](#commands)
- [Global flags](#global-flags)
- [Config file options](#config-file-options)
- [Query metrics](#query-metrics)
- [Export formats](#export-formats)
- [Setup flags](#setup-flags)
- [Setup presets](#setup-presets)
- [Environment variables](#environment-variables)
- [Config file locations](#config-file-locations)

---

## Commands

| Command | Description | Example |
|---------|-------------|---------|
| _(none)_ | Today's cost summary (default view) | `burnrate` |
| `show` | Detailed cost breakdown with cache analysis | `burnrate show` |
| `history` | Daily usage history table | `burnrate history` |
| `week` | This week's aggregate spend | `burnrate week` |
| `month` | This month's aggregate spend | `burnrate month` |
| `trends` | Spending trends with week-over-week change | `burnrate trends` |
| `budget` | Budget status, remaining, and alerts | `burnrate budget` |
| `context` | Context window usage gauge + recommendation | `burnrate context` |
| `query <metric>` | Single raw value — for scripts and agents | `burnrate query cache_rate` |
| `export <type>` | Export data as json/csv/markdown | `burnrate export summary json` |
| `themes` | List all themes, grouped by category | `burnrate themes` |
| `themes clone <s> <t>` | Clone a built-in theme to customize | `burnrate themes clone glacial mytheme` |
| `preview <theme>` | Preview a theme without setting it | `burnrate preview ocean` |
| `config` | Show current configuration | `burnrate config` |
| `config show` | Same as `config` | `burnrate config show` |
| `config edit` | Open config file in `$EDITOR` | `burnrate config edit` |
| `setup` | Interactive setup wizard | `burnrate setup` |
| `setup [flags]` | Non-interactive setup with preset or flags | `burnrate setup --arctic` |
| `doctor` | Full health check (28 assertions) | `burnrate doctor` |
| `version` | Version and environment info | `burnrate version` |
| `help` | Show help message | `burnrate help` |

---

## Global flags

These flags work with any command:

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--theme <name>` | any theme name | config value | Override theme for this run only |
| `--format <fmt>` | `detailed` `compact` `minimal` `json` `agent` `agent-json` | `detailed` | Override output format |
| `--colors <scheme>` | `none` `amber` `green` `red` `pink` `ocean` `<name>` | theme default | Override color scheme independently of theme |
| `--icons <set>` | `none` `minimal` `<name>` | theme default | Override icon set independently of theme |
| `--messages <set>` | `agent` `roast` `coach` `<name>` | theme default | Override message set independently of theme |
| `--no-color` | — | — | Disable colors (same as `--colors none`) |
| `--no-emoji` | — | — | Disable emoji for this run |
| `--no-anim` | — | — | Disable animations for this run |
| `--debug` | — | — | Enable debug logging |
| `--quiet` / `-q` | — | — | Minimal output only |

**One-off theme or format examples:**
```bash
burnrate --theme ember                         # ember theme, default command
burnrate show --theme ocean                    # ocean theme, detailed report
burnrate --format json                         # json output, default command
burnrate budget --format compact               # compact budget view
burnrate --no-color --no-emoji today           # plain text, no decoration
burnrate --format agent                        # structured key=value for agent consumption
burnrate --format agent-json                   # structured JSON for pipelines
burnrate --messages agent                      # agent messages on any theme
burnrate --colors ocean --icons minimal        # ocean colors + ASCII icons, keep theme messages
burnrate --theme roast --colors none           # roast voice, strip all color
```

---

## Config file options

Config file lives at `~/.config/burnrate/burnrate.conf` (see [Config file locations](#config-file-locations)).

Format: `KEY=value` — no spaces around `=`, no `CONFIG_` prefix in the file.

### Display

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `THEME` | theme name | `glacial` | Active theme |
| `COLORS_ENABLED` | `true` `false` `auto` | `auto` | ANSI colors (`auto` = detect terminal) |
| `EMOJI_ENABLED` | `true` `false` | `true` | Unicode emoji in output |
| `OUTPUT_FORMAT` | `detailed` `compact` `minimal` `json` `agent` `agent-json` | `detailed` | Default output format |

### Theme components

Override color, icons, or messages independently — without changing the theme.

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `COLOR_SCHEME` | `none` `amber` `green` `red` `pink` `ocean` `<name>` | _(theme default)_ | Color palette override |
| `ICON_SET` | `none` `minimal` `<name>` | _(theme default)_ | Icon set override |
| `MESSAGE_SET` | `agent` `roast` `coach` `<name>` | _(theme default)_ | Message set override |

**How it works:** each component is loaded on top of the base theme. Later layers only overwrite vars they define. A message set can also suggest default icon/color schemes via `THEME_DEFAULT_ICON_SET` and `THEME_DEFAULT_COLOR_SCHEME` — these apply when you haven't explicitly set the component. The `agent` message set does this (strips icons and colors by default).

**Examples:**
```bash
# Config file
COLOR_SCHEME=ocean          # ocean colors on any theme
ICON_SET=minimal            # ASCII-only icons
MESSAGE_SET=agent           # terse factual messages
OUTPUT_FORMAT=agent         # key=value output

# Agent/orchestrator config (written by: burnrate setup --agent)
MESSAGE_SET=agent
COLOR_SCHEME=none
ICON_SET=none
OUTPUT_FORMAT=agent
CONTEXT_WARN_THRESHOLD=70
```

### Animations

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `ANIMATIONS_ENABLED` | `true` `false` | `true` | Enable terminal animations |
| `ANIMATION_SPEED` | `slow` `normal` `fast` `instant` | `normal` | Animation playback speed |
| `ANIMATION_STYLE` | `standard` `minimal` `fancy` | `standard` | Animation style variant |

### Budget

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `DAILY_BUDGET` | decimal number | `0.00` | Daily spend limit in USD (`0` = no limit) |
| `MONTHLY_BUDGET` | decimal number | `0.00` | Monthly spend limit in USD (`0` = no limit) |
| `BUDGET_ALERT` | 0–100 | `90` | Alert threshold as % of budget used |

### Context window

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `CONTEXT_WARN` | `true` `false` | `true` | Warn when context fill exceeds threshold |
| `CONTEXT_WARN_THRESHOLD` | 0–100 | `85` | Context fill % that triggers warning |
| `CONTEXT_DISPLAY` | `visual` `number` `both` | `both` | How to display context usage: gauge only, token count only, or both |

### Behavior

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `DEBUG` | `true` `false` | `false` | Enable verbose debug logging |
| `QUIET` | `true` `false` | `false` | Suppress all non-essential output |
| `SHOW_DISCLAIMER` | `true` `false` | `true` | Show "zero tokens used" disclaimer |
| `COST_DECIMALS` | integer | `2` | Decimal places for cost display |

### Paths

| Key | Default | Description |
|-----|---------|-------------|
| `CLAUDE_DIR` | `~/.claude` | Claude Code data directory |
| `STATS_FILE` | `~/.claude/stats-cache.json` | Stats cache file location |
| `DATA_DIR` | `~/.local/share/burnrate` | burnrate data directory |
| `CACHE_DIR` | `~/.cache/burnrate` | burnrate cache directory |

**Minimal example config:**
```bash
THEME=ocean
DAILY_BUDGET=2.00
MONTHLY_BUDGET=40.00
ANIMATIONS_ENABLED=false
```

**Full example config:**
```bash
# ~/.config/burnrate/burnrate.conf

THEME=ember
COLORS_ENABLED=auto
EMOJI_ENABLED=true
OUTPUT_FORMAT=detailed

ANIMATIONS_ENABLED=true
ANIMATION_SPEED=fast
ANIMATION_STYLE=standard

DAILY_BUDGET=1.50
MONTHLY_BUDGET=30.00
BUDGET_ALERT=80

CONTEXT_WARN=true
CONTEXT_WARN_THRESHOLD=80
CONTEXT_DISPLAY=both

DEBUG=false
QUIET=false
SHOW_DISCLAIMER=false
```

---

## Query metrics

`burnrate query <metric>` returns a single raw value on stdout — no formatting, no color, no units. Designed for scripting, hooks, and agents.

| Metric | Returns | Example output |
|--------|---------|----------------|
| `cost` | Total spend today (USD) | `4.21` |
| `tokens` | Total token count today | `2847392` |
| `cache_rate` | Cache hit rate 0–100 | `87.30` |
| `cache_savings` | Dollar savings from caching today | `29.14` |
| `trend` | Week-over-week % change, signed | `-31.4` or `N/A` |
| `weekly_cost` | This week's spend (USD) | `2.11` |
| `monthly_cost` | This month's spend (USD) | `14.67` |
| `last7_cost` | Last 7 days spend (USD) | `3.28` |
| `model` | Current model name | `sonnet` |
| `context_tokens` | Tokens in current session context | `156312` |
| `context_pct` | Context fill % 0–100 | `78.2` |
| `context_remaining` | Tokens remaining in context window | `43688` |
| `recommendation` | Action code from recommendation engine | `compact_context` |
| `budget_pct` | Daily budget consumed % (0 if no budget set) | `82.4` |
| `daily_cost` | Today's spend (USD) | `2.14` |
| `savings` | Cache savings USD today | `1830.37` |

**In scripts:**
```bash
spend=$(burnrate query cost)
if (( $(echo "$spend > 2.00" | bc -l) )); then
  echo "Daily budget pressure: $spend"
fi
```

**In Claude Code hooks** (`~/.claude/settings.json`):
```json
{
  "hooks": {
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "burnrate query context_pct | awk '{if ($1+0 > 85) print \"[burnrate] Context at \" $1 \"% — consider /compact\"}'"
      }]
    }]
  }
}
```

---

## Export formats

```bash
burnrate export <type> [format] [output_file]
```

| Type | Description |
|------|-------------|
| `summary` | Today's cost summary |
| `history` | Daily usage history |
| `budget` | Budget status |
| `full` | Everything |

| Format | Description |
|--------|-------------|
| `json` | Machine-readable JSON (default) |
| `csv` | Comma-separated values |
| `markdown` | Markdown table |

```bash
burnrate export summary              # json to stdout
burnrate export summary markdown     # markdown to stdout
burnrate export history csv data.csv # csv to file
burnrate export full json full.json  # full export to file
```

**History with date range:**
```bash
burnrate export history json history.json 2024-01-01 2024-01-31
```

---

## Setup flags

`burnrate setup [flags]` — use flags to skip the interactive wizard or pre-configure options.

The interactive wizard (no flags) walks through 7 steps: prerequisites → theme → animations → emoji → budgets → **context window warning** → Claude Code hook. Every step has a default — press Enter to accept and move on.

### Preset shortcuts

| Flag | Alias | What it sets |
|------|-------|-------------|
| `--arctic` | `--full` | All features on, hook yes, threshold 75%, all animations |
| `--glacier` | `--medium` | Balanced defaults, hook yes, threshold 85% |
| `--iceberg` | `--minimal` | No animations/emoji, no hook, threshold 90%, number display |
| `--permafrost` | `--ci` | No color/emoji/anim/hook, threshold 100%, fully non-interactive |
| `--agent` | `--openclaw` | Structured output, agent messages, no decoration, hook yes, threshold 70% |

### Individual flags

| Flag | Description |
|------|-------------|
| `--preset=NAME` | Apply a named preset (`arctic`, `glacier`, `iceberg`, `permafrost`, `agent`) |
| `--theme=NAME` | Set default theme |
| `--hook` | Install Claude Code Stop hook |
| `--no-hook` | Skip hook installation |
| `--no-animations` | Disable animations |
| `--no-color` | Disable colors |
| `--no-emoji` | Disable emoji |
| `--emoji` | Enable emoji |
| `--context-warn=N` | Set context warning threshold (0–100) |
| `--context-display=MODE` | Set context display mode (`visual`, `number`, `both`) |
| `--animation-speed=SPEED` | Set animation speed (`slow`, `normal`, `fast`, `instant`) |
| `--non-interactive` | Skip all prompts, use flag values only |

### Fast paths

| Flag | Description |
|------|-------------|
| `--hook-only` | Install Claude Code hook only, skip all other setup |
| `--budget-only` | Set budget only, skip all other setup |

**Examples:**
```bash
burnrate setup                           # interactive wizard
burnrate setup --arctic                  # max features, no prompts
burnrate setup --glacier --theme ocean   # medium preset, ocean theme
burnrate setup --ci                      # CI/CD install, no interaction
burnrate setup --agent                   # agent/orchestrator preset — structured output
burnrate setup --hook-only               # just add the hook
burnrate setup --theme=ember --no-hook   # set theme, skip hook
```

---

## Environment variables

These override both config file and defaults. Useful for per-session overrides or CI environments.

| Variable | Overrides | Description |
|----------|-----------|-------------|
| `BURNRATE_CONFIG` | — | Path to config file (overrides default search) |
| `CONFIG_THEME` | `THEME` | Active theme |
| `CONFIG_COLORS_ENABLED` | `COLORS_ENABLED` | Color mode |
| `CONFIG_EMOJI_ENABLED` | `EMOJI_ENABLED` | Emoji mode |
| `CONFIG_OUTPUT_FORMAT` | `OUTPUT_FORMAT` | Output format |
| `CONFIG_ANIMATIONS_ENABLED` | `ANIMATIONS_ENABLED` | Animations |
| `CONFIG_DAILY_BUDGET` | `DAILY_BUDGET` | Daily budget |
| `CONFIG_MONTHLY_BUDGET` | `MONTHLY_BUDGET` | Monthly budget |
| `CONFIG_DEBUG` | `DEBUG` | Debug mode |
| `CONFIG_QUIET` | `QUIET` | Quiet mode |
| `CONFIG_CONTEXT_WARN` | `CONTEXT_WARN` | Context warning |
| `CONFIG_CONTEXT_WARN_THRESHOLD` | `CONTEXT_WARN_THRESHOLD` | Context threshold |
| `CONFIG_CONTEXT_DISPLAY` | `CONTEXT_DISPLAY` | Context display mode |

**Examples:**
```bash
CONFIG_THEME=space burnrate             # use space theme for this run
CONFIG_QUIET=true burnrate budget       # quiet budget check
BURNRATE_CONFIG=/etc/burnrate.conf burnrate  # use system config
```

**In CI:**
```bash
export CONFIG_THEME=permafrost
export CONFIG_ANIMATIONS_ENABLED=false
export CONFIG_EMOJI_ENABLED=false
export CONFIG_COLORS_ENABLED=false
burnrate export summary json
```

---

## Config file locations

burnrate checks these locations in order, using the first file found:

| Priority | Path | Notes |
|----------|------|-------|
| 1 | `$BURNRATE_CONFIG` | Environment variable — highest priority |
| 2 | `$XDG_CONFIG_HOME/burnrate/burnrate.conf` | Default: `~/.config/burnrate/burnrate.conf` |
| 3 | `~/.burnrate.conf` | Legacy home directory location |
| 4 | `/etc/burnrate/burnrate.conf` | System-wide config |

**Edit config:**
```bash
burnrate config edit      # opens in $EDITOR (falls back to nano)
burnrate config show      # prints current active values
```

---

## For agents

If you're running burnrate inside a Claude Code hook, MCP pipeline, OpenClaw, or any multi-agent system:

**Structured output — one call, all metrics:**
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

```bash
burnrate --format agent-json   # same fields as JSON
```

**`recommendation` values:**

| Value | Action |
|-------|--------|
| `none` | Continue normally |
| `improve_cache` | Cache < 50% — sessions too fragmented |
| `compact_context` | Context > 80% — run `/compact` before next big task |
| `reduce_spend` | Budget > 80% — be token-conscious |
| `stop_session` | Budget > 95% — stop spending |
| `compact_context_urgent` | Context > 90% — `/compact` or new session now |

**Single-value queries (no parsing needed):**
```bash
cost=$(burnrate query cost)
cache_rate=$(burnrate query cache_rate)
context_pct=$(burnrate query context_pct)
context_remaining=$(burnrate query context_remaining)
monthly=$(burnrate query monthly_cost)
```

**Setup for agent context:**
```bash
burnrate setup --agent    # non-interactive: agent messages, no decoration, 70% context warn
```

burnrate auto-detects non-TTY stdout and known orchestrator env vars (`OPENCLAW_SESSION_ID`, `MCP_SESSION`, `CLAUDE_HOOK`, `AGENT_ORCHESTRATOR`, etc.) and applies agent defaults silently.

**Machine-readable export:**
```bash
burnrate export summary json         # export to stdout
burnrate export full json out.json   # export to file
```

Zero tokens consumed. Reads local files only. No network calls.

---

*See also: [📖 INSTALL.md](INSTALL.md) — setup presets and hook configuration | [🎨 THEMES.md](THEMES.md) — create custom themes*
