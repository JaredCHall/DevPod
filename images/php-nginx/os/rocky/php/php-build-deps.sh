#!/bin/bash
set -euo pipefail

# configure dnf to use powertools and epel repos
dnf install -y dnf-plugins-core
dnf install -y epel-release
dnf config-manager --set-enabled powertools
dnf update -y

#install jq for easy json parsing
dnf install -y jq curl

dnf install -y make \
               gcc \
               gcc-c++ \
               binutils \
               glibc-devel \
               autoconf \
               libtool \
               bison \
               automake \
               re2c
