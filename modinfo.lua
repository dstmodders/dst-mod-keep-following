name = "Keep Following"
version = "0.6.0"
description = [[Version: ]] .. version .. "\n\n" ..
    [[By default, RShift +  (LMB) on the player, Bunnyman/Pig, Chester/Hutch, Critter or Glommer to keep following. ]] ..
    [[RShift + RCtrl +  (LMB) to keep pushing. WASD to stop.]] .. "\n\n" ..
    [[You can also use the above key combinations on a Tent/Siesta Lean-to used by another player to keep following or pushing him.]] .. "\n\n" ..
    [[v0.6.0:]] .. "\n" ..
    [[- Added support for Bunnymen]] .. "\n" ..
    [[- Added support for keeping the target distance configuration]] .. "\n" ..
    [[- Changed the default action and push keys back to original]] .. "\n" ..
    [[- Improved compatibility with some other mods]]
author = "Demonblink"
api_version = 10
forumthread = ""

--Advanced Controls is using the default 0 priority. We need to load our mod before them, so its
--"Attack actions only key" wouldn't interfere with us. The "1835465557" part is the workshop ID of
--this mod so other mods had enough "space for manoeuvre" in loading priority
priority = -0.011835465557

icon = "modicon.tex"
icon_atlas = "modicon.xml"

all_clients_require_mod = false
client_only_mod = true
dont_starve_compatible = false
dst_compatible = true
reign_of_giants_compatible = false
shipwrecked_compatible = false

local boolean = {
    { description = "Yes", data = true },
    { description = "No", data = false }
}

local target_distance = {
    { description = "1.5m", data = 1.5 },
    { description = "2.5m", data = 2.5 },
    { description = "3.5m", data = 3.5 }
}

local string = ""
local keys = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12", "LAlt", "RAlt", "LCtrl", "RCtrl", "LShift", "RShift", "Tab", "Capslock", "Space", "Minus", "Equals", "Backspace", "Insert", "Home", "Delete", "End", "Pageup", "Pagedown", "Print", "Scrollock", "Pause", "Period", "Slash", "Semicolon", "Leftbracket", "Rightbracket", "Backslash", "Up", "Down", "Left", "Right" }
local keylist = {}
for i = 1, #keys do
    keylist[i] = { description = keys[i], data = "KEY_" .. string.upper(keys[i]) }
end

local function AddConfig(label, name, options, default, hover)
    return { label = label, name = name, options = options, default = default, hover = hover or "" }
end

configuration_options = {
    AddConfig("Action key", "key_action", keylist, "KEY_LSHIFT", "Key used for both following and pushing"),
    AddConfig("Push key", "key_push", keylist, "KEY_LCTRL", "Key used for pushing in combination with action key"),
    AddConfig("Target Distance", "target_distance", target_distance, 2.5, "How close can you approach the leader? Ignored when pushing"),
    AddConfig("Keep target distance", "keep_target_distance", boolean, false, "Move away from leader inside the target distance. Ignored when pushing"),
    AddConfig("Debug", "debug", boolean, false, "Enables/Disables the debug mode"),
}
