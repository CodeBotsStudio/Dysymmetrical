export type Achievement = {
    Title: string,
    Description: string,
    Icon: string,
    BadgeID: number?,
    RewardType: "Currency" | "Skin",
    Amount: number?,
    Skin: string?,
    LayoutOrder: number,
    Requirement: number?,
}

type AchievementGroup = {
    Title: string,
    LayoutOrder: number,
    Achievements: {[string]: Achievement}
}

return {
    
} :: {[string]: AchievementGroup}
