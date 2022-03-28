#!/bin/bash
set -euo pipefail

# create the php error log
#touch /var/log/nginx/php-fpm.www.log
#chown www-data:www-data /var/log/nginx/php-fpm.www.log
#chmod 660 /var/log/nginx/php-fpm.www.log
#chmod +x /var/log/nginx

# backup original conf files
mkdir -p /container/defaults/php
mv /etc/php/* /container/defaults/php/

# copy the build conf files
cp -r php-etc/* /etc/php/
