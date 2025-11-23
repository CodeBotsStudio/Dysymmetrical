--!nocheck

local EffectManager = {
    Effects = {},
    Connections = {},
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Type = require(ReplicatedStorage.Classes.Effect)
local Utils = require(ReplicatedStorage.Modules.Utils)

function EffectManager:Init()
    --visual
    table.insert(self.Connections, RunService.PreSimulation:Connect(function(delta: number)
        for _, effect: Type.Effect in self.Effects do
            effect.TimeLeft -= delta
        end
    end))

    local Effects = Utils:FindFirstChild(Players.LocalPlayer.Character, "Effects")

    table.insert(self.Connections, Effects.ChildAdded:Connect(function(EffectValue: Instance)
        if EffectValue:IsA("NumberValue") then
            if EffectValue:GetAttribute("Duration") == nil then
                repeat task.wait()
                until EffectValue:GetAttribute("Duration") ~= nil
            end

            self:AddEffect(Utils:GetEffectModule(EffectValue.Name, EffectValue:GetAttribute("Subfolder"), true), EffectValue.Value, EffectValue:GetAttribute("Duration"))
        end
    end))

    table.insert(self.Connections, Effects.ChildRemoved:Connect(function(EffectValue: Instance)
        if EffectValue:IsA("NumberValue") then
            self:RemoveEffect(EffectValue.Name)
        end
    end))

	table.insert(self.Connections, Players.LocalPlayer.CharacterAdded:Connect(function()
		for _, i in self.Connections do
			i:Disconnect() --ends the script's execution
		end
	end))
end

function EffectManager:AddEffect(Effect: ModuleScript, level: number?, duration: number?)
    if self.Effects[Effect.Name] ~= nil then
        --too lazy to implement this
        -- if effect.ReplaceExisting and effect.Level >= self.Effects[effect.Name].Level then
        --     self.Effects[effect.Name].TimeLeft = self.Effects[effect.Name].Duration
        -- end
        return
    end

    local effect = Utils:CopyTable(require(Effect))
    self.Effects[Effect.Name] = effect

    effect.TimeLeft = duration or effect.Duration
    effect.Level = level or effect.Level

    effect:Apply(level, Players.LocalPlayer.Character, duration or effect.Duration)
end

function EffectManager:RemoveEffect(effect: string)
    if self.Effects[effect] == nil then return end

    self.Effects[effect]:Remove(Players.LocalPlayer.Character)
    self.Effects[effect] = nil
end

return EffectManager
