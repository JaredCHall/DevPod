#!/bin/bash
set -euo pipefail

# Install curl to download source
dnf install -y curl

# Build dependencies
dnf install -y make \
               gcc \
               gcc-c++
