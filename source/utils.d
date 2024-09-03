module utils;

import std.algorithm;
import std.array;
import std.conv;
import std.string;
import std.process;

struct RepoStats
{
    int ahead;
    int behind;
    int new_;
    int changed;
    int staged;
    int conflicted;

    bool dirty() const
    {
        return new_ + changed + staged + conflicted > 0;
    }
}

string getValidCwd()
{
    import std.file : exists, getcwd;
    import std.path : buildPath, dirName;
    import std.stdio : stderr;

    try
    {
        string cwd = environment.get("PWD", getcwd());
        if (exists(cwd))
        {
            return cwd;
        }
        else
        {
            stderr.writeln("Warning: Current directory does not exist. Using root directory.");
            return "/";
        }
    }
    catch (Exception e)
    {
        stderr.writeln("Error getting current directory: ", e.msg);
        return "/";
    }
}

string[string] getSubprocessEnv()
{
    auto env = environment.toAA();
    env["PATH"] = environment.get("PATH");
    return env;
}

string[string] getGitSubprocessEnv()
{
    auto env = getSubprocessEnv();
    env["LANG"] = "C";
    return env;
}
