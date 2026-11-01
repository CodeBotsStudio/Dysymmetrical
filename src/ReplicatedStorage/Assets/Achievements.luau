local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Classes.Types)

type AchievementGroup = {
    Title: string,
    LayoutOrder: number,
    Achievements: {[string]: Types.Achievement}
}

return {
    General = {
        Title = "General",
        LayoutOrder = 1,
        Achievements = {
            Welcome = {
                Title = "Bienvenido a Anomalis",
                Description = "Juega a Anomalis por primera vez",
                RewardType = "Currency",
                Amount = 300,
                LayoutOrder = 1,
            },
        },
    },
} :: {[string]: AchievementGroup}
