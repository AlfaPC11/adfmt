<!-- SPDX-License-Identifier: BSL-1.0 -->

# .adfmt configuration

adfmt searches from the formatted source file's directory toward the file
system root and loads the nearest extensionless `.adfmt` file. When stdin is
used, the search starts in the current working directory.

Configuration precedence, from lowest to highest, is:

1. adfmt defaults
2. `.editorconfig`
3. `.adfmt`
4. command-line options

`.adfmt` is YAML parsed by D-YAML. Keys are case-sensitive. Values documented
as names are case-insensitive, and hyphens may be used in template constraint
style values.

## Built-in styles

`BasedOnStyle` establishes a complete configuration before other keys are
applied. Its position in the YAML document does not affect precedence.

### Alfa

The `Alfa` profile uses 4-space indentation, a 120-column hard limit, a
100-column soft limit, LF line endings, Allman declaration braces, and K&R
control-flow braces.

```yaml
BasedOnStyle: Alfa
```

### Other profiles

| Profile | Main behavior |
|---------|---------------|
| `dfmt` | Upstream-compatible defaults and Allman braces |
| `Allman` | Every supported brace category starts on a new line |
| `K&R` | K&R function braces and same-line control braces |
| `Stroustrup` | Same-line opening braces; `else`, `catch`, and `finally` start on new lines |
| `OTBS` | Opening braces and continuation keywords stay on the same line |
| `Linux` | Tabs of width 8, Allman type declarations, K&R functions and controls |
| `Compact` | Two-space indentation, 100 columns, OTBS braces |

```yaml
BasedOnStyle: Stroustrup
```

When `BasedOnStyle` is omitted, no complete profile is applied. Only keys
written in `.adfmt` override lower-precedence EditorConfig values.

## Option reference

| Nested key | Flat alias | Values | Alfa default |
|------------|------------|--------|--------------|
| `Language` | - | `D` | `D` |
| `BasedOnStyle` | - | `Alfa`, `dfmt`, `Allman`, `K&R`, `Stroustrup`, `OTBS`, `Linux`, `Compact` | no profile |
| `DisableFormat` | - | `true`, `false` | `false` |
| `ColumnLimit` | - | positive integer | `120` |
| `SoftColumnLimit` | - | positive integer, at most `ColumnLimit` | `100` |
| `LineEnding` | - | `default`, `lf`, `cr`, `crlf` | `lf` |
| `Indent.Width` | `IndentWidth` | positive integer | `4` |
| `Indent.ContinuationWidth` | `ContinuationIndentWidth` | positive integer | `4` |
| `Indent.TabWidth` | `TabWidth` | positive integer | `4` |
| `Indent.Style` | `UseTab` | `space`, `tab`, `never`, `always` | `space` |
| `Indent.AlignSwitchStatements` | `AlignSwitchStatements` | boolean | `true` |
| `Indent.CaseLabels` | `IndentCaseLabels` | boolean | `false` |
| `Indent.OutdentAttributes` | `OutdentAttributes` | boolean | `true` |
| `Indent.SingleContinuationIndent` | `SingleIndent` | boolean | `false` |
| `Braces.Default` | `BraceStyle` | `allman`, `otbs`, `stroustrup`, `knr` | `allman` |
| `Braces.Declarations` | `DeclarationBraceStyle` | brace style | `allman` |
| `Braces.Functions` | `FunctionBraceStyle` | brace style | inherits declarations |
| `Braces.ControlStatements` | `ControlBraceStyle` | brace style | `knr` |
| `Spacing.AfterCast` | `SpaceAfterCast` | boolean | `true` |
| `Spacing.AfterKeywords` | `SpaceAfterKeywords` | boolean | `true` |
| `Spacing.BeforeFunctionParameters` | `SpaceBeforeFunctionParameters` | boolean | `false` |
| `Spacing.SelectiveImports` | `SelectiveImportSpace` | boolean | `true` |
| `Spacing.BeforeAssociativeArrayColon` | `SpaceBeforeAssociativeArrayColon` | boolean | `false` |
| `Spacing.BeforeNamedArgumentColon` | `SpaceBeforeNamedArgumentColon` | boolean | `false` |
| `Spacing.BeforeBraces` | `SpaceBeforeBraces` | boolean | `true` |
| `Spacing.AroundBinaryOperators` | `SpaceAroundBinaryOperators` | boolean | `true` |
| `Wrapping.KeepExistingLineBreaks` | `KeepLineBreaks` | boolean | `false` |
| `Wrapping.SplitOperatorAtLineEnd` | `SplitOperatorAtLineEnd` | boolean | `false` |
| `Wrapping.ReflowPropertyChains` | `ReflowPropertyChains` | boolean | `true` |
| `Wrapping.TemplateConstraints` | `TemplateConstraintStyle` | see below | `conditional-newline-indent` |
| `Wrapping.SingleTemplateConstraintIndent` | `SingleTemplateConstraintIndent` | boolean | `false` |
| `Wrapping.NewlinePenalty` | `WrappingNewlinePenalty` | positive integer | `480` |
| `Wrapping.LongLinePenalty` | `WrappingLongLinePenalty` | positive integer | `25` |
| `Statements.CompactLabels` | `CompactLabeledStatements` | boolean | `true` |

Template constraint styles are `conditional-newline-indent`,
`conditional-newline`, `always-newline`, and `always-newline-indent`.

Nested and flat spellings are equivalent, but both spellings of the same option
cannot appear in one file. This is rejected because the intended winner would
otherwise be ambiguous:

```yaml
IndentWidth: 2
Indent:
  Width: 4
  ContinuationWidth: 4
```

## Complete nested example

```yaml
Language: D
BasedOnStyle: Alfa
DisableFormat: false

ColumnLimit: 120
SoftColumnLimit: 100
LineEnding: lf

Indent:
  Width: 4
  ContinuationWidth: 4
  TabWidth: 4
  Style: space
  CaseLabels: false
  OutdentAttributes: true
  SingleContinuationIndent: false

Braces:
  Default: allman
  Declarations: allman
  Functions: allman
  ControlStatements: knr

Spacing:
  AfterCast: true
  AfterKeywords: true
  BeforeFunctionParameters: false
  SelectiveImports: true
  BeforeAssociativeArrayColon: false
  BeforeNamedArgumentColon: false
  BeforeBraces: true
  AroundBinaryOperators: true

Wrapping:
  KeepExistingLineBreaks: false
  SplitOperatorAtLineEnd: false
  ReflowPropertyChains: true
  TemplateConstraints: conditional-newline-indent
  SingleTemplateConstraintIndent: false
  NewlinePenalty: 480
  LongLinePenalty: 25

Statements:
  CompactLabels: true
```

## Validation

adfmt rejects:

- unknown or misspelled keys
- duplicate YAML keys
- flat and nested aliases that configure the same option
- unsupported sequences or complex YAML values
- invalid booleans, enum names, and line endings
- zero or negative widths and column limits
- a soft column limit greater than the hard column limit

Errors include the `.adfmt` path and the option that caused the failure.

## Behavioral notes

- `Braces.Functions` overrides `Braces.Declarations` only for function bodies.
- `Indent.CaseLabels: true` is the readable inverse of the legacy
  `AlignSwitchStatements` option. Do not specify both in one file.
- `Indent.ContinuationWidth` controls wrapping indentation independently from
  normal block indentation.
- A lower `Wrapping.NewlinePenalty` makes line breaks cheaper.
- A higher `Wrapping.LongLinePenalty` makes text beyond `SoftColumnLimit` more
  expensive.
- `Spacing.BeforeBraces: false` affects same-line braces only. Allman braces
  remain on their own line.
