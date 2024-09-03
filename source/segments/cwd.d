module segments.cwd;

import std.json;
import std.path;
import std.range;
import std.array;
import std.algorithm;
import std.conv;
import base;
import config;
import themes;

SegmentInfo[] cwdSegments(ThemeColors theme, string cwd, string separatorThin, JSONValue config)
{
    const string ELLIPSIS = "...";

    string replacedCwd = replaceHomeDir(cwd);
    string[] names = splitPathIntoNames(replacedCwd);

    bool fullCwd = config.getConfigValue("full_cwd", false);
    int maxDepth = config.getConfigValue("max_depth", 5);
    string mode = config.getConfigValue("mode", "fancy");

    if (maxDepth > 0 && names.length > maxDepth)
    {
        int nBefore = (maxDepth > 2) ? 2 : maxDepth - 1;
        names = names[0 .. nBefore] ~ [ELLIPSIS] ~ names[$ - (maxDepth - nBefore) .. $];
    }

    SegmentInfo[] segments;

    if (mode == "dironly")
    {
        names = names[$ - 1 .. $];
    }
    else if (mode == "plain")
    {
        string joined = names.join("/");
        segments ~= SegmentInfo(" " ~ joined ~ " ", theme.cwdFg, theme.pathBg);
        return segments;
    }

    foreach (i, name; names)
    {
        bool isLastDir = (i == names.length - 1);
        auto colors = getFgBg(theme, name, isLastDir);

        string separator = isLastDir ? null : separatorThin;
        int separatorFg = isLastDir ? theme.pathBg : theme.separatorFg;

        if (!isLastDir || !fullCwd)
        {
            name = maybeShortenName(name, config);
        }

        segments ~= SegmentInfo(name, colors[0], colors[1], separator, separatorFg);
    }

    return segments;
}

private:

string replaceHomeDir(string cwd)
{
    string home = expandTilde("~");
    if (cwd.startsWith(home))
    {
        return "~" ~ cwd[home.length .. $];
    }
    return cwd;
}

string[] splitPathIntoNames(string cwd)
{
    return cwd.split("/").filter!(s => !s.empty).array;
}

int[2] getFgBg(ThemeColors theme, string name, bool isLastDir)
{
    if (name == "~")
    {
        return [theme.homeFg, theme.homeBg];
    }
    else if (isLastDir)
    {
        return [theme.cwdFg, theme.pathBg];
    }
    else
    {
        return [theme.pathFg, theme.pathBg];
    }
}

string maybeShortenName(string name, JSONValue config)
{
    int maxSize = config.getConfigValue("max_dir_size", 0);
    if (maxSize > 0)
    {
        return name.take(maxSize).to!string;
    }
    return name;
}
