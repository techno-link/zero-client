#!/usr/bin/env bash
set -euo pipefail
set -x

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
ANSIBLE_DIR="$SCRIPT_DIR/../ansible"
SERVICES_DIR="$SCRIPT_DIR/../services"
ROOT_MOUNT_PATH="/mnt/zero-img"
IMAGE="zero-client.img"

cleanup() {
  set +e
  sync

  # Unmount in reverse order if mounted
  umount -R "$ROOT_MOUNT_PATH" 2>/dev/null || true

  if [ -n "${LOOP_DEVICE:-}" ]; then
    losetup -d "$LOOP_DEVICE" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# Create image
dd if=/dev/zero of="$IMAGE" bs=1G count=10

# Attach loop device with partition scanning
LOOP_DEVICE="$(losetup -fP --show "$IMAGE")"

# Partition the loop device
{
  echo 'label: gpt'
  echo 'size=500M, type=U'
  echo ',,L'
} | sfdisk "$LOOP_DEVICE"

# Tell kernel to re-scan partitions
partx -u "$LOOP_DEVICE" 2>/dev/null || true
sleep 1

ESP_PART="${LOOP_DEVICE}p1"
ROOT_PART="${LOOP_DEVICE}p2"

# Wait for partition devices to appear
for i in {1..10}; do
  [ -b "$ESP_PART" ] && [ -b "$ROOT_PART" ] && break
  echo "Waiting for partitions to appear... ($i/10)"
  sleep 1
done

# Verify partitions exist
if [ ! -b "$ESP_PART" ] || [ ! -b "$ROOT_PART" ]; then
  echo "ERROR: Partitions not found after sfdisk!" >&2
  lsblk "$LOOP_DEVICE" || true
  exit 1
fi

echo "Partitions ready:"
lsblk "$LOOP_DEVICE"

# Format
mkfs.vfat -F32 -n ZEROEFI "$ESP_PART"
mkfs.ext4 -L ZEROROOT "$ROOT_PART"

# Mount root + esp
mkdir -p "$ROOT_MOUNT_PATH"
mount "$ROOT_PART" "$ROOT_MOUNT_PATH"
mkdir -p "$ROOT_MOUNT_PATH/boot/efi"
mount "$ESP_PART" "$ROOT_MOUNT_PATH/boot/efi"

# Bootstrap
debootstrap --arch=amd64 noble "$ROOT_MOUNT_PATH" http://archive.ubuntu.com/ubuntu/

# Prepare chroot mounts
mkdir -p "$ROOT_MOUNT_PATH"/{proc,sys,dev,run,dev/pts}
mount -t proc /proc "$ROOT_MOUNT_PATH/proc"
mount --rbind /sys "$ROOT_MOUNT_PATH/sys"
mount --rbind /dev "$ROOT_MOUNT_PATH/dev"
mount --bind /run "$ROOT_MOUNT_PATH/run"
mount --bind /dev/pts "$ROOT_MOUNT_PATH/dev/pts"
# cp -L /etc/resolv.conf "$ROOT_MOUNT_PATH/etc/resolv.conf"

# Services and playbook
cp "$SERVICES_DIR/"*.service "$ROOT_MOUNT_PATH/etc/systemd/system/" || true
cp "$SERVICES_DIR/"*.timer "$ROOT_MOUNT_PATH/etc/systemd/system/" || true
cp "$ANSIBLE_DIR/zero.yml" "$ROOT_MOUNT_PATH/root/zero.yml"

# fstab
cat >"$ROOT_MOUNT_PATH/etc/fstab" <<'EOF'
LABEL=ZEROROOT / ext4 defaults,noatime,errors=remount-ro 0 1
LABEL=ZEROEFI /boot/efi vfat defaults 0 0
tmpfs /tmp tmpfs defaults,noatime,mode=1777 0 0
tmpfs /var/log tmpfs defaults,noatime,mode=0755 0 0
EOF

# Chroot
cp "$SCRIPT_DIR/modify-chroot.sh" "$ROOT_MOUNT_PATH/root/modify-chroot.sh"
chmod +x "$ROOT_MOUNT_PATH/root/modify-chroot.sh"

chroot "$ROOT_MOUNT_PATH" /usr/bin/env -i \
  HOME=/root TERM="$TERM" \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  /root/modify-chroot.sh

rm -f "$ROOT_MOUNT_PATH/root/modify-chroot.sh"
