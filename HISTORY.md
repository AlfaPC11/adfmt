<!-- SPDX-License-Identifier: BSL-1.0 -->

# Fork history

## Upstream lineage

adfmt descends from
[dlang-community/dfmt](https://github.com/dlang-community/dfmt), originally
created by Brian Schott and maintained by dfmt contributors under the Boost
Software License 1.0.

The fork point is upstream commit `c65d1c8` from May 30, 2026:

> Fix @attr+do/body concatenation and expand issue0601 tests

The upstream remote remains configured as `upstream`. This preserves a clear
path for reviewing and integrating later dfmt maintenance changes.

## adfmt timeline

### June 13, 2026

Commit `1a02438` established Alfa's D Formatter:

- renamed the package and executable to `adfmt`
- added extensionless D-YAML `.adfmt` configuration
- introduced separate declaration and control-flow brace styles
- added strict configuration validation
- recorded upstream attribution, licensing, and the Alfa patent grant

### June 14, 2026

Commit `143422d` completed the first public configuration system:

- added nested and flat option spellings
- added built-in profiles and migration documentation
- expanded parser validation and tests

Commits `1bf9ee3` and `e12de0f` added release packaging and GitHub Actions for
Arch Linux, Debian, RPM, and Windows artifacts.

Tag `v0.3.0` was created from `e12de0f` as the first packaged adfmt release.

Commit `e592d39` expanded brace, spacing, indentation, and wrapping controls;
added additional built-in styles; and introduced configuration examples and an
FAQ.

### Version 0.3.5

The Alfa profile was refined around a compact mixed-brace D style. The
configuration model gained independent aggregate, enum, named-function, and
function-literal brace styles, plus readable binary-operator wrapping
direction. Bash completion was expanded to cover the complete CLI, typed
values, configuration directories, and D source files.

## Maintenance policy

adfmt keeps dfmt-derived code under BSL-1.0 and preserves upstream copyright
notices. Alfa-authored contributions use the same project license; `PATENTS`
grants patent rights only for contributions authored by Alfa.

Upstream fixes should be reviewed for parser compatibility and imported with
their original attribution. adfmt-specific configuration and behavior should
remain isolated enough that future upstream synchronization is practical.
