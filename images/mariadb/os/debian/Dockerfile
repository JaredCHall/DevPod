FROM docker.io/library/debian:11.2-slim

# Always upgrade to get the latest security patches
RUN apt-get update && apt-get upgrade

# Install tzdata to allow changing container timezone
RUN apt-get install -y --no-install-recommends tzdata

# Full version number
ARG MARIADB_VERSION=10.7.3