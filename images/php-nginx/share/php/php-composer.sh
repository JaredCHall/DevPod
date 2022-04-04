#!/bin/bash
set -euo pipefail

trigger_error() { echo "[ERROR] $1" >&2; exit 1; }

#https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    trigger_error 'Invalid installer checksum'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php || trigger_error "composer installation failed"

mv composer.phar /usr/local/bin/composer
rm composer-setup.php

# sanity check
composer --version | grep -qE "^Composer version [0-9]+[.][0-9]+[.][0-9]+" || trigger_error "sanity check! composer installation failed"
