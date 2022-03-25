#!/bin/bash

[[ -z "${1-}" ]] && trigger_error "No OS argument passed";

BUILD_ARGS=('MARIADB_VERSION' 'MARIADB_USER' 'MARIADB_PASS')

MARIADB_USER='db_admin'
MARIADB_PASS='734LCaws3pnKdFbykZLefF31N8vrU2oA'

case "${1}" in
    alpine)
        MARIADB_VERSION="stable    # only latest stable is supported from os repository"
    ;;
    debian)
        MARIADB_VERSION='10.7.3  # full version number -installs from mariadb.com official repository'
    ;;
esac