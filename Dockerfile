FROM ubuntu:20.04 as zoneminder

# Переменные
ARG TZ=Europe/Moscow
ENV TZ $TZ
ARG LANG=en_US
ENV LANG $LANG
ENV LANGUAGE $LANG

ARG ZM_VERSION=1.36
ENV ZM_VERSION $ZM_VERSION

ARG SHEDULE="0 0 1 */1 *"
ENV SHEDULE $SHEDULE

ARG MYSQL_PORT=3306
ENV MYSQL_PORT $MYSQL_PORT

ARG HTTPS_PORT=443
ENV HTTPS_PORT $HTTPS_PORT

# Установка локали 
RUN apt update && apt-get install -yq --no-install-recommends locales software-properties-common && \
  localedef -i $LANG -c -f UTF-8 -A /usr/share/locale/locale.alias $LANG.UTF-8 && \
  apt install -yq  tzdata
ENV LANG $LANG.utf8
ENV LANGUAGE $LANG

# Установка ZONEMINDER
RUN set -eux; \
  apt install --assume-yes --no-install-recommends gnupg cron v4l-utils iproute2; \
  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABE4C7F993453843F0AEB8154D0BF748776FFB04 \
  && echo deb http://ppa.launchpad.net/iconnor/zoneminder-$ZM_VERSION/ubuntu $(cat /etc/os-release | grep  UBUNTU_CODENAME= | sed 's/UBUNTU_CODENAME=//g') main > /etc/apt/sources.list.d/zoneminder.list \
  && apt update; \
  DEBIAN_FRONTEND=noninteractive apt install --assume-yes zoneminder; \
  a2enconf zoneminder \
  && a2enmod rewrite cgi ssl headers expires \
  && a2ensite default-ssl.conf; \
  adduser www-data video; \
  chmod 740 /etc/zm/zm.conf \
  && chown root:www-data /etc/zm/zm.conf \
  && chown -R www-data:www-data /usr/share/zoneminder/; \
  mkdir /init && mkdir /backup && mkdir /cron && mkdir /var/www/wall && mkdir /cert; \
  echo -e "#!/bin/sh -e\nchmod 777 /dev/video*\nv4l2-ctl -d /dev/video0 -s PAL\nv4l2-ctl -d /dev/video1 -s PAL\nv4l2-ctl -d /dev/video2 -s PAL\nv4l2-ctl -d /dev/video3 -s PAL\nexit 0" > /root/fix.sh
# Далее нужно пробросить устройства в контейнер, но возможности протестировать нет
COPY ./custom_http.conf /etc/apache2/sites-available/000-default.conf
COPY ./custom_https.conf /etc/apache2/sites-available/default-ssl.conf
COPY ./ports.conf /etc/apache2/ports.conf

# Установка стены
RUN apt install -y curl jq php-curl; \
  a2enmod proxy \
  && a2enmod proxy_http \
  && a2enmod proxy_ajp \
  && a2enmod rewrite \
  && a2enmod deflate \
  && a2enmod headers \
  && a2enmod proxy_balancer \
  && a2enmod proxy_connect \
  && a2enmod proxy_html

# Setup Volumes
VOLUME /datastorage1 /datastorage2 /datastorage3 /datastorage4 /var/cache/zoneminder/images /init /backup /cron /var/lib/mysql /var/log/zm /etc/ssl/common/ /var/www/wall/ /cert/ /var/log/apache2/

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


