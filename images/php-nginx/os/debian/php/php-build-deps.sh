#!/bin/bash
set -euo pipefail

apt-get install -y --no-install-recommends jq curl

apt-get install -y --no-install-recommends autoconf \
                                               bison \
                                               build-essential \
                                               libsqlite3-dev \
                                               libxml2-dev \
                                               pkg-config \
                                               re2c
