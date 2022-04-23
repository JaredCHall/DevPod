# Install Buster because mysql.com apt repository does not support Bullseye for version 5.7
FROM docker.io/library/debian:10.11-slim

# Always upgrade to get the latest security patches
RUN apt-get update && apt-get upgrade

# Install tzdata to allow changing container timezone
RUN apt-get install -y --no-install-recommends tzdata


