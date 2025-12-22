# Zero Client Usage Guide

This guide covers how to build, deploy, and customize the Zero Client bootable USB system.

## Prerequisites

### Build Machine Requirements

- Ubuntu 22.04+ or Debian 12+ (x86_64)
- Root access (sudo)
- At least 15GB free disk space
- Internet connection

### Install Build Dependencies

```bash
cd image-creation
sudo ./requirements.sh
```

This installs: `debootstrap`, `squashfs-tools`, `mtools`, `grub-efi-amd64-bin`, `dosfstools`

## Building the Image

### Quick Start

```bash
cd image-creation
sudo ./create-image.sh
```

This creates a `zero-client.img` file (~10GB) containing a bootable Ubuntu 24.04 system.

### Build Process Overview

1. Creates a 10GB raw disk image
2. Partitions with GPT: 500MB ESP + rest as ext4 root
3. Bootstraps Ubuntu 24.04 (Noble) via debootstrap
4. Installs systemd-boot bootloader
5. Runs Ansible playbook to configure the system
6. Optimizes filesystem for USB longevity

### Configuration Options

You can customize the build by setting environment variables before running `create-image.sh`:

```bash
# Change image name
export ZC_IMAGE_NAME="my-custom-image.img"

# Change image size (in GB)
export ZC_IMAGE_SIZE_GB=16

# Change target Ubuntu release
export ZC_DISTRO_RELEASE="noble"

# Change default username
export ZC_USER="myuser"

# Change branch version for updates
export ZC_BRANCH="v4"

# Run the build
sudo ./create-image.sh
```

All configuration variables are defined in `config.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `ZC_IMAGE_NAME` | `zero-client.img` | Output image filename |
| `ZC_IMAGE_SIZE_GB` | `10` | Image size in gigabytes |
| `ZC_ROOT_MOUNT` | `/mnt/zero-img` | Temporary mount point during build |
| `ZC_ESP_SIZE` | `500M` | EFI System Partition size |
| `ZC_USER` | `zero` | Default username |
| `ZC_BRANCH` | `v4` | GitHub branch for remote updates |
| `ZC_DISTRO_RELEASE` | `noble` | Ubuntu codename |
| `ZC_DD_BLOCK_SIZE` | `4M` | Block size for USB burning |

## Burning to USB

### Single USB Drive

```bash
cd image-creation
sudo ./burn-to-usb.sh
```

1. Lists available drives
2. Prompts for target device (e.g., `sdb`)
3. Shows device info and asks for confirmation
4. Writes image with progress indicator

### Multiple USB Drives (Parallel)

For burning to multiple drives simultaneously:

```bash
cd image-creation
sudo ./burn-to-multi-usb.sh
```

Features:
- Auto-detects all USB drives
- Excludes system disk automatically
- Burns in parallel with staggered starts
- Rate-limited to prevent I/O saturation (20MB/s per drive)
- Detailed logging to `/tmp/usb-burn-*`

Configuration:
```bash
# Adjust rate limit per drive
export ZC_PV_RATE_LIMIT="30m"

# Adjust stagger between parallel starts
export ZC_STAGGER_SECONDS="3"

sudo ./burn-to-multi-usb.sh
```

## Cleaning Up Failed Builds

If a build fails or is interrupted:

```bash
cd image-creation
sudo ./clean-build.sh
```

This unmounts all filesystems, detaches loop devices, and removes the image file.

## Boot Sequence

### First Boot

1. System boots via systemd-boot (UEFI)
2. `ansible-first-boot.service` runs:
   - Downloads latest `zero.yml` from GitHub
   - Applies full Ansible configuration
   - Disables itself
   - Enables `ansible-boot.service` and `ansible-cron.timer`
   - Reboots

### Subsequent Boots

1. `ansible-boot.service` runs on every boot:
   - Downloads latest configuration from GitHub
   - Applies any updates

2. `ansible-cron.timer` triggers hourly:
   - Random delay 0-10 minutes (prevents thundering herd)
   - Downloads and applies latest configuration

## Customization

### Modifying Ansible Configuration

The Ansible playbook is modular with roles in `ansible/roles/`:

```
ansible/
├── zero.yml              # Main orchestrator
├── vars/main.yml         # All configuration variables
└── roles/
    ├── base/             # APT, packages, TTY, locales
    ├── network/          # Netplan, QoS, hostname
    ├── desktop/          # GNOME, GDM, user settings
    ├── workspaces/       # AWS WorkSpaces client
    └── parsec/           # Parsec client
```

#### Common Customizations

**Change installed applications** - Edit `ansible/vars/main.yml`:
```yaml
gui_packages:
  - firefox
  - gnome-terminal
  - your-app-here
```

**Change hidden applications** - Edit `ansible/vars/main.yml`:
```yaml
hide_apps:
  - /usr/share/applications/app-to-hide.desktop
```

**Change keyboard layouts** - Edit `desktop/gsettings.sh`:
```bash
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'de')]"
```

**Change favorite dock apps** - Edit `desktop/gsettings.sh`:
```bash
gsettings set org.gnome.shell favorite-apps "['your-app.desktop', 'another-app.desktop']"
```

### Adding Custom Roles

1. Create role directory:
   ```bash
   mkdir -p ansible/roles/myrole/tasks
   ```

2. Create `ansible/roles/myrole/tasks/main.yml`:
   ```yaml
   ---
   - name: Install my custom package
     ansible.builtin.apt:
       name: my-package
       state: latest
   ```

3. Add to `ansible/zero.yml`:
   ```yaml
   roles:
     - base
     - network
     - desktop
     - workspaces
     - parsec
     - myrole  # Add your role here
   ```

### Remote Updates

The system automatically pulls updates from GitHub. To deploy changes:

1. Modify files in your fork/branch
2. Push to GitHub
3. Wait up to 1 hour (or reboot a device) for changes to apply

The update URL is configured in `services/ansible-*.service` files.

## Troubleshooting

### Build Fails with Mount Errors

```bash
sudo ./clean-build.sh
sudo ./create-image.sh
```

### USB Won't Boot

- Ensure UEFI boot is enabled (not Legacy/CSM)
- Check Secure Boot is disabled
- Verify the USB drive is at least 16GB

### Ansible Errors on Boot

Check logs:
```bash
# First boot log
cat /home/zero/.config/linkin/ansible-first-boot.log

# Regular boot log
cat /home/zero/.config/linkin/ansible-boot.log

# Hourly update log
cat /home/zero/.config/linkin/ansible-cron.log
```

### Network Not Working

The system uses DHCP by default. For static IP, modify the netplan template:
`ansible/roles/network/templates/netplan.yaml.j2`

## Hardware Requirements

- **CPU**: x86_64 with UEFI support
- **RAM**: 4GB minimum (8GB recommended)
- **USB**: 16GB+ USB 3.0 flash drive
- **Network**: Ethernet (auto-configured via DHCP)

## File Structure Reference

```
zero-client/
├── ansible/
│   ├── zero.yml                 # Main playbook
│   ├── vars/main.yml            # Configuration variables
│   └── roles/                   # Modular roles
├── desktop/
│   ├── gsettings.sh             # GNOME settings script
│   └── wallpaper.jpg            # Desktop wallpaper
├── image-creation/
│   ├── config.sh                # Shared configuration
│   ├── lib.sh                   # Shared functions
│   ├── create-image.sh          # Image builder
│   ├── burn-to-usb.sh           # Single USB burner
│   ├── burn-to-multi-usb.sh     # Multi USB burner
│   ├── clean-build.sh           # Cleanup utility
│   ├── modify-chroot.sh         # Chroot setup
│   └── requirements.sh          # Build dependencies
└── services/
    ├── ansible-first-boot.service
    ├── ansible-boot.service
    ├── ansible-cron.service
    └── ansible-cron.timer
```
