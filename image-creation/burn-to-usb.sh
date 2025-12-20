#!/usr/bin/env bash
set -euo pipefail

IMAGE="zero-client.img"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
  exit 1
fi

# Check if image exists
if [ ! -f "$IMAGE" ]; then
  echo -e "${RED}ERROR: Image file '$IMAGE' not found!${NC}"
  echo "Run ./create-image.sh first to create the image."
  exit 1
fi

echo -e "${GREEN}=== USB Drive Writer ===${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will DESTROY ALL DATA on the target drive!${NC}"
echo ""

# Show available block devices
echo "Available drives:"
lsblk -d -o NAME,SIZE,TYPE,VENDOR,MODEL | grep -v "loop\|ram"
echo ""

# Ask for target device
read -p "Enter target device (e.g., sdb, sdc): " DEVICE

# Validate device
if [ -z "$DEVICE" ]; then
  echo -e "${RED}ERROR: No device specified${NC}"
  exit 1
fi

# Add /dev/ prefix if not present
if [[ ! "$DEVICE" =~ ^/dev/ ]]; then
  DEVICE="/dev/$DEVICE"
fi

# Check if device exists
if [ ! -b "$DEVICE" ]; then
  echo -e "${RED}ERROR: Device $DEVICE does not exist or is not a block device${NC}"
  exit 1
fi

# Check if it's a partition (should be whole disk)
if [[ "$DEVICE" =~ [0-9]$ ]]; then
  echo -e "${YELLOW}WARNING: $DEVICE appears to be a partition, not a whole disk${NC}"
  echo "You probably want the parent device (e.g., ${DEVICE%[0-9]} instead of $DEVICE)"
  read -p "Continue anyway? (yes/no): " CONFIRM_PART
  if [ "$CONFIRM_PART" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi
fi

# Show device info
echo ""
echo -e "${YELLOW}Target device information:${NC}"
lsblk "$DEVICE" -o NAME,SIZE,TYPE,VENDOR,MODEL,MOUNTPOINT
echo ""

# Show image info
IMAGE_SIZE=$(du -h "$IMAGE" | cut -f1)
echo -e "${GREEN}Image: $IMAGE ($IMAGE_SIZE)${NC}"
echo ""

# Final confirmation
echo -e "${RED}THIS WILL ERASE ALL DATA ON $DEVICE${NC}"
read -p "Type 'YES' to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 0
fi

# Unmount any mounted partitions
echo ""
echo "Unmounting any mounted partitions on $DEVICE..."
for mount in $(lsblk -ln -o MOUNTPOINT "$DEVICE" | grep -v '^$'); do
  echo "  Unmounting $mount"
  umount "$mount" 2>/dev/null || true
done

# Write image
echo ""
echo -e "${GREEN}Writing image to $DEVICE...${NC}"
echo "This may take several minutes. Please wait..."

# Use dd with status=progress if available
if dd --help 2>&1 | grep -q "status=progress"; then
  dd if="$IMAGE" of="$DEVICE" bs=4M status=progress oflag=sync
else
  # Fallback without progress
  dd if="$IMAGE" of="$DEVICE" bs=4M oflag=sync
fi

# Sync
echo ""
echo "Syncing data to disk..."
sync

echo ""
echo -e "${GREEN}✓ Successfully wrote image to $DEVICE${NC}"
echo ""
echo "You can now safely remove the USB drive."