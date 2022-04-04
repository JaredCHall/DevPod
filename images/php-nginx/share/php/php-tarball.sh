#!/bin/bash
set -euo pipefail

trigger_error() { echo "[ERROR] $1" >&2; exit 1; }
trigger_warning() { echo "[WARNING] $1" >&2; }

### VALIDATE VERSION ###
test -n "${PHP_VERSION}" || trigger_error "ERROR: build-arg PHP_VERSION not provided"
echo "${PHP_VERSION}" | grep -qE "^[0-9]+[.][0-9]+[.][0-9+]$" || trigger_error "Invalid PHP version '${PHP_VERSION}'. Must be a full version number such as 8.0.17"

# download source metadata
echo "downloading PHP version ${PHP_VERSION} from php.net repo"
php_repo_url="https://www.php.net/releases/?json&version=${PHP_VERSION}"
php_json_metadata=$(curl -s "$php_repo_url")
echo "meta: ${php_json_metadata}"
error=$(echo "$php_json_metadata" | jq -r '.error')
test "$error" != "null" && trigger_error "[php.net repo] $error"
tarball_file_name=$(echo $php_json_metadata | jq -r ".source[0].filename")
tarball_sha256_sum=$(echo $php_json_metadata | jq -r ".source[0].sha256")
test "${tarball_file_name: -7}" != '.tar.gz' && trigger_error "could not parse filename from php.net metadata -- $php_json_metadata"
test -z $( echo "${tarball_sha256_sum}" | grep -E '^[0-9a-f]+$') && trigger_error "could not parse sha256 from php.net metadata -- $php_json_metadata"

echo "downloading PHP tarball"

# download tarball
tarball_download_url="https://www.php.net/distributions/${tarball_file_name}"
curl -sL $tarball_download_url > php.tar.gz
echo "downloaded php.tar.gz"

# validate checksum
[[ $tarball_sha256_sum == $(sha256sum php.tar.gz | cut -c1-64) ]] || trigger_error "php tarball does not match expected checksum";
echo "sha256sum verified for php.tar.gz"

# unpack tarball
mkdir php
tar -xzf php.tar.gz --strip-components=1 --directory php
echo "tarball unpacked to $(pwd)/php"