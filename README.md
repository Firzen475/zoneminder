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
`    ├── index.php`  
`    ├── styles.css`  
`    └── zoom.js`  
  
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
  
### III.1 Создание поользователей  
В первую очередь задать пароль администратора, и создать пользоватьелей для наблюдения через сайт.  
Options => Users
Имена пользователей наблюдения observer1 и observer2, пароли внести в файл .env  
Параметры observer*  
Stream => View  
Monitors => View  
Restricted Monitors => Список доступных пользователю мониторов (выбираются через Ctrl)  
API Enabled => Yes  
  
### III.2 Настройки доступа по паролю  
Options => System  
OPT_USE_AUTH = Yes  
AUTH_HASH_IPS = Yes  

### III.3 Настройки storage  
Options => Storage  
Для каждого хранилища (вместо N число от 1 до 4):
Name => datastorageN  
Path => /datastorageN  
  
### III.4 Включение стриминга камер  
Options => Network  
HTTP_VERSION => 1.1  
MIN_STREAMING_PORT => 30000
  
### III.5 Подключение камер  
Zoneminder поддерживает автоматический поиск камер в сети (Console => ADD => иконка WI-FI), но в контейнере он не работает потому, что контейнер, по сути, не имеет доступ к сети хоста и не может мониторить сеть. Для обхода этой проблемы можно временно раскоментировать строку network_mode: "host" в файле docker-compose.yml и зайти на https://[Имя сервера]:443/zm/  
В этом случае контейнер использует сетевой интерфейс напрямую и игнорирует проброс портов из контейнера.  
После настройки следует закомментировать строку.
Console => ADD => General  
Name => Имя камеры  
Source Type => ffmpeg(сетевая)/Local(локальная)  
Console => ADD => Source (сетевая)  
Путь можно получить из документации по камере или автоматическим поиском  
Source Path => rtsp://user:password@[ip]:5544/live0.264  
Capture Resolution (pixels) => выбор разрешения камеры, может не перехватывать сигнал, если разрешение не совпадает.  
Console => ADD => Source (локальная)  
Путь можно получить из документации по камере или автоматическим поиском  
Source Path => rtsp://user:password@[ip]:5544/live0.264  
Capture Resolution (pixels) => выбор разрешения камеры, может не перехватывать сигнал, если разрешение не совпадает.
Каждое устройство подключается как videoN
Device Path => /dev/videoN  
Capture Method => Video For Linux version 2  
Device Channel => Каналы карты, находятся подбором обычно в диапазоне 0-4  
Device Format => PAL  
Capture Palette => *YUYV  
Multi Buffering => Use Config Value  
Captures Per Frame => (5) Находится методом подбора. Карты с несколькими портами для камер чередуют кадры с камер, соединяя их в один поток. Этот параметр выбирает, какой кадр будет использован для записи.  
Capture Resolution (pixels) => выбор разрешения камеры, может не перехватывать сигнал, если разрешение не совпадает.  
Console => ADD => Storage  
Storage Area => datastorageX  
Save JPEGs => (Disable) Сохраняет запись в виде отдельных кадров. В таком режиме у меня не выгружалось видео (хотя в документации сказано, что должно склеиваться в видеофайл)  
Video Writer => Camera Passthrough  
Optional Encoder Parameters => crf=23  
Console => ADD => Buffers  
Количество кадров, помещаемых в оперативную память. Увеличение параметров поможет избезать пустых блоков при просмотре в записи. Бывает, ZM не успевает записать часть данных на диск.  
  
### III.6 Зоны тревоги
После создания камер можно задать зоны тревоги. Колонка Zones. Там всё просто.

### III.6 Контроль заполнения диска  
Filters => Use Filter => 1 PurgeWhenFull*  
В версии 1.36 указано, что теперь очищаются все хранилища, но для перестраховки можно добавить это правило для каждого datastorage.  
and => Storage Area => eqal to => datastorageX  





