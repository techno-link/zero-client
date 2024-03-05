#!/bin/bash

# KEEP SETTINGS FILE
FILE="/home/zero/.config/linkin/settings_reset"


# ----------------------------------------------------------------------------------------------------------------------
# USER STABLE SETTINGS
# ----------------------------------------------------------------------------------------------------------------------

if [ ! -f "$FILE" ]; then
  # KEYBOARD
  gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'bg'), ('xkb', 'bg+phonetic')]"
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Super>space']"
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Super>space']"

  touch "$FILE"
fi

# ----------------------------------------------------------------------------------------------------------------------
# MANDATORY SETTINGS
# ----------------------------------------------------------------------------------------------------------------------

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
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1

# THEME DARK
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark'

# FAV APPS
gsettings set org.gnome.shell favorite-apps "['com.amazon.workspacesclient.desktop', 'parsecd.desktop']"

# POWER SETTINGS
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 900

# CUSTOM SHORTCUTS
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

# > TERMINAL
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Control><Shift><Super><Alt>t']"

# > LOCK SCREEN
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Lock Screen'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'loginctl lock-session'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>l'
