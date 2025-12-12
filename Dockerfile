FROM alpine:3.21

ARG TARGETPLATFORM

ENV NOTIFY="" \
    NOTIFY_DEBUG="" \
    NOTIFY_URLS="" \
    EXCLUDE="" \
    CRON_TIME="" \
    TOKEN=""

# Copy application files
COPY app* /app/

# Detect architecture for Docker CLI + regctl download
RUN case "${TARGETPLATFORM}" in \
        "linux/amd64")  os="amd64";   dockeros="x86_64"  ;; \
        "linux/arm64")  os="arm64";   dockeros="aarch64" ;; \
        *) echo "Unsupported TARGETPLATFORM: ${TARGETPLATFORM}" && exit 1 ;; \
    esac \
    \
    # Download Docker CLI and regctl for the detected architecture
    && wget "https://download.docker.com/linux/static/stable/${dockeros}/docker-29.0.4.tgz" -O /app/docker.tgz \
    && wget "https://github.com/regclient/regclient/releases/download/v0.10.0/regctl-linux-${os}" -O /app/regctl \
    \
    # Install required system packages
    && apk add --no-cache \
        lighttpd \
        bash \
        curl \
        vim \
        python3 \
        inotify-tools \
        grep \
        php-common \
        php-fpm \
        php-pgsql \
        php-mysqli \
        php-curl \
        php-cgi \
        fcgi \
        php-pdo \
        php-pdo_pgsql \
        postgresql \
    \
    # Create www-data user
    && adduser www-data -G www-data -H -s /bin/bash -D

# Prepare web directory
RUN mkdir -p /var/www \
    && touch /var/www/update.txt \
    && cp /app/php.ini /etc/php83/php.ini \
    && cp /app/src/* /var/www/ \
    && chown -R www-data:www-data /var/www/ \
    && mkdir -p /run/lighttpd/ \
    && chown www-data:www-data /run/lighttpd/

# Docker CLI extraction
RUN mkdir -p /app/docker_extract \
    && tar -xzf /app/docker.tgz -C /app/docker_extract --strip-components=1 \
    && cp /app/docker_extract/* /usr/bin/ \
    && rm -f /app/docker.tgz \
    && rm -rf /app/docker_extract

# Python venv and apprise
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir apprise \
    && ln -s /opt/venv/bin/apprise /usr/local/bin/apprise

# Make scripts executable and copy executables
RUN chmod +x /app/regctl /app/dockcheck /app/watcher.sh /app/postgres /app/entrypoint.sh \
    && cp /app/regctl /usr/bin/ \
    && cp /app/dockcheck /etc/periodic/daily

# Lighttpd configuration
COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

EXPOSE 80

# Entrypoint
ENTRYPOINT [ "/app/entrypoint.sh" ]
