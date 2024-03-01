#!/usr/bin/env bash
set -euox pipefail

# KERNEL AND GRUB
apt install -y linux-image-generic grub-efi-amd64
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=ZEROCLIENT --recheck --removable
update-grub

# INSTALL ANSIBLE
apt install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt install -y ansible

# CUSTOM SCRIPT AND SERVICES
systemctl enable ansible-boot.service

# ADD DEFAULT USER
useradd -m -d /home/zero -s /bin/bash zero

### DEV OPTIONS TODO: REMOVE
usermod -aG sudo zero
echo "zero:123456789" | chpasswd
echo "root:123456789" | chpasswd
echo -e "\033[31m!!! MODIFIED FOR DEV !!!\033[0m"
### END DEV OPTIONS

# RUN ANSIBLE INSIDE CHROOT
ZEROSTATE="CHROOT" ansible-playbook /root/zero.yml -v

# CLEANUP APT
apt autoclean
apt autoremove -y --purge
apt clean
