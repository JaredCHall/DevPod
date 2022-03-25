#!/bin/bash
set -euo pipefail

trigger_error() {
  echo "ERROR: $1" >&2; exit 1;
}



### VALIDATE VERSION ###
version="${1-}"
test -n "$version" || trigger_error "ERROR: build-arg PHP_VERSION not provided"

#install jq for easy json parsing
apt-get install -y --no-install-recommends jq curl

# download source metadata
echo "downloading PHP version $version from php.net repo"
php_repo_url="https://www.php.net/releases/?json&version=$version"
php_json_metadata=$(curl -s "$php_repo_url")
echo "meta: ${php_json_metadata}"
error=$(echo "$php_json_metadata" | jq -r '.error')
test "$error" != "null" && trigger_error "[php.net repo] $error"
tarball_file_name=$(echo $php_json_metadata | jq -r ".source[0].filename")
tarball_sha256_sum=$(echo $php_json_metadata | jq -r ".source[0].sha256")
test "${tarball_file_name: -7}" != '.tar.gz' && trigger_error "could not parse filename from php.net metadata -- $php_json_metadata"
test -z $( echo "${tarball_sha256_sum}" | grep -E '^[0-9a-f]+$') && trigger_error "could not parse sha256 from php.net metadata -- $php_json_metadata"

### DEPENDENCIES ###

# Minimal dependencies
apt-get install -y --no-install-recommends autoconf \
                                           bison \
                                           build-essential \
                                           libsqlite3-dev \
                                           libxml2-dev \
                                           pkg-config \
                                           re2c


# PHP-FPM requires zlib1g-dev for --enable-fpm
# Laravel requires the following dev libaries
# libssl-dev / --with-openssl
# libonig-dev / --enable-mbstring
apt-get install -y --no-install-recommends libssl-dev \
                                           libonig-dev \
                                           zlib1g-dev

# Symfony does not require additional dev libraries

#######################
### DOWNLOAD SOURCE ###
#######################

tmp_install_dir="/tmp/php.install"
mkdir $tmp_install_dir
cd $tmp_install_dir

echo "downloading PHP tarball"

# download tarball
tarball_download_url="https://www.php.net/distributions/${tarball_file_name}"
curl -sL $tarball_download_url > $tarball_file_name
echo "downloaded $tarball_file_name"

# validate checksum
[[ $tarball_sha256_sum == $(sha256sum $tarball_file_name | cut -c1-64) ]] || trigger_error "php tarball does not match expected checksum";
echo "sha256sum verified for $tarball_file_name"

# unpack tarball
php_compile_dir="${tmp_install_dir}/php-source"
mkdir $php_compile_dir
tar -xzf $tarball_file_name --strip-components=1 --directory $php_compile_dir
[[ ! -z $(ls -AU $php_compile_dir) ]] || trigger_error "failed to unpack tarball to $php_compile_dir";
echo "tarball unpacked to $php_compile_dir"


######################
### COMPILE SOURCE ###
######################

cd $php_compile_dir

useradd -r phpd
mkdir /etc/php
mkdir /etc/php/php.d

./configure --prefix=/opt/php \
            --with-config-file-path=/etc/php \
            --with-config-file-scan-dir=/etc/php/php.d \
            --sysconfdir=/etc/php \
            --enable-fpm \
            --with-fpm-user=phpd \
            --with-fpm-group=phpd \
            --enable-bcmath \
            --enable-mbstring \
            --with-openssl \
            --with-pdo-mysql=mysqlnd \
            --with-zlib

cores=$(nproc)
make -j${cores}
make install

# link installed bins & confs to standard locations
ln -s /opt/php/bin/php /usr/bin/php
ln -s /opt/php/sbin/php-fpm /usr/sbin/php-fpm

# enable the default conf files
cp ${php_compile_dir}/php.ini-development /etc/php/php.ini
mv /etc/php/php-fpm.conf.default /etc/php/php-fpm.conf
mv /etc/php/php-fpm.d/www.conf.default /etc/php/php-fpm.d/www.conf


################
### CLEAN UP ###
################

rm -r ${tmp_install_dir}

apt-get autoremove -y --purge autoconf \
                              bison \
                              build-essential \
                              pkg-config \
                              re2c \
                              jq \
                              curl
