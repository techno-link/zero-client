#!/bin/bash

# Disable any form of screen saver / screen blanking / power management
xset s off
xset s noblank
xset -dpms

# Set Wallpaper
xsetroot -solid "#0C1A2A"
feh --bg-center /home/zero/.config/openbox/wallpaper.jpg

# Autostart Composite Manager
picom -b

# Autostart Conky
conky -c /etc/conky/conkyrc # Consider using a system-wide config if this is for all users

# Autostart PulseAudio
start-pulseaudio-x11

# Autostart Workspace Client
/opt/workspacesclient/workspacesclient
