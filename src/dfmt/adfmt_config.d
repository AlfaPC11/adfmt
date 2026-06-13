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

private Config parseAdfmtConfig(string path)
{
    import std.conv : ConvException, to;
    import std.exception : enforce;
    import std.format : format;
    import std.string : replace, toLower;

    Config result;
    result.pattern = "*.d";
    const document = parseAdfmtYaml(path);

    OptionalBoolean booleanValue(string key, string value)
    {
        const normalized = value.toLower;
        enforce(normalized == "true" || normalized == "false",
            format("%s: %s must be true or false", path, key));
        return normalized == "true" ? OptionalBoolean.t : OptionalBoolean.f;
    }

    int integerValue(string key, string value)
    {
        try
            return value.to!int;
        catch (ConvException)
            throw new Exception(format("%s: %s must be an integer", path, key));
    }

    BraceStyle braceValue(string key, string value)
    {
        const normalized = value.toLower.replace("-", "_");
        try
            return normalized.to!BraceStyle;
        catch (ConvException)
            throw new Exception(format(
                "%s: %s must be allman, otbs, stroustrup, or knr", path, key));
    }

    TemplateConstraintStyle constraintValue(string key, string value)
    {
        const normalized = value.toLower.replace("-", "_");
        try
            return normalized.to!TemplateConstraintStyle;
        catch (ConvException)
            throw new Exception(format("%s: invalid template constraint style for %s",
                path, key));
    }

    foreach (key, value; document.values)
    {
        switch (key)
        {
        case "Language":
            enforce(value.toLower == "d", path ~ ": Language must be D");
            break;
        case "BasedOnStyle":
            enforce(value.toLower == "alfa" || value.toLower == "dfmt",
                path ~ ": BasedOnStyle must be Alfa or dfmt");
            break;
        case "DisableFormat":
            result.adfmt_disable_format = booleanValue(key, value);
            break;
        case "ColumnLimit":
            result.max_line_length = integerValue(key, value);
            break;
        case "SoftColumnLimit":
            result.dfmt_soft_max_line_length = integerValue(key, value);
            break;
        case "LineEnding":
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
                throw new Exception(path ~ ": LineEnding must be default, lf, cr, or crlf");
            break;
        case "IndentWidth":
        case "Indent.Width":
            result.indent_size = integerValue(key, value);
            break;
        case "TabWidth":
        case "Indent.TabWidth":
            result.tab_width = integerValue(key, value);
            break;
        case "UseTab":
        case "Indent.Style":
            const normalized = value.toLower;
            if (normalized == "never" || normalized == "space")
                result.indent_style = IndentStyle.space;
            else if (normalized == "always" || normalized == "tab")
                result.indent_style = IndentStyle.tab;
            else
                throw new Exception(path ~ ": " ~ key
                    ~ " must be never, always, space, or tab");
            break;
        case "AlignSwitchStatements":
        case "Indent.AlignSwitchStatements":
            result.dfmt_align_switch_statements = booleanValue(key, value);
            break;
        case "OutdentAttributes":
        case "Indent.OutdentAttributes":
            result.dfmt_outdent_attributes = booleanValue(key, value);
            break;
        case "SingleIndent":
        case "Indent.SingleContinuationIndent":
            result.dfmt_single_indent = booleanValue(key, value);
            break;
        case "BraceStyle":
        case "Braces.Default":
            result.dfmt_brace_style = braceValue(key, value);
            break;
        case "DeclarationBraceStyle":
        case "Braces.Declarations":
            result.dfmt_declaration_brace_style = braceValue(key, value);
            break;
        case "ControlBraceStyle":
        case "Braces.ControlStatements":
            result.dfmt_control_brace_style = braceValue(key, value);
            break;
        case "SpaceAfterCast":
        case "Spacing.AfterCast":
            result.dfmt_space_after_cast = booleanValue(key, value);
            break;
        case "SpaceAfterKeywords":
        case "Spacing.AfterKeywords":
            result.dfmt_space_after_keywords = booleanValue(key, value);
            break;
        case "SpaceBeforeFunctionParameters":
        case "Spacing.BeforeFunctionParameters":
            result.dfmt_space_before_function_parameters = booleanValue(key, value);
            break;
        case "SelectiveImportSpace":
        case "Spacing.SelectiveImports":
            result.dfmt_selective_import_space = booleanValue(key, value);
            break;
        case "SpaceBeforeAssociativeArrayColon":
        case "Spacing.BeforeAssociativeArrayColon":
            result.dfmt_space_before_aa_colon = booleanValue(key, value);
            break;
        case "SpaceBeforeNamedArgumentColon":
        case "Spacing.BeforeNamedArgumentColon":
            result.dfmt_space_before_named_arg_colon = booleanValue(key, value);
            break;
        case "KeepLineBreaks":
        case "Wrapping.KeepExistingLineBreaks":
            result.dfmt_keep_line_breaks = booleanValue(key, value);
            break;
        case "SplitOperatorAtLineEnd":
        case "Wrapping.SplitOperatorAtLineEnd":
            result.dfmt_split_operator_at_line_end = booleanValue(key, value);
            break;
        case "ReflowPropertyChains":
        case "Wrapping.ReflowPropertyChains":
            result.dfmt_reflow_property_chains = booleanValue(key, value);
            break;
        case "TemplateConstraintStyle":
        case "Wrapping.TemplateConstraints":
            result.dfmt_template_constraint_style = constraintValue(key, value);
            break;
        case "SingleTemplateConstraintIndent":
        case "Wrapping.SingleTemplateConstraintIndent":
            result.dfmt_single_template_constraint_indent = booleanValue(key, value);
            break;
        case "CompactLabeledStatements":
        case "Statements.CompactLabels":
            result.dfmt_compact_labeled_statements = booleanValue(key, value);
            break;
        default:
            throw new Exception(format("%s: unknown .adfmt option %s", path, key));
        }
    }

    return result;
}
