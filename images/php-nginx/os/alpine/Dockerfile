FROM docker.io/library/alpine:3.15

# Always upgrade to get the latest security patches
RUN apk update && apk upgrade

# Install tzdata to allow changing container timezone
RUN apk add --no-cache tzdata

# Install bash
RUN apk add --no-cache bash

#"php7" "php8"
ARG PHP_VERSION=php8

# Install somewhere easy to clean up
RUN mkdir /tmp/build-image/
WORKDIR /tmp/build-image/

# Install nginx
COPY nginx/nginx-install.sh ./
RUN ./nginx-install.sh

# Install php
COPY php/php-install.sh ./
RUN ./php-install.sh "${PHP_VERSION}"

# Configure php
COPY php/php-configure.sh ./
ADD php/etc php-etc
RUN ./php-configure.sh "${PHP_VERSION}"

# Install composer
ARG PHP_COMPOSER=1
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY php/php-composer-install.sh ./
RUN ./php-composer-install.sh ${PHP_COMPOSER}

# Configure nginx
COPY nginx/nginx-configure.sh ./
ADD nginx/etc nginx-etc
RUN ./nginx-configure.sh

# Clean up
RUN rm -r /tmp/build-image;

# Create entrypoint script
WORKDIR /var/www/
COPY start.sh /root/
ENTRYPOINT [ "/root/start.sh" ]