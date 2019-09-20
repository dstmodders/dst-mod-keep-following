name = "Keep Following"
version = "0.14.0"
description = [[Version: ]] .. version .. "\n\n" ..
    [[By default, Shift +  (LMB) on the player or supported entities to keep following. Shift + Ctrl +  (LMB) to keep pushing.]] .. "\n\n" ..
    [[You can also use the above key combinations on a Tent/Siesta Lean-to used by another player to keep following or pushing him.]] .. "\n\n" ..
    [[v0.14.0:]] .. "\n" ..
    [[- Added support for pushing players as a ghost]] .. "\n" ..
    [[- Fixed keeping the target distance behaviour]] .. "\n" ..
    [[- Improved compatibility with some other mods]] .. "\n" ..
    [[- Improved debug output]] .. "\n" ..
    [[- Removed pending tasks in favour of custom threads]]
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

local boolean = {
    { description = "Yes", data = true },
    { description = "No", data = false }
}

local target_distance = {
    { description = "1.5m", data = 1.5 },
    { description = "2.5m", data = 2.5 },
    { description = "3.5m", data = 3.5 }
}

local mobs = {
    { description = "Default", data = "default", hover = "Default: a hand-picked list based on prefabs that will suit most players" },
    { description = "All", data = "all", hover = "All: pretty much anything that moves can be followed and pushed" },
}

local string = ""
local keys = {
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
    "LAlt", "RAlt", "LCtrl", "RCtrl", "LShift", "RShift",
    "Tab", "Capslock", "Space", "Minus", "Equals", "Backspace",
    "Insert", "Home", "Delete", "End", "Pageup", "Pagedown", "Print", "Scrollock", "Pause",
    "Period", "Slash", "Semicolon", "Leftbracket", "Rightbracket", "Backslash",
    "Up", "Down", "Left", "Right"
}

local keylist = {}
for i = 1, #keys do
    keylist[i] = { description = keys[i], data = "KEY_" .. string.upper(keys[i]) }
end

local function AddConfig(label, name, options, default, hover)
    return { label = label, name = name, options = options, default = default, hover = hover or "" }
end

configuration_options = {
    AddConfig("Action key", "key_action", keylist, "KEY_LSHIFT", "Key used for both following and pushing"),
    AddConfig("Push key", "key_push", keylist, "KEY_LCTRL", "Key used for pushing in combination with action key.\nDisabled when \"Push with RMB\" is enabled"),
    AddConfig("Push with RMB", "push_with_rmb", boolean, false, "Use  (RMB) in combination with action key for pushing instead"),
    AddConfig("Push lag compensation", "push_lag_compensation", boolean, true, "Automatically disables lag compensation while pushing and restores the previous state after"),
    AddConfig("Target distance", "target_distance", target_distance, 2.5, "How close can you approach the leader?\nIgnored when pushing"),
    AddConfig("Keep target distance", "keep_target_distance", boolean, false, "Move away from a leader inside the target distance.\nIgnored when pushing"),
    AddConfig("Mobs", "mobs", mobs, "default", "Which mobs can be followed and pushed?"),
    AddConfig("Debug", "debug", boolean, false, "Enables/Disables the debug mode"),
}
