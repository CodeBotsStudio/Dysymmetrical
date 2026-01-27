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
            --oop is cool
            PlayerSpeedManager.ManagedPlayers[Player] = {
                Factors = {},
                LastMultiplier = 1,
                CanSprint = true,
            }

            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

            --add renderstepped to janitor
            CharacterJanitor:Add(RunService.PreSimulation:Connect(function(_delta: number)
                --if the character isn't in the world, halt
                if not (Character and Character.Parent and Humanoid) then
                    return
                end
				
                --get the base speed
				local CurrentSpeed = Character:GetAttribute("BaseSpeed")
                --if it's nil, get the fallback
				if CurrentSpeed == nil then
                    --by default it's 10.5
					local fallBackSpeed = 10.5
                    --getting necessary stuff for getting the character module
					local charName = Character:GetAttribute("CharacterName")
					local roleValue = Character:GetAttribute("Role")
					
                    --if everything is there then try to fetch the module
					if roleValue and charName and #charName > 0 then
                        --fetch the module
						local moduleInstance = Utils.Instance.GetCharacterModule(roleValue, charName, Character:GetAttribute("CharacterSkinName"))
						--if the module is found, try to require it and, if it got successfully required and its BaseSpeed is a number, set it
                        if moduleInstance then
							local success, mod = pcall(require, moduleInstance)
							if success and mod.GameplayConfig and type(mod.GameplayConfig.BaseSpeed) == "number" then
								fallBackSpeed = mod.GameplayConfig.BaseSpeed
							end
						end
					end
					
                    --set the final base speed
					CurrentSpeed = fallBackSpeed
				end

                --multiply a number starting from 1 by every factor since they're all multipliers
                local TotalFactor = 1
                for _, factor in PlayerSpeedManager.ManagedPlayers[Player].Factors do
                    TotalFactor *= factor
                end

                --mutliply the speed by the total calculated factor
                CurrentSpeed *= TotalFactor
                --set the humanoid's speed to the final calculated speed
                Humanoid.WalkSpeed = CurrentSpeed
                
                --set the last multiplier for usage in different scripts
                PlayerSpeedManager.ManagedPlayers[Player].LastMultiplier = TotalFactor
            end))
            
            --when the character is destroyed, remove the player from the table for making another one
            CharacterJanitor:Add(function()
                PlayerSpeedManager.ManagedPlayers[Player] = nil
            end, true)
        end)
    end)
end

--- Adds a speed factor to a specific player.
--- 
--- Speed factors are multipliers applied to a base speed, so for making it have no effect, set it to `1`.
--- 
--- If it's set to 0, all speed will be multiplied to 0, thus resulting in having no speed at all.
function PlayerSpeedManager.AddFactor(Player: Player, Name: string, Mult: number)
    --if the player doesn't have its own speed factor table, wait for a while
    --if the player still hasn't showed up, give up
    --it's a very brief while but it's just in case it needs to be instanced at the same time without applying to a new character if the player is respawning
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

    --set the factor
    PlayerSpeedManager.ManagedPlayers[Player].Factors[Name] = Mult
end

function PlayerSpeedManager.RemoveFactor(Player: Player, Name: string)
    --if the player doesn't have its own speed factor table, there's nothing to remove, so just give up
    if not PlayerSpeedManager.ManagedPlayers[Player] then
        return
    end

    --remove the factor
    PlayerSpeedManager.ManagedPlayers[Player].Factors[Name] = nil
end

return PlayerSpeedManager
