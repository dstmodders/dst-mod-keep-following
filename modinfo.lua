name = "Keep Following"
version = "0.19.0"
description = [[Version: ]] .. version .. "\n\n" ..
    [[By default, Shift +  (LMB) on the player or supported entities to keep following. Shift + Ctrl +  (LMB) to keep pushing.]] .. "\n\n" ..
    [[You can also use the above key combinations on a Tent/Siesta Lean-to used by another player to keep following or pushing him.]] .. "\n\n" ..
    [[v0.19.0:]] .. "\n" ..
    [[- Changed mod icon]] .. "\n" ..
    [[- Fixed PlayerActionPicker:DoGetMouseActions() override]] .. "\n" ..
    [[- Improved compatibility with some other mods]] .. "\n" ..
    [[- Improved debug output]] .. "\n" ..
    [[- Removed pushing support for birds]]
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

local push_mass_checking = {
    { description = "Yes", data = true, hover = "Yes: only entities with an appropriate mass difference can be pushed" },
    { description = "No", data = false, hover = "No: no mass difference limitations" },
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

local mobs = {
    { description = "Default", data = "default", hover = "Default: a hand-picked list based on prefabs that will suit most players" },
    { description = "All", data = "all", hover = "All: pretty much anything that moves can be followed and pushed" },
}

configuration_options = {
    AddConfig("Action key", "key_action", key_list, "KEY_LSHIFT", "Key used for both following and pushing"),
    AddConfig("Push key", "key_push", key_list, "KEY_LCTRL", "Key used for pushing in combination with action key.\nDisabled when \"Push with RMB\" is enabled"),
    AddConfig("Push with RMB", "push_with_rmb", boolean, false, "Use  (RMB) in combination with action key for pushing instead"),
    AddConfig("Push mass checking", "push_mass_checking", push_mass_checking, true, "Enables/Disables the mass difference checking.\nIgnored for the ghosts pushing players"),
    AddConfig("Push lag compensation", "push_lag_compensation", boolean, true, "Automatically disables lag compensation while pushing and restores the previous state after"),
    AddConfig("Following method", "following_method", following_methods, "default", "Which following method should be used?\nIgnored when pushing"),
    AddConfig("Target distance", "target_distance", target_distances, 2.5, "How close can you approach the leader?\nIgnored when pushing"),
    AddConfig("Keep target distance", "keep_target_distance", boolean, false, "Move away from a leader inside the target distance.\nIgnored when pushing"),
    AddConfig("Mobs", "mobs", mobs, "default", "Which mobs can be followed and pushed?"),
    AddConfig("Debug", "debug", boolean, false, "Enables/Disables the debug mode"),
}
