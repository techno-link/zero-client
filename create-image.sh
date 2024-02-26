# PREPARE DEV ENV (THIS IS THE REQUIREMENTS FOR THE CONTAINERS)
apt update
apt install debootstrap squashfs-tools mtools grub-efi-amd64-bin dosfstools

# CREATE EMPTY IMAGE
dd if=/dev/zero of=zero-client.img bs=1G count=6

# POSE THE IMAGE AS BLOCK DEVICE ON /dev/loop0
losetup -fP zero-client.img

# PARTITION THE BLOCK DEVICE
{
echo 'label: gpt';
echo 'size=500M, type=U';
echo ',,L';
} | sfdisk /dev/loop0

# FORMAT THE PARTITIONS
mkfs.vfat -F 32 /dev/loop0p1  # Format the EFI partition as FAT32
mkfs.ext4 /dev/loop0p2        # Format the Linux partition as ext4

# MOUNT THE BLOCK DEVICE AND BOOTSTRAP
export ROOT_MOUNT_PATH="/mnt/zero-img/"
mkdir -p $ROOT_MOUNT_PATH
mount /dev/loop0p2 $ROOT_MOUNT_PATH

debootstrap --arch=amd64 jammy $ROOT_MOUNT_PATH http://archive.ubuntu.com/ubuntu/

mkdir -p $ROOT_MOUNT_PATH/boot/efi
mount /dev/loop0p1 $ROOT_MOUNT_PATH/boot/efi

# CUSTOM SCRIPT AND SERVICES
cp image/ansible-boot.sh $ROOT_MOUNT_PATH/usr/local/bin/ansible-boot.sh
cp image/ansible-boot.service $ROOT_MOUNT_PATH/etc/systemd/system/ansible-boot.service

cp image/resizefs.sh $ROOT_MOUNT_PATH/usr/local/bin/resizefs.sh
cp image/resizefs.service $ROOT_MOUNT_PATH/etc/systemd/system/resizefs.service

# CHROOT
mount --bind /dev $ROOT_MOUNT_PATH/dev
mount --bind /proc $ROOT_MOUNT_PATH/proc
mount --bind /sys $ROOT_MOUNT_PATH/sys
chroot $ROOT_MOUNT_PATH

# MODIFY SYSTEM
apt update
apt install -y linux-image-generic
apt install -y grub-efi-amd64
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --recheck --no-nvram
update-grub

apt install -y software-properties-common
add-apt-repository --yes --update ppa:ansible/ansible
apt install -y ansible

systemctl enable ansible-boot.service
systemctl enable resizefs.service

useradd -m -d /home/zero zero

#PREPARE ISO
exit
umount $ROOT_MOUNT_PATH/proc
umount $ROOT_MOUNT_PATH/sys
umount $ROOT_MOUNT_PATH/dev
umount $ROOT_MOUNT_PATH/boot/efi
umount $ROOT_MOUNT_PATH
losetup -d /dev/loop0

# ANSIBLE ADD
# 1. DISABLE TTY 2 to 6
# 2. SET AUTOLOGIN
