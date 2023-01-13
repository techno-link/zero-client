#!/usr/bin/env bash

wget -q https://github.com/aleks-ander/zero-client-update-to-fluxbox-20.04/blob/f506b3e26f493b4c0644b142879b9f0af9d73858/ansible/zero.yml -O /root/zero.yml
ANSIBLE_LOG_PATH=/root/ansible.log ansible-playbook /root/zero.yml -v
