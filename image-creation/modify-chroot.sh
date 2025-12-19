#!/usr/bin/env bash
set -euo pipefail
set -x

export DEBIAN_FRONTEND=noninteractive

apt-get update

# Bootable base - CRITICAL ORDER for Ubuntu 24.04:
# 1. Kernel + initramfs-tools first (required by shim-signed post-install)
# 2. shim-signed (will copy real bootloader only if kernel exists)
# 3. grub-efi-amd64
echo "==> Installing kernel and initramfs tools..."
apt-get install -y --no-install-recommends \
  linux-image-generic \
  initramfs-tools \
  systemd-sysv \
  ca-certificates

echo "==> Installing shim-signed (now that kernel is installed)..."
apt-get install -y --no-install-recommends shim-signed

echo "==> Installing GRUB EFI..."
apt-get install -y --no-install-recommends grub-efi-amd64

# Validate ESP
if ! mountpoint -q /boot/efi; then
  echo "ERROR: ESP is not mounted at /boot/efi" >&2
  exit 1
fi

# Write /etc/default/grub deterministically (do NOT append)
cat >/etc/default/grub <<'EOF'
GRUB_DEFAULT=0
GRUB_TIMEOUT=2
GRUB_TIMEOUT_STYLE=menu
GRUB_DISTRIBUTOR=`( . /etc/os-release; echo ${NAME:-Ubuntu} ) 2>/dev/null || echo Ubuntu`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""

# Helpful on removable media: include search modules early
GRUB_PRELOAD_MODULES="part_gpt part_msdos fat ext2 search search_fs_uuid search_fs_label"

# For removable media, disable UUID to avoid chroot loop device UUIDs
GRUB_DISABLE_LINUX_UUID=true
GRUB_DISABLE_LINUX_PARTUUID=true
EOF

echo "==> Installing GRUB bootloader to ESP (removable fallback)..."
grub-install \
  --target=x86_64-efi \
  --efi-directory=/boot/efi \
  --boot-directory=/boot \
  --bootloader-id=ZEROCLIENT \
  --removable \
  --no-nvram \
  --recheck

echo "==> Building initramfs for all installed kernels..."
# Use -u (update) which will create if missing, safer than -c
update-initramfs -u -k all

echo "==> Generating GRUB configuration..."
update-grub

# Ubuntu 24.04 fix: Replace any hardcoded device paths with label-based search
echo "==> Fixing device references in grub.cfg for removable media..."
sed -i 's|root=/dev/[^ ]*|root=LABEL=ZEROROOT|g' /boot/grub/grub.cfg
sed -i '/set root=/s|(hd[0-9]*,gpt[0-9]*)|'\''hd0,gpt2'\''|g' /boot/grub/grub.cfg

# Provide a fallback grub.cfg next to BOOTX64.EFI (good practice for removable)
echo "==> Writing fallback config for EFI/BOOT..."
mkdir -p /boot/efi/EFI/BOOT
cat >/boot/efi/EFI/BOOT/grub.cfg <<'EOF'
# Fallback GRUB config for removable media
search --no-floppy --set=root --label ZEROROOT
set prefix=($root)/boot/grub
configfile $prefix/grub.cfg
EOF

# Validate expected outputs
echo "==> Validating boot artifacts..."
test -f /boot/grub/grub.cfg
ls -la /boot/efi/EFI/BOOT || true
test -f /boot/efi/EFI/BOOT/BOOTX64.EFI || echo "WARNING: BOOTX64.EFI not found; firmware may not boot this image."

# Universe + ansible (optional)
apt-get install -y software-properties-common
add-apt-repository --yes universe
apt-get update
apt-get install -y ansible

# Enable your service if present
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable ansible-first-boot.service || true
fi

# ----------------------------
# Create default user
# ----------------------------
if ! id -u zero >/dev/null 2>&1; then
  useradd -m -c "Linkin Zero Client" -d /home/zero -s /bin/bash zero
  echo "zero ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/zero"
  chmod 440 "/etc/sudoers.d/zero"
fi

# ----------------------------
# Run Ansible inside chroot
# ----------------------------
if [ -f /root/zero.yml ]; then
  LC_ALL=C.UTF-8 LANG=C.UTF-8 ZEROSTATE=CHROOT ansible-playbook /root/zero.yml -v
else
  echo "WARNING: /root/zero.yml not found, skipping ansible-playbook" >&2
fi
