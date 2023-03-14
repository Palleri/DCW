#!/bin/bash
while inotifywait -e modify /var/www/*.txt ; do
        update=$(</var/www/update.txt)
        if [ $update == "1" ]; then
        run-parts /etc/periodic/daily/
        echo 0 > /var/www/update.txt
        elif [ -s "/var/www/upgrade.txt"]; then
        continue
        else
        container=$(</var/www/upgrade.txt)
        /usr/bin/python3 /app/dockerpull.py --container $container
        echo "1" > /var/www/upgrade.txt
        chown www-data:www-data /var/www/upgrade
        fi
done
