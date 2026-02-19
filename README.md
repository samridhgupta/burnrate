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

---

## Hook into Claude Code sessions

Run burnrate automatically after every Claude response. Add this to `~/.claude/settings.json`:

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

After each session: your token burn flashes up before the next prompt. You'll feel every melting ice shard.

Want just the cost delta (quieter)?
```json
{ "type": "command", "command": "burnrate trends --quiet" }
```

---

## Permissions

Burnrate needs exactly two things:

| Access | Path | Why |
|--------|------|-----|
| **Read** | `~/.claude/stats-cache.json` | Your token stats. Never modified. |
| **Write** | `~/.config/burnrate/` | Config + budget state. Your Claude files untouched. |

No network. No API keys. No root. No surprises.

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
burnrate config       # Current configuration
burnrate themes       # List themes
burnrate preview <t>  # Preview a theme
burnrate doctor       # Full health check (28 assertions)
burnrate setup        # Interactive setup wizard
```

**Export**
```bash
burnrate export summary json           # stdout
burnrate export history csv out.csv    # to file
burnrate export full markdown report.md
```

---

## Configuration

`~/.config/burnrate/burnrate.conf` — or set `CONFIG_*` env vars:

```bash
CONFIG_THEME="glacial"         # glacial | ember | battery | hourglass | garden | ocean | space
CONFIG_DAILY_BUDGET="10.00"    # alert when you blow past it
CONFIG_MONTHLY_BUDGET="150.00"
CONFIG_BUDGET_ALERT="90"       # % threshold for warnings
CONFIG_COLORS_ENABLED="auto"   # auto | always | never
CONFIG_EMOJI_ENABLED="true"
```

---

## Themes

Seven built-in metaphors for your token burn:

| Theme | Vibe |
|-------|------|
| `glacial` ❄️ | Melting ice caps. Cache or the Arctic drowns. |
| `ember` 🔥 | Burning fuel. Every prompt fans the flame. |
| `battery` 🔋 | Draining charge. Cache = power saving mode. |
| `hourglass` ⏳ | Sand falling. Tokens are time. |
| `garden` 🌱 | Growing carefully. Waste nothing. |
| `ocean` 🌊 | Rising tide. Each token a drop. |
| `space` 🚀 | Finite fuel. Infinite void. |

```bash
burnrate --theme ember          # one-off
burnrate preview space          # try before you commit
```

---

## How it works

```
~/.claude/stats-cache.json
        ↓  grep + sed (no jq)
   token counts  →  bc math  →  cost
        ↓
   dailyModelTokens  →  sparkline  →  trend %
        ↓
   your terminal in ~50ms
```

Pure bash 3.2+. One external dep (`bc` for decimal math). Zero startup overhead. The entire thing is readable shell — no magic, no build step, no node_modules abyss.

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
| **Reads** | `~/.claude/stats-cache.json` only. Never written to. |
| **Writes** | `~/.config/burnrate/` — your config + budget state |
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
