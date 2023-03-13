#!/bin/sh
trap "exit" SIGINT
trap "exit" SIGTERM


echo "# Starting Dockcheck-web #"
echo "# Checking for new updates #"
echo "# This might take a while, it depends on how many containers are running #"

if [ -n "$HOSTNAME" ]; then
        echo $HOSTNAME > /etc/hostname
fi
if [ -n "$CRON_TIME" ]; then
    
    hour=$(echo $CRON_TIME | grep -Po "\d*(?=:)")
    minute=$(echo $CRON_TIME | grep -Po "(?<=:)\d*")
    echo -e "\n$minute  $hour   *   *   *   run-parts /etc/periodic/daily" >> /app/root
    else
    echo -e "\n30 12  *   *   *   run-parts /etc/periodic/daily" >> /app/root 
fi
if [ "$NOTIFY" = "true" ]; then
    if [ -n "$NOTIFY_URLS" ]; then
        echo $NOTIFY_URLS > /app/NOTIFY_URLS
        echo "Notify activated"
    fi
    if [ -n "$EXCLUDE" ]; then
    echo $EXCLUDE > /app/EXCLUDE
    fi
    if [ "$NOTIFY_DEBUG" = "true" ]; then
        echo $NOTIFY_DEBUG > /app/NOTIFY_DEBUG
        echo "NOTIFY DEBUGMODE ACTIVATED"  
    fi
fi
chmod +x /app/postgres
/app/postgres > /dev/null 2>&1
touch /var/www/update.txt
cp /app/root /etc/crontabs/root
cp /app/php.ini /etc/php7/php.ini
cd /app && tar xzvf /app/docker.tgz > /dev/null 2>&1 && cp /app/docker/* /usr/bin/ > /dev/null 2>&1
rm /app/docker.tgz
mkdir -p /run/lighttpd/
chown www-data. /run/lighttpd/
cp /app/src/index.php /var/www/index.php
cp /app/src/style.css /var/www/style.css
cp /app/src/update.php /var/www/update.php
cp /app/src/jquery.js /var/www/jquery.js
chmod +x /app/dockcheck*
chmod +x /app/regctl
mv /app/regctl /usr/bin/regctl
cp /app/dockcheck /etc/periodic/daily
chmod +x /app/watcher.sh
/app/watcher.sh </dev/null >/dev/null 2>&1 &
chown -R www-data:www-data /var/www/*
rc-service crond start && rc-update add crond
rm -rf /etc/crontabs/root
cp /app/root /etc/crontabs/root
crond -b
php-fpm7 -D
/app/dockcheck
exec lighttpd -D -f /etc/lighttpd/lighttpd.conf 