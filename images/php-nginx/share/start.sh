#!/bin/bash
set -euo pipefail

main()
{
  expose_conf
  start

  trap 'kill ${!}; shutdown; exit 0' HUP INT QUIT TERM
  sleep infinity & wait ${!}
}

start()
{
  # Start services as daemons
  echo "Starting services..."
  php-fpm -R
  nginx

  sleep 1 # give daemons a second to spin up

  php_pid=$(sed 's/[^0-9]*//g' /run/php-fpm.pid)
  nginx_pid=$(sed 's/[^0-9]*//g' /run/nginx.pid)
  echo "php-fpm master process started with pid ${php_pid}"
  echo "nginx master process started with pid ${nginx_pid}"
}

shutdown()
{
  echo "stopping services..."
  nginx -s stop
  sleep 1
  kill -QUIT ${php_pid}
  sleep 1
  echo "Shutdown Complete"
  exit 0
}

expose_conf()
{
  # Expose configurations to host
  if [ -d /container/etc/nginx ]; then
    cp -ru /etc/nginx/* /container/etc/nginx/ > /dev/null 2>&1 || true # cp -u exits non-zero even when it behaves exactly as expected
    rm -rf /etc/nginx
    ln -s /container/etc/nginx /etc/nginx
  fi

  if [ -d /container/etc/php ]; then
    cp -ru /etc/php/* /container/etc/php/ > /dev/null 2>&1 || true # cp -u exits non-zero even when it behaves exactly as expected
    rm -rf /etc/php
    ln -s /container/etc/php /etc/php
  fi

  # Expose default configuration to host
  if [ -d /container/etc/nginx.defaults ]; then
    cp -r /container/defaults/nginx/* /container/etc/nginx.defaults
  fi

  if [ -d /container/etc/php.defaults ]; then
    cp -r /container/defaults/php/* /container/etc/php.defaults
  fi

}

main

