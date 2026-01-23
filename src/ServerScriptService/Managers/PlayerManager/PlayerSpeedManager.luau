local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)

local PlayerSpeedManager = {
    ManagedPlayers = {},
}

function PlayerSpeedManager:Init()
    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveCharacter(Player, function(Character: Model, CharacterJanitor: Types.Janitor)
            PlayerSpeedManager.ManagedPlayers[Player] = {
                Factors = {},
                LastMultiplier = 1,
                CanSprint = true,
            }

            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

            CharacterJanitor:Add(RunService.PreSimulation:Connect(function(_delta: number)
                if not (Character and Character.Parent and Humanoid) then
                    return
                end

                --[[local CurrentSpeed = Character:GetAttribute("BaseSpeed")
                if CurrentSpeed == nil then
                    CurrentSpeed = 10.5
                end]]
				
				local CurrentSpeed = Character:GetAttribute("BaseSpeed")
				if CurrentSpeed == nil then
					local fallBackSpeed = 10.5
					local charName = Character:GetAttribute("CharacterName")
					local charSkin = Character:GetAttribute("CharacterSkinName")
					local roleValue
					if Character:FindFirstChild("Role") then
						roleValue = Character.Role.Value
					end
					
					if roleValue and charName and #charName > 0 then
						local moduleInstance = Utils.Instance.GetCharacterModule(roleValue, charName, charName)
						if moduleInstance then
							local success, mod = pcall(require, moduleInstance)
							if success and mod.GameplayConfig and type(mod.GameplayConfig.BaseSpeed) == "number" then
								fallBackSpeed = mod.GameplayConfig.BaseSpeed
							end
						end
					end
					
					CurrentSpeed = fallBackSpeed
				end

                local TotalFactor = 1
                for _, factor in PlayerSpeedManager.ManagedPlayers[Player].Factors do
                    TotalFactor *= factor
                end

                CurrentSpeed *= TotalFactor
                Humanoid.WalkSpeed = CurrentSpeed
                
                PlayerSpeedManager.ManagedPlayers[Player].LastMultiplier = TotalFactor
            end))
            CharacterJanitor:Add(function()
                PlayerSpeedManager.ManagedPlayers[Player] = nil
            end, true)
        end)
    end)
end

function PlayerSpeedManager.AddSpeedFactor(Player: Player, FactorName: string, FactorMult: number)
    if not PlayerSpeedManager.ManagedPlayers[Player] then
        local Timeout = 0
        repeat
            task.wait()
            Timeout += 1
        until PlayerSpeedManager.ManagedPlayers[Player] or Timeout >= 50
        if Timeout >= 50 then
            return
        end
    end

    PlayerSpeedManager.ManagedPlayers[Player].Factors[FactorName] = FactorMult
end

function PlayerSpeedManager.RemoveSpeedFactor(Player: Player, FactorName: string)
    if not PlayerSpeedManager.ManagedPlayers[Player] then
        local Timeout = 0
        repeat
            task.wait()
            Timeout += 1
        until PlayerSpeedManager.ManagedPlayers[Player] or Timeout >= 50
        if Timeout >= 50 then
            return
        end
    end

    PlayerSpeedManager.ManagedPlayers[Player].Factors[FactorName] = nil
end

return PlayerSpeedManager
