# burnrate — Installation & Configuration

**→** [Install](#install) · [Setup presets](#setup-presets) · [Individual flags](#individual-flags) · [Hook setup](#claude-code-hook) · [Edit config](#editing-config) · [All config options](#all-config-options) · [Uninstall](#uninstall)

---

## Install

**Homebrew** (macOS / Linux — recommended)
```bash
brew tap samridhgupta/burnrate https://github.com/samridhgupta/burnrate
brew install burnrate
```

**curl one-liner**
```bash
curl -fsSL https://raw.githubusercontent.com/samridhgupta/burnrate/main/install.sh | bash
```

**git (manual)**
```bash
git clone https://github.com/samridhgupta/burnrate
cd burnrate && ./install.sh
```

**WSL2** — run the curl one-liner inside your WSL2 terminal. If Claude Code runs on Windows, symlink its stats file:
```bash
ln -s /mnt/c/Users/$WINDOWS_USER/.claude ~/.claude
```

**Verify**
```bash
burnrate          # Today's summary
burnrate doctor   # Full health check (prepare for humbling)
```

---

## Setup presets

After install, run `burnrate setup` to configure. Use a preset to skip all prompts — or use the interactive wizard if you enjoy making decisions at install time:

```bash
burnrate setup                # interactive wizard (recommended for first install)
burnrate setup --arctic       # 🧊 all features on
burnrate setup --glacier      # ❄️  balanced defaults
burnrate setup --iceberg      # 🏔  lean, no animations
burnrate setup --permafrost   # 🪨  CI/script safe, fully non-interactive
```

### Presets at a glance

| Feature | `--arctic` | `--glacier` | `--iceberg` | `--permafrost` |
|---------|-----------|------------|------------|---------------|
| Animations | ✓ normal | ✓ normal | ✗ | ✗ |
| Emoji | ✓ | ✓ | ✗ | ✗ |
| Colors | auto | auto | auto | never |
| Claude Code hook | auto ✓ | auto ✓ | ✗ | ✗ |
| Context warn threshold | 75% | 85% | 90% | disabled |
| Context display | both | both | number only | number only |
| Budget prompt | ✓ | ✓ | ✗ | ✗ |
| Interactive prompts | ✗ | ✗ | ✗ | ✗ |

### Aliases

Each preset has a short alias and a longer descriptive name — they're identical:

| Themed | Descriptive | Also works |
|--------|-------------|------------|
| `--arctic` | `--full` | `--max` |
| `--glacier` | `--medium` | `--default` |
| `--iceberg` | `--minimal` | `--min` |
| `--permafrost` | `--ci` | `--script` |

```bash
burnrate setup --full       # same as --arctic
burnrate setup --ci         # same as --permafrost
```

---

## Individual flags

Mix with a preset or use standalone to override specific options:

```bash
# Start from a preset, then tweak
burnrate setup --glacier --theme=ember           # medium + ember theme
burnrate setup --iceberg --hook                  # lean but add the Stop hook
burnrate setup --arctic --context-warn=90        # full but higher warn threshold
burnrate setup --glacier --no-animations         # medium without animations

# Pure individual flags (no preset — interactive for anything not specified)
burnrate setup --theme=space
burnrate setup --no-emoji --no-animations
burnrate setup --context-warn=80 --context-display=visual
```

### Flag reference

| Flag | Values | Default |
|------|--------|---------|
| `--theme=NAME` | `glacial` `ember` `battery` `hourglass` `garden` `ocean` `space` | `glacial` |
| `--animations` / `--no-animations` | — | `true` |
| `--animation-speed=SPEED` | `slow` `normal` `fast` `instant` | `normal` |
| `--emoji` / `--no-emoji` | — | `true` |
| `--hook` / `--no-hook` | — | prompted |
| `--color` / `--no-color` | — | `auto` |
| `--context-warn=N` | 0–100 | `85` |
| `--no-context-warn` | — | off |
| `--context-display=MODE` | `visual` `number` `both` | `both` |

---

## Claude Code Hook

The Stop hook shows your token summary after every Claude response. It's the single most useful thing you can do with burnrate — you'll always know your burn rate. Ignorance was cheaper. But now you know.

**Setup automatically:**
```bash
burnrate setup --hook-only     # just the hook, nothing else
burnrate setup --arctic        # hook included in --arctic / --glacier presets
burnrate setup                 # hook is strongly recommended in interactive mode
```

**Manual setup** — add to `~/.claude/settings.json`:
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

**Quiet variant** — just the cost number, no banner:
```json
{ "type": "command", "command": "burnrate query cost" }
```

**Context-aware variant** — warn only when context is filling:
```json
{
  "type": "command",
  "command": "bash -c 'pct=$(burnrate query context_pct 2>/dev/null); [[ \"$pct\" == \"N/A\" ]] && exit 0; (( ${pct%.*} > 75 )) && burnrate context || true'"
}
```

**Remove hook** — edit `~/.claude/settings.json` and delete the burnrate entry from `hooks.Stop`.

---

## Editing config

Config file location: `~/.config/burnrate/burnrate.conf`

```bash
burnrate config edit        # open in $EDITOR (or nano)
burnrate config show        # print current values
```

Or set any option as an environment variable (takes precedence over config file):
```bash
CONFIG_THEME=ember burnrate          # one-off
export CONFIG_EMOJI_ENABLED=false    # session-wide
```

Re-run setup at any time — it overwrites the config file:
```bash
burnrate setup --glacier --theme=ember   # regenerate with new preset
burnrate setup --budget-only             # update just the budget values
```

---

## All config options

Every knob. Every dial. All of them with sensible defaults you'll probably never change, except `THEME` and `MONTHLY_BUDGET`, which you'll change immediately.

```bash
# ~/.config/burnrate/burnrate.conf

# ── Display ──────────────────────────────────────────────────────────────────
THEME=glacial              # glacial | ember | battery | hourglass | garden | ocean | space
COLORS_ENABLED=auto        # auto | always | never
EMOJI_ENABLED=true         # true | false
OUTPUT_FORMAT=detailed     # detailed | compact | minimal | json

# ── Animations ───────────────────────────────────────────────────────────────
ANIMATIONS_ENABLED=true    # true | false
ANIMATION_SPEED=normal     # slow | normal | fast | instant
ANIMATION_STYLE=standard   # standard | minimal | fancy

# ── Paths ─────────────────────────────────────────────────────────────────────
CLAUDE_DIR=$HOME/.claude
STATS_FILE=$CLAUDE_DIR/stats-cache.json
DATA_DIR=$HOME/.local/share/burnrate
CACHE_DIR=$HOME/.cache/burnrate

# ── Budget ────────────────────────────────────────────────────────────────────
DAILY_BUDGET=0.00          # 0 = no limit
MONTHLY_BUDGET=0.00        # 0 = no limit
BUDGET_ALERT=90            # % threshold for warnings (0-100)

# ── Context window ────────────────────────────────────────────────────────────
CONTEXT_WARN=true          # show warning in summary when context fills
CONTEXT_WARN_THRESHOLD=85  # % fill level that triggers the warning
CONTEXT_DISPLAY=both       # visual (gauge only) | number (tokens only) | both

# ── Behavior ──────────────────────────────────────────────────────────────────
DEBUG=false
QUIET=false
SHOW_DISCLAIMER=true
```

### Common config recipes

**Minimal / CI output** — no animations, no emoji, never use color:
```bash
ANIMATIONS_ENABLED=false
EMOJI_ENABLED=false
COLORS_ENABLED=never
```

**High-frequency hook** — quiet output for fast feedback:
```bash
OUTPUT_FORMAT=compact
ANIMATIONS_ENABLED=false
SHOW_DISCLAIMER=false
```

**Context-heavy sessions** — warn early, show gauge only:
```bash
CONTEXT_WARN_THRESHOLD=70
CONTEXT_DISPLAY=visual
```

**Agent-optimized** — machine-readable, low token output:
```bash
COLORS_ENABLED=never
EMOJI_ENABLED=false
ANIMATIONS_ENABLED=false
SHOW_DISCLAIMER=false
```
Then use `burnrate query <metric>` for single values.

---

## Uninstall

Parting is such sweet sorrow. The Arctic will miss you.

**Standard** (keeps config and budget data):
```bash
./uninstall.sh
# or: curl -fsSL .../uninstall.sh | bash
```

**Purge** (removes everything including config):
```bash
./uninstall.sh --purge
```

The Stop hook in `~/.claude/settings.json` is **not** auto-removed. If you added it, remove the burnrate entry from `hooks.Stop` manually.

Reinstall anytime:
```bash
burnrate setup --glacier      # restore defaults
burnrate setup --hook-only    # just re-add the hook
```

---

*Zero tokens used. Reads local files only. [← Back to README](README.md)*
