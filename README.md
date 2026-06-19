# adfmt

**adfmt** is Alfa's D Formatter, a fork of **dfmt** with a validated YAML
configuration system and independently configurable D syntax categories.

Upstream project: <https://github.com/dlang-community/dfmt>

## Why adfmt?

adfmt keeps dfmt's D-aware formatting engine while adding a project-local,
extensionless YAML configuration file. It is useful when one brace style is
not enough: declarations can use Allman braces while control-flow statements
continue to use K&R braces. Configuration mistakes fail loudly instead of
being silently ignored, and the same `.adfmt` file works from the command line
and the adfmt VS Code extension.

## adfmt and dfmt

| Capability | dfmt | adfmt |
|------------|------|-------|
| D-aware formatting | Yes | Yes, inherited from dfmt |
| EditorConfig | Yes | Yes |
| Extensionless YAML config | No | Yes, `.adfmt` |
| Separate brace categories | No | Aggregates, enums, functions, function literals, and control flow |
| Built-in styles | No | `Alfa`, `Dfmt`, `Allman`, `Knr`, `Stroustrup`, `Otbs`, `Linux`, `Compact` |
| Unknown-key validation | No | Yes |
| Disable an entire project config | No | `DisableFormat` |
| Configurable wrapping costs | No | Yes |
| Binary operator break direction | Boolean CLI/EditorConfig option | Readable `Before`/`After` YAML option |

adfmt remains source-derived from dfmt. It is not a rewrite and deliberately
keeps dfmt-compatible command-line and EditorConfig options where possible.
See [DIFFERENCES.md](DIFFERENCES.md) for the detailed comparison and
[HISTORY.md](HISTORY.md) for fork provenance.

## Status
**adfmt** is beta quality. `--inplace` stages complete batches, uses atomic
per-file replacement, and rolls back replacements on failure. Source control
is still recommended for reviewing formatter changes.

## Installation

### GitHub Releases

Versioned packages are published on
[GitHub Releases](https://github.com/AlfaPC11/adfmt/releases):

* Arch Linux: `.pkg.tar.zst`
* Debian and Ubuntu: `.deb`
* Fedora and other RPM-based distributions: `.rpm`
* Windows x86-64: Inno Setup installer `.exe` and portable `.exe`

The Windows installer places the executable at
`%LOCALAPPDATA%\Programs\adfmt\adfmt.exe` by default. Its checked
command-line integration task adds `%LOCALAPPDATA%\Programs\adfmt` to the
current user's `PATH`, so new terminals can invoke `adfmt` directly. The
installer removes only that entry from the user `PATH` during uninstall.
See [docs/windows.md](docs/windows.md) for installer, portable executable, and
PATH details.

### Installing with DUB

```sh
> dub run adfmt -- -h
```

### Building from source using Make
* Clone the repository
* Run ```git submodule update --init --recursive``` in the adfmt directory
* To compile with DMD, run ```make``` in the adfmt directory. To compile with
  LDC, run ```make ldc``` instead. The generated binary will be placed in
  ```adfmt/bin/```.

### Building from source using dub
* Clone the repository
* run `dub build --build=release`, optionally with `--compiler=ldc2`

### Bash completion

Linux packages install completion automatically. For a source checkout:

```sh
source bash-completion/completions/adfmt
```

Completion covers every CLI option, boolean and enum values,
`--option=value`, configuration directories, and D source paths.

### Maintainer releases

Release validation, tagging, package generation, and recovery behavior are
documented in [docs/releasing.md](docs/releasing.md). Release artifacts are
built by GitHub Actions rather than by local platform-specific archive scripts.

## Using
By default, adfmt reads its input from **stdin** and writes to **stdout**.
If a file name is specified on the command line, input will be read from the
file instead, and output will be written to **stdout**.

**adfmt** uses extensionless `.adfmt` YAML files and
[EditorConfig](http://editorconfig.org/) files for configuration. If you run **adfmt** on a
source file it will look for the nearest `.adfmt` and for `.editorconfig` files
that apply to that source file.
If no file is specified on the command line, **adfmt** will look for *.editorconfig*
files that would apply to a D file in the current working directory and for an
`.adfmt` in that directory or its parents. Precedence is defaults,
`.editorconfig`, `.adfmt`, then command-line options.

### Options

The complete input-mode, value, precedence, and exit-status reference is in
[docs/cli.md](docs/cli.md). `adfmt --help` includes the same option-level
descriptions for offline use.

* `--help | -h`: Display command line options.
* `--inplace | --in-place | -i`: Safely replace a complete formatted batch.
  Symbolic links are skipped during directory traversal and rejected when
  supplied directly.
* `--stdin-filename`: Apply file-specific configuration while reading source
  from standard input; intended for editor integrations.
* `--align_switch_statements`: *see dfmt_align_switch_statements [below](#dfmt-specific-properties)*
* `--brace_style`: *see dfmt_brace_style [below](#dfmt-specific-properties)*
* `--declaration_brace_style`: *see dfmt_declaration_brace_style [below](#dfmt-specific-properties)*
* `--aggregate_brace_style`: override brace style for class, interface, struct, and union bodies.
* `--enum_brace_style`: override brace style for enum bodies.
* `--function_brace_style`: override brace style for function bodies.
* `--function_literal_brace_style`: override brace style for delegates and lambdas.
* `--control_brace_style`: *see dfmt_control_brace_style [below](#dfmt-specific-properties)*
* `--compact_labeled_statements`: *see dfmt_compact_labeled_statements [below](#dfmt-specific-properties)*
* `--end_of_line`: *see end_of_line [below](#standard-editorconfig-properties)*
* `--indent_size`: *see indent_size [below](#standard-editorconfig-properties)*
* `--continuation_indent_width`: indentation width for wrapped lines.
* `--indent_style | -t`: *see indent_style [below](#standard-editorconfig-properties)*
* `--max_line_length`: *see max_line_length [below](#standard-editorconfig-properties)*
* `--outdent_attributes`: *see dfmt_outdent_attributes [below](#dfmt-specific-properties)*
* `--selective_import_space`: *see dfmt_selective_import_space [below](#dfmt-specific-properties)*
* `--single_template_constraint_indent`: *see dfmt_single_template_constraint_indent [below](#dfmt-specific-properties)*
* `--soft_max_line_length`: *see dfmt_soft_max_line_length [below](#dfmt-specific-properties)*
* `--space_after_cast`: *see dfmt_space_after_cast [below](#dfmt-specific-properties)*
* `--space_before_aa_colon`: *see dfmt_space_before_aa_colon [below](#dfmt-specific-properties)*
* `--space_before_named_arg_colon`: *see dfmt_space_before_named_arg_colon [below](#dfmt-specific-properties)*
* `--space_before_function_parameters`: *see dfmt_space_before_function_parameters [below](#dfmt-specific-properties)*
* `--split_operator_at_line_end`: *see dfmt_split_operator_at_line_end [below](#dfmt-specific-properties)*
* `--tab_width`: *see tab_width [below](#standard-editorconfig-properties)*
* `--template_constraint_style`: *see dfmt_template_constraint_style [below](#dfmt-specific-properties)*
* `--keep_line_breaks`: *see dfmt_keep_line_breaks [below](#dfmt-specific-properties)*
* `--single_indent`: *see dfmt_single_indent [below](#dfmt-specific-properties)*
* `--reflow_property_chains`: *see dfmt_property_chains [below](#dfmt-specific-properties)*
* `--space_after_keywords`: *see dfmt_space_after_keywords [below](#dfmt-specific-properties)*
* `--space_before_braces`: insert a space before same-line opening braces.
* `--space_around_binary_operators`: insert spaces around binary operators.
* `--indent_case_labels`: indent `case` and `default` labels.
* `--wrapping_newline_penalty`: cost assigned to inserting a line break.
* `--wrapping_long_line_penalty`: cost per column beyond the soft limit.

### Example
```
adfmt --inplace --space_after_cast=false --max_line_length=80 \
    --soft_max_line_length=70 --brace_style=otbs file.d
```

## Disabling formatting
Formatting can be temporarily disabled by placing the comments ```// dfmt off```
and ```// dfmt on``` around code that you do not want formatted.

```d
void main(string[] args)
{
    bool optionOne, optionTwo, optionThree;

    // dfmt has no way of knowing that "getopt" is special, so it wraps the
    // argument list normally
    getopt(args, "optionOne", &optionOne, "optionTwo", &optionTwo, "optionThree", &optionThree);

    // dfmt off
    getopt(args,
        "optionOne", &optionOne,
        "optionTwo", &optionTwo,
        "optionThree", &optionThree);
    // dfmt on
}
```

## Configuration
### .adfmt

`.adfmt` is parsed by D-YAML. Its nested form groups related settings while
flat clang-format-like aliases are also accepted.

The complete option reference is in
[docs/configuration.md](docs/configuration.md). Ready-to-use profiles are in
[examples](examples), and existing dfmt users can follow the
[migration guide](docs/migration-from-dfmt.md).

See also the [usage examples](docs/examples.md) and
[frequently asked questions](docs/faq.md).

```yaml
BasedOnStyle: Alfa
DisableFormat: false
ColumnLimit: 120
SoftColumnLimit: 100
LineEnding: Lf

Indent:
  Width: 2
  ContinuationWidth: 4
  TabWidth: 2
  Style: Space
  AlignSwitchStatements: true
  OutdentAttributes: true
  SingleContinuationIndent: false

Braces:
  Default: Allman
  Declarations: Allman
  Aggregates: Allman
  Enums: Allman
  Functions: Allman
  FunctionLiterals: Knr
  ControlStatements: Knr

Spacing:
  AfterCast: false
  AfterKeywords: true
  BeforeFunctionParameters: false
  SelectiveImports: true
  BeforeAssociativeArrayColon: false
  BeforeNamedArgumentColon: false

Wrapping:
  KeepExistingLineBreaks: false
  BinaryOperators: After
  ReflowPropertyChains: true
  TemplateConstraints: ConditionalNewlineIndent
  SingleTemplateConstraintIndent: false

Statements:
  CompactLabels: true
```

`BasedOnStyle` is applied first regardless of its position in the YAML file.
Later options override the selected style. Unknown keys, duplicate aliases, and
invalid values are errors so spelling mistakes cannot silently change
formatting.

### EditorConfig

**adfmt** also uses [EditorConfig](http://editorconfig.org/) configuration files.
**dfmt**-specific properties are prefixed with *dfmt_*.
### Standard EditorConfig properties
Property Name | Allowed Values | Description
--------------|----------------|------------
end_of_line | `cr`, `crlf` and `lf` | [See EditorConfig documentation.](https://github.com/editorconfig/editorconfig/wiki/EditorConfig-Properties#end_of_line) When not set, `dfmt` adopts the first line ending in the input.
insert_final_newline | **`true`** | Not supported. `dfmt` always inserts a final newline.
charset | **`UTF-8`** | Not supported. `dfmt` only works correctly on UTF-8.
indent_style | `tab`, **`space`** | [See EditorConfig documentation.](https://github.com/editorconfig/editorconfig/wiki/EditorConfig-Properties#indent_style)
indent_size | positive integers (**`4`**) | [See EditorConfig documentation.](https://github.com/editorconfig/editorconfig/wiki/EditorConfig-Properties#indent_size)
tab_width | positive integers (**`4`**) | [See EditorConfig documentation.](https://github.com/editorconfig/editorconfig/wiki/EditorConfig-Properties#tab_width)
trim_trailing_whitespace | **`true`** | Not supported. `dfmt` does not emit trailing whitespace.
max_line_length | positive integers (**`120`**) | [See EditorConfig documentation.](https://github.com/editorconfig/editorconfig/wiki/EditorConfig-Properties#max_line_length)
### dfmt-specific properties
Property Name | Allowed Values | Description
--------------|----------------|------------
dfmt_brace_style | **`allman`**, `otbs`, `stroustrup` or `knr` | [See Wikipedia](https://en.wikipedia.org/wiki/Brace_style)
dfmt_declaration_brace_style | `allman`, `otbs`, `stroustrup` or `knr` | Override the brace style for function, class, struct, union, and enum bodies.
dfmt_control_brace_style | `allman`, `otbs`, `stroustrup` or `knr` | Override the brace style for control-flow and other non-declaration blocks.
dfmt_soft_max_line_length | positive integers (**`80`**) | The formatting process will usually keep lines below this length, but they may be up to *max_line_length* columns long.
dfmt_align_switch_statements | **`true`**, `false` | Align labels, cases, and defaults with their enclosing switch.
dfmt_outdent_attributes (Not yet implemented) | **`true`**, `false`| Decrease the indentation level of attributes.
dfmt_split_operator_at_line_end | `true`, **`false`** | Place operators on the end of the previous line when splitting lines.
dfmt_space_after_cast | **`true`**, `false` | Insert space after the closing paren of a `cast` expression.
dfmt_space_after_keywords | **`true`**, `false` | Insert space after `if`, `while`, `foreach`, etc, and before the `(`.
dfmt_space_before_function_parameters | `true`, **`false`** | Insert space before the opening paren of a function parameter list.
dfmt_selective_import_space | **`true`**, `false` | Insert space after the module name and before the `:` for selective imports.
dfmt_compact_labeled_statements | **`true`**, `false` | Place labels on the same line as the labeled `switch`, `for`, `foreach`, or `while` statement.
dfmt_template_constraint_style | **`conditional_newline_indent`** `conditional_newline` `always_newline` `always_newline_indent` | Control the formatting of template constraints.
dfmt_single_template_constraint_indent | `true`, **`false`** | Set if the constraints are indented by a single tab instead of two. Has only an effect if the style set to `always_newline_indent` or `conditional_newline_indent`.
dfmt_space_before_aa_colon | `true`, **`false`** | Adds a space after an associative array key before the `:` like in older dfmt versions.
dfmt_space_before_named_arg_colon | `true`, **`false`** | Adds a space after a named function argument or named struct constructor argument before the `:`.
dfmt_keep_line_breaks | `true`, **`false`** | Keep existing line breaks if these don't violate other formatting rules.
dfmt_single_indent | `true`, **`false`** | Set if the code in parens is indented by a single tab instead of two.
dfmt_reflow_property_chains | **`true`**, `false` | Recalculate the splitting of property chains into multiple lines.

## Terminology
* Braces - `{` and `}`
* Brackets - `[` and `]`
* Parenthesis / Parens  - `(` and `)`

## License and patents

adfmt follows upstream dfmt and is licensed under the
[Boost Software License 1.0](LICENSE.txt), SPDX identifier `BSL-1.0`.

The [PATENTS](PATENTS) file grants patent rights only for contributions
authored by Alfa. It does not claim or grant patent rights belonging to
upstream dfmt contributors or other third parties. Attribution and fork
provenance are recorded in [NOTICE](NOTICE).
