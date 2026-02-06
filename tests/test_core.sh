#!/usr/bin/env bash
# tests/test_core.sh - Tests for lib/core.sh

set -euo pipefail

# Load core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_ROOT/lib/core.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test framework
test_start() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Testing: lib/core.sh"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

test_assert() {
    local name="$1"
    local condition="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if eval "$condition"; then
        echo "✓ $name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ $name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_summary() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Tests run: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✓ All tests passed!"
        return 0
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✗ Some tests failed"
        return 1
    fi
}

# Run tests
test_start

# Version tests
test_assert "Version is set" "[[ -n \$BURNRATE_VERSION ]]"
test_assert "Version format correct" "[[ \$BURNRATE_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]"

# String utilities
test_assert "trim() removes spaces" "[[ \$(trim '  hello  ') == 'hello' ]]"
test_assert "to_lower() works" "[[ \$(to_lower 'HELLO') == 'hello' ]]"
test_assert "to_upper() works" "[[ \$(to_upper 'hello') == 'HELLO' ]]"
test_assert "starts_with() works" "starts_with 'hello world' 'hello'"
test_assert "ends_with() works" "ends_with 'hello world' 'world'"
test_assert "contains() works" "contains 'hello world' 'lo wo'"

# Number utilities
test_assert "is_number() accepts integers" "is_number '123'"
test_assert "is_number() accepts decimals" "is_number '123.45'"
test_assert "is_number() rejects text" "! is_number 'abc'"
test_assert "is_integer() accepts integers" "is_integer '123'"
test_assert "is_integer() rejects decimals" "! is_integer '123.45'"

# Boolean utilities
test_assert "parse_bool() true" "[[ \$(parse_bool 'true') == 'true' ]]"
test_assert "parse_bool() yes" "[[ \$(parse_bool 'yes') == 'true' ]]"
test_assert "parse_bool() 1" "[[ \$(parse_bool '1') == 'true' ]]"
test_assert "parse_bool() false" "[[ \$(parse_bool 'false') == 'false' ]]"
test_assert "parse_bool() no" "[[ \$(parse_bool 'no') == 'false' ]]"
test_assert "is_true() works" "is_true 'yes'"
test_assert "is_true() false" "! is_true 'no'"

# System detection
test_assert "detect_os() returns value" "[[ -n \$(detect_os) ]]"
test_assert "detect_shell() returns value" "[[ -n \$(detect_shell) ]]"

# Exit codes
test_assert "EXIT_SUCCESS is 0" "[[ \$EXIT_SUCCESS -eq 0 ]]"
test_assert "EXIT_ERROR is non-zero" "[[ \$EXIT_ERROR -ne 0 ]]"

# Test summary
test_summary
