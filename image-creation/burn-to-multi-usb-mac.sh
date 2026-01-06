#!/usr/bin/env opt/homebrew/bin/bash
set -euo pipefail

IMAGE="zero-client.img"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

PV_RATE_LIMIT="20m"   
BS="1m"               # macOS dd often prefers 1m or 4m
STAGGER_SECONDS="2"   

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }

need_root() {
  [ "${EUID:-$(id -u)}" -eq 0 ] || die "This script must be run as root (use sudo)"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1. Install via: brew install $1"
}

# --- macOS Specific Functions ---

detect_usb_disks() {
  # Filters for external, physical USB disks and returns /dev/diskN
  diskutil list external physical | grep -o '/dev/disk[0-9]*' | sort -u
}

unmount_disk() {
  local disk="$1"
  echo "Force unmounting all volumes on $disk..."
  diskutil unmountDisk "$disk" || true
}

bytes_of_file() { 
  stat -f '%z' "$1"
}

bytes_of_blockdev() {
  # Extracts total size in bytes from diskutil
  diskutil info "$1" | awk '/Total Size:/ {print $5}' | tr -d '()'
}

# --- Cleanup Logic ---
PIDS=()
cleanup_children() {
  echo >&2
  echo -e "${RED}Aborting… stopping active writes${NC}" >&2
  for pid in "${PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
}
trap cleanup_children INT TERM

# ---- Preflight ----
need_root
need_cmd pv
need_cmd diskutil
need_cmd awk

[ -f "$IMAGE" ] || die "Image file '$IMAGE' not found!"

IMAGE_BYTES="$(bytes_of_file "$IMAGE")"

echo -e "${GREEN}=== macOS Multi-USB Writer ===${NC}"
mapfile -t USB_DISKS < <(detect_usb_disks)
[ "${#USB_DISKS[@]}" -gt 0 ] || die "No external USB disks detected."

echo -e "${GREEN}Detected USB disks:${NC}"
for d in "${USB_DISKS[@]}"; do
    # Identify the 'raw' device for 2-3x faster writing on macOS
    RAW_DISK="${d/\/dev\/disk/\/dev\/rdisk}"
    SIZE_INFO=$(diskutil info "$d" | grep "Disk Size" | sed 's/.*: //')
    echo -e "${BLUE}Target: $d (Raw: $RAW_DISK) - $SIZE_INFO${NC}"
done

echo
read -r -p "Type 'YES' to erase ALL listed disks: " CONFIRM
[ "$CONFIRM" = "YES" ] || exit 0

LOG_DIR="/tmp/usb-burn-$(date +%s)"
mkdir -p "$LOG_DIR"

burn_one() {
  local disk="$1"
  # Use the RAW device path (/dev/rdiskN) for significantly higher speed on macOS
  local raw_disk="${disk/\/dev\/disk/\/dev\/rdisk}"
  local log_file="$LOG_DIR/$(basename "$disk").log"

  {
    local disk_bytes
    disk_bytes="$(bytes_of_blockdev "$disk")"
    if [ "$disk_bytes" -lt "$IMAGE_BYTES" ]; then
      echo "ERROR: $disk is too small."
      exit 2
    fi

    unmount_disk "$disk"

    # On macOS, using 'pv' to pipe into 'dd' is the most reliable way to show progress
    pv --rate-limit "$PV_RATE_LIMIT" -s "$IMAGE_BYTES" "$IMAGE" | \
      dd of="$raw_disk" bs="$BS"
      
    # macOS equivalent of flushing buffers
    sync
  } >>"$log_file" 2>&1
}

echo -e "${GREEN}Starting burns...${NC}"

for disk in "${USB_DISKS[@]}"; do
  echo -e "${BLUE}Writing to $disk...${NC}"
  burn_one "$disk" &
  PIDS+=("$!")
  sleep "$STAGGER_SECONDS"
done

# Wait for completion
FAIL=0
for i in "${!PIDS[@]}"; do
  if ! wait "${PIDS[$i]}"; then
    echo -e "${RED}FAILED: ${USB_DISKS[$i]}${NC}"
    FAIL=1
  else
    echo -e "${GREEN}OK: ${USB_DISKS[$i]}${NC}"
  fi
done

[ "$FAIL" -eq 0 ] && echo -e "\n${GREEN}SUCCESS!${NC}" || echo -e "\n${RED}FAILED!${NC}"
echo "Logs at: $LOG_DIR"