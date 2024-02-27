#!/usr/bin/env bash
set -euox pipefail

# VARS
SCRIPT_DIR=$(dirname "$(realpath "$0")")
SERVICES_DIR="$SCRIPT_DIR/../services"
ANSIBLE_DIR="$SCRIPT_DIR/../ansible"
ROOT_MOUNT_PATH="/mnt/zero-img/"

# CREATE EMPTY IMAGE
dd if=/dev/zero of=zero-client.img bs=1G count=6

# POSE THE IMAGE AS BLOCK DEVICE ON /dev/loop0
losetup -fP zero-client.img

# PARTITION THE BLOCK DEVICE
{
  echo 'label: gpt'
  echo 'size=500M, type=U'
  echo ',,L'
} | sfdisk /dev/loop0

# FORMAT THE PARTITIONS
mkfs.vfat -F 32 /dev/loop0p1 # Format the EFI partition as FAT32
mkfs.ext4 /dev/loop0p2       # Format the Linux partition as ext4

# MOUNT THE BLOCK DEVICE AND BOOTSTRAP
mkdir -p $ROOT_MOUNT_PATH
mount /dev/loop0p2 $ROOT_MOUNT_PATH

debootstrap --arch=amd64 jammy $ROOT_MOUNT_PATH http://archive.ubuntu.com/ubuntu/

mkdir -p $ROOT_MOUNT_PATH/boot/efi
mount /dev/loop0p1 $ROOT_MOUNT_PATH/boot/efi

# PREPARE FOR CHROOT
mount --bind /dev $ROOT_MOUNT_PATH/dev
mount --bind /proc $ROOT_MOUNT_PATH/proc
mount --bind /sys $ROOT_MOUNT_PATH/sys

# CUSTOM SERVICES
cp "$SERVICES_DIR/resizefs.sh" "$ROOT_MOUNT_PATH/usr/local/bin/resizefs.sh"
cp "$SERVICES_DIR/resizefs.service" "$ROOT_MOUNT_PATH/etc/systemd/system/resizefs.service"
cp "$SERVICES_DIR/ansible-boot.sh" "$ROOT_MOUNT_PATH/usr/local/bin/ansible-boot.sh"
cp "$SERVICES_DIR/ansible-boot.service" "$ROOT_MOUNT_PATH/etc/systemd/system/ansible-boot.service"

# ANSIBLE PLAYBOOKS
cp "$ANSIBLE_DIR/zero.yml" "$ROOT_MOUNT_PATH/root/zero.yml"

# CHROOT
cp "$SCRIPT_DIR/modify-chroot.sh" "$ROOT_MOUNT_PATH/root/modify-chroot.sh"
chmod +x "$ROOT_MOUNT_PATH/root/modify-chroot.sh"
chroot $ROOT_MOUNT_PATH /root/modify-chroot.sh
rm "$ROOT_MOUNT_PATH/root/modify-chroot.sh"

# CLEANUP
umount $ROOT_MOUNT_PATH/proc
umount $ROOT_MOUNT_PATH/sys
umount $ROOT_MOUNT_PATH/dev
umount $ROOT_MOUNT_PATH/boot/efi
umount $ROOT_MOUNT_PATH
losetup -d /dev/loop0
