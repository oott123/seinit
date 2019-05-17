#!/bin/bash
apt-get update
apt-get install -y --no-install-recommends docker.io
docker network create --subnet=192.168.210.0/24 localnet
