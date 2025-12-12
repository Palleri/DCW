#!/bin/sh
set -e

trap "exit 0" SIGINT SIGTERM

echo "# Starting Dockcheck-web #"
echo "# Checking for new updates #"
echo "# This might take a while, it depends on how many containers are running #"

# Load default cron root
cp /app/root /etc/crontabs/root

# Set hostname if provided
[ -n "$HOSTNAME" ] && echo "$HOSTNAME" > /etc/hostname

# Cron time parsing
if [ -n "$CRON_TIME" ]; then
    hour="${CRON_TIME%:*}"
    minute="${CRON_TIME#*:}"
else
    hour="12"
    minute="30"
fi
printf "\n%s %s * * * run-parts /etc/periodic/daily\n" "$minute" "$hour" >> /etc/crontabs/root

# Notification settings
if [ "$NOTIFY" = "true" ]; then
    [ -n "$NOTIFY_URLS" ] && printf "%s" "$NOTIFY_URLS" > /app/NOTIFY_URLS && echo "Notify activated"
    [ "$NOTIFY_DEBUG" = "true" ] && printf "%s" "$NOTIFY_DEBUG" > /app/NOTIFY_DEBUG && echo "NOTIFY DEBUGMODE ACTIVATED"
fi

[ -n "$EXCLUDE" ] && printf "%s" "$EXCLUDE" > /app/EXCLUDE

# Initialize Postgres (suppress errors)
[ -x /app/postgres ] && /app/postgres >/dev/null 2>&1 || true

# Start cron in background
crond -b

# Start PHP-FPM
php-fpm83 -D

# Start watcher in background
/app/watcher.sh </dev/null >/dev/null 2>&1 &

# Run dockcheck once
[ -x /app/dockcheck ] && /app/dockcheck

# Start lighttpd in foreground
exec lighttpd -D -f /etc/lighttpd/lighttpd.conf
