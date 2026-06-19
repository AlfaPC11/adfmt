<!-- SPDX-License-Identifier: BSL-1.0 -->

# Changelog

## 0.4.0 - 2026-06-19

- Added staged, rollback-capable `--inplace` replacement.
- Skipped symbolic links during recursive formatting and rejected direct
  in-place symbolic-link inputs.
- Added `--stdin-filename` for editor integrations and file-specific config.
- Made `--config` stop EditorConfig lookup at the requested directory.
- Replaced raw exception traces with concise diagnostics.
- Tightened EditorConfig booleans and bounded `.adfmt` YAML resource use.
- Removed shell interpolation from build-version discovery.
- Hardened CI, packaging, release downloads, and Windows installation.
- Moved adfmt releases to collision-free `adfmt-v<version>` tags.
