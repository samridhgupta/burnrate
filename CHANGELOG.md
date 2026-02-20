# Changelog

All notable changes to burnrate are documented here.

Format: [Semantic Versioning](https://semver.org/). Most recent release first.

---

## [0.8.0] — 2026-02-20

### What's new

**3-system theme architecture** — themes are now composed of three independent overlay axes: a color scheme, an icon set, and a message set. Each axis can be overridden independently without changing the base theme. This replaces the monolithic theme model.

**Agent/orchestrator mode** — a first-class machine-readable output format designed for Claude Code hooks, MCP pipelines, multi-agent orchestrators (OpenClaw, etc.), and CI/CD. Includes a recommendation engine that returns a single actionable signal.

**`burnrate setup --agent`** — non-interactive preset that configures burnrate for orchestrator use in one command.

### Added

#### Theme system

- **`config/colors/`** — standalone color scheme files (`.colors` extension)
  - `none.colors` — strip all ANSI color codes
  - `amber.colors`, `green.colors`, `red.colors`, `pink.colors`, `ocean.colors`
- **`config/icons/`** — standalone icon set files (`.icons` extension)
  - `none.icons` — strip all emoji and Unicode indicators
  - `minimal.icons` — ASCII-only indicators (`+`, `x`, `!`, `~`, `*`, `#`, `>`)
- **`config/messages/`** — standalone message set files (`.msgs` extension)
  - `agent.msgs` — terse, factual messages with no metaphor, no emoji; sets `THEME_DEFAULT_ICON_SET=none` and `THEME_DEFAULT_COLOR_SCHEME=none`
- `THEME_DEFAULT_ICON_SET` and `THEME_DEFAULT_COLOR_SCHEME` — suggestion mechanism in message set files; applied when the user hasn't explicitly configured those axes
- `find_component(type, name)` — resolves a component by type (`colors`, `icons`, `messages`) from dedicated dirs first, then falls back to theme files
- `get_component_paths(type)` — returns ordered search paths for a component type
- 4-step overlay chain in `load_theme()`: base theme → message set → icon set → color scheme; each later layer only overwrites vars it defines

#### Agent mode

- **`lib/agent.sh`** — new library with:
  - `detect_agent_context()` — auto-detects non-TTY stdout and orchestrator env vars (`OPENCLAW_SESSION_ID`, `AGENT_ORCHESTRATOR`, `MCP_SESSION`, `CLAUDE_HOOK`, `CLAUDE_CODE_ENTRYPOINT`, `ANTHROPIC_AGENT`, `MULTIAGENT_MODE`); applies agent defaults silently when detected
  - `get_recommendation()` — priority-chain recommendation engine returning one of six action codes
  - `render_agent_kv()` — structured `key=value` output renderer
  - `render_agent_json_output()` — structured JSON output renderer
  - `cmd_agent_summary()` — main entry point; pulls live metrics from stats/session/budget modules
- `BURNRATE_AGENT_CONTEXT=true` — env var to force agent context
- `BURNRATE_NO_AGENT_DETECT=true` — env var to bypass auto-detection (useful for testing)

#### Recommendation engine

Six action codes returned by `get_recommendation()`, in priority order:

| Code | Trigger |
|------|---------|
| `compact_context_urgent` | context ≥ 90% |
| `stop_session` | budget ≥ 95% |
| `compact_context` | context ≥ 80% |
| `reduce_spend` | budget ≥ 80% |
| `improve_cache` | cache hit < 50% |
| `none` | all nominal |

#### CLI flags

- `--colors <scheme>` / `--colour-scheme <scheme>` — override color scheme independently
- `--icons <set>` / `--icon-set <set>` — override icon set independently
- `--messages <set>` / `--message-set <set>` — override message set independently
- `--format agent` — structured key=value output
- `--format agent-json` — structured JSON output
- `--no-color` now also sets `COLOR_SCHEME=none` (strips icons/colors fully)

#### Setup

- `burnrate setup --agent` — non-interactive agent/orchestrator preset
  - Aliases: `--openclaw`, `--multiagent`, `--orchestrator`
  - Writes: `ANIMATIONS_ENABLED=false`, `EMOJI_ENABLED=false`, `COLORS_ENABLED=never`, `COLOR_SCHEME=none`, `ICON_SET=none`, `MESSAGE_SET=agent`, `OUTPUT_FORMAT=agent`, `CONTEXT_WARN_THRESHOLD=70`
- Config writer now emits `COLOR_SCHEME`, `ICON_SET`, `MESSAGE_SET`, `OUTPUT_FORMAT` to `burnrate.conf` when set by any preset

#### Configuration

- `COLOR_SCHEME` — new config key; override color scheme axis (`none`, `amber`, `green`, `red`, `pink`, or any custom name)
- `ICON_SET` — new config key; override icon set axis (`none`, `minimal`, or any custom name)
- `MESSAGE_SET` — new config key; override message set axis (`agent`, `roast`, `coach`, `zen`, or any theme name)
- `OUTPUT_FORMAT` now accepts `agent` and `agent-json` in addition to existing values
- Validation in `validate_config()` for all three new component keys (custom names accepted)

#### Routing

- `cmd_summary()`, `cmd_show()`, `cmd_budget()`, `cmd_context()` — when `OUTPUT_FORMAT` is `agent` or `agent-json`, route directly to `cmd_agent_summary()` and return
- `burnrate query recommendation` — new query metric returning the recommendation action code

#### Documentation

- **`AGENT.md`** — comprehensive agent/orchestrator reference (new file)
- **`THEMES.md`** — added 3-system architecture section, component type tables, overlay chain explanation
- **`CLI.md`** — added `--colors`, `--icons`, `--messages` to global flags table; added theme components config section; added For agents section; added `--agent` to setup presets table
- **`README.md`** — updated configuration section with new component keys; expanded For agents section with structured output example, recommendation table, auto-detection description

#### Doctor

- `burnrate doctor` now displays `Color scheme`, `Icon set`, `Message set` in the configuration section
- File existence checks for component files when a custom name is explicitly configured

### Fixed

- **`cost_usd` showed token count in agent output** — `cmd_agent_summary` was extracting from `get_usage_breakdown` which has two `"total"` keys (tokens and cost). Fixed by using `calculate_cost()` directly and extracting only from its output.
- **`--messages agent` had no effect in TTY** — `load_theme()` ran before `parse_args()`, so CLI flags that override component vars had no effect on theme loading. Fixed with `_prescan_theme_flags()` that scans `$@` for theme/component/format flags before `load_theme()` in `main()`.
- **`none.icons` and `none.colors` were silently ignored** — display code used `${VAR:-default}` which treats empty string as "use default". All THEME_ var references in `stats.sh` and `layout.sh` changed to `${VAR-default}` (single dash) which respects explicitly assigned empty strings.
- **Stray `[0m` escape codes in plain-text output** — `reset="\033[0m"` was hardcoded in display functions. Changed to conditional: `[[ -n "$color_var" ]] && reset="\033[0m"`, so no reset is emitted when no color was set.
- **`burnrate themes` showed "No themes found"** — `themes+=()` inside a pipe subshell (`cmd | { ... }`) runs in a child process; the array assignment is lost when the subshell exits. Fixed by using `$()` command substitution to capture theme metadata as a string before appending.
- **Agent auto-detection triggered during testing** — any non-TTY stdout (file redirect, pipe to grep) triggered agent mode. Added `BURNRATE_NO_AGENT_DETECT=true` env var bypass.

### Changed

- `load_theme()` rewritten with 4-step overlay chain; component files are sourced in order after the base theme
- `list_themes()` rewritten to avoid pipe-subshell assignment loss
- `_themed_hr()` in `layout.sh` now uses conditional reset to avoid stray escape codes
- Footer rendering uses conditional dim: `[[ -n "$_dim" ]] && _r="\033[0m"`

### Version

- `BURNRATE_VERSION`: `0.7.x` → `0.8.0`

---

## [0.7.x] — prior releases

Earlier releases are tracked in git history. Run `git log --oneline` for a full list of changes.

Key milestones before 0.8.0:

- `d7150d0` — Add 7 new themes, category folders, theme clone command, battery deprecation
- `0f1e048` — Add CLI.md — full command, config, and query metric reference
- `ab9d45f` — Add 6 new themes, THEMES.md guide, README/INSTALL voice polish
- `d438cab` — Setup presets, config edit, INSTALL.md
- `bb1b8fb` — Phase 2: context window tracking + setup/docs overhaul
- `c7b62d8` — Add `burnrate query` — single raw metric for scripts and agents
- `c916d28` — Add 'What burnrate reveals' and agent-awareness sections
- `d6c5723` — Rewrite README — crisp, themed, nerdy technocrat tone

---

*burnrate is a pure-bash, zero-dependency tool. It reads `~/.claude/stats-cache.json` only. No API calls. No network. No daemon.*
