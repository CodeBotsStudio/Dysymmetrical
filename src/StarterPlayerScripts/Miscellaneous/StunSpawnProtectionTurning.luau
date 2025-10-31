local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_self)
        local Conns: {[string]: RBXScriptConnection} = {}
        
        local function SetupCharacter(Player: Player, Char: Model)
            if Conns[Player.Name] then
                Conns[Player.Name]:Disconnect()
            end

            local Role = Utils:FindFirstChild(Char, "Role")
            if Role.Value == "Killer" then
                local Label = Utils:FindFirstChild(Char, "HumanoidRootPart.StunSpawnProtection.ImageLabel")

                Conns[Player.Name] = RunService.PreRender:Connect(function(delta: number)
                    Label.Rotation += delta * 24
                end)
            end
        end

        local function SetupPlayer(Player: Player)
            Player.CharacterAdded:Connect(function(Char: Model)
                SetupCharacter(Player, Char)
            end)
            if Player.Character then
                SetupCharacter(Player, Player.Character)
            end
        end

        Players.PlayerAdded:Connect(SetupPlayer)
        for _, i in Players:GetPlayers() do
            SetupPlayer(i)
        end

        Players.PlayerRemoving:Connect(function(Player: Player)
            if Conns[Player.Name] then
                Conns[Player.Name]:Disconnect()
            end
        end)
    end,
}