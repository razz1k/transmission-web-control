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
OPENWRT_VERSION="${OPENWRT_VERSION:-23.05.0}"
OPENWRT_ARCH="${OPENWRT_ARCH:-x86-64}"
OPENWRT_IMAGE="openwrt/rootfs:${OPENWRT_ARCH}-openwrt-${OPENWRT_VERSION}"

echo "Using OpenWRT image: $OPENWRT_IMAGE"

# Pull OpenWRT image
echo "Pulling OpenWRT image..."
docker pull "$OPENWRT_IMAGE" || {
  echo "✗ Failed to pull OpenWRT image"
  exit 1
}

# Create test container
CONTAINER_NAME="transmission-web-control-test-$$"
echo "Creating test container: $CONTAINER_NAME"

# Start container in background
docker run -d \
  --name "$CONTAINER_NAME" \
  --privileged \
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
echo "Installing Transmission in container..."
docker exec "$CONTAINER_NAME" sh -c "
  opkg update || true
  opkg install transmission-daemon transmission-web uhttpd || {
    echo 'Failed to install Transmission'
    exit 1
  }
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
  /etc/init.d/transmission stop || true
  /etc/init.d/transmission start || {
    echo 'Failed to start Transmission'
    exit 1
  }
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
