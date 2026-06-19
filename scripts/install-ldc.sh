#!/bin/sh
# SPDX-License-Identifier: BSL-1.0

set -eu

version=1.42.0
sha256=a7bc9c956138f558cadf9c962352f59d41c80df6eb3ae3f8039f25be14a69303
archive="ldc2-$version-linux-x86_64.tar.xz"
destination=${RUNNER_TEMP:-${TMPDIR:-/tmp}}
archive_path="$destination/$archive"

curl --fail --location --silent --show-error \
  --output "$archive_path" \
  "https://github.com/ldc-developers/ldc/releases/download/v$version/$archive"
printf '%s  %s\n' "$sha256" "$archive_path" | sha256sum --check --strict
tar --extract --xz --directory="$destination" --file="$archive_path"

bin="$destination/ldc2-$version-linux-x86_64/bin"
if [ -n "${GITHUB_PATH:-}" ]; then
  printf '%s\n' "$bin" >> "$GITHUB_PATH"
else
  printf '%s\n' "$bin"
fi
