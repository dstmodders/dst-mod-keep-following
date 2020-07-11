--
-- Packages
--

local preloads = {
    class = "spec/class",
}

package.path = "./scripts/?.lua;" .. package.path
for k, v in pairs(preloads) do
    package.preload[k] = function()
        return require(v)
    end
end

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

function DebugSpyInit(spy)
    local methods = {
        "DebugError",
        "DebugInit",
        "DebugString",
        "DebugStringStart",
        "DebugStringStop",
        "DebugTerm",
    }

    _G.Debug = require "keepfollowing/debug"
    for _, method in pairs(methods) do
        if not _DEBUG_SPY[method] then
            _DEBUG_SPY[method] = spy.on(_G.Debug, method)
        end
    end
end

function DebugSpyTerm()
    for name, _ in pairs(_DEBUG_SPY) do
        _DEBUG_SPY[name] = nil
    end
    _G.Debug = nil
end

function DebugSpyClear(name)
    if name ~= nil then
        for _name, method in pairs(_DEBUG_SPY) do
            if _name == name then
                method:clear()
            end
        end
    else
        for _, method in pairs(_DEBUG_SPY) do
            method:clear()
        end
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
    local assert = require 'busted'.assert
    local classname = class.name ~= nil and class.name or "Class"
    assert.is_not_nil(
        class[fn_name],
        string.format("Function %s:%s() is missing", classname, fn_name)
    )
end

function AssertMethodIsMissing(class, fnname)
    local assert = require 'busted'.assert
    local classname = class.name ~= nil and class.name or "Class"
    assert.is_nil(class[fnname], string.format("Function %s:%s() exists", classname, fnname))
end

function AssertGetter(class, field, fnname, testdata)
    testdata = testdata ~= nil and testdata or "test"

    local assert = require 'busted'.assert
    AssertMethodExists(class, fnname)
    local classname = class.name ~= nil and class.name or "Class"
    local fn = class[fnname]

    local msg = string.format(
        "Getter %s:%s() doesn't return the %s.%s value",
        classname,
        fnname,
        classname,
        field
    )

    assert.is_equal(class[field], fn(class), msg)
    class[field] = testdata
    assert.is_equal(testdata, fn(class), msg)
end

function AssertSetter(class, field, fnname, testdata)
    testdata = testdata ~= nil and testdata or "test"

    local assert = require 'busted'.assert
    AssertMethodExists(class, fnname)
    local classname = class.name ~= nil and class.name or "Class"
    local fn = class[fnname]

    local msg = string.format(
        "Setter %s:%s() doesn't set the %s.%s value",
        classname,
        fnname,
        classname,
        field
    )

    fn(class, testdata)
    assert.is_equal(testdata, class[field], msg)
end
