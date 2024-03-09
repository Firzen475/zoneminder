#!/usr/bin/env bash

mkdir -p ./data/apache_logs/
mkdir -p ./data/backup/
mkdir -p ./data/cron/
mkdir -p ./data/datastorage1/
mkdir -p ./data/datastorage2/
mkdir -p ./data/datastorage3/
mkdir -p ./data/datastorage4/
mkdir -p ./data/db/
mkdir -p ./data/images/
mkdir -p ./data/init/
mkdir -p ./data/logs/
mv ./www ./data/
mv ./cron ./data/
mv ./cert ./data/
apt update && apt install -y tree
tree ./data
