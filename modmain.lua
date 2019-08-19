--Globals
local ACTIONS = GLOBAL.ACTIONS
local CONTROL_MOVE_DOWN = GLOBAL.CONTROL_MOVE_DOWN
local CONTROL_MOVE_LEFT = GLOBAL.CONTROL_MOVE_LEFT
local CONTROL_MOVE_RIGHT = GLOBAL.CONTROL_MOVE_RIGHT
local CONTROL_MOVE_UP = GLOBAL.CONTROL_MOVE_UP
local TheInput = GLOBAL.TheInput

--GetModConfigData
local function GetKeyFromConfig(config)
    local key = GetModConfigData(config)
    return key and (type(key) == "number" and key or GLOBAL[key]) or -1
end

local _DEBUG = GetModConfigData("debug")
local _KEY_ACTION = GetKeyFromConfig("key_action")
local _KEY_PUSH = GetKeyFromConfig("key_push")

local function DebugString(string)
    if _DEBUG then
        print(string.format("Mod (%s): %s", modname, tostring(string)))
    end
end

local function IsDST()
    return GLOBAL.TheSim:GetGameID() == "DST"
end

local function IsClient()
    return IsDST() and GLOBAL.TheNet:GetIsClient()
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

local function OnPlayerActivated(player)
    player:AddComponent("keepfollowing")

    player.components.keepfollowing.isclient = IsClient()
    player.components.keepfollowing.isdst = IsDST()
    player.components.keepfollowing.modname = modname

    --GetModConfigData
    player.components.keepfollowing.targetdistance = GetModConfigData("target_distance")

    if _DEBUG then
        player.components.keepfollowing:EnableDebug()
    end

    DebugString(string.format("player %s activated", player:GetDisplayName()))
end

local function OnPlayerDeactivated(player)
    player:RemoveComponent("keepfollowing")

    DebugString(string.format("player %s deactivated", player:GetDisplayName()))
end

local function AddPlayerPostInit(onActivatedFn, onDeactivatedFn)
    DebugString(string.format("game ID - %s", GLOBAL.TheSim:GetGameID()))

    if IsDST() then
        env.AddPrefabPostInit("world", function(world)
            world:ListenForEvent("playeractivated", function(world, player)
                if player == GLOBAL.ThePlayer then
                    onActivatedFn(player)
                end
            end)

            world:ListenForEvent("playerdeactivated", function(world, player)
                if player == GLOBAL.ThePlayer then
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

local function PlayerControllerPostInit(self, player)
    local ThePlayer = GLOBAL.ThePlayer

    if player ~= ThePlayer then
        return
    end

    local OldGetLeftMouseAction = self.GetLeftMouseAction
    local OldOnControl = self.OnControl
    local OldOnLeftClick = self.OnLeftClick

    local function NewGetLeftMouseAction(self)
        local act = OldGetLeftMouseAction(self)

        if act and act.target then
            local keepfollowing = act.doer.components.keepfollowing

            if act.target:HasTag("tent") and act.target:HasTag("hassleeper") then
                if TheInput:IsKeyDown(_KEY_ACTION) and not TheInput:IsKeyDown(_KEY_PUSH) then
                    act.action = ACTIONS.TENTFOLLOW
                elseif TheInput:IsKeyDown(_KEY_ACTION) and TheInput:IsKeyDown(_KEY_PUSH) then
                    act.action = ACTIONS.TENTPUSH
                end
            end

            if keepfollowing:CanBeLeader(act.target) then
                if TheInput:IsKeyDown(_KEY_ACTION) and not TheInput:IsKeyDown(_KEY_PUSH) then
                    act.action = ACTIONS.FOLLOW
                elseif TheInput:IsKeyDown(_KEY_ACTION) and TheInput:IsKeyDown(_KEY_PUSH) then
                    act.action = ACTIONS.PUSH
                end
            end
        end

        self.LMBaction = act

        return self.LMBaction
    end

    local function NewOnLeftClick(self, down)
        if not down or TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() then
            return OldOnLeftClick(self, down)
        end

        local act = self:GetLeftMouseAction()
        if act then
            local keepfollowing = act.doer.components.keepfollowing
            if keepfollowing then
                keepfollowing.playercontroller = self
            end

            if IsOurAction(act.action) then
                return act.action.fn(act)
            end
        end

        OldOnLeftClick(self, down)
    end

    local function NewOnControl(self, control, down)
        if IsMoveButton(control) then
            local keepfollowing = player.components.keepfollowing
            if keepfollowing and keepfollowing:InGame() then
                if keepfollowing:IsFollowing() then
                    keepfollowing:StopFollowing()
                end

                if keepfollowing:IsPushing() then
                    keepfollowing:StopPushing()
                end
            end
        end

        return OldOnControl(self, control, down)
    end

    self.GetLeftMouseAction = NewGetLeftMouseAction
    self.OnControl = NewOnControl
    self.OnLeftClick = NewOnLeftClick

    DebugString("playercontroller initialized")
end

AddAction("FOLLOW", "Follow", ActionFollow)
AddAction("PUSH", "Push", ActionPush)
AddAction("TENTFOLLOW", "Follow player in", ActionTentFollow)
AddAction("TENTPUSH", "Push player in", ActionTentPush)

AddComponentPostInit("playercontroller", PlayerControllerPostInit)

AddPlayerPostInit(OnPlayerActivated, OnPlayerDeactivated)
