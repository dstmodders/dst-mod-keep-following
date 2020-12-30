require "busted.runner"()

describe("Utils", function()
    -- setup
    local match

    -- before_each initialization
    local Utils

    setup(function()
        -- match
        match = require "luassert.match"

        -- debug
        DebugSpyInit()

        -- globals
        _G.ACTIONS = {
            WALKTO = { code = 163 },
        }

        _G.RPC = {
            DirectWalking = 16,
            LeftClick = 26,
            StopWalking = 46,
        }
    end)

    teardown(function()
        -- debug
        DebugSpyTerm()

        -- globals
        _G.ACTIONS = nil
        _G.BufferedAction = nil
        _G.RPC = nil
        _G.SendRPCToServer = nil
    end)

    before_each(function()
        -- globals
        _G.BufferedAction = spy.new(ReturnValueFn({}))
        _G.SendRPCToServer = spy.new(Empty)

        -- initialization
        Utils = require "keepfollowing/utils"

        DebugSpyClear()
    end)

    describe("locomotor", function()
        local pt

        before_each(function()
            pt = Vector3(1, 0, 1)
        end)

        describe("WalkToPoint", function()
            local player

            before_each(function()
                player = {
                    components = {
                        playercontroller = {
                            locomotor = {},
                            DoAction = spy.new(Empty),
                        },
                    },
                }
            end)

            describe("when the player controller is available", function()
                describe("and the locomotor component is available", function()
                    it("should call player.components.playercontroller:DoAction()", function()
                        assert.spy(player.components.playercontroller.DoAction).was_called(0)
                        Utils.WalkToPoint(player, pt)
                        assert.spy(player.components.playercontroller.DoAction).was_called(1)
                        assert.spy(player.components.playercontroller.DoAction).was_called_with(
                            match.is_ref(player.components.playercontroller),
                            {}
                        )
                    end)

                    it("shouldn't call SendRPCToServer()", function()
                        assert.spy(_G.SendRPCToServer).was_called(0)
                        Utils.WalkToPoint(player, pt)
                        assert.spy(_G.SendRPCToServer).was_called(0)
                    end)
                end)

                describe("and the locomotor component is not available", function()
                    before_each(function()
                        player.components.playercontroller.locomotor = nil
                    end)

                    it("should call SendRPCToServer()", function()
                        assert.spy(_G.SendRPCToServer).was_called(0)
                        Utils.WalkToPoint(player, pt)
                        assert.spy(_G.SendRPCToServer).was_called(1)
                        assert.spy(_G.SendRPCToServer).was_called_with(
                            _G.RPC.LeftClick,
                            _G.ACTIONS.WALKTO.code,
                            1,
                            1
                        )
                    end)
                end)
            end)

            describe("when the player controller is not available", function()
                before_each(function()
                    player.components.playercontroller = nil
                end)
            end)
        end)
    end)
end)
