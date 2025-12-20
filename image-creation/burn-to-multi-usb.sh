#!/usr/bin/env bash
set -euo pipefail

IMAGE="zero-client.img"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if pv is installed (for progress bars)
if ! command -v pv &> /dev/null; then
  echo -e "${YELLOW}Installing 'pv' for progress visualization...${NC}"
  apt-get update && apt-get install -y pv
fi

echo -e "${GREEN}=== Multi-USB Drive Writer ===${NC}"
echo ""
echo -e "${YELLOW}WARNING: This will DESTROY ALL DATA on ALL selected USB drives!${NC}"
echo ""

# Function to detect USB drives
detect_usb_drives() {
  local usb_drives=()

  # Find all removable block devices
  for device in /sys/block/sd*; do
    if [ -f "$device/removable" ] && [ "$(cat $device/removable)" = "1" ]; then
      device_name=$(basename "$device")
      # Check if device has partitions or is accessible
      if [ -b "/dev/$device_name" ]; then
        usb_drives+=("/dev/$device_name")
      fi
    done
  done

  echo "${usb_drives[@]}"
}

# Detect USB drives
USB_DRIVES=($(detect_usb_drives))

if [ ${#USB_DRIVES[@]} -eq 0 ]; then
  echo -e "${RED}ERROR: No USB drives detected!${NC}"
  echo "Please insert USB drives and try again."
  exit 1
fi

# Show detected USB drives
echo -e "${GREEN}Detected USB drives:${NC}"
for device in "${USB_DRIVES[@]}"; do
  echo ""
  echo -e "${BLUE}Device: $device${NC}"
  lsblk "$device" -o NAME,SIZE,TYPE,VENDOR,MODEL,MOUNTPOINT
done
echo ""

# Show image info
IMAGE_SIZE=$(du -h "$IMAGE" | cut -f1)
echo -e "${GREEN}Image: $IMAGE ($IMAGE_SIZE)${NC}"
echo ""
echo -e "${YELLOW}Number of drives to write: ${#USB_DRIVES[@]}${NC}"
echo ""

# Final confirmation
echo -e "${RED}THIS WILL ERASE ALL DATA ON ALL ${#USB_DRIVES[@]} USB DRIVES LISTED ABOVE${NC}"
read -p "Type 'YES' to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 0
fi

# Create temp directory for logs
LOG_DIR="/tmp/usb-burn-$(date +%s)"
mkdir -p "$LOG_DIR"

# Function to burn image to a single drive
burn_to_drive() {
  local device=$1
  local log_file="$LOG_DIR/$(basename $device).log"

  {
    echo "=== Burning to $device ===" | tee -a "$log_file"

    # Unmount any mounted partitions
    echo "Unmounting partitions on $device..." | tee -a "$log_file"
    for mount in $(lsblk -ln -o MOUNTPOINT "$device" | grep -v '^$'); do
      umount "$mount" 2>/dev/null || true
    done

    # Write image with progress
    echo "Writing image to $device..." | tee -a "$log_file"
    pv -N "$device" "$IMAGE" | dd of="$device" bs=4M oflag=sync 2>&1 | tee -a "$log_file"

    # Sync
    echo "Syncing $device..." | tee -a "$log_file"
    sync

    echo "✓ Completed: $device" | tee -a "$log_file"
  } &
}

# Start burning to all drives in parallel
echo ""
echo -e "${GREEN}Starting parallel burn to ${#USB_DRIVES[@]} drives...${NC}"
echo ""

PIDS=()
for device in "${USB_DRIVES[@]}"; do
  burn_to_drive "$device"
  PIDS+=($!)
  sleep 0.5  # Small delay to stagger starts for better display
done

# Wait for all processes to complete
echo -e "${BLUE}Waiting for all burns to complete...${NC}"
echo "Press Ctrl+C to cancel (not recommended)"
echo ""

for pid in "${PIDS[@]}"; do
  wait $pid
done

# Summary
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}ALL BURNS COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Drives written:"
for device in "${USB_DRIVES[@]}"; do
  echo "  ✓ $device"
done
echo ""
echo "Logs saved in: $LOG_DIR"
echo ""
echo "You can now safely remove all USB drives."