----
-- Different mod utilities.
--
-- Includes different utilities used throughout the whole mod.
--
-- In order to become an utility the solution should either:
--
-- 1. Be a non-mod specific and isolated which can be reused in my other mods.
-- 2. Be a mod specific and isolated which can be used between classes/modules.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-keep-following](https://github.com/victorpopkov/dst-mod-keep-following)
--
-- @module Utils
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.21.0
----
local SDK = require "keepfollowing/sdk/sdk/sdk"

local Utils = {}

-- base (to store original functions after overrides)
local BaseGetModInfo

--- General
-- @section general

--- Checks if HUD has an input focus.
-- @tparam EntityScript inst Player instance
-- @treturn boolean
function Utils.IsHUDFocused(inst)
    return not SDK.Utils.Chain.Get(inst, "HUD", "HasInputFocus", true)
end

--- Locomotor
-- @section locomotor

--- Walks to a certain point.
--
-- Prepares a `WALKTO` action for `PlayerController.DoAction` when the locomotor component is
-- available. Otherwise sends the corresponding `RPC.LeftClick`.
--
-- @tparam EntityScript inst Player instance
-- @tparam Vector3 pt Destination point
function Utils.WalkToPoint(inst, pt)
    local player_controller = SDK.Utils.Chain.Get(inst, "components", "playercontroller")
    if not player_controller then
        --DebugError("Player controller is not available")
        return
    end

    if player_controller.locomotor then
        player_controller:DoAction(BufferedAction(inst, nil, ACTIONS.WALKTO, nil, pt))
    else
        SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, pt.x, pt.z)
    end
end

--- Modmain
-- @section modmain

--- Hide the modinfo changelog.
--
-- Overrides the global `KnownModIndex.GetModInfo` to hide the changelog if it's included in the
-- description.
--
-- @tparam string modname
-- @tparam boolean enable
-- @treturn boolean
function Utils.HideChangelog(modname, enable)
    if modname and enable and not BaseGetModInfo then
        BaseGetModInfo =  _G.KnownModIndex.GetModInfo
        _G.KnownModIndex.GetModInfo = function(_self, _modname)
            if _modname == modname
                and _self.savedata
                and _self.savedata.known_mods
                and _self.savedata.known_mods[modname]
            then
                local TrimString = _G.TrimString
                local modinfo = _self.savedata.known_mods[modname].modinfo
                if modinfo and type(modinfo.description) == "string" then
                    local changelog = modinfo.description:find("v" .. modinfo.version, 0, true)
                    if type(changelog) == "number" then
                        modinfo.description = TrimString(modinfo.description:sub(1, changelog - 1))
                    end
                end
            end
            return BaseGetModInfo(_self, _modname)
        end
        return true
    elseif BaseGetModInfo then
        _G.KnownModIndex.GetModInfo = BaseGetModInfo
        BaseGetModInfo = nil
    end
    return false
end

return Utils
