#!/usr/bin/env bash

# ----------------------------------------------------------------------------------------------------------------------
# INSTALL AND RUN ANSIBLE
# ----------------------------------------------------------------------------------------------------------------------
apt-get install -y ansible
wget https://raw.githubusercontent.com/techno-link/zero-client/master/ansible/zero.yml -O /root/zero.yml
ansible-playbook /root/zero.yaml -e skip_handlers=true

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
cat <<EOT >>/etc/X11/xorg.conf
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOT

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
# ALLOW REBOOT + SHUTDOWN
# ----------------------------------------------------------------------------------------------------------------------
echo 'zero ALL=NOPASSWD:/sbin/reboot' >/etc/sudoers.d/zero
echo 'zero ALL=NOPASSWD:/sbin/poweroff' >>/etc/sudoers.d/zero

# ----------------------------------------------------------------------------------------------------------------------
# CRON
# ----------------------------------------------------------------------------------------------------------------------
wget https://raw.githubusercontent.com/techno-link/zero-client/master/ansible/ansible-cron.sh -O /etc/cron.hourly/ansible
chmod +x /etc/cron.hourly/ansible
