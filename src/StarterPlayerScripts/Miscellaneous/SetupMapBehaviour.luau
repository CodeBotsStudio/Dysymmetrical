return {
    Init = function()
        -- ChildAdded is optimized as everything that isn't maps and players is added in folders inside it so it doesn't get called. -dys
        workspace.ChildAdded:Connect(function(newChild: Instance)
            if newChild.Name ~= "Map" then
                return
            end

            local Behaviour = newChild:WaitForChild("Behaviour", 10)
            if not Behaviour then
                return
            end

            require(Behaviour):Init()
        end)
    end,
}