local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Classes.Types)
local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)

return {
    Init = function(_)
        local Character: Model = Players.LocalPlayer.Character
        local HitboxFolder: Folder = Character.Hitboxes

        local ManagedHitboxes: {[number]: BasePart} = {}
        local GhostHitboxes: {[number]: BasePart} = {}
        local TargetPositions: {[number]: Vector3} = {}

        local JanitorInstance: Types.Janitor = Utils.Instance.ObserveChildren(HitboxFolder, function(Child: Instance)
            if not Child:IsA("BasePart") then
                return
            end

            local ID = Child:GetAttribute("ID")
            if ID == nil then
                return
            end

            ManagedHitboxes[ID] = Child
            TargetPositions[ID] = Child.CFrame.Position

            local Ghost = Child:Clone()
            Ghost.Parent = HitboxFolder
            Ghost.Name = Ghost.Name.."Ghost"
            Ghost.Transparency = Ghost:GetAttribute("VisibleTransparency") or 0.75
            Ghost.Anchored = true
            GhostHitboxes[ID] = Ghost
        end)
        JanitorInstance:Add(HitboxFolder.ChildRemoved:Connect(function(Child: Instance)
            if not Child:IsA("BasePart") then
                return
            end

            local ID = Child:GetAttribute("ID")
            if ID == nil then
                return
            end
            
            ManagedHitboxes[ID] = nil
            TargetPositions[ID] = nil

            if GhostHitboxes[ID] then
                GhostHitboxes[ID]:Destroy()
            end
            GhostHitboxes[ID] = nil
        end))
        
        JanitorInstance:Add(Network:SetConnection("UpdateHitboxPosition", "UREMOTE_EVENT", function(Buffer: buffer)
            local Offset = 1
	
            local Count = buffer.readu8(Buffer, 0)
            
            for _ = 1, Count do
                local ID = buffer.readu8(Buffer, Offset)
                Offset += 1
                
                local AxisTable: {[string]: number} = {}
                for _, Axis in {"X", "Y", "Z"} do
                    AxisTable[Axis] = buffer.readf32(Buffer, Offset)
                    Offset += 4
                end
                
                TargetPositions[ID] = Vector3.new(AxisTable.X, AxisTable.Y, AxisTable.Z)
            end
        end))

        JanitorInstance:Add(RunService.PreRender:Connect(function(delta: number)
            for ID: number, targetPosition: Vector3 in TargetPositions do
                local Ghost = GhostHitboxes[ID]

                if not Ghost then
                    continue
                end

                Ghost.Position = Ghost.Position:Lerp(targetPosition, delta * 9)
            end
        end))
    end,
}