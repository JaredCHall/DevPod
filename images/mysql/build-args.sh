#!/bin/bash

[[ -z "${1-}" ]] && trigger_error "No OS argument passed";

BUILD_ARGS=('MYSQL_VERSION' 'MYSQL_USER' 'MYSQL_PASS')

MYSQL_USER='db_admin'
MYSQL_PASS='734LCaws3pnKdFbykZLefF31N8vrU2oA'

case "${1}" in
    debian)
        MYSQL_VERSION='8.0  # 5.7 or 8.0 -installs from dev.mysql.com official repository'
    ;;
esac