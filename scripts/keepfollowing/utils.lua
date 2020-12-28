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

return Utils
