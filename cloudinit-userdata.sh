#!/bin/bash
apt-get update -y
apt-get install -y wget
wget -O /root/seinit.sh https://raw.githubusercontent.com/oott123/seinit/master/seinit.sh
chmod +x /root/seinit.sh
SEI_BACKUP=yes SEI_FUCK_SSH=yes /root/seinit.sh
