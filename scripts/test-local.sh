#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "Running local test suite"
echo "=========================================="
echo ""

ERRORS=0

# Linting tests
echo "1. Running linting tests..."
if "$SCRIPT_DIR/test-lint.sh"; then
  echo "✓ Linting tests passed"
else
  echo "✗ Linting tests failed"
  ERRORS=$((ERRORS + 1))
fi
echo ""

# Shellcheck tests
echo "2. Running shellcheck tests..."
if command -v shellcheck &> /dev/null; then
  if shellcheck release/*.sh; then
    echo "✓ Shellcheck tests passed"
  else
    echo "✗ Shellcheck tests failed"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "⚠ Shellcheck not found, skipping shell script validation"
fi
echo ""

# Integration tests (optional, can be skipped if Docker is not available)
if [ "${SKIP_INTEGRATION:-0}" != "1" ]; then
  echo "3. Running integration tests..."
  if "$SCRIPT_DIR/test-integration.sh"; then
    echo "✓ Integration tests passed"
  else
    echo "✗ Integration tests failed"
    ERRORS=$((ERRORS + 1))
  fi
  echo ""
else
  echo "3. Skipping integration tests (SKIP_INTEGRATION=1)"
  echo ""
fi

# Functional tests (optional, requires Playwright)
if [ "${SKIP_FUNCTIONAL:-0}" != "1" ]; then
  echo "4. Running functional tests..."
  if command -v npx &> /dev/null && [ -f "package.json" ]; then
    if npm run test:functional 2>&1; then
      echo "✓ Functional tests passed"
    else
      echo "✗ Functional tests failed"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo "⚠ Playwright not available, skipping functional tests"
  fi
  echo ""
else
  echo "4. Skipping functional tests (SKIP_FUNCTIONAL=1)"
  echo ""
fi

echo "=========================================="
if [ $ERRORS -eq 0 ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Tests failed with $ERRORS error(s)"
  exit 1
fi
