#!/bin/bash
set -euo pipefail

# Validate expected arguments
version="${1-}"
test -n "$version" || (echo "ERROR: build-arg MARIADB_VERSION not provided" >&2 && exit 1)
echo "${version}" | grep -E "^[0-9]+[.][0-9]+$" || (echo "ERROR: invalid version, expected format (10.6, 10.7, 10.8, etc.). Version provided: '${version}'" >&2; exit 1)
status=$(curl -Is "https://mirror.rackspace.com/mariadb/yum/${version}/rhel8-amd64/" | head -n1 | cut -d ' ' -f2)
test "200" = "${status}" || (echo "ERROR: version '${version}' does not exist on the rackspace mariadb mirror" >&2; exit 1)

echo "# MariaDB ${version} RedHat repository list
# https://mariadb.org/download/
[mariadb]
name = MariaDB
baseurl = https://mirror.rackspace.com/mariadb/yum/${version}/rhel8-amd64
module_hotfixes=1
gpgkey=https://mirror.rackspace.com/mariadb/yum/RPM-GPG-KEY-MariaDB
gpgcheck=1
" > /etc/yum.repos.d/MariaDB.repo

dnf install -y MariaDB-server

