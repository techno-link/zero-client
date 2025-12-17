#!/usr/bin/env bash
# Clean up failed or incomplete builds

echo "Cleaning up zero-client build artifacts..."

# Unmount all /mnt/zero-img mounts recursively
if mountpoint -q /mnt/zero-img 2>/dev/null; then
    echo "Unmounting /mnt/zero-img..."
    umount -R /mnt/zero-img 2>/dev/null || true
    umount -l /mnt/zero-img 2>/dev/null || true  # Force lazy unmount if needed
fi

# Detach all loop devices
echo "Detaching loop devices..."
losetup -D 2>/dev/null || true

# Remove mount directory
if [ -d /mnt/zero-img ]; then
    echo "Removing mount directory..."
    rmdir /mnt/zero-img 2>/dev/null || rm -rf /mnt/zero-img
fi

# Remove image file
if [ -f zero-client.img ]; then
    echo "Removing zero-client.img..."
    rm -f zero-client.img
fi

# Check for any remaining mounts
REMAINING_MOUNTS=$(mount | grep "/mnt/zero-img" || true)
if [ -n "$REMAINING_MOUNTS" ]; then
    echo "WARNING: Some mounts still remain:"
    echo "$REMAINING_MOUNTS"
else
    echo "All mounts cleaned up successfully."
fi

# Check for any remaining loop devices
REMAINING_LOOPS=$(losetup -l | grep zero-client || true)
if [ -n "$REMAINING_LOOPS" ]; then
    echo "WARNING: Some loop devices still remain:"
    echo "$REMAINING_LOOPS"
else
    echo "All loop devices cleaned up successfully."
fi

echo "Cleanup complete!"