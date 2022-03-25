#!/bin/bash
set -euo pipefail

# backup original conf files
mkdir -p /container/defaults/nginx
mv /etc/nginx/* /container/defaults/nginx/

# copy the build conf files
cp -r nginx-etc/* /etc/nginx/

# link nginx logs to stdout and stderr
# as per official docker image: https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log

# make the public www directory
mkdir -p /var/www/public
chown -R nginx:nginx /var/www/public