FROM docker.io/library/rockylinux:8.5

# Always upgrade to get the latest security patches
RUN dnf upgrade -y

# Install tzdata to allow changing container timezone
RUN dnf install -y tzdata

ARG NGINX_INSTALL_TYPE=source
ARG NGINX_VERSION=1.20.2

ARG PHP_INSTALL_TYPE=source
ARG PHP_VERSION=8.1.4