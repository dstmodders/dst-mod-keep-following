local _DEFAULT_TASK_TIME = FRAMES * 9 --0.3
local _TENT_FIND_INVISIBLE_PLAYER_RANGE = 50

local _CAN_BE_LEADER_TAGS = {
    "abigail",
    "catcoon",
    "chester",
    "companion",
    "critter",
    "hutch",
    "koalefant",
    "lightninggoat",
    "manrabbit",
    "mossling",
    "pig",
    "player"
}

local KeepFollowing = Class(function(self, inst)
    self.inst = inst

    self.debug = false
    self.isclient = false
    self.isdst = false
    self.isfollowing = false
    self.ismastersim = false
    self.isnear = false
    self.ispushing = false
    self.leader = nil
    self.playercontroller = nil
    self.tasktime = 0

    --replaced by GetModConfigData
    self.keeptargetdistance = false
    self.targetdistance = 2.5

    inst:StartUpdatingComponent(self)
end)

function KeepFollowing:InGame()
    return self.inst and self.inst.HUD and not self.inst.HUD:HasInputFocus()
end

function KeepFollowing:CanBeLeader(entity)
    if entity == self.inst then
        return false
    end

    for _, tag in pairs(_CAN_BE_LEADER_TAGS) do
        if entity:HasTag(tag) then
            return true
        end
    end
end

function KeepFollowing:SetLeader(entity)
    if self:CanBeLeader(entity) then
        self.leader = entity
        self:DebugString(string.format("new leader %s", self.leader:GetDisplayName()))
    end
end

function KeepFollowing:GetLeader()
    return self.leader
end

function KeepFollowing:FindClosestInvisiblePlayerInRange(x, y, z, range)
    local closestPlayer
    local rangesq = range * range

    for _, v in ipairs(AllPlayers) do
        if not v.entity:IsVisible() then
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            if distsq < rangesq then
                rangesq = distsq
                closestPlayer = v
            end
        end
    end

    return closestPlayer, closestPlayer ~= nil and rangesq or nil
end

function KeepFollowing:GetTentSleeper(entity)
    local player

    if not entity:HasTag("tent") or not entity:HasTag("hassleeper") then
        return nil
    end

    self:DebugString(string.format("attempting to get a %s sleeper", entity:GetDisplayName()))

    if entity.components.sleepingbag and entity.components.sleepingbag.sleeper then
        player = entity.components.sleepingbag.sleeper
    else
        self:DebugString("sleepingbag component is not available, looking for sleeping players nearby")
        local x, y, z = entity.Transform:GetWorldPosition()
        player = self:FindClosestInvisiblePlayerInRange(x, y, z, _TENT_FIND_INVISIBLE_PLAYER_RANGE)
    end

    if player and player:HasTag("sleeping") then
        self:DebugString(string.format("found sleeper %s", player:GetDisplayName()))
        return player
    end

    return nil
end

function KeepFollowing:WalkToPoint(pos)
    if self.playercontroller.locomotor then
        self.playercontroller:DoAction(BufferedAction(self.inst, nil, ACTIONS.WALKTO, nil, pos))
    else
        SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, pos.x, pos.z)
    end
end

function KeepFollowing:IsFollowing()
    return self.leader and self.isfollowing
end

function KeepFollowing:IsPushing()
    return self.leader and self.ispushing
end

function KeepFollowing:StartFollowing(leader)
    local distance

    if not self:IsFollowing() then
        self:SetLeader(leader)
    end

    if self.leader and self.playercontroller then
        distance = math.sqrt(self.inst:GetDistanceSqToPoint(self.leader:GetPosition()))

        if not self:IsFollowing() then
            self.isfollowing = true

            self:DebugString(string.format(
                "started following leader. Distance: %0.2f. Target: %0.2f",
                distance,
                self.targetdistance
            ))
        end

        self.inst:DoTaskInTime(self.tasktime, function()
            if self:IsFollowing() then
                if distance >= self.targetdistance then
                    self.isnear = false
                elseif not self.isnear and distance < self.targetdistance then
                    self.isnear = true
                    self.tasktime = 0
                end

                if not self.isnear or self.keeptargetdistance then
                    self:WalkToPoint(self.inst:GetPositionAdjacentTo(leader, self.targetdistance - 0.25))
                    if self.tasktime == 0 then
                        self.tasktime = _DEFAULT_TASK_TIME
                    end
                end

                self:StartFollowing(leader)
            end
        end)
    end
end

function KeepFollowing:StartPushing(leader)
    local distance

    if not self:IsPushing() then
        self:SetLeader(leader)
    end

    if self.leader and self.playercontroller then
        distance = math.sqrt(self.inst:GetDistanceSqToPoint(self.leader:GetPosition()))

        if not self:IsPushing() then
            self.ispushing = true

            self:DebugString(string.format(
                "started pushing leader",
                distance,
                self.targetdistance
            ))
        end

        self.inst:DoTaskInTime(self.tasktime, function()
            if self:IsPushing() then
                self:WalkToPoint(leader:GetPosition())
                self:StartPushing(leader)
            end
        end)
    end
end

function KeepFollowing:StopFollowing()
    if self.leader then
        self:DebugString(string.format("stopped following %s", self.leader:GetDisplayName()))
        self.inst:CancelAllPendingTasks()
        self.isfollowing = false
        self.leader = nil
        self.tasktime = 0
    end
end

function KeepFollowing:StopPushing()
    if self.leader then
        self:DebugString(string.format("stopped pushing %s", self.leader:GetDisplayName()))
        self.inst:CancelAllPendingTasks()
        self.ispushing = false
        self.leader = nil
        self.tasktime = 0
    end
end

function KeepFollowing:Stop()
    if self:InGame() then
        if self:IsFollowing() then
            self:StopFollowing()
        end

        if self:IsPushing() then
            self:StopPushing()
        end
    end
end

function KeepFollowing:EnableDebug()
    self.debug = true
end

function KeepFollowing:DisableDebug()
    self.debug = false
end

function KeepFollowing:DebugString(string)
    if self.debug then
        print(string.format("Mod (%s): %s", self.modname, tostring(string)))
    end
end

return KeepFollowing
