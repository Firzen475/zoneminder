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
Конечная структура  
`/zm_data/`  
`├── apache_logs` 
`├── backup`  
`├── cert`  
`│   ├── zoneminder.crt`  
`│   └── zoneminder.key`  
`├── cron`  
`│   └── cron.sh`  
`├── datastorage1`  
`├── datastorage2`  
`├── datastorage3`  
`├── datastorage4`  
`├── db`  
`├── images`  
`├── init`  
`├── logs`  
`└── www`  
`    ├── index.php`  
`    ├── styles.css`  
`    └── zoom.js`  
  
`mkdir /zm_data/`  
`cd /zm_data && mkdir ./apache_logs && mkdir ./backup && mkdir ./cert && mkdir ./cron && mkdir ./datastorage1 && mkdir ./datastorage2 && mkdir ./datastorage3 && mkdir ./datastorage4 && mkdir ./db && mkdir ./images && mkdir ./init && mkdir ./logs && mkdir ./www`  
`cd / && git clone --branch main --single-branch https://github.com/Firzen475/zoneminder.git`  
`cp /zoneminder/www/* /zm_data/www/ && cp /zoneminder/cron/* /zm_data/cron/`  
Для создания сертификата нужно отредактировать файл:  
`nano /zoneminder/cert/zoneminder.conf`  
`openssl req -x509 -nodes -days 4000 -newkey rsa:2048 -keyout /zm_data/cert/zoneminder.key -out /zm_data/cert/zoneminder.crt -config /zoneminder/cert/zoneminder.conf`  
  
### II.2 Подготовка развертывания  
Нужно подправить следующие файлы:
`nano /zoneminder/.env`  
`nano /zoneminder/docker-compose.yml`  
И ознакомиться с оставшимися файлами  
  
***  

## III Развертывание  
`#Сборка из Dockerfile`  
`cd /zoneminder/`  
`docker-compose down && docker-compose build --force-rm && docker-compose up -d`  
`#Запуск без сборки`  
`cd /zoneminder/`  
`docker-compose down && docker-compose up -d` 
`#Проверка статуса`  
`docker container ls`  
`#Подключение к контейнеру`  
`docker exec -it zoneminder /bin/bash`  
  
***
  
## III Настройка  
После множества тестов так и не удалось успешно запустить zm после обновления. В этом разделе описаны основные настройки в ручном режиме.  
  
### III.1 Создание поользователей  
В первую очередь задать пароль администратора, и создать пользоватьелей для наблюдения через сайт.  
Имена пользователей наблюдения observer1 и observer2, пароли внести в файл .env








