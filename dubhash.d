import std.algorithm;
import std.ascii;
import std.conv;
import std.exception;
import std.file;
import std.path;
import std.process;
import std.range;
import std.string;

void main()
{
    auto dir = environment.get("DUB_PACKAGE_DIR");
    auto hashFile = dir.buildPath("bin", "dubhash.txt");
    auto gitVer = execute(["git", "-C", dir, "describe", "--tags",
        "--match", "adfmt-v[0-9]*"]);
    auto describedVersion = gitVer.output.strip;
    if (describedVersion.startsWith("adfmt-"))
        describedVersion = describedVersion["adfmt-".length .. $];
    auto versionFile = dir.buildPath("VERSION");
    auto fallbackVersion = versionFile.exists
        ? "v" ~ versionFile.readText.strip
        : "v" ~ dir.dirName.baseName.findSplitAfter(
            environment.get("DUB_ROOT_PACKAGE") ~ "-")[1];
    auto ver = (gitVer.status == 0 ? describedVersion
            : fallbackVersion).ifThrown("0.0.0")
        .chain(newline).to!string.strip;
    dir.buildPath("bin").mkdirRecurse;
    if (!hashFile.exists || ver != hashFile.readText.strip)
        hashFile.write(ver);
}
