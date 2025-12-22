#!/usr/bin/env bash
# Clean up failed or incomplete builds
# This script consolidates all cleanup functionality

# Source shared library if available, otherwise define minimal requirements
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
if [ -f "$SCRIPT_DIR/lib.sh" ]; then
  source "$SCRIPT_DIR/lib.sh"
else
  # Minimal fallbacks if lib.sh doesn't exist yet
  ZC_ROOT_MOUNT="${ZC_ROOT_MOUNT:-/mnt/zero-img}"
  ZC_IMAGE_NAME="${ZC_IMAGE_NAME:-zero-client.img}"
fi

echo "Cleaning up zero-client build artifacts..."

# Unmount all mounts under root mount point recursively
if mountpoint -q "$ZC_ROOT_MOUNT" 2>/dev/null; then
  echo "Unmounting $ZC_ROOT_MOUNT..."
  umount -R "$ZC_ROOT_MOUNT" 2>/dev/null || true
  umount -l "$ZC_ROOT_MOUNT" 2>/dev/null || true
fi

# Also try common submounts explicitly (in case recursive unmount fails)
for submount in proc sys dev/pts dev run boot/efi; do
  if mountpoint -q "$ZC_ROOT_MOUNT/$submount" 2>/dev/null; then
    echo "Unmounting $ZC_ROOT_MOUNT/$submount..."
    umount "$ZC_ROOT_MOUNT/$submount" 2>/dev/null || \
    umount -l "$ZC_ROOT_MOUNT/$submount" 2>/dev/null || true
  fi
done

# Final attempt on root mount
if mountpoint -q "$ZC_ROOT_MOUNT" 2>/dev/null; then
  umount "$ZC_ROOT_MOUNT" 2>/dev/null || \
  umount -l "$ZC_ROOT_MOUNT" 2>/dev/null || true
fi

# Detach all loop devices associated with our image
echo "Detaching loop devices..."
if [ -f "$ZC_IMAGE_NAME" ]; then
  for loop in $(losetup -j "$ZC_IMAGE_NAME" 2>/dev/null | cut -d: -f1); do
    echo "Detaching $loop..."
    losetup -d "$loop" 2>/dev/null || true
  done
fi

# Fallback: detach all loop devices (if specific detach didn't work)
losetup -D 2>/dev/null || true

# Remove mount directory
if [ -d "$ZC_ROOT_MOUNT" ]; then
  echo "Removing mount directory..."
  rmdir "$ZC_ROOT_MOUNT" 2>/dev/null || rm -rf "$ZC_ROOT_MOUNT"
fi

# Remove image file
if [ -f "$ZC_IMAGE_NAME" ]; then
  echo "Removing $ZC_IMAGE_NAME..."
  rm -f "$ZC_IMAGE_NAME"
fi

# Check for any remaining mounts
REMAINING_MOUNTS=$(mount | grep "$ZC_ROOT_MOUNT" || true)
if [ -n "$REMAINING_MOUNTS" ]; then
  echo "WARNING: Some mounts still remain:"
  echo "$REMAINING_MOUNTS"
else
  echo "All mounts cleaned up successfully."
fi

# Check for any remaining loop devices
REMAINING_LOOPS=$(losetup -l 2>/dev/null | grep -E "zero-client|$ZC_IMAGE_NAME" || true)
if [ -n "$REMAINING_LOOPS" ]; then
  echo "WARNING: Some loop devices still remain:"
  echo "$REMAINING_LOOPS"
else
  echo "All loop devices cleaned up successfully."
fi

echo "Cleanup complete!"
