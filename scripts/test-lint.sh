#!/bin/bash
set -e

echo "Running linting tests..."

ERRORS=0

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# JavaScript linting
echo "Checking JavaScript files..."
if npx eslint --version > /dev/null 2>&1; then
  if npm run lint:js; then
    echo "✓ JavaScript linting passed"
  else
    echo "✗ JavaScript linting failed"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "⚠ ESLint not available, skipping JavaScript linting"
fi

# CSS linting
echo "Checking CSS files..."
if npx stylelint --version > /dev/null 2>&1; then
  if npm run lint:css; then
    echo "✓ CSS linting passed"
  else
    echo "✗ CSS linting failed"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "⚠ Stylelint not available, skipping CSS linting"
fi

# HTML validation
echo "Checking HTML files..."
if npx html-validate --version > /dev/null 2>&1; then
  if npm run lint:html; then
    echo "✓ HTML validation passed"
  else
    echo "✗ HTML validation failed"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "⚠ html-validate not available, skipping HTML validation"
fi

# JSON validation
echo "Checking JSON files..."
if npx jsonlint-cli --version > /dev/null 2>&1; then
  if npm run lint:json; then
    echo "✓ JSON validation passed"
  else
    echo "✗ JSON validation failed"
    ERRORS=$((ERRORS + 1))
  fi
else
  echo "⚠ jsonlint-cli not available, skipping JSON validation"
fi

# Check required files exist
echo "Checking required files..."
REQUIRED_FILES=(
  "src/index.html"
  "src/index.mobile.html"
  "src/tr-web-control/config.js"
  "src/tr-web-control/plugin.js"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✓ Found: $file"
  else
    echo "✗ Missing: $file"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -eq 0 ]; then
  echo ""
  echo "✓ All linting checks passed!"
  exit 0
else
  echo ""
  echo "✗ Linting failed with $ERRORS error(s)"
  exit 1
fi
