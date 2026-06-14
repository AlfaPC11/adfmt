<!-- SPDX-License-Identifier: BSL-1.0 -->

# Releasing adfmt

GitHub Actions is the only supported artifact builder. A release tag produces
the Arch Linux, Debian, RPM, Windows portable, Windows installer, and checksum
assets. The local release script validates the checkout and creates the tag; it
does not build a separate legacy archive.

## Prepare

1. Update `pkgver` in `packaging/arch/PKGBUILD`.
2. Regenerate that package's metadata if its sources or dependencies changed.
3. Commit and push every release change to `main`.
4. Ensure local `main` is clean and synchronized with `origin/main`.

The nFPM and Inno Setup definitions receive the version from the workflow and
must continue to use `ADFMT_VERSION`.

The Inno Setup package is a per-user installation and defaults to
`%LOCALAPPDATA%\Programs\adfmt`. Therefore the installed executable is
`%LOCALAPPDATA%\Programs\adfmt\adfmt.exe`. Its command-line integration task
adds the installation directory to the current user's `PATH`; uninstall
removes that exact directory without deleting unrelated `PATH` entries.

## Validate

Run the same metadata, unit, release-build, and regression checks used by the
release helper:

```sh
./release.sh check 0.3.6
```

The equivalent Make target is:

```sh
make release-check VERSION=0.3.6
```

Validation does not create a tag, push commits, or modify a GitHub Release.

## Publish

```sh
./release.sh publish 0.3.6
```

The version has no leading `v`. The command validates the repository, creates
the annotated `v0.3.6` tag, pushes only that tag, waits for the `Release`
workflow, and displays the resulting GitHub Release. It refuses dirty,
diverged, non-`main`, and already-tagged states.

The equivalent Make target is:

```sh
make release VERSION=0.3.6
```

If the tag push itself fails, the newly created local tag is removed. Once a
tag reaches GitHub, failures should be diagnosed in GitHub Actions rather than
reusing or moving the published tag.

## Inspect

```sh
./release.sh status 0.3.6
```

This displays the matching workflow run and GitHub Release without changing
either one.

`release-windows.sh` is retained only as a migration notice. Windows artifacts
are produced natively on GitHub's Windows runner and are not cross-compiled by
the local release process.
