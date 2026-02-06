#!/usr/bin/env bash
# Simple cross-platform compatibility test
# Standalone script that doesn't require sourcing libraries

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║   Burnrate Cross-Platform Compatibility Test         ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# System Info
echo "System Information:"
echo "  OS: $OSTYPE"
echo "  Bash: $(bash --version | head -1)"
echo ""

# Tests
PASSED=0
FAILED=0

# Test 1: Bash version
echo -n "  ✓ Bash version >= 3.2 ... "
bash_version=$(bash --version | head -1 | grep -o '[0-9]\.[0-9]\.[0-9]*' | head -1)
bash_major=$(echo "$bash_version" | cut -d. -f1)
if [[ "$bash_major" -ge 3 ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC} (found $bash_version)"
    ((FAILED++))
fi

# Test 2: Required commands
echo -n "  ✓ Required commands ... "
MISSING=()
for cmd in bc grep sed cut tr date; do
    command -v "$cmd" >/dev/null 2>&1 || MISSING+=("$cmd")
done
if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC} (missing: ${MISSING[*]})"
    ((FAILED++))
fi

# Test 3: bc arithmetic
echo -n "  ✓ bc calculator ... "
result=$(echo "scale=2; 10 / 3" | bc 2>/dev/null)
if [[ "$result" == "3.33" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC} (got $result)"
    ((FAILED++))
fi

# Test 4: Date command
echo -n "  ✓ Date operations ... "
today=$(date +%Y-%m-%d 2>/dev/null)
if [[ "$today" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

# Test 5: JSON parsing (no jq)
echo -n "  ✓ JSON parsing ... "
json='{"value": 12345}'
result=$(echo "$json" | grep -o '"value"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*')
if [[ "$result" == "12345" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

# Test 6: Run actual burnrate
echo -n "  ✓ Burnrate execution ... "
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
if "$PROJECT_ROOT/burnrate" --version >/dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Results: $PASSED passed, $FAILED failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ System is compatible!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some compatibility issues detected${NC}"
    exit 1
fi
