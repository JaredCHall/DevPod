#!/bin/bash
set -euo pipefail

# $1 command name
cmd_exists()
{
	[[ -n $(which $1 2>/dev/null) ]] && return;
	false
}

check_dependencies()
{
  local cmd
  for cmd; do
    cmd_exists "${cmd}" || trigger_error "You must install ${cmd} to use this script"
  done
}

# $1 - needle
# $2 - haystack
in_array()
{
  local e match="$1"
  shift
  for e; do
    test "$e" = "$match" && return;
  done
  false
}

# $1 prompt message
# $2 callback function
prompt_input()
{
	echo -e "\n$1\n"
	read TMP_VAR
	$2 ${TMP_VAR}
}

# $1 prompt message
# $2 callback yes function
# $3 callback no function
prompt_confirm()
{
  echo -e "\n$1\n"
	yn=$(prompt_choice "Yes" "No")
	echo ""
	if [[ ${yn} == "Yes" ]]; then
    [[ -n ${2-} ]] && $2;
		:;
  else
    [[ -n ${3-} ]] && $3;
		:;
	fi
}

prompt_choice()
{
	select choice in "$@"; do
		for sel in "$@"; do
			[[ "$sel" == "$choice" ]] && break 2;
			:;
		done
  done
	echo "$sel"
}

#$1 - error message
trigger_error()
{
  echo "ERROR: $1" >&2
  exit 1
}
