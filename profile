#!/usr/bin/env bash
        
set -euo pipefail

test_log="$1" ; shift
mkdir -p $(dirname "$test_log")
exit_status='0'
`which time` --quiet --format '%x %es %Us %Ss %MKB %C' --output "$test_log" --append \
    "$@" &>/dev/null \
    || exit_status="$?"
exit "$exit_status"