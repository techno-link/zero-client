if [[ ! ${DISPLAY} && ${XDG_VTNR} == 1 ]]; then
    exec startx >/dev/null 2>&1
fi
