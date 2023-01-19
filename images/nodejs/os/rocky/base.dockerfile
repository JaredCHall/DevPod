FROM docker.io/library/rockylinux:9

# Always upgrade to get the latest security patches
RUN dnf upgrade -y

# Install tzdata to allow changing container timezone
RUN dnf install -y tzdata

