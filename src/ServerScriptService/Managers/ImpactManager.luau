--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)

local ImpactManager = {
    Config = {
        ShotLength = 10,
        PropRadius = 7,
        PropImpulse = 45,
        DamageForFullStrength = 40,
    },
}

local function strengthOf(damage: number): number
    return math.clamp(damage / ImpactManager.Config.DamageForFullStrength, 0.3, 1)
end

local function pushProps(position: Vector3, strength: number)
    local config = ImpactManager.Config
    for _, part in workspace:GetPartBoundsInRadius(position, config.PropRadius) do
        if part.Anchored or not part:HasTag("Reactive") then
            continue
        end
        local away = part.Position - position
        local direction = (if away.Magnitude > 0.1 then away.Unit else Vector3.zero) + Vector3.new(0, 0.7, 0)
        part:ApplyImpulse(direction.Unit * part.AssemblyMass * config.PropImpulse * strength)
    end
end

function ImpactManager.ProbeHitbox(source: Player, hitboxCFrame: CFrame, size: Vector3, damage: number, params: RaycastParams)
    local root = source.Character and source.Character.PrimaryPart
    if not root then
        return
    end
    local kind = if size.Z >= ImpactManager.Config.ShotLength then "Shot" else "Melee"
    local farEnd = hitboxCFrame.Position + hitboxCFrame.LookVector * size.Z / 2
    local hit = workspace:Raycast(root.Position, farEnd - root.Position, params)
    if not hit and kind == "Melee" then
        hit = workspace:Raycast(hitboxCFrame.Position, Vector3.new(0, -(size.Y / 2 + 4), 0), params)
    end
    if not hit or hit.Instance:IsDescendantOf(workspace.Players) then
        return
    end
    local strength = strengthOf(damage)
    Network:FireAllClientConnection("Impact", "REMOTE_EVENT", kind, hit.Position, hit.Normal, hit.Instance.Color, hit.Material, strength, source, nil, hit.Instance.Anchored)
    pushProps(hit.Position, strength)
end

function ImpactManager.Body(source: Player, target: Model, root: BasePart, damage: number)
    local strength = strengthOf(damage)
    Network:FireAllClientConnection("Impact", "REMOTE_EVENT", "Body", root.Position, Vector3.yAxis, Color3.fromRGB(150, 140, 130), Enum.Material.Concrete, strength, source, target)
    pushProps(root.Position, strength)
end

function ImpactManager:Init()
    Network:SetConnection("Impact", "REMOTE_EVENT", function() end)
    workspace.ChildAdded:Connect(function(map: Instance)
        if map.Name ~= "Map" then
            return
        end
        task.defer(function()
            for _, part in map:GetDescendants() do
                if part:IsA("BasePart") and part:HasTag("Reactive") and not part.Anchored then
                    part:SetNetworkOwner(nil)
                end
            end
        end)
    end)
end

return ImpactManager
