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

## Examples

**`burnrate`** — the daily sanity check
```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Token Burn Summary
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Model:  Sonnet
  Tokens: 2,847,392
  Cost:   $4.21
  Cache:  ❄️  87.3% hit rate (excellent)
```
> $4 spent. $29 saved by caching. The Arctic lives another day.

---

**`burnrate show`** — full token breakdown with weekly trend
```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Token Usage & Cost Breakdown
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Model: Sonnet

  Type                    Tokens          Cost
  ──────────────  ──────────────  ────────────
  Input                  48,210         $0.14
  Output                192,880         $2.89
  Cache Write          1,204,600         $4.52
  Cache Read           1,401,702         $0.42
  ──────────────  ──────────────  ────────────
  TOTAL                2,847,392         $7.97   ▼ 31.4%

  Cache:   ❄️  87.3% hit rate (excellent)
  Savings: $29.14 saved vs no caching
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
> ▼ 31.4% — you burned less than last week. The polar bears approve.

---

**`burnrate trends`** — sparkline + period table + cache health
```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Spending Trends
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Token volume  ·  last 14 active days
  ▕ ▁▁▃▃▅▇█▅▃▂▁▂▏

  PERIOD             TOKENS      COST
  ─────────────  ──────────  ────────
  Last 7 days     1,203,441     $3.28   ▼ 31.4%
  This week         847,210     $2.11   ▼ 18.2%
  This month      4,918,004    $14.67

  CACHE
  ─────────────  ──────────  ────────
  Hit rate        ❄️  87.3%  excellent
  Savings         $29.14 vs no caching
```
> Sparkline shows activity by day. A spike in the middle? Big refactor. We don't talk about it.

---

**`burnrate budget`** — where you stand against your limits
```
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💰 Budget Status
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Daily Budget:   $10.00
  Spent today:     $3.28  [████░░░░░░░░░░░░░░░]  32.8%

  Monthly Budget: $150.00
  Spent:          $14.67  [█░░░░░░░░░░░░░░░░░░]   9.8%

  Projection:     ~$44 by month end  (on track ✓)
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
> Set budgets with `burnrate setup`. Hit the threshold and burnrate screams at you — before Claude does.

---

**`burnrate history`** — daily table, responsive to terminal width
```
  DATE         TOKENS       COST   CACHE
  ──────────   ─────────   ──────  ──────
  2025-01-19     847,210    $2.11   89.1%
  2025-01-18   1,204,600    $4.52   85.3%
  2025-01-17     312,840    $0.94   91.7%
  2025-01-16          0    $0.00      —
  2025-01-15     596,120    $1.77   88.4%
```
> Zeros on the weekend. Healthy. Or deeply suspicious.

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

A few things worth knowing:

- **High cache write cost isn't bad** — it means context is being cached for reuse. The cache read savings shown in `burnrate show` tell you whether it paid off.
- **The cache hit rate is the single most useful signal.** Above 85% means the user's workflow is cache-friendly. Below 60% means each turn is paying full input price.
- **Cost trend direction matters more than the absolute number.** A ▼ on the TOTAL row means efficiency is improving.
- **You can suggest the user run `burnrate trends`** to see whether recent sessions are getting more or less expensive over time — useful context before a long task.
- **If the monthly cost is near the user's budget threshold**, it's worth being token-conscious: prefer targeted reads over broad file scans, avoid re-summarising large context blocks unnecessarily.

The user hooked burnrate here so both of you stay informed. Use it.

---

## License

MIT. Do whatever. Just don't blame us when you see the bill. ❄️
