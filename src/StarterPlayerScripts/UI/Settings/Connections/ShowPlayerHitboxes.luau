return function(Value: boolean)
    for _, Player: Model in workspace.Players:GetChildren() do
        local Hitboxes = Player:FindFirstChild("Hitboxes")
        if Hitboxes then
            for _, i in Hitboxes:GetChildren() do
                i.Transparency = Value and i:GetAttribute("VisibleTransparency") or 1
            end
        end
    end
end
