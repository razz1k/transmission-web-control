#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Running OpenWRT integration tests..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
  echo "✗ Docker is not installed or not in PATH"
  exit 1
fi

# OpenWRT version to test
# Target device: Routerich AX3000 (mediatek/filogic)
# Specs: MT7981BA (ARMv8), 256 MB RAM, OpenWrt 24.10
# Note: ARM64 images use format "armsr-armv8-SNAPSHOT", x86_64 uses "x86_64-openwrt-24.10"
OPENWRT_VERSION="${OPENWRT_VERSION:-SNAPSHOT}"
OPENWRT_ARCH="${OPENWRT_ARCH:-armsr-armv8}"
OPENWRT_IMAGE="ghcr.io/openwrt/rootfs:${OPENWRT_ARCH}-${OPENWRT_VERSION}"

# Memory limit to simulate Routerich AX3000 (256 MB RAM)
MEMORY_LIMIT="${MEMORY_LIMIT:-256m}"

echo "Using OpenWRT image: $OPENWRT_IMAGE"
echo "Memory limit: $MEMORY_LIMIT (Routerich AX3000 has 256 MB RAM)"

# Pull OpenWRT image
echo "Pulling OpenWRT image..."
docker pull "$OPENWRT_IMAGE" || {
  echo "✗ Failed to pull OpenWRT image"
  exit 1
}

# Create test container
CONTAINER_NAME="transmission-web-control-test-$$"
echo "Creating test container: $CONTAINER_NAME"

# Start container in background with memory limit
docker run -d \
  --name "$CONTAINER_NAME" \
  --privileged \
  --memory="$MEMORY_LIMIT" \
  --memory-swap="$MEMORY_LIMIT" \
  -p 9091:9091 \
  -v "$PROJECT_ROOT/src:/tmp/webui:ro" \
  "$OPENWRT_IMAGE" \
  /sbin/init

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 5

# Cleanup function
cleanup() {
  echo "Cleaning up..."
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

# Install Transmission and dependencies
# Note: SNAPSHOT uses APK, stable versions use opkg
echo "Installing Transmission in container..."
docker exec "$CONTAINER_NAME" sh -c "
  if command -v apk >/dev/null 2>&1; then
    echo 'Using APK package manager (SNAPSHOT)'
    apk update
    apk add transmission-daemon transmission-web
  elif command -v opkg >/dev/null 2>&1; then
    echo 'Using opkg package manager'
    opkg update
    opkg install transmission-daemon transmission-web
  else
    echo 'No package manager found'
    exit 1
  fi
" || {
  echo "✗ Failed to install Transmission"
  exit 1
}

# Copy web interface
echo "Copying web interface to container..."
docker exec "$CONTAINER_NAME" sh -c "
  mkdir -p /usr/share/transmission/web
  cp -r /tmp/webui/* /usr/share/transmission/web/
  chmod -R 755 /usr/share/transmission/web
" || {
  echo "✗ Failed to copy web interface"
  exit 1
}

# Start Transmission daemon
echo "Starting Transmission daemon..."
docker exec "$CONTAINER_NAME" sh -c "
  mkdir -p /etc/transmission /var/lib/transmission/downloads
  cat > /etc/transmission/settings.json << 'EOF'
{\"download-dir\":\"/var/lib/transmission/downloads\",\"rpc-enabled\":true,\"rpc-bind-address\":\"0.0.0.0\",\"rpc-port\":9091,\"rpc-whitelist-enabled\":false,\"rpc-authentication-required\":false}
EOF
  export TRANSMISSION_WEB_HOME=/usr/share/transmission/web
  # Try init.d first (stable versions), fallback to direct start (SNAPSHOT)
  if [ -f /etc/init.d/transmission ]; then
    /etc/init.d/transmission stop 2>/dev/null || true
    /etc/init.d/transmission start
  else
    transmission-daemon -g /etc/transmission
  fi
  sleep 3
" || {
  echo "✗ Failed to start Transmission"
  exit 1
}

# Check if Transmission is running
echo "Checking Transmission status..."
if docker exec "$CONTAINER_NAME" pgrep -f transmission-daemon > /dev/null; then
  echo "✓ Transmission daemon is running"
else
  echo "✗ Transmission daemon is not running"
  exit 1
fi

# Check if web interface is accessible
echo "Checking web interface accessibility..."
MAX_RETRIES=10
RETRY_COUNT=0
SUCCESS=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if docker exec "$CONTAINER_NAME" wget -q -O - http://localhost:9091/transmission/web/ 2>/dev/null | grep -q "Transmission"; then
    SUCCESS=1
    break
  fi
  RETRY_COUNT=$((RETRY_COUNT + 1))
  sleep 2
done

if [ $SUCCESS -eq 1 ]; then
  echo "✓ Web interface is accessible"
else
  echo "✗ Web interface is not accessible"
  exit 1
fi

# Check if required files exist in web directory
echo "Checking required files in web directory..."
REQUIRED_FILES=(
  "/usr/share/transmission/web/index.html"
  "/usr/share/transmission/web/tr-web-control/config.js"
)

for file in "${REQUIRED_FILES[@]}"; do
  if docker exec "$CONTAINER_NAME" test -f "$file"; then
    echo "✓ Found: $file"
  else
    echo "✗ Missing: $file"
    exit 1
  fi
done

echo ""
echo "✓ All integration tests passed!"
