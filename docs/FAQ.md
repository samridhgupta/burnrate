# Frequently Asked Questions (FAQ) 🤔

## General Questions

### What is burnrate?

Burnrate is a pure bash CLI tool that tracks your Claude Code token usage and costs. It reads from your local stats file and calculates costs without using any tokens!

### Does burnrate use tokens or make API calls?

**NO!** Burnrate never makes API calls and uses **zero tokens**. It only reads your local `~/.claude/stats-cache.json` file.

### Is burnrate safe to use?

Yes! Burnrate is:
- ✅ Read-only (except its own config files)
- ✅ No network requests
- ✅ No external dependencies (except bc)
- ✅ Open source and auditable
- ✅ Security audited - see [SECURITY.md](../SECURITY.md)

### What permissions does burnrate need?

- **Read:** `~/.claude/stats-cache.json` (Claude's stats)
- **Write:** `~/.config/burnrate/` (burnrate's config)
- **No:** Network, root, Claude API keys, other files

### Is burnrate free?

Yes! MIT licensed and free forever. But if you love it, consider [supporting development](../README.md#-support-burnrate)! ☕

## Installation & Setup

### Where should I install burnrate?

The installer creates a symlink at `~/.local/bin/burnrate`. Make sure `~/.local/bin` is in your PATH.

### Do I need to install anything else?

Just `bc` (calculator). It's pre-installed on macOS and most Linux systems.

### Can I install without the install script?

Yes! Just create a symlink:
```bash
ln -sf /path/to/burnrate/burnrate ~/.local/bin/burnrate
```

### How do I uninstall?

```bash
rm ~/.local/bin/burnrate
rm -rf ~/.config/burnrate/
```

## Usage Questions

### How do I check my current costs?

```bash
burnrate          # Quick summary
burnrate show     # Detailed breakdown
```

### How do I set budgets?

```bash
# Via environment
export CONFIG_DAILY_BUDGET="5.00"
export CONFIG_MONTHLY_BUDGET="150.00"

# Or in ~/.config/burnrate/burnrate.conf
CONFIG_DAILY_BUDGET="5.00"
CONFIG_MONTHLY_BUDGET="150.00"
```

### How do I export data?

```bash
burnrate export summary json
burnrate export history csv report.csv
burnrate export full markdown full-report.md
```

### Can I change themes?

Yes! Seven built-in themes:
```bash
burnrate themes              # List themes
burnrate preview glacial     # Preview a theme
burnrate --theme ember       # Use a theme
```

### How do I create custom themes?

Copy an existing theme and customize:
```bash
cp config/themes/glacial.theme ~/.config/burnrate/themes/mytheme.theme
vi ~/.config/burnrate/themes/mytheme.theme
burnrate --theme mytheme
```

## Technical Questions

### What bash version do I need?

Bash 3.2+ (works on macOS default bash!)

### Does it work on macOS?

Yes! Tested on macOS 13+ with default bash 3.2.57.

### Does it work on Linux?

Yes! Tested on Ubuntu 20.04+ and Debian 11+.

### Does it work on Windows?

Should work in WSL (Windows Subsystem for Linux). Not tested natively on Windows.

### Why bash instead of Python/Node?

- ⚡ Instant execution (no interpreter startup)
- 🔧 Works everywhere bash exists
- 📦 Zero dependencies (except bc)
- 🔒 Can't accidentally make API calls
- 🎓 Great example of pure bash capabilities

### How does burnrate parse JSON without jq?

Using grep, sed, and cut! Pure bash text processing. See [implementation details](../README.md#-how-it-works-for-the-curious).

### How accurate are the costs?

Very accurate! We use official Anthropic pricing and precise bc calculations.

### Where does burnrate get pricing data?

Hardcoded in `lib/pricing.sh`, updated manually when API prices change.

### Can I use burnrate offline?

Yes! Burnrate is 100% offline. No network required.

## Troubleshooting

### Stats file not found?

Run Claude Code at least once to generate the stats file. Or set custom path:
```bash
export CONFIG_STATS_FILE="/path/to/stats-cache.json"
```

### Colors not showing?

Enable colors:
```bash
burnrate --color always
```

Or check your terminal supports colors.

### Emoji showing as weird characters?

Disable emoji:
```bash
burnrate --no-emoji
```

Or install a font with emoji support (JetBrains Mono, Fira Code).

### Budget always shows $0?

Reset budget state:
```bash
rm ~/.config/burnrate/budget-state.json
burnrate budget
```

## Contributing

### How can I contribute?

See [Contributing Guide](../README.md#-contributing). We welcome:
- 🎨 Theme creation
- 🔌 Integrations
- 🐛 Bug reports
- 📚 Documentation
- ✨ Features

### Where do I report bugs?

[GitHub Issues](https://github.com/yourusername/burnrate/issues)

### Can I request features?

Yes! Use [GitHub Discussions](https://github.com/yourusername/burnrate/discussions).

### How do I submit a theme?

Create a PR with your theme file in `config/themes/`. Include a screenshot!

## Support

### How do I get help?

1. Check this FAQ
2. Search [GitHub Issues](https://github.com/yourusername/burnrate/issues)
3. Ask in [GitHub Discussions](https://github.com/yourusername/burnrate/discussions)
4. Open a new issue with details

### Can I hire you for custom development?

Contact: dev@burnrate.dev (if available)

### How do I support the project?

- ⭐ Star the repo
- ☕ [Buy me a coffee](../README.md#-support-burnrate)
- 💬 Share with others
- 🔧 Contribute code

---

**Didn't find your answer?**

Ask in [GitHub Discussions](https://github.com/yourusername/burnrate/discussions) - we're happy to help!

**Found an error in this FAQ?**

Submit a PR or [open an issue](https://github.com/yourusername/burnrate/issues). Thanks!

---

🧊 **Remember: Every token melts the ice. Cache to save the Arctic!** 🐻‍❄️
