--
-- Globals
--
local _G = GLOBAL
local ACTIONS = _G.ACTIONS
local CONTROL_MOVE_DOWN = _G.CONTROL_MOVE_DOWN
local CONTROL_MOVE_LEFT = _G.CONTROL_MOVE_LEFT
local CONTROL_MOVE_RIGHT = _G.CONTROL_MOVE_RIGHT
local CONTROL_MOVE_UP = _G.CONTROL_MOVE_UP
local CONTROL_PRIMARY = _G.CONTROL_PRIMARY
local CONTROL_SECONDARY = _G.CONTROL_SECONDARY
local RPC = _G.RPC
local SendRPCToServer = _G.SendRPCToServer
local TheInput = _G.TheInput
local TheSim = _G.TheSim

--
-- Private
--
local _MOVEMENT_PREDICTION_PREVIOUS_STATE

--
-- GetModConfigData-related
--
local function GetKeyFromConfig(config)
    local key = GetModConfigData(config)
    return key and (type(key) == "number" and key or _G[key]) or -1
end

local _DEBUG = GetModConfigData("debug")
local _KEY_ACTION = GetKeyFromConfig("key_action")
local _KEY_PUSH = GetKeyFromConfig("key_push")
local _PUSH_WITH_RMB = GetModConfigData("push_with_rmb")
local _PUSHING_LAG_COMPENSATION = GetModConfigData("pushing_lag_compensation")

--
-- Debugging-related
--

local DebugFn = _DEBUG and function(...)
    local msg = string.format("[%s]", modname)
    for i = 1, arg.n do
        msg = msg .. " " .. tostring(arg[i])
    end
    print(msg)
end or function()
    --nil
end

local function DebugString(...)
    DebugFn(...)
end

--
-- Helpers
--

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
        or action == ACTIONS.TENTFOLLOW
        or action == ACTIONS.TENTPUSH
end

local function IsOurFollowAction(action)
    return action == ACTIONS.FOLLOW or action == ACTIONS.TENTFOLLOW
end

local function IsOurPushAction(action)
    return action == ACTIONS.PUSH or action == ACTIONS.TENTPUSH
end

local function IsMovementPredictionEnabled()
    return _G.ThePlayer.components.locomotor ~= nil
end

local function MovementPrediction(enable)
    local ThePlayer = _G.ThePlayer

    if enable then
        local x, _, z = ThePlayer.Transform:GetWorldPosition()
        SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, x, z)
        ThePlayer:EnableMovementPrediction(true)
        DebugString("movement prediction enabled")
        return true
    elseif ThePlayer.components and ThePlayer.components.locomotor then
        ThePlayer.components.locomotor:Stop()
        ThePlayer:EnableMovementPrediction(false)
        DebugString("movement prediction disabled")
        return false
    end
end

--
-- Actions
--

local function ActionFollow(act)
    if not act.doer or not act.target or not act.doer.components.keepfollowing then
        return false
    end

    local keepfollowing = act.doer.components.keepfollowing
    keepfollowing:StopFollowing()
    keepfollowing:StartFollowing(act.target)

    return true
end

local function ActionPush(act)
    if not act.doer or not act.target or not act.doer.components.keepfollowing then
        return false
    end

    local keepfollowing = act.doer.components.keepfollowing
    keepfollowing:StopPushing()
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
        keepfollowing:StopFollowing()
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
        keepfollowing:StopPushing()
        keepfollowing:StartPushing(leader)
    end

    return true
end

AddAction("FOLLOW", "Follow", ActionFollow)
AddAction("PUSH", "Push", ActionPush)
AddAction("TENTFOLLOW", "Follow player in", ActionTentFollow)
AddAction("TENTPUSH", "Push player in", ActionTentPush)

--
-- Player-related
--

local function OnPlayerActivated(player)
    player:AddComponent("keepfollowing")

    player.components.keepfollowing.debugfn = DebugFn
    player.components.keepfollowing.isclient = IsClient()
    player.components.keepfollowing.isdst = IsDST()
    player.components.keepfollowing.modname = modname

    --GetModConfigData
    player.components.keepfollowing.keeptargetdistance = GetModConfigData("keep_target_distance")
    player.components.keepfollowing.targetdistance = GetModConfigData("target_distance")

    DebugString("player", player:GetDisplayName(), "activated")
end

local function OnPlayerDeactivated(player)
    player:RemoveComponent("keepfollowing")
    DebugString("player", player:GetDisplayName(), "deactivated")
end

local function AddPlayerPostInit(onActivatedFn, onDeactivatedFn)
    DebugString("game ID -", TheSim:GetGameID())

    if IsDST() then
        env.AddPrefabPostInit("world", function(world)
            world:ListenForEvent("playeractivated", function(world, player)
                if player == _G.ThePlayer then
                    onActivatedFn(player)
                end
            end)

            world:ListenForEvent("playerdeactivated", function(world, player)
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

    DebugString("AddPrefabPostInit fired")
end

local function PlayerControllerPostInit(self, player)
    local ThePlayer = _G.ThePlayer

    if player ~= ThePlayer then
        return
    end

    local function KeepFollowingStop()
        local keepfollowing = player.components.keepfollowing
        if not keepfollowing then
            return
        end

        if keepfollowing:IsFollowing() then
            keepfollowing:Stop()
        elseif keepfollowing:IsPushing() then
            if _PUSHING_LAG_COMPENSATION then
                MovementPrediction(_MOVEMENT_PREDICTION_PREVIOUS_STATE)
                _MOVEMENT_PREDICTION_PREVIOUS_STATE = nil
            end

            keepfollowing:Stop()
        end
    end

    local function OurMouseAction(player, act)
        if not act then
            KeepFollowingStop()
            return
        end

        local keepfollowing = player.components.keepfollowing
        local action = act.action

        if keepfollowing then
            keepfollowing.playercontroller = self
        end

        if _PUSHING_LAG_COMPENSATION and IsOurPushAction(action) then
            if _MOVEMENT_PREDICTION_PREVIOUS_STATE == nil then
                _MOVEMENT_PREDICTION_PREVIOUS_STATE = IsMovementPredictionEnabled()
            end

            if _MOVEMENT_PREDICTION_PREVIOUS_STATE then
                MovementPrediction(false)
            end

            return action.fn(act)
        elseif _PUSHING_LAG_COMPENSATION and IsOurFollowAction(action) then
            if _MOVEMENT_PREDICTION_PREVIOUS_STATE ~= nil then
                MovementPrediction(_MOVEMENT_PREDICTION_PREVIOUS_STATE)
                _MOVEMENT_PREDICTION_PREVIOUS_STATE = nil
            end

            return action.fn(act)
        elseif IsOurAction(action) then
            return action.fn(act)
        else
            KeepFollowingStop()
        end
    end

    local OldGetLeftMouseAction = self.GetLeftMouseAction
    local OldGetRightMouseAction = self.GetRightMouseAction
    local OldOnControl = self.OnControl

    local function NewGetLeftMouseAction(self)
        local act = OldGetLeftMouseAction(self)

        if act and act.target then
            local keepfollowing = act.doer.components.keepfollowing
            local target = act.target

            if TheInput:IsKeyDown(_KEY_ACTION)
                and target:HasTag("tent")
                and target:HasTag("hassleeper")
            then
                if _PUSH_WITH_RMB then
                    act.action = ACTIONS.TENTFOLLOW
                elseif TheInput:IsKeyDown(_KEY_PUSH) then
                    act.action = ACTIONS.TENTPUSH
                elseif not TheInput:IsKeyDown(_KEY_PUSH) then
                    act.action = ACTIONS.TENTFOLLOW
                end
            end

            if TheInput:IsKeyDown(_KEY_ACTION) and keepfollowing:CanBeLeader(target) then
                if _PUSH_WITH_RMB then
                    act.action = ACTIONS.FOLLOW
                elseif TheInput:IsKeyDown(_KEY_PUSH) then
                    act.action = ACTIONS.PUSH
                elseif not TheInput:IsKeyDown(_KEY_PUSH) then
                    act.action = ACTIONS.FOLLOW
                end
            end
        end

        self.LMBaction = act

        return self.LMBaction
    end

    local function NewGetRightMouseAction(self)
        local act = OldGetRightMouseAction(self)

        if act and act.target then
            local keepfollowing = act.doer.components.keepfollowing
            local target = act.target

            if TheInput:IsKeyDown(_KEY_ACTION)
                and target:HasTag("tent")
                and target:HasTag("hassleeper")
            then
                act.action = ACTIONS.TENTPUSH
            end

            if keepfollowing:CanBeLeader(target) then
                if TheInput:IsKeyDown(_KEY_ACTION) then
                    act.action = ACTIONS.PUSH
                end
            end
        end

        self.RMBaction = act

        return self.RMBaction
    end

    local function NewOnControl(self, control, down)
        if IsMoveButton(control) then
            KeepFollowingStop()
        end

        if control == CONTROL_PRIMARY then
            if not down or TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() then
                return OldOnControl(self, control, down)
            end

            OurMouseAction(player, self:GetLeftMouseAction())
        elseif _PUSH_WITH_RMB and control == CONTROL_SECONDARY then
            if not down or TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() then
                return OldOnControl(self, control, down)
            end

            OurMouseAction(player, self:GetRightMouseAction())
        end

        OldOnControl(self, control, down)
    end

    self.GetLeftMouseAction = NewGetLeftMouseAction
    self.OnControl = NewOnControl

    if _PUSH_WITH_RMB then
        self.GetRightMouseAction = NewGetRightMouseAction
    end

    DebugString("playercontroller initialized")
end

AddPlayerPostInit(OnPlayerActivated, OnPlayerDeactivated)
AddComponentPostInit("playercontroller", PlayerControllerPostInit)
