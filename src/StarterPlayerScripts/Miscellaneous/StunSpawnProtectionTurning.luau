local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_self)
        local Instances: {[string]: ImageLabel} = {}
        
        local function SetupCharacter(Player: Player, Char: Model)
            if Instances[Player.Name] then
                Instances[Player.Name] = nil
            end

            local Role = Utils:FindFirstChild(Char, "Role")
            if Role.Value == "Killer" then
                local Label = Utils:FindFirstChild(Char, "HumanoidRootPart.StunSpawnProtection.ImageLabel")
                if not Label then
                    return
                end

                Instances[Player.Name] = Label
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
            if Instances[Player.Name] then
                Instances[Player.Name] = nil
            end
        end)

        RunService.PreRender:Connect(function(delta: number)
            for _, Label in Instances do
                if not Label then
                    continue
                end

                Label.Rotation += delta * 24
            end
        end)
    end,
}