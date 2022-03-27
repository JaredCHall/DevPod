#!/bin/bash
set -euo pipefail

### DEPENDENCIES
source ./src/utils.sh

#container/image data
podunit_build_context=''
podunit_image_name='podunit-test'
podunit_image_tag=''
podunit_host_port="8008" # picking one that hopefully won't interfere with other services
podunit_container_port=''
podunit_volumes=()
podunit_named_volumes=()

#test data
podunit_script_name=''         # the calling test.sh script
podunit_tmp_dir='/tmp/podunit' # tmp directory for test files and volumes
podunit_test_fail=0
podunit_test_pass=0
podunit_test_skip=0

#test options
podunit_build_args=() # additional --build-args to pass to 'docker build'
podunit_nocache=''    # skips image cache layers, and completely rebuilds the image
podunit_quiet=''      # does not print out
podunit_stream=''     # pipe test output to stdout and exit on first test failure
podunit_strict=''     # use 'set -euxo pipefail' for all tests
podunit_debug=''      # print debug info

# initializes "class"; performs validations and creates files
podunit_init() {
    # validations
    [ -z ${podunit_build_context} ] && trigger_error "\$podunit_build_context is not defined"
    [ -z ${podunit_script_name} ] && trigger_error "\$podunit_script_name is not defined"
    [ -z ${podunit_image_tag} ] && trigger_error "\$podunit_image_tag is not defined"

    podunit_parse_options "$@"

    # start test with a clean environment
    podunit_clean

    # create tmp testing dir
    mkdir ${podunit_tmp_dir}

    # handle volume args
    local arg dir
    for arg in "${podunit_volumes[@]}"; do
        dir=$(echo "$arg" | sed 's/[:].*$//')

        # if the volume options starts with '/' or './', then it's a bind mount, otherwise a named volume
        if echo "$dir" | grep -Eq "^(/|./)"; then
            mkdir "$dir" # bind mounts require an existing directory
        else
            podunit_named_volumes+=("$dir") # store for cleanup logic
        fi
    done

    # print debug info, if necessary
    test ! -z ${podunit_debug} && print_debug_info && exit 0

    # Ensure temporary files / containers are cleaned up on exit
    trap 'podunit_clean' EXIT

    # set bash error handling
    set +euo pipefail
    test ! -z ${podunit_strict} && set -euo pipefail

    # prepare containers
    podunit_msg "Testing build ${podunit_image_name}:${podunit_image_tag} ..."
    container_up
}

podunit_clean() {
    container_down &>/dev/null
    rm -rf ${podunit_tmp_dir} &>/dev/null
    volume_remove &>/dev/null
}

# prints msg to shell
#$ 1 - msg
podunit_msg() {
    if test -z ${podunit_quiet}; then echo "$1"; fi
}

# $1 - name
# $2 - test expression
# ex. podunit_assert "file exists" test -f "${file}"
podunit_assert() {
    local n
    local flag
    local is_failure

    n="$1"
    shift

    if "$@"; then
        is_failure=""
        flag="\e[32m ✔ \e[0m"
        podunit_test_pass=$((podunit_test_pass + 1))
    else
        is_failure="1"
        flag="\e[31m ✘ \e[0m"
        podunit_test_fail=$((podunit_test_fail + 1))
    fi

    if test -z ${podunit_stream}; then
        echo -e "${flag} ${n}" >>${podunit_tmp_dir}/output.log
        test -z ${is_failure} || false
    else
        echo -e "${flag} ${n}" | tee -a ${podunit_tmp_dir}/output.log
        test -z ${is_failure} || exit 1
    fi
    return
}

# $1 - name
podunit_skip() {
    local n
    local flag

    n="$1"
    flag="\e[93m s \e[0m"

    podunit_test_skip=$((podunit_test_skip + 1))
    if test -z ${podunit_stream}; then
        echo -e "${flag} ${n}" >>${podunit_tmp_dir}/output.log
    else
        echo -e "${flag} ${n}" | tee -a ${podunit_tmp_dir}/output.log
    fi
}

podunit_result() {
    if test -z ${podunit_quiet}; then
        echo -e "\n-------- Test Results --------\n"
        cat ${podunit_tmp_dir}/output.log
        echo ""
        echo "Passed: ${podunit_test_pass}"
        echo "Failed: ${podunit_test_fail}"
        echo "Skipped: ${podunit_test_skip}"
        if test ${podunit_test_fail} -ge 1; then
            echo "TEST FAILED"
        else
            echo "TEST SUCCESS"
        fi
    else
        if test 0 -eq ${podunit_test_fail}; then
            echo "1"
        else
            exit 1
        fi
    fi
}

podunit_parse_options() {
    local tmp
    tmp=$(getopt -o "hnqsx" --long "help,no-cache,quiet,stream,strict,debug,arg:" -n "nginx-php-test.sh" -- "$@")
    eval set -- "$tmp"

    while true; do
        case "$1" in
        --arg)
            podunit_build_args+=("${2}")
            shift 2
            ;;
        --debug)
            podunit_debug="1"
            shift
            ;;
        -n | --no-cache)
            podunit_nocache="1"
            shift
            ;;
        -q | --quiet)
            podunit_quiet='1'
            shift
            ;;
        -s | --stream)
            podunit_stream='1'
            shift
            ;;
        -x | --strict)
            podunit_strict='1'
            shift
            ;;
        -h | --help)
            echo "Description:
  Test ${podunit_image_tag} image/container build

Usage:
  ${podunit_script_name} [options]

Options:
    -n, --no-cache    Skips image cache layers, and completely rebuilds the image
    -q, --quiet       Suppress stdout, for test automation
    -s, --stream      Pipe test output to stdout and exit on first test failure
    -x, --strict      Use 'set -euxo pipefail' for all tests
    --arg             A build arg passed to the Dockerfile (ex. PHP_VERSION=php8)
                      You can pass this option multiple times, just like with the podman/docker command
    --debug           Print podman commands useful for debugging builds
    -h, --help        Display this help
"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        esac
    done

}

get_build_args_str() {
    local str="" arg
    for arg in "${podunit_build_args[@]}"; do str="${str} --build-arg ${arg}"; done
    echo "${str:1}"
}

get_volume_args_str() {
    local str="" arg
    for arg in "${podunit_volumes[@]}"; do str="${str} -v ${arg}"; done
    echo "${str:1}"
}

get_port_arg_str() {
    [ -n "${podunit_container_port}" ] && echo "-p 127.0.0.1:${podunit_host_port}:${podunit_container_port}"
}

print_debug_info() {
    podunit_msg "---- USEFUL DEBUG COMMANDS ---

# stop / remove container
podman stop ${podunit_image_name}
podman rm -v ${podunit_image_name}

# remove image
podman image rm ${podunit_image_name}:${podunit_image_tag}

# build image
podman build -t ${podunit_image_name}:${podunit_image_tag} $(get_build_args_str) ${podunit_build_context}

# create container
podman create --name ${podunit_image_name} $(get_port_arg_str) $(get_volume_args_str) ${podunit_image_name}:${podunit_image_tag}

# start container
podman start ${podunit_image_name}
"
}

image_build() {
    podunit_msg "building image..."
    local build_args="$(get_build_args_str)"
    podman build -q -t ${podunit_image_name}:${podunit_image_tag} ${build_args} ${podunit_build_context} >/dev/null && return
    false
}

image_remove() {
    podunit_msg "removing image..."
    podman image rm ${podunit_image_name}:${podunit_image_tag} >/dev/null
}

# does not remove bind mounts, only proper volumes
volume_remove() {
    echo "removing volume..."
    for vol in "${podunit_named_volumes[@]}"; do
        podman volume rm "$vol" 2>/dev/null || true
    done
}

container_up() {

    local err_file="${podunit_tmp_dir}/build.err"

    if test ! -z ${podunit_nocache}; then
        image_remove 1>&2 /dev/null || true
    fi

    image_build >/dev/null 2>"${err_file}"
    if test "$?" != "0"; then
        build_err=$(cat "${err_file}")
        podunit_msg "
--- ERROR: Image could not be built ---
${build_err}"
        echo ""
        exit 1
    fi

    : >"${err_file}"
    container_create 2>"${err_file}"
    if test "$?" != "0"; then
        build_err=$(cat "${err_file}")
        podunit_msg "
--- ERROR: Container could not be created ---
${build_err}"
        echo ""
        exit 1
    fi

    : >"${err_file}"
    container_start 2>"${err_file}"
    if test "$?" != "0"; then
        build_err=$(cat "${err_file}")
        podunit_msg "
--- ERROR: Container did not start ---
${build_err}"
        echo ""
        exit 1
    fi

    sleep 5 # wait a few seconds to see if container stays up or fails
    container_is_running
    if test "$?" != "0"; then
        build_err=$(podman logs ${podunit_image_name})
        podunit_msg "
--- ERROR: Container went down after a few seconds ---
${build_err}"
        echo ""
        exit 1
    fi

}

container_down() {
    # stop/start without printing errors or exiting script if container is already stopped or does not exist
    container_stop 2>/dev/null || true
    container_remove 2>/dev/null || true
}

container_stop() {
    podunit_msg "stopping container..."
    podman stop "${podunit_image_name}"
}

# $1 - keep volumes
container_remove() {
    podunit_msg "removing container..."
    podman rm -v "${podunit_image_name}" >/dev/null
}

container_start() {
    podunit_msg "starting container..."
    podman start ${podunit_image_name} >/dev/null
}

container_create() {
    podunit_msg "creating container..."
    local volume_args="$(get_volume_args_str)"
    podman create --name ${podunit_image_name} $(get_port_arg_str) ${volume_args} ${podunit_image_name}:${podunit_image_tag} >/dev/null
}

container_is_running() {
    test "0" != $(podman ps | grep -c "${podunit_image_name}") && return
    false
}
container_exec() {
    podman exec "${podunit_image_name}" "$@"
}
