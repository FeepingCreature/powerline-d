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

static if (!__traits(compiles, GIT_OID_SHA1_HEXSIZE) && __traits(compiles, GIT_OID_SHA1_SIZE))
{
    enum GIT_OID_SHA1_HEXSIZE = GIT_OID_SHA1_SIZE * 2;
}

SegmentInfo[] gitSegments(ThemeColors theme, string cwd, JSONValue config)
{
    auto status = getGitStatus(cwd);
    if (status.branch.empty)
        return [];

    SegmentInfo[] segments;
    segments ~= createBranchSegment(status, theme);
    segments ~= createStatusSegments(status, theme);
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

    if (stashCount == 0)
        return [];

    string stashStr = stashCount > 1 ? stashCount.to!string : "";
    stashStr ~= "≡";

    return [SegmentInfo(" " ~ stashStr ~ " ", theme.gitStashFg, theme.gitStashBg)];
}

private:

SegmentInfo createBranchSegment(GitStatus status, ThemeColors theme)
{
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
    return SegmentInfo(" " ~ status.branch ~ " ", fg, bg);
}

SegmentInfo[] createStatusSegments(GitStatus status, ThemeColors theme)
{
    SegmentInfo[] segments;
    segments ~= createStatusSegment(status.ahead, "⬆", theme.gitAheadFg, theme.gitAheadBg);
    segments ~= createStatusSegment(status.behind, "⬇", theme.gitBehindFg, theme.gitBehindBg);
    segments ~= createStatusSegment(status.staged, "✔", theme.gitStagedFg, theme.gitStagedBg);
    segments ~= createStatusSegment(status.notStaged, "✎", theme.gitNotStagedFg, theme.gitNotStagedBg);
    segments ~= createStatusSegment(status.untracked, "?", theme.gitUntrackedFg, theme.gitUntrackedBg);
    segments ~= createStatusSegment(status.conflicted, "!", theme.gitConflictedFg, theme.gitConflictedBg);
    return segments.filter!(s => !s.content.empty).array;
}

SegmentInfo createStatusSegment(int count, string symbol, int fg, int bg)
{
    if (count == 0)
        return SegmentInfo.init;
    string content = count == 1 ? symbol : count.to!string ~ symbol;
    return SegmentInfo(" " ~ content ~ " ", fg, bg);
}

extern(C) int increment(size_t index, const(char)* message, const(git_oid)* stash_id, void* payload) {
    (cast(size_t*)payload)[0]++;
    return 0;
}

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
    if (git_repository_open_ext(&repo, cwd.toStringz, GIT_REPOSITORY_OPEN_FROM_ENV, null) != 0)
        return status;
    scope(exit) git_repository_free(repo);

    getBranchInfo(repo, status);
    getStatusInfo(repo, status);

    return status;
}

void getBranchInfo(git_repository* repo, ref GitStatus status)
{
    git_reference* head;
    if (git_repository_head(&head, repo) != 0)
    {
        status.branch = "Big Bang";
        return;
    }
    scope(exit) git_reference_free(head);

    if (git_reference_is_branch(head))
        getBranchInfoForBranch(head, repo, status);
    else
        getBranchInfoForDetached(head, status);
}

void getBranchInfoForBranch(git_reference* head, git_repository* repo, ref GitStatus status)
{
    status.branch = git_reference_shorthand(head).fromStringz.idup;

    git_reference* upstream;
    if (git_branch_upstream(&upstream, head) != 0)
        return;
    scope(exit) git_reference_free(upstream);

    size_t ahead, behind;
    if (git_graph_ahead_behind(&ahead, &behind, repo, git_reference_target(head), git_reference_target(upstream)) != 0)
        return;

    status.ahead = cast(int)ahead;
    status.behind = cast(int)behind;
}

void getBranchInfoForDetached(git_reference* head, ref GitStatus status)
{
    git_object* target_obj;
    if (git_reference_peel(&target_obj, head, GIT_OBJECT_COMMIT) != 0)
    {
        status.branch = "Big Bang";
        return;
    }
    scope(exit) git_object_free(target_obj);

    git_describe_options describe_options;
    git_describe_options_init(&describe_options, GIT_DESCRIBE_OPTIONS_VERSION);
    describe_options.describe_strategy = GIT_DESCRIBE_ALL;

    git_describe_result* describe_result;
    if (git_describe_commit(&describe_result, target_obj, &describe_options) != 0)
    {
        status.branch = getDetachedOid(target_obj);
        return;
    }
    scope(exit) git_describe_result_free(describe_result);

    git_buf buf;
    git_describe_format_options format_options;
    git_describe_format_options_init(&format_options, GIT_DESCRIBE_FORMAT_OPTIONS_VERSION);

    if (git_describe_format(&buf, describe_result, &format_options) != 0)
    {
        status.branch = getDetachedOid(target_obj);
        return;
    }
    scope(exit) git_buf_free(&buf);

    status.branch = "⚓ " ~ buf.ptr.fromStringz.idup;
}

string getDetachedOid(git_object* obj)
{
    char[GIT_OID_SHA1_HEXSIZE + 1] oid_buf;
    git_oid_tostr(oid_buf.ptr, oid_buf.length, git_object_id(obj));
    return "⎇ " ~ oid_buf[0 .. 7].idup;
}

void getStatusInfo(git_repository* repo, ref GitStatus status)
{
    git_status_options statusopt = git_status_options(GIT_STATUS_OPTIONS_VERSION);
    statusopt.show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
    statusopt.flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED |
                      GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX |
                      GIT_STATUS_OPT_SORT_CASE_SENSITIVELY |
                      GIT_STATUS_OPT_INCLUDE_UNMODIFIED;

    git_status_list* statusList;
    if (git_status_list_new(&statusList, repo, &statusopt) != 0)
        return;
    scope(exit) git_status_list_free(statusList);

    size_t count = git_status_list_entrycount(statusList);
    for (size_t i = 0; i < count; i++)
    {
        const(git_status_entry)* entry = git_status_byindex(statusList, i);
        updateStatusCounts(entry, status);
    }

    status.isClean = (status.staged == 0 && status.notStaged == 0 && status.untracked == 0 && status.conflicted == 0);
}

void updateStatusCounts(const(git_status_entry)* entry, ref GitStatus status)
{
    uint s = entry.status;

    if (s & GIT_STATUS_INDEX_NEW || s & GIT_STATUS_INDEX_MODIFIED ||
        s & GIT_STATUS_INDEX_DELETED || s & GIT_STATUS_INDEX_RENAMED ||
        s & GIT_STATUS_INDEX_TYPECHANGE)
    {
        status.staged++;
    }

    if (s & GIT_STATUS_WT_MODIFIED || s & GIT_STATUS_WT_DELETED ||
        s & GIT_STATUS_WT_TYPECHANGE || s & GIT_STATUS_WT_RENAMED)
    {
        status.notStaged++;
    }

    if (s & GIT_STATUS_WT_NEW)
    {
        status.untracked++;
    }

    if (s & GIT_STATUS_CONFLICTED)
    {
        status.conflicted++;
    }
}
