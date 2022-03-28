#!/bin/bash
set -euo pipefail

# Exit 0, if image not configured to install composer
[[ '1' != "${1-}" ]] && exit 0

#https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    >&2 echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
mv composer.phar /usr/local/bin/composer
RESULT=$?
rm composer-setup.php
# Add line to .bashrc to prevent composer complaining when run as root
echo "export COMPOSER_ALLOW_SUPERUSER=1" >> /root/.bashrc
exit $RESULT