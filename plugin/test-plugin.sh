#!/usr/bin/env bash
# Test script for burnrate MCP plugin

set -euo pipefail

echo "🧪 Testing Burnrate MCP Plugin"
echo "==============================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
test_step() {
    local name="$1"
    local command="$2"

    echo -n "Testing: $name... "

    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "Prerequisites"
echo "-------------"

# Check Node.js
test_step "Node.js version" "node --version | grep -E 'v1[8-9]|v[2-9][0-9]'"

# Check burnrate CLI
test_step "burnrate CLI installed" "command -v burnrate"

# Check stats file
test_step "Stats file exists" "[ -f ~/.claude/stats-cache.json ]"

echo ""
echo "Build"
echo "-----"

# Build plugin
test_step "TypeScript compilation" "cd plugin && npm run build"

# Check dist folder
test_step "Distribution files created" "[ -f plugin/dist/index.js ]"

echo ""
echo "Plugin Structure"
echo "----------------"

# Check required files
test_step "package.json exists" "[ -f plugin/package.json ]"
test_step "tsconfig.json exists" "[ -f plugin/tsconfig.json ]"
test_step "claude-plugin.json exists" "[ -f plugin/claude-plugin.json ]"
test_step "README.md exists" "[ -f plugin/README.md ]"

echo ""
echo "MCP Server"
echo "----------"

# Test server starts (timeout after 2 seconds)
echo -n "Testing: Server starts... "
if timeout 2s node plugin/dist/index.js >/dev/null 2>&1 || [ $? -eq 124 ]; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    ((TESTS_FAILED++))
fi

# Test MCP protocol (list tools)
echo -n "Testing: MCP tools/list request... "
RESPONSE=$(echo '{"jsonrpc":"2.0","method":"tools/list","id":1}' | timeout 2s node plugin/dist/index.js 2>/dev/null | head -1 || true)
if echo "$RESPONSE" | grep -q '"tools"'; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "  Response: $RESPONSE"
    ((TESTS_FAILED++))
fi

# Test MCP protocol (list resources)
echo -n "Testing: MCP resources/list request... "
RESPONSE=$(echo '{"jsonrpc":"2.0","method":"resources/list","id":1}' | timeout 2s node plugin/dist/index.js 2>/dev/null | head -1 || true)
if echo "$RESPONSE" | grep -q '"resources"'; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗ FAIL${NC}"
    echo "  Response: $RESPONSE"
    ((TESTS_FAILED++))
fi

echo ""
echo "Metadata Validation"
echo "-------------------"

# Check claude-plugin.json structure
test_step "Plugin name defined" "grep -q '\"name\".*burnrate' plugin/claude-plugin.json"
test_step "Plugin version defined" "grep -q '\"version\"' plugin/claude-plugin.json"
test_step "MCP server config defined" "grep -q '\"mcp_server\"' plugin/claude-plugin.json"

echo ""
echo "Documentation"
echo "-------------"

test_step "README has installation" "grep -q 'Installation' plugin/README.md"
test_step "QUICKSTART exists" "[ -f plugin/QUICKSTART.md ]"
test_step "PUBLISHING guide exists" "[ -f plugin/PUBLISHING.md ]"

echo ""
echo "==============================="
echo "Results:"
echo -e "  ${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed: $TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Install plugin in Claude Desktop (see plugin/QUICKSTART.md)"
    echo "2. Test in Claude conversations"
    echo "3. Submit to marketplace (see plugin/PUBLISHING.md)"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please fix issues before publishing.${NC}"
    exit 1
fi
