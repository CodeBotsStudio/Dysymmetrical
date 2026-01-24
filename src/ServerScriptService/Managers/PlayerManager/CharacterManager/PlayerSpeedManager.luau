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
				
				local CurrentSpeed = Character:GetAttribute("BaseSpeed")
				if CurrentSpeed == nil then
					local fallBackSpeed = 10.5
					local charName = Character:GetAttribute("CharacterName")
					local roleValue = Character:GetAttribute("Role")
					
					if roleValue and charName and #charName > 0 then
						local moduleInstance = Utils.Instance.GetCharacterModule(roleValue, charName, Character:GetAttribute("CharacterSkinName"))
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

function PlayerSpeedManager.AddFactor(Player: Player, Name: string, Mult: number)
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

    PlayerSpeedManager.ManagedPlayers[Player].Factors[Name] = Mult
end

function PlayerSpeedManager.RemoveFactor(Player: Player, Name: string)
    if not PlayerSpeedManager.ManagedPlayers[Player] then
        return
    end

    PlayerSpeedManager.ManagedPlayers[Player].Factors[Name] = nil
end

return PlayerSpeedManager
