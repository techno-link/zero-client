#!/usr/bin/env bash

wget -q https://raw.githubusercontent.com/techno-link/zero-client/master/openbox/conkyrc.lua -O /home/zero/.config/conkyrc
chown zero:zero /home/zero/.config/conkyrc
