#!/usr/bin/env bash

# ----------------------------------------------------------------------------------------------------------------------
# INSTALL SOFTWARE
# ----------------------------------------------------------------------------------------------------------------------

# Install Openbox and XServer
apt-get install -y --no-install-recommends xserver-xorg x11-xserver-utils xinit openbox compton

# Install xterm
apt-get install -y xterm

# Install PusleAudio
apt-get install -y pulseaudio pavucontrol alsa-base alsa-utils linux-sound-base libasound2

# Install Conky
apt-get install -y conky

# Install Node (required for pipe menu)
apt-get install -y nodejs

# Install Workspace Client
apt-get install -y gnupg
wget -q -O - https://workspaces-client-linux-public-key.s3-us-west-2.amazonaws.com/ADB332E7.asc | sudo apt-key add -
echo "deb [arch=amd64] https://d3nt0h4h6pmmc4.cloudfront.net/ubuntu bionic main" | sudo tee /etc/apt/sources.list.d/amazon-workspaces-clients.list
apt-get update
apt-get install -y workspacesclient

# Allow sudo for zero user
usermod -aG sudo zero
echo "zero ALL=(ALL) NOPASSWORD:ALL" >> /etc/sudoers

# ----------------------------------------------------------------------------------------------------------------------
# AUTOSTART OPENBOX CONFIG
# ----------------------------------------------------------------------------------------------------------------------

# Disable any form of screen saver / screen blanking / power management
echo 'xset s off' >/etc/xdg/openbox/autostart
echo 'xset s noblank' >>/etc/xdg/openbox/autostart
echo 'xset -dpms' >>/etc/xdg/openbox/autostart

## Autostart Composite Compton
echo 'compton -b -c' >>/etc/xdg/openbox/autostart

## Autostart Conky
echo 'conky -c ~/.config/conkyrc' >>/etc/xdg/openbox/autostart

## Autostart PulseAudio
echo 'start-pulseaudio-x11' >>/etc/xdg/openbox/autostart

# Autostart Workspace Client
echo '/opt/workspacesclient/workspacesclient' >>/etc/xdg/openbox/autostart

# ----------------------------------------------------------------------------------------------------------------------
# DIABLE VIRTUAL TTY
# ----------------------------------------------------------------------------------------------------------------------
#cat <<EOT >>/etc/X11/xorg.conf
#Section "ServerFlags"
#    Option "DontVTSwitch" "true"
#EndSection
#EOT

# ----------------------------------------------------------------------------------------------------------------------
# AUTOLOIN AND START X
# ----------------------------------------------------------------------------------------------------------------------

mkdir -p /etc/systemd/system/getty@tty1.service.d/
tee -a /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --skip-login --noissue --autologin zero --noclear %I $TERM
Type=idle
EOF

echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && startx >/dev/null 2>&1' >/home/zero/.bash_profile
chown zero:zero /home/zero/.bash_profile

touch /home/zero/.hushlogin
chown zero:zero /home/zero/.hushlogin

sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="quiet"/' /etc/default/grub
echo 'GRUB_RECORDFAIL_TIMEOUT=0' >>/etc/default/grub
update-grub

# ----------------------------------------------------------------------------------------------------------------------
# CONFIG OPENBOX
# ----------------------------------------------------------------------------------------------------------------------
mkdir -p /home/zero/.config/openbox

wget https://raw.githubusercontent.com/techno-link/zero-client/feature_dev/test/openbox/rc.xml -O /home/zero/.config/openbox/rc.xml
wget https://raw.githubusercontent.com/techno-link/zero-client/feature_dev/test/openbox/menu.xml -O /home/zero/.config/openbox/menu.xml
chown zero:zero -R /home/zero/.config

wget -q https://raw.githubusercontent.com/techno-link/zero-client/feature_dev/test/openbox/audio-menu.js -O /home/zero/audio-menu.js
chown zero:zero /home/zero/audio-menu.js

wget -q https://raw.githubusercontent.com/techno-link/zero-client/feature_dev/test/openbox/conkyrc.lua -O /home/zero/.config/conkyrc
chown zero:zero /home/zero/.config/conkyrc

# ----------------------------------------------------------------------------------------------------------------------
# ALLOW REBOOT + SHUTDOWN
# ----------------------------------------------------------------------------------------------------------------------
echo 'zero ALL=NOPASSWD:/sbin/reboot' >/etc/sudoers.d/zero
echo 'zero ALL=NOPASSWD:/sbin/poweroff' >>/etc/sudoers.d/zero

# ----------------------------------------------------------------------------------------------------------------------
# CRON
# ----------------------------------------------------------------------------------------------------------------------
wget https://raw.githubusercontent.com/techno-link/zero-client/feature_dev/test/cron/workspaces.sh -O /etc/cron.hourly/workspaces
chmod +x /etc/cron.hourly/workspaces

wget https://raw.githubusercontent.com/techno-link/zero-client/feature_dev/test/cron/menu.sh -O /etc/cron.hourly/menu
chmod +x /etc/cron.hourly/menu

wget https://raw.githubusercontent.com/techno-link/zero-client/feature_dev/test/cron/conky.sh -O /etc/cron.hourly/conky
chmod +x /etc/cron.hourly/conky
