FROM docker.io/library/debian:11.2-slim

# Always upgrade to get the latest security patches
RUN apt-get update && apt-get upgrade -y

# Install tzdata to allow changing container timezone
RUN apt-get install -y --no-install-recommends tzdata

# Install ca-certificates
RUN apt-get install -y --no-install-recommends ca-certificates

ARG NGINX_INSTALL_TYPE=repo
ARG NGINX_VERSION=''

ARG PHP_INSTALL_TYPE=repo
ARG PHP_VERSION=''