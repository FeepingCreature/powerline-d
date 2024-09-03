module segments.git;

import std.json;
import std.process;
import std.array;
import std.algorithm;
import std.string;
import std.conv;
import std.regex;
import base;
import config;
import themes;

SegmentInfo[] gitSegments(ThemeColors theme, string cwd, JSONValue config)
{
    auto status = getGitStatus(cwd);
    if (status.branch.length == 0)
        return [];

    SegmentInfo[] segments;

    // Branch segment
    int fg, bg;
    if (status.branch == "Big Bang" || status.branch.startsWith("⎇"))
    {
        fg = theme.gitDetachedFg;
        bg = theme.gitDetachedBg;
    }
    else if (status.isClean)
    {
        fg = theme.repoCleanFg;
        bg = theme.repoCleanBg;
    }
    else
    {
        fg = theme.repoDirtyFg;
        bg = theme.repoDirtyBg;
    }
    segments ~= SegmentInfo(" " ~ status.branch ~ " ", fg, bg);

    string check(int count, string code)
    {
        if (count == 0)
            return "";
        return count == 1 ? code : count.to!string ~ code;
    }
    // Status segments
    if (status.ahead > 0)
    {
        const content = check(status.ahead, "⬆ ");
        segments ~= SegmentInfo(" " ~ content.strip ~ " ", theme.gitAheadFg, theme.gitAheadBg);
    }
    if (status.behind > 0)
    {
        const content = check(status.behind, "⬇ ");
        segments ~= SegmentInfo(" " ~ content.strip ~ " ", theme.gitBehindFg, theme.gitBehindBg);
    }
    if (status.staged > 0 || status.notStaged > 0)
    {
        const content = check(status.staged, "✔   ") ~ check(status.notStaged, "✎   ");
        segments ~= SegmentInfo(" " ~ content.strip ~ " ", theme.gitStagedFg, theme.gitStagedBg);
    }
    if (status.untracked > 0)
    {
        const content = check(status.untracked, "?");
        segments ~= SegmentInfo(" " ~ content.strip ~ " ", theme.gitUntrackedFg, theme
                .gitUntrackedBg);
    }
    if (status.conflicted > 0)
    {
        const content = check(status.conflicted, "!");
        segments ~= SegmentInfo(" " ~ content.strip ~ " ", theme.gitConflictedFg, theme
                .gitConflictedBg);
    }

    return segments;
}

SegmentInfo[] gitStashSegment(ThemeColors theme, string cwd)
{
    auto result = execute(["git", "stash", "list"], null, Config.none, size_t.max, cwd);
    if (result.status != 0)
        return [];

    int stashCount = cast(int) result.output.split("\n").length - 1;
    if (stashCount <= 0)
        return [];

    string stashStr = stashCount > 1 ? stashCount.to!string : "";
    stashStr ~= "≡";

    return [SegmentInfo(" " ~ stashStr ~ " ", theme.gitStashFg, theme.gitStashBg)];
}

private:

struct GitStatus
{
    string branch;
    bool isClean;
    int ahead;
    int behind;
    int staged;
    int notStaged;
    int untracked;
    int conflicted;
}

GitStatus getGitStatus(string cwd)
{
    GitStatus status;

    // Check if we're in a git repository
    auto gitDirResult = execute(["git", "rev-parse", "--git-dir"], null, Config.none, size_t.max, cwd);
    if (gitDirResult.status != 0)
        return status;

    // Get the status
    auto statusResult = execute(["git", "status", "--porcelain", "--branch"], null, Config.none, size_t.max, cwd);
    if (statusResult.status != 0)
        return status;

    auto lines = statusResult.output.split("\n");

    // Try to parse branch info
    auto branchLine = lines.find!(l => l.startsWith("##"));
    if (!branchLine.empty)
    {
        auto branchInfo = branchLine.front[3 .. $].strip();
        auto branchMatch = branchInfo.matchFirst(
                r"^(\S+?)(\.{3}(\S+?)( \[(ahead (\d+)(, )?)?(behind (\d+))?\])?)?$");
        if (!branchMatch.empty)
        {
            status.branch = branchMatch[1];
            if (branchMatch.length > 6 && branchMatch[6].length > 0)
                status.ahead = branchMatch[6].to!int;
            if (branchMatch.length > 9 && branchMatch[9].length > 0)
                status.behind = branchMatch[9].to!int;
        }
    }

    // If we couldn't parse branch info, try git describe
    if (status.branch.length == 0)
    {
        auto describeResult = execute(["git", "describe", "--tags", "--always"], null, Config.none, size_t.max, cwd);
        if (describeResult.status == 0)
        {
            status.branch = "⎇ " ~ describeResult.output.strip();
        }
        else
        {
            status.branch = "Big Bang";
        }
    }

    // Parse status
    foreach (line; lines)
    {
        if (line.length >= 2 && !line.startsWith("##"))
        {
            if (line[0 .. 2] == "??")
                status.untracked++;
            else if (line[0 .. 2].among("DD", "AU", "UD", "UA", "DU", "AA", "UU"))
                status.conflicted++;
            else
            {
                if (line[0] != ' ')
                    status.staged++;
                if (line[1] != ' ')
                    status.notStaged++;
            }
        }
    }

    status.isClean = (status.staged == 0 && status.notStaged == 0 && status.untracked == 0);

    return status;
}
