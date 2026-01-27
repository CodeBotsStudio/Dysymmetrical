--TODO: comment this script from 9 months ago that i barely understand now and has like 7 tabs of indentation like holy shit
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PlayerSpeedManager = require(script.Parent.PlayerSpeedManager)
local Types = require(ReplicatedStorage.Classes.Types)
local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)

local PlayerSprintManager = {
    ManagedPlayers = {},
}

local SprintModule = {}
SprintModule.__index = SprintModule

local FactorName = "Sprint"

function PlayerSprintManager:Init()
    Utils.Player.ObservePlayers(function(Player: Player)
        Utils.Character.ObserveCharacter(Player, function(Character: Model, CharacterJanitor: Types.Janitor)
            local ManagedPlayer = setmetatable({
                AttemptingSprint = false,
                PressingSprintWhileRecovering = false,
                Recovering = false,
                Exhausted = false,
                Stamina = 100,
                TweenSpeed = true,
                SpeedApplied = false,
                SprintMultiplier = 2.66666,
                CanGainStamina = true,
                RecoverDelay = 0.75,
                RecoverExhaustionDelay = 2,
            }, SprintModule)

            local HumanoidRootPart = Utils.Character.GetRootPart(Character)
            local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
            local Role = Character:GetAttribute("Role")

            ManagedPlayer.Character = Character

            PlayerSpeedManager.AddFactor(Player, FactorName, 1)

            CharacterJanitor:Add(RunService.PreSimulation:Connect(function(delta: number)
                local function SetAttributeSafely(Name: string, Value: any)
                    if ManagedPlayer.Character:GetAttribute(Name) ~= Value then
                        ManagedPlayer.Character:SetAttribute(Name, Value)
                    end
                end

                local DirectionOfMovement = HumanoidRootPart.CFrame:VectorToObjectSpace(HumanoidRootPart.AssemblyLinearVelocity)
                local HumanoidDirectionOfMovement = Vector3.new(Humanoid.MoveDirection.X, 0, Humanoid.MoveDirection.Z)
                local Moving = not HumanoidRootPart.Anchored and Humanoid.WalkSpeed > 0 and DirectionOfMovement.Magnitude > 0.1 and HumanoidDirectionOfMovement.Magnitude > 0
            
                if Moving and ManagedPlayer.AttemptingSprint and not ManagedPlayer.Exhausted and not ManagedPlayer.PressingSprintWhileRecovering and PlayerSpeedManager.ManagedPlayers[Player].LastMultiplier >= 0.65 and PlayerSpeedManager.ManagedPlayers[Player].CanSprint then
                    ManagedPlayer.SpeedApplied = true

                    if ManagedPlayer.RecoveryThread then
                        task.cancel(ManagedPlayer.RecoveryThread)
                    end

                    --killer's stamina should only deplete when other survivors are close
                    --using `playersFolder` is fine since spectators will be around 1000 studs away in the lobby
                    if Role == "Killer" then
                        local found = false
                        for _, otherChar in workspace.Players:GetChildren() do
                            if otherChar == Character then
                                continue
                            end

                            local charHRP = Utils.Character.GetRootPart(otherChar)
                            if not charHRP then
                                continue
                            end
                            
                            if otherChar:GetAttribute("Role") ~= "Survivor" then
                                continue
                            end

                            if (charHRP.Position - HumanoidRootPart.Position).Magnitude <= 110 then
                                found = true
                                break
                            end
                        end
                        
                        if found then
                            ManagedPlayer:_DrainStamina(delta)
                        elseif ManagedPlayer.CanGainStamina then
                            ManagedPlayer:_GainStaminaLegally(delta)
                        end
                    else
                        ManagedPlayer:_DrainStamina(delta)
                    end

                    if ManagedPlayer.Stamina <= 0 then
                        ManagedPlayer:_Stop(true)
                    end

                else

                    if ManagedPlayer.SpeedApplied then
                        ManagedPlayer:_Stop(false)
                        ManagedPlayer.SpeedApplied = false
                    end

                    if ManagedPlayer.CanGainStamina then
                        ManagedPlayer:_GainStaminaLegally(delta)
                    end

                end

                if ManagedPlayer.TweenSpeed then
                    local ValueToTweenTo = ManagedPlayer.SpeedApplied and ManagedPlayer.SprintMultiplier or 1
                    
                    PlayerSpeedManager.ManagedPlayers[Player].Factors[FactorName] = math.lerp(PlayerSpeedManager.ManagedPlayers[Player].Factors[FactorName], ValueToTweenTo, delta * 5.5)
                else
                    PlayerSpeedManager.ManagedPlayers[Player].Factors[FactorName] = ManagedPlayer.SpeedApplied and ManagedPlayer.SprintMultiplier or 1
                end

                SetAttributeSafely("Stamina", ManagedPlayer.Stamina)
                SetAttributeSafely("Sprinting", ManagedPlayer.SpeedApplied)
            end))

            CharacterJanitor:Add(Network:SetConnection("ChangeSprintState", "REMOTE_EVENT", function(plr: Player, Pressed: boolean)
                if plr ~= Player then
                    return
                end

                ManagedPlayer.AttemptingSprint = Pressed
                ManagedPlayer.PressingSprintWhileRecovering = ManagedPlayer.Exhausted and Pressed
            end))

            CharacterJanitor:Add(function()
                if PlayerSprintManager.ManagedPlayers[Player].RecoveryThread then
                    task.cancel(PlayerSprintManager.ManagedPlayers[Player].RecoveryThread)
                end
                PlayerSprintManager.ManagedPlayers[Player] = nil
            end, true)

            PlayerSprintManager.ManagedPlayers[Player] = ManagedPlayer
        end)
    end)
end

function SprintModule:_Stop(StopExhausted: boolean)
	self.Recovering = true

	if StopExhausted then
		self.Stamina = 0
		self.PressingSprintWhileRecovering = true
		self.Exhausted = true
		task.delay(self.RecoverExhaustionDelay, function()
			self.Recovering = false
			self.Exhausted = false
		end)
	else
		self.RecoveryThread = task.delay(self.RecoverDelay, function()
			self.Recovering = false
		end)
	end
end

function SprintModule:_DrainStamina(delta: number)
	self.Stamina -= self.Character:GetAttribute("StaminaDrain") * delta
end

function SprintModule:_GainStaminaLegally(delta: number)
	if not self.Recovering and not self.Exhausted and self.Stamina <= self.Character:GetAttribute("MaxStamina") then
		self.Stamina = math.clamp(self.Stamina + self.Character:GetAttribute("StaminaGain") * delta, 0, self.Character:GetAttribute("MaxStamina") :: any)
	end
end

return PlayerSprintManager
