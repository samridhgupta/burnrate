# Publishing Burnrate Plugin to Claude Marketplace

Step-by-step guide to submit the burnrate plugin to the Claude plugin marketplace.

## 📋 Pre-Publishing Checklist

### Code Quality
- [ ] TypeScript compiles without errors: `npm run build`
- [ ] All MCP tools are working correctly
- [ ] Resources are properly exposed
- [ ] Error handling is robust
- [ ] No console.log statements (use console.error for debugging)

### Documentation
- [ ] README.md is complete and accurate
- [ ] QUICKSTART.md provides clear setup instructions
- [ ] All example commands work as documented
- [ ] Troubleshooting section covers common issues
- [ ] License information is clear (MIT)

### Metadata
- [ ] `claude-plugin.json` has all required fields
- [ ] Version number follows semver (0.1.0)
- [ ] Description is clear and compelling
- [ ] Keywords are relevant for discovery
- [ ] Categories are appropriate
- [ ] Icon/emoji is set (🔥❄️)

### Testing
- [ ] Tested on macOS
- [ ] Tested on Linux (if applicable)
- [ ] Tested with Claude Desktop
- [ ] All tools execute without errors
- [ ] Resources are readable
- [ ] Export functions work correctly

### Security
- [ ] No API keys or secrets in code
- [ ] Only reads allowed files (~/.claude/stats-cache.json)
- [ ] No network requests
- [ ] Follows least privilege principle
- [ ] Permissions are clearly documented

## 🚀 Publishing Steps

### 1. Prepare the Package

```bash
cd plugin

# Clean and rebuild
rm -rf dist node_modules
npm install
npm run build

# Test the build
node dist/index.js
```

### 2. Create Package for Distribution

```bash
# Create a distribution tarball
npm pack

# This creates: burnrate-claude-plugin-0.1.0.tgz
```

### 3. Update Repository

```bash
# Tag the release
git tag -a plugin-v0.1.0 -m "Burnrate Plugin v0.1.0"
git push origin plugin-v0.1.0

# Ensure main branch is up to date
git push origin main
```

### 4. Create GitHub Release

1. Go to: https://github.com/samridhgupta/burnrate/releases/new
2. Select tag: `plugin-v0.1.0`
3. Title: "Burnrate Plugin v0.1.0"
4. Description:
```markdown
# Burnrate Claude Plugin v0.1.0

Track Claude Code token costs directly from Claude - with zero API calls!

## 🎉 First Release

This is the initial release of the Burnrate Claude plugin.

## ✨ Features

- 🔥 Track token usage and costs in real-time
- 💰 Budget management with alerts
- 📊 Historical analysis and trends
- 📈 Cache efficiency monitoring
- 📦 Export data (JSON/CSV/Markdown)
- ⚡ Zero token usage - completely offline

## 📦 Installation

See [Plugin README](https://github.com/samridhgupta/burnrate/tree/main/plugin#installation) for installation instructions.

## 🔗 Links

- [Quick Start Guide](https://github.com/samridhgupta/burnrate/blob/main/plugin/QUICKSTART.md)
- [Full Documentation](https://github.com/samridhgupta/burnrate/blob/main/plugin/README.md)
- [Main Burnrate CLI](https://github.com/samridhgupta/burnrate)
```

5. Attach files:
   - Upload `burnrate-claude-plugin-0.1.0.tgz`
   - Upload `claude-plugin.json`

### 5. Submit to Claude Plugin Marketplace

**Note**: The exact submission process depends on Anthropic's marketplace requirements. Generally:

1. **Visit the Claude Plugin Submission Portal**
   - URL: https://claude.com/plugins/submit (hypothetical - check actual URL)
   - Sign in with your Anthropic account

2. **Fill out the Submission Form**
   - Plugin Name: `burnrate`
   - Display Name: `Burnrate - Token Cost Tracker`
   - Category: Productivity, Development, Analytics
   - Short Description: "Track Claude Code token costs with zero API calls"
   - Long Description: (Copy from claude-plugin.json)
   - Repository URL: https://github.com/samridhgupta/burnrate
   - License: MIT
   - Homepage: https://github.com/samridhgupta/burnrate/tree/main/plugin

3. **Upload Required Files**
   - `claude-plugin.json` (metadata)
   - `package.json`
   - Package tarball: `burnrate-claude-plugin-0.1.0.tgz`
   - Screenshots (if required)
   - Icon/logo (if required)

4. **Verification Information**
   - Contact email
   - GitHub account
   - Support URL: https://github.com/samridhgupta/burnrate/issues

5. **Technical Review Checklist**
   - [ ] MCP protocol compliance
   - [ ] Security review (no malicious code)
   - [ ] Privacy compliance (no data collection)
   - [ ] Performance testing
   - [ ] Documentation quality

### 6. Prepare for Review

**Create a Review Guide** for the Anthropic team:

```markdown
# Review Guide for Burnrate Plugin

## Testing Instructions

1. Install burnrate CLI:
   ```bash
   git clone https://github.com/samridhgupta/burnrate.git
   cd burnrate && ./install.sh
   ```

2. Install plugin:
   ```bash
   cd plugin && npm install && npm run build
   ```

3. Configure Claude Desktop:
   ```json
   {
     "mcpServers": {
       "burnrate": {
         "command": "node",
         "args": ["/path/to/burnrate/plugin/dist/index.js"]
       }
     }
   }
   ```

4. Test commands in Claude:
   - "Check my token usage with burnrate"
   - "Show me this week's usage"
   - "Export my usage as JSON"

## Security Notes

- Zero network requests (can be verified with network monitoring)
- Only reads ~/.claude/stats-cache.json
- Only writes to ~/.config/burnrate/
- No external dependencies with security concerns
- Open source - all code is auditable

## Performance

- Typical response time: <100ms
- Zero token usage
- Minimal memory footprint
- No background processes

## Privacy

- No telemetry or analytics
- No data sent to external services
- All processing is local
- No PII collected or stored
```

### 7. Post-Submission

1. **Monitor Submission Status**
   - Check email for updates
   - Respond to any review feedback promptly
   - Address any requested changes

2. **Prepare Announcement**
   - Blog post or Twitter thread
   - Post on relevant communities (Reddit, HackerNews, etc.)
   - Update main burnrate README with plugin info

3. **Setup Support Channels**
   - Monitor GitHub issues
   - Create discussions section
   - Consider Discord/Slack community

## 📝 Marketplace Requirements

### Required Metadata

- ✅ Name and display name
- ✅ Version (semver)
- ✅ Description (short and long)
- ✅ Author information
- ✅ License (MIT)
- ✅ Repository URL
- ✅ Categories and keywords
- ✅ MCP server configuration
- ✅ Permissions list

### Optional but Recommended

- Screenshots demonstrating functionality
- Demo video (1-2 minutes)
- Icon/logo (high resolution)
- Detailed feature list
- Comparison with alternatives
- Use case examples

### Documentation Requirements

- Installation guide
- Quick start tutorial
- API/tool reference
- Troubleshooting guide
- Security and privacy policy
- Support contact information

## 🎯 Marketing Tips

1. **Unique Value Proposition**
   - Emphasize "zero tokens used"
   - Highlight offline/privacy benefits
   - Focus on cost savings

2. **Target Audience**
   - Developers using Claude Code
   - Teams managing AI budgets
   - Power users optimizing costs

3. **Social Proof**
   - Share usage statistics
   - Collect user testimonials
   - Showcase real savings

4. **Content Strategy**
   - Tutorial videos
   - Blog posts about cost optimization
   - Case studies

## 🔄 Version Updates

For future releases:

```bash
# 1. Update version in package.json and claude-plugin.json
npm version patch  # or minor, or major

# 2. Build and test
npm run build

# 3. Tag and push
git tag -a plugin-v0.1.1 -m "Bug fixes"
git push origin plugin-v0.1.1

# 4. Create release on GitHub

# 5. Submit update to marketplace
```

## 📞 Support

If you need help with the submission process:

- Anthropic Support: support@anthropic.com
- Claude Plugin Docs: https://docs.anthropic.com/plugins
- Community Forum: https://community.anthropic.com

---

**Good luck with your submission! 🚀**
