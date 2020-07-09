std = {
    max_code_line_length = 100,
    max_comment_line_length = 150,
    max_line_length = 100,
    max_string_line_length = 100,

    -- std.read_globals should include only the "native" Lua-related stuff
    read_globals = {
        "Class",
        "arg",
        "assert",
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
    max_code_line_length = 250,
    max_comment_line_length = 100,
    max_line_length = 100,
    max_string_line_length = 250,

    -- globals
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

files["modmain.lua"] = {
    max_code_line_length = 100,
    max_comment_line_length = 250,
    max_line_length = 100,
    max_string_line_length = 100,

    -- globals
    globals = {
        "GLOBAL",
    },
    read_globals = {
        "AddAction",
        "AddComponentPostInit",
        "GetModConfigData",
        "modname",
    },
}

files["scripts/**/*.lua"] = {
    max_code_line_length = 100,
    max_comment_line_length = 250,
    max_line_length = 100,
    max_string_line_length = 100,

    -- globals
    globals = {
        -- general
        "Networking_Say",
        "SendRPCToServer",
        "TheWorld",

        -- project
        "Debug",
    },
    read_globals = {
        -- general
        "AllPlayers",
        "BufferedAction",
        "KnownModIndex",
        "_G",

        -- constants
        "ACTIONS",
        "COLLISION",
        "FRAMES",
        "RPC",

        -- threads
        "KillThreadsWithID",
        "scheduler",
        "Sleep",
        "StartThread",
    },
}

files["spec/**/*.lua"] = {
  max_code_line_length = 100,
  max_comment_line_length = 250,
  max_line_length = 100,
  max_string_line_length = 100,

  -- globals
  globals = {
    -- general
    "Class",
    "ClassRegistry",
    "_G",
    "package",

    -- project
    "AssertChainNil",
    "DebugSpyClear",
    "DebugSpyInit",
    "DebugSpyTerm",
    "Empty",
    "ReturnValueFn",
    "ReturnValues",
    "ReturnValuesFn",
  },
  read_globals = {
    -- general
    "rawget",
    "setmetatable",

    -- project

  },
}
