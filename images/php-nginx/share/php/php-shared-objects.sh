#!/bin/bash
set -euo pipefail

readarray -t extensions < <(ldd /opt/php/bin/php | grep -oE "[/]lib64[/]lib[^ ]+");

mkdir /root/php-lib
for file in "${extensions[@]}"; do
    cp $file /root/php-lib
done
