#!/usr/bin/env bash
# SPDX-License-Identifier: BSL-1.0

set -euo pipefail

readonly REPOSITORY="AlfaPC11/adfmt"
readonly WORKFLOW="Release"

die()
{
  printf 'release: %s\n' "$*" >&2
  exit 1
}

usage()
{
  cat <<'EOF'
Usage:
  ./release.sh check <version>
  ./release.sh publish <version>
  ./release.sh status <version>

Commands:
  check    Validate metadata and run release tests without changing Git.
  publish  Run checks, create v<version>, push it, and watch GitHub Actions.
  status   Show the workflow and GitHub Release state for v<version>.

The version must be written without a leading "v", for example 0.3.6.
GitHub Actions builds Arch, DEB, RPM, Windows installer, portable Windows,
and SHA256SUMS assets.
EOF
}

repository_root()
{
  git rev-parse --show-toplevel 2>/dev/null ||
    die "run this command inside the adfmt Git repository"
}

validate_version()
{
  local version=$1
  [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z]+)*$ ]] ||
    die "invalid version '$version'; expected a semantic version without leading v"
}

require_command()
{
  command -v "$1" >/dev/null 2>&1 ||
    die "required command not found: $1"
}

check_metadata()
{
  local version=$1
  local package_version

  package_version=$(
    sed -n 's/^pkgver=//p' packaging/arch/PKGBUILD
  )
  [[ $package_version == "$version" ]] ||
    die "packaging/arch/PKGBUILD has pkgver=$package_version; expected $version"

  grep -Fq 'version: ${ADFMT_VERSION}' packaging/nfpm.yaml ||
    die "packaging/nfpm.yaml must use \${ADFMT_VERSION}"

  grep -Fq '#define MyAppVersion GetEnv("ADFMT_VERSION")' \
    packaging/windows/adfmt.iss ||
    die "Windows installer must read ADFMT_VERSION"

  bash -n PKGBUILD
  bash -n bash-completion/completions/adfmt
  makepkg --printsrcinfo | diff -u .SRCINFO -
}

run_checks()
{
  local version=$1
  local regression_runner="${TMPDIR:-/tmp}/adfmt-release-tests.$$"

  require_command dub
  require_command ldc2
  require_command makepkg

  check_metadata "$version"
  dub test --compiler=ldc2
  dub build --build=release --compiler=ldc2
  ldc2 tests/test.d -of="$regression_runner"
  if ! (
      cd tests
      "$regression_runner"
    ); then
    rm -f "$regression_runner"
    return 1
  fi
  rm -f "$regression_runner"
  git diff --check

  printf 'release: checks passed for %s\n' "$version"
}

require_publish_state()
{
  local version=$1
  local branch

  require_command gh

  branch=$(git branch --show-current)
  [[ $branch == "main" ]] ||
    die "publish must run from main, not '$branch'"
  [[ -z $(git status --porcelain) ]] ||
    die "working tree is not clean"

  git fetch --quiet origin main --tags
  [[ $(git rev-parse HEAD) == $(git rev-parse origin/main) ]] ||
    die "local main and origin/main are not at the same commit"

  if git rev-parse -q --verify "refs/tags/v$version" >/dev/null; then
    die "local tag v$version already exists"
  fi
  if git ls-remote --exit-code --tags origin "refs/tags/v$version" \
      >/dev/null 2>&1; then
    die "remote tag v$version already exists"
  fi

  gh auth status >/dev/null
}

publish_release()
{
  local version=$1
  local run_id

  require_publish_state "$version"
  run_checks "$version"

  git tag -a "v$version" -m "adfmt $version"
  if ! git push origin "refs/tags/v$version"; then
    git tag -d "v$version" >/dev/null
    die "could not push v$version; removed the local tag"
  fi

  printf 'release: waiting for the %s workflow\n' "$WORKFLOW"
  for _ in {1..30}; do
    run_id=$(
      gh run list \
        --repo "$REPOSITORY" \
        --workflow "$WORKFLOW" \
        --branch "v$version" \
        --limit 1 \
        --json databaseId \
        --jq '.[0].databaseId // empty'
    )
    [[ -n $run_id ]] && break
    sleep 2
  done
  [[ -n ${run_id:-} ]] ||
    die "GitHub Actions run did not appear for v$version"

  gh run watch "$run_id" --repo "$REPOSITORY" --exit-status
  gh release view "v$version" --repo "$REPOSITORY"
}

show_status()
{
  local version=$1

  require_command gh
  gh run list \
    --repo "$REPOSITORY" \
    --workflow "$WORKFLOW" \
    --branch "v$version" \
    --limit 1
  gh release view "v$version" --repo "$REPOSITORY"
}

main()
{
  local command=${1:-}
  local version=${2:-}
  local root

  [[ $# -eq 2 ]] || {
    usage
    exit 2
  }
  validate_version "$version"

  root=$(repository_root)
  cd "$root"

  case $command in
    check)
      run_checks "$version"
      ;;
    publish)
      publish_release "$version"
      ;;
    status)
      show_status "$version"
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
