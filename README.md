# zoneminder  
## I Введение  
За основу взят [этот](https://github.com/ZoneMinder/zmdockerfiles) репозиторий.  
Полезная и довольно подробная [документация](https://zoneminder.readthedocs.io/_/downloads/en/1.34.3/pdf/).
  
***  
  
## II Подготовка  
### II.1 Установка основного софта  
[Docker](https://docs.docker.com/engine/install/ubuntu/)  
[docker-compose](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-20-04-ru)  
`sudo apt install git`  
  
### II.2 Подготовка пространства  
  
```
mkdir -p /zoneminder/zm_data/  
cd /zoneminder/zm_data/ && mkdir ./apache_logs && mkdir ./backup && mkdir ./cert && mkdir ./cron && mkdir ./datastorage1 && mkdir ./datastorage2 && mkdir ./datastorage3 && mkdir ./datastorage4 && mkdir ./db && mkdir ./images && mkdir ./init && mkdir ./logs && mkdir ./www  
cd /zoneminder && git clone --branch main --single-branch https://github.com/Firzen475/zoneminder.git /zoneminder 
cp /zoneminder/www/* /zoneminder/zm_data/www/ && cp /zoneminder/cron/* /zoneminder/zm_data/cron/  
```  
Для создания сертификата нужно отредактировать файл:  
```
nano /zoneminder/cert/zoneminder.conf  
openssl req -x509 -nodes -days 4000 -newkey rsa:2048 -keyout /zm_data/cert/zoneminder.key -out /zm_data/cert/zoneminder.crt -config /zoneminder/cert/zoneminder.conf` 
```
  
Конечная структура  
```
/zoneminder/zm_data/  
├── apache_logs  
├── backup  
├── cert  
│   ├── zoneminder.crt  
│   └── zoneminder.key  
├── cron  
│   └── cron.sh  
├── datastorage1  
├── datastorage2  
├── datastorage3  
├── datastorage4  
├── db  
├── images  
├── init  
├── logs  
└── www  
    ├── index.php  
    ├── styles.css  
    └── zoom.js
```

### II.2 Подготовка развертывания  
Нужно подправить следующие файлы:  
```
nano /zoneminder/.env  
nano /zoneminder/docker-compose.yml  
```
И ознакомиться с оставшимися файлами  
  
***  

## III Развертывание  
```
#Сборка из Dockerfile  
cd /zoneminder/  
docker-compose down && docker-compose build --force-rm && docker-compose up -d  
#Запуск без сборки  
cd /zoneminder/  
docker-compose down && docker-compose up -d  
#Проверка статуса  
docker container ls  
#Подключение к контейнеру  
docker exec -it zoneminder /bin/bash  
```
  
***
  
## IV Настройка    
  
### IV.1 Общее  
В первую очередь нужно добанить сертификт сайта в доверенные и добавить запись на DNS сервере при работе с https. Если этого не сделать могут появляться проблемы с отсутствием изображения с камер.  
После заершения настройки нужно выполнить бекап настроек. Для этого:  
`docker exec zoneminder /bin/sh -c '/cron/cron.sh'`
### IV.2 Создание поользователей  
В первую очередь задать пароль администратора, и создать пользоватьелей для наблюдения через сайт.  
`Options => Users`
Имена пользователей наблюдения observer1 и observer2, пароли получить из [.env](/.env)  
Параметры observer*  
```
Stream => View  
Monitors => View  
Restricted Monitors => Список доступных пользователю мониторов (выбираются через Ctrl)  
API Enabled => Yes  
```

### IV.3 Настройки доступа по паролю  
```
Options => System  
OPT_USE_AUTH = Yes  
AUTH_HASH_IPS = Yes  
```
  
### IV.4 Настройки storage  
```
Options => Storage  
Для каждого хранилища (вместо N число от 1 до 4):
Name => datastorageN  
Path => /datastorageN  
```
  
### IV.5 Включение стриминга камер  
```
Options => Network  
HTTP_VERSION => 1.1  
MIN_STREAMING_PORT => 30000
```

### IV.6 Подключение камер  
Zoneminder поддерживает автоматический поиск камер в сети (Console => ADD => ![1](/ico.png)), но в контейнере он не работает потому, что контейнер, по сути, не имеет доступ к сети хоста и не может мониторить сеть. Для обхода этой проблемы можно временно раскоментировать строку `network_mode: "host"` в файле [docker-compose.yml](/docker-compose.yml) и зайти на `https://[Имя сервера]:443/zm/`  
В этом случае контейнер использует сетевой интерфейс напрямую и игнорирует проброс портов из контейнера.  
После настройки следует закомментировать строку.
Добавление камеры:
```
Console => ADD => General  
Name => Имя камеры  
Source Type => ffmpeg(сетевая)/Local(локальная)  
```
- Для сетевой:  
```
Console => ADD => Source (сетевая)  
Source Path => rtsp://user:password@[ip]:5544/live0.264 #Путь можно получить из документации по камере или автоматическим поиском  
Capture Resolution (pixels) => выбор разрешения камеры, может не перехватывать сигнал, если разрешение не совпадает.    
```
- Для локальной:
```
Console => ADD => Source (локальная)  
Device Path => /dev/videoN #Каждое устройство подключается как videoN  
Capture Method => Video For Linux version 2  
Device Channel => Каналы карты, находятся подбором обычно в диапазоне 0-4  
Device Format => PAL  
Capture Palette => *YUYV  
Multi Buffering => Use Config Value  
Captures Per Frame => (5) Находится методом подбора. Карты с несколькими портами для камер чередуют кадры с камер, соединяя их в один поток. Этот параметр выбирает, какой кадр будет использован для записи.  
Capture Resolution (pixels) => выбор разрешения камеры, может не перехватывать сигнал, если разрешение не совпадает.  
```
Общее:
```
Console => ADD => Storage  
Storage Area => datastorageX  
Save JPEGs => (Disable) Сохраняет запись в виде отдельных кадров. В таком режиме у меня не выгружалось видео (хотя в документации сказано, что должно склеиваться в видеофайл)  
Video Writer => Camera Passthrough  
Optional Encoder Parameters => crf=23  
```
```
Console => ADD => Buffers  #Количество кадров, помещаемых в оперативную память. Увеличение параметров поможет избежать пустых блоков при просмотре в записи. Бывает, ZM не успевает записать часть данных на диск.
```  
  
### IV.7 Зоны тревоги
После создания камер можно задать зоны тревоги. Колонка Zones. Там всё просто.

### IV.8 Контроль заполнения диска  
В версии 1.36 указано, что теперь очищаются все хранилища, но для перестраховки можно добавить это правило для каждого datastorage.  
```
Filters => Use Filter => 1 PurgeWhenFull*  
#Добавить условие
and => Storage Area => eqal to => datastorageX  
```
  
***
  
## V Сайт наблюдения (стена)  
- Чтобы добавить камеру пользователю, выбрать нужные при редактировании пользователя. пункт Restricted Monitors.
- Чтобы использовался пользователь observer2 => https://[Имя сервера]:[Порт для стены(docker-compose.yml)]/?user=obs2
- Для стены используется обратный прокси, поэтому не нужно пробрасывать все порты 300**. Достаточно пробросить порт стены в интернет.
- Раз в 3600 секунд страница стены обновляется, в этот момент пользователи могут жаловаться на это. Периодические обновления нужны для предотвращения зависания изображения.
- Если камеры по какой-то причине не доступны, сайт будет обновляться раз в минуту, пока камеры не заработают.

## VI Обновление  
Перед обновлением проверить наличие резервной копии базы текущей версии в папке backup!  
Релизные версии идут через одну: 34 => 36 => 38(еще не вышла)...  
Для обновления нужно изменить версию в файле [docker-compose.yml](/docker-compose.yml). Это установит соответствующую версию в контейнер при сборке, но версия базы останется старой. Для её обновлерия нужно из контейнера запустить скрипт.  
```
docker exec -it zoneminder /bin/bash  
find / -name  zmupdate.pl  
```
выполнить скрипт обновления:  
```
/usr/bin/zmupdate.pl -nointeractive  
```
#### Баги  
После обновления камеры не записывают и не работают. Ошибки в логах могут быть разные.  
Исправить эту ошибку при переходе с 34-й на 36-ю версию не удалось. Пришлось заново настраивать базу.



