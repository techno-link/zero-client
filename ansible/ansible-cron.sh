#!/usr/bin/env bash

wget -q https://raw.githubusercontent.com/aleks-ander/zero-client-update-to-fluxbox-20.04/master/ansible/zero.yml -O /root/zero.yml
ANSIBLE_LOG_PATH=/root/ansible.log ansible-playbook /root/zero.yml -v
