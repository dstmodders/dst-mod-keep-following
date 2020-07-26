----
-- Modmain.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-keep-following](https://github.com/victorpopkov/dst-mod-keep-following)
--
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.20.0-beta
----
local _G = GLOBAL
local require = _G.require

--
-- Globals
--

local ACTIONS = _G.ACTIONS
local BufferedAction = _G.BufferedAction
local CONTROL_ACTION = _G.CONTROL_ACTION
local CONTROL_MOVE_DOWN = _G.CONTROL_MOVE_DOWN
local CONTROL_MOVE_LEFT = _G.CONTROL_MOVE_LEFT
local CONTROL_MOVE_RIGHT = _G.CONTROL_MOVE_RIGHT
local CONTROL_MOVE_UP = _G.CONTROL_MOVE_UP
local CONTROL_PRIMARY = _G.CONTROL_PRIMARY
local CONTROL_SECONDARY = _G.CONTROL_SECONDARY
local TheInput = _G.TheInput
local TheSim = _G.TheSim

--
-- Debugging
--

local Debug

if GetModConfigData("debug") then
    Debug = require "keepfollowing/debug"
    Debug:DoInit(modname)
    Debug:SetIsEnabled(GetModConfigData("debug") and true or false)
    Debug:DebugModConfigs()
    _G.KeepFollowingDebug = Debug
end

local function DebugString(...)
    return Debug and Debug:DebugString(...)
end

local function DebugInit(...)
    return Debug and Debug:DebugInit(...)
end

--
-- Helpers
--

local function GetKeyFromConfig(config)
    local key = GetModConfigData(config)
    return key and (type(key) == "number" and key or _G[key]) or -1
end

local function IsDST()
    return TheSim:GetGameID() == "DST"
end

local function IsClient()
    return IsDST() and _G.TheNet:GetIsClient()
end

local function IsMoveButton(control)
    return control == CONTROL_MOVE_UP
        or control == CONTROL_MOVE_DOWN
        or control == CONTROL_MOVE_LEFT
        or control == CONTROL_MOVE_RIGHT
end

local function IsOurAction(action)
    return action == ACTIONS.FOLLOW
        or action == ACTIONS.PUSH
        or action == ACTIONS.TENT_FOLLOW
        or action == ACTIONS.TENT_PUSH
end

--
-- Configurations
--

local _KEY_ACTION = GetKeyFromConfig("key_action")
local _KEY_PUSH = GetKeyFromConfig("key_push")
local _PUSH_WITH_RMB = GetModConfigData("push_with_rmb")

--
-- Actions
--

local function ActionFollow(act)
    if not act.doer or not act.target or not act.doer.components.keepfollowing then
        return false
    end

    local keepfollowing = act.doer.components.keepfollowing
    keepfollowing:Stop()
    keepfollowing:StartFollowing(act.target)

    return true
end

local function ActionPush(act)
    if not act.doer or not act.target or not act.doer.components.keepfollowing then
        return false
    end

    local keepfollowing = act.doer.components.keepfollowing
    keepfollowing:Stop()
    keepfollowing:StartPushing(act.target)

    return true
end

local function ActionTentFollow(act)
    if not act.doer or not act.target or not act.doer.components.keepfollowing then
        return false
    end

    local keepfollowing = act.doer.components.keepfollowing
    local leader = keepfollowing:GetTentSleeper(act.target)

    if leader then
        keepfollowing:Stop()
        keepfollowing:StartFollowing(leader)
    end

    return true
end

local function ActionTentPush(act)
    if not act.doer or not act.target or not act.doer.components.keepfollowing then
        return false
    end

    local keepfollowing = act.doer.components.keepfollowing
    local leader = keepfollowing:GetTentSleeper(act.target)

    if leader then
        keepfollowing:Stop()
        keepfollowing:StartPushing(leader)
    end

    return true
end

AddAction("FOLLOW", "Follow", ActionFollow)
AddAction("PUSH", "Push", ActionPush)
AddAction("TENT_FOLLOW", "Follow player in", ActionTentFollow)
AddAction("TENT_PUSH", _PUSH_WITH_RMB and "Push player" or "Push player in", ActionTentPush)

--
-- Player
--

local function OnPlayerActivated(player, world)
    player:AddComponent("keepfollowing")

    local keepfollowing = player.components.keepfollowing

    if keepfollowing then
        keepfollowing.is_client = IsClient()
        keepfollowing.is_dst = IsDST()
        keepfollowing.is_master_sim = world.ismastersim
        keepfollowing.world = world

        -- GetModConfigData
        local configs = {
            "following_method",
            "keep_target_distance",
            "push_lag_compensation",
            "push_mass_checking",
            "target_distance",
        }

        for _, config in ipairs(configs) do
            keepfollowing.config[config] = GetModConfigData(config)
        end
    end

    DebugString("Player", player:GetDisplayName(), "activated")
end

local function OnPlayerDeactivated(player)
    player:RemoveComponent("keepfollowing")
    DebugString("Player", player:GetDisplayName(), "deactivated")
end

local function AddPlayerPostInit(onActivatedFn, onDeactivatedFn)
    DebugString("Game ID -", TheSim:GetGameID())

    if IsDST() then
        env.AddPrefabPostInit("world", function(_world)
            _world:ListenForEvent("playeractivated", function(world, player)
                if player == _G.ThePlayer then
                    onActivatedFn(player, world)
                end
            end)

            _world:ListenForEvent("playerdeactivated", function(_, player)
                if player == _G.ThePlayer then
                    onDeactivatedFn(player)
                end
            end)
        end)
    else
        env.AddPlayerPostInit(function(player)
            onActivatedFn(player)
        end)
    end

    DebugInit("AddPlayerPostInit")
end

local function PlayerActionPickerPostInit(_self, player)
    if player ~= _G.ThePlayer then
        return
    end

    local OldDoGetMouseActions = _self.DoGetMouseActions

    local function NewDoGetMouseActions(self, position, _target)
        local lmb, rmb = OldDoGetMouseActions(self, position, _target)

        if TheInput:IsKeyDown(_KEY_ACTION) then
            local keepfollowing = player.components.keepfollowing
            local buffered = self.inst:GetBufferedAction()

            -- We could have used lmb.target. However, the PlayerActionPicker has leftclickoverride
            -- and rightclickoverride so we can't trust that. A good example is Woodie's Weregoose
            -- form which overrides mouse actions.
            local target = TheInput:GetWorldEntityUnderMouse()
            if not target then
                return lmb, rmb
            end

            -- You are probably wondering why we need this check? Isn't it better to just show our
            -- actions without the buffered action check?
            --
            -- There are so many mods out there "in the wild" which also do different in-game
            -- actions and don't bother checking for interruptions in their scheduler tasks
            -- (threads). For example, ActionQueue Reborn will always try to force their action if
            -- entities have already been selected. We can adapt our mod for such cases to improve
            -- compatibility but this is the only bulletproof way to cover the most.
            if buffered
                and not IsOurAction(buffered.action)
                and buffered.action ~= ACTIONS.WALKTO
            then
                return lmb, rmb
            end

            if target:HasTag("tent") and target:HasTag("hassleeper") then
                if _PUSH_WITH_RMB then
                    lmb = BufferedAction(player, target, ACTIONS.TENT_FOLLOW)
                elseif TheInput:IsKeyDown(_KEY_PUSH) then
                    lmb = BufferedAction(player, target, ACTIONS.TENT_PUSH)
                elseif not TheInput:IsKeyDown(_KEY_PUSH) then
                    lmb = BufferedAction(player, target, ACTIONS.TENT_FOLLOW)
                end
            end

            if keepfollowing:CanBeLeader(target) then
                if _PUSH_WITH_RMB then
                    lmb = BufferedAction(player, target, ACTIONS.FOLLOW)
                elseif TheInput:IsKeyDown(_KEY_PUSH) and keepfollowing:CanBePushed(target) then
                    lmb = BufferedAction(player, target, ACTIONS.PUSH)
                elseif not TheInput:IsKeyDown(_KEY_PUSH) then
                    lmb = BufferedAction(player, target, ACTIONS.FOLLOW)
                end
            end

            if _PUSH_WITH_RMB then
                if target:HasTag("tent") and target:HasTag("hassleeper") then
                    rmb = BufferedAction(player, target, ACTIONS.TENT_PUSH)
                end

                if keepfollowing:CanBeLeader(target) and keepfollowing:CanBePushed(target) then
                    rmb = BufferedAction(player, target, ACTIONS.PUSH)
                end
            end
        end

        return lmb, rmb
    end

    _self.DoGetMouseActions = NewDoGetMouseActions

    DebugInit("PlayerActionPickerPostInit")
end

local function PlayerControllerPostInit(_self, _player)
    if _player ~= _G.ThePlayer then
        return
    end

    local function KeepFollowingStop()
        local keepfollowing = _player.components.keepfollowing
        if not keepfollowing then
            return
        end

        keepfollowing:Stop()
    end

    -- We ignore ActionQueue(DST) mod here intentionally. Our mod won't work with theirs if the same
    -- action key is used. So there is no point to mess with their functions anyway.
    --
    -- From an engineering perspective, the method which ActionQueue(DST) mod uses for overriding
    -- PlayerController:OnControl() should never be used. Technically, we can fix this issue by
    -- either using the same approach or using the global input handler when ActionQueue(DST) mod is
    -- enabled. However, I don't see any valid reason to do that.
    local function ClearActionQueueRebornEntities()
        local actionqueuer = _player.components.actionqueuer
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

    local function OurMouseAction(player, act)
        if not act then
            KeepFollowingStop()
            return
        end

        local keepfollowing = player.components.keepfollowing
        local action = act.action

        if keepfollowing then
            keepfollowing.player_controller = _self
        end

        if IsOurAction(action) then
            ClearActionQueueRebornEntities()
            return action.fn(act)
        else
            KeepFollowingStop()
        end
    end

    local OldOnControl = _self.OnControl

    local function NewOnControl(self, control, down)
        if IsMoveButton(control) or control == CONTROL_ACTION then
            KeepFollowingStop()
        end

        if control == CONTROL_PRIMARY and not down then
            if TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() then
                return OldOnControl(self, control, down)
            end

            OurMouseAction(_player, self:GetLeftMouseAction())
        elseif _PUSH_WITH_RMB and control == CONTROL_SECONDARY and not down then
            if TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() then
                return OldOnControl(self, control, down)
            end

            OurMouseAction(_player, self:GetRightMouseAction())
        end

        OldOnControl(self, control, down)
    end

    _self.OnControl = NewOnControl

    DebugInit("PlayerControllerPostInit")
end

AddPlayerPostInit(OnPlayerActivated, OnPlayerDeactivated)
AddComponentPostInit("playeractionpicker", PlayerActionPickerPostInit)
AddComponentPostInit("playercontroller", PlayerControllerPostInit)

--
-- KnownModIndex
--

if GetModConfigData("hide_changelog") then
    local KnownModIndex = _G.KnownModIndex
    local OldGetModInfo = KnownModIndex.GetModInfo
    local TrimString = _G.TrimString

    KnownModIndex.GetModInfo = function(_self, _modname)
        if _modname == modname
            and _self.savedata
            and _self.savedata.known_mods
            and _self.savedata.known_mods[modname]
        then
            local modinfo = _self.savedata.known_mods[modname].modinfo
            if modinfo and modinfo.description then
                local changelog = string.find(modinfo.description, "v" .. modinfo.version)
                if type(changelog) == "number" then
                    modinfo.description = TrimString(modinfo.description:sub(1, changelog - 1))
                end
            end
        end
        return OldGetModInfo(_self, _modname)
    end

    _G.KnownModIndex = KnownModIndex
end
