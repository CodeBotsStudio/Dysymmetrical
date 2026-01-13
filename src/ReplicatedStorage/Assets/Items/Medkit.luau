local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Item = require(ReplicatedStorage.Classes.Item)
local Types = require(ReplicatedStorage.Classes.Types)
local PlayerSpeedManager = RunService:IsServer() and require(game:GetService("ServerScriptService").Managers.PlayerManager.PlayerSpeedManager) or nil

return Item.New({
    Name = "Medkit",
    ToolPrefab = script:FindFirstChild("Medkit"),

    Behaviour = function(self: Types.Item)
        if not RunService:IsServer() then
            return
        end

        PlayerSpeedManager.AddSpeedFactor(self.Owner, "MedkitUse", 0.2)
        self:AddUseConnection(task.delay(6, function()
            self.OwnerProperties.Humanoid.Health += 80
            self.ToolInstance:Destroy()
            PlayerSpeedManager.RemoveSpeedFactor(self.Owner, "MedkitUse")
        end))
    end,

    OnUnequip = function(self: Types.Item)
        if not RunService:IsServer() then
            return
        end

        PlayerSpeedManager.RemoveSpeedFactor(self.Owner, "MedkitUse")
    end,
})