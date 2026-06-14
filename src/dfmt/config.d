//          Copyright Brian Schott 2015.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
// SPDX-License-Identifier: BSL-1.0

module dfmt.config;

import dfmt.editorconfig;

/// Brace styles
enum BraceStyle
{
    _unspecified,
    /// $(LINK https://en.wikipedia.org/wiki/Indent_style#Allman_style)
    allman,
    /// $(LINK https://en.wikipedia.org/wiki/Indent_style#Variant:_1TBS)
    otbs,
    /// $(LINK https://en.wikipedia.org/wiki/Indent_style#Variant:_Stroustrup)
    stroustrup,
    /// $(LINK https://en.wikipedia.org/wiki/Indentation_style#K&R_style)
    knr,
}

enum TemplateConstraintStyle
{
    _unspecified,
    conditional_newline_indent,
    conditional_newline,
    always_newline,
    always_newline_indent
}

/// Configuration options for formatting
struct Config
{
    ///
    OptionalBoolean adfmt_disable_format;
    ///
    OptionalBoolean dfmt_align_switch_statements;
    ///
    BraceStyle dfmt_brace_style;
    ///
    BraceStyle dfmt_declaration_brace_style;
    ///
    BraceStyle adfmt_aggregate_brace_style;
    ///
    BraceStyle adfmt_enum_brace_style;
    ///
    BraceStyle dfmt_function_brace_style;
    ///
    BraceStyle adfmt_function_literal_brace_style;
    ///
    BraceStyle dfmt_control_brace_style;
    ///
    OptionalBoolean dfmt_outdent_attributes;
    ///
    int dfmt_soft_max_line_length = -1;
    ///
    int adfmt_continuation_indent_width = -1;
    ///
    int adfmt_wrapping_newline_penalty = -1;
    ///
    int adfmt_wrapping_long_line_penalty = -1;
    ///
    OptionalBoolean dfmt_space_after_cast;
    ///
    OptionalBoolean dfmt_space_after_keywords;
    ///
    OptionalBoolean dfmt_space_before_function_parameters;
    ///
    OptionalBoolean dfmt_split_operator_at_line_end;
    ///
    OptionalBoolean dfmt_selective_import_space;
    ///
    OptionalBoolean dfmt_compact_labeled_statements;
    ///
    TemplateConstraintStyle dfmt_template_constraint_style;
    ///
    OptionalBoolean dfmt_single_template_constraint_indent;
    ///
    OptionalBoolean dfmt_space_before_aa_colon;
    ///
    OptionalBoolean dfmt_keep_line_breaks;
    ///
    OptionalBoolean dfmt_single_indent;
    ///
    OptionalBoolean dfmt_reflow_property_chains;
    ///
    OptionalBoolean dfmt_space_before_named_arg_colon;
    ///
    OptionalBoolean adfmt_space_before_braces;
    ///
    OptionalBoolean adfmt_space_around_binary_operators;

    mixin StandardEditorConfigFields;

    /**
     * Initializes the standard EditorConfig properties with default values that
     * make sense for D code.
     */
    void initializeWithDefaults()
    {
        pattern = "*.d";
        end_of_line = EOL._default;
        indent_style = IndentStyle.space;
        indent_size = 4;
        tab_width = 4;
        max_line_length = 120;
        adfmt_disable_format = OptionalBoolean.f;
        dfmt_align_switch_statements = OptionalBoolean.t;
        dfmt_brace_style = BraceStyle.allman;
        dfmt_declaration_brace_style = BraceStyle._unspecified;
        adfmt_aggregate_brace_style = BraceStyle._unspecified;
        adfmt_enum_brace_style = BraceStyle._unspecified;
        dfmt_function_brace_style = BraceStyle._unspecified;
        adfmt_function_literal_brace_style = BraceStyle._unspecified;
        dfmt_control_brace_style = BraceStyle._unspecified;
        dfmt_outdent_attributes = OptionalBoolean.t;
        dfmt_soft_max_line_length = 80;
        adfmt_continuation_indent_width = 4;
        adfmt_wrapping_newline_penalty = 480;
        adfmt_wrapping_long_line_penalty = 25;
        dfmt_space_after_cast = OptionalBoolean.t;
        dfmt_space_after_keywords = OptionalBoolean.t;
        dfmt_space_before_function_parameters = OptionalBoolean.f;
        dfmt_split_operator_at_line_end = OptionalBoolean.f;
        dfmt_selective_import_space = OptionalBoolean.t;
        dfmt_compact_labeled_statements = OptionalBoolean.t;
        dfmt_template_constraint_style = TemplateConstraintStyle.conditional_newline_indent;
        dfmt_single_template_constraint_indent = OptionalBoolean.f;
        dfmt_space_before_aa_colon = OptionalBoolean.f;
        dfmt_keep_line_breaks = OptionalBoolean.f;
        dfmt_single_indent = OptionalBoolean.f;
        dfmt_reflow_property_chains = OptionalBoolean.t;
        dfmt_space_before_named_arg_colon = OptionalBoolean.f;
        adfmt_space_before_braces = OptionalBoolean.t;
        adfmt_space_around_binary_operators = OptionalBoolean.t;
    }

    BraceStyle declarationBraceStyle() const
    {
        return dfmt_declaration_brace_style == BraceStyle._unspecified
            ? dfmt_brace_style : dfmt_declaration_brace_style;
    }

    BraceStyle controlBraceStyle() const
    {
        return dfmt_control_brace_style == BraceStyle._unspecified
            ? dfmt_brace_style : dfmt_control_brace_style;
    }

    BraceStyle functionBraceStyle() const
    {
        return dfmt_function_brace_style == BraceStyle._unspecified
            ? declarationBraceStyle() : dfmt_function_brace_style;
    }

    BraceStyle aggregateBraceStyle() const
    {
        return adfmt_aggregate_brace_style == BraceStyle._unspecified
            ? declarationBraceStyle() : adfmt_aggregate_brace_style;
    }

    BraceStyle enumBraceStyle() const
    {
        return adfmt_enum_brace_style == BraceStyle._unspecified
            ? declarationBraceStyle() : adfmt_enum_brace_style;
    }

    BraceStyle functionLiteralBraceStyle() const
    {
        return adfmt_function_literal_brace_style == BraceStyle._unspecified
            ? BraceStyle.knr : adfmt_function_literal_brace_style;
    }

    /**
     * Returns:
     *     true if the configuration is valid
     */
    bool isValid()
    {
        import std.stdio : stderr;

        const error = validationError();
        if (error.length != 0)
        {
            stderr.writeln(error);
            return false;
        }
        return true;
    }

    string validationError() const
    {
        import std.format : format;

        if (indent_size <= 0)
            return format("Indent width must be greater than zero (got %d)", indent_size);
        if (tab_width <= 0)
            return format("Tab width must be greater than zero (got %d)", tab_width);
        if (adfmt_continuation_indent_width <= 0)
            return format("Continuation indent width must be greater than zero (got %d)",
                adfmt_continuation_indent_width);
        if (max_line_length <= 0)
            return format("Column limit must be greater than zero (got %d)", max_line_length);
        if (dfmt_soft_max_line_length <= 0)
            return format("Soft column limit must be greater than zero (got %d)",
                dfmt_soft_max_line_length);
        if (adfmt_wrapping_newline_penalty <= 0)
            return format("Wrapping newline penalty must be greater than zero (got %d)",
                adfmt_wrapping_newline_penalty);
        if (adfmt_wrapping_long_line_penalty <= 0)
            return format("Wrapping long-line penalty must be greater than zero (got %d)",
                adfmt_wrapping_long_line_penalty);
        if (dfmt_soft_max_line_length > max_line_length)
            return format(
                "Column limit (%d) must be greater than or equal to soft column limit (%d)",
                max_line_length, dfmt_soft_max_line_length);
        return null;
    }
}
