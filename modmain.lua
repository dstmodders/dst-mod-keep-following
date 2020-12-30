----
-- Modmain.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-keep-following](https://github.com/victorpopkov/dst-mod-keep-following)
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.21.0
----
local _G = GLOBAL
local require = _G.require

_G.MOD_KEEP_FOLLOWING_TEST = false

--- Globals
-- @section globals

local ACTIONS = _G.ACTIONS
local BufferedAction = _G.BufferedAction
local CONTROL_ACTION = _G.CONTROL_ACTION
local CONTROL_PRIMARY = _G.CONTROL_PRIMARY
local CONTROL_SECONDARY = _G.CONTROL_SECONDARY
local TheInput = _G.TheInput

--- SDK
-- @section sdk

local SDK

SDK = require "keepfollowing/sdk/sdk/sdk"
SDK.Load(env, "keepfollowing/sdk", {
    "Config",
    "Debug",
    "DebugUpvalue",
    "Entity",
    "Input",
    "ModMain",
    "Player",
    "RPC",
    "Thread",
    "World",
})

--- Debugging
-- @section debugging

SDK.Debug.SetIsEnabled(GetModConfigData("debug") and true or false)
SDK.Debug.ModConfigs()

--- Actions
-- @section actions

local _PUSH_WITH_RMB = GetModConfigData("push_with_rmb")

AddAction("MOD_KEEP_FOLLOWING_FOLLOW", "Follow", function(act)
    local keepfollowing = SDK.Utils.Chain.Get(act, "doer", "components", "keepfollowing")
    if keepfollowing and act.doer and act.target then
        keepfollowing:Stop()
        keepfollowing:StartFollowing(act.target)
        return true
    end
    return false
end)

AddAction("MOD_KEEP_FOLLOWING_PUSH", "Push", function(act)
    local keepfollowing = SDK.Utils.Chain.Get(act, "doer", "components", "keepfollowing")
    if keepfollowing and act.doer and act.target then
        keepfollowing:Stop()
        keepfollowing:StartPushing(act.target)
        return true
    end
    return false
end)

AddAction("MOD_KEEP_FOLLOWING_TENT_FOLLOW", "Follow player in", function(act)
    local keepfollowing = SDK.Utils.Chain.Get(act, "doer", "components", "keepfollowing")
    if keepfollowing and act.doer and act.target then
        local leader = SDK.Entity.GetTentSleeper(act.target)
        if leader then
            keepfollowing:Stop()
            keepfollowing:StartFollowing(leader)
            return true
        end
    end
    return false
end)

AddAction(
    "MOD_KEEP_FOLLOWING_TENT_PUSH",
    _PUSH_WITH_RMB and "Push player" or "Push player in",
    function(act)
        local keepfollowing = SDK.Utils.Chain.Get(act, "doer", "components", "keepfollowing")
        if keepfollowing and act.doer and act.target then
            local leader = SDK.Entity.GetTentSleeper(act.target)
            if leader then
                keepfollowing:Stop()
                keepfollowing:StartPushing(leader)
                return true
            end
        end
        return false
    end
)

--- Player
-- @section player

SDK.OnPlayerActivated(function(world, player)
    player:AddComponent("keepfollowing")
    local keepfollowing = player.components.keepfollowing
    if keepfollowing then
        keepfollowing.is_master_sim = world.ismastersim
        keepfollowing.world = world

        -- GetModConfigData
        local configs = {
            "follow_distance",
            "follow_distance_keeping",
            "follow_method",
            "push_lag_compensation",
            "push_mass_checking",
        }

        for _, config in ipairs(configs) do
            keepfollowing.config[config] = GetModConfigData(config)
        end
    end
end)

SDK.OnPlayerDeactivated(function(_, player)
    player:RemoveComponent("keepfollowing")
end)

--- Components
-- @section components

local function IsOurAction(action)
    return action == ACTIONS.MOD_KEEP_FOLLOWING_FOLLOW
        or action == ACTIONS.MOD_KEEP_FOLLOWING_PUSH
        or action == ACTIONS.MOD_KEEP_FOLLOWING_TENT_FOLLOW
        or action == ACTIONS.MOD_KEEP_FOLLOWING_TENT_PUSH
end

SDK.OnLoadComponent("playeractionpicker", function(_self, player)
    if player ~= _G.ThePlayer then
        return
    end

    local _KEY_ACTION = SDK.Config.GetModKeyConfigData("key_action")
    local _KEY_PUSH = SDK.Config.GetModKeyConfigData("key_push")

    --
    -- Overrides
    --

    SDK.OverrideMethod(_self, "DoGetMouseActions", function(original_fn, self, position, _target)
        local lmb, rmb = original_fn(self, position, _target)
        if TheInput:IsKeyDown(_KEY_ACTION) then
            local keepfollowing = player.components.keepfollowing
            local buffered = self.inst:GetBufferedAction()

            -- We could have used lmb.target. However, the PlayerActionPicker has
            -- leftclickoverride and rightclickoverride so we can't trust that. A good example
            -- is Woodie's Weregoose form which overrides mouse actions.
            local target = TheInput:GetWorldEntityUnderMouse()
            if not target then
                return lmb, rmb
            end

            -- You are probably wondering why we need this check? Isn't it better to just show
            -- our actions without the buffered action check?
            --
            -- There are so many mods out there "in the wild" which also do different in-game
            -- actions and don't bother checking for interruptions in their scheduler tasks
            -- (threads). For example, ActionQueue Reborn will always try to force their action
            -- if entities have already been selected. We can adapt our mod for such cases to
            -- improve compatibility but this is the only bulletproof way to cover the most.
            if buffered
                and not IsOurAction(buffered.action)
                and buffered.action ~= ACTIONS.WALKTO
            then
                return lmb, rmb
            end

            if target:HasTag("tent") and target:HasTag("hassleeper") then
                if _PUSH_WITH_RMB then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_TENT_FOLLOW)
                elseif TheInput:IsKeyDown(_KEY_PUSH) then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_TENT_PUSH)
                elseif not TheInput:IsKeyDown(_KEY_PUSH) then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_TENT_FOLLOW)
                end
            end

            if keepfollowing:CanBeLeader(target) then
                if _PUSH_WITH_RMB then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_FOLLOW)
                elseif TheInput:IsKeyDown(_KEY_PUSH) and keepfollowing:CanBePushed(target) then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_PUSH)
                elseif not TheInput:IsKeyDown(_KEY_PUSH) then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_FOLLOW)
                end
            end

            if _PUSH_WITH_RMB then
                if target:HasTag("tent") and target:HasTag("hassleeper") then
                    rmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_TENT_PUSH)
                end

                if keepfollowing:CanBeLeader(target) and keepfollowing:CanBePushed(target) then
                    rmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_PUSH)
                end
            end
        end
        return lmb, rmb
    end, SDK.OVERRIDE.ORIGINAL_NONE)
end)

SDK.OnLoadComponent("playercontroller", function(_self, player)
    if player ~= _G.ThePlayer then
        return
    end

    local _COMPATIBILITY = GetModConfigData("compatibility")

    --
    -- Helpers
    --

    local function KeepFollowingStop()
        local keepfollowing = player.components.keepfollowing
        if keepfollowing then
            keepfollowing:Stop()
        end
    end

    -- We ignore ActionQueue(DST) mod here intentionally. Our mod won't work with theirs if the same
    -- action key is used. So there is no point to mess with their functions anyway.
    --
    -- From an engineering perspective, the method which ActionQueue(DST) mod uses for overriding
    -- PlayerController:OnControl() should never be used. Technically, we can fix this issue by
    -- either using the same approach or using the global input handler when ActionQueue(DST) mod is
    -- enabled. However, I don't see any valid reason to do that.
    local function ClearActionQueueRebornEntities()
        local actionqueuer = player.components.actionqueuer
        if not actionqueuer
            or not actionqueuer.ClearActionThread
            or not actionqueuer.ClearSelectionThread
            or not actionqueuer.ClearSelectedEntities
        then
            return
        end

        actionqueuer:ClearActionThread()
        actionqueuer:ClearSelectionThread()
        actionqueuer:ClearSelectedEntities()
    end

    local function OurMouseAction(act)
        if not act then
            KeepFollowingStop()
            return false
        end

        local action = act.action
        if IsOurAction(action) then
            ClearActionQueueRebornEntities()
            if action.fn(act) then
                return true
            end
        else
            KeepFollowingStop()
        end

        return false
    end

    --
    -- Overrides
    --

    SDK.OverrideMethod(_self, "OnControl", function(original_fn, self, control, down)
        if SDK.Input.IsControlMove(control) or control == CONTROL_ACTION then
            KeepFollowingStop()
        end

        if _COMPATIBILITY == "alternative" then
            if control == CONTROL_PRIMARY and not down then
                if TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() then
                    return original_fn(self, control, down)
                end
                OurMouseAction(self:GetLeftMouseAction())
            elseif _PUSH_WITH_RMB and control == CONTROL_SECONDARY and not down then
                if TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() then
                    return original_fn(self, control, down)
                end
                OurMouseAction(self:GetRightMouseAction())
            end
        end

        original_fn(self, control, down)
    end, SDK.OVERRIDE.ORIGINAL_NONE)

    if _COMPATIBILITY == "recommended" then
        SDK.OverrideMethod(_self, "OnLeftClick", function(original_fn, self, down)
            if not down
                and not self:IsAOETargeting()
                and not TheInput:GetHUDEntityUnderMouse()
                and OurMouseAction(self:GetLeftMouseAction())
            then
                return
            end
            original_fn(self, down)
        end, SDK.OVERRIDE.ORIGINAL_NONE)

        if _PUSH_WITH_RMB then
            SDK.OverrideMethod(_self, "OldOnRightClick", function(original_fn, self, down)
                if not down
                    and not self:IsAOETargeting()
                    and not TheInput:GetHUDEntityUnderMouse()
                    and OurMouseAction(self:GetRightMouseAction())
                then
                    return
                end
                original_fn(self, down)
            end, SDK.OVERRIDE.ORIGINAL_NONE)
        end
    end
end)

--- KnownModIndex
-- @section knownmodindex

if GetModConfigData("hide_changelog") then
    SDK.ModMain.HideChangelog(true)
end
