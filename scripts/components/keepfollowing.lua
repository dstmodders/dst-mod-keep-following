local _DEFAULT_TASK_TIME = FRAMES * 9 --0.3
local _TENT_FIND_INVISIBLE_PLAYER_RANGE = 50

local _CAN_BE_LEADER_TAGS = {
    "abigail",
    "babybeefalo",
    "balloon",
    "beefalo",
    "berrythief", --Gobbler
    "catcoon",
    "chester",
    "companion",
    "critter",
    "deer",
    "fruitdragon", --Saladmander
    "grassgekko",
    "hutch",
    "koalefant",
    "lightninggoat", --Volt Goat
    "manrabbit",
    "monkey", --Splumonkey
    "mossling",
    "mufflehat", --Slurper
    "penguin", --Pengull
    "pig",
    "player",
    "rocky", --Rock Lobster
    "slurtle",
    "snurtle"
}

local KeepFollowing = Class(function(self, inst)
    self.inst = inst

    self:Init()
    inst:StartUpdatingComponent(self)
end)

function KeepFollowing:Init()
    self.debugfn = nil
    self.isclient = false
    self.isdst = false
    self.isfollowing = false
    self.ismastersim = TheWorld.ismastersim
    self.isnear = false
    self.ispushing = false
    self.leader = nil
    self.movementpredictionstate = nil
    self.playercontroller = nil
    self.tasktime = 0
    self.world = TheWorld

    --replaced by GetModConfigData
    self.configkeeptargetdistance = false
    self.configpushinglagcompensation = true
    self.configtargetdistance = 2.5
end

--
-- General
--

function KeepFollowing:IsMasterSim()
    return self.ismastersim
end

function KeepFollowing:InGame()
    return self.inst and self.inst.HUD and not self.inst.HUD:HasInputFocus()
end

function KeepFollowing:WalkToPosition(pos)
    if self.playercontroller.locomotor then
        self.playercontroller:DoAction(BufferedAction(self.inst, nil, ACTIONS.WALKTO, nil, pos))
    else
        SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, pos.x, pos.z)
    end
end

function KeepFollowing:Stop()
    if self:InGame() then
        if self:IsFollowing() then
            self:StopFollowing()
        end

        if self:IsPushing() then
            if self.configpushinglagcompensation and not self:IsMasterSim() then
                self:MovementPredictionOnStop()
            end

            self:StopPushing()
        end
    end
end

--
-- Movement prediction
--

function KeepFollowing:IsMovementPredictionEnabled()
    local state = self.inst.components.locomotor ~= nil
    self:DebugString("Checking movement prediction current state...")
    self:DebugString("Current state:", state and "enabled" or "disabled")
    return state
end

function KeepFollowing:MovementPrediction(enable)
    if enable then
        local x, _, z = self.inst.Transform:GetWorldPosition()
        SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, x, z)
        self.inst:EnableMovementPrediction(true)
        self:DebugString("Movement prediction: enabled")
        return true
    elseif self.inst.components and self.inst.components.locomotor then
        self.inst.components.locomotor:Stop()
        self.inst:EnableMovementPrediction(false)
        self:DebugString("Movement prediction: disabled")
        return false
    end
end

function KeepFollowing:MovementPredictionOnPush()
    local state = self:IsMovementPredictionEnabled()

    if self.movementpredictionstate == nil then
        self:DebugString("Setting movement prediction previous state...")
        self.movementpredictionstate = state
        self:DebugString("Previous state:", state and "enabled" or "disabled")
    end

    if self.movementpredictionstate then
        self:MovementPrediction(false)
    end
end

function KeepFollowing:MovementPredictionOnFollow()
    local state = self.movementpredictionstate
    if state ~= nil then
        self:MovementPrediction(state)
        self.movementpredictionstate = nil
    end
end

function KeepFollowing:MovementPredictionOnStop()
    self:MovementPrediction(self.movementpredictionstate)
    self.movementpredictionstate = nil
end

--
-- Leader-related
--

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
        self:DebugString("New leader:", self.leader:GetDisplayName())
    end
end

function KeepFollowing:GetLeader()
    return self.leader
end

--
-- Tent-related
--

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

    self:DebugString("Attempting to get a", entity:GetDisplayName(), "sleeper...")

    if entity.components.sleepingbag and entity.components.sleepingbag.sleeper then
        player = entity.components.sleepingbag.sleeper
    else
        self:DebugString("Component sleepingbag is not available, looking for sleeping players nearby...")
        local x, y, z = entity.Transform:GetWorldPosition()
        player = self:FindClosestInvisiblePlayerInRange(x, y, z, _TENT_FIND_INVISIBLE_PLAYER_RANGE)
    end

    if player and player:HasTag("sleeping") then
        self:DebugString("Found sleeping", player:GetDisplayName())
        return player
    end

    return nil
end

--
-- Following
--

function KeepFollowing:IsFollowing()
    return self.leader and self.isfollowing
end

function KeepFollowing:StartFollowing(leader)
    local distance

    if not self:IsFollowing() then
        if self.configpushinglagcompensation and not self:IsMasterSim() then
            self:MovementPredictionOnFollow()
        end

        self:SetLeader(leader)
    end

    if self.leader and self.playercontroller then
        distance = math.sqrt(self.inst:GetDistanceSqToPoint(self.leader:GetPosition()))

        if not self:IsFollowing() then
            self.isfollowing = true

            self:DebugString(string.format(
                "Started following leader. Distance: %0.2f. Target: %0.2f",
                distance,
                self.configtargetdistance
            ))
        end

        self.inst:DoTaskInTime(self.tasktime, function()
            if not self:IsFollowing() or not self.leader then
                return
            end

            if not self.leader.entity:IsValid() then
                self:DebugString("Leader doesn't exist anymore")
                self:Stop()
                return
            end

            if distance >= self.configtargetdistance then
                self.isnear = false
            elseif not self.isnear and distance < self.configtargetdistance then
                self.isnear = true
                self.tasktime = 0
            end

            if not self.isnear or self.configkeeptargetdistance then
                self:WalkToPosition(self.inst:GetPositionAdjacentTo(self.leader, self.configtargetdistance - 0.25))
                if self.tasktime == 0 then
                    self.tasktime = _DEFAULT_TASK_TIME
                end
            end

            self:StartFollowing(self.leader)
        end)
    end
end

function KeepFollowing:StopFollowing()
    if self.leader then
        self:DebugString("Stopped following", self.leader:GetDisplayName())
        self.inst:CancelAllPendingTasks()
        self.isfollowing = false
        self.leader = nil
        self.tasktime = 0
    end
end

--
-- Pushing
--

function KeepFollowing:IsPushing()
    return self.leader and self.ispushing
end

function KeepFollowing:StartPushing(leader)
    if not self:IsPushing() then
        if self.configpushinglagcompensation and not self:IsMasterSim() then
            self:MovementPredictionOnPush()
        end

        self:SetLeader(leader)
    end

    if self.leader and self.playercontroller then
        if not self:IsPushing() then
            self.ispushing = true

            self:DebugString("Started pushing leader")
        end

        self.inst:DoTaskInTime(self.tasktime, function()
            if not self:IsPushing() or not self.leader then
                return
            end

            if not self.leader.entity:IsValid() then
                self:DebugString("Leader doesn't exist anymore")
                self:Stop()
                return
            end

            self:WalkToPosition(self.leader:GetPosition())
            self:StartPushing(self.leader)
        end)
    end
end

function KeepFollowing:StopPushing()
    if self.leader then
        self:DebugString("Stopped pushing", self.leader:GetDisplayName())
        self.inst:CancelAllPendingTasks()
        self.ispushing = false
        self.leader = nil
        self.tasktime = 0
    end
end

--
-- Debugging-related
--

function KeepFollowing:DebugString(...)
    self.debugfn(...)
end

return KeepFollowing
