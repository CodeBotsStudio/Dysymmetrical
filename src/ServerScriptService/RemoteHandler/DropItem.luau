local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Modules.Network)
local Utils = require(ReplicatedStorage.Modules.Utils)
return function()
    Network:SetConnection("DropItem", "REMOTE_EVENT", function(Player: Player, Tool: Tool)
        if not Player.Character or not Tool or (Tool.Parent ~= Player.Character and Tool.Parent ~= Player.Backpack) then
            return
        end

        local PickableItemEquivalent = ReplicatedStorage.Assets.PickableItems:FindFirstChild(Tool.Name)
        if not PickableItemEquivalent then
            return
        end

        Tool:Destroy()

        PickableItemEquivalent = Utils.Type.CopyTable(require(PickableItemEquivalent))
        PickableItemEquivalent:Init()

        local Pivot = Player.Character:GetPivot()
        local _, Bounds = Player.Character:GetExtentsSize();
        (PickableItemEquivalent.ModelInstance :: Model):PivotTo(CFrame.new(Pivot.Position - Vector3(0, Bounds.Y / 2), 0) * Pivot.Rotation)
    end)
end