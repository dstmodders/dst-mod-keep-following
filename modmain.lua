--Globals
local CONTROL_MOVE_DOWN = GLOBAL.CONTROL_MOVE_DOWN
local CONTROL_MOVE_LEFT = GLOBAL.CONTROL_MOVE_LEFT
local CONTROL_MOVE_RIGHT = GLOBAL.CONTROL_MOVE_RIGHT
local CONTROL_MOVE_UP = GLOBAL.CONTROL_MOVE_UP
local TheInput = GLOBAL.TheInput

--Other
local _DEBUG = GetModConfigData("debug")

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

local function IsMoveButtonDown()
    return TheInput:IsControlPressed(CONTROL_MOVE_UP)
        or TheInput:IsControlPressed(CONTROL_MOVE_DOWN)
        or TheInput:IsControlPressed(CONTROL_MOVE_LEFT)
        or TheInput:IsControlPressed(CONTROL_MOVE_RIGHT)
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

    TheInput:AddKeyHandler(function()
        if player.components.keepfollowing:InGame() and IsMoveButtonDown() then
            if player.components.keepfollowing:IsFollowing() then
                player.components.keepfollowing:StopFollowing()
            end

            if player.components.keepfollowing:IsPushing() then
                player.components.keepfollowing:StopPushing()
            end
        end
    end)

    DebugString("added movement keys handler")
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

AddPlayerPostInit(OnPlayerActivated, OnPlayerDeactivated)
