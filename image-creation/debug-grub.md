# GRUB Rescue Debug Guide

When you boot from USB and get into GRUB rescue mode, use these commands to debug:

## 1. Check available devices and partitions
```
ls
```
This shows all available devices. You should see something like:
- `(hd0)` - your USB drive
- `(hd0,gpt1)` - EFI partition
- `(hd0,gpt2)` - Root partition

## 2. Check partition contents
```
ls (hd0,gpt1)/
ls (hd0,gpt2)/
```

The EFI partition `(hd0,gpt1)` should contain:
- `EFI/` directory

The root partition `(hd0,gpt2)` should contain:
- `boot/` directory
- `etc/`, `usr/`, `var/` etc.

## 3. Set the correct root partition
```
set root=(hd0,gpt2)
```

## 4. Check if GRUB files exist
```
ls (hd0,gpt2)/boot/grub/
```
You should see `grub.cfg` and other GRUB files.

## 5. Load the GRUB configuration
```
set prefix=(hd0,gpt2)/boot/grub
configfile (hd0,gpt2)/boot/grub/grub.cfg
```

## 6. If that doesn't work, manually boot
```
set root=(hd0,gpt2)
linux (hd0,gpt2)/boot/vmlinuz-* root=LABEL=ZEROROOT ro
initrd (hd0,gpt2)/boot/initrd.img-*
boot
```

## Common Issues:

1. **Wrong partition numbers**: If `(hd0,gpt2)` doesn't work, try `(hd0,gpt1)` or other numbers
2. **Missing GRUB files**: The `/boot/grub/` directory should be on the root partition, not EFI partition
3. **Label issues**: Make sure the root partition has label `ZEROROOT`

## After successful boot, fix GRUB permanently:
```bash
sudo update-grub
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable
```