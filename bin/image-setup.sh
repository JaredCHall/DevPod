#!/bin/bash
set -euo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null
source ../src/utils.sh

echo "
################
DevPod - Builder
################

Setup an image

"

# main data
build_dir='/tmp/devpod-build'
image_type=''
image_os=''

# command options
cmdopt_build_dir=''
cmdopt_clobber=''
cmdopt_defaults=''
cmdopt_image_type=''
cmdopt_image_os=''

main() {

    image_dir=$(realpath ../images || trigger_error "Could not find image directory")

    parse_options "$@"

    ### Set data from command options or prompt

    # Set the build dir
    if test -n "${cmdopt_build_dir}"; then
        build_dir=${cmdopt_build_dir}
    elif test -z "${cmdopt_defaults}"; then
        msg="Where would you like to create the build? (Use real path! default: ${build_dir})"
        prompt_input "$msg" set_build_dir
    fi
    set_build_dir "${build_dir}"

    # set the image type
    set_enum_image_types
    if test -n "${cmdopt_image_type}"; then
        image_type=${cmdopt_image_type}
    elif test -z "${cmdopt_defaults}"; then
        echo "Which type of image would you like to build?"
        image_type=$(prompt_choice "${enum_image_types[@]}")
        echo ""
    fi
    set_image_type "${image_type}"

    # set the os type
    set_enum_os_types
    if test -n "${cmdopt_image_os}"; then
        image_os=${cmdopt_image_os}
    elif test -z "${cmdopt_defaults}"; then
        echo "On which OS would you like to install ${image_type}?"
        image_os=$(prompt_choice "${enum_os_types[@]}")
        echo ""
    fi
    set_image_os "${image_os}"

    echo "build_dir: ${build_dir}"
    echo "image_type: ${image_type}"
    echo "image_os: ${image_os}"

    msg="Is the above information correct?"
    prompt_confirm "$msg" "" quit

    install_build_context

}

install_build_context() {



    echo "Installing build context"

    image_dir="${image_dir}/${image_type}"
    src_dir="${image_dir}/os/${image_os}"

    install_dir="${build_dir}/images/${image_type}"
    mkdir -p "${install_dir}"

    # Copy shared resources
    if [ -d "${image_dir}/share" ]; then
        cp -r "${image_dir}/share/"* "${install_dir}"
    fi

    # Copy os-specific resources
    cp -r "${src_dir}/"* "${install_dir}"

    # Create Dockerfile
    cat ${src_dir}/Dockerfile >"${install_dir}/Dockerfile"
    if [ -f "${image_dir}/stub/Dockerfile.stub" ]; then
        cat "${image_dir}/stub/Dockerfile.stub" >>"${install_dir}/Dockerfile"
    fi

    # Copy test src
    mkdir -p "${build_dir}/tests/src"
    cp -f ../src/utils.sh "${build_dir}/tests/src"
    cp -f ../src/podunit.sh "${build_dir}/tests/src"

    # Copy image test unit
    cp -f "../tests/${image_type}-test.sh" "${build_dir}/tests/"

    create_compose_example

    # Copy docker-compose.yaml example

}

create_compose_example() {
    local compose_file new_file replace

    compose_file="${image_dir}/compose.yaml"
    [[ ! -f "${compose_file}" ]] && return;

    mkdir -p "${build_dir}/examples"
    new_file="${build_dir}/examples/${image_type}.service.yaml"

    local dirname
    dirname=$(realpath "$build_dir/../")
    dirname=$(basename "$dirname" | sed "s/ /-/g" | tr -d "/'")

    replace=()
    replace+=("s/VAR_IMAGE_NAME/${image_type}/g")
    local timezone="America/New_York # UTC, America/New_York, America/Chicago, America/Denver, America/Los_Angeles"
    replace+=("s|VAR_TIMEZONE|${timezone}|")

    case "${image_type}" in
        php-nginx) service="web" ;;
        mysql | mariadb) service="data" ;;
    esac
    replace+=("s/VAR_SERVICE_NAME/${dirname}-${service}/g")
    replace+=("s/VAR_NETWORK_NAME/${dirname}-net/g")

    local args_file arg_name arg_val
    args_file="${image_dir}/build-args.sh"
    if [[ -f "${args_file}" ]]; then
        source "${args_file}" "${image_os}"
        for arg_name in "${BUILD_ARGS[@]}"; do
            arg_val=$(echo "${!arg_name}" | tr -d "/'") # remove bad characters
            replace+=("s/ARG_${arg_name}/${arg_val}/")
        done
    fi

    local cmd
    cmd="cat ${compose_file}"
    for i in "${replace[@]}"; do
        cmd="${cmd} | sed '${i}'"
    done
    cmd="${cmd} > ${new_file}"
    eval "$cmd"
}

find_subdirs() {
    find "${1}" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort | tr "\n" " "
}

set_enum_image_types() {
    enum_image_types=$(find_subdirs "${image_dir}")
    test -z "${enum_image_types}" && trigger_error "No builds found in ${image_dir}"
    IFS=" " read -r -a enum_image_types <<<"${enum_image_types}" #convert to array
}

set_enum_os_types() {
    local os_dir
    test -z "$image_type" && trigger_error "cannot set os_type before setting image_type"
    os_dir="${image_dir}/${image_type}/os"
    test -d "$os_dir" || trigger_error "directory not found ${os_dir}"
    enum_os_types=$(find_subdirs "${os_dir}")
    test -z "${enum_os_types}" && trigger_error "no supported image-os found in ${os_dir}"
    IFS=" " read -r -a enum_os_types <<<"${enum_os_types}" #convert to array
}

set_build_dir() {
    test -n "${1-}" && build_dir="$1"
    build_dir=$(echo "${build_dir}" | sed 's|~|'${HOME}'|')
    build_dir=$(realpath "${build_dir}" || trigger_error "Invalid directory")
}

set_image_type() {
    test -n "${1-}" && image_type="$1"
    in_array "${image_type}" "${enum_image_types[@]}" || trigger_error "Invalid image-type: ${image_type}"
}

set_image_os() {
    test -n "${1-}" && image_os="$1"
    in_array "${image_os}" "${enum_os_types[@]}" || trigger_error "Invalid image-os: ${image_os}"
}

parse_options() {

    local tmp
    tmp=$(getopt -o "ht:o:d:" --long "help,directory:,image-type:,image-os:" -n "image_setup.sh" -- "$@")
    eval set -- "$tmp"

    while true; do
        case "$1" in
        -d | --directory)
            cmdopt_build_dir="$2"
            shift 2
            ;;
        -b | --build-dir)
            cmdopt_build_dir="$2"
            shift 2
            ;;
        -t | --image-type)
            cmdopt_image_type="$2"
            shift 2
            ;;
        -o | --image-os)
            cmdopt_image_os="$2"
            shift 2
            ;;
        -h | --help)
            echo "
Usage:
  image-setup.sh [options]

Setup an image build

Options:

-d, --directory     build install location
-t, --image-type    type of image (ex: php-nginx, mariadb)
-o, --image-os      image operating system (ex: alpine, debian)
-h, --help          Display this help
"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            shift
            trigger_error "invalid argument"
            exit 1
            ;;
        esac
    done

}

quit() {
    echo "Goodbye"
    exit 0
}

main "$@"
