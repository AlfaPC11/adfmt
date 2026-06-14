//          Copyright Brian Schott 2015.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)
// SPDX-License-Identifier: BSL-1.0

module dfmt.main;

import std.string : strip;

static immutable VERSION = () {
    debug
    {
        enum DEBUG_SUFFIX = "-debug";
    }
    else
    {
        enum DEBUG_SUFFIX = "";
    }

    version (built_with_dub)
    {
        enum DFMT_VERSION = import("dubhash.txt").strip;
    }
    else
    {
        /**
         * Current build's Git commit hash
         */
        enum DFMT_VERSION = import("githash.txt").strip;
    }

    return DFMT_VERSION ~ DEBUG_SUFFIX;
} ();


version (NoMain)
{
}
else
{
    import dfmt.config : Config;
    import dfmt.adfmt_config : getAdfmtConfigFor;
    import dfmt.editorconfig : getConfigFor;
    import dfmt.formatter : format;
    import std.array : appender, front, popFront;
    import std.getopt : getopt, GetOptException;
    import std.path : buildPath, dirName, expandTilde;
    import std.stdio : File, stderr, stdin, stdout, writeln;

    int main(string[] args)
    {
        bool inplace = false;
        Config optConfig;
        optConfig.pattern = "*.d";
        bool showHelp;
        bool showVersion;
        string explicitConfigDir;

        void handleBooleans(string option, string value)
        {
            import dfmt.editorconfig : OptionalBoolean;
            import std.exception : enforce;

            enforce!GetOptException(value == "true" || value == "false", "Invalid argument");
            immutable OptionalBoolean optVal = value == "true" ? OptionalBoolean.t
                : OptionalBoolean.f;
            switch (option)
            {
            case "align_switch_statements":
                optConfig.dfmt_align_switch_statements = optVal;
                break;
            case "outdent_attributes":
                optConfig.dfmt_outdent_attributes = optVal;
                break;
            case "space_after_cast":
                optConfig.dfmt_space_after_cast = optVal;
                break;
            case "space_before_function_parameters":
                optConfig.dfmt_space_before_function_parameters = optVal;
                break;
            case "split_operator_at_line_end":
                optConfig.dfmt_split_operator_at_line_end = optVal;
                break;
            case "selective_import_space":
                optConfig.dfmt_selective_import_space = optVal;
                break;
            case "compact_labeled_statements":
                optConfig.dfmt_compact_labeled_statements = optVal;
                break;
            case "single_template_constraint_indent":
                optConfig.dfmt_single_template_constraint_indent = optVal;
                break;
            case "space_before_aa_colon":
                optConfig.dfmt_space_before_aa_colon = optVal;
                break;
            case "space_before_named_arg_colon":
                optConfig.dfmt_space_before_named_arg_colon = optVal;
                break;
            case "keep_line_breaks":
                optConfig.dfmt_keep_line_breaks = optVal;
                break;
            case "single_indent":
                optConfig.dfmt_single_indent = optVal;
                break;
            case "reflow_property_chains":
                optConfig.dfmt_reflow_property_chains = optVal;
                break;
            case "space_after_keywords":
                optConfig.dfmt_space_after_keywords = optVal;
                break;
            case "space_before_braces":
                optConfig.adfmt_space_before_braces = optVal;
                break;
            case "space_around_binary_operators":
                optConfig.adfmt_space_around_binary_operators = optVal;
                break;
            case "indent_case_labels":
                optConfig.dfmt_align_switch_statements =
                    optVal == OptionalBoolean.t ? OptionalBoolean.f : OptionalBoolean.t;
                break;
            default:
                assert(false, "Invalid command-line switch");
            }
        }

        try
        {
            // dfmt off
            getopt(args,
                "version", &showVersion,
                "align_switch_statements", &handleBooleans,
                "brace_style", &optConfig.dfmt_brace_style,
                "declaration_brace_style", &optConfig.dfmt_declaration_brace_style,
                "aggregate_brace_style", &optConfig.adfmt_aggregate_brace_style,
                "enum_brace_style", &optConfig.adfmt_enum_brace_style,
                "function_brace_style", &optConfig.dfmt_function_brace_style,
                "function_literal_brace_style", &optConfig.adfmt_function_literal_brace_style,
                "control_brace_style", &optConfig.dfmt_control_brace_style,
                "config|c", &explicitConfigDir,
                "end_of_line", &optConfig.end_of_line,
                "help|h", &showHelp,
                "indent_size", &optConfig.indent_size,
                "continuation_indent_width", &optConfig.adfmt_continuation_indent_width,
                "indent_style|t", &optConfig.indent_style,
                "indent_case_labels", &handleBooleans,
                "inplace|in-place|i", &inplace,
                "max_line_length", &optConfig.max_line_length,
                "soft_max_line_length", &optConfig.dfmt_soft_max_line_length,
                "outdent_attributes", &handleBooleans,
                "space_after_cast", &handleBooleans,
                "space_after_keywords", &handleBooleans,
                "space_before_braces", &handleBooleans,
                "space_around_binary_operators", &handleBooleans,
                "selective_import_space", &handleBooleans,
                "space_before_function_parameters", &handleBooleans,
                "split_operator_at_line_end", &handleBooleans,
                "compact_labeled_statements", &handleBooleans,
                "single_template_constraint_indent", &handleBooleans,
                "space_before_aa_colon", &handleBooleans,
                "space_before_named_arg_colon", &handleBooleans,
                "tab_width", &optConfig.tab_width,
                "template_constraint_style", &optConfig.dfmt_template_constraint_style,
                "keep_line_breaks", &handleBooleans,
                "single_indent", &handleBooleans,
                "reflow_property_chains", &handleBooleans,
                "wrapping_newline_penalty", &optConfig.adfmt_wrapping_newline_penalty,
                "wrapping_long_line_penalty", &optConfig.adfmt_wrapping_long_line_penalty);
            // dfmt on
        }
        catch (GetOptException e)
        {
            stderr.writeln(e.msg);
            return 1;
        }
        catch (Exception e)
        {
            stderr.writeln(e.msg);
            return 1;
        }

        if (showVersion)
        {
            writeln(VERSION);
            return 0;
        }

        if (showHelp)
        {
            printHelp();
            return 0;
        }

        args.popFront();
        immutable bool readFromStdin = args.length == 0;
        if (readFromStdin && inplace)
        {
            stderr.writeln("--inplace requires at least one file or directory");
            return 1;
        }
        if (args.length >= 2 && !inplace)
        {
            stderr.writeln("multiple input paths require --inplace");
            return 1;
        }

        version (Windows)
        {
            // On Windows, set stdout to binary mode (needed for correct EOL writing)
            // See Phobos' stdio.File.rawWrite
            {
                import std.stdio : _O_BINARY;
                immutable fd = stdout.fileno;
                _setmode(fd, _O_BINARY);
                version (CRuntime_DigitalMars)
                {
                    import core.atomic : atomicOp;
                    import core.stdc.stdio : __fhnd_info, FHND_TEXT;

                    atomicOp!"&="(__fhnd_info[fd], ~FHND_TEXT);
                }
            }
        }

        ubyte[] buffer;

        Config explicitConfig;
        Config explicitAdfmtConfig;
        if (explicitConfigDir)
        {
            import std.file : exists, isDir;

            if (!exists(explicitConfigDir) || !isDir(explicitConfigDir))
            {
                stderr.writeln("--config|c must specify existing directory path");
                return 1;
            }
            explicitConfig = getConfigFor!Config(explicitConfigDir);
            explicitConfig.pattern = "*.d";
            try
                explicitAdfmtConfig = getAdfmtConfigFor(explicitConfigDir, true);
            catch (Exception e)
            {
                stderr.writeln(e.msg);
                return 1;
            }
        }

        if (readFromStdin)
        {
            import std.file : getcwd;

            auto cwdDummyPath = buildPath(getcwd(), "dummy.d");

            Config config;
            config.initializeWithDefaults();
            if (explicitConfigDir != "")
            {
                config.merge(explicitConfig, buildPath(explicitConfigDir, "dummy.d"));
                config.merge(explicitAdfmtConfig, buildPath(explicitConfigDir, "dummy.d"));
            }
            else
            {
                Config fileConfig = getConfigFor!Config(getcwd());
                fileConfig.pattern = "*.d";
                config.merge(fileConfig, cwdDummyPath);
                try
                {
                    Config adfmtConfig = getAdfmtConfigFor(getcwd());
                    config.merge(adfmtConfig, cwdDummyPath);
                }
                catch (Exception e)
                {
                    stderr.writeln(e.msg);
                    return 1;
                }
            }
            config.merge(optConfig, cwdDummyPath);
            if (!config.isValid())
                return 1;
            ubyte[4096] inputBuffer;
            ubyte[] b;
            while (true)
            {
                b = stdin.rawRead(inputBuffer);
                if (b.length)
                    buffer ~= b;
                else
                    break;
            }
            if (config.adfmt_disable_format)
            {
                stdout.rawWrite(buffer);
                return 0;
            }
            immutable bool formatSuccess = format("stdin", buffer,
                stdout.lockingTextWriter(), &config);
            return formatSuccess ? 0 : 1;
        }
        else
        {
            import std.file : dirEntries, isDir, SpanMode;

            int retVal;
            while (args.length > 0)
            {
                const path = args.front;
                args.popFront();
                if (isDir(path))
                {
                    if (!inplace)
                    {
                        stderr.writeln("directory input requires --inplace: ", path);
                        retVal = 1;
                        continue;
                    }
                    foreach (string name; dirEntries(path, "*.d", SpanMode.depth))
                        args ~= name;
                    continue;
                }
                Config config;
                config.initializeWithDefaults();
                if (explicitConfigDir != "")
                {
                    config.merge(explicitConfig, buildPath(explicitConfigDir, "dummy.d"));
                    config.merge(explicitAdfmtConfig, buildPath(explicitConfigDir, "dummy.d"));
                }
                else
                {
                    Config fileConfig = getConfigFor!Config(path);
                    fileConfig.pattern = "*.d";
                    config.merge(fileConfig, path);
                    try
                    {
                        Config adfmtConfig = getAdfmtConfigFor(path);
                        config.merge(adfmtConfig, path);
                    }
                    catch (Exception e)
                    {
                        stderr.writeln(e.msg);
                        return 1;
                    }
                }
                config.merge(optConfig, path);
                if (!config.isValid())
                    return 1;
                File f = File(path);
                // ignore empty files
                if (f.size)
                {
                    buffer = new ubyte[](cast(size_t) f.size);
                    f.rawRead(buffer);
                    if (config.adfmt_disable_format)
                    {
                        if (!inplace)
                            stdout.rawWrite(buffer);
                        continue;
                    }
                    auto output = appender!string;
                    immutable bool formatSuccess = format(path, buffer, output, &config);
                    if (formatSuccess)
                    {
                        if (inplace)
                            File(path, "wb").rawWrite(output.data);
                        else
                            stdout.rawWrite(output.data);
                    }
                    else
                        retVal = 1;
                }
            }
            return retVal;
        }
    }
}

private version (Windows)
{
    version(CRuntime_DigitalMars)
    {
        extern(C) int setmode(int, int) nothrow @nogc;
        alias _setmode = setmode;
    }
    else version(CRuntime_Microsoft)
    {
        extern(C) int _setmode(int, int) nothrow @nogc;
    }
}

private void printHelp()
{
    writeln(`adfmt `, VERSION, `
Alfa's D Formatter
https://github.com/AlfaPC11/adfmt

Usage:
    adfmt [options] [file-or-directory ...]

Input and output:
    With no path, read D source from stdin and write formatted source to stdout.
    With one file, read that file and write formatted source to stdout.
    Multiple paths and directories require --inplace. adfmt never enables
    file replacement implicitly.

General options:
    --help, -h
        Print this help and exit.
    --version
        Print the build version and exit.
    --inplace, --in-place, -i
        Replace each input file after successful formatting.
    --config, -c <directory>
        Load .editorconfig and .adfmt only from the specified directory.

Indentation and lines:
    --indent_size <positive integer>
        Spaces per block indentation level.
    --continuation_indent_width <positive integer>
        Spaces per wrapped continuation level.
    --tab_width <positive integer>
        Display width of a tab.
    --indent_style, -t <tab|space>
        Select tabs or spaces for block indentation.
    --indent_case_labels <true|false>
        Indent case and default labels inside switch statements.
    --align_switch_statements <true|false>
        Legacy inverse of --indent_case_labels.
    --outdent_attributes <true|false>
        Outdent supported declaration attributes.
    --end_of_line <_default|lf|cr|crlf>
        Select emitted line endings.
    --max_line_length <positive integer>
        Hard line-length limit.
    --soft_max_line_length <positive integer>
        Preferred line-length limit.

Brace styles (allman|otbs|stroustrup|knr):
    --brace_style <style>
        Fallback style for every ordinary block.
    --declaration_brace_style <style>
        Fallback for declaration bodies.
    --aggregate_brace_style <style>
        Override class, interface, struct, and union bodies.
    --enum_brace_style <style>
        Override enum bodies.
    --function_brace_style <style>
        Override named function bodies.
    --function_literal_brace_style <style>
        Override delegate and lambda bodies.
    --control_brace_style <style>
        Override control-flow and statement blocks.

Spacing (true|false):
    --space_after_cast
        Add a space after cast(...).
    --space_after_keywords
        Add a space between control keywords and '('.
    --space_before_function_parameters
        Add a space before function parameter lists.
    --space_before_braces
        Add a space before same-line opening braces.
    --space_around_binary_operators
        Add spaces around binary operators.
    --selective_import_space
        Add a space before ':' in selective imports.
    --space_before_aa_colon
        Add a space before associative-array colons.
    --space_before_named_arg_colon
        Add a space before named-argument colons.

Wrapping:
    --keep_line_breaks <true|false>
        Preserve compatible source line breaks.
    --single_indent <true|false>
        Use one continuation level inside parentheses.
    --reflow_property_chains <true|false>
        Recalculate line breaks in property and UFCS chains.
    --split_operator_at_line_end <true|false>
        Keep a split binary operator on the preceding line.
    --template_constraint_style
        <conditional_newline_indent|conditional_newline|
         always_newline|always_newline_indent>
        Control line breaks and indentation for template constraints.
    --single_template_constraint_indent <true|false>
        Use one indentation level for indented template constraints.
    --wrapping_newline_penalty <positive integer>
        Cost assigned to adding a line break.
    --wrapping_long_line_penalty <positive integer>
        Cost per column beyond the soft line limit.

Statements:
    --compact_labeled_statements <true|false>
        Keep supported labeled statements on the label line.

Configuration precedence:
    defaults < .editorconfig < .adfmt < command line

Full reference:
    https://github.com/AlfaPC11/adfmt/blob/main/docs/cli.md`);
}

private string createFilePath(bool readFromStdin, string fileName)
{
    import std.file : getcwd;
    import std.path : isRooted;

    immutable string cwd = getcwd();
    if (readFromStdin)
        return buildPath(cwd, "dummy.d");
    if (isRooted(fileName))
        return fileName;
    else
        return buildPath(cwd, fileName);
}
