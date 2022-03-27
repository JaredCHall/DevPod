# DevPod

DevPod assists with setting up container images for developing web applications. DevPod containers are intended for development environments only and should not be used in production.

## Purpose

Why use a DevPod? You certainly could just download a MariaDB container image from an image repository like docker.io. Unfortunately, those images obscure how they are built. Many of them do not have a publicly available Dockerfile for you to inspect. Unless you build an image yourself, you don't really know what is in it. Premade images also prevent you from customizing the build.

Use DevPods When:
- You have the unshakable need to understand exactly how everything works.
- You are learning about containers and how they are built.
- You are paranoid about downloading container images from popular repositories.
- You need to customize images to suit your own needs, but don't want to start your build completely from scratch.

## Available Builds

- Php-Nginx: front-end web server
- MariaDB: database server
- Mysql: database server

## Supported Distributions

- Alpine Linux
- Debian Linux
- Rocky Linux

## Usage

Setup Image Build
```
bin/image-setup.sh
```

Customize Your Build
```
# Dockerfile and installation scripts are located in the /build directory
```

Run & Customize Tests
```
tests/php-nginx-test.sh
tests/mariadb-test.sh
tests/mysql-test.sh
```

Push to Container Registry
```
podman build [image_name]
podman push [image_name] [registry]
```