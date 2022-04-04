#!/bin/bash
set -euo pipefail

trigger_error() { echo "[ERROR] $1" >&2; exit 1; }

### VALIDATE VERSION ###
test -n "${NGINX_VERSION}" || trigger_error "ERROR: build-arg NGINX_VERSION not provided"
echo "${NGINX_VERSION}" | grep -qE "^[0-9]+[.][0-9]+[.][0-9+]$" || trigger_error "Invalid NGINX version '${NGINX_VERSION}'. Must be a full version number such as 1.20.2"

# download/unpack pcre source files
curl -sL https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.gz/download > pcre.tar.gz
mkdir pcre
tar -xzf pcre.tar.gz --strip-components=1 --directory pcre

# download/unpack zlib source files
curl -sL https://zlib.net/zlib-1.2.12.tar.gz > zlib.tar.gz
mkdir zlib
tar -xzf zlib.tar.gz --strip-components=1 --directory zlib

# download/unpack nginx source files
echo "downloading NGINX version ${NGINX_VERSION} from nginx.com"
curl -sL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" > nginx.tar.gz
mkdir nginx
tar -xzf nginx.tar.gz --strip-components=1 --directory nginx