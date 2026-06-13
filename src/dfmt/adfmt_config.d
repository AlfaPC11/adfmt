// SPDX-License-Identifier: BSL-1.0

module dfmt.adfmt_config;

import dfmt.config : BraceStyle, Config, TemplateConstraintStyle;
import dfmt.editorconfig : EOL, IndentStyle, OptionalBoolean;
import dfmt.yaml_config_parser : parseAdfmtYaml;

Config getAdfmtConfigFor(string path, bool exactDirectory = false)
{
    import std.file : exists, isDir;
    import std.path : absolutePath, buildPath, dirName;

    string directory = absolutePath(path);
    if (!isDir(directory))
        directory = dirName(directory);

    while (true)
    {
        const configPath = buildPath(directory, ".adfmt");
        if (exists(configPath))
            return parseAdfmtConfig(configPath);
        if (exactDirectory)
            break;

        const parent = dirName(directory);
        if (parent == directory)
            break;
        directory = parent;
    }

    Config result;
    result.pattern = "*.d";
    return result;
}

Config parseAdfmtConfig(string path)
{
    import std.conv : ConvException, to;
    import std.exception : enforce;
    import std.format : format;
    import std.string : replace, toLower;

    Config result;
    result.pattern = "*.d";
    const document = parseAdfmtYaml(path);
    const style = "BasedOnStyle" in document.values;
    if (style !is null)
        applyBuiltInStyle(result, *style, path);
    string[string] configuredOptions;

    OptionalBoolean booleanValue(string key, string value)
    {
        const normalized = value.toLower;
        enforce(normalized == "true" || normalized == "false",
            format("%s: invalid value '%s' for %s; expected true or false",
                path, value, key));
        return normalized == "true" ? OptionalBoolean.t : OptionalBoolean.f;
    }

    int positiveIntegerValue(string key, string value)
    {
        int parsed;
        try
            parsed = value.to!int;
        catch (ConvException)
            throw new Exception(format(
                "%s: invalid value '%s' for %s; expected a positive integer",
                path, value, key));
        enforce(parsed > 0, format(
            "%s: invalid value '%s' for %s; expected a positive integer",
            path, value, key));
        return parsed;
    }

    BraceStyle braceValue(string key, string value)
    {
        const normalized = value.toLower.replace("-", "_");
        try
            return normalized.to!BraceStyle;
        catch (ConvException)
            throw new Exception(format(
                "%s: invalid value '%s' for %s; expected allman, otbs, stroustrup, or knr",
                path, value, key));
    }

    TemplateConstraintStyle constraintValue(string key, string value)
    {
        const normalized = value.toLower.replace("-", "_");
        try
            return normalized.to!TemplateConstraintStyle;
        catch (ConvException)
            throw new Exception(format(
                "%s: invalid value '%s' for %s; expected conditional-newline-indent, "
                ~ "conditional-newline, always-newline, or always-newline-indent",
                path, value, key));
    }

    void markConfigured(string canonicalKey, string inputKey)
    {
        if (const previous = canonicalKey in configuredOptions)
            throw new Exception(format(
                "%s: %s and %s configure the same option; use only one spelling",
                path, *previous, inputKey));
        configuredOptions[canonicalKey] = inputKey;
    }

    foreach (key, value; document.values)
    {
        switch (key)
        {
        case "Language":
            enforce(value.toLower == "d", path ~ ": Language must be D");
            break;
        case "BasedOnStyle":
            break;
        case "DisableFormat":
            markConfigured("DisableFormat", key);
            result.adfmt_disable_format = booleanValue(key, value);
            break;
        case "ColumnLimit":
            markConfigured("ColumnLimit", key);
            result.max_line_length = positiveIntegerValue(key, value);
            break;
        case "SoftColumnLimit":
            markConfigured("SoftColumnLimit", key);
            result.dfmt_soft_max_line_length = positiveIntegerValue(key, value);
            break;
        case "LineEnding":
            markConfigured("LineEnding", key);
            const normalized = value.toLower;
            if (normalized == "default")
                result.end_of_line = EOL._default;
            else if (normalized == "lf")
                result.end_of_line = EOL.lf;
            else if (normalized == "cr")
                result.end_of_line = EOL.cr;
            else if (normalized == "crlf")
                result.end_of_line = EOL.crlf;
            else
                throw new Exception(format(
                    "%s: invalid value '%s' for LineEnding; expected default, lf, cr, or crlf",
                    path, value));
            break;
        case "IndentWidth":
        case "Indent.Width":
            markConfigured("Indent.Width", key);
            result.indent_size = positiveIntegerValue(key, value);
            break;
        case "TabWidth":
        case "Indent.TabWidth":
            markConfigured("Indent.TabWidth", key);
            result.tab_width = positiveIntegerValue(key, value);
            break;
        case "UseTab":
        case "Indent.Style":
            markConfigured("Indent.Style", key);
            const normalized = value.toLower;
            if (normalized == "never" || normalized == "space")
                result.indent_style = IndentStyle.space;
            else if (normalized == "always" || normalized == "tab")
                result.indent_style = IndentStyle.tab;
            else
                throw new Exception(format(
                    "%s: invalid value '%s' for %s; expected never, always, space, or tab",
                    path, value, key));
            break;
        case "AlignSwitchStatements":
        case "Indent.AlignSwitchStatements":
            markConfigured("Indent.AlignSwitchStatements", key);
            result.dfmt_align_switch_statements = booleanValue(key, value);
            break;
        case "OutdentAttributes":
        case "Indent.OutdentAttributes":
            markConfigured("Indent.OutdentAttributes", key);
            result.dfmt_outdent_attributes = booleanValue(key, value);
            break;
        case "SingleIndent":
        case "Indent.SingleContinuationIndent":
            markConfigured("Indent.SingleContinuationIndent", key);
            result.dfmt_single_indent = booleanValue(key, value);
            break;
        case "BraceStyle":
        case "Braces.Default":
            markConfigured("Braces.Default", key);
            result.dfmt_brace_style = braceValue(key, value);
            break;
        case "DeclarationBraceStyle":
        case "Braces.Declarations":
            markConfigured("Braces.Declarations", key);
            result.dfmt_declaration_brace_style = braceValue(key, value);
            break;
        case "ControlBraceStyle":
        case "Braces.ControlStatements":
            markConfigured("Braces.ControlStatements", key);
            result.dfmt_control_brace_style = braceValue(key, value);
            break;
        case "SpaceAfterCast":
        case "Spacing.AfterCast":
            markConfigured("Spacing.AfterCast", key);
            result.dfmt_space_after_cast = booleanValue(key, value);
            break;
        case "SpaceAfterKeywords":
        case "Spacing.AfterKeywords":
            markConfigured("Spacing.AfterKeywords", key);
            result.dfmt_space_after_keywords = booleanValue(key, value);
            break;
        case "SpaceBeforeFunctionParameters":
        case "Spacing.BeforeFunctionParameters":
            markConfigured("Spacing.BeforeFunctionParameters", key);
            result.dfmt_space_before_function_parameters = booleanValue(key, value);
            break;
        case "SelectiveImportSpace":
        case "Spacing.SelectiveImports":
            markConfigured("Spacing.SelectiveImports", key);
            result.dfmt_selective_import_space = booleanValue(key, value);
            break;
        case "SpaceBeforeAssociativeArrayColon":
        case "Spacing.BeforeAssociativeArrayColon":
            markConfigured("Spacing.BeforeAssociativeArrayColon", key);
            result.dfmt_space_before_aa_colon = booleanValue(key, value);
            break;
        case "SpaceBeforeNamedArgumentColon":
        case "Spacing.BeforeNamedArgumentColon":
            markConfigured("Spacing.BeforeNamedArgumentColon", key);
            result.dfmt_space_before_named_arg_colon = booleanValue(key, value);
            break;
        case "KeepLineBreaks":
        case "Wrapping.KeepExistingLineBreaks":
            markConfigured("Wrapping.KeepExistingLineBreaks", key);
            result.dfmt_keep_line_breaks = booleanValue(key, value);
            break;
        case "SplitOperatorAtLineEnd":
        case "Wrapping.SplitOperatorAtLineEnd":
            markConfigured("Wrapping.SplitOperatorAtLineEnd", key);
            result.dfmt_split_operator_at_line_end = booleanValue(key, value);
            break;
        case "ReflowPropertyChains":
        case "Wrapping.ReflowPropertyChains":
            markConfigured("Wrapping.ReflowPropertyChains", key);
            result.dfmt_reflow_property_chains = booleanValue(key, value);
            break;
        case "TemplateConstraintStyle":
        case "Wrapping.TemplateConstraints":
            markConfigured("Wrapping.TemplateConstraints", key);
            result.dfmt_template_constraint_style = constraintValue(key, value);
            break;
        case "SingleTemplateConstraintIndent":
        case "Wrapping.SingleTemplateConstraintIndent":
            markConfigured("Wrapping.SingleTemplateConstraintIndent", key);
            result.dfmt_single_template_constraint_indent = booleanValue(key, value);
            break;
        case "CompactLabeledStatements":
        case "Statements.CompactLabels":
            markConfigured("Statements.CompactLabels", key);
            result.dfmt_compact_labeled_statements = booleanValue(key, value);
            break;
        default:
            throw new Exception(format(
                "%s: unknown .adfmt option '%s'; check spelling and nesting",
                path, key));
        }
    }

    if (result.max_line_length > 0 && result.dfmt_soft_max_line_length > 0)
        enforce(result.dfmt_soft_max_line_length <= result.max_line_length,
            format("%s: Column limit (%d) must be greater than or equal to "
                ~ "soft column limit (%d)", path, result.max_line_length,
                result.dfmt_soft_max_line_length));
    return result;
}

private void applyBuiltInStyle(ref Config config, string style, string path)
{
    import std.exception : enforce;
    import std.format : format;
    import std.string : toLower;

    const normalized = style.toLower;
    enforce(normalized == "alfa" || normalized == "dfmt",
        format("%s: unknown BasedOnStyle '%s'; expected Alfa or dfmt", path, style));

    config.initializeWithDefaults();
    if (normalized == "alfa")
    {
        config.end_of_line = EOL.lf;
        config.dfmt_soft_max_line_length = 100;
        config.dfmt_declaration_brace_style = BraceStyle.allman;
        config.dfmt_control_brace_style = BraceStyle.knr;
    }
}

unittest
{
    import std.file : mkdirRecurse, remove, rmdirRecurse, tempDir, write;
    import std.algorithm : canFind;
    import std.path : buildPath;
    import std.uuid : randomUUID;

    const directory = buildPath(tempDir(), "adfmt-config-" ~ randomUUID().toString());
    mkdirRecurse(directory);
    scope (exit) rmdirRecurse(directory);

    Config parse(string name, string yaml)
    {
        const path = buildPath(directory, name);
        write(path, yaml);
        scope (exit) remove(path);
        return parseAdfmtConfig(path);
    }

    const flat = parse("flat", `
BasedOnStyle: Alfa
IndentWidth: 2
TabWidth: 8
UseTab: always
AlignSwitchStatements: false
OutdentAttributes: false
SingleIndent: true
BraceStyle: otbs
DeclarationBraceStyle: allman
ControlBraceStyle: knr
SpaceAfterCast: false
SpaceAfterKeywords: false
SpaceBeforeFunctionParameters: true
SelectiveImportSpace: false
SpaceBeforeAssociativeArrayColon: true
SpaceBeforeNamedArgumentColon: true
KeepLineBreaks: true
SplitOperatorAtLineEnd: true
ReflowPropertyChains: false
TemplateConstraintStyle: always-newline
SingleTemplateConstraintIndent: true
CompactLabeledStatements: false
`);
    const nested = parse("nested", `
BasedOnStyle: Alfa
Indent:
  Width: 2
  TabWidth: 8
  Style: tab
  AlignSwitchStatements: false
  OutdentAttributes: false
  SingleContinuationIndent: true
Braces:
  Default: otbs
  Declarations: allman
  ControlStatements: knr
Spacing:
  AfterCast: false
  AfterKeywords: false
  BeforeFunctionParameters: true
  SelectiveImports: false
  BeforeAssociativeArrayColon: true
  BeforeNamedArgumentColon: true
Wrapping:
  KeepExistingLineBreaks: true
  SplitOperatorAtLineEnd: true
  ReflowPropertyChains: false
  TemplateConstraints: always-newline
  SingleTemplateConstraintIndent: true
Statements:
  CompactLabels: false
`);
    assert(flat == nested);

    const alfa = parse("alfa", "ControlBraceStyle: allman\nBasedOnStyle: Alfa\n");
    assert(alfa.dfmt_soft_max_line_length == 100);
    assert(alfa.declarationBraceStyle() == BraceStyle.allman);
    assert(alfa.controlBraceStyle() == BraceStyle.allman);

    void assertConfigError(string yaml, string expected)
    {
        bool thrown;
        try
            parse("invalid", yaml);
        catch (Exception error)
        {
            thrown = true;
            assert(error.msg.canFind(expected), error.msg);
        }
        assert(thrown, "Expected configuration error containing: " ~ expected);
    }

    assertConfigError("Spcaing:\n  AfterCast: true\n", "unknown .adfmt option 'Spcaing.AfterCast'");
    assertConfigError("IndentWidth: 0\n", "expected a positive integer");
    assertConfigError("Braces:\n  Default: java\n", "expected allman, otbs, stroustrup, or knr");
    assertConfigError("BasedOnStyle: dfmt\nColumnLimit: 80\nSoftColumnLimit: 100\n",
        "must be greater than or equal to soft column limit");
    assertConfigError("IndentWidth: 2\nIndent:\n  Width: 4\n",
        "configure the same option");
    assertConfigError("BasedOnStyle: Unknown\n", "unknown BasedOnStyle");
}
