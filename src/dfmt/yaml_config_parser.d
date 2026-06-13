// SPDX-License-Identifier: BSL-1.0

module dfmt.yaml_config_parser;

import dyaml : Loader, Node, NodeID, NodeType;

struct AdfmtYamlDocument
{
    string[string] values;
}

AdfmtYamlDocument parseAdfmtYaml(string path)
{
    import std.file : readText;
    import std.format : format;

    Node root;
    try
    {
        const yaml = prepareAdfmtYaml(readText(path));
        root = Loader.fromString(yaml).load();
    }
    catch (Exception error)
    {
        throw new Exception(format("%s: invalid .adfmt YAML: %s", path, error.msg));
    }

    AdfmtYamlDocument result;
    flattenMapping(root, "", result);
    return result;
}

private string prepareAdfmtYaml(string yaml)
{
    return yaml;
}

private void flattenMapping(const Node node, string prefix, ref AdfmtYamlDocument result)
{
    import std.conv : to;
    import std.exception : enforce;

    enforce(node.nodeID == NodeID.mapping, "The .adfmt root must be a mapping");
    foreach (const Node keyNode, const Node valueNode; node)
    {
        enforce(keyNode.type == NodeType.string, ".adfmt keys must be strings");
        const key = keyNode.as!string;
        const fullKey = prefix.length == 0 ? key : prefix ~ "." ~ key;

        if (valueNode.nodeID == NodeID.mapping)
        {
            flattenMapping(valueNode, fullKey, result);
            continue;
        }

        enforce(valueNode.nodeID == NodeID.scalar,
            "Sequences are not supported for .adfmt option " ~ fullKey);
        enforce((fullKey in result.values) is null,
            "Duplicate .adfmt option " ~ fullKey);

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
            result.values[fullKey] = valueNode.as!string;
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
