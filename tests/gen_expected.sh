#!/bin/sh
# SPDX-License-Identifier: BSL-1.0

set -eu
set -f

if [ "$#" -ne 1 ]; then
  echo "usage: gen_expected.sh <test-name-without-extension>" >&2
  exit 2
fi

name=$1
arguments_file="$name.args"
arguments=
if [ -f "$arguments_file" ]; then
  arguments=$(cat "$arguments_file")
fi

# Argument fixtures contain formatter options only and intentionally split on
# whitespace. Filename expansion is disabled above.
# shellcheck disable=SC2086
set -- $arguments
printf 'Args: %s\n' "$arguments"

for style in allman otbs; do
  output="$style/$name.d.ref"
  ../bin/adfmt "--brace_style=$style" "$@" "$name.d" >"$output"
  printf '%s\n%s:\n%s\n' '------------------' "$style" '------------------'
  cat "$output"
done
