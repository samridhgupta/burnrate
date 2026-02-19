#!/usr/bin/env bash
# Burnrate Plugin - Interactive Setup Script

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR"
BURNRATE_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════╗"
echo "║  Burnrate Plugin Setup  🔥❄️               ║"
echo "╔════════════════════════════════════════════╗"
echo -e "${NC}"
echo ""

# Step 1: Check prerequisites
echo -e "${BLUE}Step 1: Checking Prerequisites${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}✗ Node.js not found${NC}"
    echo "  Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}✗ Node.js version too old (need 18+)${NC}"
    echo "  Found: $(node --version)"
    exit 1
fi
echo -e "${GREEN}✓ Node.js ${NC}$(node --version)"

# Check npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗ npm not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ npm ${NC}$(npm --version)"

# Check burnrate CLI
if ! command -v burnrate &> /dev/null; then
    echo -e "${YELLOW}⚠ burnrate CLI not found${NC}"
    echo ""
    echo "The CLI needs to be installed first. Options:"
    echo ""
    echo "1. Quick install (recommended):"
    echo "   cd $BURNRATE_DIR && ./install.sh"
    echo ""
    echo "2. Manual install:"
    echo "   - Copy burnrate to ~/.local/bin/"
    echo "   - Make it executable: chmod +x ~/.local/bin/burnrate"
    echo "   - Add to PATH: export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    read -p "Install burnrate CLI now? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$BURNRATE_DIR"
        if [ -f "./install.sh" ]; then
            ./install.sh
        else
            echo -e "${RED}install.sh not found${NC}"
            exit 1
        fi
    else
        echo "Please install burnrate CLI first, then run this script again."
        exit 1
    fi
fi
echo -e "${GREEN}✓ burnrate CLI ${NC}$(burnrate version 2>/dev/null | head -1 || echo 'installed')"

# Check stats file
if [ ! -f ~/.claude/stats-cache.json ]; then
    echo -e "${YELLOW}⚠ Stats file not found${NC}"
    echo "  ~/.claude/stats-cache.json doesn't exist"
    echo "  This file is created by Claude Code when you use it"
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓ Stats file exists${NC}"
fi

echo ""

# Step 2: Install dependencies
echo -e "${BLUE}Step 2: Installing Dependencies${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$PLUGIN_DIR"

if [ -f "package-lock.json" ]; then
    rm package-lock.json
fi

echo "Running npm install..."
npm install

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 3: Build plugin
echo -e "${BLUE}Step 3: Building Plugin${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Running npm run build..."
npm run build

if [ ! -f "dist/index.js" ]; then
    echo -e "${RED}✗ Build failed - dist/index.js not created${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Plugin built successfully${NC}"
echo ""

# Step 4: Test plugin
echo -e "${BLUE}Step 4: Testing Plugin${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Running tests..."
if [ -f "test-plugin.sh" ]; then
    bash test-plugin.sh
else
    echo -e "${YELLOW}⚠ Test script not found, skipping tests${NC}"
fi

echo ""

# Step 5: Configure Claude Desktop
echo -e "${BLUE}Step 5: Claude Desktop Configuration${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect OS and config path
if [[ "$OSTYPE" == "darwin"* ]]; then
    CONFIG_PATH="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CONFIG_PATH="$HOME/.config/Claude/claude_desktop_config.json"
else
    CONFIG_PATH="$HOME/.config/Claude/claude_desktop_config.json"
fi

echo "Config file: $CONFIG_PATH"
echo ""

# Create config directory if it doesn't exist
CONFIG_DIR=$(dirname "$CONFIG_PATH")
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Creating config directory..."
    mkdir -p "$CONFIG_DIR"
fi

# Generate config snippet
PLUGIN_PATH="$PLUGIN_DIR/dist/index.js"

cat > /tmp/burnrate-mcp-config.json <<EOF
{
  "mcpServers": {
    "burnrate": {
      "command": "node",
      "args": ["$PLUGIN_PATH"],
      "env": {
        "BURNRATE_PATH": "burnrate"
      }
    }
  }
}
EOF

echo "Configuration snippet saved to: /tmp/burnrate-mcp-config.json"
echo ""
echo "You need to add this to your Claude Desktop config:"
echo ""
cat /tmp/burnrate-mcp-config.json
echo ""

# Check if config file exists
if [ -f "$CONFIG_PATH" ]; then
    echo -e "${YELLOW}⚠ Config file already exists${NC}"
    echo "Please manually merge the configuration above into:"
    echo "  $CONFIG_PATH"
else
    echo "Creating new config file..."
    cp /tmp/burnrate-mcp-config.json "$CONFIG_PATH"
    echo -e "${GREEN}✓ Config file created${NC}"
fi

echo ""

# Step 6: Final instructions
echo -e "${BLUE}Step 6: Next Steps${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. ${GREEN}Restart Claude Desktop${NC}"
echo "   - Completely quit Claude (not just close window)"
echo "   - Reopen Claude Desktop"
echo ""
echo "2. ${GREEN}Test the plugin${NC}"
echo "   Open Claude and try:"
echo "   \"Check my token usage with burnrate\""
echo ""
echo "3. ${GREEN}Verify it works${NC}"
echo "   Claude should use the burnrate_summary tool"
echo "   and show your current usage stats"
echo ""
echo "4. ${GREEN}Explore features${NC}"
echo "   Try these commands:"
echo "   - \"Show me this week's token usage\""
echo "   - \"Am I within my budget?\""
echo "   - \"Export my usage as JSON\""
echo ""

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════╗"
echo "║  Setup Complete! 🎉                       ║"
echo "╔════════════════════════════════════════════╗"
echo -e "${NC}"
echo ""
echo "📚 Documentation:"
echo "   - Quick Start: $PLUGIN_DIR/QUICKSTART.md"
echo "   - Full Docs:   $PLUGIN_DIR/README.md"
echo "   - Publishing:  $PLUGIN_DIR/PUBLISHING.md"
echo ""
echo "🐛 Troubleshooting:"
echo "   - Check logs: Claude → Settings → Advanced → View Logs"
echo "   - Test CLI:   burnrate --version"
echo "   - Test MCP:   node $PLUGIN_PATH"
echo ""
echo "💬 Need help?"
echo "   https://github.com/yourusername/burnrate/issues"
echo ""

# Cleanup
rm -f /tmp/burnrate-mcp-config.json

echo "Happy tracking! 🔥❄️"
