#!/usr/bin/env bash
# Zero Client Shared Library
# Common functions used across all image-creation scripts.
# Source this file to get access to colors, logging, and utility functions.

# Determine script directory and source config
ZC_LIB_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
# shellcheck source=./config.sh
source "${ZC_LIB_DIR}/config.sh"

# Colors (using $'...' syntax for proper ANSI handling)
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

# Logging functions
die() {
  echo -e "${RED}ERROR: $*${NC}" >&2
  exit 1
}

info() {
  echo -e "${BLUE}$*${NC}"
}

warn() {
  echo -e "${YELLOW}WARNING: $*${NC}"
}

success() {
  echo -e "${GREEN}$*${NC}"
}

# Preflight check functions
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
  warn "Installing 'pv' for progress visualization..."
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get install -y pv
  else
    die "'pv' is not installed and apt-get is unavailable. Install pv and rerun."
  fi
}

# Image validation
check_image_exists() {
  [ -f "$ZC_IMAGE_NAME" ] || die "Image file '$ZC_IMAGE_NAME' not found! Run ./create-image.sh first."
}

# Device utilities
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
  mapfile -t parts < <(list_partitions "$disk" 2>/dev/null || true)

  for p in "${parts[@]:-}"; do
    if is_mounted_anywhere "$p"; then
      info "Unmounting $p..."
      umount "$p" 2>/dev/null || umount -l "$p" 2>/dev/null || true
    fi
  done

  if is_mounted_anywhere "$disk"; then
    info "Unmounting $disk..."
    umount "$disk" 2>/dev/null || umount -l "$disk" 2>/dev/null || true
  fi
}

# Size utilities
bytes_of_file() {
  stat -c '%s' "$1"
}

bytes_of_blockdev() {
  blockdev --getsize64 "$1"
}

human_size() {
  numfmt --to=iec --suffix=B "$1" 2>/dev/null || echo "$1 bytes"
}

# USB disk detection
detect_usb_disks() {
  lsblk -dpno NAME,TYPE,TRAN | awk '$2=="disk" && $3=="usb" {print $1}'
}

get_root_disk() {
  local root_source root_pkname
  root_source="$(findmnt -n -o SOURCE /)"
  root_pkname="$(lsblk -no PKNAME "$root_source" 2>/dev/null || true)"
  if [ -n "$root_pkname" ]; then
    echo "/dev/$root_pkname"
  fi
}
