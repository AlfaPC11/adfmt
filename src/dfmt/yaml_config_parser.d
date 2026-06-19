// SPDX-License-Identifier: BSL-1.0

module dfmt.yaml_config_parser;

import dyaml : Loader, Node, NodeID, NodeType;

private enum maxConfigBytes = 1024 * 1024;
private enum maxNestingDepth = 16;
private enum maxOptionCount = 256;
private enum maxKeyLength = 128;
private enum maxScalarLength = 4096;

struct AdfmtYamlDocument
{
    string[string] values;
}

AdfmtYamlDocument parseAdfmtYaml(string path)
{
    import std.exception : enforce;
    import std.file : getSize, readText;
    import std.format : format;

    try
    {
        enforce(getSize(path) <= maxConfigBytes,
            ".adfmt exceeds the 1 MiB size limit");
        const yaml = prepareAdfmtYaml(readText(path));
        const root = Loader.fromString(yaml).load();
        AdfmtYamlDocument result;
        size_t optionCount;
        flattenMapping(root, "", result, 0, optionCount);
        return result;
    }
    catch (Exception error)
    {
        throw new Exception(format("%s: invalid .adfmt YAML: %s", path, error.msg));
    }
}

private string prepareAdfmtYaml(string yaml)
{
    return yaml;
}

private void flattenMapping(const Node node, string prefix,
    ref AdfmtYamlDocument result, size_t depth, ref size_t optionCount)
{
    import std.conv : to;
    import std.exception : enforce;

    enforce(node.nodeID == NodeID.mapping, "The .adfmt root must be a mapping");
    enforce(depth <= maxNestingDepth, ".adfmt nesting exceeds 16 levels");
    foreach (const Node keyNode, const Node valueNode; node)
    {
        enforce(keyNode.type == NodeType.string, ".adfmt keys must be strings");
        const key = keyNode.as!string;
        const fullKey = prefix.length == 0 ? key : prefix ~ "." ~ key;
        enforce(key.length <= maxKeyLength,
            ".adfmt key exceeds 128 bytes: " ~ fullKey);

        if (valueNode.nodeID == NodeID.mapping)
        {
            flattenMapping(valueNode, fullKey, result, depth + 1, optionCount);
            continue;
        }

        enforce(valueNode.nodeID == NodeID.scalar,
            "Sequences are not supported for .adfmt option " ~ fullKey);
        enforce((fullKey in result.values) is null,
            "Duplicate .adfmt option " ~ fullKey);
        enforce(++optionCount <= maxOptionCount,
            ".adfmt contains more than 256 options");

        final switch (valueNode.type)
        {
        case NodeType.boolean:
            result.values[fullKey] = valueNode.as!bool ? "true" : "false";
            break;
        case NodeType.integer:
            result.values[fullKey] = valueNode.as!long.to!string;
            break;
        case NodeType.decimal:
            result.values[fullKey] = valueNode.as!real.to!string;
            break;
        case NodeType.string:
            const value = valueNode.as!string;
            enforce(value.length <= maxScalarLength,
                ".adfmt scalar exceeds 4096 bytes for " ~ fullKey);
            result.values[fullKey] = value;
            break;
        case NodeType.null_:
            result.values[fullKey] = "";
            break;
        case NodeType.binary:
        case NodeType.timestamp:
        case NodeType.mapping:
        case NodeType.sequence:
        case NodeType.merge:
        case NodeType.invalid:
            enforce(false, "Unsupported YAML value for .adfmt option " ~ fullKey);
        }
    }
}
