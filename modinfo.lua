name = "Keep Following"
version = "0.2.0"
description = [[Version: ]] .. version .. "\n\n" ..
    [[Shift +  (LMB) on the player, Chester/Hutch, Critter, Glommer or Pig to keep following. WASD to stop.]] .. "\n\n" ..
    [[v0.2.0:]] .. "\n" ..
    [[- Fixed delay after approaching a leader]] .. "\n" ..
    [[- Fixed delay before following a new leader]] .. "\n" ..
    [[- Removed leader reinitialization if a leader didn't change]]
author = "Demonblink"
api_version = 10
forumthread = ""
priority = -10

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

local function AddConfig(label, name, options, default, hover)
    return { label = label, name = name, options = options, default = default, hover = hover or "" }
end

configuration_options = {
    AddConfig("Debug", "debug", boolean, false, "Enables/Disables the debug mode"),
    AddConfig("Target Distance", "target_distance", target_distance, 2.5, "How close you can approach the target"),
}
