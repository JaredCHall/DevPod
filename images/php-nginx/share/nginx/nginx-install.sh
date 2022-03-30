#!/bin/bash
set -euo pipefail

trigger_error() { echo "[ERROR] $1" >&2; exit 1; }
trigger_warning() { echo "[WARNING] $1" >&2; }

install_type="${1-}"
version="${2-}"
test -n "${install_type}" || trigger_error "ERROR: build-arg NGINX_INSTALL_TYPE not provided"

case "${install_type}" in
    repo)
        ./nginx-install-from-repo.sh "${version}"
        ;;
    source)
        ./nginx-compile-from-source.sh "${version}"
        ;;
    *)
        trigger_error "Invalid NGINX_INSTALL_TYPE '${install_type}'; Must be 'repo' or 'source'"
        ;;
esac