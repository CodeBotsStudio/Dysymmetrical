return {
    Init = function(_)
        require(game:GetService("ReplicatedStorage").Modules.Utils).Character.ObserveCharacter(
                game:GetService("Players").LocalPlayer, function(Character: Model)

            require(Character:FindFirstChild("Initter")):Init(Character)
        end)
    end,
}
