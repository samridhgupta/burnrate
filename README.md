# Burnrate 🔥

> Track your Claude token burn. Because API bills shouldn't be surprises.

**⚠️ ZERO TOKENS USED** - Pure bash script. No AI calls. Just reads local stats.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-0.1.0--alpha-blue)](https://github.com/yourusername/burnrate)

## 🌍 What Is This?

Burnrate tracks your Claude Code API usage and calculates costs in real-time. With a unique **environmental theme system**, it makes token usage tangible and meaningful.

**Primary Theme:** 🧊 **GLACIAL** - Every token melts the ice. Cache to save the Arctic!

```
❄️  GLACIAL REPORT ━━━━━━━━━━━━━━━━━━━━━━━━
   🌍 Token Impact on the Arctic 🌍

   Ice Status:  ████████▓░ 85% Frozen
   Polar Bear:  🐻‍❄️  (Stable habitat)

   💰 Carbon Cost:  $346.79
   🌡️  Efficiency:   92.4% ⭐⭐⭐

   ✨ You saved the Arctic today by caching! ✨
```

## 🚀 Quick Start

```bash
# Clone and install
git clone https://github.com/yourusername/burnrate
cd burnrate
./install.sh

# Check your burn
burnrate summary    # Overall stats
burnrate today      # Today's costs
burnrate cache      # Cache efficiency
```

## ✨ Features

- 🧊 **7 Themed Experiences** - Glacial, Ember, Battery, Hourglass, Garden, Ocean, Space
- 💰 **Multi-Model Support** - Opus, Sonnet, Haiku cost tracking
- 📊 **Budget Tracking** - Set limits, get alerts before overspending
- 🎨 **32+ ASCII Animations** - Beautiful, configurable visual feedback
- 📤 **Export Everything** - CSV, JSON, Markdown reports
- 🔔 **Smart Notifications** - Desktop, email, Slack, Discord, webhooks
- ⚙️  **50+ Config Options** - Customize everything
- 🤖 **Agent-Friendly** - JSON output, composable utilities

## 🎨 Themes

| Theme | Icon | Metaphor | Vibe |
|-------|------|----------|------|
| **Glacial** | ❄️ | Ice melting | Environmental |
| **Ember** | 🔥 | Fire burning | Intense |
| **Battery** | 🔋 | Energy drain | Tech |
| **Hourglass** | ⏳ | Time flowing | Philosophical |
| **Garden** | 🌱 | Plant growth | Nurturing |
| **Ocean** | 🌊 | Water level | Conservation |
| **Space** | 🚀 | Fuel gauge | Sci-fi |

## 📋 Commands

```bash
burnrate summary        # Overall usage and costs
burnrate today          # Today's burn rate
burnrate week           # This week's costs
burnrate month          # This month's costs
burnrate cache          # Cache efficiency
burnrate budget         # Budget status
burnrate export csv     # Export data
burnrate config         # Show configuration
burnrate theme glacial  # Switch theme
```

## 🛠️ Installation

### One-Line Install (Coming Soon)

```bash
curl -sSL https://burnrate.sh/install | bash
```

### Manual Install

```bash
# Clone repository
git clone https://github.com/yourusername/burnrate
cd burnrate

# Run installer
./install.sh

# Or manual copy
cp bin/burnrate ~/.local/bin/
chmod +x ~/.local/bin/burnrate
```

## ⚙️  Configuration

Burnrate is highly configurable with 50+ options:

```bash
# Config file locations (priority order):
# 1. ~/.config/burnrate/burnrate.conf
# 2. ~/.burnrate.conf
# 3. Built-in defaults

# Run setup wizard
burnrate setup

# Edit config
vi ~/.config/burnrate/burnrate.conf
```

See [CONFIGURATION.md](docs/CONFIGURATION.md) for all options.

## 🤖 For AI Agents

Burnrate is designed to be agent-friendly:

```bash
# JSON output
burnrate summary --json

# Scriptable
COST=$(burnrate today --json | jq -r '.cost')

# Exit codes
burnrate budget --check  # Exit 0 if under budget, 1 if over
```

## 📚 Documentation

- [Configuration Guide](docs/CONFIGURATION.md) - All 50+ config options
- [Theme Guide](docs/THEMES.md) - Create custom themes
- [Integration Guide](docs/INTEGRATIONS.md) - Webhooks, notifications
- [Development Guide](docs/DEVELOPMENT.md) - Contributing
- [Examples](docs/EXAMPLES.md) - Real-world usage

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md)

### Development Setup

```bash
git clone https://github.com/yourusername/burnrate
cd burnrate
./tests/run_tests.sh
```

## 📜 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Credits

Created with ❄️ by the Burnrate community.

**Special thanks:** Inspired by the need to make AI costs transparent and environmental impact visible.

---

**Remember:** Every token melts the ice. Cache to save the Arctic! 🐻‍❄️
