#!/bin/bash
set -euo pipefail

# Validate expected arguments
user="${1-}"
pass="${2-}"
test -n "$user" || (echo "ERROR: build-arg MARIADB_USER not provided" && exit 1)
test -n "$pass" || (echo "ERROR: build-arg MARIADB_PASS not provided" && exit 1)

# Create required dirs
mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql
mkdir -p /var/log/mysql && chown -R mysql:mysql /var/log/mysql
mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld


# backup original conf files
defaults_dir=/container/defaults/mysql
mkdir -p $defaults_dir
cp -r --no-dereference /etc/mysql/* $defaults_dir

# Remove default configurations
rm -r /etc/mysql

# Copy build conf file
mkdir -p /etc/mysql
cp my.cnf /etc/mysql

# Create the default mysql user
mariadbd-safe &
sleep 3
echo "GRANT ALL PRIVILEGES ON *.* TO '$user'@'%' IDENTIFIED BY '$pass'; FLUSH PRIVILEGES" | mysql
mariadb-tzinfo-to-sql /usr/share/zoneinfo | mysql mysql
mariadb-admin shutdown





