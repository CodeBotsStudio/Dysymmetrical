local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Effect = require(ReplicatedStorage.Classes.Effect)
local Types = require(ReplicatedStorage.Classes.Types)

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

return Effect.New({
    Name = "Invisibility",
    Description = "Makes the player fairly transparent (but never fully invisible) the higher the level.",
    Duration = 10,
    TransparentInstances = {},

    ApplyEffect = function(own: Types.Effect, level: number, char: Model)
        if not RunService:IsServer() then
            return
        end

        table.clear(own.TransparentInstances)
        local handleIndex = 1
        for _, Part in char:GetDescendants() do
            if Part:IsA("BasePart") then
                local nameToUse = Part.Name
                if Part.Name == "Handle" then
                    nameToUse = "Handle"..tostring(handleIndex)
                    handleIndex += 1
                end
                own.TransparentInstances[nameToUse] = {
                    Instance = Part,
                    Transparency = Part.Transparency,
                    CastShadow = Part.CastShadow,
                }
            elseif Part:IsA("Decal") then
                own.TransparentInstances[Part.Name] = {
                    Instance = Part,
                    Transparency = Part.Transparency,
                }
            end
        end

        Work(true, own.TransparentInstances, level)
    end,
    RemoveEffect = function(own: Types.Effect)
        if not RunService:IsServer() then
            return
        end

        Work(false, own.TransparentInstances)
        table.clear(own.TransparentInstances)
    end
})