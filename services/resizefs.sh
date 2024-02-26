#!/usr/bin/env bash

# The device holding the root filesystem, typically /dev/sda1 or /dev/mmcblk0p1 for USB/SD cards
ROOT_PART=$(findmnt / -o source -n)

# Expand the filesystem
resize2fs $ROOT_PART

echo "Filesystem resized."

# Disable this script from running again at boot
systemctl disable resizefs.service
