#!/bin/bash
set -euo pipefail

# install php and php modules
apk add --no-cache \
    ${1}  \
    ${1}-phar \
	  ${1}-fpm \
	  ${1}-json \
		${1}-mbstring \
		${1}-opcache \
		${1}-openssl \
		${1}-bcmath \
		${1}-session \
		${1}-pdo \
		${1}-pdo_mysql \
		${1}-mysqlnd \
		${1}-dom  \
    ${1}-xml \
    ${1}-xmlwriter \
    ${1}-fileinfo \
    ${1}-tokenizer

