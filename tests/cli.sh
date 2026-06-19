#!/bin/sh
# SPDX-License-Identifier: BSL-1.0

set -eu

adfmt=${ADFMT_BIN:-../bin/adfmt}
case $adfmt in
  /*) ;;
  *) adfmt=$(cd "$(dirname "$adfmt")" && pwd)/$(basename "$adfmt") ;;
esac

root=$(mktemp -d "${TMPDIR:-/tmp}/adfmt-cli.XXXXXX")
trap 'rm -rf "$root"' EXIT HUP INT TERM

if "$adfmt" "$root/missing.d" >"$root/out" 2>"$root/error"; then
  echo "missing file unexpectedly succeeded" >&2
  exit 1
fi
if grep -q -- '----------------' "$root/error"; then
  echo "missing file leaked a stack trace" >&2
  exit 1
fi

mkdir "$root/tree"
printf 'void main(){}\n' >"$root/outside.d"
ln -s ../outside.d "$root/tree/escape.d"
"$adfmt" --inplace "$root/tree" >"$root/out" 2>"$root/error"
test "$(cat "$root/outside.d")" = 'void main(){}'

printf 'void first(){}\n' >"$root/first.d"
printf '### invalid D source\n' >"$root/broken.d"
if "$adfmt" --inplace "$root/first.d" "$root/broken.d" \
    >"$root/out" 2>"$root/error"; then
  echo "broken batch unexpectedly succeeded" >&2
  exit 1
fi
test "$(cat "$root/first.d")" = 'void first(){}'

mkdir "$root/project"
cat >"$root/project/.editorconfig" <<'EOF'
root = true

[special.d]
indent_size = 7
EOF
printf 'void main(){\nif(true){\n}\n}\n' |
  "$adfmt" --stdin-filename "$root/project/special.d" >"$root/formatted.d"
grep -q '^       if' "$root/formatted.d"

mkdir -p "$root/parent/config"
cat >"$root/parent/.editorconfig" <<'EOF'
[*.d]
indent_size = 8
EOF
cat >"$root/parent/config/.editorconfig" <<'EOF'
[*.d]
indent_size = 3
EOF
printf 'void main(){\nif(true){\n}\n}\n' |
  "$adfmt" --config "$root/parent/config" \
    --stdin-filename "$root/parent/config/input.d" >"$root/exact.d"
grep -q '^   if' "$root/exact.d"

cat >"$root/project/.editorconfig" <<'EOF'
root = true

[*.d]
dfmt_space_after_cast = maybe
EOF
printf 'void main(){}\n' >"$root/project/special.d"
if "$adfmt" "$root/project/special.d" >"$root/out" 2>"$root/error"; then
  echo "invalid EditorConfig boolean unexpectedly succeeded" >&2
  exit 1
fi
grep -q 'invalid boolean' "$root/error"

echo "CLI integration checks passed."
