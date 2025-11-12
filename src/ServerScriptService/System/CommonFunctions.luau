--!nocheck

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
	Ranks = {
		Owner = 1,
		LeadDeveloper = 5,
		HeadModerator = 10,
		Moderator = 15,
		Developer = 18,
		ServerOwner = 20,
		DefaultPlayer = 30,
	},
	AdminPerms = {
		{
			Name = "Dyscarn",
			UserId = 432073982,
			Rank = "Developer",
		},
	},
}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Achievements = require(ReplicatedStorage.Assets.Achievements)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)

function Utils:Init()
	Network:SetConnection("GetPermRank", "REMOTE_FUNCTION", function(Player: Player): number
		return self:GetPlayerPermissionRank(Player)
	end)
	Network:SetConnection("HasPermRank", "REMOTE_FUNCTION", function(Player: Player, Rank: string | number): boolean
		return self:PlayerHasPermissionRank(Player, Rank)
	end)
end

--- Function that should be used to damage a player from another player's attack.
--- Handles resistance, weakness...
function CommonFunctions:DamagePlayer(sourcePlayer: Player, targetHumanoid: Humanoid, inflictedDamage: number, reason: string?, knockbackDirection: Vector3?, knockbackMagnitude: number?)
    local Char = targetHumanoid.Parent
	local HRP: BasePart = Char.HumanoidRootPart
    local targetPos = HRP.Position
	local Player = Players:GetPlayerFromCharacter(Char)

	--decided to remove server-side checking because BRO. THEY DON'T DO THAT IN FORSAKEN.
	--correction: the hitboxes in Forsaken are FULLY server-handled, but it doesn't lag because THEIR GAME SOMEHOW DOESN'T LAG AT ALL. WHAT????
	--quick thing: hitboxes are now fully server-sided. yup. i had to. :(

	if Utils:FindFirstChild(Char, "Effects.StunSpawnProtection", false) and not sourcePlayer.Character:GetAttribute("BypassStunProtection") then
		return
	end

	if Utils:FindFirstChild(Char, "Role") and Char.Role.Value == "Survivor" then
		Char.Killer.Value = sourcePlayer
	end
	
	reason = reason or "HAHAHA https://www.youtube.com/watch?v=L8XbI9aJOXk" --OnlyIvo

	if Utils:FindFirstChild(Char, "Effects.Resistance", false) then
		inflictedDamage /= 0.1 * Char.Effects.Resistance.Value + 1 --since lvl 1 should do the trick already
	end

	targetHumanoid:TakeDamage(inflictedDamage)

	Network:FireClientConnection(sourcePlayer, "DisplayHitmarker", "REMOTE_EVENT", targetPos, inflictedDamage)
	if Utils:GetPlayerSetting(sourcePlayer, "Miscellaneous.ImageFlashOnHit") then
		Network:FireClientConnection(sourcePlayer, "ShowJokeSettingImage", "REMOTE_EVENT", false, sourcePlayer.Character.Role.Value)
	end

	knockbackDirection = knockbackDirection or Vector3.zero
	if knockbackDirection ~= Vector3.zero then
		knockbackMagnitude = knockbackMagnitude or 1
		if knockbackMagnitude >= 15 then
			HRP.AssemblyLinearVelocity = knockbackDirection * knockbackMagnitude * 10
			
		--using bodyvel generally works better with less than 15 magnitude
		elseif knockbackMagnitude > 0 then
			local BodyVel = Instance.new("BodyVelocity")
			BodyVel.Name = "Knockback"
			BodyVel.MaxForce = Vector3.new(1e999, 1e999, 1e999)
			BodyVel.Velocity = knockbackDirection * knockbackMagnitude * 10
			BodyVel.Parent = HRP
			Debris:AddItem(BodyVel, 0.05)
		end
	end

	--printing
	local targetName = Char.Name or "Dummy"
    if workspace:GetAttribute("DebugAllowed") then
		Utils:Print("[DamageDealt] Target: "..targetName.." || InflictedDamage: "..tostring(inflictedDamage).." || Reason: "..tostring(reason))
	end

	if Player then
		Network:FireClientConnection(Player, "DamagePlayer", "REMOTE_EVENT", sourcePlayer, reason)
		if Utils:GetPlayerSetting(Player, "Miscellaneous.ImageFlashOnHit") then
			Network:FireClientConnection(Player, "ShowJokeSettingImage", "REMOTE_EVENT", true, Utils:FindFirstChild(Char, "Role") and Char.Role.Value or "Survivor")
		end
	end
	Network:FireClientConnection(sourcePlayer, "DamagedPlayer", "REMOTE_EVENT", Player, targetHumanoid, reason)
end

--- Applies an effect on a specific humanoid. It can be a player or an NPC, it doesn't matter.
function CommonFunctions:ApplyEffect(hum: Humanoid, name: string, level: number?, duration: number?, subfolder: string?)
	local char = hum.Parent

	if name == "Stunned" then
		if Utils:FindFirstChild(char, "Effects"):FindFirstChild("SpawnProtection") then
			return
		end
	end
	
	local EffectModule = Utils:GetEffectModule(name, subfolder)
	local EffectValue = Utils:FindFirstChild(char, "Effects."..name, false) or Instance.new("NumberValue")

	EffectValue.Name = name
	EffectValue.Value = level or EffectModule.Level
	if subfolder and #subfolder > 0 then
		EffectValue:SetAttribute("Subfolder", subfolder)
	end
	EffectValue:SetAttribute("Duration", duration or EffectModule.Duration)

	EffectValue.Parent = Utils:FindFirstChild(char, "Effects")
	
	task.delay(duration, function()
		if EffectValue then
			EffectModule:Remove(char)
			EffectValue:Destroy()
		end
	end)
	EffectModule:Apply(level, char, duration or EffectModule.Duration)
end

--- Grants money and/or EXP to a player and displays a notification showing it.
--- The `Reason` parameter is the source of the reward to display in the UI locally.
function CommonFunctions:GrantRewardToPlayer(Player: Player, Money: number?, EXP: number?, Reason: string?)
	--shouldn't give anything if in a private server
	if #game.PrivateServerId > 0 then
		return
	end

	local MoneyGranted = Money ~= nil and Money > 0 and Money or 0
	local EXPGranted = EXP ~= nil and EXP > 0 and EXP or 0
	
	--if none are granted somehow
	if MoneyGranted <= 0 and EXPGranted <= 0 then
		return
	end

	--if only EXP is granted
	if MoneyGranted <= 0 then
		self:_GrantEXPToPlayer(Player, EXP, true, Reason)
		return
	end

	--if only money is granted
	if EXPGranted <= 0 then
		self:UpdatePlayerStat(Player, "Currency.Money", MoneyGranted)
		Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", MoneyGranted, 0, Reason)
		return
	end

	--if both are granted
	self:UpdatePlayerStat(Player, "Currency.Money", MoneyGranted)
	self:_GrantEXPToPlayer(Player, EXPGranted, false, Reason)
	Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", MoneyGranted, EXPGranted, Reason)
end

--- INTERNAL FUNCTION: Function used to grant EXP to a player in `CommonFunctions:GrantRewardToPlayer()`. Use that one instead.
function CommonFunctions:_GrantEXPToPlayer(Player: Player, amount: number, visual: boolean, Reason: string?)
	--shouldn't give anything if in a private server
	if #game.PrivateServerId > 0 then
		return
	end
	
	if visual then
		Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", 0, amount, Reason)
	end

	local Role = Player.Character:FindFirstChild("Role")
	if not Role or Role.Value == "Spectator" then
		return
	end
	local CharacterName = Player.Character:GetAttribute("CharacterName")

	local CharValue = Utils:GetPlayerOwned(Player, Role.Value.."s."..CharacterName, false)
	CharValue.Value += amount
end

--- Updates a player's stat specified by a `string` path.
--- Stats are all either `int`s or `number`s.
function CommonFunctions:UpdatePlayerStat(Player: Player, path: string, amount: number)
    local Stat = Utils:FindFirstChild(Player, "PlayerData.Stats."..path)
	if Stat then
		Stat.Value += amount
	else
		warn("[CommonFunctions:UpdatePlayerStat()] Couldn't find stat "..path.."!")
	end
end

--- Function used instead of the typical `Player:Kick()` to auto-generate an anti-cheat kick message and keep consistency.
--- Use `Utils.KickIDs`.
function CommonFunctions:KickPlayer(Player: Player, KickMessage: {
    ID: string,
    Message: string,
})

    Player:Kick("\n\n[DysMemberer] "..KickMessage.ID..":\n"..KickMessage.Message.."\n")
end

--TODO: Achievement UI
--- Increments a player's progress of a specific achievement.
function CommonFunctions:IncrementAchievementProgress(Player: Player, AchievementPath: string, Amount: number)
	local SplitPath = Utils:SplitStringPath(AchievementPath)
	local Achievement: Achievements.Achievement = Achievements
	for _, step in SplitPath do
		Achievement = Achievement[step]
		if not Achievement then
			warn("[CommonFunctions:IncrementAchievementProgress] Achievement from path "..AchievementPath.." not found!", debug.traceback())
			return
		end
	end
	if not Achievement.Requirement then
		warn("[CommonFunctions:IncrementAchievementProgress] Achievement from path "..AchievementPath.." doesn't have a numeric requirement!", debug.traceback())
		return
	end

	local AValue = Utils:FindFirstChild(Player, "PlayerData.Achievements."..AchievementPath)
	if AValue.Value + Amount >= Achievement.Requirement then
		self:CompleteAchievement(Player, AchievementPath)
	else
		AValue.Value += Amount
	end
end

--- Grants a player an achievement instantly.
--- Useful to grant boolean achievements or just complete achievements that have a numeric requirement.
function CommonFunctions:CompleteAchievement(Player: Player, AchievementPath: string)
	local SplitPath = Utils:SplitStringPath(AchievementPath)
	local Achievement: Achievements.Achievement = Achievements
	for _, step in SplitPath do
		Achievement = Achievement[step]
		if not Achievement then
			warn("[CommonFunctions:CompleteAchievement] Achievement from path "..AchievementPath.." not found!", debug.traceback())
			return
		end
	end

	--TODO: achievement rewards
	if Achievement.Requirement then
		Utils:FindFirstChild(Player, "PlayerData.Achievements."..AchievementPath).Value = Achievement.Requirement
	else
		local AValue = Instance.new("BoolValue")
		AValue.Name = SplitPath[#SplitPath]
		AValue.Value = true
		local InstPath = SplitPath[1]
		for i, step in SplitPath do
			if i == 1 or i == #SplitPath then
				continue
			end

			InstPath = InstPath.."."..step
		end
		AValue.Parent = Utils:FindFirstChild(Player, "PlayerData.Achievements."..InstPath)
	end

	Network:FireClientConnection(Player, "CompletedAchievement", "REMOTE_EVENT", Achievement)
end

--- Gets a player's permission rank.
function CommonFunctions:GetPlayerPermissionRank(Player: Player): number
	for _, i in self.AdminPerms do
		if i.UserId == Player.UserId then
			return self.Ranks[i.Rank] or tonumber(i.Rank) or self.Ranks.DefaultPlayer
		end
	end

	return self.Ranks.DefaultPlayer
end

--- Checks if a player has a specific permission rank or higher.
--- The minimum rank should be grabbed from `CommonFunctions.Ranks` through its name.
--- Inputting a number is still possible but the existing ranks should be checked.
--- @return Will return if the player has the specified rank and its actual rank.
function CommonFunctions:PlayerHasPermissionRank(Player: Player, MandatoryRank: string | number): (boolean, number)
	local Rank = self:GetPlayerRank(Player)
	return Rank < (typeof(MandatoryRank) == "string" and self.Ranks[MandatoryRank] or MandatoryRank), Rank
end

return CommonFunctions
