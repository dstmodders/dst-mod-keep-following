name = "Keep Following"
version = "0.21.0"
description = [[Version: ]]
    .. version
    .. "\n\n"
    .. [[By default, Shift +  (LMB) on the player or supported entities to keep following. Shift ]]
    .. [[+ Ctrl +  (LMB) to keep pushing.]]
    .. "\n\n"
    .. [[You can also use the above key combinations on a Tent/Siesta Lean-to used by another ]]
    .. [[player to keep following or pushing him.]]
author = "Depressed DST Modders"
api_version = 10
forumthread = ""

-- Advanced Controls is using the default 0 priority. We need to load our mod after theirs, so its
-- "Attack actions only key" wouldn't interfere with us. The "1835465557" part is the workshop ID of
-- this mod so other mods had enough "space for manoeuvre" in loading priority.
priority = -0.011835465557

icon = "modicon.tex"
icon_atlas = "modicon.xml"

all_clients_require_mod = false
client_only_mod = true
dont_starve_compatible = false
dst_compatible = true
reign_of_giants_compatible = false
shipwrecked_compatible = false

folder_name = folder_name or "mod-keep-following"
if not folder_name:find("workshop-") then
    name = name .. " (dev)"
end

--
-- Configuration
--

local function AddConfig(name, label, hover, options, default)
    return { label = label, name = name, options = options, default = default, hover = hover or "" }
end

local function AddBooleanConfig(name, label, hover, default)
    default = default == nil and true or default
    return AddConfig(name, label, hover, {
        { description = "Disabled", data = false },
        { description = "Enabled", data = true },
    }, default)
end

local function AddKeyListConfig(name, label, hover, default)
    if default == nil then
        default = false
    end

    -- helpers
    local function AddDisabled(t)
        t[#t + 1] = { description = "Disabled", data = false }
    end

    local function AddKey(t, key)
        t[#t + 1] = { description = key, data = "KEY_" .. key:gsub(" ", ""):upper() }
    end

    local function AddKeysByName(t, names)
        for i = 1, #names do
            AddKey(t, names[i])
        end
    end

    local function AddAlphabetKeys(t)
        local string = ""
        for i = 1, 26 do
            AddKey(t, string.char(64 + i))
        end
    end

    local function AddTypewriterNumberKeys(t)
        for i = 1, 10 do
            AddKey(t, "" .. (i % 10))
        end
    end

    local function AddTypewriterModifierKeys(t)
        AddKeysByName(t, { "Alt", "Ctrl", "Shift" })
    end

    local function AddTypewriterKeys(t)
        AddAlphabetKeys(t)
        AddKeysByName(t, {
            "Slash",
            "Backslash",
            "Period",
            "Semicolon",
            "Left Bracket",
            "Right Bracket",
        })
        AddKeysByName(t, { "Space", "Tab", "Backspace", "Enter" })
        AddTypewriterModifierKeys(t)
        AddKeysByName(t, { "Tilde" })
        AddTypewriterNumberKeys(t)
        AddKeysByName(t, { "Minus", "Equals" })
    end

    local function AddFunctionKeys(t)
        for i = 1, 12 do
            AddKey(t, "F" .. i)
        end
    end

    local function AddArrowKeys(t)
        AddKeysByName(t, { "Up", "Down", "Left", "Right" })
    end

    local function AddNavigationKeys(t)
        AddKeysByName(t, { "Insert", "Delete", "Home", "End", "Page Up", "Page Down" })
    end

    -- key list
    local list = {}

    AddDisabled(list)
    AddArrowKeys(list)
    AddFunctionKeys(list)
    AddTypewriterKeys(list)
    AddNavigationKeys(list)
    AddKeysByName(list, { "Escape", "Pause", "Print" })

    return AddConfig(name, label, hover, list, default)
end

local function AddSection(title)
    return AddConfig("", title, nil, { { description = "", data = 0 } }, 0)
end

configuration_options = {
    --
    -- Keybinds
    --

    AddSection("Keybinds"),

    AddKeyListConfig(
        "key_action",
        "Action Key",
        "Key used for both following and pushing",
        "KEY_SHIFT"
    ),

    AddKeyListConfig(
        "key_push",
        "Push Key",
        "Key used in combination with an action key for pushing",
        "KEY_CTRL"
    ),

    --
    -- General
    --

    AddSection("General"),

    AddConfig(
        "compatibility",
        "Compatibility",
        "Which compatibility mode should be used?\nMay fix some issues with other mods",
        {
            {
                description = "Recommended",
                hover = "Recommended: overrides both on control and on left/right clicks",
                data = "recommended",
            },
            {
                description = "Alternative",
                hover = "Alternative: overrides only on control",
                data = "alternative",
            },
        },
        "recommended"
    ),

    AddConfig(
        "target_entities",
        "Target Entities",
        "Which target entities should be used for following and pushing?",
        {
            {
                description = "Default",
                hover = "Default: target most entities with the ability to move",
                data = "default",
            },
            {
                description = "Friendly",
                hover = "Friendly: target only non-hostile entities with the ability to move",
                data = "friendly",
            },
            {
                description = "Players",
                hover = "Players: target only players",
                data = "players",
            },
        },
        "default"
    ),

    --
    -- Following
    --

    AddSection("Following"),

    AddConfig("follow_method", "Follow Method", "Which follow method should be used?", {
        {
            description = "Default",
            hover = "Default: you follow the target step-by-step",
            data = "default",
        },
        {
            description = "Closest",
            hover = "Closest: you go to the closest point to the target",
            data = "closest",
        },
    }, "default"),

    AddConfig("follow_distance", "Follow Distance", "How close can you approach the target?", {
        { description = "1.5m", data = 1.5 },
        { description = "2.5m", data = 2.5 },
        { description = "3.5m", data = 3.5 },
    }, 2.5),

    AddBooleanConfig(
        "follow_distance_keeping",
        "Follow Distance Keeping",
        "When enabled, you move away from the target within the follow distance",
        false
    ),

    --
    -- Pushing
    --

    AddSection("Pushing"),

    AddBooleanConfig(
        "push_with_rmb",
        "Push With RMB",
        "When enabled, \238\132\129 (RMB) + action key is used for pushing",
        false
    ),

    AddBooleanConfig(
        "push_mass_checking",
        "Push Mass Checking",
        [[When enabled, disables pushing entities with very high mass.]]
            .. "\n"
            .. [[Ignored when pushing players as a ghost]]
    ),

    AddBooleanConfig(
        "push_lag_compensation",
        "Push Lag Compensation",
        [[When enabled, automatically disables the lag compensation during pushing]]
    ),

    --
    -- Other
    --

    AddSection("Other"),

    AddBooleanConfig(
        "debug",
        "Debug",
        "When enabled, displays debug data in the console.\nUsed mainly for development",
        false
    ),
}
