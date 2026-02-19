# Burnrate Plugin - Quick Start Guide

Get up and running with the Burnrate Claude plugin in 5 minutes!

## 🚀 Quick Setup

### 1. Install Burnrate CLI (if not already installed)

```bash
# Clone the repo
git clone https://github.com/samridhgupta/burnrate.git
cd burnrate

# Run installer
./install.sh

# Verify it works
burnrate --version
```

### 2. Install Plugin Dependencies

```bash
cd plugin
npm install
npm run build
```

### 3. Configure Claude Desktop

Find your Claude config file:
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

Add this configuration:

```json
{
  "mcpServers": {
    "burnrate": {
      "command": "node",
      "args": ["/absolute/path/to/burnrate/plugin/dist/index.js"]
    }
  }
}
```

**Important**: Replace `/absolute/path/to/burnrate` with your actual path!

### 4. Restart Claude Desktop

Close and reopen Claude Desktop completely.

## ✅ Test It Works

Open Claude and try these commands:

### Basic Test
```
"Check my token usage with burnrate"
```

### Expected Response
Claude should use the `burnrate_summary` tool and show your current usage stats.

## 📝 Example Conversations

### Check Current Costs
**You:** "What's my token cost today?"

**Claude:** *Uses burnrate_summary tool*
```
📊 Token Burn Summary
━━━━━━━━━━━━━━━━━━━━━━

Total Tokens: 592,540,647
Total Cost: $346.79
Cache Efficiency: 92.4%
```

### View History
**You:** "Show me this week's usage"

**Claude:** *Uses burnrate_week tool*
```
📅 This Week's Usage

Tokens:         12,345,678
Cost:           $45.67
```

### Budget Check
**You:** "Am I within my budget?"

**Claude:** *Uses burnrate_budget tool*
```
💰 Budget Status

Daily Budget: $10.00
Today's Spend: $3.45
Remaining: $6.55 ✅
```

### Export Data
**You:** "Export my usage as JSON"

**Claude:** *Uses burnrate_export tool*
```json
{
  "summary": {
    "totalTokens": 592540647,
    "totalCost": 346.79,
    "cacheEfficiency": 0.924
  }
}
```

## 🎯 Common Use Cases

### 1. Morning Check-in
```
"Give me a burnrate summary for yesterday and today"
```

### 2. Weekly Review
```
"Compare my token usage this week vs last week"
```

### 3. Budget Monitoring
```
"Check if I'm on track with my monthly budget"
```

### 4. Optimization Analysis
```
"Show me my cache efficiency trends and suggest optimizations"
```

### 5. Cost Reporting
```
"Export this month's usage data as a markdown report"
```

## 🐛 Troubleshooting

### Issue: Plugin not appearing

**Solution:**
1. Check config file is valid JSON (no trailing commas!)
2. Verify the path is absolute (not relative like `~/burnrate`)
3. Restart Claude Desktop completely (quit, not just close window)

### Issue: "burnrate: command not found"

**Solution:**
```bash
# Check if burnrate is in PATH
which burnrate

# If not found, add to your shell config:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Issue: Permission denied

**Solution:**
```bash
# Make burnrate executable
chmod +x ~/.local/bin/burnrate

# Check the symlink
ls -l ~/.local/bin/burnrate
```

### Issue: Stats file not found

**Solution:**
```bash
# Verify stats file exists
ls -l ~/.claude/stats-cache.json

# If not found, use Claude Code once to generate it
```

## 🔍 Testing the MCP Server Directly

You can test the MCP server manually:

```bash
cd plugin

# Start the server (it listens on stdio)
node dist/index.js

# In another terminal, send a test request
echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | node dist/index.js
```

## 📊 Verify Everything Works

Run this checklist:

```bash
# 1. CLI works
burnrate --version
# Expected: burnrate version 0.1.0

# 2. Stats file exists
ls -l ~/.claude/stats-cache.json
# Expected: file exists with read permissions

# 3. Plugin builds
cd plugin && npm run build
# Expected: dist/ folder created

# 4. Node version
node --version
# Expected: v18.0.0 or higher

# 5. Config is valid
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | jq
# Expected: valid JSON output
```

## 🎉 You're All Set!

Now you can track token costs right from Claude conversations. The plugin uses zero tokens and works completely offline.

## 💡 Pro Tips

1. **Set up budgets first**: Run `burnrate setup` to configure budgets
2. **Check costs daily**: Make it a habit to ask Claude for daily summaries
3. **Use trends**: Ask for trends to identify usage patterns
4. **Export regularly**: Export data monthly for long-term tracking
5. **Monitor cache**: High cache efficiency = lower costs!

## 📚 Learn More

- [Plugin Documentation](README.md)
- [Main Burnrate Docs](../README.md)
- [MCP Protocol](https://modelcontextprotocol.io/)

---

Need help? [Open an issue](https://github.com/samridhgupta/burnrate/issues)
