local _DEBUG_FN
local _FOLLOWING_THREAD_ID = "following_thread"
local _PATH_THREAD_ID = "path_thread"
local _PUSHING_THREAD_ID = "pushing_thread"
local _TENT_FIND_INVISIBLE_PLAYER_RANGE = 50

-- We could have used group tags instead of mob-specific ones but this approach gives more control.
-- Originally the list included only player-friendly ones but as the mod has matured the list was
-- expanding based on the requests from players as there are some cases when even following/pushing
-- bosses, ghosts and worms is useful.
--
-- When "Mobs" configuration option is set to "All" this hand-picked list will be ignored.
local _CAN_BE_LEADER_TAGS = {
    -- hostile creatures
    "bat", -- Batilisk
    "birchnutdrake", -- Birchnutter
    "bishop",
    "bishop_nightmare",
    "firehound",
    "frog",
    "ghost",
    "hound",
    "icehound",
    "knight",
    "knight_nightmare",
    "lavae",
    "little_walrus", -- Wee MacTusk
    "merm",
    "moonpig", -- Werepig
    "pigguard", -- Guardian Pig
    "rook",
    "rook_nightmare",
    "slurper",
    "spat", -- Ewecus
    "spider",
    "spider_dropper", -- Dangling Depth Dweller
    "spider_hider", -- Cave Spider
    "spider_spitter", -- Spitter
    "spider_warrior",
    "tallbird",
    "walrus", -- MacTusk
    "warg", -- Varg
    "worm", -- Depths Worm

    -- boss monsters
    "bearger",
    "beequeen",
    "deerclops",
    "dragonfly",
    "klaus",
    "leif", -- Normal Treeguard
    "leif_sparse", -- Lumpy Treeguard
    "minotaur", -- Ancient Guardian
    "moose", -- Moose/Goose
    "spiderqueen",
    "stalker", -- Reanimated Skeleton (Caves)
    "stalker_atrium", -- Reanimated Skeleton (Ancient Fuelweaver)
    "stalker_forest", -- Reanimated Skeleton (Forest)
    "toadstool",
    "toadstool_dark", -- Misery Toadstool

    -- neutral animals
    "beefalo",
    "catcoon",
    "fruitdragon", -- Saladmander
    "koalefant",
    "krampus",
    "lightninggoat", -- Volt Goat
    "monkey", -- Splumonkey/Shadow Splumonkey
    "mossling", -- Mosling
    "penguin", -- Pengull
    "pig",
    "rocky", -- Rock Lobster
    "slurtle",
    "snurtle",
    "teenbird", -- Smallish Tallbird

    -- passive animals
    "babybeefalo",
    "berrythief", -- Gobbler
    "carrat",
    "chester",
    "deer",
    "deer_blue", -- Gem Deer (Blue)
    "deer_red", -- Gem Deer (Red)
    "glommer",
    "grassgekko",
    "hutch",
    "lavae_pet", -- Extra-Adorable Lavae
    "manrabbit", -- Bunnyman/Beardlord
    "mole",
    "smallbird",

    -- other
    "abigail",
    "balloon",
    "companion",
    "critter",
    "player",
}

local KeepFollowing = Class(function(self, inst)
    self.inst = inst

    self:Init()
    inst:StartUpdatingComponent(self)
end)

function KeepFollowing:Init()
    self.isclient = false
    self.isdst = false
    self.isfollowing = false
    self.isleadernear = false
    self.ismastersim = TheWorld.ismastersim
    self.ispushing = false
    self.leader = nil
    self.leaderpositions = {}
    self.movementpredictionstate = nil
    self.playercontroller = nil
    self.threadfollowing = nil
    self.threadpath = nil
    self.threadpushing = nil
    self.world = TheWorld

    --replaced by GetModConfigData
    self.configfollowingmethod = "default"
    self.configkeeptargetdistance = false
    self.configmobs = "default"
    self.configpushlagcompensation = true
    self.configpushmasschecking = true
    self.configtargetdistance = 2.5
end

--
-- Helpers
--

local function IsPlayerInGame(player)
    return player and player.HUD and not player.HUD:HasInputFocus()
end

local function GetDistSq(x1, y1, z1, x2, y2, z2)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1
    return dx * dx + dy * dy + dz * dz
end

local function GetDistSqBetweenPositions(p1, p2)
    return GetDistSq(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z)
end

local function WalkToPosition(self, pos)
    local action = BufferedAction(self.inst, nil, ACTIONS.WALKTO, nil, pos)

    if self.ismastersim then
        self.playercontroller:DoAction(action)
    else
        if self.playercontroller.locomotor then
            self.playercontroller:DoAction(action)
        else
            SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, pos.x, pos.z)
        end

        local locomotor = self.playercontroller.locomotor
        if locomotor then
            locomotor:PreviewAction(action)
        end
    end
end

--
-- Debugging-related
--

function KeepFollowing:SetDebugFn(fn)
    _DEBUG_FN = fn
end

local function DebugString(...)
    if _DEBUG_FN then
        _DEBUG_FN(...)
    end
end

local function DebugTheadString(...)
    if _DEBUG_FN then
        local task = scheduler:GetCurrentTask()
        if task then
            _DEBUG_FN("[" .. task.id .. "]", ...)
        end
    end
end

--
-- General
--

function KeepFollowing:Stop()
    if IsPlayerInGame(self.inst) then
        if self:IsFollowing() then
            self:StopFollowing()
        end

        if self:IsPushing() then
            self:StopPushing()
        end
    end
end

--
-- Movement prediction
--

local function MovementPredictionOnPush(self)
    local state = self:IsMovementPredictionEnabled()

    if self.movementpredictionstate == nil then
        DebugString("Setting movement prediction previous state...")
        self.movementpredictionstate = state
        DebugString("Previous state:", state and "enabled" or "disabled")
    end

    if self.movementpredictionstate then
        self:MovementPrediction(false)
    end
end

local function MovementPredictionOnFollow(self)
    local state = self.movementpredictionstate
    if state ~= nil then
        self:MovementPrediction(state)
        self.movementpredictionstate = nil
    end
end

local function MovementPredictionOnStop(self)
    self:MovementPrediction(self.movementpredictionstate)
    self.movementpredictionstate = nil
end

function KeepFollowing:IsMovementPredictionEnabled()
    local state = self.inst.components.locomotor ~= nil
    DebugString("Checking movement prediction current state...")
    DebugString("Current state:", state and "enabled" or "disabled")
    return state
end

function KeepFollowing:MovementPrediction(enable)
    if enable then
        local x, _, z = self.inst.Transform:GetWorldPosition()
        SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, x, z)
        self.inst:EnableMovementPrediction(true)
        DebugString("Movement prediction: enabled")
        return true
    elseif self.inst.components and self.inst.components.locomotor then
        self.inst.components.locomotor:Stop()
        self.inst:EnableMovementPrediction(false)
        DebugString("Movement prediction: disabled")
        return false
    end
end

--
-- Leader-related
--

function KeepFollowing:CanBeFollowed(entity)
    if not entity or (entity.entity and not entity.entity:IsValid()) then
        return false
    end

    return entity:HasTag("locomotor") or entity:HasTag("balloon")
end

function KeepFollowing:CanBePushed(entity)
    if not self.inst or not entity or not entity.Physics then
        return false
    end

    -- ghosts should be able to push other players ignoring the mass difference as the point is not
    -- to move the player but to provide light
    if self.inst:HasTag("playerghost") and entity:HasTag("player") then
        return true
    end

    -- different flyers don't collide with characters so pushing won't work anyway
    if entity.Physics:GetCollisionGroup() == COLLISION.FLYERS then
        return false
    end

    -- Shadow Creatures also don't collide with characters
    if entity.Physics:GetCollisionGroup() == COLLISION.SANITY then
        return false
    end

    if not self.configpushmasschecking then
        return true
    end

    -- Mass is the key factor for pushing. Players have a mass of 75 while most bosses have a mass
    -- 1000. Moleworms have a mass of 99999 and Gigantic Beehive has a mass of 999999 which makes
    -- them act as "unpushable". If Klei's physics is correct then even those entities can be pushed
    -- but it will take a very very long time.
    --
    -- The only entities with high mass that still can be useful to be pushed are bosses like
    -- Bearger or Toadstool. They both have mass 1000 and that will be our ceil value to disable
    -- pushing.
    local mass = self.inst.Physics:GetMass()
    local entitymass = entity.Physics:GetMass()
    local massdiff = math.abs(entitymass - mass)

    -- 925 = 1000 (boss) - 75 (player)
    if massdiff > 925 then
        return false
    end

    -- When the player becomes a ghost his mass becomes 1. In this case, we just set the ceil value
    -- difference to 10 as there is no point to push something with a mass higher than that. But
    -- there are Frogs, Saladmanders and Critters with mass 1 so why ruin all the fun and disable
    -- pushing for a ghost.
    if mass == 1 and massdiff > 10 then
        return false
    end

    return true
end

function KeepFollowing:CanBeLeader(entity)
    if not entity or not entity.entity:IsValid() or entity == self.inst then
        return false
    end

    if self.configmobs == "all" then
        return self:CanBeFollowed(entity)
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
        DebugString(string.format(
            "New leader: %s. Distance: %0.2f. Target: %0.2f",
            self.leader:GetDisplayName(),
            math.sqrt(self.inst:GetDistanceSqToPoint(self.leader:GetPosition())),
            self.configtargetdistance
        ))
    end
end

function KeepFollowing:GetLeader()
    return self.leader
end

--
-- Tent-related
--

local function FindClosestInvisiblePlayerInRange(x, y, z, range)
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

    DebugString("Attempting to get a", entity:GetDisplayName(), "sleeper...")

    if entity.components.sleepingbag and entity.components.sleepingbag.sleeper then
        player = entity.components.sleepingbag.sleeper
    else
        DebugString("Component sleepingbag is not available, looking for sleeping players nearby...")
        local x, y, z = entity.Transform:GetWorldPosition()
        player = FindClosestInvisiblePlayerInRange(x, y, z, _TENT_FIND_INVISIBLE_PLAYER_RANGE)
    end

    if player and player:HasTag("sleeping") then
        DebugString("Found sleeping", player:GetDisplayName())
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

function KeepFollowing:StartPathThread()
    self.threadpath = StartThread(function()
        local pos, previouspos
        local dist

        DebugTheadString("Started gathering path coordinates...")

        while self.inst and self.inst:IsValid() and self:IsFollowing() do
            if not self.leader or not self.leader.entity:IsValid() then
                DebugTheadString("Leader doesn't exist anymore")
                self:StopFollowing()
                return
            end

            pos = self.leader:GetPosition()

            if not previouspos then
                table.insert(self.leaderpositions, pos)
                previouspos = pos
            end

            -- 1 is the most optimal value so far
            dist = math.sqrt(GetDistSqBetweenPositions(pos, previouspos))
            if dist > 1 and pos ~= previouspos then
                table.insert(self.leaderpositions, pos)
                previouspos = pos
            end

            Sleep(FRAMES)
        end

        self:ClearPathThread()
    end, _PATH_THREAD_ID)
end

function KeepFollowing:StartFollowingThread()
    self.threadfollowing = StartThread(function()
        local distinstsq, distinst
        local distsqleader, distleader
        local pos, previouspos, isleadernear

        local radiusinst = self.inst.Physics:GetRadius()
        local radiusleader = self.leader.Physics:GetRadius()
        local target = self.configtargetdistance + radiusleader

        self.isfollowing = true

        DebugTheadString("Following method:", self.configfollowingmethod)
        DebugTheadString(string.format(
            "Started following %s...",
            self.leader:GetDisplayName()
        ))

        if self.configfollowingmethod == "default" then
            self:StartPathThread()
        end

        while self.inst and self.inst:IsValid() and self:IsFollowing() do
            if not self.leader or not self.leader.entity:IsValid() then
                DebugTheadString("Leader doesn't exist anymore")
                self:StopFollowing()
                return
            end

            isleadernear = self.inst:IsNear(self.leader, target)

            if self.configfollowingmethod == "default" then
                pos = self.leaderpositions[1]

                if pos then
                    distinstsq = self.inst:GetDistanceSqToPoint(pos)
                    distinst = math.sqrt(distinstsq)
                    distsqleader = self.leader:GetDistanceSqToPoint(pos)
                    distleader = math.sqrt(distsqleader)

                    -- 1.5 in diameter. Smaller value gives more precision, especially near the
                    -- corners. However, when lag compensation is off the movement becomes "awkward"
                    -- so I don't recommend using something less than 1 diameter.
                    if distinst > radiusinst * 3 then
                        if not self.isleadernear and isleadernear or (isleadernear and self.configkeeptargetdistance) then
                            WalkToPosition(self, self.inst:GetPositionAdjacentTo(self.leader, target))
                            self.leaderpositions = {}
                        elseif not isleadernear then
                            WalkToPosition(self, pos)
                        else
                            self.leaderpositions = {}
                        end
                    else
                        table.remove(self.leaderpositions, 1)
                    end
                end
            elseif self.configfollowingmethod == "closest" then
                pos = self.leader:GetPosition()
                distsqleader = self.leader:GetDistanceSqToPoint(pos)

                if (not previouspos or pos ~= previouspos) and (not isleadernear or self.configkeeptargetdistance) then
                    WalkToPosition(self, self.inst:GetPositionAdjacentTo(self.leader, target))
                    previouspos = pos
                end
            end

            self.isleadernear = isleadernear

            Sleep(FRAMES)
        end

        self:ClearFollowingThread()
    end, _FOLLOWING_THREAD_ID)
end

function KeepFollowing:StartFollowing(leader)
    if self.configpushlagcompensation and not self.ismastersim then
        MovementPredictionOnFollow(self)
    end

    self:SetLeader(leader)
    self:StartFollowingThread()
end

function KeepFollowing:ClearPathThread()
    if self.threadpath then
        DebugString("[" .. self.threadpath.id .. "]", "Thread cleared")
        KillThreadsWithID(self.threadpath.id)
        self.threadpath:SetList(nil)
        self.threadpath = nil
    end
end

function KeepFollowing:ClearFollowingThread()
    if self.threadfollowing then
        DebugString("[" .. self.threadfollowing.id .. "]", "Thread cleared")
        KillThreadsWithID(self.threadfollowing.id)
        self.threadfollowing:SetList(nil)
        self.threadfollowing = nil
    end
end

function KeepFollowing:StopFollowing()
    if self.leader then
        DebugString("[" .. self.threadfollowing.id .. "]", "Stopped following", self.leader:GetDisplayName())
        self.isfollowing = false
        self.leader = nil
        self.leaderpositions = {}
        self:ClearPathThread()
        self:ClearFollowingThread()
    end
end

--
-- Pushing
--

function KeepFollowing:IsPushing()
    return self.leader and self.ispushing
end

function KeepFollowing:StartPushing(leader)
    if self.configpushlagcompensation and not self.ismastersim then
        MovementPredictionOnPush(self)
    end

    self:SetLeader(leader)

    self.threadpushing = StartThread(function()
        self.ispushing = true

        DebugTheadString("Started pushing leader")

        while self.inst and self.inst:IsValid() and self:IsPushing() do
            if not self.leader or not self.leader.entity:IsValid() then
                DebugTheadString("Leader doesn't exist anymore")
                self:StopPushing()
                return
            end

            WalkToPosition(self, self.leader:GetPosition())

            Sleep(FRAMES)
        end

        self:ClearPushingThread()
    end, _PUSHING_THREAD_ID)
end

function KeepFollowing:ClearPushingThread()
    if self.threadpushing then
        DebugString("[" .. self.threadpushing.id .. "]", "Thread cleared")
        KillThreadsWithID(self.threadpushing.id)
        self.threadpushing:SetList(nil)
        self.threadpushing = nil
    end
end

function KeepFollowing:StopPushing()
    if self.configpushlagcompensation and not self.ismastersim then
        MovementPredictionOnStop(self)
    end

    if self.leader then
        DebugString("[" .. self.threadpushing.id .. "]", "Stopped pushing", self.leader:GetDisplayName())
        self.inst:CancelAllPendingTasks()
        self.ispushing = false
        self.leader = nil
        self:ClearPushingThread()
    end
end

return KeepFollowing
