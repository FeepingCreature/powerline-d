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

SegmentInfo[] cwdSegments(ThemeColors theme, string cwd, string separator, string separatorThin, JSONValue config)
{
    const string ELLIPSIS = "\u2026";

    string replacedCwd = replaceHomeDir(cwd);
    string[] names = splitPathIntoNames(replacedCwd);

    bool fullCwd = config.getConfigValue("full_cwd", false);
    int maxDepth = config.getConfigValue("max_depth", 5);
    string mode = config.getConfigValue("mode", "fancy");

    if (maxDepth <= 0)
    {
        // Warning: Ignoring cwd.max_depth option since it's not greater than 0
    }
    else if (names.length > maxDepth)
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

    bool isFirstRealDir = true;
    foreach (i, name; names)
    {
        bool isLastDir = (i == names.length - 1);
        auto colors = getFgBg(theme, name, isLastDir);

        string dirSeparator;
        int separatorFg;

        if (name == "~" && theme.homeSpecialDisplay)
        {
            dirSeparator = null;
            separatorFg = theme.homeBg;
        }
        else if (isLastDir)
        {
            dirSeparator = null;
            separatorFg = theme.pathBg;
        }
        else
        {
            dirSeparator = separatorThin;
            separatorFg = theme.separatorFg;
        }

        if (!isLastDir || !fullCwd)
        {
            name = maybeShortenName(name, config);
        }

        if (mode == "compact")
        {
            segments ~= SegmentInfo(name, colors[0], colors[1], dirSeparator, separatorFg);
            continue;
        }

        if (name == "~" && theme.homeSpecialDisplay)
        {
            name = " " ~ name ~ " ";
        }
        else if (isFirstRealDir && isLastDir)
        {
            name = " " ~ name ~ " ";
        }
        else if (isFirstRealDir)
        {
            name = " " ~ name;
            isFirstRealDir = false;
        }
        else if (isLastDir)
        {
            name = name ~ " ";
        }

        segments ~= SegmentInfo(name, colors[0], colors[1], dirSeparator, separatorFg);
    }

    // Add the thick separator after the last segment
    if (!segments.empty)
    {
        segments[$ - 1].separator = separator;
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
    auto parts = cwd.split("/").filter!(s => !s.empty).array;
    return parts.empty ? ["/"] : parts;
}

int[2] getFgBg(ThemeColors theme, string name, bool isLastDir)
{
    if (name == "~" && theme.homeSpecialDisplay)
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
