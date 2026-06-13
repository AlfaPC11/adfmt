<!-- SPDX-License-Identifier: BSL-1.0 -->

# Frequently asked questions

## Why is the configuration file named `.adfmt` without an extension?

It is a project-level formatter file, similar to `.clang-format`. Its contents
are YAML and the VS Code extension associates it with YAML automatically.

## Does adfmt still support EditorConfig?

Yes. Precedence is defaults, `.editorconfig`, `.adfmt`, then command-line
arguments.

## What is the difference between declarations and functions?

`Braces.Declarations` controls aggregate, enum, and function bodies.
`Braces.Functions`, when present, overrides only function bodies. This permits
Allman classes and structs with K&R functions.

## What is the difference between K&R and OTBS?

Both keep control-flow opening braces on the header line. K&R places function
opening braces on the following line, while OTBS keeps them on the same line.
OTBS also keeps `else`, `catch`, and `finally` beside the preceding closing
brace.

## How does Stroustrup differ from OTBS?

Stroustrup uses same-line opening braces but places continuation keywords such
as `else`, `catch`, and `finally` on a new line.

## Why did changing `SoftColumnLimit` not create an exact line length?

It is a preference used by the wrapping cost model. `ColumnLimit` is the hard
limit. `Wrapping.NewlinePenalty` and `Wrapping.LongLinePenalty` tune the
trade-off.

## Can continuation indentation differ from block indentation?

Yes. Set `Indent.ContinuationWidth`.

## Can case labels be indented?

Yes. Set `Indent.CaseLabels: true`. This is the inverse of the inherited
`AlignSwitchStatements` spelling, so use only one of them.

## Why are `// dfmt off` and `// dfmt on` still named dfmt?

They are retained for source compatibility with upstream dfmt. Existing D
projects do not need suppression-comment migrations.

## Is adfmt a complete rewrite?

No. It is a dfmt fork that retains dfmt's D parser and formatting engine while
adding `.adfmt`, independent brace categories, profiles, validation, and
editor integration.
