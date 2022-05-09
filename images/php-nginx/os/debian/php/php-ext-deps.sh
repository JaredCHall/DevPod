#!/bin/bash
set -euo pipefail

apt-get install -y --no-install-recommends libssl-dev \
                                           libonig-dev \
                                           zlib1g-dev \
                                           libxml2-dev \
                                           libcurl4-openssl-dev \
                                           libbz2-dev
