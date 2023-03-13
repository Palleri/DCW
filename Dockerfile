FROM alpine:3.15
ARG TARGETPLATFORM
ENV NOTIFY="" \
NOTIFY_DEBUG="" \
NOTIFY_URLS="" \
EXCLUDE="" \
CRON_TIME="" \
TOKEN=""
COPY app* /app/ 
RUN case ${TARGETPLATFORM} in \
         "linux/amd64")  os=amd64  ;; \
         "linux/arm64")  os=arm64  ;; \
    esac \
&& case ${TARGETPLATFORM} in \
         "linux/amd64")  dockeros=x86_64  ;; \
         "linux/arm64")  dockeros=aarch64  ;; \
    esac \
&& wget "https://download.docker.com/linux/static/stable/${dockeros}/docker-23.0.1.tgz" -O /app/docker.tgz \
&& wget "https://github.com/regclient/regclient/releases/download/v0.4.7/regctl-linux-${os}" -O /app/regctl \
&& apk --update add --no-cache \
    lighttpd \
    bash \
    curl \
    busybox-initscripts \
    openrc \
    vim \
    py-pip \
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
    && rm -rf /var/cache/apk/* \
&& adduser www-data -G www-data -H -s /bin/bash -D \
&& pip install --no-cache-dir apprise docker
ADD lighttpd.conf /etc/lighttpd/lighttpd.conf 

EXPOSE 80
#VOLUME /var/www



ENTRYPOINT [ "/app/entrypoint.sh" ]
