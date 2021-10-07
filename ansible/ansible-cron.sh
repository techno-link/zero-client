#!/usr/bin/env bash

wget -q https://raw.githubusercontent.com/techno-link/zero-client/master/ansible/zero.yml -O /root/zero.yml
ANSIBLE_LOG_PATH=/root/ansible.log ansible-playbook /root/zero.yml -v
