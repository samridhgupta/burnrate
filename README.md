# Burnrate 🔥❄️

> Track your Claude token burn. Because API bills shouldn't be surprises.

**⚠️ ZERO TOKENS USED** - Pure bash script. No AI calls. Just reads local stats.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0--alpha-blue)](https://github.com/yourusername/burnrate)
[![Bash](https://img.shields.io/badge/bash-3.2%2B-green)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)](https://github.com/yourusername/burnrate)
[![Security](https://img.shields.io/badge/security-audited-success)](SECURITY.md)

---

## 👥 Who Is This For?

**🧑‍💻 Developers:** Track your Claude Code costs while you build. Set budgets, get alerts, optimize your workflow.

**📊 Data Scientists:** Monitor token usage across experiments. Export to CSV/JSON for analysis.

**🏢 Teams:** Share budgets and reports. Keep everyone aligned on AI costs.

**🤖 Agents:** Yes, even AI agents can install and use burnrate! See [Agent Guide](#-for-claude-agents) below.

## 🔌 Claude Plugin Available!

Use burnrate directly from Claude conversations with our official MCP plugin:

- **Track costs** while chatting with Claude
- **Get summaries** without leaving your conversation
- **Check budgets** in real-time
- **Export data** on demand
- **Zero tokens used** - completely offline!

👉 **[Install the Plugin](plugin/README.md)** | [Quick Start](plugin/QUICKSTART.md)

```
You: "Check my token usage with burnrate"
Claude: Uses burnrate_summary tool
        📊 Token Burn Summary
        Tokens: 592M | Cost: $346.79 | Cache: 92.4% ✅
```

## 🌍 What Is This?

Burnrate tracks your [Claude Code](https://claude.com/claude-code) token usage and calculates costs in real-time. With a unique **environmental theme system**, it makes token usage tangible and meaningful - all without using a single token!

**Primary Theme:** 🧊 **GLACIAL** - Every token melts the ice. Cache to save the Arctic!

### 🔐 What Permissions Does Burnrate Need?

Don't worry, we're not asking for your first-born child! Burnrate needs:

**✅ READ Access:**
- `~/.claude/stats-cache.json` - Your Claude token stats (we just read it, never modify!)

**✅ WRITE Access:**
- `~/.config/burnrate/` - Our config files (completely isolated, your stuff is safe!)
- Export files - Only when YOU choose to export somewhere

**❌ Does NOT Need:**
- Network/Internet - We're 100% offline!
- Claude API keys - We don't make API calls
- Root/sudo - Please don't! Regular user permissions are perfect
- Your wallet - But we'll help you keep more money in it! 💰

**Security Promise:** Burnrate never makes network requests, never uses tokens, and never touches anything outside its designated folders. [Full security audit →](SECURITY.md)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Token Burn Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Model: Sonnet 4.5
Tokens: 592,540,647
Cost: $346.79
Cache Hit: 92.4%

Remember: Every token melts the ice. Cache to save the Arctic! 🐻‍❄️
```

## ✨ Key Features

- **🔓 Zero Tokens** - Pure bash, reads local `~/.claude/stats-cache.json`
  - *How it works:* Claude Code maintains a local stats cache. We just read it!

- **💰 Multi-Model Support** - Opus, Sonnet, Haiku (3/3.5/4/4.5)
  - *Implementation:* Hardcoded pricing table updated with latest API rates

- **📅 Historical Tracking** - Daily, weekly, monthly breakdowns
  - *Behind the scenes:* Parses `dailyModelTokens` array, estimates costs from proportions

- **💳 Budget Management** - Set limits, track spending, get alerts
  - *Features:* Daily/monthly budgets, percentage alerts, projected spend

- **📤 Export Everything** - JSON, CSV, Markdown formats
  - *Use cases:* Integrate with other tools, create reports, analyze trends

- **🎨 Beautiful TUI** - 7 themed experiences with ASCII animations
  - *Themes:* Glacial ❄️, Ember 🔥, Battery 🔋, Hourglass ⏳, Garden 🌱, Ocean 🌊, Space 🚀

- **🔧 15 Config Options** - Simple, essential customization
  - *Philosophy:* Minimal config, maximum impact. No bloat!

- **🖥️ Cross-Platform** - macOS (bash 3.2+) and Linux compatible
  - *How:* Auto-detects BSD vs GNU date commands, bash 3.2 compatible (no arrays!)

- **⚡ Fast & Offline** - No network calls, instant results
  - *Performance:* Pure bash is FAST. No Python startup time, no Node.js overhead!

## 🚀 Quick Start

### One-Line Install

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/burnrate/main/install.sh | bash
```

### Manual Install

```bash
# Clone repository
git clone https://github.com/yourusername/burnrate
cd burnrate

# Run installer
./install.sh

# Run setup wizard
burnrate setup
```

### Verify Installation

```bash
burnrate --version
burnrate           # Show current usage
```

---

## 🤖 For Claude Agents

**Hey Agent!** Installing burnrate for your user? Here's everything you need:

### Quick Agent Install

```bash
# 1. Clone (no tokens used!)
git clone https://github.com/yourusername/burnrate
cd burnrate

# 2. Install (creates symlink to ~/.local/bin/burnrate)
./install.sh

# 3. Verify
burnrate --version
```

### What You're Installing
- **Zero tokens:** Burnrate never calls Claude API
- **Local only:** Reads `~/.claude/stats-cache.json`
- **Safe:** No network, no modifications to Claude files
- **Fast:** Pure bash, instant execution

### Permissions Needed
```bash
# Read access
~/.claude/stats-cache.json  # Claude's token stats

# Write access (created if missing)
~/.config/burnrate/         # Burnrate config
~/.local/bin/burnrate       # Symlink to CLI
```

### Common Agent Tasks

**Check current costs:**
```bash
burnrate  # Quick summary
burnrate show  # Detailed breakdown
```

**Export data for analysis:**
```bash
# JSON for programmatic use
burnrate export summary json > /tmp/usage.json

# CSV for spreadsheets
burnrate export history csv /tmp/history.csv

# Markdown for reports
burnrate export full markdown /tmp/report.md
```

**Set up budgets:**
```bash
# Configure via env or config file
export CONFIG_DAILY_BUDGET="5.00"
export CONFIG_MONTHLY_BUDGET="150.00"
burnrate budget  # Check status
```

### Integration with Agent Workflows

```bash
# Add to shell hooks for automatic tracking
burnrate setup  # Interactive wizard

# Or manually add to ~/.bashrc:
alias burn='burnrate'
```

**Pro tip:** Use `burnrate export summary json` to get structured data you can parse and analyze!

---

## 📋 Commands

### Core Commands

```bash
burnrate              # Show today's summary (default)
burnrate show         # Detailed cost breakdown
burnrate history      # Daily usage table
burnrate week         # This week's aggregate
burnrate month        # This month's aggregate
burnrate trends       # Historical trends with week-over-week comparison
burnrate budget       # Budget status with projections
```

### Export Commands

```bash
# Export summary
burnrate export summary json
burnrate export summary csv report.csv
burnrate export summary markdown

# Export history
burnrate export history csv history.csv
burnrate export history json
burnrate export history markdown report.md 2026-01-01 2026-01-31

# Export budget
burnrate export budget json
burnrate export budget csv budget.csv

# Full report
burnrate export full markdown full-report.md
```

### Theme & Config

```bash
burnrate themes              # List available themes
burnrate preview glacial     # Preview a theme
burnrate config              # Show current configuration
burnrate setup               # Run interactive setup wizard
```

## 🎨 Themes

Burnrate includes 7 built-in themes with unique metaphors:

| Theme | Icon | Metaphor | Message |
|-------|------|----------|---------|
| **Glacial** | ❄️ | Ice melting | Every token melts the ice |
| **Ember** | 🔥 | Fire burning | Fuel your ideas, not the burn |
| **Battery** | 🔋 | Energy drain | Conserve your charge |
| **Hourglass** | ⏳ | Time flowing | Time is tokens |
| **Garden** | 🌱 | Plant growth | Nurture wisely |
| **Ocean** | 🌊 | Water level | Every drop counts |
| **Space** | 🚀 | Fuel gauge | Infinite sky, finite fuel |

### Creating Custom Themes

```bash
# Copy example theme
cp config/themes/glacial.theme ~/.config/burnrate/themes/mytheme.theme

# Edit your theme
vi ~/.config/burnrate/themes/mytheme.theme

# Use your theme
burnrate --theme mytheme
```

See [docs/THEMES.md](docs/THEMES.md) for theme development guide.

## ⚙️ Configuration

Burnrate uses 15 essential configuration options organized into categories:

### Display (4 options)
- `CONFIG_THEME` - Theme name (default: glacial)
- `CONFIG_COLORS_ENABLED` - Enable colors (auto|always|never)
- `CONFIG_EMOJI_ENABLED` - Show emoji (true|false)
- `CONFIG_OUTPUT_FORMAT` - Output format (detailed|compact|minimal|json)

### Animation (3 options)
- `CONFIG_ANIMATIONS_ENABLED` - Enable animations (true|false)
- `CONFIG_ANIMATION_SPEED` - Animation speed (slow|normal|fast|instant)
- `CONFIG_ANIMATION_STYLE` - Animation style (standard|minimal)

### Paths (4 options)
- `CONFIG_STATS_FILE` - Stats file location
- `CONFIG_CONFIG_FILE` - Config file location
- `CONFIG_DATA_DIR` - Data directory
- `CONFIG_THEMES_DIR` - Custom themes directory

### Budget (3 options)
- `CONFIG_DAILY_BUDGET` - Daily budget limit ($)
- `CONFIG_MONTHLY_BUDGET` - Monthly budget limit ($)
- `CONFIG_BUDGET_ALERT` - Alert threshold (%)

### Behavior (1 option)
- `CONFIG_SHOW_DISCLAIMER` - Show "zero tokens" disclaimer

### Configuration File Locations (Priority Order)

1. Environment variables (`CONFIG_*`)
2. `~/.config/burnrate/burnrate.conf` (XDG)
3. `~/.burnrate.conf` (Home)
4. Built-in defaults

### Example Configuration

```bash
# ~/.config/burnrate/burnrate.conf

# Display
CONFIG_THEME="glacial"
CONFIG_COLORS_ENABLED="auto"
CONFIG_EMOJI_ENABLED="true"
CONFIG_OUTPUT_FORMAT="detailed"

# Budget
CONFIG_DAILY_BUDGET="5.00"
CONFIG_MONTHLY_BUDGET="150.00"
CONFIG_BUDGET_ALERT="90"

# Animation
CONFIG_ANIMATIONS_ENABLED="true"
CONFIG_ANIMATION_SPEED="normal"
```

## 🎯 Ways to Use Burnrate

### For Individual Developers

**Morning Ritual:** Check your overnight spend
```bash
alias morning="burnrate && git status"
```

**Pre-Commit Check:** Make sure you're under budget before committing
```bash
# In .git/hooks/pre-commit
burnrate budget --check || echo "⚠️  Over budget! Consider caching more."
```

**End of Day:** Export daily report
```bash
alias eod="burnrate export summary markdown ~/reports/$(date +%Y-%m-%d).md"
```

### For Teams

**Standups:** Share team usage
```bash
# Generate team report
burnrate export full markdown team-report.md
# Share in Slack/email
```

**Sprint Reviews:** Track token usage per sprint
```bash
burnrate export history csv sprint-$SPRINT_NUMBER.csv
```

**Budget Alerts:** Set up monitoring
```bash
# Cron job for daily budget alerts
0 9 * * * burnrate budget | grep "⚠️" && notify-send "Budget Alert!"
```

### For Data Science / Research

**Experiment Tracking:** Log costs per experiment
```bash
echo "Experiment A" >> experiment.log
burnrate >> experiment.log
# Run experiment
burnrate >> experiment.log
```

**Cost Analysis:** Export to analyze patterns
```bash
burnrate export history json | jq '.[] | {date, cost}' > costs.json
```

### For Agencies / Consultants

**Client Billing:** Track costs per project
```bash
burnrate export history csv client-$CLIENT_NAME-$(date +%Y-%m).csv
```

**Cost Estimation:** Use historical data for quotes
```bash
burnrate trends  # See your average daily/weekly costs
```

### Creative Uses

**Shell Prompt:** Show budget status in PS1
```bash
burnrate_prompt() {
    local pct=$(burnrate export budget json | jq -r '.daily.percentage')
    if (( pct >= 90 )); then echo "🔥"
    elif (( pct >= 75 )); then echo "❄️"
    else echo "🧊"; fi
}
PS1='$(burnrate_prompt) '$PS1
```

**Git Commit Messages:** Auto-add cost info
```bash
# In .git/hooks/prepare-commit-msg
echo "" >> $1
echo "Token cost today: $(burnrate show | grep 'Total' | awk '{print $NF}')" >> $1
```

**Slack Bot:** Post daily summaries
```bash
#!/bin/bash
# daily-burnrate-slack.sh
curl -X POST $SLACK_WEBHOOK \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"$(burnrate export summary markdown)\"}"
```

**Gamification:** Compete with teammates!
```bash
# Who cached the most today?
echo "Cache champion: $USER - $(burnrate show | grep 'Cache Efficiency')"
```

## 📊 Usage Examples

### Check Current Usage

```bash
$ burnrate

⚠️  ZERO TOKENS USED - Pure script, reads local files only

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Token Burn Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Model: Sonnet 4.5
Tokens: 592,540,647
Cost: $346.79
Cache Hit: 92.4%

Remember: Every token melts the ice. Cache to save the Arctic! 🐻‍❄️
```

### View Detailed Breakdown

```bash
$ burnrate show

Token Usage & Cost Breakdown
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Model: Sonnet 4.5

Type                          Tokens         Cost
──────────────────── ─────────────── ────────────
Input                        218,326 $       0.65
Output                       910,583 $      13.66
Cache Write               44,943,815 $     168.54
Cache Read               546,467,923 $     163.94
──────────────────── ─────────────── ────────────
TOTAL                    592,540,647 $     346.79

Cache Efficiency: 92.40%
Cache Savings: $1,475.46
```

### Historical Trends

```bash
$ burnrate trends

📅 Historical Token Usage

Last 7 days:           21,663 tokens    $.02
This week:             18,919 tokens    $.02
This month:            18,919 tokens    $.02

📈 Weekly Trend
Last week:    $0.00
This week:    $.02 (first week)
```

### Budget Tracking

```bash
$ burnrate budget

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  💰 Budget Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Daily Budget:
  🐻‍❄️  Spent: $0.45 / $5.00 (9.0%)
  [███░░░░░░░░░░░░░░░░░░░░░░░░░░]
  ✓ Projected: $10.80 (under budget)

Monthly Budget:
  🐻‍❄️  Spent: $12.50 / $150.00 (8.3%)
  [███░░░░░░░░░░░░░░░░░░░░░░░░░░]
  ✓ Projected: $125.00 (under budget)
```

### Export Data

```bash
# Export as CSV
$ burnrate export history csv usage.csv
Exported history to: usage.csv

# Export as Markdown report
$ burnrate export full markdown report.md
Exported full to: report.md

# Export to stdout (JSON)
$ burnrate export summary json
{
  "model": "sonnet-4-5",
  "tokens": {
    "input": 218326,
    "output": 910583,
    ...
  }
}
```

## 🔧 Integration

### Shell Integration

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Add burnrate to PATH
export PATH="$HOME/.local/bin:$PATH"

# Show budget in prompt
burnrate_prompt() {
    local status=$(burnrate budget --format json 2>/dev/null | grep '"percentage"' | cut -d: -f2)
    if (( status >= 90 )); then echo "❄️ "
    elif (( status >= 75 )); then echo "🧊 "
    elif (( status >= 50 )); then echo "💧 "
    else echo "🔥 "
    fi
}
PS1='$(burnrate_prompt)'"$PS1"

# Daily summary alias
alias burn='burnrate'
alias burntoday='burnrate trends'
```

### Claude Code Hook

Add to `~/.claude/hooks.json`:

```json
{
  "post-message": {
    "command": "burnrate",
    "args": ["budget", "--check"],
    "description": "Check token budget after each message"
  }
}
```

### Cron Job for Daily Reports

```bash
# Add to crontab
0 9 * * * burnrate export full markdown ~/reports/$(date +\%Y-\%m-\%d)-burnrate.md
```

## 🧪 Testing

Burnrate includes a cross-platform test suite:

```bash
# Run platform compatibility tests
./tests/test-platform-simple.sh

# Expected output:
╔═══════════════════════════════════════════════════════╗
║   Burnrate Cross-Platform Compatibility Test         ║
╚═══════════════════════════════════════════════════════╝

System Information:
  OS: darwin25
  Bash: GNU bash, version 3.2.57(1)-release

  ✓ Bash version >= 3.2 ... PASS
  ✓ Required commands ... PASS
  ✓ bc calculator ... PASS
  ✓ Date operations ... PASS
  ✓ JSON parsing ... PASS
  ✓ Burnrate execution ... PASS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Results: 6 passed, 0 failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ System is compatible!
```

## 🐛 Troubleshooting

Having issues? Don't panic! Here's your rescue guide. 🦸

### Stats File Not Found

**Error:** `Stats file not found: ~/.claude/stats-cache.json`

**Why:** Claude Code hasn't been run yet, or it's installed elsewhere

**Fix:**
```bash
# 1. Check if Claude Code is installed
which claude  # Should show path to claude CLI

# 2. Check stats file exists
ls -la ~/.claude/stats-cache.json

# 3. If it's elsewhere, set custom path
export CONFIG_STATS_FILE="/path/to/stats-cache.json"

# 4. Add to your shell profile to make it permanent
echo 'export CONFIG_STATS_FILE="/path/to/stats-cache.json"' >> ~/.bashrc
```

**Still not working?** Run Claude Code at least once to generate the stats file!

### bc Calculator Errors

**Error:** `bc: parse error` or `bc: command not found`

**Why:** bc is not installed (rare) or receiving malformed input

**Fix:**
```bash
# 1. Verify bc is installed
which bc  # Should show /usr/bin/bc or similar

# 2. If not installed:
# macOS: bc comes pre-installed
# Linux: sudo apt-get install bc  (Ubuntu/Debian)
#        sudo yum install bc      (CentOS/RHEL)

# 3. Test bc works
echo "scale=2; 10/3" | bc  # Should output 3.33
```

**Good news:** Burnrate has robust bc error handling. You might see `$0.00` instead of errors!

### Colors Not Showing

**Problem:** Output is plain text, no pretty colors

**Why:** Terminal doesn't support colors, or colors are disabled

**Fix:**
```bash
# Force colors on
burnrate --color always

# Or in config
echo 'CONFIG_COLORS_ENABLED="always"' >> ~/.config/burnrate/burnrate.conf

# Check terminal supports colors
echo -e "\033[31mRed\033[0m"  # Should show "Red" in red

# Or disable colors if you prefer
burnrate --no-color
```

### Emoji Not Displaying

**Problem:** See weird characters instead of emoji

**Why:** Terminal font doesn't support emoji

**Fix:**
```bash
# Disable emoji
burnrate --no-emoji

# Or permanently
echo 'CONFIG_EMOJI_ENABLED="false"' >> ~/.config/burnrate/burnrate.conf

# Or install a font with emoji support:
# - JetBrains Mono
# - Fira Code
# - SF Mono (macOS)
```

### Budget Not Tracking

**Problem:** Budget always shows $0.00 or wrong amount

**Why:** Budget state file is corrupted or missing

**Fix:**
```bash
# 1. Reset budget state
rm ~/.config/burnrate/budget-state.json

# 2. Set your budgets
export CONFIG_DAILY_BUDGET="5.00"
export CONFIG_MONTHLY_BUDGET="150.00"

# 3. Run budget command to reinitialize
burnrate budget
```

### Installation Failed

**Error:** `install.sh: permission denied` or similar

**Fix:**
```bash
# Make install script executable
chmod +x install.sh

# Run it
./install.sh

# If that fails, manual install:
mkdir -p ~/.local/bin
ln -sf "$(pwd)/burnrate" ~/.local/bin/burnrate
export PATH="$HOME/.local/bin:$PATH"
```

### Wrong Costs Displayed

**Problem:** Costs seem way too high or low

**Why:** Model pricing might be outdated, or wrong model detected

**Check:**
```bash
# Show detailed breakdown
burnrate show

# Check your actual model
grep '"model"' ~/.claude/stats-cache.json

# If pricing is wrong, check lib/pricing.sh for latest rates
```

**Report:** If pricing is outdated, please open an issue! We update it regularly.

### 🆘 Still Stuck?

1. **Check the FAQ:** [docs/FAQ.md](docs/FAQ.md) (coming soon!)
2. **Search Issues:** [github.com/yourusername/burnrate/issues](https://github.com/yourusername/burnrate/issues)
3. **Ask for Help:** [GitHub Discussions](https://github.com/yourusername/burnrate/discussions)
4. **Open an Issue:** Include your `burnrate --version` and OS info

### Known Issues

**None yet!** 🎉

We've tested on:
- ✅ macOS 13+ (bash 3.2.57)
- ✅ Ubuntu 20.04+ (bash 5.0+)
- ✅ Debian 11+ (bash 5.1+)

**Untested but should work:**
- 🤔 WSL (Windows Subsystem for Linux)
- 🤔 FreeBSD
- 🤔 Alpine Linux

If you try these, let us know how it goes!

## 🔍 How It Works (For the Curious)

Want to know what's happening under the hood? Here's the magic! ✨

### Data Flow

```
~/.claude/stats-cache.json
         ↓
    [READ JSON]
         ↓
 grep + sed parsing (no jq!)
         ↓
   Calculate costs
         ↓
  Pretty formatting
         ↓
    Your terminal!
```

### Key Implementation Details

**1. Zero Dependencies (Almost!)**
- Pure bash 3.2+ (works on macOS default bash!)
- Only external tool: `bc` for precise cost calculations
- No jq, no Python, no Node.js - just good old bash!

**2. Cross-Platform Date Handling**
```bash
# BSD (macOS)
date -v-7d +%Y-%m-%d

# GNU (Linux)
date -d "7 days ago" +%Y-%m-%d

# We detect and use the right one!
```

**3. JSON Parsing Without jq**
```bash
# Extract model name
model=$(grep '"model"' stats.json | cut -d'"' -f4)

# Extract nested cost value
costs=$(sed -n '/"costs":/,/}/p' stats.json)
total=$(echo "$costs" | grep '"total"' | grep -o '[0-9.]*')
```

**4. Bash 3.2 Compatibility**
- No associative arrays (use case statements for pricing)
- No ${array[@]} syntax that breaks on macOS
- Careful quoting and IFS handling

**5. Safe Math with bc**
```bash
# All numbers sanitized before bc
clean_number() {
    echo "$1" | tr -d '$, '  # Remove $, commas, spaces
}

# Safe bc with error handling
result=$(echo "scale=2; $expr" | bc 2>/dev/null) || echo "0"
```

**6. Historical Data Estimation**
- Daily totals from `dailyModelTokens` array
- Estimate input/output/cache breakdown from cumulative proportions
- Calculate daily costs using estimated breakdowns

**7. Theme System**
```bash
# Themes are just sourced bash files!
THEME_NAME="Glacial"
THEME_ICON="❄️"
THEME_MESSAGE="Every token melts the ice"
THEME_FOOTER="Cache to save the Arctic! 🐻‍❄️"
```

### Why Bash?

**Speed:** No interpreter startup time. Instant execution!

**Portability:** Works everywhere bash exists (macOS, Linux, WSL, servers)

**Simplicity:** 2000 lines of readable bash vs 10,000 lines of framework code

**Zero Tokens:** Bash can't accidentally call Claude API. It's physically impossible!

**Learning:** Great example of what pure bash can do. Inspect the code!

## 🏗️ Architecture

```
burnrate/
├── burnrate              # Main CLI entry point
├── lib/                  # Core libraries
│   ├── core.sh          # Foundation & utilities
│   ├── config.sh        # Configuration management
│   ├── stats.sh         # Stats file parsing
│   ├── pricing.sh       # Multi-model pricing
│   ├── historical.sh    # Historical tracking
│   ├── date-utils.sh    # Cross-platform dates
│   ├── budget.sh        # Budget tracking
│   ├── export.sh        # Export functionality
│   ├── themes.sh        # Theme system
│   ├── animations.sh    # ASCII animations
│   ├── layout.sh        # Responsive layout
│   ├── colors.sh        # Color utilities
│   └── integrations.sh  # Shell integration
├── config/
│   └── themes/          # Built-in themes
├── tests/               # Test suite
└── docs/                # Documentation
```

### Key Design Decisions

- **Pure Bash** - No external dependencies except `bc` (calculator)
- **Bash 3.2+ Compatible** - Works on macOS default bash
- **Zero Tokens** - All operations are local file reads
- **Cross-Platform** - BSD (macOS) and GNU (Linux) date handling
- **No jq Required** - Pure bash JSON parsing

## 📚 Documentation

- [Configuration Guide](docs/CONFIGURATION.md) - All config options
- [Theme Development](docs/THEMES.md) - Create custom themes
- [Integration Guide](docs/INTEGRATIONS.md) - Hooks & automation
- [Implementation Analysis](docs/IMPLEMENTATION_ANALYSIS.md) - CodexBar comparison

## 🤝 Contributing

**We'd love your help!** Burnrate is better with contributions from the community. 🌍

### Ways to Contribute

**🎨 Create Themes**
- Design new environmental metaphors
- Share your unique perspective on token usage
- Make it beautiful!

**🔌 Build Integrations**
- Shell hooks and prompts
- CI/CD pipeline integration
- Notification systems (Slack, Discord, email)

**🧪 Test & Report**
- Try on different platforms (Linux distros, BSD, WSL)
- Report bugs with detailed info
- Suggest improvements

**📚 Improve Documentation**
- Write tutorials
- Create video guides
- Translate to other languages

**✨ Add Features**
- Cost prediction algorithms
- Anomaly detection (unusual spending spikes)
- Real-time monitoring mode
- Web dashboard

### Quick Start for Contributors

```bash
# 1. Fork and clone
git clone https://github.com/yourusername/burnrate
cd burnrate

# 2. Create feature branch
git checkout -b feature/amazing-feature

# 3. Make changes and test
./tests/test-platform-simple.sh
./burnrate show

# 4. Commit with clear messages
git commit -m "Add: Amazing feature that does X"

# 5. Push and create PR
git push origin feature/amazing-feature
```

### Code Style Guide

- **Pure bash 3.2+** - No bashisms that break on macOS
- **Zero external deps** - Except bc (calculator)
- **Comments** - Explain the "why", not the "what"
- **Error handling** - Always handle failures gracefully
- **Testing** - Add tests for new features

### Theme Contribution Template

```bash
# config/themes/yourtheme.theme
THEME_NAME="Your Theme"
THEME_ICON="🎨"
THEME_COLOR="cyan"
THEME_MESSAGE="Your unique message about token usage"
THEME_FOOTER="Inspiring call to action! 🚀"
THEME_WARNING="Alert message for budget limits"
THEME_PROGRESS_CHAR="█"
THEME_EMPTY_CHAR="░"
```

### Recognition

All contributors get:
- ✨ Name in CONTRIBUTORS.md
- 🏆 Credit in release notes
- 💝 Eternal gratitude from the community
- ❄️ A cool burnrate contributor badge (coming soon!)

### Code of Conduct

**Be excellent to each other!** 🤘

- Be respectful and inclusive
- Help others learn
- Give constructive feedback
- Celebrate successes together

We follow the [Contributor Covenant](https://www.contributor-covenant.org/). Harassment won't be tolerated.

## ☕ Support Burnrate

Love burnrate? Help keep the Arctic frozen! ❄️

### Ways to Support

**⭐ Star on GitHub**
- It's free and makes us smile!
- Helps others discover burnrate
- [Give us a star →](https://github.com/yourusername/burnrate)

**💬 Spread the Word**
- Tweet about your savings: "Burnrate helped me save $XXX on Claude costs! ❄️"
- Write a blog post
- Tell your fellow developers

**🐛 Report Issues**
- Found a bug? [Report it!](https://github.com/yourusername/burnrate/issues)
- Have an idea? [Share it!](https://github.com/yourusername/burnrate/discussions)

**🔧 Contribute Code**
- See [Contributing](#-contributing) above
- Every PR makes burnrate better!

**☕ Buy Me a Coffee**

Building burnrate took many ~~tokens~~ hours! If it's saved you money or made your life easier:

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow.svg)](https://buymeacoffee.com/yourusername)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-support-ff5e5b.svg)](https://ko-fi.com/yourusername)
[![GitHub Sponsors](https://img.shields.io/badge/GitHub%20Sponsors-support-ea4aaa.svg)](https://github.com/sponsors/yourusername)

**Every coffee helps:**
- ☕ $3 - One coffee = One new feature
- ☕☕ $10 - Three coffees = One new theme
- ☕☕☕ $25 - A week of coffees = Major feature development

**What your support funds:**
- 🔧 Maintenance and bug fixes
- ✨ New features and improvements
- 📚 Documentation and tutorials
- 🎨 More themes and integrations
- 💡 Community support and help

### Sponsors 🌟

**Thank you to our amazing sponsors!**

<!--
Sponsor tiers:
🧊 Glacier ($100+/mo) - Logo + link on README
❄️ Snowflake ($50+/mo) - Name + link on README
💧 Droplet ($10+/mo) - Name on README
-->

*(Your name here! Be the first sponsor!)*

### Corporate Sponsorship

Using burnrate at your company? Consider sponsoring development!

**Benefits:**
- 🏢 Company logo on README
- 📧 Priority support
- 🎯 Feature requests prioritization
- 📄 Custom integrations

Contact: sponsors@burnrate.dev

## 📊 Roadmap

- [x] Basic usage tracking
- [x] Multi-model support (Opus/Sonnet/Haiku 3/3.5/4/4.5)
- [x] Historical data tracking
- [x] Budget management
- [x] Export functionality (JSON/CSV/Markdown)
- [x] Cross-platform support
- [ ] Cost prediction algorithms
- [ ] Anomaly detection
- [ ] Web dashboard (optional)
- [ ] Real-time monitoring mode

## 📜 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Acknowledgments

- **Claude Code** - For the excellent AI development environment
- **CodexBar** - Inspiration for implementation approaches
- **Community** - For feedback and contributions

## 💡 Philosophy

> "Every token melts the ice. Cache to save the Arctic!" 🐻‍❄️

**Why environmental themes?** Because abstract numbers don't motivate change. But when you see that ice melting with every token? Suddenly you care about caching!

Burnrate makes AI costs **tangible** through environmental metaphors. It's not just about saving money (though that's nice!) — it's about:

- **Visibility:** See where your tokens go
- **Mindfulness:** Be intentional about AI usage
- **Efficiency:** Optimize through caching and smart prompts
- **Sustainability:** Computational resources aren't infinite

**The Burnrate Mission:**
1. Make Claude costs transparent (no surprises!)
2. Promote efficient AI usage (cache everything!)
3. Help developers budget wisely (stay under limits!)
4. Make cost tracking actually fun (themes! animations! ❄️)

---

## 🎊 Join the Community

**Built something cool with burnrate?** Share it!

- 💬 [GitHub Discussions](https://github.com/yourusername/burnrate/discussions) - Share tips, themes, integrations
- 🐛 [Issue Tracker](https://github.com/yourusername/burnrate/issues) - Report bugs, request features
- ⭐ [Star the repo](https://github.com/yourusername/burnrate) - Help others discover burnrate
- 🐦 [Tweet @burnrate](https://twitter.com/burnrate) - Share your savings!

**Theme Showcase:** [Share your custom themes →](https://github.com/yourusername/burnrate/discussions/themes)

**Integration Library:** [Browse community integrations →](https://github.com/yourusername/burnrate/wiki/integrations)

---

## 📝 License

MIT License - see [LICENSE](LICENSE)

**TL;DR:** Do whatever you want with this code! Build on it, sell it, modify it. Just don't blame us if something breaks. 😉

---

## 🙏 Acknowledgments

**Thank you to:**

- **Claude Code Team** - For building an amazing AI development environment
- **CodexBar** - Inspiration for tracking approaches
- **The Bash Community** - For keeping bash alive and awesome
- **Early Adopters** - Your feedback made burnrate better
- **Contributors** - Every PR, issue, and star makes a difference
- **You!** - For reading this far. Seriously, you're awesome! 🎉

---

## 🎯 Quick Links

- 📖 **Documentation:** [docs/](docs/)
- 🔐 **Security:** [SECURITY.md](SECURITY.md)
- 🤝 **Contributing:** [#-contributing](#-contributing)
- 💰 **Pricing:** [lib/pricing.sh](lib/pricing.sh)
- 🎨 **Themes:** [config/themes/](config/themes/)
- ✅ **Tests:** [tests/](tests/)

---

<div align="center">

**Created with ❄️ by the Burnrate Community**

**Remember:** Track tokens. Cache aggressively. Save the Arctic. 🌍

[![Star on GitHub](https://img.shields.io/github/stars/yourusername/burnrate?style=social)](https://github.com/yourusername/burnrate)
[![Follow on Twitter](https://img.shields.io/twitter/follow/burnrate?style=social)](https://twitter.com/burnrate)

**[⬆ Back to Top](#burnrate-)**

Made with 🤍 (and zero tokens!) • [Report Bug](https://github.com/yourusername/burnrate/issues) • [Request Feature](https://github.com/yourusername/burnrate/discussions)

</div>
