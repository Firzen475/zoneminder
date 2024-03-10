#!/bin/bash
# Общие настройки > начало
init_config(){
        echo "TZ $TZ"
        chmod -R 777 /datastorage*
        if [ -d "/var/lib/mysql" ]; then
                chown -R mysql:mysql /var/lib/mysql/
        fi
        rm -f /var/lib/mysql/ib_logfile* > /dev/null 2>&1 &
        sed -i 's/ZM_DB_HOST=localhost/ZM_DB_HOST=127.0.0.1:'${MYSQL_PORT}'/g' /etc/zm/zm.conf
        for FILE in "/etc/php/7.4/apache2/php.ini" "/etc/php/7.2/apache2/php.ini" "/etc/php/7.0/apache2/php.ini" "/etc/php5/apache2/php.ini" "/etc/php.ini" "/usr/local/etc/php.ini"; do
                if [ -f $FILE ]; then
                        echo "date.timezone = $TZ" >> $FILE;
                        break
                fi
        done
   # Set the php-fpm socket owner
    if [ -e /etc/php-fpm.d/www.conf ]; then
        mkdir -p /var/run/php-fpm

        sed -E 's/^;(listen.(group|owner) = ).*/\1apache/g' /etc/php-fpm.d/www.conf | \
            sed -E 's/^(listen\.acl_users.*)/;\1/' > /etc/php-fpm.d/www.conf.n

        if [ $? -ne 0 ]; then
            echo
            echo " * Unable to update php-fpm file"
            exit 95
        fi

        mv -f /etc/php-fpm.d/www.conf.n /etc/php-fpm.d/www.conf
    fi
        sed -i 's/^Define port .*/Define port '${HTTPS_PORT}'/I' /etc/apache2/sites-available/000-default.conf
        chmod 777 /cert/zoneminder.*
	chown -R www-data:www-data /var/www/*
}
# Общие настройки > конец
# Настройки базы > начало
zm_db_exists() {
    mysqlshow zm > /dev/null 2>&1
    RETVAL=$?
    if [ "$RETVAL" = "0" ] && [ -f "/var/lib/mysql/zm/Config.ibd" ] ; then
        echo "1" # ZoneMinder database exists
    else
        echo "0" # ZoneMinder database does not exist
    fi
}

mysql_running () {
    mysqladmin ping > /dev/null 2>&1
    local result="$?"
    if [ "$result" -eq "0" ]; then
        echo "1" # mysql is running
    else
        echo "0" # mysql is not running
    fi
}

mysql_timer () {
    timeout=60
    count=0
    while [ "$(mysql_running)" -eq "0" ] && [ "$count" -lt "$timeout" ]; do
        sleep 1 # Mysql has not started up completely so wait one second then check again
        count=$((count+1))
    done

    if [ "$count" -ge "$timeout" ]; then
       echo " * Warning: Mysql startup timer expired!"
    fi
}

init_database(){
    if [ "$CLEAR_DB" = 'true' ]; then
        echo "clear database. CLEAR_DB=$CLEAR_DB";
        rm -rfd /var/lib/mysql/*
        mysqld --initialize-insecure
    fi
    mysqld_safe --user=mysql --timezone="$TZ" --port=${MYSQL_PORT} > /dev/null 2>&1 &
    mysql_timer
    # Look in common places for the zoneminder dB creation script - zm_create.sql
    for FILE in "/usr/share/zoneminder/db/zm_create.sql" "/usr/local/share/zoneminder/db/zm_create.sql"; do
        if [ -f $FILE ]; then
            ZMCREATE=$FILE
            break
        fi
    done
    echo "ZMCREATE $ZMCREATE"
    if [ "$(zm_db_exists)" -eq "0" ]; then
        echo " * First run of mysql in the container, creating ZoneMinder dB."
        if [ -d "/var/lib/mysql/zm/" ]; then
                rm -rf /var/lib/mysql/zm/
        fi
		mysql -u root -e "CREATE USER 'zmuser'@'localhost' IDENTIFIED WITH mysql_native_password BY 'zmpass';"
		mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'zmuser'@'localhost';"
		mysql -u root < $ZMCREATE
		mysql -u root zm < /init/dump.sql || true
        else
        echo " * ZoneMinder dB already exists, skipping table creation."
    fi
}
# Настройки базы > конец

_start_cron(){
        echo "_start_cron"
	/etc/init.d/cron start
	touch /var/log/cron.log
	if [ -f /cron/cronjob ]; then
                sed -i -e "s:\[SHEDULE\]:$SHEDULE:I" /cron/cronjob
                sed -i -e "s:\[OBSERVER1\]:$OBSERVER1:I" /cron/onStart.sh
                sed -i -e "s:\[OBSERVER_PASSWORD1\]:$OBSERVER_PASSWORD1:I" /cron/onStart.sh
                sed -i -e "s:\[OBSERVER2\]:$OBSERVER2:I" /cron/onStart.sh
                sed -i -e "s:\[OBSERVER_PASSWORD2\]:$OBSERVER_PASSWORD2:I" /cron/onStart.sh
                sed -i -e "s:\[OBSERVER1\]:$OBSERVER1:I" /cron/onRefresh.sh
                sed -i -e "s:\[OBSERVER_PASSWORD1\]:$OBSERVER_PASSWORD1:I" /cron/onRefresh.sh
                sed -i -e "s:\[OBSERVER2\]:$OBSERVER2:I" /cron/onRefresh.sh
                sed -i -e "s:\[OBSERVER_PASSWORD2\]:$OBSERVER_PASSWORD2:I" /cron/onRefresh.sh
		crontab -u root /cron/cronjob
		crontab -l
	fi
}
# Запуск cron > конец

start_zoneminder(){
        /usr/bin/zmpkg.pl start
}



init_config

init_database

start_zoneminder

_start_cron

/etc/init.d/apache2 start

tail -f /var/log/cron.log

