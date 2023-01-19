#!/usr/bin/env bash

wget -q https://raw.githubusercontent.com/aleks-ander/zero-client-update-to-fluxbox-20.04/test/ansible/zero.yml -O /root/zero.yml
wget -q https://raw.githubusercontent.com/aleks-ander/zero-client-update-to-fluxbox-20.04/test/ansible/run-once.yml -O /root/run-once.yml
ANSIBLE_LOG_PATH=/root/ansible.log ansible-playbook /root/zero.yml -v
ANSIBLE_LOG_PATH=/root/ansible_once.log ansible-playbook /root/run-once.yml -v
