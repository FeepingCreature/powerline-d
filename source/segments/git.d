module segments.git;

import std.json;
import std.array;
import std.algorithm;
import std.string;
import std.conv;
import std.regex;
import base;
import config;
import themes;
import git2;

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
    if (status.staged > 0)
    {
        const content = check(status.staged, "✔   ");
        segments ~= SegmentInfo(" " ~ content.strip ~ " ", theme.gitStagedFg, theme.gitStagedBg);
    }
    if (status.notStaged > 0)
    {
        const content = check(status.notStaged, "✎   ");
        segments ~= SegmentInfo(" " ~ content.strip ~ " ",
            theme.gitNotStagedFg, theme.gitNotStagedBg);
    }
    if (status.untracked > 0)
    {
        const content = check(status.untracked, "?");
        segments ~= SegmentInfo(" " ~ content.strip ~ " ",
            theme.gitUntrackedFg, theme.gitUntrackedBg);
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
    git_libgit2_init();
    scope(exit) git_libgit2_shutdown();

    git_repository* repo;
    if (git_repository_open(&repo, cwd.toStringz) != 0)
        return [];
    scope(exit) git_repository_free(repo);

    size_t stashCount;
    if (git_stash_foreach(repo, &increment, &stashCount) != 0)
        return [];

    if (stashCount <= 0)
        return [];

    string stashStr = stashCount > 1 ? stashCount.to!string : "";
    stashStr ~= "≡";

    return [SegmentInfo(" " ~ stashStr ~ " ", theme.gitStashFg, theme.gitStashBg)];
}

extern(C) int increment(size_t index, const(char)* message, const(git_oid)* stash_id, void* payload) {
    (cast(size_t*)payload)[0]++;
    return 0;
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

    git_libgit2_init();
    scope(exit) git_libgit2_shutdown();

    git_repository* repo;
    if (git_repository_open(&repo, cwd.toStringz) != 0)
        return status;
    scope(exit) git_repository_free(repo);

    // Get branch info
    git_reference* head;
    if (git_repository_head(&head, repo) == 0)
    {
        scope(exit) git_reference_free(head);
        if (git_reference_is_branch(head))
        {
            status.branch = git_reference_shorthand(head).fromStringz.idup;

            // Get ahead/behind
            git_reference* upstream;
            if (git_branch_upstream(&upstream, head) == 0)
            {
                scope(exit) git_reference_free(upstream);
                size_t ahead, behind;
                if (git_graph_ahead_behind(&ahead, &behind, repo, git_reference_target(head), git_reference_target(upstream)) == 0)
                {
                    status.ahead = cast(int)ahead;
                    status.behind = cast(int)behind;
                }
            }
        }
        else
        {
            git_object* obj;
            if (git_reference_peel(&obj, head, GIT_OBJECT_COMMIT) == 0)
            {
                scope(exit) git_object_free(obj);
                char[GIT_OID_SHA1_HEXSIZE + 1] buf;
                git_oid_tostr(buf.ptr, buf.length, git_object_id(obj));
                status.branch = "⎇ " ~ buf[0 .. 7].idup;
            }
            else
            {
                status.branch = "Big Bang";
            }
        }
    }
    else
    {
        status.branch = "Big Bang";
    }

    // Get status
    git_status_options statusopt = git_status_options(GIT_STATUS_OPTIONS_VERSION);
    statusopt.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
    statusopt.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED |
                      GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX |
                      GIT_STATUS_OPT_SORT_CASE_SENSITIVELY;
    git_status_list* statusList;
    if (git_status_list_new(&statusList, repo, &statusopt) == 0)
    {
        scope(exit) git_status_list_free(statusList);
        size_t count = git_status_list_entrycount(statusList);
        for (size_t i = 0; i < count; i++)
        {
            const(git_status_entry)* entry = git_status_byindex(statusList, i);
            if (entry.status & GIT_STATUS_WT_NEW)
                status.untracked++;
            else if (entry.status & GIT_STATUS_INDEX_NEW)
                status.staged++;
            else if (entry.status & GIT_STATUS_INDEX_MODIFIED)
                status.staged++;
            else if (entry.status & GIT_STATUS_WT_MODIFIED)
                status.notStaged++;
            else if (entry.status & GIT_STATUS_CONFLICTED)
                status.conflicted++;
        }
    }

    status.isClean = (status.staged == 0 && status.notStaged == 0 && status.untracked == 0);

    return status;
}
