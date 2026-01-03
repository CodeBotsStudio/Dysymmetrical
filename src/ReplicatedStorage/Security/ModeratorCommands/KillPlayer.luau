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
            for _, PlayerChar in workspace.Players:GetChildren() do
                if not PlayerChar:FindFirstChildWhichIsA("Humanoid") then
                    continue
                end

                PlayerChar.Humanoid.Health = 0
            end
            return
        end

        if not workspace.Players:FindFirstChild(Player) or not workspace.Players[Player]:FindFirstChildWhichIsA("Humanoid") then
            return
        end

        workspace.Players[Player].Humanoid.Health = 0
    end,
}
