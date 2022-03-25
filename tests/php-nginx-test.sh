#!/bin/bash
set -euo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null
source ./src/podunit.sh

main()
{

  check_dependencies "podman" "wget"

  # set podunit variables
  podunit_script_name='php-nginx-test.sh'
  podunit_build_context=$(realpath '../images/php-nginx')
  podunit_image_tag='php-nginx'
  podunit_container_port="80"

  # set volumes
  podunit_volumes+=("${podunit_tmp_dir}/project:/var/www/public:Z")
  podunit_volumes+=("${podunit_tmp_dir}/nginx-etc:/container/etc/nginx:Z")
  podunit_volumes+=("${podunit_tmp_dir}/php-etc:/container/etc/php:Z")
  podunit_volumes+=("${podunit_tmp_dir}/nginx-defaults:/container/etc/nginx.defaults:Z")
  podunit_volumes+=("${podunit_tmp_dir}/php-defaults:/container/etc/php.defaults:Z")

  # define exposed ports

  podunit_init "$@"
  run_tests
  podunit_result
}

run_tests()
{

  test_dir="${podunit_tmp_dir}/project/tmp-testing-dir"
  test_uri="localhost:${podunit_host_port}/tmp-testing-dir"
  mkdir $test_dir

  # Test nginx serves html
  echo "ok" > ${test_dir}/test.html
  r=$(wget -qO- "${test_uri}/test.html")
  r="${r//[$'\r\n']}"
  podunit_assert "nginx serves html" test "${r}" = 'ok'

  # Test nginx serves php
  echo "<?php echo 'ok'; ?>" > ${test_dir}/index.php
  r=$(wget -qO- ${test_uri}/index.php)
  r="${r//[$'\r\n']}"
  podunit_assert "nginx serves php" test "${r}" = 'ok'

  # Test php composer installed
  r=$(container_exec composer --version | grep -c "Composer version")
  podunit_assert "php composer installed" test "${r}" = '1'

  # Test php opcache enabled
  echo "<?php echo extension_loaded('Zend OPcache'); ?>" > ${test_dir}/index.php
  r=$(wget -qO- ${test_uri}/index.php)
  r="${r//[$'\r\n']}"
  podunit_assert "php opcache enabled" test "${r}" = '1'

  # Test nginx logs requests
  r=$(podman logs --tail 1 ${podunit_image_name} 2>&1 | grep -c "index.php")
  podunit_assert "nginx logs requests" test "1" = "${r}"

  # Test nginx logs errors
  wget -qO- ${test_uri}/noimage.jpg || true
  r=$(podman logs --tail 1 ${podunit_image_name} 2>&1 | grep -c "noimage.jpg")
  podunit_assert "nginx logs errors" test "1" = "${r}"

  # Test php-fpm logs master process
  if podunit_assert "php-fpm.log exists" container_exec test -f /var/log/nginx/php-fpm.log; then
    r=$(container_exec head -n 1 /var/log/nginx/php-fpm.log | grep -c "fpm is running")
    podunit_assert "php-fpm logs master process" test "1" = "${r}"
  else
    bashunit_skip "php-fpm logs master process"
  fi

  # Test nginx logs php errors
  echo "<?php trigger_error('panic!'); ?>" > ${test_dir}/error.php
  wget -qO- ${test_uri}/error.php
  r=$(podman logs --tail 2 ${podunit_image_name} 2>&1 >/dev/null | grep -c "panic!")
  podunit_assert "php-fpm logs errors" test "1" = "${r}"

  # Test nginx conf exposed to host
  podunit_assert "nginx conf exposed to host" test -f ${podunit_tmp_dir}/nginx-etc/nginx.conf

  # Test php conf exposed to host
  podunit_assert "php conf exposed to host" test -f ${podunit_tmp_dir}/php-etc/php-fpm.conf

  # Test nginx conf defaults exposed to host
  r=$(ls -1U ${podunit_tmp_dir}/nginx-defaults | wc -l)
  podunit_assert "nginx default conf exposed to host" test "$r" -gt 0

  # Test php conf defaults exposed to host
  r=$(ls -1U ${podunit_tmp_dir}/php-defaults | wc -l)
  podunit_assert "php default conf exposed to host" test "$r" -gt 0

}

main "$@"