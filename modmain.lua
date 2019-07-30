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

AddPlayerPostInit(OnPlayerActivated, OnPlayerDeactivated)
