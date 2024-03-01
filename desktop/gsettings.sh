#!/bin/bash

# KEYBOARD
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'bg'), ('xkb', 'bg+phonetic')]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Super>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Super>space']"

# WALLPAPER
gsettings set org.gnome.desktop.background picture-uri 'file:///home/zero/.config/linkin/wallpaper.jpg'
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///home/zero/.config/linkin/wallpaper.jpg'
gsettings set org.gnome.desktop.background primary-color '#000000000000'
gsettings set org.gnome.desktop.background secondary-color '#000000000000'

gsettings set org.gnome.desktop.screensaver picture-uri 'file:///home/zero/.config/linkin/wallpaper.jpg'
gsettings set org.gnome.desktop.screensaver primary-color '#000000000000'
gsettings set org.gnome.desktop.screensaver secondary-color '#000000000000'

# VIRTUAL WORKSPACES (MULTITASKING)
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1

# THEME DARK
gsettings set org.gnome.desktop gtk-theme 'Yaru-dark'

# FAV APPS
gsettings set org.gnome.shell favorite-apps ['com.amazon.workspacesclient.desktop', 'parsecd.desktop', 'gnome-system-monitor.desktop']

# POWER SETTINGS
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 900

# LOCK SCREEN
gsettings set org.gnome.desktop.screensaver lock-enabled true
gsettings set org.gnome.desktop.lockdown disable-lock-screen false
