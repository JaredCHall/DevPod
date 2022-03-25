FROM docker.io/library/alpine:3.15

# Always upgrade to get the latest security patches
RUN apk update && apk upgrade

# Install tzdata to allow changing container timezone
RUN apk add --no-cache tzdata

# Install bash
RUN apk add --no-cache bash
