#!/bin/bash
set -euo pipefail

main()
{

  echo "FIX ME!!!!!"
  exit 1


  # Trap to ensure we get a safe shutdown
  trap 'mariadb-admin shutdown; exit 0' HUP INT QUIT TERM
  mariadbd --user=mysql & wait "$!"
}

main

