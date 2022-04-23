FROM docker.io/library/rockylinux:8.5

# Always upgrade to get the latest security patches
RUN dnf upgrade -y

# Install tzdata to allow changing container timezone
RUN dnf install -y tzdata

# Full version number
ARG MARIADB_VERSION=10.6
