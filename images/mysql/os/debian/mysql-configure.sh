#!/bin/bash
set -euo pipefail

# Validate expected arguments
user="${1-}"
pass="${2-}"
test -n "$user" || (echo "ERROR: build-arg MYSQL_USER not provided" && exit 1)
test -n "$pass" || (echo "ERROR: build-arg MYSQL_PASS not provided" && exit 1)

# Create required dirs
#mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql
#mkdir -p /var/log/mysql && chown -R mysql:mysql /var/log/mysql
#mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld

# backup original conf files
defaults_dir=/container/defaults/mysql
mkdir -p $defaults_dir
cp -r /etc/mysql/* $defaults_dir

# Create the default mysql user & import tzdata
mysqld_safe &
sleep 3
echo "
CREATE USER '$user'@'%' IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON *.* TO '$user'@'%';
FLUSH PRIVILEGES;" | mysql
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql
mysqladmin shutdown

# Remove default configurations
rm -r /etc/mysql

# Copy build conf file
mkdir -p /etc/mysql
cp my.cnf /etc/mysql


