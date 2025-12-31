--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Types = require(script.Parent.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Sounds = require(ReplicatedStorage.Modules.Sounds)

local KillerIntroClass = {}

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
function KillerIntroClass.New2DIntro(Config: IntroSettings, IntroModule: ModuleScript): Types.UiIntro
    return {
        Connections = {},
        Disposables = {},

        Init = function(self: Types.UiIntro)
            if RunService:IsServer() then
                return
            end

            local VideoPlayer = require(Players.LocalPlayer.PlayerScripts.UI.VideoPlayer)

            local Intro = require(IntroModule)
            local Module = require(Utils.Instance.GetCharacterModule("Killer", Config.KillerName, Config.SkinName))

            if Intro.Frames then
                VideoPlayer:LoadVideo(Intro.Frames)
            end
            if Intro.Sound then
                VideoPlayer:SetAudio(Intro.Sound)
            end

            self.VideoPlayer = VideoPlayer
            self.Module = Module

            if Module.Config.OnIntroInit then
                Module.Config:OnIntroInit(self)
            end
        end,

        Play = function(self: Types.UiIntro): (any)
            if RunService:IsServer() then
                return
            end

            local Intro = require(IntroModule)
            table.insert(self.Connections, task.spawn(function()
                if Intro.Frames then
                    self.VideoPlayer:Play(self.Module.Config.IntroFPS) --will default to 30 if nil
                elseif Intro.Sound then
                    Sounds.PlaySound(Intro.Sound or self.Module.Config.Sounds.IntroSound, {Name = "IntroSound"})
                end
            end))

            if Intro.Behaviour then
                table.insert(self.Connections, task.spawn(function()
                    Intro:Behaviour(self)
                end))
            end

            if self.Module.Config.OnIntroPlay then
                table.insert(self.Connections, task.spawn(function()
                    self.Module.Config:OnIntroPlay(self.VideoPlayer)
                end))
            end

            return self.VideoPlayer
        end,

        Destroy = function(self: Types.UiIntro)
            self.VideoPlayer:Reset()

            for _, connection in self.Connections do
                if typeof(connection) == "thread" then
                    if coroutine.status(connection) ~= "running" then
                        task.cancel(connection)
                    end
                else
                    connection:Disconnect()
                end
            end

            for _, disposable in self.Disposables do
                disposable:Destroy()
            end
        end,
    }
end

--- Creates a new 3D killer intro.
--- See `IntroSettings`.
function KillerIntroClass.New3DIntro(Config: IntroSettings): Types.AnimatedIntro
    return {
        Connections = {},
        Disposables = {},
        Animations = {},

        Init = function(self: Types.AnimatedIntro)
            if RunService:IsServer() then
                return
            end

            local Module = Utils.Instance.GetCharacterModule("Killer", Config.KillerName, Config.SkinName)

            local PlayerRig = Utils.Instance.FindFirstChild(workspace.Players, Config.PlayerName)
            --yield until the char loads properly
            local HRP = Utils.Instance.FindFirstChild(PlayerRig, "HumanoidRootPart")

            local KillerRig = PlayerRig:Clone()
            HRP = Utils.Instance.FindFirstChild(KillerRig, "HumanoidRootPart")
            KillerRig.Parent = workspace.TempObjectFolders.Intro
            HRP.Anchored = true
            KillerRig:PivotTo(CFrame.new(0, 10000, 0))
            self.Disposables.KillerRig = KillerRig

            local CameraRig = Module:FindFirstChild("CameraRig") or ReplicatedStorage.Objects.CameraRig
            CameraRig = CameraRig:Clone()
            CameraRig:PivotTo(CFrame.new(0, 10000, 0))
            CameraRig.Parent = workspace.TempObjectFolders.Intro
            self.Disposables.CameraRig = CameraRig

            Module = require(Module)
            self.Module = Module

            if not Module.Config.AnimationIDs["KillerRig"] and not Module.Config.AnimationIDs["CameraRig"] then
                self:Destroy()
                return
            end

            if Module.Config.OnIntroInit then
                Module.Config:OnIntroInit(self, KillerRig, CameraRig)
            end

            for _, Rig in {
                "KillerRig",
                "CameraRig",
            } do
                if Module.Config.AnimationIDs[Rig] then
                    self.Animations[Rig] = Utils.Character.LoadAnimationFromID(Rig:find("Killer") and KillerRig or CameraRig, Module.Config.AnimationIDs[Rig])
                end
            end
        end,

        Play = function(self: Types.AnimatedIntro): (Model, Model, number)
            if RunService:IsServer() then
                return
            end

            if not self.Module.Config.AnimationIDs["KillerRig"] and not self.Module.Config.AnimationIDs["CameraRig"] then
                return
            end

            local Camera = workspace.CurrentCamera
            local CamPart = self.Disposables.CameraRig:FindFirstChild(self.Disposables.CameraRig:GetAttribute("CameraName") or "CameraPart")

            table.insert(self.Connections, task.spawn(function()
                if CamPart then
                    while self.Disposables.Camera do
                        Camera.CameraType = Enum.CameraType.Scriptable
                        Camera.CFrame = CamPart.CFrame
                        task.wait()
                    end
                end

                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            end))

            for _, Anim in self.Animations do
                Anim:Play(0)
            end

            if self.Module.Config.Sounds.IntroSound then
                Sounds.PlaySound(self.Module.Config.Sounds.IntroSound)
            end

            if self.Module.Config.OnIntroPlay then
                table.insert(self.Connections, task.spawn(function()
                    self.Module.Config:OnIntroPlay(self.Disposables.KillerRig, self.Disposables.CameraRig, self.Animations.CameraRig.Length)
                end))
            end

            return self.Disposables.KillerRig, self.Disposables.CameraRig, self.Animations.CameraRig.Length
        end,

        Destroy = function(self: Types.AnimatedIntro)
            for _, connection in self.Connections do
                if typeof(connection) == "thread" then
                    task.cancel(connection)
                else
                    connection:Disconnect()
                end
            end

            for _, disposable in self.Disposables do
                disposable:Destroy()
            end
        end,
    }
end

return KillerIntroClass
