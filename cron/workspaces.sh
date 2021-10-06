#!/usr/bin/env bash

apt-get update
apt-get --only-upgrade install -y workspacesclient

wget https://builds.parsecgaming.com/package/parsec-linux.deb -O /home/zero
dpkg -i parsec-linux.deb
