#!/bin/bash
set -euo pipefail

# Validate expected arguments
version="${1-}"
test -n "$version" || (echo "ERROR: build-arg MYSQL_VERSION not provided" >&2 && exit 1)

# enable mysql.com apt repository (https://dev.mysql.com/doc/mysql-apt-repo-quick-guide/en/)
apt-get install -y --no-install-recommends lsb-release wget gnupg ca-certificates
wget -O mysql-apt-config.deb https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb
debconf-set-selections <<< "mysql-apt-config mysql-apt-config/select-server select mysql-${version}"
DEBIAN_FRONTEND=noninteractive dpkg --install mysql-apt-config.deb
apt-get update

# Use no password to enable root login by unix socket
debconf-set-selections <<< 'mysql-community-server mysql-community-server/root-pass password '
debconf-set-selections <<< 'mysql-community-server mysql-community-server/re-root-pass password '
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mysql-server

# remove unnecessary packages/files
apt-get remove -y wget gnupg lsb-release
apt-get autoremove -y --purge
rm -rf /var/lib/apt/lists/*