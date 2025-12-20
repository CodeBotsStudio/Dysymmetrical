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

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Achievements = require(ReplicatedStorage.Assets.Achievements)
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

--- Function that should be used to damage a player from another player's attack.
--- Handles resistance, weakness...
function CommonFunctions.DamagePlayer(sourcePlayer: Player, targetHumanoid: Humanoid, inflictedDamage: number, reason: string?, knockbackDirection: Vector3?, knockbackMagnitude: number?)
    local Char = targetHumanoid.Parent
	local HRP: BasePart = Char.HumanoidRootPart
    local targetPos = HRP.Position
	local Player = Players:GetPlayerFromCharacter(Char)

	-- leaving these comments here as memories from may 2025 lol -dys
	--decided to remove server-side checking because BRO. THEY DON'T DO THAT IN FORSAKEN.
	--correction: the hitboxes in Forsaken are FULLY server-handled, but it doesn't lag because THEIR GAME SOMEHOW DOESN'T LAG AT ALL. WHAT????
	--quick thing: hitboxes are now fully server-sided. yup. i had to. :(

	if Utils.Instance.FindFirstChild(Char, "Effects.StunSpawnProtection", 0) and not sourcePlayer.Character:GetAttribute("BypassStunProtection") then
		return
	end

	local Role = Utils.Instance.FindFirstChild(Char, "Role", 0.2)
	if Char:FindFirstChild("Killer") and Role and Role.Value == "Survivor" then
		Char.Killer.Value = sourcePlayer
	end
	
	reason = reason or "HAHAHA" --OnlyIvo

	if Utils.Instance.FindFirstChild(Char, "Effects.Resistance", 0) then
		inflictedDamage /= 0.1 * Char.Effects.Resistance.Value + 1 --since lvl 1 should do the trick already
	end

	targetHumanoid.Health -= inflictedDamage

	Network:FireClientConnection(sourcePlayer, "DisplayHitmarker", "REMOTE_EVENT", targetPos, inflictedDamage)
	if Utils.PlayerData.GetPlayerSetting(sourcePlayer, "Miscellaneous.ImageFlashOnHit") then
		Network:FireClientConnection(sourcePlayer, "ShowJokeSettingImage", "REMOTE_EVENT", false, sourcePlayer.Character.Role.Value)
	end

	knockbackDirection = knockbackDirection or Vector3.zero
	knockbackMagnitude = knockbackMagnitude or 1
	CommonFunctions.RigImpulse(HRP, knockbackMagnitude, knockbackDirection)

	--printing
	local targetName = Char.Name or "Dummy"
    if workspace:GetAttribute("DebugAllowed") then
		Utils.Misc.Print("[DamageDealt] Target: "..targetName.." || InflictedDamage: "..tostring(inflictedDamage).." || Reason: "..tostring(reason))
	end

	if Player then
		Network:FireClientConnection(Player, "DamagePlayer", "REMOTE_EVENT", sourcePlayer, reason)
		if Utils.PlayerData.GetPlayerSetting(Player, "Miscellaneous.ImageFlashOnHit") then
			Network:FireClientConnection(Player, "ShowJokeSettingImage", "REMOTE_EVENT", true, Role and Role.Value or "Survivor")
		end
	end
	Network:FireClientConnection(sourcePlayer, "DamagedPlayer", "REMOTE_EVENT", Player, targetHumanoid, reason)
end

--- Applies an effect on a specific humanoid. It can be a player or an NPC, it doesn't matter.
function CommonFunctions.ApplyEffect(hum: Humanoid, name: string, level: number?, duration: number?, subfolder: string?, overwriteExisting: boolean?) : NumberValue?
	if overwriteExisting == nil then
		overwriteExisting = true
	end

	local char = hum.Parent

	local CharEffects = char:FindFirstChild("Effects")
	if not CharEffects then
		return
	end

	if name == "Stunned" then
		if CharEffects:FindFirstChild("SpawnProtection") then
			return
		end
	end

	local ExistingEffect = CharEffects:FindFirstChild(name)
	if ExistingEffect then
		if not overwriteExisting then
			return
		end

		ExistingEffect:Destroy()
	end
	
	local EffectModule = Utils.Instance.GetEffectModule(name, subfolder)

	local EffectValue = Instance.new("NumberValue")

	EffectValue.Name = name
	EffectValue.Value = level or EffectModule.Level
	if subfolder and #subfolder > 0 then
		EffectValue:SetAttribute("Subfolder", subfolder)
	end
	EffectValue:SetAttribute("Duration", duration or EffectModule.Duration)

	EffectValue.Parent = CharEffects
	
	task.delay(duration, function()
		if EffectValue then
			EffectModule:Remove(char)
			EffectValue:Destroy()
		end
	end)
	EffectModule:Apply(level, char, duration or EffectModule.Duration)

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

--- Grants money and/or EXP to a player and displays a notification showing it.
--- The `Reason` parameter is the source of the reward to display in the UI locally.
function CommonFunctions.GrantRewardToPlayer(Player: Player, Money: number?, EXP: number?, Reason: string?)
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
		CommonFunctions._GrantEXPToPlayer(Player, EXP, true, Reason)
		return
	end

	--if only money is granted
	if EXPGranted <= 0 then
		CommonFunctions.UpdatePlayerStat(Player, "Currency.Money", MoneyGranted)
		Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", MoneyGranted, 0, Reason)
		return
	end

	--if both are granted
	CommonFunctions.UpdatePlayerStat(Player, "Currency.Money", MoneyGranted)
	CommonFunctions._GrantEXPToPlayer(Player, EXPGranted, false, Reason)
	Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", MoneyGranted, EXPGranted, Reason)
end

--- INTERNAL FUNCTION: Function used to grant EXP to a player in `CommonFunctions.GrantRewardToPlayer()`. Use that one instead.
function CommonFunctions._GrantEXPToPlayer(Player: Player, amount: number, visual: boolean, Reason: string?)
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
	local SkinName = Player.Character:GetAttribute("CharacterSkinName")

	local CharValue = Utils.PlayerData.GetPlayerOwned(Player, Role.Value.."s."..CharacterName, false)
	CharValue.Value += amount

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
function CommonFunctions.GrantCharacterItemToPlayer(Player: Player, Type: "Killer" | "Survivor", CharacterName: string, SkinName: string)
	--shouldn't give anything if in a private server
	if #game.PrivateServerId > 0 then
		return
	end

	--checks for the parent
	--if SkinName is available, get the Skins folder
	--if not, get the role's folder
	local Parent = Utils.Instance.FindFirstChild(Player, "PlayerData.Purchased."..(SkinName and "Skins" or Type.."s"), 0)

	--if the value that's about to be created is already there, don't do anything
	if Utils.Instance.FindFirstChild(Parent, CharacterName..("."..SkinName or ""), 0) then
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

--TODO: Achievement UI
--- Increments a player's progress of a specific achievement.
function CommonFunctions.IncrementAchievementProgress(Player: Player, AchievementPath: string, Amount: number)
	local SplitPath = Utils.Type.SplitStringPath(AchievementPath)
	local Achievement: Achievements.Achievement = Achievements
	for _, step in SplitPath do
		Achievement = Achievement[step]
		if not Achievement then
			warn("[CommonFunctions.IncrementAchievementProgress] Achievement from path "..AchievementPath.." not found!", debug.traceback())
			return
		end
	end
	if not Achievement.Requirement then
		warn("[CommonFunctions.IncrementAchievementProgress] Achievement from path "..AchievementPath.." doesn't have a numeric requirement!", debug.traceback())
		return
	end

	local AValue = Utils.Instance.FindFirstChild(Player, "PlayerData.Achievements."..AchievementPath)
	if AValue.Value + Amount >= Achievement.Requirement then
		CommonFunctions.CompleteAchievement(Player, AchievementPath)
	else
		AValue.Value += Amount
	end
end

--- Grants a player an achievement instantly.
--- Useful to grant boolean achievements or just complete achievements that have a numeric requirement.
function CommonFunctions.CompleteAchievement(Player: Player, AchievementPath: string)
	local SplitPath = Utils.Type.SplitStringPath(AchievementPath)
	local Achievement: Achievements.Achievement = Achievements
	for _, step in SplitPath do
		Achievement = Achievement[step]
		if not Achievement then
			warn("[CommonFunctions.CompleteAchievement] Achievement from path "..AchievementPath.." not found!", debug.traceback())
			return
		end
	end

	--TODO: achievement rewards
	if Achievement.Requirement then
		Utils.Instance.FindFirstChild(Player, "PlayerData.Achievements."..AchievementPath).Value = Achievement.Requirement
	else
		local AValue = Instance.new("BoolValue")
		AValue.Name = SplitPath[#SplitPath]
		AValue.Value = true
		local InstPath = SplitPath[1]
		for index, step in SplitPath do
			if index == 1 or index == #SplitPath then
				continue
			end

			InstPath = InstPath.."."..step
		end
		AValue.Parent = Utils.Instance.FindFirstChild(Player, "PlayerData.Achievements."..InstPath)
	end

	Network:FireClientConnection(Player, "CompletedAchievement", "REMOTE_EVENT", Achievement)
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

	local HRP = Rig:IsA("Model") and Rig:FindFirstChild("HumanoidRootPart") or Rig

	-- If the knockback property of the hitbox is greater than 15, fling the target(?) -itrid
	-- FLINGING GO BOOM -dys
	if magnitude >= 15 and allowAssembly then
		HRP.AssemblyLinearVelocity = direction * magnitude * 10
	
	-- Otherwise, lightly push the target instead. -itrid
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

return CommonFunctions
