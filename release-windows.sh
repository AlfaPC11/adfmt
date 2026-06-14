#!/usr/bin/env bash
# SPDX-License-Identifier: BSL-1.0

set -euo pipefail

cat >&2 <<'EOF'
release-windows.sh is no longer a standalone cross-compilation path.

Windows portable and Inno Setup packages are built by GitHub Actions.
Use:

  ./release.sh check <version>
  ./release.sh publish <version>
EOF

exit 2
