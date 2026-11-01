--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)

local LocalPlayer = Players.LocalPlayer
local RoundState: StringValue = ReplicatedStorage.RoundInfo.CurrentState

local TERROR_RADIUS = 60
local EDGE_COLOR = Color3.fromRGB(200, 20, 20)

local function nearestKillerDistance(root: BasePart): number
    local nearest = math.huge
    for _, character in workspace.Players:GetChildren() do
        local role = character:FindFirstChild("Role") :: StringValue?
        local killerRoot = role and role.Value == "Killer" and Utils.Character.GetRootPart(character)
        if killerRoot and not Utils.Instance.FindFirstChild(character, "Effects.Undetectable", 0) then
            nearest = math.min(nearest, (killerRoot.Position - root.Position).Magnitude)
        end
    end
    return nearest
end

local function lowQuality(): boolean
    local quality = UserSettings().GameSettings.SavedQualityLevel
    return quality ~= Enum.SavedQualitySetting.Automatic and quality.Value <= 3
end

return {
    Init = function(_)
        local gui = Instance.new("ScreenGui")
        gui.Name = "TerrorPulse"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local edge = Instance.new("CanvasGroup")
        edge.Size = UDim2.fromScale(1, 1)
        edge.BackgroundTransparency = 1
        edge.GroupTransparency = 1
        edge.Parent = gui
        for _, side in {
            { UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0), 90 },
            { UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.78), -90 },
            { UDim2.fromScale(0.16, 1), UDim2.fromScale(0, 0), 0 },
            { UDim2.fromScale(0.16, 1), UDim2.fromScale(0.84, 0), 180 },
        } do
            local band = Instance.new("Frame")
            band.Size = side[1]
            band.Position = side[2]
            band.BackgroundColor3 = EDGE_COLOR
            band.BorderSizePixel = 0
            band.Parent = edge
            local fade = Instance.new("UIGradient")
            fade.Transparency = NumberSequence.new(0, 1)
            fade.Rotation = side[3]
            fade.Parent = band
        end

        Utils.Character.ObserveCharacter(LocalPlayer, function(character: Model, janitor: Types.Janitor)
            local role = character:WaitForChild("Role", 5) :: StringValue?
            local root = Utils.Character.GetRootPart(character)
            if not role or not root then
                return
            end

            if role.Value ~= "Spectator" then
                local light = Instance.new("PointLight")
                light.Name = "PresenceLight"
                light.Range = 14
                light.Brightness = if lowQuality() then 0.8 else 0.35
                light.Color = Color3.fromRGB(190, 200, 230)
                light.Shadows = false
                light.Parent = root
            end

            janitor:Add(RunService.PreRender:Connect(function()
                if role.Value ~= "Survivor" or RoundState.Value ~= "InRound" then
                    edge.GroupTransparency = 1
                    return
                end
                local closeness = 1 - math.clamp(nearestKillerDistance(root) / TERROR_RADIUS, 0, 1)
                if closeness <= 0 then
                    edge.GroupTransparency = 1
                    return
                end
                local calm = Utils.PlayerData.GetPlayerSetting(LocalPlayer, "Accessibility.EpilepsyMode") == true
                local beat = if calm then 0 else (math.sin(os.clock() * math.pi * 2 * (0.9 + 1.6 * closeness)) + 1) / 2
                edge.GroupTransparency = 1 - closeness * (0.25 + 0.2 * beat)
            end))
            janitor:Add(function()
                edge.GroupTransparency = 1
            end, true)
        end)
    end,
}
