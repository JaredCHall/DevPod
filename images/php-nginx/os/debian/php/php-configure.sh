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
    # find the elusive versioned conf directory
    conf_dir_name=$(ls -1 /etc/php | grep -E '^[0-9]+[.][0-9]+$')
    test -z "${conf_dir_name}" && trigger_error "expected versioned conf dir at /etc/php/[version]"

    # backup original conf files
    mkdir -p /container/defaults/php
    cp -r "/etc/php/${conf_dir_name}/"* /container/defaults/php/

    # copy the build conf files
    rm -r /etc/php;
    mkdir /etc/php
    cp -r php-etc/* /etc/php/

    # copy debian-provided module confs
    rm /etc/php/php.d/*
    cp /container/defaults/php/mods-available/* /etc/php/php.d

    # fix debian configuration hell
    # Debian: let's take a nice clean conf pattern from source and mangle it into sheer confusion
    mkdir -p "/etc/php/${conf_dir_name}/cli/"
    mkdir -p "/etc/php/${conf_dir_name}/fpm/"
    ln -s /etc/php/php.ini "/etc/php/${conf_dir_name}/cli/php.ini"
    ln -s /etc/php/php.ini "/etc/php/${conf_dir_name}/fpm/php.ini"
    ln -s /etc/php/php.d "/etc/php/${conf_dir_name}/cli/conf.d"
    ln -s /etc/php/php.d "/etc/php/${conf_dir_name}/fpm/conf.d"
    ln -s /etc/php/php-fpm.conf "/etc/php/${conf_dir_name}/fpm/php-fpm.conf"

}



main "$@"