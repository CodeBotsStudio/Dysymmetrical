local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Character = require(ReplicatedStorage.Classes.Character)
local Types = require(ReplicatedStorage.Classes.Types)

local function OnCommanderInit(self: Types.Survivor, Char: Model)
    if not RunService:IsServer() then
        return
    end

    Char:FindFirstChildWhichIsA("Humanoid"):ApplyDescription(Players:GetHumanoidDescriptionFromUserIdAsync(self.Owner.UserId))
end

return Character.CreateSkin("Survivor", "Commander", {
    Config = {
        Name = "Yourself",
        Quote = "Hey, it's you!",
        Price = 99999999,

        Origin = {},
    },

    OnInit = OnCommanderInit,
})
