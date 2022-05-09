### NGINX ###
FROM base as nginx

WORKDIR /tmp/

ARG NGINX_VERSION=1.20.2
ENV NGINX_VERSION="${NGINX_VERSION}"

COPY nginx/nginx-build-deps.sh ./
RUN ./nginx-build-deps.sh

COPY nginx/nginx-tarball.sh ./
RUN ./nginx-tarball.sh

COPY nginx/nginx-compile.sh ./
RUN ./nginx-compile.sh

ADD nginx/etc /etc/nginx

### PHP ###
FROM base as php

WORKDIR /tmp/

ARG PHP_VERSION=8.1.4
ENV PHP_VERSION="${PHP_VERSION}"

COPY php/php-build-deps.sh ./
RUN ./php-build-deps.sh

COPY php/php-tarball.sh ./
RUN ./php-tarball.sh

COPY php/php-ext-deps.sh ./
RUN ./php-ext-deps.sh

COPY php/php-compile.sh ./
RUN ./php-compile.sh

COPY php/php-shared-objects.sh ./
RUN ./php-shared-objects.sh "BACKUP"

ADD php/etc /etc/php



### php-nginx ###
FROM base as php-nginx

# Copy php/nginx
COPY --from=nginx /opt/nginx/ /opt/nginx/
COPY --from=nginx /etc/nginx/ /etc/nginx/
COPY --from=php /opt/php/ /opt/php/
COPY --from=php /etc/php/ /etc/php/

# Copy shared libraries php depends on
COPY --from=php /root/php-lib/ /root/php-lib/
COPY php/php-shared-objects.sh ./
RUN ./php-shared-objects.sh "RESTORE"

# Create sym links
RUN ln -s /opt/php/bin/php /usr/bin/php; \
    ln -s /opt/php/sbin/php-fpm /usr/sbin/php-fpm; \
    ln -s /opt/nginx/sbin/nginx /usr/sbin/nginx;

RUN useradd -r -s /sbin/nologin nginx; \
    mkdir -p /var/log/nginx; \
    chown -R nginx:nginx /var/log/nginx; \
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log; \
    mkdir -p /var/www/public; \
    chown -R nginx:nginx /var/www;

### COMPOSER ###
FROM php-nginx as with-composer

WORKDIR /tmp/

ENV COMPOSER_ALLOW_SUPERUSER=1
COPY php/php-composer.sh ./
RUN ./php-composer.sh

FROM with-composer as final

WORKDIR /var/www/
COPY start.sh /root/
ENTRYPOINT [ "/root/start.sh" ]