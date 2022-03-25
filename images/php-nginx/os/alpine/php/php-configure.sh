#!/bin/bash
set -euo pipefail

# Validate expected arguments
version="${1-}"
test -n "$version" || (echo "ERROR: build-arg PHP_VERSION not provided" >&2 && exit 1)

# create the php error log
#touch /var/log/nginx/php-fpm.www.log
#chown nginx:nginx /var/log/nginx/php-fpm.www.log
#chmod 660 /var/log/nginx/php-fpm.www.log
#chmod +x /var/log/nginx

# backup original conf files
mkdir -p /container/defaults/php
cp -r /etc/${version}/* /container/defaults/php/

# copy the build's conf files to generic php conf directory
mkdir /etc/php
cp -r php-etc/* /etc/php/
cp -r /etc/${version}/conf.d /etc/php # copy enabled php extensions as these are frequently changed and a static conf would be bad

# replace conf directory compiled into php by package manager with symlink
rm -r /etc/${version}
ln -s /etc/php /etc/${version}

# link php and php-fpm binaries to version-less names
[[ "php8" = "${version}" ]] && ln -s /usr/bin/${version} /usr/bin/php
ln -s /usr/sbin/php-fpm${version: -1} /usr/sbin/php-fpm