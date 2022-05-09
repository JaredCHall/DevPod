FROM docker.io/library/debian:11.2-slim as base

# Always upgrade to get the latest security patches
RUN apt-get update && apt-get upgrade -y

# Install tzdata to allow changing container timezone
RUN apt-get install -y --no-install-recommends tzdata

# Install ca-certificates
RUN apt-get install -y --no-install-recommends ca-certificates
