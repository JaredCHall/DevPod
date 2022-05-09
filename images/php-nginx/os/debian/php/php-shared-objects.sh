#!/bin/bash
set -euo pipefail

trigger_error() { echo "[ERROR] $1" >&2; exit 1; }

### VALIDATE VERSION ###
test -n "${1}" || trigger_error "Argument required"
echo "${1}" | grep -qE "^BACKUP|RESTORE$" || trigger_error "Invalid argument: must be BACKUP or RESTORE"

if [[ "BACKUP" == "${1}" ]]; then

   readarray -t extensions < <(ldd /opt/php/bin/php | grep -oE " [/]lib[/]x86_64-linux-gnu[^ ]+");
   mkdir -p /root/php-lib/usr/lib/x86_64-linux-gnu
   mkdir -p /root/php-lib/lib/x86_64-linux-gnu
   for file in "${extensions[@]}"; do
       cp -L $file /root/php-lib/lib/x86_64-linux-gnu
   done
   readarray -t extensions < <(ldd /opt/php/bin/php | grep -oE " [/]usr[/]lib[/]x86_64-linux-gnu[^ ]+");
   for file in "${extensions[@]}"; do
       cp -L $file /root/php-lib/usr/lib/x86_64-linux-gnu
   done

elif [[ "RESTORE" == "${1}" ]]; then
    cp /root/php-lib/lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu
    cp /root/php-lib/usr/lib/x86_64-linux-gnu/* /usr/lib/x86_64-linux-gnu
fi