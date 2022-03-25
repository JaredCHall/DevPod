#!/bin/bash

[[ -z "${1-}" ]] && trigger_error "No OS argument passed";

BUILD_ARGS=('COMPOSER' 'PHP_VERSION')

COMPOSER="1          # 0 or 1  -indicates if composer should be installed"

case "${1}" in
    alpine)
        PHP_VERSION="php8    # php7 or php8 -installs from alpine repository"
    ;;
    debian)
        PHP_VERSION='8.0.17  # full version number -installs from source'
    ;;
esac