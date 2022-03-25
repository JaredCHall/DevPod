#!/bin/bash
set -euo pipefail

apt-get install -y --no-install-recommends nginx

# Make the nginx user consistent with other distributions
useradd nginx -s /usr/sbin/nologin -r
userdel www-data