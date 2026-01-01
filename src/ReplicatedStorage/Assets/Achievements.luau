local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Classes.Types)

type AchievementGroup = {
    Title: string,
    LayoutOrder: number,
    Achievements: {[string]: Types.Achievement}
}

return {
    
} :: {[string]: AchievementGroup}
