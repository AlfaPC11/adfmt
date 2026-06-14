<!-- SPDX-License-Identifier: BSL-1.0 -->

# adfmt, dfmt, and clang-format

adfmt is a source fork of
[dlang-community/dfmt](https://github.com/dlang-community/dfmt), not a
clean-room rewrite. It retains dfmt's D parser, formatter architecture,
EditorConfig support, suppression comments, and most command-line options.

[clang-format](https://clang.llvm.org/docs/ClangFormat.html) is an independent
formatter from the LLVM project. It is included here because its broad
configuration model is a design reference for adfmt, not because adfmt wraps,
embeds, or claims compatibility with clang-format.

## At a glance

| Area | dfmt | adfmt | clang-format |
|------|------|-------|--------------|
| Primary languages | D | D | C, C++, Objective-C, Java, JavaScript, JSON, C#, and other supported LLVM modes |
| Parser/engine | libdparse-based D formatter | Forked dfmt/libdparse architecture | LLVM's language-specific parsers and token annotators |
| Main project config | `.editorconfig` | `.editorconfig` and extensionless YAML `.adfmt` | YAML `.clang-format` or `_clang-format` |
| Config discovery | EditorConfig rules | nearest `.adfmt` plus applicable EditorConfig files | parent-directory search, explicit file, or inline style |
| Config precedence | defaults, EditorConfig, CLI | defaults, EditorConfig, `.adfmt`, CLI | base style, config document, CLI overrides |
| Unknown option handling | limited by EditorConfig parsing | error | error for unsupported keys in the active version |
| Built-in styles | formatter defaults | `Alfa`, `Dfmt`, `Allman`, `Knr`, `Stroustrup`, `Otbs`, `Linux`, `Compact` | LLVM, Google, Chromium, Mozilla, WebKit, Microsoft, GNU, InheritParentConfig |
| Syntax-specific brace control | general declaration/control options | aggregates, enums, functions, function literals, and control flow | extensive wrapping rules, but organized around clang-format's supported language syntax |
| Whole-file disable | suppression comments | `DisableFormat` and suppression comments | `DisableFormat` and formatting off/on comments |
| Editor integration | external integrations | CLI plus dedicated VS Code extension/schema | broad editor ecosystem and clangd integrations |
| In-place operation | supported | explicit `--inplace`/`--in-place`; guarded for ambiguous inputs | `-i` |

The tools are not interchangeable. dfmt and adfmt understand D syntax.
clang-format does not provide a D language mode, so feeding D source to one of
its other modes cannot reliably reproduce D-aware formatting.

## Relationship to dfmt

adfmt begins with dfmt's implementation and preserves upstream behavior where
possible. The `Dfmt` built-in profile is the compatibility baseline. Existing
EditorConfig properties, inherited CLI flags, `// dfmt off`, `// dfmt on`, and
ordinary dfmt formatting remain supported.

New adfmt options use the `adfmt_` prefix internally. Upstream fields retain
their `dfmt_` names so that compatibility and future source comparison remain
clear. Fork provenance and release history are documented in
[HISTORY.md](HISTORY.md).

## Configuration model

### dfmt

dfmt primarily uses EditorConfig. This is portable and familiar, but its flat
key/value model is less suitable for a growing hierarchy of formatter options.
The available settings focus on dfmt's established indentation, spacing,
wrapping, and brace behavior.

### adfmt

adfmt adds an extensionless `.adfmt` file using YAML syntax. The nearest file
is found by walking from the formatted source file toward the filesystem root.
Nested keys and supported flat compatibility aliases resolve to canonical
options.

The configuration contract is deliberately strict:

- option names and symbolic values are PascalCase and case-sensitive
- unknown keys are rejected
- duplicate aliases for the same canonical option are rejected
- conflicting spellings are rejected instead of relying on YAML document order
- invalid types and enum values produce configuration errors
- standard YAML booleans remain `true` and `false`
- the published schema drives validation and completion in the VS Code extension

The effective precedence is defaults, EditorConfig, `.adfmt`, then explicit CLI
arguments. This permits gradual migration from dfmt without making project
configuration weaker than command-line intent.

### clang-format

clang-format also uses YAML and provides a much larger option surface developed
over many LLVM releases. Its configuration can inherit a named base style,
contain language-specific sections, inherit a parent configuration, and expose
version-dependent options.

adfmt follows the useful principle of a declarative, discoverable YAML style
file, but not clang-format's key names or parser. A `.clang-format` file cannot
be renamed to `.adfmt`, and `.adfmt` is not intended to be accepted by
clang-format.

## Formatting categories

dfmt exposes a general brace style with declaration and control-flow
overrides. adfmt divides D syntax into categories that can fall back to a
broader parent:

| Category | Typical D constructs |
|----------|----------------------|
| Aggregates | `class`, `interface`, `struct`, `union` |
| Enums | named and anonymous enum bodies |
| Named functions | functions, methods, constructors, destructors |
| Function literals | delegates, lambdas, anonymous functions |
| Control flow | `if`, `else`, `for`, `foreach`, `while`, `switch`, `try`, `catch` |

This makes declaration-oriented Allman formatting possible without forcing
Allman braces onto control flow. clang-format offers similarly fine-grained
control in many areas, but its categories describe C-family syntax and cannot
serve as a D parser.

## Wrapping and spacing

Beyond inherited dfmt options, adfmt provides:

- independent continuation indentation width
- separate hard and soft line limits
- configurable newline and long-line wrapping costs
- readable binary operator break direction, `Before` or `After`
- same-line brace spacing
- binary operator spacing
- composable built-in profiles

clang-format has substantially more mature controls for include sorting,
preprocessor indentation, pointer and reference alignment, namespace
indentation, constructor initializer lists, concepts, macros, comments, and
language-specific token rules. Those options are not copied when D has no
sound equivalent. adfmt's goal is broad D formatting control, not option-count
parity obtained through irrelevant settings.

## Alfa style

The `Alfa` profile currently establishes:

- 2-space block indentation
- 4-space continuation indentation
- 120-column hard and 100-column soft limits
- Allman aggregate, enum, and named-function bodies
- K&R function literals and control flow
- unindented `case` labels
- binary operators at the end of broken lines
- no space after D `cast(...)`
- LF output

The visual direction is comparable to a selectively configured clang-format
style: declarations are vertically separated while short-lived control flow
stays compact. The result is implemented with D syntax categories rather than
by translating a C++ `.clang-format` file.

## CLI and safety

dfmt and clang-format historically expose direct in-place formatting. adfmt
keeps that capability but requires `--inplace`, `--in-place`, or `-i` for
multiple paths and directories, rejects it for standard input, and never
enables it implicitly. A single explicit file without the flag is formatted to
standard output.

adfmt also reports strict configuration failures through a nonzero exit status.
The full input modes, precedence rules, and exit behavior are documented in
[docs/cli.md](docs/cli.md).

## Suppression

All three projects support local formatting suppression concepts. adfmt keeps
dfmt's `// dfmt off` and `// dfmt on` comments for source compatibility and
adds configuration-level `DisableFormat` for a project or directory tree.
clang-format has its own off/on comment handling and configuration-level
disable option; the exact accepted comments and syntax are tool-specific.

## Compatibility boundaries

- adfmt is source-compatible with much of dfmt, but new strict `.adfmt`
  validation may intentionally reject ambiguous configuration.
- `.editorconfig` remains the shared migration path between dfmt and adfmt.
- `.adfmt` and `.clang-format` are separate YAML dialects with separate schemas.
- clang-format cannot safely format D by pretending it is C++, Java, or another
  supported language.
- adfmt does not sort D imports or rewrite source semantically unless a
  documented formatter option explicitly controls that behavior.
- Formatter output may change as parser fixes and options evolve; pinning the
  formatter version is recommended for CI.

## Distribution

dfmt, adfmt, and clang-format have independent package identities, licenses,
release histories, and versioning. adfmt publishes Arch Linux, Debian, RPM,
Windows installer, and Windows portable artifacts from its own GitHub
repository. Its releases do not replace or redistribute dfmt or clang-format
under those projects' package names.
