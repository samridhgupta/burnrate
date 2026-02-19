# Burnrate Claude Plugin 🔥❄️

> Track Claude Code token costs directly from Claude - with zero API calls!

This plugin exposes [burnrate](https://github.com/samridhgupta/burnrate) functionality as MCP tools, allowing Claude to help you monitor and optimize your token usage.

## ⚠️ Zero Tokens Used

This plugin reads local stats only - no API calls, no token usage. It's completely offline!

## 📦 Installation

### Prerequisites

1. **Install the burnrate CLI first:**
   ```bash
   git clone https://github.com/samridhgupta/burnrate.git
   cd burnrate
   ./install.sh
   ```

2. **Verify installation:**
   ```bash
   burnrate --version
   ```

### Install the Plugin

#### Via Claude Plugin Marketplace (Recommended)

1. Open Claude Desktop
2. Go to Settings → Plugins
3. Search for "burnrate"
4. Click "Install"

#### Manual Installation

1. **Navigate to the plugin directory:**
   ```bash
   cd /path/to/burnrate/plugin
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Build the plugin:**
   ```bash
   npm run build
   ```

4. **Add to Claude config:**

   Edit your Claude MCP settings file:
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Linux**: `~/.config/Claude/claude_desktop_config.json`
   - **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

   Add the burnrate server:
   ```json
   {
     "mcpServers": {
       "burnrate": {
         "command": "node",
         "args": ["/absolute/path/to/burnrate/plugin/dist/index.js"],
         "env": {
           "BURNRATE_PATH": "burnrate"
         }
       }
     }
   }
   ```

5. **Restart Claude Desktop**

## 🚀 Usage

Once installed, you can ask Claude to use burnrate commands:

### Get Current Usage Summary
```
"Show me my current token usage"
"What's my Claude cost today?"
"Check my cache efficiency"
```

### View Historical Data
```
"Show me this week's token usage"
"What did I spend on tokens this month?"
"Show my daily usage history"
```

### Budget Management
```
"Check my budget status"
"Am I within my token budget?"
"Show budget alerts"
```

### Export Data
```
"Export my usage data as JSON"
"Give me a CSV of my token history"
"Export summary as markdown"
```

### Analyze Trends
```
"Show spending trends"
"How has my usage changed over time?"
"What are my usage patterns?"
```

## 🛠️ Available Tools

The plugin exposes these MCP tools:

| Tool | Description |
|------|-------------|
| `burnrate_summary` | Current usage summary with costs |
| `burnrate_show` | Detailed breakdown by token type |
| `burnrate_history` | Daily usage history |
| `burnrate_week` | This week's aggregate |
| `burnrate_month` | This month's aggregate |
| `burnrate_trends` | Spending trends and patterns |
| `burnrate_budget` | Budget status and alerts |
| `burnrate_export` | Export data (JSON/CSV/Markdown) |
| `burnrate_config` | Current configuration |

## 📊 Available Resources

The plugin also provides these MCP resources:

| Resource | Description |
|----------|-------------|
| `burnrate://summary` | Current usage summary |
| `burnrate://history` | Daily usage history |
| `burnrate://budget` | Budget status |
| `burnrate://config` | Configuration settings |
| `burnrate://export/summary.json` | JSON export of summary |
| `burnrate://export/history.json` | JSON export of history |

## 🔒 Permissions

This plugin requires:

**Read Access:**
- `~/.claude/stats-cache.json` - Your Claude token stats
- `~/.config/burnrate/` - Burnrate config files

**Write Access:**
- `~/.config/burnrate/` - For config updates

**Network:** None! Completely offline.

## 🐛 Troubleshooting

### "burnrate: command not found"

The CLI isn't in your PATH. Either:

1. **Add burnrate to PATH:**
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

2. **Set full path in config:**
   ```json
   {
     "env": {
       "BURNRATE_PATH": "/absolute/path/to/burnrate"
     }
   }
   ```

### Plugin not showing up in Claude

1. Verify the config file syntax (valid JSON)
2. Restart Claude Desktop completely
3. Check Claude logs for errors
4. Ensure Node.js 18+ is installed: `node --version`

### "Failed to execute burnrate"

1. Test CLI directly: `burnrate --version`
2. Check file permissions: `ls -l ~/.local/bin/burnrate`
3. Verify stats file exists: `ls -l ~/.claude/stats-cache.json`

## 🤝 Contributing

Contributions welcome! See the [main burnrate repo](https://github.com/samridhgupta/burnrate) for guidelines.

## 📜 License

MIT - See [LICENSE](../LICENSE) for details

## 🔗 Links

- [Main Burnrate Repo](https://github.com/samridhgupta/burnrate)
- [Documentation](https://github.com/samridhgupta/burnrate#readme)
- [Issues](https://github.com/samridhgupta/burnrate/issues)
- [Claude Plugin Marketplace](https://claude.com/plugins)

## 🎯 Why Use This Plugin?

- **Zero Token Cost**: Unlike other monitoring tools, this uses zero tokens
- **Real-time**: Instant cost tracking without delays
- **Offline**: No network requests, complete privacy
- **Powerful**: Full access to burnrate's features
- **Integrated**: Works seamlessly within Claude conversations
- **Open Source**: Transparent, auditable, community-driven

---

**Made with ❄️ by the Burnrate community**
