# Burnrate 🔥❄️

> Track your Claude token burn. Because API bills shouldn't be surprises.

**⚠️ ZERO TOKENS USED** - Pure bash script. No AI calls. Just reads local stats.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0--alpha-blue)](https://github.com/yourusername/burnrate)
[![Bash](https://img.shields.io/badge/bash-3.2%2B-green)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)](https://github.com/yourusername/burnrate)

## 🌍 What Is This?

Burnrate tracks your [Claude Code](https://claude.com/claude-code) token usage and calculates costs in real-time. With a unique **environmental theme system**, it makes token usage tangible and meaningful - all without using a single token!

**Primary Theme:** 🧊 **GLACIAL** - Every token melts the ice. Cache to save the Arctic!

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
- **💰 Multi-Model Support** - Opus, Sonnet, Haiku (3/3.5/4/4.5)
- **📅 Historical Tracking** - Daily, weekly, monthly breakdowns
- **💳 Budget Management** - Set limits, track spending, get alerts
- **📤 Export Everything** - JSON, CSV, Markdown formats
- **🎨 Beautiful TUI** - 7 themed experiences with ASCII animations
- **🔧 15 Config Options** - Simple, essential customization
- **🖥️ Cross-Platform** - macOS (bash 3.2+) and Linux compatible
- **⚡ Fast & Offline** - No network calls, instant results

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

### Stats File Not Found

```bash
# Check if Claude Code is installed
which claude

# Check stats file location
ls -la ~/.claude/stats-cache.json

# Set custom path
export CONFIG_STATS_FILE="/path/to/stats-cache.json"
```

### bc Calculator Errors

Burnrate handles `bc` errors gracefully with fallbacks. If you see errors:

```bash
# Verify bc is installed
which bc

# Test bc
echo "scale=2; 10/3" | bc
```

### Colors Not Showing

```bash
# Force colors
burnrate --color always

# Or disable colors
burnrate --no-color
```

### Budget Not Tracking

```bash
# Reset budget state
rm ~/.config/burnrate/budget-state.json

# Run budget command to reinitialize
burnrate budget
```

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

Contributions welcome! Areas for contribution:

1. **Themes** - Create new themed experiences
2. **Integrations** - Shell hooks, notifications
3. **Testing** - Test on different platforms
4. **Documentation** - Improve guides and examples
5. **Features** - Cost predictions, anomaly detection

### Development Setup

```bash
git clone https://github.com/yourusername/burnrate
cd burnrate

# Run tests
./tests/test-platform-simple.sh

# Test commands
./burnrate --help
./burnrate show
```

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

Burnrate makes AI costs visible and meaningful through environmental metaphors. By tracking token usage and promoting caching, we help developers build more efficiently while being mindful of computational resources.

---

**Created with ❄️ by the Burnrate community**

**Remember:** Track tokens. Save costs. Preserve the Arctic. 🌍
