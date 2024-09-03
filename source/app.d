module app;

import std.stdio;
import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.json;
import std.path;
import std.process;
import std.string;
import std.getopt;
import core.thread;
import base;
import config;
import segments;
import themes;
import utils : getValidCwd;

class Powerline
{
    private PowerlineConfig _config;
    private ThemeColors _theme;
    string cwd;
    string colorTemplate = "\\[\\e%s\\]";
    string reset = "\\[\\e[0m\\]";
    string lock;
    string network;
    string separator;
    string separatorThin;
    SegmentInfo[] segments;
    string shell;
    int prevError;

    this(string[] args, PowerlineConfig config, ThemeColors theme, string shell, int prevError)
    {
        this._config = config;
        this._theme = theme;
        this.cwd = getValidCwd();

        this.reset = colorTemplate.format("0");
        this.separator = config.mode == "patched" ? "\uE0B0" : ">";
        // this.separatorThin = config.mode == "patched" ? "\uE0B1" : ">";
        this.separatorThin = "/";
        this.lock = config.mode == "patched" ? "" : "RO";
        this.network = "SSH";
        this.shell = shell;
        this.prevError = prevError;
    }

    void append(string content, int fg, int bg, string separator = null,
                int separatorFg = -1, bool sanitize = true)
    {
        if (shell == "bash" && sanitize)
        {
            import std.regex : regex, replaceAll;
            content = content.replaceAll(regex(r"([`$])"), "\\$1");
        }
        segments ~= SegmentInfo(content, fg, bg,
            separator ? separator : this.separator,
            separatorFg != -1 ? separatorFg : bg);
    }

    @property ThemeColors theme() { return _theme; }

    private string fgcolor(int code)
    {
        return code == -1 ? "\\[\\e[39m\\]" : colorTemplate.format("[38;5;" ~ code.to!string ~ "m");
    }

    private string bgcolor(int code)
    {
        return code == -1 ? "\\[\\e[49m\\]" : colorTemplate.format("[48;5;" ~ code.to!string ~ "m");
    }

    string draw()
    {
        string result;
        for (int i = 0; i < segments.length; i++)
        {
            if (i < segments.length - 1)
            {
                result ~= drawSegment(segments[i], segments[i + 1]);
            }
            else
            {
                result ~= drawSegment(segments[i]);
                result ~= fgcolor(segments[i].bg) ~ bgcolor(theme.reset) ~ separator ~ "\\[\\e[0m\\]";
            }
        }
        return result ~ reset ~ " ";
    }

    private string drawSegment(SegmentInfo segment, SegmentInfo nextSegment = SegmentInfo.init)
    {
        string result = fgcolor(segment.fg) ~ bgcolor(segment.bg);
        if (segment.bold)
            result ~= "\\[\\e[1m\\]";
        result ~= segment.content;
        if (segment.bold)
            result ~= "\\[\\e[22m\\]";
        if (nextSegment != SegmentInfo.init)
        {
            result ~= bgcolor(nextSegment.bg) ~ fgcolor(segment.separatorFg) ~ segment.separator;
        }
        return result;
    }
}

SegmentInfo[] createSegments(string segmentType, Powerline powerline, JSONValue segmentConfig)
{
    auto theme = powerline.theme;
    auto cwd = powerline.cwd;

    switch (segmentType)
    {
        case "username":
            return usernameSegment(theme);
        case "hostname":
            return hostnameSegment(theme, segmentConfig);
        case "newline":
            return newlineSegment(theme);
        case "stdout":
            return stdoutSegment(theme, cwd, segmentConfig);
        case "env":
            return envSegment(theme, segmentConfig);
        case "uptime":
            return uptimeSegment(theme);
        case "ssh":
            return sshSegment(theme);
        case "cwd":
            return cwdSegments(theme, cwd, powerline.separatorThin, segmentConfig);
        case "readonly":
            return readonlySegment(theme, cwd);
        case "git":
            return gitSegments(theme, cwd, segmentConfig);
        case "git_stash":
            return gitStashSegment(theme, cwd);
        case "svn":
            return svnSegments(theme, cwd);
        case "fossil":
            return fossilSegments(theme, cwd);
        case "bzr":
            return bzrSegments(theme, cwd);
        case "hg":
            return hgSegments(theme, cwd);
        case "virtual_env":
            return virtualEnvSegment(theme);
        case "aws_profile":
            return awsProfileSegment(theme);
        case "battery":
            return batterySegment(theme, segmentConfig);
        case "dev":
            return devSegment(theme);
        case "exit_code":
            return exitCodeSegment(theme, powerline.prevError);
        case "jobs":
            return jobsSegment(theme, cwd, powerline.shell);
        case "time":
            return timeSegment(theme);
        case "node_version":
            return nodeVersionSegment(theme, cwd);
        case "npm_version":
            return npmVersionSegment(theme, cwd);
        case "php_version":
            return phpVersionSegment(theme, cwd);
        case "rbenv":
            return rbenvSegment(theme, cwd);
        case "root":
            return rootSegment(theme, powerline.shell);
        case "ruby_version":
            return rubyVersionSegment(theme);
        case "set_term_title":
            return setTermTitleSegment(theme, cwd, powerline.shell);
        default:
            throw new Exception("Unknown segment type: " ~ segmentType);
    }
}

void main(string[] args)
{
    string shell = "bash";
    int prevError = 0;

    auto helpInformation = getopt(
        args,
        "shell", "Set this to your shell type (bash|tcsh|zsh|bare)", &shell,
        "prev-error", "Error code returned by the last command", &prevError,
    );

    if (helpInformation.helpWanted)
    {
        defaultGetoptPrinter("Powerline-Shell-D", helpInformation.options);
        return;
    }

    auto config = findConfig();
    auto theme = loadTheme(config.theme);
    auto powerline = new Powerline(args, config, theme, shell, prevError);

    foreach (segmentConfig; config.segments)
    {
        auto segmentInfos = createSegments(segmentConfig.type, powerline, segmentConfig.options);
        foreach (segmentInfo; segmentInfos)
        {
            if (segmentInfo.content.length > 0)
            {
                powerline.append(segmentInfo.content, segmentInfo.fg, segmentInfo.bg,
                                segmentInfo.separator, segmentInfo.separatorFg, segmentInfo.bold);
            }
        }
    }

    write(powerline.draw());
}
