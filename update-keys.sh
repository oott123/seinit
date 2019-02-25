#!/bin/bash
set -e
[ -d ~/.ssh ] || mkdir ~/.ssh
chmod 755 ~/.ssh

KEYS=$(curl -s --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 40 https://launchpad.net/~oott123/+sshkeys)
if [ $? -eq 0 ]; then
  echo "$KEYS" > ~/.ssh/authorized_keys2
  chmod 600 ~/.ssh/authorized_keys2
fi
