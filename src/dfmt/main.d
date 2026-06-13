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
                "function_brace_style", &optConfig.dfmt_function_brace_style,
                "control_brace_style", &optConfig.dfmt_control_brace_style,
                "config|c", &explicitConfigDir,
                "end_of_line", &optConfig.end_of_line,
                "help|h", &showHelp,
                "indent_size", &optConfig.indent_size,
                "continuation_indent_width", &optConfig.adfmt_continuation_indent_width,
                "indent_style|t", &optConfig.indent_style,
                "indent_case_labels", &handleBooleans,
                "inplace|i", &inplace,
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

            if (args.length >= 2)
                inplace = true;
            int retVal;
            while (args.length > 0)
            {
                const path = args.front;
                args.popFront();
                if (isDir(path))
                {
                    inplace = true;
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

template optionsToString(E) if (is(E == enum))
{
    import std.algorithm.searching : startsWith;

    enum optionsToString = () {

        string result = "(";
        foreach (s; [__traits(allMembers, E)])
        {
            if (!s.startsWith("_"))
                result ~= s ~ "|";
        }
        result = result[0 .. $ - 1] ~ ")";
        return result;
    } ();
}

private void printHelp()
{
    writeln(`adfmt `, VERSION, `
Alfa's D Formatter
https://github.com/dlang-community/dfmt

Options:
    --help, -h          Print this help message
    --inplace, -i       Edit files in place
    --config, -c    Path to directory to load .editorconfig and .adfmt from.
    --version           Print the version number and then exit

Formatting Options:
    --align_switch_statements
    --brace_style               `, optionsToString!(typeof(Config.dfmt_brace_style)),
            `
    --declaration_brace_style   `, optionsToString!(typeof(Config.dfmt_declaration_brace_style)),
            `
    --function_brace_style      `, optionsToString!(typeof(Config.dfmt_function_brace_style)),
            `
    --control_brace_style       `, optionsToString!(typeof(Config.dfmt_control_brace_style)),
            `
    --end_of_line               `, optionsToString!(typeof(Config.end_of_line)), `
    --indent_size
    --continuation_indent_width
    --indent_style, -t          `,
            optionsToString!(typeof(Config.indent_style)), `
    --keep_line_breaks
    --indent_case_labels
    --soft_max_line_length
    --max_line_length
    --outdent_attributes
    --space_after_cast
    --space_before_function_parameters
    --space_after_keywords
    --space_before_braces
    --space_around_binary_operators
    --selective_import_space
    --single_template_constraint_indent
    --split_operator_at_line_end
    --compact_labeled_statements
    --template_constraint_style
    --space_before_aa_colon
    --space_before_named_arg_colon
    --single_indent
    --reflow_property_chains
    --wrapping_newline_penalty
    --wrapping_long_line_penalty
        `,
            optionsToString!(typeof(Config.dfmt_template_constraint_style)));
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
