local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Item = require(ReplicatedStorage.Classes.Item)
local Types = require(ReplicatedStorage.Classes.Types)
local CommonFunctions = RunService:IsServer() and require(game:GetService("ServerScriptService").System.CommonFunctions) or nil

return Item.New({
    Name = "Bloxy Cola",
    ToolPrefab = script:FindFirstChild("Cola"),

    Behaviour = function(self: Types.Item)
        if RunService:IsServer() then
            self:AddUseConnection(task.delay(4, function()
                CommonFunctions.ApplyEffect({
                    TargetHumanoid = self.OwnerProperties.Humanoid,
                    EffectSettings = {
                        Name = "Speed",
                        Level = 2,
                        Duration = 10,
                    },
                    OverwriteExistingEffect = true,
                })
                self.ToolInstance:Destroy()
            end))

            return
        end

        self.OwnerProperties.SpeedManager:AddSpeedFactor("ColaDrink", 0.3)
        self:AddUseConnection(task.delay(4, function()
            self.OwnerProperties.SpeedManager:RemoveSpeedFactor("ColaDrink")
        end))
    end,

    OnUnequip = function(self: Types.Item)
        if RunService:IsServer() then
            return
        end

        self.OwnerProperties.SpeedManager:RemoveSpeedFactor("ColaDrink")
    end,
})