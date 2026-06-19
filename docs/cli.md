<!-- SPDX-License-Identifier: BSL-1.0 -->

# Command-line reference

## Synopsis

```text
adfmt [options] [file-or-directory ...]
```

## Input modes

| Invocation | Input | Output |
|------------|-------|--------|
| `adfmt` | stdin | stdout |
| `adfmt file.d` | one file | stdout |
| `adfmt --inplace file.d` | one file | replaces the file |
| `adfmt --inplace first.d second.d` | multiple files | replaces the files |
| `adfmt --inplace source/` | every `.d` file below the directory | replaces the files |

All outputs are prepared before `--inplace` replaces any source. Replacement
uses temporary files beside the originals and attempts to restore every
original if committing the batch fails. Directory traversal is recursive and
skips symbolic links. An explicitly supplied symbolic link is rejected for
in-place formatting. Multiple paths and directories are rejected unless
`--inplace` is explicitly present.

## General options

| Option | Value | Effect |
|--------|-------|--------|
| `--help`, `-h` | none | Print built-in help and exit. |
| `--version` | none | Print the build version and exit. |
| `--inplace`, `--in-place`, `-i` | none | Safely replace the complete successfully formatted batch. |
| `--stdin-filename` | path | Use a source path for configuration and diagnostics while reading stdin. |
| `--config`, `-c` | existing directory | Load `.editorconfig` and `.adfmt` only from that directory. |

Without `--config`, adfmt searches for the nearest `.adfmt` from each source
file toward the filesystem root. EditorConfig follows its normal cascading
rules.

## Indentation and line options

| Option | Value | Effect |
|--------|-------|--------|
| `--indent_size` | positive integer | Block indentation width. |
| `--continuation_indent_width` | positive integer | Wrapped-line indentation width. |
| `--tab_width` | positive integer | Display width of a tab. |
| `--indent_style`, `-t` | `tab`, `space` | Select block indentation characters. |
| `--indent_case_labels` | boolean | Indent `case` and `default` labels. |
| `--align_switch_statements` | boolean | Legacy inverse of `--indent_case_labels`. |
| `--outdent_attributes` | boolean | Outdent supported declaration attributes. |
| `--end_of_line` | `_default`, `lf`, `cr`, `crlf` | Select emitted line endings. |
| `--max_line_length` | positive integer | Hard line-length limit. |
| `--soft_max_line_length` | positive integer | Preferred line-length limit. |

The soft limit must not exceed the hard limit.

## Brace options

Every brace option accepts `allman`, `otbs`, `stroustrup`, or `knr`.

| Option | Scope |
|--------|-------|
| `--brace_style` | Fallback for ordinary blocks. |
| `--declaration_brace_style` | Fallback for declaration bodies. |
| `--aggregate_brace_style` | Classes, interfaces, structs, and unions. |
| `--enum_brace_style` | Enum bodies. |
| `--function_brace_style` | Named function bodies. |
| `--function_literal_brace_style` | Delegates and lambdas. |
| `--control_brace_style` | Control-flow and statement blocks. |

More specific options override broader options.

## Spacing options

These options accept an explicit `true` or `false`.

| Option | Effect when `true` |
|--------|--------------------|
| `--space_after_cast` | Add a space after `cast(...)`. |
| `--space_after_keywords` | Add a space between control keywords and `(`. |
| `--space_before_function_parameters` | Add a space before function parameter lists. |
| `--space_before_braces` | Add a space before same-line opening braces. |
| `--space_around_binary_operators` | Add spaces around binary operators. |
| `--selective_import_space` | Add a space before `:` in selective imports. |
| `--space_before_aa_colon` | Add a space before associative-array colons. |
| `--space_before_named_arg_colon` | Add a space before named-argument colons. |

## Wrapping options

| Option | Value | Effect |
|--------|-------|--------|
| `--keep_line_breaks` | boolean | Preserve compatible source line breaks. |
| `--single_indent` | boolean | Use one continuation level inside parentheses. |
| `--reflow_property_chains` | boolean | Recalculate property and UFCS chain breaks. |
| `--split_operator_at_line_end` | boolean | Keep split binary operators on the preceding line. |
| `--template_constraint_style` | enum | Select template-constraint wrapping. |
| `--single_template_constraint_indent` | boolean | Use one indentation level for indented constraints. |
| `--wrapping_newline_penalty` | positive integer | Cost assigned to a new line. |
| `--wrapping_long_line_penalty` | positive integer | Cost per column beyond the soft limit. |

`--template_constraint_style` accepts:

- `conditional_newline_indent`
- `conditional_newline`
- `always_newline`
- `always_newline_indent`

Lower newline penalties encourage wrapping. Higher long-line penalties more
strongly discourage exceeding the soft limit.

## Statement options

| Option | Value | Effect |
|--------|-------|--------|
| `--compact_labeled_statements` | boolean | Keep supported labeled statements on the label line. |

## Precedence

Configuration is merged in this order:

1. built-in defaults
2. `.editorconfig`
3. `.adfmt`
4. command-line options

Later sources override earlier sources.

## Exit status

| Code | Meaning |
|------|---------|
| `0` | Formatting or informational command succeeded. |
| `1` | Invalid arguments, invalid configuration, parsing failure, or formatting failure. |

## Examples

Preview one file:

```sh
adfmt source/app.d
```

Format a tree in place:

```sh
adfmt --inplace source/
```

Override the project style temporarily:

```sh
adfmt --function_brace_style=allman \
  --control_brace_style=knr \
  --indent_size=2 \
  source/app.d
```

Use a dedicated configuration directory:

```sh
adfmt --config=config/formatting --inplace source/
```

Format editor input while retaining file-specific configuration:

```sh
adfmt --stdin-filename=source/app.d < source/app.d
```
