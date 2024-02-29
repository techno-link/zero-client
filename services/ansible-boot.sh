#!/usr/bin/env bash

wget https://raw.githubusercontent.com/techno-link/zero-client/v3/ansible/ansible-cron.sh -O /etc/cron.hourly/run-ansible
chmod +x /etc/cron.hourly/run-ansible

bash /etc/cron.hourly/run-ansible
