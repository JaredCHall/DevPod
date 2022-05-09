#!/bin/bash
set -euo pipefail

trigger_error() { echo "[ERROR] $1" >&2; exit 1; }

### VALIDATE VERSION ###
test -n "${1}" || trigger_error "Argument required"
echo "${1}" | grep -qE "^BACKUP|RESTORE$" || trigger_error "Invalid argument: must be BACKUP or RESTORE"

if [[ "BACKUP" == "${1}" ]]; then

    readarray -t extensions < <(ldd /opt/php/bin/php | grep -oE "[/]lib64[/]lib[^ ]+");

    mkdir /root/php-lib
    for file in "${extensions[@]}"; do
        cp "${file}" /root/php-lib
    done

elif [[ "RESTORE" == "${1}" ]]; then
    cp /root/php-lib/* /lib64
fi