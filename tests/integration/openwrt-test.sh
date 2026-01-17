#!/bin/sh
set -e

# Integration test script for OpenWRT environment
# This script is executed inside the OpenWRT container
# First installs bash, then re-executes itself with bash

echo "Starting OpenWRT integration test..."

# Wait for container to be fully initialized
sleep 5

# Update package list
echo "Updating package list..."
opkg update || echo "Warning: opkg update failed, continuing anyway..."

# Install bash first
echo "Installing bash..."
opkg install bash || {
  echo "Error: Failed to install bash"
  exit 1
}

# Re-execute with bash if not already running in bash
if [ -z "$BASH_VERSION" ]; then
  exec /bin/bash "$0" "$@"
fi

# Install Transmission
echo "Installing Transmission..."
if ! opkg install transmission-daemon transmission-web; then
  echo "Error: Failed to install Transmission"
  exit 1
fi

# Verify Transmission installation
if ! command -v transmission-daemon &> /dev/null; then
  echo "Error: transmission-daemon not found after installation"
  exit 1
fi

echo "✓ Transmission installed successfully"

# Copy web interface
echo "Copying web interface..."
if [ -d "/tmp/webui" ]; then
  mkdir -p /usr/share/transmission/web
  cp -r /tmp/webui/* /usr/share/transmission/web/
  chmod -R 755 /usr/share/transmission/web
  echo "✓ Web interface copied"
else
  echo "Error: Web interface source not found at /tmp/webui"
  exit 1
fi

# Verify required files
REQUIRED_FILES=(
  "/usr/share/transmission/web/index.html"
  "/usr/share/transmission/web/tr-web-control/config.js"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Error: Required file not found: $file"
    exit 1
  fi
done

echo "✓ All required files present"

# Start Transmission
echo "Starting Transmission daemon..."
/etc/init.d/transmission stop || true
/etc/init.d/transmission start || {
  echo "Error: Failed to start Transmission"
  exit 1
}

# Wait for Transmission to start
sleep 5

# Verify Transmission is running
if ! pgrep -f transmission-daemon > /dev/null; then
  echo "Error: Transmission daemon is not running"
  exit 1
fi

echo "✓ Transmission daemon is running"

# Test web interface accessibility
echo "Testing web interface accessibility..."
MAX_RETRIES=10
RETRY_COUNT=0
SUCCESS=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if wget -q -O - http://localhost:9091/transmission/web/ 2>/dev/null | grep -q "Transmission"; then
    SUCCESS=1
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  sleep 2
done

if [ $SUCCESS -eq 1 ]; then
  echo "✓ Web interface is accessible"
else
  echo "Error: Web interface is not accessible after $MAX_RETRIES retries"
  exit 1
fi

echo ""
echo "✓ All integration tests passed!"
