return function(Value: boolean)
    for _, Player: Model in workspace.Players:GetChildren() do
        local Hitboxes = Player:FindFirstChild("Hitboxes")
        if Hitboxes then
            for _, hitbox in Hitboxes:GetChildren() do
                hitbox.Transparency = Value and hitbox:GetAttribute("VisibleTransparency") or 1
            end
        end
    end
end
