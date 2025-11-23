local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Network = require(ReplicatedStorage.Modules.Network)
local LightingModule = {
    Properties = {
        Ambient = Color3.fromRGB(0, 0, 0), 
        Brightness = 3, 
        ColorShift_Bottom = Color3.fromRGB(0, 0, 0), 
        ColorShift_Top = Color3.fromRGB(0, 0, 0), 
        EnvironmentDiffuseScale = 1, 
        EnvironmentSpecularScale = 1, 
        GlobalShadows = true, 
        OutdoorAmbient = Color3.fromRGB(70, 70, 70), 
        ShadowSoftness = 0.2, 
        ClockTime = 5.4, 
        GeographicLatitude = 0, 
        ExposureCompensation = 1.24, 
        FogColor = Color3.fromRGB(192, 192, 192), 
        FogEnd = 100000, 
        FogStart = 0,
    },
    CurrentLighting = nil,
}

function LightingModule:Init()
    if RunService:IsServer() then
        Network:SetConnection("GetCurrentLighting", "REMOTE_FUNCTION", function(player: Player)
            if self.CurrentLighting then
                local Props = self.CurrentLighting:Clone()
                Props.Parent = player.PlayerGui
                Debris:AddItem(Props, 20)
                return Props
            end
            return {}
        end)
    else
        Network:SetConnection("SetCustomLighting", "REMOTE_EVENT", function(Properties)
            self:SetCustomLighting(Properties)
        end)
        Network:SetConnection("SetDefaultLighting", "REMOTE_EVENT", function()
            self:SetDefaultLighting()
        end)
        self:SetDefaultLighting()
    end
end

function LightingModule:SetAsCurrentLighting()
    if RunService:IsServer() then
        return
    end

    self:SetDefaultLighting()
    local Current = Network:FireServerConnection("GetCurrentLighting", "REMOTE_FUNCTION")
    if Current then
        self:SetCustomLighting(Current)
    end
end

function LightingModule:SetCustomLighting(Properties: {[any]: any} | Instance)
    if RunService:IsServer() then
        if typeof(Properties) == "Instance" and Properties:IsA("Folder") then
            if ReplicatedStorage:FindFirstChild("CurrentReplicatedLighting") then
                ReplicatedStorage.CurrentReplicatedLighting:Destroy()
            end
            Properties = Properties:Clone()
            Properties.Name = "CurrentReplicatedLighting"
            Properties.Parent = ReplicatedStorage
        end
        self.CurrentLighting = Properties
        Network:FireAllClientConnection("SetCustomLighting", "REMOTE_EVENT", Properties)
    elseif typeof(Properties) == "Instance" then
        if Properties:IsA("Folder") then
            Lighting:ClearAllChildren()
            for _, i in Properties:GetChildren() do
                if i:IsA("ModuleScript") then
                    self:SetCustomLighting(require(i))
                else
                    i:Clone().Parent = Lighting
                end
            end
        elseif Properties:IsA("ModuleScript") then
            if #Properties:GetChildren() > 0 then
                Lighting:ClearAllChildren()
                for _, i in Properties:GetChildren() do
                    i:Clone().Parent = Lighting
                end
            end
            self:SetCustomLighting(require(Properties))
        end
    else
        local Props = Properties or {}
        for name, value in Props do
            Lighting[name] = value
        end
    end
end

function LightingModule:SetDefaultLighting()
    if RunService:IsServer() then
        if typeof(self.CurrentLighting) == "Instance" then
            self.CurrentLighting:Destroy()
        end
        self.CurrentLighting = nil
        Network:FireAllClientConnection("SetDefaultLighting", "REMOTE_EVENT")
    else
        self:SetCustomLighting(self.Properties)
        Lighting:ClearAllChildren()
        for _, i in script:GetChildren() do
            i:Clone().Parent = Lighting
        end
    end
end

return LightingModule
