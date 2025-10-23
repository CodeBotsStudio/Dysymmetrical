--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Character = require(ReplicatedStorage.Classes.Character)
local Utils = require(ReplicatedStorage.Modules.Utils)

local CommanderYourself: Character.Survivor = Utils:CopyTable(require(Utils:GetCharacterModule("Survivor", "Commander")))
CommanderYourself.Config.Name = "Yourself"
CommanderYourself.Config.Quote = "Hey, it's you!"
CommanderYourself.Config.Price = 99999999 --to appear at the end of the list

CommanderYourself.OnInit = function(self: Character.Survivor, Char: Model)
    if not RunService:IsServer() then
        return
    end

    Utils:FindFirstChild(Char, "Humanoid"):ApplyDescription(Players:GetHumanoidDescriptionFromUserId(self.Owner.UserId))
end

return CommanderYourself
