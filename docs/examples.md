<!-- SPDX-License-Identifier: BSL-1.0 -->

# Usage examples

## Format one file

```sh
adfmt source/app.d
```

## Replace a file in place

```sh
adfmt --inplace source/app.d
```

## Use a specific configuration directory

```sh
adfmt --config=config/formatting source/app.d
```

The directory may contain `.adfmt`, `.editorconfig`, or both.

## Allman declarations with K&R control flow

```yaml
BasedOnStyle: Alfa
Braces:
  Declarations: allman
  Functions: allman
  ControlStatements: knr
```

## Allman types with K&R functions

```yaml
BasedOnStyle: Linux
Indent:
  Style: space
  Width: 4
  TabWidth: 4
```

## Compact code

```yaml
BasedOnStyle: Compact
ColumnLimit: 90
Spacing:
  BeforeBraces: true
  AroundBinaryOperators: true
```

## More eager wrapping

```yaml
BasedOnStyle: Alfa
ColumnLimit: 100
SoftColumnLimit: 80
Wrapping:
  NewlinePenalty: 240
  LongLinePenalty: 50
Indent:
  ContinuationWidth: 6
```

## Preserve manual line breaks

```yaml
BasedOnStyle: Alfa
Wrapping:
  KeepExistingLineBreaks: true
  ReflowPropertyChains: false
```

## Disable formatting temporarily

Inherited dfmt suppression comments remain supported:

```d
// dfmt off
auto table = [
    "one"   : 1,
    "three" : 3,
];
// dfmt on
```
