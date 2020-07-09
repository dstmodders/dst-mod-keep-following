require "busted.runner"()

describe("KeepFollowing", function()
    -- setup
    local match

    -- before_each initialization
    local inst
    local KeepFollowing, keepfollowing

    setup(function()
        -- match
        match = require "luassert.match"

        -- debug
        DebugSpyTerm()
        DebugSpyInit(spy)
    end)

    teardown(function()
        -- debug
        DebugSpyTerm()

        -- globals
        _G.ACTIONS = nil
        _G.TheWorld = nil
    end)

    before_each(function()
        -- globals
        _G.ACTIONS = {}
        _G.TheWorld = mock({
            Map = {
                GetPlatformAtPoint = ReturnValueFn({}),
            },
        })

        -- initialization
        inst = mock({
            GetPosition = ReturnValueFn({
                Get = ReturnValuesFn(1, 0, -1),
            }),
            StartUpdatingComponent = Empty,
        })

        KeepFollowing = require "components/keepfollowing"
        keepfollowing = KeepFollowing(inst)

        -- debug
        DebugSpyClear()
    end)

    insulate("initialization", function()
        before_each(function()
            -- initialization
            inst = {
                StartUpdatingComponent = spy.new(Empty),
            }

            KeepFollowing = require "components/keepfollowing"
            keepfollowing = KeepFollowing(inst)
        end)

        local function AssertDefaults(self)
            -- general
            assert.is_equal(inst, self.inst)
            assert.is_false(self.isclient)
            assert.is_false(self.isdst)
            assert.is_equal(_G.TheWorld.ismastersim, self.ismastersim)
            assert.is_nil(self.leader)
            assert.is_nil(self.movementpredictionstate)
            assert.is_nil(self.playercontroller)
            assert.is_nil(self.starttime)
            assert.is_equal(_G.TheWorld, self.world)

            -- following
            assert.is_false(self.isfollowing)
            assert.is_false(self.isleadernear)
            assert.is_false(self.ispaused)
            assert.is_same({}, self.leaderpositions)
            assert.is_nil(self.threadfollowing)
            assert.is_nil(self.threadpath)

            -- pushing
            assert.is_false(self.ispushing)
            assert.is_nil(self.threadpushing)

            -- upvalues
            assert.is_nil(self.weathermoisturefloor)
            assert.is_nil(self.weathermoisturerate)
            assert.is_nil(self.weatherpeakprecipitationrate)
            assert.is_nil(self.weatherwetrate)
        end

        describe("using the constructor", function()
            before_each(function()
                keepfollowing = KeepFollowing(inst)
            end)

            it("should have the default fields", function()
                AssertDefaults(keepfollowing)
            end)
        end)

        describe("using the DoInit()", function()
            before_each(function()
                KeepFollowing:DoInit(inst)
            end)

            it("should have the default fields", function()
                AssertDefaults(KeepFollowing)
            end)
        end)
    end)

    describe("general", function()
        describe("IsOnPlatform", function()
            describe("when the self.world is set", function()
                local GetPlatformAtPoint

                before_each(function()
                    GetPlatformAtPoint = keepfollowing.world.Map.GetPlatformAtPoint
                end)

                it("should call the self.world.Map.GetPlatformAtPoint()", function()
                    assert.spy(GetPlatformAtPoint).was_called(0)
                    keepfollowing:IsOnPlatform()
                    assert.spy(GetPlatformAtPoint).was_called(1)
                    assert.spy(GetPlatformAtPoint).was_called_with(
                        match.is_ref(keepfollowing.world.Map),
                        1,
                        0,
                        -1
                    )
                end)
            end)

            describe("when the self.inst is set", function()
                local GetPosition

                before_each(function()
                    GetPosition = keepfollowing.inst.GetPosition
                end)

                it("should call the self.inst.GetPosition()", function()
                    assert.spy(GetPosition).was_called(0)
                    keepfollowing:IsOnPlatform()
                    assert.spy(GetPosition).was_called(1)
                    assert.spy(GetPosition).was_called_with(match.is_ref(keepfollowing.inst))
                end)

                it("should return true", function()
                    assert.is_true(keepfollowing:IsOnPlatform())
                end)
            end)
        end)
    end)
end)
