#!/usr/bin/env bash
set -euo pipefail

# Source shared library (includes config and utility functions)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/lib.sh"

# Preflight checks
need_root
check_image_exists

success "=== USB Drive Writer ==="
echo ""
warn "This will DESTROY ALL DATA on the target drive!"
echo ""

# Show available block devices
echo "Available drives:"
lsblk -d -o NAME,SIZE,TYPE,VENDOR,MODEL | grep -v "loop\|ram"
echo ""

# Ask for target device
read -r -p "Enter target device (e.g., sdb, sdc): " DEVICE

# Validate device
if [ -z "$DEVICE" ]; then
  die "No device specified"
fi

# Add /dev/ prefix if not present
if [[ ! "$DEVICE" =~ ^/dev/ ]]; then
  DEVICE="/dev/$DEVICE"
fi

# Check if device exists
if [ ! -b "$DEVICE" ]; then
  die "Device $DEVICE does not exist or is not a block device"
fi

# Check if it's a partition (should be whole disk)
if [[ "$DEVICE" =~ [0-9]$ ]]; then
  warn "$DEVICE appears to be a partition, not a whole disk"
  echo "You probably want the parent device (e.g., ${DEVICE%[0-9]} instead of $DEVICE)"
  read -r -p "Continue anyway? (yes/no): " CONFIRM_PART
  if [ "$CONFIRM_PART" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi
fi

# Show device info
echo ""
warn "Target device information:"
lsblk "$DEVICE" -o NAME,SIZE,TYPE,VENDOR,MODEL,MOUNTPOINT
echo ""

# Show image info
IMAGE_SIZE=$(human_size "$(bytes_of_file "$ZC_IMAGE_NAME")")
success "Image: $ZC_IMAGE_NAME ($IMAGE_SIZE)"
echo ""

# Final confirmation
echo -e "${RED}THIS WILL ERASE ALL DATA ON $DEVICE${NC}"
read -r -p "Type 'YES' to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 0
fi

# Unmount any mounted partitions
echo ""
info "Unmounting any mounted partitions on $DEVICE..."
unmount_disk "$DEVICE"

# Write image
echo ""
success "Writing image to $DEVICE..."
echo "This may take several minutes. Please wait..."

# Use dd with status=progress if available
if dd --help 2>&1 | grep -q "status=progress"; then
  dd if="$ZC_IMAGE_NAME" of="$DEVICE" bs="$ZC_DD_BLOCK_SIZE" status=progress oflag=sync
else
  dd if="$ZC_IMAGE_NAME" of="$DEVICE" bs="$ZC_DD_BLOCK_SIZE" oflag=sync
fi

# Sync
echo ""
info "Syncing data to disk..."
sync

echo ""
success "Successfully wrote image to $DEVICE"
echo ""
echo "You can now safely remove the USB drive."
