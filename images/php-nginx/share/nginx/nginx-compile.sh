#!/bin/bash
set -euo pipefail

cd nginx

useradd -r -s /sbin/nologin nginx

./configure --prefix=/opt/nginx \
            --conf-path=/etc/nginx/nginx.conf \
            --user=nginx \
            --group=nginx \
            --with-threads \
            --with-pcre=../pcre \
            --with-zlib=../zlib \
            --without-http_uwsgi_module \
            --without-http_autoindex_module \
            --without-http_scgi_module

cores=$(nproc)
make -j${cores}
make install
