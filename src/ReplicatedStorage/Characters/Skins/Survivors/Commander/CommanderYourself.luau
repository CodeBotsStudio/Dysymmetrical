--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Character = require(ReplicatedStorage.Classes.Character)
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)

local CommanderYourself: Character.Survivor = CommonUtils:CopyTable(require(CommonUtils:GetCharacterModule("Survivor", "Commander")))
CommanderYourself.Config.Name = "Yourself"
CommanderYourself.Config.Quote = "Hey, it's you!"
CommanderYourself.Config.Price = 99999999 --to appear at the end of the list

CommanderYourself.OnInit = function(self: Character.Survivor, Char: Model)
    if not RunService:IsServer() then
        return
    end

    CommonUtils:FindFirstChild(Char, "Humanoid"):ApplyDescription(Players:GetHumanoidDescriptionFromUserId(self.Owner.UserId))
end

return CommanderYourself
