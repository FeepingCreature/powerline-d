module segments;

import std.json;
import std.process;
import core.sys.posix.unistd;
import std.path;
import std.array;
import std.algorithm;
import std.range;
import std.file;
import std.string;
import std.conv;
import std.datetime;
import std.digest.md : md5Of;
import base;
import config;
import themes;
import utils;

public import segments.cwd;
public import segments.git;

SegmentInfo[] usernameSegment(ThemeColors theme)
{
    string username = environment.get("USER");
    if (username.empty)
        return [];

    int bgcolor = username == "root" ?
        theme.usernameRootBg :
        theme.usernameBg;

    return [SegmentInfo(" " ~ username ~ " ",
                       theme.usernameFg,
                       bgcolor)];
}

SegmentInfo[] hostnameSegment(ThemeColors theme, JSONValue config)
{
    import core.sys.posix.unistd : gethostname;
    import std.string : fromStringz;

    char[256] hostname;
    auto result = gethostname(hostname.ptr, hostname.length);
    if (result != 0)
        return [];

    string hostnameStr = hostname.ptr.fromStringz.idup;

    if (config.getConfigValue("colorize", false))
    {
        auto hash = md5Of(hostnameStr);
        int fg = hash[0] % 15 + 1;
        int bg = hash[1] % 15 + 1;
        return [SegmentInfo(" " ~ hostnameStr ~ " ", fg, bg)];
    }
    else
    {
        return [SegmentInfo(" " ~ hostnameStr ~ " ",
                           theme.hostnameFg,
                           theme.hostnameBg)];
    }
}

SegmentInfo[] newlineSegment(ThemeColors theme)
{
    return [SegmentInfo("\n", theme.reset, theme.reset, "")];
}

SegmentInfo[] stdoutSegment(ThemeColors theme, string cwd, JSONValue config)
{
    string command = config.getConfigValue("command", "");
    if (command.empty)
        return [];

    auto result = execute(["sh", "-c", command], null, Config.none, size_t.max, cwd);
    if (result.status != 0)
        return [];

    string output = result.output.strip();
    if (output.empty)
        return [];

    int fg = config.getConfigValue("fg", theme.pathFg);
    int bg = config.getConfigValue("bg", theme.pathBg);

    return [SegmentInfo(" " ~ output ~ " ", fg, bg)];
}

SegmentInfo[] uptimeSegment(ThemeColors theme)
{
    try
    {
        auto uptime = execute(["uptime", "-p"]);
        if (uptime.status == 0)
        {
            string uptimeStr = uptime.output.strip();
            return [SegmentInfo(" " ~ uptimeStr ~ " ", theme.timeFg, theme.timeBg)];
        }
    }
    catch (Exception e)
    {
        // Fallback to manual calculation if 'uptime -p' is not available
        auto currentTime = Clock.currTime();
        auto bootTime = SysTime.fromUnixTime(0);  // You might need to find a way to get actual boot time
        auto uptime = currentTime - bootTime;

        auto days = uptime.total!"days";
        auto hours = uptime.total!"hours" % 24;
        auto minutes = uptime.total!"minutes" % 60;

        string uptimeStr = format("%d days %02d:%02d", days, hours, minutes);
        return [SegmentInfo(" " ~ uptimeStr ~ " ", theme.timeFg, theme.timeBg)];
    }

    return [];
}

SegmentInfo[] envSegment(ThemeColors theme, JSONValue config)
{
    string varName = config.getConfigValue("var", "");
    if (varName.empty)
        return [];

    string value = environment.get(varName, "");
    if (value.empty)
        return [];

    int fg = config.getConfigValue("fg", theme.pathFg);
    int bg = config.getConfigValue("bg", theme.pathBg);

    return [SegmentInfo(" " ~ value ~ " ", fg, bg)];
}

SegmentInfo[] sshSegment(ThemeColors theme)
{
    if ("SSH_CLIENT" in environment)
    {
        return [SegmentInfo(" SSH ",
                           theme.sshFg,
                           theme.sshBg)];
    }
    return [];
}

SegmentInfo[] readonlySegment(ThemeColors theme, string cwd)
{
    auto attrs = getAttributes(cwd);

    if ((attrIsDir(attrs) || attrIsFile(attrs)) && access(cwd.ptr, W_OK) != 0)
    {
        return [SegmentInfo(" RO ",
                           theme.readonlyFg,
                           theme.readonlyBg)];
    }
    return [];
}

SegmentInfo[] virtualEnvSegment(ThemeColors theme)
{
    string virtualEnv = environment.get("VIRTUAL_ENV");
    string condaEnvPath = environment.get("CONDA_ENV_PATH");
    string condaDefaultEnv = environment.get("CONDA_DEFAULT_ENV");

    string env = virtualEnv ? virtualEnv : (condaEnvPath ? condaEnvPath : condaDefaultEnv);

    if (env.empty)
        return [];

    if (virtualEnv && baseName(env) == ".venv")
        env = baseName(dirName(env));

    string envName = baseName(env);

    return [SegmentInfo(" " ~ envName ~ " ",
                       theme.virtualEnvFg,
                       theme.virtualEnvBg)];
}

SegmentInfo[] awsProfileSegment(ThemeColors theme)
{
    string awsProfile = environment.get("AWS_PROFILE", environment.get("AWS_DEFAULT_PROFILE"));

    if (awsProfile.empty)
        return [];

    return [SegmentInfo(" aws:" ~ baseName(awsProfile) ~ " ",
                       theme.awsProfileFg,
                       theme.awsProfileBg)];
}

SegmentInfo[] batterySegment(ThemeColors theme, JSONValue config)
{
    string[] batteryDirs = ["/sys/class/power_supply/BAT0", "/sys/class/power_supply/BAT1"];
    string batteryDir;

    foreach (dir; batteryDirs)
    {
        if (exists(dir))
        {
            batteryDir = dir;
            break;
        }
    }

    if (batteryDir.empty)
        return [];

    int capacity = readText(buildPath(batteryDir, "capacity")).strip().to!int;
    string status = readText(buildPath(batteryDir, "status")).strip();

    string content;
    if (status == "Full")
    {
        if (config.getConfigValue("always_show_percentage", false))
            content = format(" %d%% \u26A1 ", capacity);
        else
            content = " \u26A1 ";
    }
    else if (status == "Charging")
    {
        content = format(" %d%% \u26A1 ", capacity);
    }
    else
    {
        content = format(" %d%% ", capacity);
    }

    int fg, bg;
    if (capacity < 20)  // You can adjust this threshold
    {
        fg = theme.batteryLowFg;
        bg = theme.batteryLowBg;
    }
    else
    {
        fg = theme.batteryNormalFg;
        bg = theme.batteryNormalBg;
    }

    return [SegmentInfo(content, fg, bg)];
}

SegmentInfo[] devSegment(ThemeColors theme)
{
    if ("CONTAINER" in environment)
    {
        return [SegmentInfo("dev", theme.virtualEnvFg, theme.virtualEnvBg)];
    }
    return [];
}

SegmentInfo[] exitCodeSegment(ThemeColors theme, int prevError)
{
    if (prevError == 0)
        return [];

    return [SegmentInfo(" ERROR " ~ prevError.to!string ~ " ",
                       theme.cmdFailedFg,
                       theme.cmdFailedBg,
                       null, -1, true)];  // Set bold to true
}

SegmentInfo[] jobsSegment(ThemeColors theme, string cwd, string shell)
{
    int numJobs;

    switch (shell)
    {
        case "bash":
        case "zsh":
            auto result = execute(["ps", "-o", "ppid="], null, Config.none, size_t.max, cwd);
            if (result.status == 0)
            {
                auto ppid = thisProcessID.to!string;
                numJobs = cast(int)(result.output.split.count!(line => line.strip == ppid)) - 1;
            }
            break;
        case "fish":
            auto result = execute(["fish", "-c", "jobs -p | wc -l"], null, Config.none, size_t.max, cwd);
            if (result.status == 0)
            {
                numJobs = result.output.strip.to!int;
            }
            break;
        default:
            return [];
    }

    if (numJobs <= 0)
        return [];

    return [SegmentInfo(" " ~ numJobs.to!string ~ " ",
                       theme.jobsFg,
                       theme.jobsBg)];
}

SegmentInfo[] timeSegment(ThemeColors theme)
{
    auto now = Clock.currTime();
    string timeStr = format(" %02d:%02d:%02d ", now.hour, now.minute, now.second);

    return [SegmentInfo(timeStr,
                       theme.timeFg,
                       theme.timeBg)];
}

SegmentInfo[] nodeVersionSegment(ThemeColors theme, string cwd)
{
    auto result = execute(["node", "--version"], null, Config.none, size_t.max, cwd);
    if (result.status != 0)
        return [];

    string version_ = result.output.strip();
    return [SegmentInfo("node " ~ version_, theme.virtualEnvFg, theme.virtualEnvBg)];
}

SegmentInfo[] npmVersionSegment(ThemeColors theme, string cwd)
{
    auto result = execute(["npm", "--version"], null, Config.none, size_t.max, cwd);
    if (result.status != 0)
        return [];

    string version_ = result.output.strip();
    return [SegmentInfo("npm " ~ version_, theme.virtualEnvFg, theme.virtualEnvBg)];
}

SegmentInfo[] phpVersionSegment(ThemeColors theme, string cwd)
{
    auto result = execute(["php", "-r", "echo PHP_VERSION;"], null, Config.none, size_t.max, cwd);
    if (result.status != 0)
        return [];

    string version_ = result.output.split("-")[0];
    return [SegmentInfo(" " ~ version_ ~ " ", theme.virtualEnvFg, theme.virtualEnvBg)];
}

SegmentInfo[] rubyVersionSegment(ThemeColors theme)
{
    auto result = execute(["ruby", "-v"]);
    if (result.status != 0)
        return [];

    string version_ = result.output.split(" ")[1];
    string gemSet = environment.get("GEM_HOME", "@").split("@")[$-1];

    string content = version_;
    if (!gemSet.empty)
        content ~= "@" ~ gemSet;

    return [SegmentInfo(content, theme.virtualEnvFg, theme.virtualEnvBg)];
}

SegmentInfo[] rbenvSegment(ThemeColors theme, string cwd)
{
    auto result = execute(["rbenv", "local"], null, Config.none, size_t.max, cwd);
    if (result.status != 0 || result.output.strip().empty)
        return [];

    string version_ = result.output.strip();
    return [SegmentInfo(" " ~ version_ ~ " ",
                       theme.virtualEnvFg,
                       theme.virtualEnvBg)];
}

SegmentInfo[] rootSegment(ThemeColors theme, string shell)
{
    string rootIndicator;
    switch (shell)
    {
        case "bash":
            rootIndicator = " $ ";
            break;
        case "zsh":
            rootIndicator = " %# ";
            break;
        case "tcsh":
            rootIndicator = " %# ";
            break;
        default:
            rootIndicator = " $ ";
            break;
    }

    return [SegmentInfo(rootIndicator,
                       theme.cmdPassedFg,
                       theme.cmdPassedBg)];
}

SegmentInfo[] setTermTitleSegment(ThemeColors theme, string cwd, string shell)
{
    string term = environment.get("TERM");
    if (!term.startsWith("xterm") && !term.startsWith("rxvt"))
        return [];

    string setTitle;
    switch (shell)
    {
        case "bash":
            setTitle = "\033]0;\\u@\\h: \\w\007";
            break;
        case "zsh":
            setTitle = "%{\033]0;%n@%m: %~\007%}";
            break;
        default:
            import core.sys.posix.unistd : gethostname;
            char[256] hostname;
            if (gethostname(hostname.ptr, hostname.length) == 0)
            {
                string hostnameStr = hostname.ptr.fromStringz.idup;
                setTitle = format("\033]0;%s@%s: %s\007",
                                environment.get("USER"),
                                hostnameStr.split(".")[0],
                                cwd);
            }
            else
            {
                setTitle = format("\033]0;%s@unknown: %s\007",
                                environment.get("USER"),
                                cwd);
            }
            break;
    }

    return [SegmentInfo(setTitle, -1, -1, "")];
}

SegmentInfo[] svnSegments(ThemeColors theme, string cwd)
{
    auto result = execute(["svn", "info"], null, Config.none, size_t.max, cwd);
    if (result.status != 0)
        return [];

    string revision;
    foreach (line; result.output.splitLines())
    {
        if (line.startsWith("Revision: "))
        {
            revision = line["Revision: ".length .. $];
            break;
        }
    }

    if (revision.empty)
        return [];

    auto statusResult = execute(["svn", "status"], null, Config.none, size_t.max, cwd);
    if (statusResult.status != 0)
        return [];

    RepoStats stats;
    foreach (line; statusResult.output.splitLines())
    {
        if (line.empty) continue;
        switch (line[0])
        {
            case '?': stats.new_++; break;
            case 'A': stats.staged++; break;
            case 'M': stats.changed++; break;
            case 'C': stats.conflicted++; break;
            default: break;
        }
    }

    SegmentInfo[] segments;
    int fg = stats.dirty ? theme.repoDirtyFg : theme.repoCleanFg;
    int bg = stats.dirty ? theme.repoDirtyBg : theme.repoCleanBg;

    segments ~= SegmentInfo(" svn " ~ revision ~ " ", fg, bg);

    if (stats.dirty)
    {
        string status = "";
        if (stats.new_ > 0) status ~= "?" ~ stats.new_.to!string;
        if (stats.changed > 0) status ~= "+" ~ stats.changed.to!string;
        if (stats.staged > 0) status ~= "→" ~ stats.staged.to!string;
        if (stats.conflicted > 0) status ~= "×" ~ stats.conflicted.to!string;
        segments ~= SegmentInfo(" " ~ status ~ " ", theme.repoDirtyFg, theme.repoDirtyBg);
    }

    return segments;
}

SegmentInfo[] fossilSegments(ThemeColors theme, string cwd)
{
    auto result = execute(["fossil", "status"], null, Config.none, size_t.max, cwd);
    if (result.status != 0)
        return [];

    RepoStats stats;
    string branch;
    foreach (line; result.output.splitLines())
    {
        if (line.startsWith("local-root:"))
        {
            branch = line["local-root:".length .. $].strip();
        }
        else if (line.startsWith("ADDED"))
        {
            stats.staged++;
        }
        else if (line.startsWith("EXTRA"))
        {
            stats.new_++;
        }
        else if (line.startsWith("EDITED"))
        {
            stats.changed++;
        }
    }

    if (branch.empty)
        return [];

    SegmentInfo[] segments;
    int fg = stats.dirty ? theme.repoDirtyFg : theme.repoCleanFg;
    int bg = stats.dirty ? theme.repoDirtyBg : theme.repoCleanBg;

    segments ~= SegmentInfo(" fossil " ~ branch ~ " ", fg, bg);

    if (stats.dirty)
    {
        string status = "";
        if (stats.new_ > 0) status ~= "?" ~ stats.new_.to!string;
        if (stats.changed > 0) status ~= "+" ~ stats.changed.to!string;
        if (stats.staged > 0) status ~= "→" ~ stats.staged.to!string;
        segments ~= SegmentInfo(" " ~ status ~ " ", theme.repoDirtyFg, theme.repoDirtyBg);
    }

    return segments;
}

SegmentInfo[] bzrSegments(ThemeColors theme, string cwd)
{
    auto result = execute(["bzr", "status"], null, Config.none, size_t.max, cwd);
    if (result.status != 0)
        return [];

    RepoStats stats;
    foreach (line; result.output.splitLines())
    {
        if (line.startsWith("added:"))
            stats.staged++;
        else if (line.startsWith("unknown:"))
            stats.new_++;
        else if (line.startsWith("modified:"))
            stats.changed++;
        else if (line.startsWith("conflicts:"))
            stats.conflicted++;
    }

    auto branchResult = execute(["bzr", "nick"], null, Config.none, size_t.max, cwd);
    string branch = branchResult.status == 0 ? branchResult.output.strip() : "unknown";

    SegmentInfo[] segments;
    int fg = stats.dirty ? theme.repoDirtyFg : theme.repoCleanFg;
    int bg = stats.dirty ? theme.repoDirtyBg : theme.repoCleanBg;

    segments ~= SegmentInfo(" bzr " ~ branch ~ " ", fg, bg);

    if (stats.dirty)
    {
        string status = "";
        if (stats.new_ > 0) status ~= "?" ~ stats.new_.to!string;
        if (stats.changed > 0) status ~= "+" ~ stats.changed.to!string;
        if (stats.staged > 0) status ~= "→" ~ stats.staged.to!string;
        if (stats.conflicted > 0) status ~= "×" ~ stats.conflicted.to!string;
        segments ~= SegmentInfo(" " ~ status ~ " ", theme.repoDirtyFg, theme.repoDirtyBg);
    }

    return segments;
}

SegmentInfo[] hgSegments(ThemeColors theme, string cwd)
{
    auto result = execute(["hg", "status"], null, Config.none, size_t.max, cwd);
    if (result.status != 0)
        return [];

    RepoStats stats;
    foreach (line; result.output.splitLines())
    {
        if (line.empty) continue;
        switch (line[0])
        {
            case '?': stats.new_++; break;
            case 'A': stats.staged++; break;
            case 'M': stats.changed++; break;
            case 'R': stats.changed++; break;
            case '!': stats.changed++; break;
            default: break;
        }
    }

    auto branchResult = execute(["hg", "branch"], null, Config.none, size_t.max, cwd);
    string branch = branchResult.status == 0 ? branchResult.output.strip() : "default";

    SegmentInfo[] segments;
    int fg = stats.dirty ? theme.repoDirtyFg : theme.repoCleanFg;
    int bg = stats.dirty ? theme.repoDirtyBg : theme.repoCleanBg;

    segments ~= SegmentInfo(" hg " ~ branch ~ " ", fg, bg);

    if (stats.dirty)
    {
        string status = "";
        if (stats.new_ > 0) status ~= "?" ~ stats.new_.to!string;
        if (stats.changed > 0) status ~= "+" ~ stats.changed.to!string;
        if (stats.staged > 0) status ~= "→" ~ stats.staged.to!string;
        segments ~= SegmentInfo(" " ~ status ~ " ", theme.repoDirtyFg, theme.repoDirtyBg);
    }

    return segments;
}
