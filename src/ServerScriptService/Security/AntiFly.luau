--!nocheck

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Utils = require(ReplicatedStorage.Modules.Utils)
local CommonFunctions = require(ServerScriptService.System.CommonFunctions)
local AntiFly = {
    TimeBetweenChecks = 0.5,
    MaximumFlyTime = 10,
    VisualizeRays = false,
}

function AntiFly:Init()
    --check for any players that joined before initting
    for _, plr: Player in Players:GetPlayers() do
        if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
            self:_SetupCharacter(plr, plr.Character)
        end
        plr.CharacterAdded:Connect(function(char: Model)
            self:_SetupCharacter(plr, char)
        end)
    end

    Players.PlayerAdded:Connect(function(plr: Player)
        plr.CharacterAdded:Connect(function(char: Model)
            self:_SetupCharacter(plr, char)
        end)
    end)
end

function AntiFly:_SetupCharacter(player: Player, char: Model)
    local root = Utils:FindFirstChild(char, "HumanoidRootPart")

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = {char}

    local lastTouched = time()

    task.spawn(function()
        while root and root.Parent and char and char.Parent do
            task.wait(self.TimeBetweenChecks)
            
            if self:_IsCharacterNotFlying(root, Params) then
                lastTouched = time()
                continue --used to not check anything else during this check
            end
        
            local timeSinceFloor = time() - lastTouched
            if timeSinceFloor >= self.MaximumFlyTime then
                CommonFunctions:KickPlayer(player, CommonFunctions.KickIDs.Flying)
            end
        end
    end)
end

function AntiFly:_IsCharacterNotFlying(root: BasePart, Params: RaycastParams): boolean
    if not (root and root.Parent) then
        return true
    end
    if math.abs(root.AssemblyLinearVelocity.Y) > 45 then --if the player is flung it's obv gonna be false positive (DAMN YOU SHITTY ROBLOX PHYSICS!!!)
        return true
    end

    for v = -1, 1 do
        for i = -1, 1 do
            local Origin = root.Position + (root.CFrame.RightVector * i) + (root.CFrame.LookVector * v)
            -- local Origin = root.Position + Vector3.new(i, 0, 0)
            local RayHeight = (root.Size.Y / 2) + (root.Parent:FindFirstChild("Right Leg") and root.Parent["Right Leg"].Size.Y or 2) + 1.25

            local Cast = workspace:Raycast(Origin, Vector3.new(0, -RayHeight, 0), Params)

            if self.VisualizeRays then
                local Part = Instance.new("Part")
                Part.Anchored = true
                Part.CanCollide = false
                Part.CanTouch = false
                Part.CanQuery = false
                Part.Position = Origin - Vector3.new(0, 2.125, 0)
                Part.Size = Vector3.new(0.1, 4.25, 0.1)
                Part.Material = Enum.Material.Neon
                Part.Color = Cast and Cast.Instance and Color3.fromRGB(255, 145, 0) or Color3.fromRGB(255, 72, 0)
                Part.Parent = workspace.TempObjectFolders
                Debris:AddItem(Part, 3)
            end

            if Cast and Cast.Instance then
                return true
            end
        end
    end

    return false
end

return AntiFly
