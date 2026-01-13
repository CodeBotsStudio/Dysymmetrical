local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Item = require(ReplicatedStorage.Classes.Item)
local Types = require(ReplicatedStorage.Classes.Types)
local CommonFunctions = RunService:IsServer() and require(game:GetService("ServerScriptService").System.CommonFunctions) or nil
local PlayerSpeedManager = RunService:IsServer() and require(game:GetService("ServerScriptService").Managers.PlayerManager.PlayerSpeedManager) or nil

return Item.New({
    Name = "Bloxy Cola",
    ToolPrefab = script:FindFirstChild("Cola"),

    Behaviour = function(self: Types.Item)
        if not RunService:IsServer() then
            return
        end
        
        PlayerSpeedManager.AddSpeedFactor(self.Owner, "ColaDrink", 0.3)
        self:AddUseConnection(task.delay(4, function()
            PlayerSpeedManager.RemoveSpeedFactor(self.Owner, "ColaDrink")
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
    end,

    OnUnequip = function(self: Types.Item)
        if RunService:IsServer() then
            return
        end

        PlayerSpeedManager.RemoveSpeedFactor(self.Owner, "ColaDrink")
    end,
})