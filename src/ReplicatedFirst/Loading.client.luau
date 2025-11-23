local LoadingGui = script:WaitForChild("LoadingGui")
local Main = LoadingGui:WaitForChild("LoadingScreen"):WaitForChild("Main")
local Percent = Main:WaitForChild("Percent")
local AmountTxt = Main:WaitForChild("Amount")
local CurrentlyInitting = Main:WaitForChild("CurrentlyInitting")
local Skip = Main:WaitForChild("Skip")

LoadingGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

repeat
    task.wait()
until game:IsLoaded()

task.wait(1)

local assets = {}
local loadedAssets = {}
local function addAssetsToLoad(tmp)
    for _, i in tmp do
        table.insert(assets, i)
    end
end
addAssetsToLoad(workspace:GetDescendants())
addAssetsToLoad(game:GetService("ReplicatedStorage"):GetDescendants())
addAssetsToLoad(game:GetService("StarterPlayer"):GetDescendants())
addAssetsToLoad(game:GetService("StarterGui"):GetDescendants())

local assetAmount = #assets
local loaded = false
function updateProgress()
    if not loaded then
        Percent.Text = tostring(math.floor(#loadedAssets / assetAmount * 100 - 1)).."%"
        AmountTxt.Text = "("..tostring(#loadedAssets - 1).."/"..tostring(assetAmount)..")"
    end
end

for index, i in assets do
    task.delay(index / (assetAmount / 0.75), function()
        game.ContentProvider:PreloadAsync({
            i
        })
        table.insert(loadedAssets, i)
        updateProgress()
    end)
end

local TweenService = game:GetService("TweenService")

local function Finish()
    if not game:GetService("RunService"):IsStudio() then
        --don't remove this or you'll get in trouble! salutations! (unless you mention the engine in the game's description)
        print(require(game:GetService("ReplicatedStorage").Modules.Utils).Credits)
    end

    loaded = true

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

    task.wait(3) -- wait for the player to actually be in the game instead of being thrown into a round right away

    require(game:GetService("ReplicatedStorage").Modules.Network):FireServerConnection("AddLoadedPlayer", "REMOTE_EVENT")
end

task.delay(10, function()
    if not loaded then
        Skip.Visible = true
        TweenService:Create(Skip, TweenInfo.new(1), {
            TextTransparency = 0
        }):Play()
        Skip.MouseButton1Click:Once(function()
            loaded = true
            Finish()
        end)
    end
end)

repeat
    task.wait()
until #loadedAssets >= #assets - 100 or loaded

local function InitScripts(module: ModuleScript)
    local ModuleCode = require(module)
    task.spawn(function()
        ModuleCode:Init()
    end)
    repeat
        if ModuleCode.CurrentlyInitting then
            CurrentlyInitting.Text = "Initializing "..ModuleCode.CurrentlyInitting.."..."
        else
            CurrentlyInitting.Text = ""
        end
        task.wait()
    until ModuleCode.Loaded
end

InitScripts(game:GetService("ReplicatedStorage").Initter)
InitScripts(game:GetService("Players").LocalPlayer.PlayerScripts.PlayerInitter)

repeat task.wait()
until workspace:GetAttribute("ServerLoaded")

if loaded then return end

Finish()
