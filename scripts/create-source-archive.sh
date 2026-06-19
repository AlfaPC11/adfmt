#!/bin/sh
# SPDX-License-Identifier: BSL-1.0

set -eu

if [ "$#" -ne 2 ]; then
  echo "usage: create-source-archive.sh <version> <output.tar.gz>" >&2
  exit 2
fi

version=$1
output=$2
temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/adfmt-source.XXXXXX")
trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

git ls-files -z -- . ':(exclude)packaging/arch/**' \
  >"$temporary_directory/files"
tar --create --null --no-recursion \
  --files-from="$temporary_directory/files" \
  --sort=name \
  --mtime='@0' \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --transform="s,^,adfmt-$version/," \
  --file="$temporary_directory/source.tar"
gzip -n -c "$temporary_directory/source.tar" >"$output"
