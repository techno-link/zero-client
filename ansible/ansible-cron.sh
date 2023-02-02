#!/usr/bin/env bash

wget -q https://raw.githubusercontent.com/techno-link/zero-client/master/ansible/zero.yml -O /root/zero.yml
wget -q https://raw.githubusercontent.com/techno-link/zero-client/master/ansible/run-once.yml -O /root/run-once.yml
ANSIBLE_LOG_PATH=/root/ansible.log ansible-playbook /root/zero.yml -v
ANSIBLE_LOG_PATH=/root/ansible_once.log ansible-playbook /root/run-once.yml -v
