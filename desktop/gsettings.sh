#!/bin/bash

gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'bg'), ('xkb', 'bg+phonetic')]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Super>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Super>space']"
gsettings set org.gnome.desktop.background picture-uri '/home/zero/.config/linkin/wallpaper.jpg'
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1
