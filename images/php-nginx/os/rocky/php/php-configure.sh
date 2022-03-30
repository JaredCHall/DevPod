#!/bin/bash
set -euo pipefail

# backup original conf files
mkdir -p /container/defaults/php
mv /etc/php/* /container/defaults/php/

# copy the build conf files
cp -r php-etc/* /etc/php/
