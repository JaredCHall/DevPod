#!/bin/bash
set -euo pipefail

cd php

mkdir /etc/php
mkdir /etc/php/php.d

./configure --prefix=/opt/php \
            --with-config-file-path=/etc/php \
            --with-config-file-scan-dir=/etc/php/php.d \
            --sysconfdir=/etc/php \
            --enable-fpm \
            --with-fpm-user=phpd \
            --with-fpm-group=phpd \
            --enable-bcmath \
            --enable-mbstring \
            --with-openssl \
            --with-pdo-mysql=mysqlnd \
            --with-zlib \
            --enable-opcache \
            --enable-pcntl \
            --with-curl \
            --enable-exif \
            --enable-calendar \
            --with-bz2


cores=$(nproc)
make -j${cores}
make install

# link installed bins & confs to standard locations
ln -s /opt/php/bin/php /usr/bin/php
ln -s /opt/php/sbin/php-fpm /usr/sbin/php-fpm

# enable the default conf files
cp ./php.ini-development /etc/php/php.ini
mv /etc/php/php-fpm.conf.default /etc/php/php-fpm.conf
mv /etc/php/php-fpm.d/www.conf.default /etc/php/php-fpm.d/www.conf
