-- Intro lighting support: Allows intros to have custom lighting that transitions back to normal

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
    _IntroLightingStack = {}, -- Stack to save/restore lighting during intros
}

function LightingModule:Init()
    if RunService:IsServer() then
        Network:SetConnection("GetCurrentLighting", "REMOTE_FUNCTION", function(player: Player)
            if LightingModule.CurrentLighting then
                local Props = LightingModule.CurrentLighting:Clone()
                Props.Parent = player.PlayerGui
                Debris:AddItem(Props, 20)
                return Props
            end
            return {}
        end)
    else
        Network:SetConnection("SetCustomLighting", "REMOTE_EVENT", function(Properties)
            LightingModule.SetCustomLighting(Properties)
        end)
        Network:SetConnection("SetDefaultLighting", "REMOTE_EVENT", function()
            LightingModule.SetDefaultLighting()
        end)
        LightingModule.SetDefaultLighting()
    end
end

function LightingModule.SetAsCurrentLighting()
    if RunService:IsServer() then
        return
    end

    LightingModule.SetDefaultLighting()
    local Current = Network:FireServerConnection("GetCurrentLighting", "REMOTE_FUNCTION")
    if Current then
        LightingModule.SetCustomLighting(Current)
    end
end

function LightingModule.SetCustomLighting(Properties: {[any]: any} | Instance)
    if RunService:IsServer() then
        if typeof(Properties) == "Instance" and Properties:IsA("Folder") then
            if ReplicatedStorage:FindFirstChild("CurrentReplicatedLighting") then
                ReplicatedStorage.CurrentReplicatedLighting:Destroy()
            end
            Properties = Properties:Clone()
            Properties.Name = "CurrentReplicatedLighting"
            Properties.Parent = ReplicatedStorage
        end
        LightingModule.CurrentLighting = Properties
        Network:FireAllClientConnection("SetCustomLighting", "REMOTE_EVENT", Properties)
    elseif typeof(Properties) == "Instance" then
        if Properties:IsA("Folder") then
            Lighting:ClearAllChildren()
            for _, Child in Properties:GetChildren() do
                if Child:IsA("ModuleScript") then
                    LightingModule.SetCustomLighting(require(Child))
                else
                    Child:Clone().Parent = Lighting
                end
            end
        elseif Properties:IsA("ModuleScript") then
            if #Properties:GetChildren() > 0 then
                Lighting:ClearAllChildren()
                for _, Child in Properties:GetChildren() do
                    Child:Clone().Parent = Lighting
                end
            end
            LightingModule.SetCustomLighting(require(Properties))
        end
    else
        local Props = Properties or {}
        for name, value in Props do
            Lighting[name] = value
        end
    end
end

function LightingModule.SetDefaultLighting()
    if RunService:IsServer() then
        if typeof(LightingModule.CurrentLighting) == "Instance" then
            LightingModule.CurrentLighting:Destroy()
        end
        LightingModule.CurrentLighting = nil
        Network:FireAllClientConnection("SetDefaultLighting", "REMOTE_EVENT")
    else
        LightingModule.SetCustomLighting(LightingModule.Properties)
        Lighting:ClearAllChildren()
        for _, Child in script:GetChildren() do
            Child:Clone().Parent = Lighting
        end
    end
end

--- Push intro lighting onto stack (saves current lighting state)
---@param introProperies {[any]: any} | Instance Intro lighting properties
---@return function Function to pop/restore lighting when intro ends
function LightingModule.PushIntroLighting(introProperies: any): () -> ()
    -- Save current lighting state
    local savedState = {
        currentLighting = LightingModule.CurrentLighting,
        lightingProps = {},
    }
    
    -- Save current property values
    for name, _ in LightingModule.Properties do
        if typeof(Lighting[name]) ~= "userdata" then
            savedState.lightingProps[name] = Lighting[name]
        end
    end
    
    -- Push to stack
    table.insert(LightingModule._IntroLightingStack, savedState)
    
    -- Apply intro lighting
    LightingModule.SetCustomLighting(introProperies)
    
    -- Return function to restore lighting
    return function()
        LightingModule.PopIntroLighting()
    end
end

--- Pop intro lighting from stack (restores previous lighting state)
function LightingModule.PopIntroLighting()
    if #LightingModule._IntroLightingStack == 0 then
        return
    end
    
    local savedState = table.remove(LightingModule._IntroLightingStack)
    
    -- Restore lighting
    if savedState.currentLighting then
        LightingModule.SetCustomLighting(savedState.currentLighting)
    else
        LightingModule.SetCustomLighting(savedState.lightingProps)
    end
end

--- Set intro lighting with automatic restoration after duration
---@param introProperies {[any]: any} | Instance Intro lighting properties
---@param duration number Duration in seconds before returning to normal
---@return function Function to manually end intro early
function LightingModule.SetIntroLighting(introProperies: any, duration: number): () -> ()
    local restoreFn = LightingModule.PushIntroLighting(introProperies)
    
    local connection
    connection = task.delay(duration, function()
        restoreFn()
    end)
    
    return function()
        if connection then
            task.cancel(connection)
            connection = nil
        end
        restoreFn()
    end
end

return LightingModule
