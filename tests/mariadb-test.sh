#!/bin/bash
set -euo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null
source ./src/podunit.sh

main()
{

  # Check dependencies
  check_dependencies "podman" "mysql"

  # set podunit variables
  podunit_script_name='mariadb-test.sh'
  podunit_build_context=$(realpath '../images/mariadb')
  podunit_image_tag='mariadb'
  podunit_container_port="3306"
  podunit_host_port="3366"

  # add volumes
  podunit_volumes+=("podunit_dbdata:/var/lib/mysql/:Z")
  podunit_volumes+=("${podunit_tmp_dir}/mysql-etc:/container/etc/mysql/:Z")
  podunit_volumes+=("${podunit_tmp_dir}/mysql-defaults:/container/etc/mysql.defaults:Z")

  # add build args
  podunit_build_args+=("MARIADB_USER=podunit")
  podunit_build_args+=("MARIADB_PASS=abc123")

  # define exposed ports
  podunit_init "$@"
  run_tests
  podunit_result

}

run_tests()
{
  local r
  local mysql_cmd

  mysql_cmd="mysql -N -h 127.0.0.1 -P ${podunit_host_port} -u podunit -pabc123"

  # Test remote connection from host
  r=$(echo "SELECT 1;" | $mysql_cmd)
  podunit_assert "remote mysql connection" test "1" = "$r"

  # Test database logs errors
  echo "SELECT 1" | mysql -N -h 127.0.0.1 -P ${podunit_host_port} -u fakeuser -pfakepass > /dev/null 2>&1
  r=$(podman logs --tail 1 ${podunit_image_name} 2>&1 | grep -c fakeuser)
  podunit_assert "mariadb logs errors" test "1" = "${r}"

  # Test timezone data loaded
  r=$(echo "SELECT count(*) FROM mysql.time_zone;" | $mysql_cmd)
  podunit_assert "timezone data loaded" test 100 -lt "${r}"

  # Test database persistence
  echo "CREATE DATABASE persistence_test;" | $mysql_cmd

  container_down
  container_up

  sleep 1

  r=$( echo "show databases;" | $mysql_cmd | grep persistence_test)
  podunit_assert "database persists on restart" test -n "$r"

  # Test mysql conf exposed to host
  podunit_assert "mysql conf exposed to host" test -f ${podunit_tmp_dir}/mysql-etc/my.cnf

  # Test mysql conf defaults exposed to host
  r=$(ls -1U ${podunit_tmp_dir}/mysql-defaults | wc -l)
  podunit_assert "mysql default conf exposed to host" test "$r" -gt 0

  # handle test result
  bashunit_result
}



main "$@"