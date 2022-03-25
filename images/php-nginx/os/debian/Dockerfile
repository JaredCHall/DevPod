FROM docker.io/library/debian:11.2-slim

# Always upgrade to get the latest security patches
RUN apt-get update && apt-get upgrade

# Install tzdata to allow changing container timezone
RUN apt-get install -y --no-install-recommends tzdata

# Install ca-certificates
RUN apt-get install -y --no-install-recommends ca-certificates

# Full version number
ARG PHP_VERSION=8.1.4