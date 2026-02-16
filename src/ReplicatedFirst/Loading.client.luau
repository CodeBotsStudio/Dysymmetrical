local LoadingGui = script:WaitForChild("LoadingGui")
local Main = LoadingGui:WaitForChild("LoadingScreen"):WaitForChild("Main")
local Percent = Main:WaitForChild("Percent")
local AmountTxt = Main:WaitForChild("Amount")
local CurrentlyInitting = Main:WaitForChild("CurrentlyInitting")
local Skip = Main:WaitForChild("Skip")

LoadingGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

while not game:IsLoaded() do
    task.wait()
end

task.wait(1)

local assets = {}
local loadedAssets = {}
local function addAssetsToLoad(assetList)
    for _, asset in assetList do
        if asset then
            table.insert(assets, asset)
        end
    end
end

local success = pcall(function()
    addAssetsToLoad(workspace:GetDescendants())
    addAssetsToLoad(game:GetService("ReplicatedStorage"):GetDescendants())
    addAssetsToLoad(game:GetService("StarterPlayer"):GetDescendants())
    addAssetsToLoad(game:GetService("StarterGui"):GetDescendants())
end)

if not success then
    warn("Failed to load asset list")
end

local assetAmount = #assets
local loaded = false
function updateProgress()
    if not loaded then
        local progress = math.floor(math.max(#loadedAssets / math.max(1, assetAmount) * 100 - 1, 0))
        pcall(function()
            Percent.Text = tostring(progress).."%"
            AmountTxt.Text = "("..tostring(#loadedAssets - 1).."/"..tostring(assetAmount)..")"
        end)
    end
end

local ContentProvider = game:GetService("ContentProvider")
local preloadStart = os.clock()
local preloadTimeout = 120

for index, asset in assets do
    if os.clock() - preloadStart > preloadTimeout then
        warn("Asset preloading timeout")
        break
    end
    
    task.delay(math.min(index / (math.max(1, assetAmount) / 0.75), 60), function()
        if loaded then return end
        
        local preloadSuccess = pcall(function()
            ContentProvider:PreloadAsync({asset})
        end)
        
        if preloadSuccess then
            table.insert(loadedAssets, asset)
            updateProgress()
        end
    end)
end

local TweenService = game:GetService("TweenService")

local function Finish()
    if not game:GetService("RunService"):IsStudio() then
        local creditsSuccess, utils = pcall(function()
            return require(game:GetService("ReplicatedStorage").Modules.Utils)
        end)
        if creditsSuccess and utils and utils.Credits then
            print(utils.Credits)
        end
    end
    
    task.spawn(function()
        local networkSuccess, Network = pcall(function()
            return require(game:GetService("ReplicatedStorage").Modules.Network)
        end)
        
        if networkSuccess and Network then
            local remoteSuccess = pcall(function()
                Network:FireServerConnection("AddLoadedPlayer", "REMOTE_EVENT")
            end)
            if not remoteSuccess then
                warn("Failed to notify server of client load")
            end
        else
            warn("Network module not available")
        end
    end)

    loaded = true

    pcall(function()
        Percent.Text = "100%"
        AmountTxt.Text = "("..tostring(assetAmount).."/"..tostring(assetAmount)..")"

        TweenService:Create(CurrentlyInitting, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            TextTransparency = 1
        }):Play()
        TweenService:Create(Percent.UIStroke, TweenInfo.new(0.666), {
            Transparency = 1
        }):Play()
        TweenService:Create(Percent.UIStroke, TweenInfo.new(2), {
            Thickness = 20
        }):Play()
        TweenService:Create(AmountTxt.UIStroke, TweenInfo.new(0.666), {
            Transparency = 1
        }):Play()
        TweenService:Create(AmountTxt.UIStroke, TweenInfo.new(2), {
            Thickness = 20
        }):Play()
        TweenService:Create(Skip, TweenInfo.new(0.666), {
            TextTransparency = 1
        }):Play()
        task.wait(1)
        TweenService:Create(Percent, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            TextTransparency = 1
        }):Play()
        TweenService:Create(AmountTxt, TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            TextTransparency = 1
        }):Play()
        task.wait(0.5)
        TweenService:Create(Main, TweenInfo.new(0.75), {
            BackgroundTransparency = 1
        }):Play()

        game:GetService("Debris"):AddItem(LoadingGui, 0.8)
        game:GetService("StarterGui"):SetCore("ResetButtonCallback", true)

        task.wait(0.8)

        workspace:SetAttribute("ClientLoaded", true)
    end)
end

-- Skip button handler
if Skip then
    Skip.Activated:Connect(function()
        loaded = true
    end)
end

-- Timeout protection - finish after max wait time
task.delay(120, function()
    if not loaded then
        warn("Client loading timeout - forcing completion")
        loaded = true
    end
end)

-- Wait for assets to preload (but don't finish yet)
local assetWaitStart = os.clock()
while #loadedAssets < assetAmount and os.clock() - assetWaitStart < 120 do
    task.wait(1)
end

-- Show skip button if still loading after 10 seconds
task.delay(10, function()
    if not loaded then
        Skip.Visible = true
        TweenService:Create(Skip, TweenInfo.new(1), {
            TextTransparency = 0
        }):Play()
        Skip.MouseButton1Click:Once(function()
            loaded = true
        end)
    end
end)

-- Wait for enough assets to be loaded
while #loadedAssets < #assets - 100 and not loaded do
    task.wait()
end

local function InitScripts(module: ModuleScript)
    local ModuleCode = require(module)
    task.spawn(function()
        ModuleCode:Init()
    end)

    while not ModuleCode.Loaded do
        if ModuleCode.CurrentlyInitting then
            CurrentlyInitting.Text = "Initializing "..ModuleCode.CurrentlyInitting.."..."
        else
            CurrentlyInitting.Text = ""
        end
        task.wait()
    end
end

-- Initialize modules
InitScripts(game:GetService("ReplicatedStorage").Initter)
InitScripts(game:GetService("Players").LocalPlayer.PlayerScripts.PlayerInitter)

-- Wait for server to complete initialization
while not workspace:GetAttribute("ServerLoaded") do
    task.wait()
end

-- Now finish and show the main UI
if not loaded then
    Finish()
end
