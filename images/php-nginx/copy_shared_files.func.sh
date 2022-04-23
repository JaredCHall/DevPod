#!/bin/bash
set -euo pipefail

# Special function for alpine php-nginx
if [ "${image_os}" == 'alpine' ]; then
    copy_shared_files() {
        mkdir -p "${install_dir}/nginx/etc/"
        mkdir -p "${install_dir}/php/etc/"
        cp -r "${image_dir}/share/nginx/etc/"* "${install_dir}/nginx/etc/"
        cp -r "${image_dir}/share/php/etc/"* "${install_dir}/php/etc/"
        cp "${image_dir}/share/php/php-composer.sh" "${install_dir}/php/"
        cp "${image_dir}/share/start.sh" "${install_dir}/"
    }
fi
