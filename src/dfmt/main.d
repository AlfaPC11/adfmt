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
    import std.array : appender, array, front, popFront;
    import std.getopt : getopt, GetOptException;
    import std.path : absolutePath, baseName, buildPath, dirName, expandTilde;
    import std.stdio : File, stderr, stdin, stdout, writeln;

    int main(string[] args)
    {
        try
            return run(args);
        catch (Exception error)
        {
            stderr.writeln("adfmt: ", error.msg);
            return 1;
        }
    }

    private int run(string[] args)
    {
        bool inplace = false;
        Config optConfig;
        optConfig.pattern = "*.d";
        bool showHelp;
        bool showVersion;
        string explicitConfigDir;
        string stdinFilename;

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
                "stdin-filename", &stdinFilename,
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
        if (!readFromStdin && stdinFilename.length)
        {
            stderr.writeln("--stdin-filename can only be used with standard input");
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

        Config explicitAdfmtConfig;
        if (explicitConfigDir)
        {
            import std.file : exists, isDir;

            if (!exists(explicitConfigDir) || !isDir(explicitConfigDir))
            {
                stderr.writeln("--config|c must specify existing directory path");
                return 1;
            }
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

            const inputPath = stdinFilename.length
                ? absolutePath(expandTilde(stdinFilename))
                : buildPath(getcwd(), "stdin.d");

            Config config;
            config.initializeWithDefaults();
            if (explicitConfigDir != "")
            {
                Config fileConfig = getConfigFor!Config(
                    buildPath(explicitConfigDir, inputPath.baseName), true);
                fileConfig.pattern = "*.d";
                config.merge(fileConfig, inputPath);
                config.merge(explicitAdfmtConfig, inputPath);
            }
            else
            {
                Config fileConfig = getConfigFor!Config(inputPath);
                fileConfig.pattern = "*.d";
                config.merge(fileConfig, inputPath);
                try
                {
                    Config adfmtConfig = getAdfmtConfigFor(inputPath);
                    config.merge(adfmtConfig, inputPath);
                }
                catch (Exception e)
                {
                    stderr.writeln(e.msg);
                    return 1;
                }
            }
            config.merge(optConfig, inputPath);
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
            immutable bool formatSuccess = format(
                stdinFilename.length ? inputPath : "stdin", buffer,
                stdout.lockingTextWriter(), &config);
            return formatSuccess ? 0 : 1;
        }
        else
        {
            import std.algorithm : sort, uniq;
            import std.file : dirEntries, isDir, isSymlink, SpanMode;

            int retVal;
            string[] inputPaths;
            while (args.length > 0)
            {
                const path = args.front;
                args.popFront();
                if (inplace && isSymlink(path))
                {
                    stderr.writeln("refusing to traverse or replace symbolic link: ", path);
                    retVal = 1;
                    continue;
                }
                if (isDir(path))
                {
                    if (!inplace)
                    {
                        stderr.writeln("directory input requires --inplace: ", path);
                        retVal = 1;
                        continue;
                    }
                    foreach (string name; dirEntries(path, "*.d", SpanMode.depth))
                    {
                        if (isSymlink(name))
                        {
                            stderr.writeln("skipping symbolic link: ", name);
                            continue;
                        }
                        inputPaths ~= name;
                    }
                    continue;
                }
                inputPaths ~= path;
            }

            inputPaths = inputPaths.sort.uniq.array;
            PendingReplacement[] replacements;
            scope (exit) cleanupReplacements(replacements);

            foreach (path; inputPaths)
            {
                if (inplace && isSymlink(path))
                {
                    stderr.writeln("refusing to replace symbolic link: ", path);
                    retVal = 1;
                    continue;
                }
                Config config;
                config.initializeWithDefaults();
                if (explicitConfigDir != "")
                {
                    Config fileConfig = getConfigFor!Config(
                        buildPath(explicitConfigDir, path.baseName), true);
                    fileConfig.pattern = "*.d";
                    config.merge(fileConfig, path);
                    config.merge(explicitAdfmtConfig, path);
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
                            replacements ~= stageReplacement(path, output.data);
                        else
                            stdout.rawWrite(output.data);
                    }
                    else
                        retVal = 1;
                }
            }
            if (retVal == 0 && inplace)
                commitReplacements(replacements);
            return retVal;
        }
    }

    private struct PendingReplacement
    {
        string path;
        string temporaryPath;
        string backupPath;
        bool installed;
    }

    private PendingReplacement stageReplacement(string path, const(char)[] contents)
    {
        import std.file : exists, getAttributes, remove, setAttributes;
        import std.uuid : randomUUID;

        PendingReplacement replacement;
        replacement.path = path;
        replacement.temporaryPath = buildPath(path.dirName,
            "." ~ path.baseName ~ ".adfmt-" ~ randomUUID().toString() ~ ".tmp");
        scope (failure)
            if (replacement.temporaryPath.exists)
                remove(replacement.temporaryPath);

        auto temporary = File(replacement.temporaryPath, "wb");
        temporary.rawWrite(contents);
        temporary.flush();
        syncFile(temporary);
        temporary.close();
        setAttributes(replacement.temporaryPath, getAttributes(path));
        return replacement;
    }

    private void syncFile(File file)
    {
        version (Posix)
        {
            import core.sys.posix.unistd : fsync;

            if (fsync(file.fileno) != 0)
                throw new Exception("could not synchronize temporary output");
        }
    }

    private void commitReplacements(ref PendingReplacement[] replacements)
    {
        import std.file : exists, remove, rename;
        import std.uuid : randomUUID;

        try
        {
            foreach (ref replacement; replacements)
            {
                replacement.backupPath = buildPath(replacement.path.dirName,
                    "." ~ replacement.path.baseName ~ ".adfmt-"
                    ~ randomUUID().toString() ~ ".backup");
                rename(replacement.path, replacement.backupPath);
                try
                    rename(replacement.temporaryPath, replacement.path);
                catch (Exception installError)
                {
                    rename(replacement.backupPath, replacement.path);
                    throw installError;
                }
                replacement.installed = true;
            }

        }
        catch (Exception error)
        {
            foreach_reverse (ref replacement; replacements)
            {
                if (replacement.installed)
                {
                    if (replacement.path.exists)
                        remove(replacement.path);
                    if (replacement.backupPath.exists)
                        rename(replacement.backupPath, replacement.path);
                    replacement.installed = false;
                }
                else if (replacement.backupPath.length
                        && replacement.backupPath.exists && !replacement.path.exists)
                    rename(replacement.backupPath, replacement.path);
            }
            throw new Exception("could not replace input files; original files were restored: "
                ~ error.msg);
        }

        foreach (ref replacement; replacements)
        {
            try
            {
                remove(replacement.backupPath);
                replacement.backupPath = null;
            }
            catch (Exception error)
                stderr.writeln("warning: could not remove backup ",
                    replacement.backupPath, ": ", error.msg);
        }
    }

    private void cleanupReplacements(ref PendingReplacement[] replacements)
    {
        import std.file : exists, remove;

        foreach (ref replacement; replacements)
        {
            if (replacement.temporaryPath.length && replacement.temporaryPath.exists)
                remove(replacement.temporaryPath);
            if (replacement.backupPath.length && replacement.backupPath.exists)
                remove(replacement.backupPath);
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
        Replace input files only after every file formats successfully. Writes
        are staged beside each source file and rolled back if replacement fails.
        Symbolic links are never replaced or followed during directory scans.
    --stdin-filename <path>
        Use this path for configuration discovery and diagnostics while reading
        source text from stdin. The path does not need to exist.
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
