module themes;

import std.conv : to;
import std.json;
import std.file;
import std.path;

struct ThemeColors {
    int reset = -1;
    int usernameFg = 250;
    int usernameBg = 240;
    int usernameRootBg = 124;
    int hostnameFg = 250;
    int hostnameBg = 238;
    bool homeSpecialDisplay = true;
    int homeBg = 31;
    int homeFg = 15;
    int pathBg = 237;
    int pathFg = 250;
    int cwdFg = 254;
    int separatorFg = 244;
    int readonlyBg = 124;
    int readonlyFg = 254;
    int sshBg = 166;
    int sshFg = 254;
    int repoCleanBg = 148;
    int repoCleanFg = 0;
    int repoDirtyBg = 161;
    int repoDirtyFg = 15;
    int jobsFg = 39;
    int jobsBg = 238;
    int cmdPassedBg = 236;
    int cmdPassedFg = 15;
    int cmdFailedBg = 161;
    int cmdFailedFg = 15;
    int svnChangesBg = 148;
    int svnChangesFg = 22;

    // git colors
    int gitAheadBg = 240;
    int gitAheadFg = 250;
    int gitBehindBg = 240;
    int gitBehindFg = 250;
    int gitStagedBg = 22;
    int gitStagedFg = 15;
    int gitNotstagedBg = 130;
    int gitNotstagedFg = 15;
    int gitUntrackedBg = 52;
    int gitUntrackedFg = 15;
    int gitConflictedBg = 9;
    int gitConflictedFg = 15;
    int gitDetachedFg = 255;
    int gitDetachedBg = 61;
    int gitStashFg = 15;
    int gitStashBg = 0;

    int virtualEnvBg = 35;
    int virtualEnvFg = 0;

    // AWS Profile colors
    int awsProfileFg = 14;
    int awsProfileBg = 8;

    // Battery colors
    int batteryNormalFg = 7;
    int batteryNormalBg = 22;
    int batteryLowFg = 7;
    int batteryLowBg = 196;

    // Time colors
    int timeFg = 250;
    int timeBg = 238;
}

ThemeColors loadTheme(string themeName)
{
    import std.path : buildPath, expandTilde;
    import std.file : exists, readText;

    string[] themePaths = [
        buildPath(expandTilde("~/.powerline-themes"), themeName ~ ".json"),
        buildPath("themes", themeName ~ ".json")
    ];

    foreach (themePath; themePaths)
    {
        if (exists(themePath))
        {
            try
            {
                string themeContent = readText(themePath);
                JSONValue themeJson = parseJSON(themeContent);
                return deserializeTheme(themeJson);
            }
            catch (Exception e)
            {
                import std.stdio : stderr;
                stderr.writefln("Error loading theme '%s': %s", themeName, e.msg);
            }
        }
    }

    // Fallback to default theme
    return ThemeColors();
}

ThemeColors deserializeTheme(JSONValue json)
{
    ThemeColors theme;

    static foreach (member; __traits(allMembers, ThemeColors))
    {{
        static if (is(typeof(__traits(getMember, theme, member)) == int))
        {
            if (member in json)
            {
                __traits(getMember, theme, member) = json[member].integer.to!int;
            }
        }
        else static if (is(typeof(__traits(getMember, theme, member)) == bool))
        {
            if (member in json)
            {
                __traits(getMember, theme, member) = json[member].boolean;
            }
        }
    }}

    return theme;
}

