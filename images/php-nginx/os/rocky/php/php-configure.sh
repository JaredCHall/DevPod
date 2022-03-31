#!/bin/bash
set -euo pipefail

trigger_error() { echo "[ERROR] $1" >&2; exit 1; }
trigger_warning() { echo "[WARNING] $1" >&2; }

main()
{
    install_type="${1-}"
    test -n "${install_type}" || trigger_error "ERROR: build-arg PHP_INSTALL_TYPE not provided"

    case "${install_type}" in
        repo) configure_repo_install ;;
        source) configure_source_install ;;
        *) trigger_error "Invalid PHP_INSTALL_TYPE '${install_type}'; Must be 'repo' or 'source'" ;;
    esac
}

configure_source_install()
{
    # backup original conf files
    mkdir -p /container/defaults/php
    mv /etc/php/* /container/defaults/php/

    # copy the build conf files
    cp -r php-etc/* /etc/php/
}

configure_repo_install()
{
    # backup original conf files
    mkdir -p /container/defaults/php

    # rocky repo installs directly into /etc. what!?!
    mv /etc/php.ini /container/defaults/php
    mv /etc/php-fpm.conf /container/defaults/php
    mv /etc/php.d /container/defaults/php
    mv /etc/php-fpm.d /container/defaults/php

    # copy the build conf files
    mkdir -p /etc/php
    cp -r php-etc/* /etc/php

    # copy the repo installed php.d directory containing enabled modules
    rm -r /etc/php/php.d
    cp -r /container/defaults/php/php.d /etc/php

    # create symbolic links back to rocky's expected etc path
    ln -s /etc/php/php.ini /etc/php.ini
    ln -s /etc/php/php-fpm.conf /etc/php-fpm.conf
    ln -s /etc/php/php.d /etc/php.d
    ln -s /etc/php/php-fpm.d /etc/php-fpm.d

}

main "$@"