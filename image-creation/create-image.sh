#!/usr/bin/env bash
set -euo pipefail
set -x

# Source shared library (includes config and utility functions)
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source "$SCRIPT_DIR/lib.sh"

ANSIBLE_DIR="$SCRIPT_DIR/../ansible"
SERVICES_DIR="$SCRIPT_DIR/../services"

cleanup() {
  set +e
  sync

  umount -R "$ZC_ROOT_MOUNT" 2>/dev/null || true

  if [ -n "${LOOP_DEVICE:-}" ]; then
    losetup -d "$LOOP_DEVICE" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# Create image
dd if=/dev/zero of="$ZC_IMAGE_NAME" bs=1G count="$ZC_IMAGE_SIZE_GB"

# Attach loop device with partition scanning
LOOP_DEVICE="$(losetup -fP --show "$ZC_IMAGE_NAME")"

# Partition the loop device (GPT: ESP + rest Linux)
{
  echo 'label: gpt'
  echo "size=$ZC_ESP_SIZE, type=U"
  echo ',,L'
} | sfdisk "$LOOP_DEVICE"

# Tell kernel to re-scan partitions
partx -u "$LOOP_DEVICE" 2>/dev/null || true
sleep 1

ESP_PART="${LOOP_DEVICE}p1"
ROOT_PART="${LOOP_DEVICE}p2"

# Wait for partition devices to appear
for i in {1..20}; do
  [ -b "$ESP_PART" ] && [ -b "$ROOT_PART" ] && break
  echo "Waiting for partitions to appear... ($i/20)"
  sleep 0.5
done

if [ ! -b "$ESP_PART" ] || [ ! -b "$ROOT_PART" ]; then
  echo "ERROR: Partitions not found after sfdisk!" >&2
  lsblk "$LOOP_DEVICE" || true
  exit 1
fi

lsblk "$LOOP_DEVICE"

# Format ESP
mkfs.vfat -F32 -n "$ZC_ESP_LABEL" "$ESP_PART"

# Format root (USB-friendly: fully initialize now; no reserved blocks)
mkfs.ext4 -L "$ZC_ROOT_LABEL" -m 0 -E lazy_itable_init=0,lazy_journal_init=0 "$ROOT_PART"

# Set journal writeback mode (less writes, better for USB)
tune2fs -o journal_data_writeback "$ROOT_PART"

# Mount root + esp
mkdir -p "$ZC_ROOT_MOUNT"
mount "$ROOT_PART" "$ZC_ROOT_MOUNT"
mkdir -p "$ZC_ROOT_MOUNT/boot/efi"
mount "$ESP_PART" "$ZC_ROOT_MOUNT/boot/efi"

# Bootstrap
debootstrap --arch=amd64 "$ZC_DISTRO_RELEASE" "$ZC_ROOT_MOUNT" http://archive.ubuntu.com/ubuntu/

# Prepare chroot mounts
mkdir -p "$ZC_ROOT_MOUNT"/{proc,sys,dev,run,dev/pts}
mount -t proc /proc "$ZC_ROOT_MOUNT/proc"
mount --rbind /sys "$ZC_ROOT_MOUNT/sys"
mount --rbind /dev "$ZC_ROOT_MOUNT/dev"
mount --bind /run "$ZC_ROOT_MOUNT/run"
mount --bind /dev/pts "$ZC_ROOT_MOUNT/dev/pts"

# Services and playbook
cp "$SERVICES_DIR/"*.service "$ZC_ROOT_MOUNT/etc/systemd/system/" 2>/dev/null || true
cp "$SERVICES_DIR/"*.timer   "$ZC_ROOT_MOUNT/etc/systemd/system/" 2>/dev/null || true
cp "$ANSIBLE_DIR/zero.yml" "$ZC_ROOT_MOUNT/root/zero.yml"

# Copy ansible roles if they exist
if [ -d "$ANSIBLE_DIR/roles" ]; then
  mkdir -p "$ZC_ROOT_MOUNT/root/roles"
  cp -r "$ANSIBLE_DIR/roles/"* "$ZC_ROOT_MOUNT/root/roles/"
fi

# Copy ansible vars if they exist
if [ -d "$ANSIBLE_DIR/vars" ]; then
  mkdir -p "$ZC_ROOT_MOUNT/root/vars"
  cp -r "$ANSIBLE_DIR/vars/"* "$ZC_ROOT_MOUNT/root/vars/"
fi

# fstab (USB read-mostly)
cat >"$ZC_ROOT_MOUNT/etc/fstab" <<EOF
LABEL=$ZC_ROOT_LABEL / ext4 defaults,noatime,nodiratime,commit=60,errors=remount-ro 0 1
LABEL=$ZC_ESP_LABEL /boot/efi vfat defaults,noatime 0 0
tmpfs /tmp      tmpfs defaults,noatime,mode=1777 0 0
tmpfs /var/tmp  tmpfs defaults,noatime,mode=1777 0 0
tmpfs /var/log  tmpfs defaults,noatime,mode=0755 0 0
tmpfs /var/cache tmpfs defaults,noatime,mode=0755 0 0
EOF

# Chroot
cp "$SCRIPT_DIR/modify-chroot.sh" "$ZC_ROOT_MOUNT/root/modify-chroot.sh"
chmod +x "$ZC_ROOT_MOUNT/root/modify-chroot.sh"

chroot "$ZC_ROOT_MOUNT" /usr/bin/env -i \
  HOME=/root TERM="$TERM" \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  ZC_USER="$ZC_USER" \
  ZC_USER_HOME="$ZC_USER_HOME" \
  ZC_USER_COMMENT="$ZC_USER_COMMENT" \
  /root/modify-chroot.sh

rm -f "$ZC_ROOT_MOUNT/root/modify-chroot.sh"
