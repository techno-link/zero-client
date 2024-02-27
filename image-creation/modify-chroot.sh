#!/usr/bin/env bash
set -euox pipefail

# KERNEL AND GRUB
apt install -y linux-image-generic grub-efi-amd64
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --recheck
update-grub

# INSTALL ANSIBLE
apt install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt install -y ansible

# CLEANUP APT
apt autoclean
apt autoremove -y --purge
apt clean

# CUSTOM SCRIPT AND SERVICES
systemctl enable ansible-boot.service
systemctl enable resizefs.service

# ADD DEFAULT USER
useradd -m -d /home/zero zero

# RUN ANSIBLE INSIDE CHROOT
ANSIBLE_LOG_PATH=/root/ansible.log ansible-playbook /root/zero.yml -v

