#!/bin/bash
set -euo pipefail

#install curl to download source
apt-get install -y --no-install-recommends curl

# Minimal dependencies
apt-get install -y  --no-install-recommends make \
                                            gcc \
                                            g++
