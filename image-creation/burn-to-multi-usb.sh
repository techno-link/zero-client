#!/usr/bin/env bash
set -euo pipefail

IMAGE="zero-client.img"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

# Defaults tuned for: image on fast local NVMe, writing in parallel to 4 cheap USB drives
PV_RATE_LIMIT="20m"   # per-drive cap (MiB/s)
BS="4M"               # dd block size
STAGGER_SECONDS="2"   # stagger parallel starts

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }

need_root() {
  [ "${EUID:-$(id -u)}" -eq 0 ] || die "This script must be run as root (use sudo)"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

ensure_pv() {
  if command -v pv >/dev/null 2>&1; then
    return 0
  fi
  echo -e "${YELLOW}Installing 'pv' for progress visualization...${NC}"
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get install -y pv
  else
    die "'pv' is not installed and apt-get is unavailable. Install pv and rerun."
  fi
}

detect_usb_disks() {
  # TYPE=disk, TRAN=usb
  lsblk -dpno NAME,TYPE,TRAN | awk '$2=="disk" && $3=="usb" {print $1}'
}

list_partitions() {
  local disk="$1"
  lsblk -lnpo NAME,TYPE "$disk" | awk '$2=="part" {print $1}'
}

is_mounted_anywhere() {
  local dev="$1"
  findmnt -rnS "$dev" >/dev/null 2>&1
}

unmount_disk() {
  local disk="$1"
  local parts
  mapfile -t parts < <(list_partitions "$disk" || true)

  for p in "${parts[@]:-}"; do
    if is_mounted_anywhere "$p"; then
      echo "Unmounting $p..."
      umount "$p" || umount -l "$p" || true
    fi
  done

  if is_mounted_anywhere "$disk"; then
    echo "Unmounting $disk..."
    umount "$disk" || umount -l "$disk" || true
  fi
}

bytes_of_file() { stat -c '%s' "$1"; }
bytes_of_blockdev() { blockdev --getsize64 "$1"; }

# Kill background jobs on Ctrl+C / termination
PIDS=()
cleanup_children() {
  echo >&2
  echo -e "${RED}Aborting… stopping active writes${NC}" >&2
  if [ "${#PIDS[@]}" -gt 0 ]; then
    for pid in "${PIDS[@]}"; do
      kill "$pid" 2>/dev/null || true
    done
  fi
}
trap cleanup_children INT TERM

# ---- Preflight ----
need_root
need_cmd lsblk
need_cmd dd
need_cmd awk
need_cmd stat
need_cmd blockdev
need_cmd findmnt
need_cmd umount
need_cmd udevadm
ensure_pv

[ -f "$IMAGE" ] || die "Image file '$IMAGE' not found! Run ./create-image.sh first."

IMAGE_BYTES="$(bytes_of_file "$IMAGE")"
IMAGE_HUMAN="$(numfmt --to=iec --suffix=B "$IMAGE_BYTES" 2>/dev/null || echo "$IMAGE_BYTES bytes")"

echo -e "${GREEN}=== Multi-USB Drive Writer ===${NC}"
echo
echo -e "${YELLOW}WARNING: This will DESTROY ALL DATA on ALL selected USB drives!${NC}"
echo

mapfile -t USB_DISKS < <(detect_usb_disks || true)
[ "${#USB_DISKS[@]}" -gt 0 ] || die "No USB disks detected (TRAN=usb, TYPE=disk). Insert drives and try again."

# Safety: do not write to the disk backing /
ROOT_SOURCE="$(findmnt -n -o SOURCE /)"
ROOT_PKNAME="$(lsblk -no PKNAME "$ROOT_SOURCE" 2>/dev/null || true)"
ROOT_DISK="/dev/${ROOT_PKNAME:-}"

SAFE_USB_DISKS=()
for d in "${USB_DISKS[@]}"; do
  if [ -n "${ROOT_PKNAME:-}" ] && [ "$d" = "$ROOT_DISK" ]; then
    echo -e "${YELLOW}Skipping system disk (contains /): $d${NC}"
    continue
  fi
  SAFE_USB_DISKS+=("$d")
done
USB_DISKS=("${SAFE_USB_DISKS[@]}")
[ "${#USB_DISKS[@]}" -gt 0 ] || die "All detected USB disks are in use by the running system."

echo -e "${GREEN}Detected USB disks:${NC}"
for d in "${USB_DISKS[@]}"; do
  echo
  echo -e "${BLUE}Disk: $d${NC}"
  lsblk "$d" -o NAME,SIZE,TYPE,TRAN,VENDOR,MODEL,SERIAL,MOUNTPOINT
done
echo

echo -e "${GREEN}Image: $IMAGE (${IMAGE_HUMAN})${NC}"
echo -e "${YELLOW}Throttling: ${PV_RATE_LIMIT} per drive${NC}"
echo -e "${YELLOW}dd block size: ${BS}${NC}"
echo -e "${YELLOW}Parallel drives: ${#USB_DISKS[@]}${NC}"
echo

echo -e "${RED}THIS WILL ERASE ALL DATA ON ALL ${#USB_DISKS[@]} USB DISKS LISTED ABOVE${NC}"
read -r -p "Type 'YES' to continue: " CONFIRM
[ "$CONFIRM" = "YES" ] || { echo "Aborted."; exit 0; }

LOG_DIR="/tmp/usb-burn-$(date +%s)"
mkdir -p "$LOG_DIR"

burn_one() {
  local disk="$1"
  local log_file="$LOG_DIR/$(basename "$disk").log"

  {
    echo "=== Burning to $disk ==="
    date -Is
    echo "Image: $IMAGE ($IMAGE_BYTES bytes)"
    echo "Throttle: $PV_RATE_LIMIT, BS: $BS"
    echo

    # Size check
    local disk_bytes
    disk_bytes="$(bytes_of_blockdev "$disk")"
    if [ "$disk_bytes" -lt "$IMAGE_BYTES" ]; then
      echo "ERROR: Disk is smaller than image: disk=$disk_bytes image=$IMAGE_BYTES"
      exit 2
    fi

    # Unmount everything from this disk
    unmount_disk "$disk"

    echo "Writing image to $disk..."
    pv --rate-limit "$PV_RATE_LIMIT" -s "$IMAGE_BYTES" "$IMAGE" | \
      dd of="$disk" bs="$BS" conv=fsync status=progress

    echo "Syncing and flushing buffers..."
    sync
    blockdev --flushbufs "$disk" || true
    udevadm settle || true

    echo "Completed: $disk"
    date -Is
  } >>"$log_file" 2>&1
}

echo
echo -e "${GREEN}Starting parallel burn to ${#USB_DISKS[@]} drives...${NC}"
echo -e "${BLUE}Logs: $LOG_DIR${NC}"
echo

FAIL=0
PIDS=()

for disk in "${USB_DISKS[@]}"; do
  echo -e "${BLUE}Queue: $disk${NC}"
  burn_one "$disk" &
  PIDS+=("$!")
  sleep "$STAGGER_SECONDS"
done

echo
echo -e "${BLUE}Waiting for all burns to complete...${NC}"
echo "Press Ctrl+C to cancel (not recommended)"
echo

for i in "${!PIDS[@]}"; do
  pid="${PIDS[$i]}"
  disk="${USB_DISKS[$i]}"
  if ! wait "$pid"; then
    echo -e "${RED}FAILED: $disk (see $LOG_DIR/$(basename "$disk").log)${NC}"
    FAIL=1
  else
    echo -e "${GREEN}OK: $disk${NC}"
  fi
done

echo
if [ "$FAIL" -eq 0 ]; then
  echo -e "${GREEN}================================================${NC}"
  echo -e "${GREEN}ALL BURNS COMPLETED SUCCESSFULLY${NC}"
  echo -e "${GREEN}================================================${NC}"
else
  echo -e "${RED}================================================${NC}"
  echo -e "${RED}SOME BURNS FAILED. CHECK LOGS IN: $LOG_DIR${NC}"
  echo -e "${RED}================================================${NC}"
fi

echo
echo "Logs saved in: $LOG_DIR"
echo "You can now safely remove the USB drives (after activity LEDs are idle)."

exit "$FAIL"
