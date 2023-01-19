#!/bin/bash
set -euo pipefail

main()
{
  expose_conf
  # Trap to ensure we get a safe shutdown
  trap 'mariadb-admin shutdown; exit 0' HUP INT QUIT TERM
  mariadbd --user=mysql & wait "$!"
}

expose_conf()
{
  # Expose configuration to host
  if [ -d /container/etc/mysql ]; then
    cp -ru /etc/mysql/* /container/etc/mysql/ > /dev/null 2>&1 || true # cp -u exits non-zero even when it behaves exactly as expected
    rm -rf /etc/mysql
    ln -s /container/etc/mysql /etc/mysql
  fi

  # Expose default configuration to host
  if [ -d /container/etc/mysql.defaults ]; then
    cp -r /container/defaults/mysql/* /container/etc/mysql.defaults
  fi
}

main

