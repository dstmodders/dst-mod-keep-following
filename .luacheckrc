exclude_files = {
    "scripts/keepfollowing/sdk/",
    "workshop/",
}

std = {
    max_code_line_length = 100,
    max_comment_line_length = 150,
    max_line_length = 100,
    max_string_line_length = 100,

    -- std.read_globals should include only the "native" Lua-related stuff
    read_globals = {
        "arg",
        "assert",
        "Class",
        "debug",
        "env",
        "getmetatable",
        "ipairs",
        "json",
        "math",
        "next",
        "os",
        "pairs",
        "print",
        "rawset",
        "require",
        "string",
        "table",
        "tonumber",
        "tostring",
        "type",
        "unpack",
    },
}

files["modinfo.lua"] = {
    globals = {
        "all_clients_require_mod",
        "api_version",
        "author",
        "client_only_mod",
        "configuration_options",
        "description",
        "dont_starve_compatible",
        "dst_compatible",
        "folder_name",
        "forumthread",
        "icon",
        "icon_atlas",
        "name",
        "priority",
        "reign_of_giants_compatible",
        "shipwrecked_compatible",
        "version",
    },
}

files["**/*.lua"] = {
    max_comment_line_length = 250,

    -- globals
    globals = {
        "_G",
        "GLOBAL",
        "package",
    },
    read_globals = {
        "_G",
        "ACTIONS",
        "AddAction",
        "AssertChainNil",
        "AssertClassGetter",
        "AssertDebugSpyWasCalled",
        "BufferedAction",
        "COLLISION",
        "DebugSpyClear",
        "DebugSpyInit",
        "DebugSpyTerm",
        "Empty",
        "FRAMES",
        "GetModConfigData",
        "package",
        "ReturnValueFn",
        "ReturnValuesFn",
        "RPC",
        "SendRPCToServer",
        "Sleep",
        "ThePlayer",
        "Vector3",
    },
}
