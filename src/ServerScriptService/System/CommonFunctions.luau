local CommonFunctions = {
	--- IDs used in the anti-cheat to display kick messages.
	KickIDs = {
		Noclipping = {
			ID = "0001",
			Message = "Player assumed to be noclipping.",
		},
		Flying = {
			ID = "0002",
			Message = "Player assumed to be flying.",
		},
		TPing = {
			ID = "0003",
			Message = "Player assumed to be teleporting across great distances.",
		},
	},
	AdminPerms = {
		{
			Name = "Dyscarn",
			UserId = 432073982,
			Rank = "Developer",
		},
	},

	--don't add anything in here
	Commands = {},
	CommandDebounce = {},
}

local BadgeService = game:GetService("BadgeService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Achievements = require(ReplicatedStorage.Assets.Achievements)
local Types = require(ReplicatedStorage.Classes.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)

function CommonFunctions.Init()
    for _, CommandScript in ReplicatedStorage.Security.ModeratorCommands:GetChildren() do
        if not CommandScript:IsA("ModuleScript") then
            continue
        end
        CommonFunctions.Commands[CommandScript.Name] = require(CommandScript)
    end

	Network:SetConnection("GetPermRank", "REMOTE_FUNCTION", function(Player: Player): number
		return CommonFunctions.GetPlayerPermissionRank(Player)
	end)
	Network:SetConnection("HasPermRank", "REMOTE_FUNCTION", function(Player: Player, Rank: string | number): boolean
		return CommonFunctions.PlayerHasPermissionRank(Player, Rank)
	end)
	Network:SetConnection("ExecuteCommand", "REMOTE_FUNCTION", function(Player: Player, CommandName: string, ...)
        if CommonFunctions.CommandDebounce[Player.UserId] and not CommonFunctions.PlayerHasPermissionRank(Player, CommonFunctions.Commands[CommandName].RankRequired or Utils.Ranks.ServerOwner) or CommonFunctions.Commands[CommandName] == nil then
            return
        end
		
		task.defer(function()
			CommonFunctions.CommandDebounce[Player.UserId] = 0.5
			while CommonFunctions.CommandDebounce[Player.UserId] > 0 do
				CommonFunctions.CommandDebounce[Player.UserId] -= task.wait(0.05)
			end
			CommonFunctions.CommandDebounce[Player.UserId] = nil
		end)
        
        return CommonFunctions.Commands[CommandName]:Executed(...)
    end)
end

type DamagePlayerSettings = {
	--- The `Player` that's inflicting the damage.
	SourcePlayer: Player,
	--- The `Humanoid` receiving the damage.
	TargetHumanoid: Humanoid,
	--- The damage to be inflicted (base).
	Damage: number,
	--- A reason tag for the source of the damage.
	Reason: string?,
	--- The direction of any knockback to be applied.
	KnockbackDirection: Vector3?,
	--- The magnitude of any knockback to be applied.
	KnockbackMagnitude: number?,
}
--- Function that should be used to damage a player from another player's attack.
--- Handles resistance, weakness...
function CommonFunctions.DamagePlayer(DamageSettings: DamagePlayerSettings)
    local Char = DamageSettings.TargetHumanoid.Parent
	local HRP: BasePart = Utils.Character.GetRootPart(Char)
    local targetPos = HRP.Position
	local TargetPlayer = Players:GetPlayerFromCharacter(Char)

	-- leaving these comments here as memories from may 2025 lol -dys
	--decided to remove server-side checking because BRO. THEY DON'T DO THAT IN FORSAKEN.
	--correction: the hitboxes in Forsaken are FULLY server-handled, but it doesn't lag because THEIR GAME SOMEHOW DOESN'T LAG AT ALL. WHAT????
	--quick thing: hitboxes are now fully server-sided. yup. i had to. :(

	if DamageSettings.Damage == 0 or (Utils.Instance.FindFirstChild(Char, "Effects.StunSpawnProtection", 0) and not DamageSettings.SourcePlayer.Character:GetAttribute("BypassStunProtection")) then
		return
	end

	local Role = Char:FindFirstChild("Role")
	if Char:FindFirstChild("Killer") and Role and Role.Value == "Survivor" then
		Char.Killer.Value = DamageSettings.SourcePlayer
	end
	
	DamageSettings.Reason = DamageSettings.Reason or "HAHAHA" --OnlyIvo

	local ResistanceValue = Utils.Instance.FindFirstChild(Char, "Effects.Resistance", 0)
	if ResistanceValue and DamageSettings.Damage > 0 then
		DamageSettings.Damage /= 0.1 * ResistanceValue + 1 --since lvl 1 should do the trick already
	end

	DamageSettings.TargetHumanoid:TakeDamage(DamageSettings.Damage)

	Network:FireClientConnection(DamageSettings.SourcePlayer, "DisplayHitmarker", "REMOTE_EVENT", targetPos, DamageSettings.Damage)
	if Utils.PlayerData.GetPlayerSetting(DamageSettings.SourcePlayer, "Miscellaneous.ImageFlashOnHit") then
		Network:FireClientConnection(DamageSettings.SourcePlayer, "ShowJokeSettingImage", "REMOTE_EVENT", false, DamageSettings.SourcePlayer.Character.Role.Value)
	end

	DamageSettings.KnockbackDirection = DamageSettings.KnockbackDirection or Vector3.zero
	DamageSettings.KnockbackMagnitude = DamageSettings.KnockbackMagnitude or 1
	CommonFunctions.RigImpulse(HRP, DamageSettings.KnockbackMagnitude, DamageSettings.KnockbackDirection)

	--printing
	local targetName = Char.Name
    if workspace:GetAttribute("DebugAllowed") then
		Utils.Misc.Print("[DamageDealt] Target: "..targetName.." || InflictedDamage: "..tostring(DamageSettings.Damage).." || Reason: "..DamageSettings.Reason)
	end

	if TargetPlayer then
		Network:FireClientConnection(TargetPlayer, "DamagePlayer", "REMOTE_EVENT", DamageSettings.SourcePlayer, DamageSettings.Reason)
		if Utils.PlayerData.GetPlayerSetting(TargetPlayer, "Miscellaneous.ImageFlashOnHit") then
			Network:FireClientConnection(TargetPlayer, "ShowJokeSettingImage", "REMOTE_EVENT", true, Role and Role.Value or "Survivor")
		end
	end
	Network:FireClientConnection(DamageSettings.SourcePlayer, "DamagedPlayer", "REMOTE_EVENT", TargetPlayer, DamageSettings.TargetHumanoid, DamageSettings.Reason)
end

type ApplyEffectSettings = {
	TargetHumanoid: Humanoid,
	EffectSettings: {
		Name: string,
		Level: number?,
		Duration: number?,
		Subfolder: string?,
	},
	OverwriteExistingEffect: boolean?,
}
--- Applies an effect on a specific humanoid. It can be a player or an NPC, it doesn't matter.
function CommonFunctions.ApplyEffect(EffectSettings: ApplyEffectSettings) : NumberValue?
	if EffectSettings.OverwriteExistingEffect == nil then
		EffectSettings.OverwriteExistingEffect = true
	end

	local char = EffectSettings.TargetHumanoid.Parent

	local CharEffects = char:FindFirstChild("Effects")
	if not CharEffects then
		return
	end

	if EffectSettings.EffectSettings.Name == "Stunned" then
		if CharEffects:FindFirstChild("SpawnProtection") then
			return
		end
	end

	local ExistingEffect = CharEffects:FindFirstChild(EffectSettings.EffectSettings.Name)
	if ExistingEffect then
		if not EffectSettings.OverwriteExistingEffect then
			return
		end

		ExistingEffect:Destroy()
	end
	
	local EffectModule = Utils.Instance.GetEffectModule(EffectSettings.EffectSettings.Name, EffectSettings.EffectSettings.Subfolder)

	local EffectValue = Instance.new("NumberValue")

	EffectValue.Name = EffectSettings.EffectSettings.Name
	EffectValue.Value = EffectSettings.EffectSettings.Level or EffectModule.Level
	if EffectSettings.EffectSettings.Subfolder and #EffectSettings.EffectSettings.Subfolder > 0 then
		EffectValue:SetAttribute("Subfolder", EffectSettings.EffectSettings.Subfolder)
	end
	EffectValue:SetAttribute("Duration", EffectSettings.EffectSettings.Duration or EffectModule.Duration)

	EffectValue.Parent = CharEffects
	
	task.delay(EffectSettings.EffectSettings.Duration or EffectModule.Duration, function()
		if EffectValue then
			EffectModule:Remove(char)
			EffectValue:Destroy()
		end
	end)
	EffectModule:Apply(EffectSettings.EffectSettings.Level or EffectModule.Level, char, EffectSettings.EffectSettings.Duration or EffectModule.Duration)

	return EffectValue
end

function CommonFunctions.RemoveEffect(char: Model | Humanoid, name: string)
	char = char:IsA("Model") and char or char.Parent

	local CharEffects = char:FindFirstChild("Effects")
	if not CharEffects then
		return
	end

	local EffectInst = CharEffects:FindFirstChild(name)
	if not EffectInst then
		return
	end
	
	local EffectModule = Utils.Instance.GetEffectModule(name, EffectInst:GetAttribute("Subfolder"))
	EffectModule:Remove(char)
	EffectInst:Destroy()
end

type GrantedReward = {
	Money: number?,
	EXP: number?,
	Reason: string?,
}
--- Grants money and/or EXP to a player and displays a notification showing it.
--- The `Reason` parameter is the source of the reward to display in the UI locally.
function CommonFunctions.GrantRewardToPlayer(Player: Player, Reward: GrantedReward)
	--shouldn't give anything if in a private server
	if #game.PrivateServerId > 0 then
		return
	end

	local MoneyGranted = Reward.Money ~= nil and Reward.Money > 0 and Reward.Money or 0
	local EXPGranted = Reward.EXP ~= nil and Reward.EXP > 0 and Reward.EXP or 0
	
	--if none are granted somehow
	if MoneyGranted <= 0 and EXPGranted <= 0 then
		return
	end

	--if only EXP is granted
	if MoneyGranted <= 0 then
		CommonFunctions._GrantEXPToPlayer(Player, {Reward = Reward.EXP, Visual = true, Reason = Reward.Reason})
		return
	end

	--if only money is granted
	if EXPGranted <= 0 then
		CommonFunctions.UpdatePlayerStat(Player, "Currency.Money", MoneyGranted)
		Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", MoneyGranted, 0, Reward.Reason)
		return
	end

	--if both are granted
	CommonFunctions.UpdatePlayerStat(Player, "Currency.Money", MoneyGranted)
	CommonFunctions._GrantEXPToPlayer(Player, {Amount = EXPGranted, Visual = false, Reason = Reward.Reason})
	Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", MoneyGranted, EXPGranted, Reward.Reason)
end

type EXPGrantSettings = {
	Amount: number,
	Visual: boolean,
	Reason: string?,
}
--- INTERNAL FUNCTION: Function used to grant EXP to a player in `CommonFunctions.GrantRewardToPlayer()`. Use that one instead.
function CommonFunctions._GrantEXPToPlayer(Player: Player, GrantSettings: EXPGrantSettings)
	--shouldn't give anything if in a private server
	if #game.PrivateServerId > 0 then
		return
	end
	
	if GrantSettings.Visual then
		Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", 0, GrantSettings.Amount, GrantSettings.Reason)
	end

	local Role = Player.Character:FindFirstChild("Role")
	if not Role or Role.Value == "Spectator" then
		return
	end
	local CharacterName = Player.Character:GetAttribute("CharacterName")
	local SkinName = Player.Character:GetAttribute("CharacterSkinName")

	local CharValue = Utils.PlayerData.GetPlayerOwned(Player, Role.Value.."s."..CharacterName, false)
	CharValue.Value += GrantSettings.Amount

	local CharModule = require(Utils.Instance.GetCharacterModule(Role.Value, CharacterName))
	if CharModule.Config.Milestones then
		local CurrentLevel, _EXPRemaining, _EXPForNextLevel = Utils.Math.CalculateLevelFromEXP(CharValue.Value)
		for Level, Skin in CharModule.Config.Milestones do
			if Level <= CurrentLevel then
				CommonFunctions.GrantCharacterItemToPlayer(Player, Role.Value, CharacterName, SkinName)
			end
		end
	end
end

--- Grants a character / skin to a player.
--- 
--- Should be called from achievements or milestone granting.
function CommonFunctions.GrantCharacterItemToPlayer(Player: Player, Type: "Killer" | "Survivor", CharacterName: string, SkinName: string?)
	--shouldn't give anything if in a private server
	if #game.PrivateServerId > 0 then
		return
	end

	--checks for the parent
	--if SkinName is available, get the Skins folder
	--if not, get the role's folder
	local Parent = Utils.Instance.FindFirstChild(Player, "PlayerData.Purchased."..(SkinName and "Skins" or Type.."s"), 0)

	--if the value that's about to be created is already there, don't do anything
	if Utils.Instance.FindFirstChild(Parent, CharacterName..(SkinName and "."..SkinName or ""), 0) then
		return
	end

	--if the module supposedly doesn't exist, don't do anything
	local CharacterModule = Utils.Instance.GetCharacterModule(Type, CharacterName, SkinName)
	if not CharacterModule then
		return
	end

	--if SkinName is available, get an existing character skins's folder or create it if non-existent, then set the result as the value's parent
	if SkinName then
		local CharFolder = Parent:FindFirstChild(CharacterName)
		if not CharFolder then
			CharFolder = Instance.new("Folder")
			CharFolder.Name = CharacterName
			CharFolder.Parent = Parent
		end

		Parent = CharFolder
	end

	--create the item's value
	local Value = Instance.new("IntValue")
	Value.Name = SkinName or CharacterName --if SkinName is available, it should be named that
	Value.Parent = Parent

	--display the reward notification
	Network:FireClientConnection(Player, "ShowRewardNotification", "REMOTE_EVENT", CharacterModule, "QuotedGranted"..(SkinName and "Skin" or "Character"))
end

--- Grants an emote to a player.
--- 
--- Should be called from achievements or milestone granting.
function CommonFunctions.GrantEmoteToPlayer(Player: Player, EmoteName: string)
	--shouldn't give anything if in a private server
	if #game.PrivateServerId > 0 then
		return
	end

	--checks for the parent
	--if SkinName is available, get the Skins folder
	--if not, get the role's folder
	local Parent = Utils.Instance.FindFirstChild(Player, "PlayerData.Purchased.Emotes", 0)

	--if the module supposedly doesn't exist, don't do anything
	local EmoteModule = Utils.Instance.GetEmoteModule(EmoteName)
	if not EmoteModule then
		return
	end

	--create the item's value
	local Value = Instance.new("IntValue")
	Value.Name = EmoteName --if SkinName is available, it should be named that
	Value.Parent = Parent

	--display the reward notification
	Network:FireClientConnection(Player, "ShowRewardNotification", "REMOTE_EVENT", EmoteModule, "QuotedGrantedEmote")
end

--- Updates a player's stat specified by a `string` path.
--- Stats are all either `int`s or `number`s.
function CommonFunctions.UpdatePlayerStat(Player: Player, path: string, amount: number)
    local Stat = Utils.Instance.FindFirstChild(Player, "PlayerData.Stats."..path)
	if Stat then
		Stat.Value += amount
	else
		warn("[CommonFunctions.UpdatePlayerStat()] Couldn't find stat "..path.."!")
	end
end

--- Function used instead of the typical `Player:Kick()` to auto-generate an anti-cheat kick message and keep consistency.
--- Use `Utils.KickIDs`.
function CommonFunctions.KickPlayer(Player: Player, KickMessage: {
    ID: string,
    Message: string,
})

    Player:Kick("\n\n[DysMemberer] "..KickMessage.ID..":\n"..KickMessage.Message.."\n")
end

--- Sets a player's progress of a specific achievement.
--- 
--- Useful for milestone achievements.
function CommonFunctions.SetAchievementProgress(Player: Player, AchievementPath: string, Amount: number)
	local SplitPath = Utils.Type.SplitStringPath(AchievementPath)
	local Achievement: Types.Achievement = Achievements
	for _, step in SplitPath do
		Achievement = Achievement[step]
		if not Achievement then
			warn("[CommonFunctions.SetAchievementProgress] Achievement from path "..AchievementPath.." not found!", debug.traceback())
			return
		end
	end
	if not Achievement.Requirement then
		warn("[CommonFunctions.SetAchievementProgress] Achievement from path "..AchievementPath.." doesn't have a numeric requirement! If this is intentional, make sure to use `CommonFunctions.CompleteAchievement()` instead!", debug.traceback())
		return
	end

	local AValue = Utils.PlayerData.GetAchievementObject(Player, AchievementPath)

	if Amount >= Achievement.Requirement then
		task.defer(CommonFunctions.CompleteAchievement, Player, AchievementPath)
		return
	end

	AValue.Value = Amount
end

--- Increments a player's progress of a specific achievement.
function CommonFunctions.IncrementAchievementProgress(Player: Player, AchievementPath: string, Amount: number)
	local SplitPath = Utils.Type.SplitStringPath(AchievementPath)
	local Achievement: Types.Achievement = Achievements
	for _, step in SplitPath do
		Achievement = Achievement[step]
		if not Achievement then
			warn("[CommonFunctions.IncrementAchievementProgress] Achievement from path "..AchievementPath.." not found!", debug.traceback())
			return
		end
	end
	if not Achievement.Requirement then
		warn("[CommonFunctions.IncrementAchievementProgress] Achievement from path "..AchievementPath.." doesn't have a numeric requirement! If this is intentional, make sure to use `CommonFunctions.CompleteAchievement()` instead!", debug.traceback())
		return
	end

	local AValue = Utils.PlayerData.GetAchievementObject(Player, AchievementPath)

	if AValue.Value + Amount >= Achievement.Requirement then
		task.defer(CommonFunctions.CompleteAchievement, Player, AchievementPath)
		return
	end

	AValue.Value += Amount
end

--- Grants a player an achievement instantly.
--- 
--- Useful to grant boolean achievements or just complete achievements that have a numeric requirement.
--- 
--- ### ANY CALLS TO THIS FUNCTION SHOULD BE DEFERRED IF THE ACHIEVEMENT TO GRANT HAS A `BadgeId` PROPERTY SET!
function CommonFunctions.CompleteAchievement(Player: Player, AchievementPath: string)
	print(`Granting achievement "{AchievementPath}"...`)
	local SplitPath = Utils.Type.SplitStringPath(AchievementPath)
	local Achievement: Types.Achievement = Achievements[SplitPath[1]].Achievements[SplitPath[2]]
	if not Achievement then
		warn("[CommonFunctions.CompleteAchievement] Achievement from path "..AchievementPath.." not found!", debug.traceback())
		return
	end

	Utils.Instance.FindFirstChild(Player, "PlayerData.Achievements."..AchievementPath).Value = Achievement.Requirement or true

	--granting achievement reward
	task.defer(function()
		if not Achievement.RewardType then
			return
		end

		if Achievement.RewardType == "Currency" then
			CommonFunctions.UpdatePlayerStat(Player, "Currency.Money", Achievement.Amount)
			return
		end

		if Achievement.RewardType == "Emote" then
			CommonFunctions.GrantEmoteToPlayer(Player, Achievement.Item)
			return
		end

		CommonFunctions.GrantCharacterItemToPlayer(Player,
			Achievement.CharacterRole,
			Achievement.Item,
			Achievement.RewardType == "Skin" and Achievement.Skin or nil
		)
	end)

	--display the reward notification
	Network:FireClientConnection(Player, "ShowRewardNotification", "REMOTE_EVENT", AchievementPath, "Achievement")

	--grant the badge if applicable
	if Achievement.BadgeID then
		BadgeService:AwardBadgeAsync(Player.UserId, Achievement.BadgeID)
	end
end

--- Gets a player's permission rank.
function CommonFunctions.GetPlayerPermissionRank(Player: Player): number
	local HighestPlayerRank = Utils.Ranks.DefaultPlayer
	for _, Permission in CommonFunctions.AdminPerms do
		if Permission.UserId == Player.UserId then
			local Value = Utils.Ranks[Permission.Rank] or tonumber(Permission.Rank) or Utils.Ranks.DefaultPlayer
			if Value < HighestPlayerRank then
				HighestPlayerRank = Value
			end
		end
	end

	return HighestPlayerRank
end

--- Checks if a player has a specific permission rank or higher.
--- The minimum rank should be grabbed from `CommonFunctions.Ranks` through its name.
--- Inputting a number is still possible but the existing ranks should be checked.
--- @return Will return if the player has the specified rank and its actual rank.
function CommonFunctions.PlayerHasPermissionRank(Player: Player, MandatoryRank: string | number): (boolean, number)
	local Rank = CommonFunctions.GetPlayerPermissionRank(Player)
	return Rank < (typeof(MandatoryRank) == "string" and Utils.Ranks[MandatoryRank] or MandatoryRank), Rank
end

function CommonFunctions.RigImpulse(Rig: Model | BasePart, magnitude: number, direction: Vector3, allowAssembly: boolean?)
	if magnitude <= 0 or direction == Vector3.zero then
		return
	end

	if allowAssembly == nil then
		allowAssembly = true
	end

	local HRP = Rig:IsA("Model") and Utils.Character.GetRootPart(Rig) or Rig

	-- If the knockback property of the hitbox is greater than 15, fling the target(?) -itred
	-- FLINGING GO BOOM -dys
	if magnitude >= 15 and allowAssembly then
		HRP.AssemblyLinearVelocity = direction * magnitude * 10
	
	-- Otherwise, lightly push the target instead. -itred
	--using linearvel generally works better with less than 15 magnitude -dys
	elseif magnitude > 0 then
		local Att = Instance.new("Attachment")
        Att.Name = "LVAtt"
        Att.Parent = HRP

        local LinearVel = Instance.new("LinearVelocity")
        LinearVel.MaxForce = 16000
        LinearVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
        LinearVel.LineVelocity = magnitude * 10
        LinearVel.LineDirection = direction
        LinearVel.Attachment0 = Att
        LinearVel.Parent = HRP

        Debris:AddItem(Att, 0.05)
        Debris:AddItem(LinearVel, 0.05)
	end
end

function CommonFunctions.GivePhysicalItemToPlayer(Player: Player, Item: Types.Item)
	if not Player.Character then
		return
	end

	if not Item then
		return
	end

	Utils.Type.CopyTable(Item):Init(Player)
end

return CommonFunctions
