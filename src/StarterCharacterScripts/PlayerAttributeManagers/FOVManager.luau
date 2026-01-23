local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Janitor = require(ReplicatedStorage.Packages.Janitor)

local FOVManager = {
    Factors = {},
    LerpDelta = 4,
    CanUpdate = true,
    Janitor = nil,
    Lerp = true,
}

function FOVManager:Init()
    --gets core stuffs
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local Camera = workspace.CurrentCamera

    --instancing janitor for mem leak prevention
    self.Janitor = Janitor.new()
    self.Janitor:LinkToInstance(LocalPlayer.Character)

    --render connection
    self.Janitor:Add(RunService.PreRender:Connect(function(delta: number)
        --if the fov can't be updated by the manager, halt
        if not self.CanUpdate then
            return
        end

        --get base fov
        local FOV = LocalPlayer:GetAttribute("BaseFOV") or 70

        --multiply by every factor
        for _, Factor in self.Factors do
            FOV *= Factor
        end

        --lerp the camera fov or snap if lerping isn't allowed
        Camera.FieldOfView = self.Lerp and math.lerp(Camera.FieldOfView, FOV, delta * self.LerpDelta) or FOV
    end))
end

--- Adds an FOV multiplier to this manager-
function FOVManager:AddFactor(Name: string, Multiplier: number)
    self.Factors[Name] = Multiplier
end

--- Removes an FOV multiplier from this manager-
function FOVManager:RemoveFactor(Name: string)
    self.Factors[Name] = nil
end

return FOVManager
