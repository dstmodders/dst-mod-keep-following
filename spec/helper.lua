--
-- Packages
--

require "spec/vector3"

local preloads = {
    ["sdk/config"] = "scripts/keepfollowing/sdk/sdk/config",
    ["sdk/console"] = "scripts/keepfollowing/sdk/sdk/console",
    ["sdk/constant"] = "scripts/keepfollowing/sdk/sdk/constant",
    ["sdk/debug"] = "scripts/keepfollowing/sdk/sdk/debug",
    ["sdk/debugupvalue"] = "scripts/keepfollowing/sdk/sdk/debugupvalue",
    ["sdk/dump"] = "scripts/keepfollowing/sdk/sdk/dump",
    ["sdk/entity"] = "scripts/keepfollowing/sdk/sdk/entity",
    ["sdk/input"] = "scripts/keepfollowing/sdk/sdk/input",
    ["sdk/inventory"] = "scripts/keepfollowing/sdk/sdk/inventory",
    ["sdk/modmain"] = "scripts/keepfollowing/sdk/sdk/modmain",
    ["sdk/persistentdata"] = "scripts/keepfollowing/sdk/sdk/persistentdata",
    ["sdk/player"] = "scripts/keepfollowing/sdk/sdk/player",
    ["sdk/rpc"] = "scripts/keepfollowing/sdk/sdk/rpc",
    ["sdk/thread"] = "scripts/keepfollowing/sdk/sdk/thread",
    ["sdk/utils"] = "scripts/keepfollowing/sdk/sdk/utils",
    ["sdk/utils/chain"] = "scripts/keepfollowing/sdk/sdk/utils/chain",
    ["sdk/utils/methods"] = "scripts/keepfollowing/sdk/sdk/utils/methods",
    ["sdk/utils/string"] = "scripts/keepfollowing/sdk/sdk/utils/string",
    ["sdk/utils/table"] = "scripts/keepfollowing/sdk/sdk/utils/table",
    ["sdk/world"] = "scripts/keepfollowing/sdk/sdk/world",
    class = "spec/class",
}

package.path = "./scripts/?.lua;" .. package.path
for k, v in pairs(preloads) do
    package.preload[k] = function()
        return require(v)
    end
end

--
-- SDK
--

_G.MODS_ROOT = "./"

function softresolvefilepath(filepath)
    return _G.MODS_ROOT .. filepath
end

local SDK

SDK = require "keepfollowing/sdk/sdk/sdk"
SDK.SetIsSilent(true).Load({
    modname = "dst-mod-dev-tools",
    AddPrefabPostInit = function() end
}, "keepfollowing/sdk", {
    "Config",
    "Debug",
    "DebugUpvalue",
    "Entity",
    "Input",
    "ModMain",
    "Player",
    "Thread",
    "World",
})

_G.SDK = SDK

--
-- General
--

function Empty()
end

function ReturnValues(...)
    return ...
end

function ReturnValueFn(value)
    return function()
        return value
    end
end

function ReturnValuesFn(...)
    local args = { ... }
    return function()
        return unpack(args)
    end
end

--
-- Debug
--

local _DEBUG_SPY = {}

function DebugSpy(name)
    for _name, method in pairs(_DEBUG_SPY) do
        if _name == name then
            return method
        end
    end
end

function DebugSpyAssert(name)
    local assert = require "luassert.assert"
    return assert.spy(DebugSpy(name))
end

function DebugSpyAssertWasCalled(name, calls, args)
    local match = require "luassert.match"
    calls = calls ~= nil and calls or 0
    args = args ~= nil and args or {}
    args = type(args) == "string" and { args } or args
    DebugSpyAssert(name).was_called(calls)
    if calls > 0 then
        DebugSpyAssert(name).was_called_with(match.is_not_nil(), unpack(args))
    end
end

function DebugSpyClear(name)
    if name ~= nil then
        for _name, method in pairs(_DEBUG_SPY) do
            if _name == name then
                method:clear()
                return
            end
        end
    end

    for _, method in pairs(_DEBUG_SPY) do
        method:clear()
    end
end

function DebugSpyInit()
    local spy = require "luassert.spy"
    local functions = {
        "Error",
        "Init",
        "ModConfigs",
        "String",
        "StringStart",
        "StringStop",
        "Term",
    }

    DebugSpyTerm()

    for _, fn in pairs(functions) do
        if SDK.Debug[fn] and not _DEBUG_SPY[fn] then
            _DEBUG_SPY[fn] = spy.new(Empty)
        end
    end

    SDK.Debug.AddMethods = function(self)
        for _, fn in pairs(functions) do
            if SDK.Debug[fn] and _DEBUG_SPY[fn] and not self["Debug" .. fn] then
                self["Debug" .. fn] = _DEBUG_SPY[fn]
                _DEBUG_SPY["Debug" .. fn] = self["Debug" .. fn]
            end
        end
    end
end

function DebugSpyTerm()
    for name, _ in pairs(_DEBUG_SPY) do
        _DEBUG_SPY[name] = nil
    end
end

--
-- Asserts
--

function AssertChainNil(fn, src, ...)
    if src and (type(src) == "table" or type(src) == "userdata") then
        local args = { ... }
        local start = src
        local previous, key

        for i = 1, #args do
            if start[args[i]] then
                previous = start
                key = args[i]
                start = start[key]
            end
        end

        if previous and src then
            previous[key] = nil
            args[#args] = nil
            fn()
            AssertChainNil(fn, src, unpack(args))
        end
    end
end

function AssertMethodExists(class, fn_name)
    local assert = require "busted".assert
    local classname = class.name ~= nil and class.name or "Class"
    assert.is_not_nil(
        class[fn_name],
        string.format("Function %s:%s() is missing", classname, fn_name)
    )
end

function AssertMethodIsMissing(class, fn_name)
    local assert = require "busted".assert
    local classname = class.name ~= nil and class.name or "Class"
    assert.is_nil(class[fn_name], string.format("Function %s:%s() exists", classname, fn_name))
end

function AssertGetter(class, field, fn_name, test_data)
    test_data = test_data ~= nil and test_data or "test"

    local assert = require "busted".assert
    AssertMethodExists(class, fn_name)
    local classname = class.name ~= nil and class.name or "Class"
    local fn = class[fn_name]

    local msg = string.format(
        "Getter %s:%s() doesn't return the %s.%s value",
        classname,
        fn_name,
        classname,
        field
    )

    assert.is_equal(class[field], fn(class), msg)
    class[field] = test_data
    assert.is_equal(test_data, fn(class), msg)
end

function AssertSetter(class, field, fn_name, test_data)
    test_data = test_data ~= nil and test_data or "test"

    local assert = require "busted".assert
    AssertMethodExists(class, fn_name)
    local classname = class.name ~= nil and class.name or "Class"
    local fn = class[fn_name]

    local msg = string.format(
        "Setter %s:%s() doesn't set the %s.%s value",
        classname,
        fn_name,
        classname,
        field
    )

    fn(class, test_data)
    assert.is_equal(test_data, class[field], msg)
end
