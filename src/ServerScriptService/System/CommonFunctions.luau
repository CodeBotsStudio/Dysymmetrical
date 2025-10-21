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
}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Achievements = require(ReplicatedStorage.Assets.Achievements)
local CommonUtils = require(ReplicatedStorage.Modules.CommonUtils)
local Network = require(ReplicatedStorage.Modules.Network)

local DominoEffectModule = require(ReplicatedStorage.Effects.SurvivorSpecific.DominoEffect)

--- Function that should be used to damage a player from another player's attack.
--- Handles blocking, resistance, weakness...
function CommonFunctions:DamagePlayer(sourcePlayer: Player, targetHumanoid: Humanoid, inflictedDamage: number, reason: string?, knockbackDirection: Vector3?, knockbackMagnitude: number?)
    local Char = targetHumanoid.Parent
	local HRP: BasePart = Char.HumanoidRootPart
    local targetPos = HRP.Position
	local Player = Players:GetPlayerFromCharacter(Char)

	--decided to remove server-side checking because BRO. THEY DON'T DO THAT IN FORSAKEN.
	--correction: the hitboxes in Forsaken are FULLY server-handled, but it doesn't lag because THEIR GAME SOMEHOW DOESN'T LAG AT ALL. WHAT????
	--quick thing: hitboxes are now fully server-sided. yup. i had to. :(

	if CommonUtils:FindFirstChild(Char, "Role") and Char.Role.Value == "Survivor" then
		Char.Killer.Value = sourcePlayer
	end
	
	reason = reason or "HAHAHA https://www.youtube.com/watch?v=L8XbI9aJOXk" --OnlyIvo

	if CommonUtils:FindFirstChild(Char, "PlayerAttributes.Effects.Resistance", false) then
		inflictedDamage /= Char.PlayerAttributes.Effects.Resistance.Value + 1 --since lvl 1 should do the trick already
	end

	if not CommonUtils:FindFirstChild(Char, "Effects.Blocking", false) then
		targetHumanoid:TakeDamage(inflictedDamage)
	else
		self:ApplyEffect(sourcePlayer.Character:FindFirstChildOfClass("Humanoid"), "Slowness", 6, 2, "KillerSpecific")
		self:ApplyEffect(sourcePlayer.Character:FindFirstChildOfClass("Humanoid"), "Helpless", 1, 2, "KillerSpecific")
	end
	
	--NOTE: this is from Driftwood and you can use it as an example.
	if CommonUtils:FindFirstChild(Char, "Effects.Domino Effect", false) and table.find(DominoEffectModule.Attacks, reason) then
		Network:FireClientConnection(sourcePlayer, "ExecuteReplicatedModule", "REMOTE_EVENT", ReplicatedStorage.Effects.SurvivorSpecific.DominoEffect.ApplyInk:GetFullName())
		Char.Effects["Domino Effect"]:Destroy()
		CommonUtils:GetEffectModule("Domino Effect", "SurvivorSpecific"):Remove(Char)
	end

	Network:FireClientConnection(sourcePlayer, "DisplayHitmarker", "REMOTE_EVENT", targetPos, inflictedDamage)
	if CommonUtils:GetPlayerSetting(sourcePlayer, "Miscellaneous.ImageFlashOnHit") then
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
		CommonUtils:Print("[DamageDealt] Target: "..targetName.." || InflictedDamage: "..tostring(inflictedDamage).." || Reason: "..tostring(reason))
	end

	if Player then
		Network:FireClientConnection(Player, "DamagePlayer", "REMOTE_EVENT", sourcePlayer, reason)
		if CommonUtils:GetPlayerSetting(Player, "Miscellaneous.ImageFlashOnHit") then
			Network:FireClientConnection(Player, "ShowJokeSettingImage", "REMOTE_EVENT", true, CommonUtils:FindFirstChild(Char, "Role") and Char.Role.Value or "Survivor")
		end
	end
	Network:FireClientConnection(sourcePlayer, "DamagedPlayer", "REMOTE_EVENT", Player, targetHumanoid, reason)
end

--- Applies an effect on a specific humanoid. It can be a player or an NPC, it doesn't matter.
function CommonFunctions:ApplyEffect(hum: Humanoid, name: string, level: number?, duration: number?, subfolder: string?)
	local char = hum.Parent
	local EffectModule = CommonUtils:GetEffectModule(name, subfolder)

	local EffectValue = Instance.new("NumberValue")

	EffectValue.Name = name
	EffectValue.Value = level or EffectModule.Level
	if subfolder and #subfolder > 0 then
		EffectValue:SetAttribute("Subfolder", subfolder)
	end
	EffectValue:SetAttribute("Duration", duration or EffectModule.Duration)

	EffectValue.Parent = CommonUtils:FindFirstChild(char, "Effects")
	
	task.delay(duration, function()
		if EffectValue then
			EffectModule:Remove(char)
			EffectValue:Destroy()
		end
	end)
	EffectModule:Apply(level, char, duration or EffectModule.Duration)
end

--TODO: make a UI for this
--- Grants money and/or EXP to a player and displays a notification showing it.
--- The `Reason` parameter is the source of the reward to display in the UI locally.
function CommonFunctions:GrantRewardToPlayer(Player: Player, Money: number?, EXP: number?, Reason: string?)
	--shouldn't give anything if in a private server
	if #game.PrivateServerId > 0 then
		return
	end

	local MoneyGranted = Money ~= nil and Money > 0 and Money or 0
	local EXPGranted = EXP ~= EXP and EXP > 0 and EXP or 0
	
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

	local CharValue = CommonUtils:GetPlayerOwned(Player, Role.Value.."s."..CharacterName, false)
	CharValue.Value += amount
end

--- Updates a player's stat specified by a `string` path.
--- Stats are all either `int`s or `number`s.
function CommonFunctions:UpdatePlayerStat(Player: Player, path: string, amount: number)
    local Stat = CommonUtils:FindFirstChild(Player, "PlayerData.Stats."..path)
	if Stat then
		Stat.Value += amount
	else
		warn("[CommonFunctions:UpdatePlayerStat()] Couldn't find stat "..path.."!")
	end
end

--- Function used instead of the typical `Player:Kick()` to auto-generate an anti-cheat kick message and keep consistency.
--- Use `CommonUtils.KickIDs`.
function CommonFunctions:KickPlayer(Player: Player, KickMessage: {
    ID: string,
    Message: string,
})

    Player:Kick("\n\n[DysMemberer] "..KickMessage.ID..":\n"..KickMessage.Message.."\n")
end

--TODO: Achievement UI
--- Increments a player's progress of a specific achievement.
function CommonFunctions:IncrementAchievementProgress(Player: Player, AchievementPath: string, Amount: number)
	local SplitPath = CommonUtils:SplitStringPath(AchievementPath)
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

	local AValue = CommonUtils:FindFirstChild(Player, "PlayerData.Achievements."..AchievementPath)
	if AValue.Value + Amount >= Achievement.Requirement then
		self:CompleteAchievement(Player, AchievementPath)
	else
		AValue.Value += Amount
	end
end

--- Grants a player an achievement instantly.
--- Useful to grant boolean achievements or just complete achievements that have a numeric requirement.
function CommonFunctions:CompleteAchievement(Player: Player, AchievementPath: string)
	local SplitPath = CommonUtils:SplitStringPath(AchievementPath)
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
		CommonUtils:FindFirstChild(Player, "PlayerData.Achievements."..AchievementPath).Value = Achievement.Requirement
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
		AValue.Parent = CommonUtils:FindFirstChild(Player, "PlayerData.Achievements."..InstPath)
	end

	Network:FireClientConnection(Player, "CompletedAchievement", "REMOTE_EVENT", Achievement)
end

return CommonFunctions
