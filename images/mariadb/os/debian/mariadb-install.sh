#!/bin/bash
set -euo pipefail

# Validate expected arguments
version="${1-}"
test -n "$version" || (echo "ERROR: build-arg MARIADB_VERSION not provided" >&2 && exit 1)

# Install mariadb repository
apt-get install -y --no-install-recommends software-properties-common gnupg apt-transport-https
apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
add-apt-repository "deb [arch=amd64,i386,arm64,ppc64el] https://archive.mariadb.org/mariadb-${version}/repo/debian/ bullseye main"
apt-get update

#install mariadb
apt-get install -y --no-install-recommends mariadb-server

# remove unnecessary packages/files
apt-get remove -y software-properties-common gnupg apt-transport-https
apt-get autoremove -y --purge
rm -rf /var/lib/apt/lists/*

