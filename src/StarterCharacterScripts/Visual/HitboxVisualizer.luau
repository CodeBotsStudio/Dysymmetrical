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

        --necessary tables
        local GhostHitboxes: {[number]: BasePart} = {}
        local TargetPositions: {[number]: Vector3} = {}

        --creating the janitor by conveniently using `Utils.Instance.ObserveChildren()`, which is bound to HitboxFolder
        local JanitorInstance: Types.Janitor = Utils.Instance.ObserveChildren(HitboxFolder, function(Child: Instance)
            --safety check
            if not Child:IsA("BasePart") then
                return
            end

            --if there is no ID available, halt
            local ID = Child:GetAttribute("ID")
            if ID == nil then
                return
            end

            --add its CURRENT position to the table just in case
            TargetPositions[ID] = Child.CFrame.Position

            --create its dupe with its supposed transparency
            local Ghost = Child:Clone()
            Ghost.Parent = HitboxFolder
            Ghost.Name = Ghost.Name.."Ghost"
            Ghost.Transparency = Ghost:GetAttribute("VisibleTransparency") or 0.75
            --IMPORTANTLY anchor it or it will fall to oblivion
            Ghost.Anchored = true
            --add it to the ghost table for the render loop
            GhostHitboxes[ID] = Ghost
        end)
        --use the same janitor for removing stuffs
        JanitorInstance:Add(HitboxFolder.ChildRemoved:Connect(function(Child: Instance)
            --safety check
            if not Child:IsA("BasePart") then
                return
            end

            --if there is no ID available, halt
            local ID = Child:GetAttribute("ID")
            if ID == nil then
                return
            end
            
            --remove stuff from tables to clean up
            if GhostHitboxes[ID] then
                GhostHitboxes[ID]:Destroy()
            end
            GhostHitboxes[ID] = nil
            TargetPositions[ID] = nil
        end))
        
        --use the same janitor again to add the network connection
        JanitorInstance:Add(Network:SetConnection("UpdateHitboxPosition", "UREMOTE_EVENT", function(Buffer: buffer)
            --start from 1 to skip the buffer's counter header at first
            local Offset = 1
	
            local Count = buffer.readu8(Buffer, 0)
            
            --iterate over the amount of hitboxes
            for _ = 1, Count do
                --get the id and increase the offset
                local ID = buffer.readu8(Buffer, Offset)
                Offset += 1
                
                --read every axis and write it to a table for creating the vector
                local AxisTable: {[string]: number} = {}
                for _, Axis in {"X", "Y", "Z"} do
                    AxisTable[Axis] = buffer.readf32(Buffer, Offset)
                    Offset += 4
                end
                
                --set the new vector with the set values to the set ID
                TargetPositions[ID] = Vector3.new(AxisTable.X, AxisTable.Y, AxisTable.Z)
            end
        end))

        --use the same janitor yet again to add the render loop
        JanitorInstance:Add(RunService.PreRender:Connect(function(delta: number)
            --iterate over every available position in this frame
            for ID: number, targetPosition: Vector3 in TargetPositions do
                --if a ghost for this ID doesn't exist, move on to the next one
                local Ghost = GhostHitboxes[ID]
                if not Ghost then
                    continue
                end

                --lerp the ghost's position to its supposed target position
                Ghost.Position = Ghost.Position:Lerp(targetPosition, delta * 9)
            end
        end))
    end,
}