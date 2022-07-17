# zoneminder
## I Введение  
За основу взят этот репозиторий.
***
## II Подготовка
### II.1 Установка основного софта
https://docs.docker.com/engine/install/ubuntu/
https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04-ru
`sudo apt install git`
### II.2 Подготовка пространства

./zm/
├── zm_apache_logs
├── zm_backup
├── zm_cert
│   ├── zoneminder.crt
│   └── zoneminder.key
├── zm_cron
│   └── cron.sh
├── zm_datastorage1
├── zm_datastorage2
├── zm_datastorage3
├── zm_datastorage4
├── zm_db
│   ├── ....
│   └── zm
│       ├── ...
│       └── ...
├── zm_images
├── zm_init
│   └── dump.sql
├── zm_logs
└── zm_www
    ├── index.php
    ├── styles.css
    └── zoom.js

mkdir /zoneminder/ && mkdir /zoneminder_source/
cd /zoneminder && mkdir ./apache_logs && mkdir ./backup && mkdir ./cron && mkdir ./datastorage1 && mkdir ./datastorage2 && mkdir ./datastorage3 && mkdir ./datastorage4 && mkdir ./db && mkdir ./images && mkdir ./init && mkdir ./logs && mkdir ./www
cd /zoneminder_source && git clone --branch master --single-branch https://github.com/Firzen475/zoneminder.git`
