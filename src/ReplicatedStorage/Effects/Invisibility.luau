--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Effect = require(ReplicatedStorage.Classes.Effect)

local Invisibility = Effect:GetDefaultEffect()
Invisibility.Name = "Invisibility"
Invisibility.Description = "Makes the player fairly transparent (but never fully invisible) the higher the level."
Invisibility.Duration = 10
Invisibility.TransparentInstances = {}

local function Work(apply: boolean, instances: {BasePart & Decal}, level: number?)
    if apply then
        for _, values in instances do
            if values.Instance:HasTag("Transparent") then
                continue
            end
            values.Instance.Transparency = math.clamp(0.7 + 0.07 * level, 0, 0.975)
            if values.Instance.Transparency > 0.8 and values.Instance:IsA("BasePart") then
                values.Instance.CastShadow = false
            end
        end
    else
        for _, values in instances do
            if values.Instance:HasTag("Transparent") then
                continue
            end
            values.Instance.Transparency = values.Transparency
            if values.Instance:IsA("BasePart") then
                values.Instance.CastShadow = values.CastShadow
            end
        end
    end
end

Invisibility.ApplyEffect = function(own: Effect.Effect, level: number, char: Model)
    if not RunService:IsServer() then
        return
    end

    table.clear(own.TransparentInstances)
    local handleIndex = 1
    for _, i in char:GetDescendants() do
        if i:IsA("BasePart") then
            local nameToUse = i.Name
            if i.Name == "Handle" then
                nameToUse = "Handle"..tostring(handleIndex)
                handleIndex += 1
            end
            own.TransparentInstances[nameToUse] = {
                Instance = i,
                Transparency = i.Transparency,
                CastShadow = i.CastShadow,
            }
        elseif i:IsA("Decal") then
            own.TransparentInstances[i.Name] = {
                Instance = i,
                Transparency = i.Transparency,
            }
        end
    end

    Work(true, own.TransparentInstances, level)
end

Invisibility.RemoveEffect = function(own: Effect.Effect)
    if not RunService:IsServer() then
        return
    end

    Work(false, own.TransparentInstances)
    table.clear(own.TransparentInstances)
end

return Invisibility