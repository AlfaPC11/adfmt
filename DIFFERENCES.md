<!-- SPDX-License-Identifier: BSL-1.0 -->

# adfmt and dfmt differences

adfmt is a source fork of
[dlang-community/dfmt](https://github.com/dlang-community/dfmt), not a clean-room
rewrite. It keeps dfmt's parser, formatter architecture, EditorConfig support,
suppression comments, and most command-line options. The differences below
describe the additional contract maintained by adfmt.

## Configuration

| Area | dfmt | adfmt |
|------|------|-------|
| Project config | `.editorconfig` | `.editorconfig` plus extensionless YAML `.adfmt` |
| Precedence | defaults, EditorConfig, CLI | defaults, EditorConfig, `.adfmt`, CLI |
| Validation | EditorConfig-compatible parsing | unknown keys, duplicate aliases, invalid types, and conflicting spellings are errors |
| Base styles | implicit defaults | `Alfa`, `dfmt`, `Allman`, `K&R`, `Stroustrup`, `OTBS`, `Linux`, `Compact` |
| Whole-project bypass | suppression comments only | `DisableFormat` plus suppression comments |
| Editor assistance | EditorConfig tooling | published JSON schema used by the adfmt VS Code extension |

The nearest `.adfmt` file is loaded by walking from the source file's directory
toward the filesystem root. Nested YAML keys and flat compatibility aliases map
to one canonical option. Supplying two spellings of the same option is rejected
instead of relying on document order.

## Formatting

dfmt exposes one general brace style and later declaration/control overrides.
adfmt adds D-aware categories:

- aggregate bodies: class, interface, struct, and union
- enum bodies
- named function bodies
- function literals: delegates and lambdas
- control-flow and other statement blocks

Each specialized category falls back to its broader parent, so existing dfmt
configuration remains valid.

adfmt also adds:

- independent continuation indentation width
- separate hard and soft line limits in `.adfmt`
- configurable newline and long-line wrapping costs
- readable binary operator break direction (`before` or `after`)
- same-line brace spacing and binary operator spacing
- strict, composable built-in profiles

## Alfa style

The `Alfa` profile defines these D formatting choices:

- 2-space block indentation
- 4-space continuation indentation
- 120-column hard and 100-column soft limits
- Allman aggregate, enum, and named-function bodies
- K&R function literals and control flow
- unindented `case` labels
- binary operators at the end of broken lines
- no space after D `cast(...)`
- LF output

C++-specific concepts such as preprocessor indentation, pointer alignment,
include categories, namespaces, concepts, and constructor initializer lists are
intentionally not copied because D has no direct equivalent.

## Compatibility

The `dfmt` built-in profile is the compatibility baseline. Existing
`.editorconfig` properties, inherited CLI flags, `// dfmt off` and
`// dfmt on`, and ordinary dfmt formatting behavior remain supported.

New adfmt options use the `adfmt_` prefix internally. Existing upstream fields
retain their `dfmt_` names to keep merging and compatibility behavior stable.

## Distribution

dfmt and adfmt have independent package identities and release histories.
adfmt publishes Arch Linux, Debian, RPM, Windows installer, and Windows
portable artifacts from its own GitHub repository.
