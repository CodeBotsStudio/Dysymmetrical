return {
    Name = "Kill Player",
    Executable = true,
    Params = {
        {
            Title = "Chosen Player",
            Type = "String",
            Default = "...",
        },
    },
    Executed = function(self, Player: string)
        if typeof(Player) ~= "string" then
            return
        end

        if Player:lower() == "all" then
            for _, i in workspace.Players:GetChildren() do
                if not i:FindFirstChildOfClass("Humanoid") then
                    continue
                end

                i.Humanoid.Health = 0
            end
            return
        end

        if not workspace.Players:FindFirstChild(Player) or not workspace.Players[Player]:FindFirstChildOfClass("Humanoid") then
            return
        end

        workspace.Players[Player].Humanoid.Health = 0
    end,
}
