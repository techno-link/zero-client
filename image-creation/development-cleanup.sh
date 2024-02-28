#!/usr/bin/env bash
set -euox pipefail

umount /mnt/zero-img/proc
umount /mnt/zero-img/sys/firmware/efi/efivars
umount /mnt/zero-img/sys
umount /mnt/zero-img/dev/pts
umount /mnt/zero-img/dev
umount /mnt/zero-img/run/snapd/ns
umount /mnt/zero-img/run
umount /mnt/zero-img/efi
umount /mnt/zero-img
losetup -d /dev/loop0
losetup -d /dev/loop1
losetup -d /dev/loop2
losetup -d /dev/loop3
losetup -d /dev/loop4
losetup -d /dev/loop5
losetup -d /dev/loop6
losetup -d /dev/loop7
losetup -d /dev/loop8
losetup -d /dev/loop9

losetup -l

rm zero-client.img
