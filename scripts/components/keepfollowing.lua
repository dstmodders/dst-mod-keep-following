local _DEBUG_FN
local _FOLLOWING_THREAD_ID = "following_thread"
local _PATH_THREAD_ID = "path_thread"
local _PUSHING_THREAD_ID = "pushing_thread"
local _TENT_FIND_INVISIBLE_PLAYER_RANGE = 50

-- A list of actions that will cause the following thread to pause. The first value represents an
-- action itself and the second (optional) is a sleep time (default: 1.25).
local _PAUSE_ACTIONS = {
    { ACTIONS.ADDFUEL, .5 },
    { ACTIONS.ADDWETFUEL, .5 },
    { ACTIONS.BUILD },
    { ACTIONS.DROP, .5 },
    { ACTIONS.EAT, 1 },
    { ACTIONS.HEAL },
    { ACTIONS.LOOKAT, .25 },
    { ACTIONS.TEACH },
    { ACTIONS.USEITEM },
}

-- We could have used group tags instead of the mob-specific ones. However, this approach gives more
-- control. Originally the list included only player-friendly mobs but as the mod has matured the
-- list kept growing based on user requests. There are some cases when even following/pushing
-- bosses becomes useful.
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
    -- general
    self.isclient = false
    self.isdst = false
    self.ismastersim = TheWorld.ismastersim
    self.leader = nil
    self.movementpredictionstate = nil
    self.playercontroller = nil
    self.starttime = nil
    self.world = TheWorld

    -- following
    self.isfollowing = false
    self.isleadernear = false
    self.ispaused = false
    self.leaderpositions = {}
    self.threadfollowing = nil
    self.threadpath = nil

    -- pushing
    self.ispushing = false
    self.threadpushing = nil

    -- debugging
    self.debugrequests = 0

    -- replaced by GetModConfigData
    self.configfollowingmethod = "default"
    self.configkeeptargetdistance = false
    self.configmobs = "default"
    self.configpushlagcompensation = true
    self.configpushmasschecking = true
    self.configtargetdistance = 2.5
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
-- Helpers
--

local function IsPlayerInGame(player)
    return player and player.HUD and not player.HUD:HasInputFocus()
end

local function IsPassable(pos)
    return TheWorld.Map:IsPassableAtPoint(pos:Get())
end

local function GetClosestPosition(entity1, entity2)
    local distance = entity1.Physics:GetRadius() + entity2.Physics:GetRadius()
    return entity1:GetPositionAdjacentTo(entity2, distance)
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

local function GetDistBetweenPositions(p1, p2)
    return math.sqrt(GetDistSqBetweenPositions(p1, p2))
end

local function GetPauseAction(action)
    for _, v in ipairs(_PAUSE_ACTIONS) do
        if v[1] == action then
            if v[2] then
                return v[1], v[2]
            end

            return v[1], 1.25 -- 1.25 is the most optimal so far as a default value
        end
    end

    return nil
end

--
-- General
--

-- TODO: In some cases WalkToPosition() doesn't trigger moving (investigate PlayerController:DoAction())
local function WalkToPosition(self, pos)
    if self.ismastersim or self.playercontroller.locomotor then
        self.playercontroller:DoAction(BufferedAction(self.inst, nil, ACTIONS.WALKTO, nil, pos))
    else
        SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, pos.x, pos.z)
    end
end

function KeepFollowing:IsOnPlatform()
    if not self.world or not self.inst then
        return
    end

    return self.world.Map:GetPlatformAtPoint(self.inst:GetPosition():Get()) and true or false
end

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
    DebugString("Checking movement prediction current state...")
    local state = self:IsMovementPredictionEnabled()
    DebugString("Current state:", state and "enabled" or "disabled")

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
    return self.inst.components.locomotor ~= nil
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

function KeepFollowing:IsLeaderOnPlatform()
    if not self.world or not self.inst then
        return
    end

    return self.world.Map:GetPlatformAtPoint(self.leader:GetPosition():Get()) and true or false
end

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

    -- Ghosts should be able to push other players and ignore the mass difference checking. The
    -- point is to provide light.
    if self.inst:HasTag("playerghost") and entity:HasTag("player") then
        return true
    end

    -- different flyers don't collide with characters
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

    -- Mass is the key factor for pushing. For example, players have a mass of 75 while most bosses
    -- have a mass of 1000. Some entities just act as "unpushable" like Moleworm (99999) and
    -- Gigantic Beehive (999999). However, if Klei's physics is correct then even those entities can
    -- be pushed but it will take an insane amount of time...
    --
    -- So far the only entities with a high mass that still can be useful to be pushed are bosses
    -- like Bearger or Toadstool. They both have a mass of 1000 which makes a perfect ceil value for
    -- us to disable pushing.
    local mass = self.inst.Physics:GetMass()
    local entitymass = entity.Physics:GetMass()
    local massdiff = math.abs(entitymass - mass)

    -- 925 = 1000 (boss) - 75 (player)
    if massdiff > 925 then
        return false
    end

    -- When the player becomes a ghost his mass becomes 1. In that case, we just set the ceil
    -- difference to 10 (there is no point to push something with a mass higher than that) to allow
    -- pushing Frogs, Saladmanders and Critters as they all have a mass of 1.
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

local function GetDefaultMethodNextPosition(self, target)
    local pos = self.leaderpositions[1]

    if pos then
        local distinstsq = self.inst:GetDistanceSqToPoint(pos)
        local distinst = math.sqrt(distinstsq)

        -- This represents the distance where the gathered points (leaderpositions) will be
        -- ignored/removed. There is no real point to step on each coordinate and we still need to
        -- remove the past ones. Smaller value gives more precision, especially near the corners.
        -- However, when lag compensation is off the movement becomes less smooth. I don't recommend
        -- using anything < 1 diameter.
        local step = self.inst.Physics:GetRadius() * 3
        local isleadernear = self.inst:IsNear(self.leader, target + step)

        if not self.isleadernear and isleadernear or (isleadernear and self.configkeeptargetdistance) then
            self.leaderpositions = {}
            return self.inst:GetPositionAdjacentTo(self.leader, target)
        end

        if not isleadernear and distinst > step then
            return pos
        else
            table.remove(self.leaderpositions, 1)
            pos = GetDefaultMethodNextPosition(self, target)
            return pos
        end
    end

    return nil
end

local function GetClosestMethodNextPosition(self, target, isleadernear)
    if not isleadernear or self.configkeeptargetdistance then
        local pos = self.inst:GetPositionAdjacentTo(self.leader, target)

        if IsPassable(pos) then
            return pos
        end

        if self:IsLeaderOnPlatform() ~= self:IsOnPlatform() then
            pos = GetClosestPosition(self.inst, self.leader)
        end

        return pos
    end

    return nil
end

function KeepFollowing:IsFollowing()
    return self.leader and self.isfollowing
end

function KeepFollowing:StartFollowingThread()
    self.threadfollowing = StartThread(function()
        local pos, previouspos, isleadernear
        local buffered, previousbuffered
        local pauseaction, pauseactiontime
        local retry

        local retryframes = 0
        local radiusinst = self.inst.Physics:GetRadius()
        local radiusleader = self.leader.Physics:GetRadius()
        local target = self.configtargetdistance + radiusinst + radiusleader

        self.isfollowing = true
        self.starttime = os.clock()

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

            buffered = self.inst:GetBufferedAction()

            if buffered and buffered.action ~= ACTIONS.WALKTO then
                if not previousbuffered or buffered ~= previousbuffered then
                    DebugTheadString("Interrupted by action:", buffered.action.id)
                    pauseaction, pauseactiontime = GetPauseAction(buffered.action)

                    if pauseaction then
                        self.ispaused = true
                        DebugTheadString(string.format("Pausing (%2.2f)...", pauseactiontime))
                        Sleep(FRAMES / FRAMES * pauseactiontime)
                    end

                    previousbuffered = buffered
                end
            elseif not self:IsMovementPredictionEnabled() then
                -- When movement prediction is disabled the buffered action will be nil. In that
                -- case, we use the default sleep time and just rely on IsBusy() functions.
                if self.playercontroller:IsBusy() or self.inst.replica.builder:IsBusy() then
                    self.ispaused = true
                    pauseactiontime = 1.25 -- default
                    DebugTheadString(string.format("Pausing (%2.2f)...", pauseactiontime))
                    Sleep(FRAMES / FRAMES * pauseactiontime)
                end
            end

            if self.ispaused
                and not self.playercontroller:IsBusy()
                and not self.inst.replica.builder:IsBusy()
            then
                self.ispaused = false
                DebugTheadString("Unpausing...")
            end

            isleadernear = self.inst:IsNear(self.leader, target)

            if not self.ispaused and self.configfollowingmethod == "default" then
                -- default: player follows a leader step-by-step
                pos = GetDefaultMethodNextPosition(self, target)
                if pos and (not previouspos or pos ~= previouspos) then
                    WalkToPosition(self, pos)
                    previouspos = pos
                    retry = false
                    retryframes = 0

                    if _DEBUG_FN then
                        self.debugrequests = self.debugrequests + 1
                    end
                elseif not retry and pos and pos == previouspos then
                    -- In some cases, the WalkToPosition() doesn't trigger movement and I don't know
                    -- why yet. So we try sending the walking request once again (still better than
                    -- sending a request on each frame).
                    retryframes = retryframes + 1

                    -- 0.5 sec
                    if retryframes * FRAMES > .5 then
                        WalkToPosition(self, pos)
                        previouspos = pos
                        retry = true

                        if _DEBUG_FN then
                            self.debugrequests = self.debugrequests + 1
                        end
                    end
                elseif retry and #self.leaderpositions > 1 and pos and pos == previouspos then
                    -- after the retry, if the position didn't change then most likely we are
                    -- dealing with an invalid one
                    table.remove(self.leaderpositions, 1)
                end
            elseif not self.ispaused and self.configfollowingmethod == "closest" then
                -- closest: player goes to the closest target point from a leader
                pos = GetClosestMethodNextPosition(self, target, isleadernear)
                if pos and (not previouspos or GetDistSqBetweenPositions(pos, previouspos) > .1) then
                    WalkToPosition(self, pos)
                    previouspos = pos

                    if _DEBUG_FN then
                        self.debugrequests = self.debugrequests + 1
                    end
                end
            end

            self.isleadernear = isleadernear

            Sleep(FRAMES)
        end

        self:ClearFollowingThread()
    end, _FOLLOWING_THREAD_ID)
end

function KeepFollowing:ClearFollowingThread()
    if self.threadfollowing then
        DebugString("[" .. self.threadfollowing.id .. "]", "Thread cleared")
        KillThreadsWithID(self.threadfollowing.id)
        self.threadfollowing:SetList(nil)
        self.threadfollowing = nil
    end
end

function KeepFollowing:StartPathThread()
    self.threadpath = StartThread(function()
        local pos, previouspos

        DebugTheadString("Started gathering path coordinates...")

        while self.inst and self.inst:IsValid() and self:IsFollowing() do
            if not self.leader or not self.leader.entity:IsValid() then
                DebugTheadString("Leader doesn't exist anymore")
                self:StopFollowing()
                return
            end

            pos = self.leader:GetPosition()

            if self:IsLeaderOnPlatform() ~= self:IsOnPlatform() then
                pos = GetClosestPosition(self.inst, self.leader)
            end

            if not previouspos then
                table.insert(self.leaderpositions, pos)
                previouspos = pos
            end

            if IsPassable(pos) == IsPassable(previouspos) then
                -- 1 is the most optimal value so far
                if GetDistBetweenPositions(pos, previouspos) > 1
                    and pos ~= previouspos
                    and self.leaderpositions[#self.leaderpositions] ~= pos
                then
                    table.insert(self.leaderpositions, pos)
                    previouspos = pos
                end
            end

            Sleep(FRAMES)
        end

        self:ClearPathThread()
    end, _PATH_THREAD_ID)
end

function KeepFollowing:ClearPathThread()
    if self.threadpath then
        DebugString("[" .. self.threadpath.id .. "]", "Thread cleared")
        KillThreadsWithID(self.threadpath.id)
        self.threadpath:SetList(nil)
        self.threadpath = nil
    end
end

function KeepFollowing:StartFollowing(leader)
    if self.configpushlagcompensation and not self.ismastersim then
        MovementPredictionOnFollow(self)
    end

    self:SetLeader(leader)
    self:StartFollowingThread()
end

function KeepFollowing:StopFollowing()
    if self.leader then
        DebugString(string.format(
            "[%s] Stopped following %s. Requests: %d. Time: %f",
            self.threadfollowing.id,
            self.leader:GetDisplayName(),
            self.debugrequests,
            os.clock() - self.starttime
        ))

        self.debugrequests = 0
        self.isfollowing = false
        self.leader = nil
        self.leaderpositions = {}
        self.starttime = nil
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

function KeepFollowing:StartPushingThread()
    self.threadpushing = StartThread(function()
        self.ispushing = true
        self.starttime = os.clock()

        DebugTheadString("Started pushing leader")

        while self.inst and self.inst:IsValid() and self:IsPushing() do
            if not self.leader or not self.leader.entity:IsValid() then
                DebugTheadString("Leader doesn't exist anymore")
                self:StopPushing()
                return
            end

            WalkToPosition(self, self.leader:GetPosition())

            if _DEBUG_FN then
                self.debugrequests = self.debugrequests + 1
            end

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

function KeepFollowing:StartPushing(leader)
    if self.configpushlagcompensation and not self.ismastersim then
        MovementPredictionOnPush(self)
    end

    self:SetLeader(leader)
    self:StartPushingThread()
end

function KeepFollowing:StopPushing()
    if self.configpushlagcompensation and not self.ismastersim then
        MovementPredictionOnStop(self)
    end

    if self.leader then
        DebugString(string.format(
            "[%s] Stopped pushing %s. Requests: %d. Time: %f",
            self.threadpushing.id,
            self.leader:GetDisplayName(),
            self.debugrequests,
            os.clock() - self.starttime
        ))

        self.debugrequests = 0
        self.ispushing = false
        self.leader = nil
        self.starttime = nil
        self:ClearPushingThread()
    end
end

return KeepFollowing
