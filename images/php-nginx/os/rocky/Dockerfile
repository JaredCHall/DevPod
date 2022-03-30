FROM docker.io/library/rockylinux:8.5

# Always upgrade to get the latest security patches
RUN dnf upgrade -y

# Install tzdata to allow changing container timezone
RUN dnf install -y tzdata

ARG PHP_VERSION=latest
ARG PHP_INSTALL_TYPE=repo

# Full version number
ARG PHP_VERSION=8.1.4