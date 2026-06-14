<!-- SPDX-License-Identifier: BSL-1.0 -->

# Migrating from dfmt to adfmt

adfmt retains dfmt's formatter and accepts the existing dfmt command-line and
EditorConfig settings. Migration can therefore be incremental.

## 1. Replace the executable

Change formatter invocations from `dfmt` to `adfmt`:

```sh
adfmt --inplace source/app.d
```

Existing options such as `--max_line_length`,
`--space_before_function_parameters`, and `--brace_style` remain available.

## 2. Keep EditorConfig or add .adfmt

Existing `.editorconfig` files continue to work. To preserve dfmt defaults
explicitly, add this extensionless file at the project root:

```yaml
BasedOnStyle: dfmt
```

You can then move options into `.adfmt` one at a time. For example:

```ini
dfmt_brace_style = allman
max_line_length = 100
```

becomes:

```yaml
BasedOnStyle: dfmt
Braces:
  Default: allman
ColumnLimit: 100
```

`.adfmt` overrides `.editorconfig` when both configure the same setting.

## 3. Split brace styles when needed

dfmt has one general brace setting. adfmt can preserve it:

```yaml
Braces:
  Default: allman
```

or specialize it:

```yaml
Braces:
  Declarations: allman
  Aggregates: allman
  Enums: allman
  Functions: allman
  FunctionLiterals: knr
  ControlStatements: knr
```

`Declarations` remains the compatibility fallback. adfmt can further specialize
aggregate bodies, enum bodies, named function bodies, and function literals.
Control braces cover statements such as `if`, `else`, `for`, `foreach`,
`while`, `switch`, `try`, and `catch`.

## 4. Update formatter suppression comments only if desired

The inherited `// dfmt off` and `// dfmt on` comments remain supported for
source compatibility. No source changes are required.

## 5. Validate in CI

Run adfmt without `--inplace` and compare its output, or format a clean checkout
and fail when Git reports changes. Invalid `.adfmt` files already produce a
non-zero exit status with a focused error message.
