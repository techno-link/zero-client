# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zero Client is an automated bootable Ubuntu 24.04 LTS USB image builder for thin client workloads. It creates fully-configured systems with pre-installed remote desktop clients (AWS WorkSpaces, Parsec), automatic remote management via Ansible, and USB flash drive longevity optimizations.

## Architecture

The system has three phases:

1. **Image Creation** (`image-creation/`): Bash scripts that use `debootstrap` to bootstrap Ubuntu into a 10GB raw disk image with GPT partitioning, systemd-boot (UEFI-only), and ext4 root. The Ansible playbook runs inside chroot during build.

2. **USB Deployment** (`image-creation/burn-to-*.sh`): Scripts that `dd` the image to one or multiple USB drives in parallel with progress tracking and rate limiting.

3. **Runtime Management** (`services/`): Systemd services pull the latest `ansible/zero.yml` from the `v4` branch on GitHub and apply it automatically:
   - `ansible-first-boot.service` — runs once, then disables itself and enables the other two
   - `ansible-boot.service` — runs on every boot
   - `ansible-cron.service` + timer — runs hourly with random 0-10 min delay

**To deploy configuration changes**: edit `ansible/zero.yml`, push to the `v4` branch. Devices auto-update within 1 hour.

## Key Files

- `ansible/zero.yml` — Main Ansible playbook (package installation, desktop config, user setup, QoS/DSCP rules, localization, client installation)
- `image-creation/create-image.sh` — Image builder: partitioning, debootstrap, filesystem setup
- `image-creation/modify-chroot.sh` — Runs inside chroot: kernel install, systemd-boot setup, Ansible run
- `desktop/gsettings.sh` — GNOME desktop settings (wallpaper, keyboard layouts, shortcuts)

## Common Commands

```bash
# Install build dependencies (Ubuntu host)
cd image-creation && sudo ./requirements.sh

# Build the image (produces zero-client.img)
sudo ./create-image.sh

# Burn to USB
sudo ./burn-to-usb.sh              # Single USB (interactive)
sudo ./burn-to-multi-usb.sh        # Multiple USBs in parallel (Linux)
sudo ./burn-to-multi-usb-mac.sh    # Multiple USBs in parallel (macOS)

# Clean up failed/incomplete builds
./clean-build.sh

# Test Ansible playbook locally
sudo ansible-playbook ansible/zero.yml -v
```

## Code Conventions

- **Language**: All scripts are Bash. No other languages in the project.
- **Formatting**: UTF-8, LF line endings, 2-space indentation, max 180 char line length (see `.editorconfig`)
- **Git**: Conventional commits (`feat:`, `fix:`, `docs:`, etc.). Development happens on `v4` branch.
- All image-creation scripts require `sudo` and are designed to run on Ubuntu hosts (except the mac burn script)
- The Ansible playbook uses a `ZEROSTATE` variable to distinguish chroot-time vs runtime execution
