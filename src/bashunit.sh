#!/bin/bash
set -euo pipefail

declare -gA bashunit
bashunit['test_file']='/dev/null'
bashunit['test_fail']=0
bashunit['test_pass']=0
bashunit['test_skip']=0
#options
bashunit['quiet']='' # does not print out
bashunit['stream']='' # pipe test output to stdout and exit on first test failure
bashunit['strict']='' # use 'set -euxo pipefail' for all tests

bashunit_init()
{
  # create test file
  if test -z ${bashunit['quiet']}; then
    bashunit['test_file']=$(mktemp -p /tmp "test-build.XXX");
  fi

  # set bash error handling
  if test '1' = bashunit['strict']; then
    set -euo pipefail
  else
    set +euo pipefail
  fi
}

# If your unit test requires additional options, feel free to copy & paste this into the test
# I tried playing around with doing something inheritance-like, but it proved very finicky
bashunit_parse_options()
{
  local options
  options=$(getopt -o "hqsx" --long "help,quiet,stream,strict" -name "bashunit.sh" -- "$@")
  eval set -- "$options"

  while true; do
    case "$1" in
      -q | --quiet)
          bashunit['quiet']='1'
          shift
      ;;
      -s | --stream)
          bashunit['stream']='1'
          shift
      ;;
      -x | --strict)
          bashunit['strict']='1'
          shift
      ;;
      -h | --help)
          echo "
    Usage:
      some-unit-test.sh [options]

    Test some unit of code

    -q, --quiet    stdout suppressed
    -s, --stream   pipe test output to stdout and exit on first test failure
    -x, --strict   use 'set -euxo pipefail' for all tests
    -h, --help     Display this help
"
          exit 0
      ;;
      --) shift
          break
      ;;
      *) shift
          trigger_error "invalid argument"
          exit 1
      ;;
    esac
  done
}

# prints msg to shell
#$ 1 - msg
bashunit_msg()
{
  if test -z ${bashunit['quiet']}; then echo "$1"; fi
}

# $1 - name
# $2 - test expression
# ex. bashunit_assert "file exists" test -f "${file}"
bashunit_assert()
{
  local n
  local flag
  local is_failure

  n="$1"
  shift;

  if "$@"; then
    is_failure=""
    flag="\e[32m ✔ \e[0m"
    bashunit['test_pass']=$((bashunit['test_pass']+1))
  else
    is_failure="1"
    flag="\e[31m ✘ \e[0m"
    bashunit['test_fail']=$((bashunit['test_fail']+1))
  fi

  if test -z ${bashunit['stream']}; then
    echo -e "${flag} ${n}" >> ${bashunit['test_file']}
    test -z ${is_failure} || false
  else
    echo -e "${flag} ${n}" | tee -a ${bashunit['test_file']}
    test -z ${is_failure} || exit 1
  fi
  return
}

# $1 - name
bashunit_skip()
{
  local n
  local flag

  n="$1"
  flag="\e[93m s \e[0m"

  bashunit['test_skip']=$((bashunit['test_skip']+1))
  if test -z ${bashunit['stream']}; then
    echo -e "${flag} ${n}" >> ${bashunit['test_file']}
  else
    echo -e "${flag} ${n}" | tee -a ${bashunit['test_file']}
  fi
}

bashunit_result()
{
  if test -z ${bashunit['quiet']}; then
    echo -e "\n-------- Test Results --------\n"
    cat ${bashunit['test_file']}
    echo ""
    echo "Passed: ${bashunit['test_pass']}"
    echo "Failed: ${bashunit['test_fail']}"
    echo "Skipped: ${bashunit['test_skip']}"
    if test ${bashunit['test_fail']} -ge 1; then
      echo "TEST FAILED"
    else
      echo "TEST SUCCESS"
    fi
  else
    if test 0 -eq ${bashunit['test_fail']}; then
      echo "1"
    else
      exit 1
    fi
  fi
}