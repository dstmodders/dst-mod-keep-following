name = "Keep Following"
version = "0.20.0-beta"
description = [[Version: ]] .. version .. "\n\n" ..
    [[By default, Shift +  (LMB) on the player or supported entities to keep following. Shift + Ctrl +  (LMB) to keep pushing.]] .. "\n\n" ..
    [[You can also use the above key combinations on a Tent/Siesta Lean-to used by another player to keep following or pushing him.]] .. "\n\n" ..
    [[v]] .. version .. [[:]] .. "\n" ..
    [[- Added support for the hide changelog configuration]] .. "\n" ..
    [[- Added tests and documentation]] .. "\n" ..
    [[- Changed configuration to be divided into sections]] .. "\n" ..
    [[- Refactored most of the existing code]] .. "\n" ..
    [[- Removed mobs configuration in favour of the "all" behaviour]]
author = "Demonblink"
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

folder_name = folder_name or "dst-mod-keep-following"
if not folder_name:find("workshop-") then
    name = name .. " (dev)"
end

--
-- Helpers
--

local function AddConfig(label, name, options, default, hover)
    return { label = label, name = name, options = options, default = default, hover = hover or "" }
end

local function AddSection(title)
    return AddConfig(title, "", { { description = "", data = 0 } }, 0)
end

local function CreateKeyList()
    local keylist = {}
    local string = ""
    local keys = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
        "LAlt", "RAlt", "LCtrl", "RCtrl", "LShift", "RShift",
        "Tab", "Capslock", "Space", "Minus", "Equals", "Backspace",
        "Insert", "Home", "Delete", "End", "Pageup", "Pagedown", "Print", "Scrollock", "Pause",
        "Period", "Slash", "Semicolon", "Leftbracket", "Rightbracket", "Backslash",
        "Up", "Down", "Left", "Right",
    }

    keylist[1] = { description = "Disabled", data = false }
    for i = 1, #keys do
        keylist[i + 1] = { description = keys[i], data = "KEY_" .. string.upper(keys[i]) }
    end

    return keylist
end

--
-- Configuration
--

local key_list = CreateKeyList()

local boolean = {
    { description = "Yes", data = true },
    { description = "No", data = false }
}

local following_methods = {
    { description = "Default", data = "default", hover = "Default: player follows a leader step-by-step" },
    { description = "Closest", data = "closest", hover = "Closest: player goes to the closest target point from a leader" },
}

local target_distances = {
    { description = "1.5m", data = 1.5 },
    { description = "2.5m", data = 2.5 },
    { description = "3.5m", data = 3.5 }
}

local keep_target_distance = {
    { description = "Yes", data = true, hover = "Yes: move away from a leader within the target distance" },
    { description = "No", data = false, hover = "No: stay still within the target distance" },
}

local push_with_rmb = {
    { description = "Yes", data = true, hover = "Yes: the \"push key\" becomes disabled in favour of the RMB" },
    { description = "No", data = false, hover = "No: the \"push key\" is used for pushing" },
}

local push_mass_checking = {
    { description = "Yes", data = true, hover = "Yes: limits pushing to entities with an appropriate mass difference" },
    { description = "No", data = false, hover = "No: no limitations for the mass difference" },
}

configuration_options = {
    AddSection("Keybinds"),
    AddConfig("Action key", "key_action", key_list, "KEY_LSHIFT", "Key used for both following and pushing"),
    AddConfig("Push key", "key_push", key_list, "KEY_LCTRL", "Key used in combination with an action key for pushing"),

    AddSection("Following"),
    AddConfig("Following method", "following_method", following_methods, "default", "Which following method should be used?\nIgnored when pushing"),
    AddConfig("Target distance", "target_distance", target_distances, 2.5, "How close can you approach the leader?\nIgnored when pushing"),
    AddConfig("Keep target distance", "keep_target_distance", keep_target_distance, false, "Should the follower keep the distance from the leader?\nIgnored when pushing"),

    AddSection("Pushing"),
    AddConfig("Push with RMB", "push_with_rmb", push_with_rmb, false, "Should the  (RMB) in combination with an action key be used for pushing?"),
    AddConfig("Push mass checking", "push_mass_checking", push_mass_checking, true, "Should the mass difference checking be enabled?\nIgnored for pushing players as a ghost"),
    AddConfig("Push lag compensation", "push_lag_compensation", boolean, true, "Should the lag compensation be automatically disabled while pushing?"),

    AddSection("Other"),
    AddConfig("Hide changelog", "hide_changelog", boolean, true, "Should the changelog in the mod description be hidden?\nMods should be reloaded to take effect"),
    AddConfig("Debug", "debug", boolean, false, "Should the debug mode be enabled?"),
}
