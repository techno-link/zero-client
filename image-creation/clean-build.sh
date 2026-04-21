#!/usr/bin/env bash
# Clean up failed or incomplete builds.
#
# Safety: this script NEVER runs `rm -rf` on the mount directory. If any
# submount is still live (because a chroot process is holding /dev or /sys
# open), we would end up recursing through a bind mount into the host's
# real filesystem. We refuse to delete anything until everything is clean.

set -u

MOUNT_ROOT="/mnt/zero-img"
IMAGE_FILE="zero-client.img"

echo "Cleaning up zero-client build artifacts..."

# Order matters: unmount deepest bind-mounts first, root last. Every call uses
# lazy unmount so that busy submounts detach now and free their resources
# once no longer referenced.
SUBMOUNTS=(
  "$MOUNT_ROOT/dev/pts"
  "$MOUNT_ROOT/dev"
  "$MOUNT_ROOT/proc"
  "$MOUNT_ROOT/sys"
  "$MOUNT_ROOT/run"
  "$MOUNT_ROOT/boot/efi"
  "$MOUNT_ROOT"
)

for mount_path in "${SUBMOUNTS[@]}"; do
  if mountpoint -q "$mount_path" 2>/dev/null; then
    echo "Unmounting $mount_path..."
    umount "$mount_path" 2>/dev/null || umount -l "$mount_path" 2>/dev/null || true
  fi
done

# Detach any loop devices that were pointing at our image.
echo "Detaching loop devices backing $IMAGE_FILE..."
while read -r loop_device; do
  [ -n "$loop_device" ] && losetup -d "$loop_device" 2>/dev/null || true
done < <(losetup -l -O NAME,BACK-FILE 2>/dev/null | awk -v img="$IMAGE_FILE" '$2 ~ img {print $1}')

# Verify nothing remains mounted under MOUNT_ROOT before touching the directory.
REMAINING_MOUNTS=$(mount | awk -v root="$MOUNT_ROOT" '$3 ~ root {print}' || true)
if [ -n "$REMAINING_MOUNTS" ]; then
  echo "ERROR: mounts still remain under $MOUNT_ROOT — refusing to delete:" >&2
  echo "$REMAINING_MOUNTS" >&2
  echo "Resolve the stuck mounts manually (or reboot) and rerun." >&2
  exit 1
fi

# Only rmdir (never rm -rf) — rmdir fails if non-empty, which is what we want.
if [ -d "$MOUNT_ROOT" ]; then
  if ! rmdir "$MOUNT_ROOT" 2>/dev/null; then
    echo "ERROR: $MOUNT_ROOT is not empty after unmounting. Leaving it alone." >&2
    echo "Inspect its contents and remove manually if you're certain it's safe." >&2
    exit 1
  fi
fi

# Remove image file only after we confirmed nothing was mounted from it.
if [ -f "$IMAGE_FILE" ]; then
  echo "Removing $IMAGE_FILE..."
  rm -f "$IMAGE_FILE"
fi

# Final sanity check.
REMAINING_LOOPS=$(losetup -l -O NAME,BACK-FILE 2>/dev/null | awk -v img="$IMAGE_FILE" '$2 ~ img {print}' || true)
if [ -n "$REMAINING_LOOPS" ]; then
  echo "WARNING: loop devices still reference $IMAGE_FILE:" >&2
  echo "$REMAINING_LOOPS" >&2
  exit 1
fi

echo "Cleanup complete."
