#!/bin/sh
# SPDX-License-Identifier: BSL-1.0

set -eu

REPOSITORY="AlfaPC11/adfmt"
WORKFLOW="Release"

die()
{
  printf 'release: %s\n' "$*" >&2
  exit 1
}

release_tag()
{
  printf 'adfmt-v%s' "$1"
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
  publish  Run checks, create adfmt-v<version>, push it, and watch GitHub Actions.
  status   Show the workflow and GitHub Release state for adfmt-v<version>.

The version must be written without a leading "v", for example 0.4.0.
GitHub Actions builds source, Arch, DEB, RPM, Windows installer, portable
Windows, and SHA256SUMS assets.
EOF
}

repository_root()
{
  git rev-parse --show-toplevel 2>/dev/null ||
    die "run this command inside the adfmt Git repository"
}

validate_version()
{
  version=$1
  printf '%s\n' "$version" |
    grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z]+)*$' ||
    die "invalid version '$version'; expected a semantic version without leading v"
}

require_command()
{
  command -v "$1" >/dev/null 2>&1 ||
    die "required command not found: $1"
}

check_metadata()
{
  version=$1
  package_version=$(sed -n 's/^pkgver=//p' packaging/arch/PKGBUILD)

  [ "$package_version" = "$version" ] ||
    die "packaging/arch/PKGBUILD has pkgver=$package_version; expected $version"

  [ "$(tr -d '\r\n' < VERSION)" = "$version" ] ||
    die "VERSION does not contain $version"

  grep -Fq "version: \${ADFMT_VERSION}" packaging/nfpm.yaml ||
    die "packaging/nfpm.yaml must use \${ADFMT_VERSION}"

  grep -Fq '#define MyAppVersion GetEnv("ADFMT_VERSION")' \
    packaging/windows/adfmt.iss ||
    die "Windows installer must read ADFMT_VERSION"

  sh -n release.sh
  sh -n tests/cli.sh
  bash -n PKGBUILD
  bash -n bash-completion/completions/adfmt
  makepkg --printsrcinfo | diff -u .SRCINFO -
}

run_checks()
{
  version=$1
  temporary_directory=$(mktemp -d "${TMPDIR:-/tmp}/adfmt-release.XXXXXX")
  regression_runner="$temporary_directory/regression-tests"
  trap 'rm -rf "$temporary_directory"' EXIT HUP INT TERM

  require_command dub
  require_command ldc2
  require_command makepkg

  check_metadata "$version"
  dub test --compiler=ldc2
  dub build --build=release --compiler=ldc2
  ldc2 tests/test.d -of="$regression_runner"
  (
    cd tests
    "$regression_runner"
  )
  ADFMT_BIN="$PWD/bin/adfmt" tests/cli.sh
  git diff --check

  rm -rf "$temporary_directory"
  trap - EXIT HUP INT TERM
  printf 'release: checks passed for %s\n' "$version"
}

require_publish_state()
{
  version=$1
  tag=$(release_tag "$version")

  require_command gh

  branch=$(git branch --show-current)
  [ "$branch" = "main" ] ||
    die "publish must run from main, not '$branch'"
  [ -z "$(git status --porcelain)" ] ||
    die "working tree is not clean"

  git fetch --quiet origin main --tags
  [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] ||
    die "local main and origin/main are not at the same commit"

  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    die "local tag $tag already exists"
  fi
  if git ls-remote --exit-code --tags origin "refs/tags/$tag" \
      >/dev/null 2>&1; then
    die "remote tag $tag already exists"
  fi

  gh auth status >/dev/null
}

publish_release()
{
  version=$1
  tag=$(release_tag "$version")

  require_publish_state "$version"
  run_checks "$version"

  git tag -a "$tag" -m "adfmt $version"
  if ! git push origin "refs/tags/$tag"; then
    git tag -d "$tag" >/dev/null
    die "could not push $tag; removed the local tag"
  fi

  printf 'release: waiting for the %s workflow\n' "$WORKFLOW"
  run_id=
  attempt=0
  while [ "$attempt" -lt 30 ]; do
    run_id=$(
      gh run list \
        --repo "$REPOSITORY" \
        --workflow "$WORKFLOW" \
        --branch "$tag" \
        --limit 1 \
        --json databaseId \
        --jq '.[0].databaseId // empty'
    )
    [ -n "$run_id" ] && break
    sleep 2
    attempt=$((attempt + 1))
  done
  [ -n "$run_id" ] ||
    die "GitHub Actions run did not appear for $tag"

  gh run watch "$run_id" --repo "$REPOSITORY" --exit-status
  gh release view "$tag" --repo "$REPOSITORY"
}

show_status()
{
  version=$1
  tag=$(release_tag "$version")

  require_command gh
  gh run list \
    --repo "$REPOSITORY" \
    --workflow "$WORKFLOW" \
    --branch "$tag" \
    --limit 1
  gh release view "$tag" --repo "$REPOSITORY"
}

main()
{
  command=${1:-}
  version=${2:-}

  [ "$#" -eq 2 ] || {
    usage
    exit 2
  }
  validate_version "$version"

  root=$(repository_root)
  cd "$root"

  case $command in
    check) run_checks "$version" ;;
    publish) publish_release "$version" ;;
    status) show_status "$version" ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
