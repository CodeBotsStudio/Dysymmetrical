local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Item = require(ReplicatedStorage.Classes.Item)
local Types = require(ReplicatedStorage.Classes.Types)

return Item.New({
    Name = "Medkit",
    ToolPrefab = script:FindFirstChild("Medkit"),

    Behaviour = function(self: Types.Item)
        if RunService:IsServer() then
            self:AddUseConnection(task.delay(6, function()
                self.OwnerProperties.Humanoid.Health += 80
                self.ToolInstance:Destroy()
            end))

            return
        end

        self.OwnerProperties.SpeedManager:AddSpeedFactor("MedkitUse", 0.2)
        self:AddUseConnection(task.delay(6, function()
            self.OwnerProperties.SpeedManager:RemoveSpeedFactor("MedkitUse")
        end))
    end,

    OnUnequip = function(self: Types.Item)
        if RunService:IsServer() then
            return
        end

        self.OwnerProperties.SpeedManager:RemoveSpeedFactor("MedkitUse")
    end,
})