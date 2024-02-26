#!/usr/bin/env bash
set -euox pipefail

apt update
apt install -y debootstrap squashfs-tools mtools grub-efi-amd64-bin dosfstools
