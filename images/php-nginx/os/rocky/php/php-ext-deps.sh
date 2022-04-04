#!/bin/bash
set -euo pipefail

dnf install -y openssl-devel \
               zlib-devel \
               libxml2-devel \
               oniguruma-devel \
               sqlite-devel \
               libcurl-devel \
               bzip2-devel
