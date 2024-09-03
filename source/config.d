module config;

import std.conv : to;
import std.file;
import std.path;
import std.json;

struct SegmentConfig
{
    string type;
    JSONValue options;
}

struct PowerlineConfig
{
    SegmentConfig[] segments;
    string mode = "patched";
    string theme = "default";
}

PowerlineConfig findConfig()
{
    string[] configLocations = [
        "powerline-d.json",
        expandTilde("~/.powerline-d.json")
    ];

    foreach (location; configLocations)
    {
        if (exists(location))
        {
            try
            {
                string content = readText(location);
                JSONValue json = parseJSON(content);
                return deserializeConfig(json);
            }
            catch (Exception e)
            {
                import std.stdio : stderr;

                stderr.writefln("Config file (%s) could not be decoded! Error: %s", location, e.msg);
            }
        }
    }

    return defaultConfig;
}

enum defaultConfig = parseJSON(`
{
    "segments": [
        "ssh",
        "username",
        "hostname",
        "cwd",
        "git",
        "hg",
        "jobs",
        "root"
    ],
    "mode": "patched",
    "theme": "default"
}`).deserializeConfig;

PowerlineConfig deserializeConfig(JSONValue json)
{
    PowerlineConfig config;

    if ("segments" in json && json["segments"].type == JSONType.array)
    {
        foreach (segment; json["segments"].array)
        {
            SegmentConfig segConfig;
            if (segment.type == JSONType.string)
            {
                segConfig.type = segment.str;
                segConfig.options = JSONValue.init;
            }
            else if (segment.type == JSONType.object)
            {
                segConfig.type = segment["type"].str;
                segConfig.options = segment;
            }
            config.segments ~= segConfig;
        }
    }

    if ("mode" in json)
        config.mode = json["mode"].str;
    if ("theme" in json)
        config.theme = json["theme"].str;

    return config;
}

T getConfigValue(T)(JSONValue config, string key, T defaultValue)
{
    if (config.type == JSONType.object && key in config)
    {
        static if (is(T == int))
            return config[key].integer.to!int;
        else static if (is(T == bool))
            return config[key].boolean;
        else static if (is(T == string))
            return config[key].str;
        else
            static assert(false, "Unsupported type for getConfigValue");
    }
    return defaultValue;
}
