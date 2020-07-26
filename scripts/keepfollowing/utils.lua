----
-- Different global utilities.
--
-- Most of them are expected to be used in the gameplay console.
--
-- **Source Code:** [https://github.com/victorpopkov/dst-mod-keep-following](https://github.com/victorpopkov/dst-mod-keep-following)
--
-- @module Utils
-- @author Victor Popkov
-- @copyright 2019
-- @license MIT
-- @release 0.20.0-beta
----
local Utils = {}

--
-- Helpers
--

local function DebugString(...)
    return _G.KeepFollowingDebug and _G.KeepFollowingDebug:DebugString(...)
end

--
-- Debugging
--

--- Adds debug methods to the destination class.
--
-- Checks the global environment if the `KeepFollowingDebug` (`Debug`) is available and adds the
-- corresponding methods from there. Otherwise, adds all the corresponding functions as empty ones.
--
-- @tparam table dest Destination class
function Utils.AddDebugMethods(dest)
    local methods = {
        "DebugError",
        "DebugInit",
        "DebugString",
        "DebugStringStart",
        "DebugStringStop",
        "DebugTerm",
    }

    if _G.KeepFollowingDebug then
        for _, v in pairs(methods) do
            dest[v] = function(_, ...)
                if _G.KeepFollowingDebug and _G.KeepFollowingDebug[v] then
                    return _G.KeepFollowingDebug[v](_G.KeepFollowingDebug, ...)
                end
            end
        end
    else
        for _, v in pairs(methods) do
            dest[v] = function()
            end
        end
    end
end

--
-- Chain
--

--- Gets chained field.
--
-- Simplifies the last chained field retrieval like:
--
--    return TheWorld
--        and TheWorld.net
--        and TheWorld.net.components
--        and TheWorld.net.components.shardstate
--        and TheWorld.net.components.shardstate.GetMasterSessionId
--        and TheWorld.net.components.shardstate:GetMasterSessionId
--
-- Or it's value:
--
--    return TheWorld
--        and TheWorld.net
--        and TheWorld.net.components
--        and TheWorld.net.components.shardstate
--        and TheWorld.net.components.shardstate.GetMasterSessionId
--        and TheWorld.net.components.shardstate:GetMasterSessionId()
--
-- It also supports net variables and tables acting as functions.
--
-- @usage Utils.ChainGet(TheWorld, "net", "components", "shardstate", "GetMasterSessionId") -- (function) 0x564445367790
-- @usage Utils.ChainGet(TheWorld, "net", "components", "shardstate", "GetMasterSessionId", true) -- (string) D000000000000000
-- @tparam table src
-- @tparam string|boolean ...
-- @treturn function|userdata|table
function Utils.ChainGet(src, ...)
    if src and (type(src) == "table" or type(src) == "userdata") then
        local args = { ... }
        local execute = false

        if args[#args] == true then
            table.remove(args, #args)
            execute = true
        end

        local previous = src
        for i = 1, #args do
            if src[args[i]] then
                previous = src
                src = src[args[i]]
            else
                return
            end
        end

        if execute and previous then
            if type(src) == "function" then
                return src(previous)
            elseif type(src) == "userdata" or type(src) == "table" then
                if type(src.value) == "function" then
                    -- netvar
                    return src:value()
                elseif getmetatable(src.value) and getmetatable(src.value).__call then
                    -- netvar (for testing)
                    return src.value(src)
                elseif getmetatable(src) and getmetatable(src).__call then
                    -- table acting as a function
                    return src(previous)
                end
            end
            return
        end

        return src
    end
end

--- Validates chained fields.
--
-- Simplifies the chained fields checking like below:
--
--    return TheWorld
--        and TheWorld.net
--        and TheWorld.net.components
--        and TheWorld.net.components.shardstate
--        and TheWorld.net.components.shardstate.GetMasterSessionId
--        and true
--        or false
--
-- @usage Utils.ChainValidate(TheWorld, "net", "components", "shardstate", "GetMasterSessionId") -- (boolean) true
-- @tparam table src
-- @tparam string|boolean ...
-- @treturn boolean
function Utils.ChainValidate(src, ...)
    return Utils.ChainGet(src, ...) and true or false
end

--
-- Thread
--

--- Starts a new thread.
--
-- Just a convenience wrapper for the `StartThread`.
--
-- @tparam string id Thread ID
-- @tparam function fn Thread function
-- @tparam function whl While function
-- @tparam[opt] function init Initialization function
-- @tparam[opt] function term Termination function
-- @treturn table
function Utils.ThreadStart(id, fn, whl, init, term)
    return StartThread(function()
        DebugString("Thread started")
        if init then
            init()
        end
        while whl() do
            fn()
        end
        if term then
            term()
        end
        Utils.ThreadClear()
    end, id)
end

--- Clears a thread.
-- @tparam table thread Thread
function Utils.ThreadClear(thread)
    local task = scheduler:GetCurrentTask()
    if thread or task then
        if thread and not task then
            DebugString("[" .. thread.id .. "]", "Thread cleared")
        else
            DebugString("Thread cleared")
        end

        thread = thread ~= nil and thread or task
        KillThreadsWithID(thread.id)
        thread:SetList(nil)
        thread = nil -- luacheck: only
    end
end

return Utils
