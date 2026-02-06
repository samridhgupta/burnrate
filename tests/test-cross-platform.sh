#!/usr/bin/env bash
# Cross-platform compatibility test suite
# Tests date utilities, JSON parsing, and core functionality

set -eo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source libraries
source "$PROJECT_ROOT/lib/date-utils.sh"

# Test helpers
test_start() {
    echo -n "  Testing: $1 ... "
    ((TESTS_RUN++))
}

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

test_fail() {
    local expected="$1"
    local actual="$2"
    echo -e "${RED}✗ FAIL${NC}"
    echo "    Expected: $expected"
    echo "    Actual:   $actual"
    ((TESTS_FAILED++))
}

# ============================================================================
# Date Utilities Tests
# ============================================================================

test_date_utilities() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Date Utilities Tests"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test 1: Get current date format
    test_start "get_current_date format"
    local today
    today=$(get_current_date)
    if [[ "$today" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        test_pass
    else
        test_fail "YYYY-MM-DD format" "$today"
    fi

    # Test 2: Date days ago
    test_start "get_date_days_ago"
    local past_date
    past_date=$(get_date_days_ago 7)
    if [[ "$past_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        test_pass
    else
        test_fail "YYYY-MM-DD format" "$past_date"
    fi

    # Test 3: Monday of week
    test_start "get_monday_of_week"
    local monday
    monday=$(get_monday_of_week)
    if [[ "$monday" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        test_pass
    else
        test_fail "YYYY-MM-DD format" "$monday"
    fi

    # Test 4: First day of month
    test_start "get_first_day_of_month"
    local first_day
    first_day=$(get_first_day_of_month)
    if [[ "$first_day" =~ -01$ ]]; then
        test_pass
    else
        test_fail "date ending with -01" "$first_day"
    fi

    # Test 5: Date comparison
    test_start "date_less_than"
    if date_less_than "2026-01-01" "2026-01-02"; then
        test_pass
    else
        test_fail "2026-01-01 < 2026-01-02" "comparison failed"
    fi

    # Test 6: Date in range
    test_start "date_in_range"
    if date_in_range "2026-01-15" "2026-01-01" "2026-01-31"; then
        test_pass
    else
        test_fail "2026-01-15 in range [2026-01-01, 2026-01-31]" "failed"
    fi

    # Test 7: Validate date format (valid)
    test_start "validate_date_format (valid)"
    if validate_date_format "2026-02-06"; then
        test_pass
    else
        test_fail "2026-02-06 is valid" "validation failed"
    fi

    # Test 8: Validate date format (invalid)
    test_start "validate_date_format (invalid)"
    if ! validate_date_format "2026-13-45"; then
        test_pass
    else
        test_fail "2026-13-45 is invalid" "validation passed incorrectly"
    fi
}

# ============================================================================
# JSON Parsing Tests
# ============================================================================

test_json_parsing() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  JSON Parsing Tests (No jq)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test 1: Extract simple number
    test_start "extract number from JSON"
    local json='{"count": 12345}'
    local result
    result=$(echo "$json" | grep -o '"count"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*')
    if [[ "$result" == "12345" ]]; then
        test_pass
    else
        test_fail "12345" "$result"
    fi

    # Test 2: Extract string
    test_start "extract string from JSON"
    local json='{"name": "test-value"}'
    local result
    result=$(echo "$json" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
    if [[ "$result" == "test-value" ]]; then
        test_pass
    else
        test_fail "test-value" "$result"
    fi

    # Test 3: Extract nested value
    test_start "extract nested JSON value"
    local json='{"data": {"tokens": 99999}}'
    local result
    result=$(echo "$json" | grep -o '"tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*')
    if [[ "$result" == "99999" ]]; then
        test_pass
    else
        test_fail "99999" "$result"
    fi
}

# ============================================================================
# Bash Compatibility Tests
# ============================================================================

test_bash_compatibility() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Bash Compatibility Tests"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test 1: Bash version
    test_start "bash version >= 3.2"
    local bash_version bash_major bash_minor pass_test
    bash_version=$(bash --version 2>&1 | head -1 | grep -o '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' || echo "3.2.0")
    bash_major=$(echo "$bash_version" | cut -d. -f1)
    bash_minor=$(echo "$bash_version" | cut -d. -f2)
    pass_test=false

    [[ "$bash_major" -gt 3 ]] && pass_test=true
    [[ "$bash_major" -eq 3 && "$bash_minor" -ge 2 ]] && pass_test=true

    if [[ "$pass_test" == "true" ]]; then
        test_pass
    else
        test_fail "bash >= 3.2" "bash $bash_major.$bash_minor"
    fi

    # Test 2: Required commands
    test_start "required commands available"
    local missing=()
    for cmd in bc grep sed cut tr date; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        test_pass
    else
        test_fail "all commands present" "missing: ${missing[*]}"
    fi

    # Test 3: bc calculator
    test_start "bc arithmetic"
    local result
    result=$(echo "scale=2; 10 / 3" | bc 2>/dev/null || echo "error")
    if [[ "$result" == "3.33" ]]; then
        test_pass
    else
        test_fail "3.33" "$result"
    fi

    # Test 4: Heredoc support
    test_start "heredoc support"
    local result
    result=$(cat <<EOF
test
EOF
)
    if [[ "$result" == "test" ]]; then
        test_pass
    else
        test_fail "test" "$result"
    fi
}

# ============================================================================
# System Information
# ============================================================================

show_system_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  System Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  OS:           $OSTYPE"
    echo "  Bash:         ${BASH_VERSION}"
    echo "  Date command: ${DATE_COMMAND_TYPE}"
    echo "  bc version:   $(bc --version 2>&1 | head -1 || echo 'unknown')"
    echo ""
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║   Burnrate Cross-Platform Compatibility Test Suite   ║"
    echo "╚═══════════════════════════════════════════════════════╝"

    show_system_info
    test_bash_compatibility
    test_date_utilities
    test_json_parsing

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Test Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  Tests run:    $TESTS_RUN"
    echo -e "  ${GREEN}Passed:       $TESTS_PASSED${NC}"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "  ${RED}Failed:       $TESTS_FAILED${NC}"
    else
        echo -e "  ${GREEN}Failed:       $TESTS_FAILED${NC}"
    fi
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests passed! System is compatible.${NC}"
        echo ""
        exit 0
    else
        echo -e "${RED}✗ Some tests failed. Check compatibility issues above.${NC}"
        echo ""
        exit 1
    fi
}

main "$@"
