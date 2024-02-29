# Disable any form of screen saver / screen blanking / power management
xset s off &
xset s noblank &
xset -dpms &

# Set Wallpaper
xsetroot -solid "#0C1A2A" &
feh --bg-center /home/zero/.config/openbox/wallpaper.jpg &

# Autostart Conky
conky -c /home/zero/.config/conky/conkyrc &

# Autostart Composite Manager
picom -b &

# Autostart PulseAudio
start-pulseaudio-x11 &

# Keyboard
setxkbmap -layout us,bg,bg -variant ,phonetic -option 'grp:alt_shift_toggle' &
