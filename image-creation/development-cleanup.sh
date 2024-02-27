#!/usr/bin/env bash
set -euox pipefail

umount /mnt/zero-img/proc
umount /mnt/zero-img/sys
umount /mnt/zero-img/dev
umount /mnt/zero-img/boot/efi
umount /mnt/zero-img
losetup -d /dev/loop0

losetup -l

rm zero-client.img
