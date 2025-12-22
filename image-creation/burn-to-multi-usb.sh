#!/usr/bin/env bash
set -euo pipefail

# Source shared library (includes config and utility functions)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/lib.sh"

# Kill background jobs on Ctrl+C / termination
PIDS=()
cleanup_children() {
  echo >&2
  echo -e "${RED}Aborting... stopping active writes${NC}" >&2
  if [ "${#PIDS[@]}" -gt 0 ]; then
    for pid in "${PIDS[@]}"; do
      kill "$pid" 2>/dev/null || true
    done
  fi
}
trap cleanup_children INT TERM

# Preflight checks
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
check_image_exists

IMAGE_BYTES="$(bytes_of_file "$ZC_IMAGE_NAME")"
IMAGE_HUMAN="$(human_size "$IMAGE_BYTES")"

success "=== Multi-USB Drive Writer ==="
echo
warn "This will DESTROY ALL DATA on ALL selected USB drives!"
echo

mapfile -t USB_DISKS < <(detect_usb_disks || true)
[ "${#USB_DISKS[@]}" -gt 0 ] || die "No USB disks detected (TRAN=usb, TYPE=disk). Insert drives and try again."

# Safety: do not write to the disk backing /
ROOT_DISK="$(get_root_disk)"

SAFE_USB_DISKS=()
for d in "${USB_DISKS[@]}"; do
  if [ -n "${ROOT_DISK:-}" ] && [ "$d" = "$ROOT_DISK" ]; then
    warn "Skipping system disk (contains /): $d"
    continue
  fi
  SAFE_USB_DISKS+=("$d")
done
USB_DISKS=("${SAFE_USB_DISKS[@]}")
[ "${#USB_DISKS[@]}" -gt 0 ] || die "All detected USB disks are in use by the running system."

success "Detected USB disks:"
for d in "${USB_DISKS[@]}"; do
  echo
  info "Disk: $d"
  lsblk "$d" -o NAME,SIZE,TYPE,TRAN,VENDOR,MODEL,SERIAL,MOUNTPOINT
done
echo

success "Image: $ZC_IMAGE_NAME (${IMAGE_HUMAN})"
warn "Throttling: ${ZC_PV_RATE_LIMIT} per drive"
warn "dd block size: ${ZC_DD_BLOCK_SIZE}"
warn "Parallel drives: ${#USB_DISKS[@]}"
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
    echo "Image: $ZC_IMAGE_NAME ($IMAGE_BYTES bytes)"
    echo "Throttle: $ZC_PV_RATE_LIMIT, BS: $ZC_DD_BLOCK_SIZE"
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
    pv --rate-limit "$ZC_PV_RATE_LIMIT" -s "$IMAGE_BYTES" "$ZC_IMAGE_NAME" | \
      dd of="$disk" bs="$ZC_DD_BLOCK_SIZE" conv=fsync status=progress

    echo "Syncing and flushing buffers..."
    sync
    blockdev --flushbufs "$disk" || true
    udevadm settle || true

    echo "Completed: $disk"
    date -Is
  } >>"$log_file" 2>&1
}

echo
success "Starting parallel burn to ${#USB_DISKS[@]} drives..."
info "Logs: $LOG_DIR"
echo

FAIL=0
PIDS=()

for disk in "${USB_DISKS[@]}"; do
  info "Queue: $disk"
  burn_one "$disk" &
  PIDS+=("$!")
  sleep "$ZC_STAGGER_SECONDS"
done

echo
info "Waiting for all burns to complete..."
echo "Press Ctrl+C to cancel (not recommended)"
echo

for i in "${!PIDS[@]}"; do
  pid="${PIDS[$i]}"
  disk="${USB_DISKS[$i]}"
  if ! wait "$pid"; then
    echo -e "${RED}FAILED: $disk (see $LOG_DIR/$(basename "$disk").log)${NC}"
    FAIL=1
  else
    success "OK: $disk"
  fi
done

echo
if [ "$FAIL" -eq 0 ]; then
  success "================================================"
  success "ALL BURNS COMPLETED SUCCESSFULLY"
  success "================================================"
else
  echo -e "${RED}================================================${NC}"
  echo -e "${RED}SOME BURNS FAILED. CHECK LOGS IN: $LOG_DIR${NC}"
  echo -e "${RED}================================================${NC}"
fi

echo
echo "Logs saved in: $LOG_DIR"
echo "You can now safely remove the USB drives (after activity LEDs are idle)."

exit "$FAIL"
