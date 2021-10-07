# Disable any form of screen saver / screen blanking / power management
xset s off
xset s noblank
xset -dpms

# Autostart Composite Compton
compton -b -c

# Autostart Conky
conky -c ~/.config/conkyrc

# Autostart PulseAudio
start-pulseaudio-x11

# Autostart Workspace Client
/opt/workspacesclient/workspacesclient
