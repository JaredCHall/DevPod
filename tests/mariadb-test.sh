#!/bin/bash
set -euo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null
source ./src/podunit.sh
source ../.mariadb.env

main() {

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
    podunit_build_args+=("MARIADB_VERSION=${PODMAN_MARIADB_VERSION}")
    podunit_build_args+=("MARIADB_USER=${PODMAN_MARIADB_USER}")
    podunit_build_args+=("MARIADB_PASS=${PODMAN_MARIADB_PASS}")

    # define exposed ports
    podunit_init "$@"



    run_tests
    podunit_result

}

run_tests() {
    local r mysql_cmd os

    mysql_cmd="mysql -N -h 127.0.0.1 -P ${podunit_host_port} -u ${PODMAN_MARIADB_USER} -p${PODMAN_MARIADB_PASS}"

    # Display mariadb version
    mariadb_version=$(container_exec mariadbd --version | grep -oE "Ver [0-9]+[.][0-9]+[.][0-9]+" | sed 's|Ver ||')
    podunit_msg "MariaDB Version: ${mariadb_version}"

    # Test installed mariadb version
    case ${PODMAN_MARIADB_OS} in
        alpine)
            podunit_skip "Mariadb version"
        ;;
        debian)
            podunit_assert "Mariadb version" test "${PODMAN_MARIADB_VERSION}" = "$mariadb_version"
        ;;
        rocky)
            r=$(echo "$mariadb_version" | grep -qE "^${PODMAN_MARIADB_VERSION}" && echo "1")
            podunit_assert "Mariadb version" test "1" = "$r"
        ;;
    esac

    # Test remote connection from host
    r=$(echo "SELECT 1;" | $mysql_cmd)
    podunit_assert "remote mysql connection" test "1" = "$r"

    # Test database logs errors
    echo "SELECT 1" | mysql -N -h 127.0.0.1 -P ${podunit_host_port} -u fakeuser -pfakepass >/dev/null 2>&1
    r=$(podman logs --tail 1 ${podunit_image_name} 2>&1 | grep -c fakeuser)
    podunit_assert "mariadb logs errors" test "1" = "${r}"

    # Test timezone data loaded
    r=$(echo "SELECT count(*) FROM mysql.time_zone;" | $mysql_cmd)
    podunit_assert "timezone data loaded" test 100 -lt "${r}"

    # Test database persistence
    echo "CREATE DATABASE persistence_test;" | $mysql_cmd

    container_down > /dev/null
    container_up > /dev/null

    sleep 1

    r=$(echo "show databases;" | $mysql_cmd | grep persistence_test)
    podunit_assert "database persists on restart" test -n "$r"

    # Test mysql conf exposed to host
    podunit_assert "mysql conf exposed to host" test -f ${podunit_tmp_dir}/mysql-etc/my.cnf

    # Test mysql conf defaults exposed to host
    r=$(ls -1U ${podunit_tmp_dir}/mysql-defaults | wc -l)
    podunit_assert "mysql default conf exposed to host" test "$r" -gt 0

}

main "$@"
