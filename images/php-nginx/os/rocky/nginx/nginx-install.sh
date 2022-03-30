#!/bin/bash
set -euo pipefail

trigger_error() { echo "[ERROR] $1" >&2; exit 1; }
trigger_warning() { echo "[WARNING] $1" >&2; }

main()
{
    install_type="${1-}"
    version="${2-}"
    test -n "${install_type}" || trigger_error "ERROR: build-arg NGINX_INSTALL_TYPE not provided"

    case "${install_type}" in
        repo)
            install_from_repo
            ;;
        source)
            compile_from_source
            ;;
        *)
            trigger_error "Invalid NGINX_INSTALL_TYPE '${install_type}'; Must be 'repo' or 'source'"
            ;;
    esac

    # sanity check
    nginx -v 2>&1 | grep -qE "nginx[/][0-9]+[.][0-9]+[.][0-9]+" || trigger_error "nginx installation failed"

}

install_from_repo()
{
    trigger_warning "NGINX_VERSION ignored. Only the latest stable can be installed from the Rocky Linux repository."
    dnf install -y nginx;
}

compile_from_source()
{

    ### VALIDATE VERSION ###
    test -n "${version}" || trigger_error "ERROR: build-arg NGINX_VERSION not provided"
    echo "${version}" | grep -qE "^[0-9]+[.][0-9]+[.][0-9+]$" || trigger_error "Invalid NGINX version '${version}'. Must be a full version number such as 1.20.2"

    # configure dnf to use powertools and epel repos
    dnf install -y dnf-plugins-core
    dnf install -y epel-release
    dnf config-manager --set-enabled powertools
    dnf update -y

    #install curl to download source
    dnf install -y curl

    # Minimal dependencies
    dnf install -y make \
                   gcc

    dnf install -y zlib-devel \
                   pcre-devel

    tmp_install_dir="/tmp/nginx.install"
    mkdir $tmp_install_dir
    cd $tmp_install_dir

    echo "downloading NGINX version $version from nginx.com"
    curl -sL "https://nginx.org/download/nginx-${version}.tar.gz" > nginx.tar.gz

    compile_dir="${tmp_install_dir}/nginx-source"
    mkdir $compile_dir
    tar -xzf nginx.tar.gz --strip-components=1 --directory ${compile_dir}

    cd ${compile_dir}

    useradd -r -s /sbin/nologin nginx

    ./configure --prefix=/opt/nginx \
                --conf-path=/etc/nginx/nginx.conf \
                --user=nginx \
                --group=nginx \
                --with-threads \
                --with-pcre \
                --without-http_uwsgi_module \
                --without-http_autoindex_module \
                --without-http_scgi_module

    cores=$(nproc)
    make -j${cores}
    make install

    # link installed bins to standard locations
    ln -s /opt/nginx/sbin/nginx /usr/sbin/nginx

    # Minimal dependencies
    dnf remove -y   make \
                    gcc

}

main "$@"