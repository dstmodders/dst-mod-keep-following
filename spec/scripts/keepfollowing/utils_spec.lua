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

    describe("general", function()
        describe("IsHUDFocused", function()
            local player

            before_each(function()
                player = {
                    HUD = {
                        HasInputFocus = spy.new(ReturnValueFn(true)),
                    },
                }
            end)

            describe("when some chain fields are missing", function()
                it("should return true", function()
                    AssertChainNil(function()
                        assert.is_true(Utils.IsHUDFocused(player))
                    end, player, "HUD", "HasInputFocus")
                end)
            end)

            describe("when player.HUD:HasInputFocus()", function()
                local function AssertCall()
                    it("should call player.HUD:HasInputFocus()", function()
                        assert.spy(player.HUD.HasInputFocus).was_called(0)
                        Utils.IsHUDFocused(player)
                        assert.spy(player.HUD.HasInputFocus).was_called(1)
                        assert.spy(player.HUD.HasInputFocus).was_called_with(
                            match.is_ref(player.HUD)
                        )
                    end)
                end

                describe("returns true", function()
                    before_each(function()
                        player.HUD.HasInputFocus = spy.new(ReturnValueFn(true))
                    end)

                    AssertCall()

                    it("should return false", function()
                        assert.is_false(Utils.IsHUDFocused(player))
                    end)
                end)

                describe("returns false", function()
                    before_each(function()
                        player.HUD.HasInputFocus = spy.new(ReturnValueFn(false))
                    end)

                    AssertCall()

                    it("should return true", function()
                        assert.is_true(Utils.IsHUDFocused(player))
                    end)
                end)
            end)
        end)
    end)

    describe("locomotor", function()
        local pt

        before_each(function()
            pt = Vector3(1, 0, 1)
        end)

        describe("IsLocomotorAvailable", function()
            local player

            before_each(function()
                player = {
                    components = {
                        locomotor = {},
                    },
                }
            end)

            describe("when some chain fields are missing", function()
                it("should return false", function()
                    AssertChainNil(function()
                        assert.is_false(Utils.IsLocomotorAvailable(player))
                    end, player, "components", "locomotor")
                end)
            end)

            describe("when the locomotor component is available", function()
                it("should return true", function()
                    assert.is_true(Utils.IsLocomotorAvailable(player))
                end)
            end)

            describe("when the locomotor component is not available", function()
                before_each(function()
                    player.components.locomotor = nil
                end)

                it("should return true", function()
                    assert.is_false(Utils.IsLocomotorAvailable(player))
                end)
            end)
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

    describe("modmain", function()
        describe("HideChangelog", function()
            before_each(function()
                _G.KnownModIndex = {
                    GetModInfo = spy.new(Empty),
                }
            end)

            after_each(function()
                Utils.HideChangelog(nil, false)
            end)

            teardown(function()
                _G.KnownModIndex = nil
            end)

            describe("when no modname is passed", function()
                describe("and enabling", function()
                    it("shouldn't override KnownModIndex:GetModInfo()", function()
                        local old = _G.KnownModIndex.GetModInfo
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                        Utils.HideChangelog(nil, true)
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                    end)

                    it("should return false", function()
                        assert.is_false(Utils.HideChangelog(nil, true))
                    end)
                end)

                describe("and disabling", function()
                    it("shouldn't override KnownModIndex:GetModInfo()", function()
                        local old = _G.KnownModIndex.GetModInfo
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                        Utils.HideChangelog(nil, false)
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                    end)

                    it("should return false", function()
                        assert.is_false(Utils.HideChangelog(nil, false))
                    end)
                end)
            end)

            describe("when modname is passed", function()
                local modname

                before_each(function()
                    modname = "dst-mod-keep-following"
                end)

                describe("and enabling", function()
                    it("should override KnownModIndex:GetModInfo()", function()
                        local old = _G.KnownModIndex.GetModInfo
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                        Utils.HideChangelog(modname, true)
                        assert.is_not_equal(old, _G.KnownModIndex.GetModInfo)
                    end)

                    it("should return true", function()
                        assert.is_true(Utils.HideChangelog(modname, true))
                    end)
                end)

                describe("and disabling", function()
                    it("shouldn't override KnownModIndex:GetModInfo()", function()
                        local old = _G.KnownModIndex.GetModInfo
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                        Utils.HideChangelog(modname, false)
                        assert.is_equal(old, _G.KnownModIndex.GetModInfo)
                    end)

                    it("should return false", function()
                        assert.is_false(Utils.HideChangelog(modname, false))
                    end)
                end)
            end)
        end)
    end)
end)
