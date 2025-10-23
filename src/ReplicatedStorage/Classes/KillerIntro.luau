--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local KillerIntroClass = {}

--- Type used for 2D killer intros.
export type UiIntro = {
    --- Connections and threads that make the intro work. Add any `task.delay()`s or `RBXScriptConnection`s here.
    Connections: {RBXScriptConnection & thread},
    --- Everything that'll be removed after the intro ends.
    Disposables: {[string]: Instance},

    --- Function used to prepare the intro to be played.
    Init: (self: UiIntro) -> (),
    --- Plays the intro.
    Play: (self: UiIntro) -> (any),
    --- Used when the intro ends so that everything gets disposed.
    Destroy: (self: UiIntro) -> (),

    --- The module of the character for custom usage.
    Module: any,
    --- The player's VideoPlayer that'll be used to play the intro's sprite animation if it has one.
    VideoPlayer: any,
}

--- Type used for 3D killer intros.
export type AnimatedIntro = {
    --- Connections and threads that make the intro work. Add any `task.delay()`s or `RBXScriptConnection`s here.
    Connections: {RBXScriptConnection & thread},
    --- Everything that'll be removed after the intro ends.
    Disposables: {[string]: Instance},
    --- All of the animations that are used in the intro.
    Animations: {[string]: AnimationTrack},

    --- Function used to prepare the intro to be played.
    Init: (self: AnimatedIntro) -> (),
    --- Plays the intro.
    --- @return The killer rig.
    --- @return The camera rig.
    --- @return The length of the camera rig's animation.
    Play: (self: AnimatedIntro) -> (Model, Model, number),
    --- Used when the intro ends so that everything gets disposed.
    Destroy: (self: AnimatedIntro) -> (),

    --- The module of the character for custom usage.
    Module: any,
}

--- The settings of a killer intro. Determines which intro to use and what names to display.
export type IntroSettings = {
    --- The killer's Roblox name.
    PlayerName: string,
    --- The killer's name.
    KillerName: string,
    --- The killer's skin name.
    SkinName: string?,
}

--- Creates a new 2D killer intro.
--- See `IntroSettings`.
function KillerIntroClass:New2DIntro(Config: IntroSettings, IntroModule: ModuleScript): UiIntro
    return {
        Connections = {},
        Disposables = {},

        Init = function(own: UiIntro)
            if RunService:IsServer() then
                return
            end

            local VideoPlayer = require(Players.LocalPlayer.PlayerScripts.UI.VideoPlayer)

            local Intro = require(IntroModule)
            local Module = require(Utils:GetCharacterModule("Killer", Config.KillerName, Config.SkinName))

            if Intro.Frames then
                VideoPlayer:LoadVideo(Intro.Frames)
            end
            if Intro.Sound then
                VideoPlayer:SetAudio(Intro.Sound)
            end

            own.VideoPlayer = VideoPlayer
            own.Module = Module

            if Module.Config.OnIntroInit then
                Module.Config:OnIntroInit(own)
            end
        end,

        Play = function(own: UiIntro): (any)
            if RunService:IsServer() then
                return
            end

            local Intro = require(IntroModule)
            table.insert(own.Connections, task.spawn(function()
                if Intro.Frames then
                    own.VideoPlayer:Play(own.Module.Config.IntroFPS) --will default to 30 if nil
                elseif Intro.Sound then
                    Sounds:PlaySound(Intro.Sound or own.Module.Config.Sounds.IntroSound, {Name = "IntroSound"})
                end
            end))

            if Intro.Behaviour then
                table.insert(own.Connections, task.spawn(function()
                    Intro:Behaviour(own)
                end))
            end

            if own.Module.Config.OnIntroPlay then
                table.insert(own.Connections, task.spawn(function()
                    own.Module.Config:OnIntroPlay(own.VideoPlayer)
                end))
            end

            return own.VideoPlayer
        end,

        Destroy = function(own: UiIntro)
            own.VideoPlayer:Reset()

            for _, i in own.Connections do
                if typeof(i) == "thread" then
                    if coroutine.status(i) ~= "running" then
                        task.cancel(i)
                    end
                else
                    i:Disconnect()
                end
            end

            for _, i in own.Disposables do
                i:Destroy()
            end
        end,
    }
end

--- Creates a new 3D killer intro.
--- See `IntroSettings`.
function KillerIntroClass:New3DIntro(Config: IntroSettings): AnimatedIntro
    return {
        Connections = {},
        Disposables = {},
        Animations = {},

        Init = function(own: AnimatedIntro)
            if RunService:IsServer() then
                return
            end

            local Module = Utils:GetCharacterModule("Killer", Config.KillerName, Config.SkinName)

            local PlayerRig = Utils:FindFirstChild(workspace.Players, Config.PlayerName)
            --yield until the char loads properly
            local HRP = Utils:FindFirstChild(PlayerRig, "HumanoidRootPart")

            local KillerRig = PlayerRig:Clone()
            HRP = Utils:FindFirstChild(KillerRig, "HumanoidRootPart")
            KillerRig.Parent = workspace.TempObjectFolders.Intro
            HRP.Anchored = true
            KillerRig:PivotTo(CFrame.new(0, 10000, 0))
            own.Disposables.KillerRig = KillerRig

            local CameraRig = Module:FindFirstChild("CameraRig") or ReplicatedStorage.Objects.CameraRig
            CameraRig = CameraRig:Clone()
            CameraRig:PivotTo(CFrame.new(0, 10000, 0))
            CameraRig.Parent = workspace.TempObjectFolders.Intro
            own.Disposables.CameraRig = CameraRig

            Module = require(Module)
            own.Module = Module

            if not Module.Config.AnimationIDs["KillerRig"] and not Module.Config.AnimationIDs["CameraRig"] then
                own:Destroy()
                return
            end

            if Module.Config.OnIntroInit then
                Module.Config:OnIntroInit(own, KillerRig, CameraRig)
            end

            for _, i in {
                "KillerRig",
                "CameraRig",
            } do
                if Module.Config.AnimationIDs[i] then
                    own.Animations[i] = Utils:LoadAnimationFromID(i:find("Killer") and KillerRig or CameraRig, Module.Config.AnimationIDs[i])
                end
            end
        end,

        Play = function(own: AnimatedIntro): (Model, Model, number)
            if RunService:IsServer() then
                return
            end

            if not own.Module.Config.AnimationIDs["KillerRig"] and not own.Module.Config.AnimationIDs["CameraRig"] then
                return
            end

            local Camera = workspace.CurrentCamera
            local CamPart = own.Disposables.CameraRig:FindFirstChild(own.Disposables.CameraRig:GetAttribute("CameraName") or "CameraPart")

            table.insert(own.Connections, task.spawn(function()
                if CamPart then
                    while own.Disposables.Camera do
                        Camera.CameraType = Enum.CameraType.Scriptable
                        Camera.CFrame = CamPart.CFrame
                        task.wait()
                    end
                end

                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            end))

            for _, i in own.Animations do
                i:play(0)
            end

            if own.Module.Config.Sounds.IntroSound then
                Sounds:PlaySound(own.Module.Config.Sounds.IntroSound)
            end

            if own.Module.Config.OnIntroPlay then
                table.insert(own.Connections, task.spawn(function()
                    own.Module.Config:OnIntroPlay(own.Disposables.KillerRig, own.Disposables.CameraRig, own.Animations.CameraRig.Length)
                end))
            end

            return own.Disposables.KillerRig, own.Disposables.CameraRig, own.Animations.CameraRig.Length
        end,

        Destroy = function(own: AnimatedIntro)
            for _, i in own.Connections do
                if typeof(i) == "thread" then
                    task.cancel(i)
                else
                    i:Disconnect()
                end
            end

            for _, i in own.Disposables do
                i:Destroy()
            end
        end,
    }
end

return KillerIntroClass
