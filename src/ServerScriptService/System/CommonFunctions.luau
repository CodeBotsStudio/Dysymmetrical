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
		--- Kick message displayed when taking too long to send a specific RemoteEvent related to security.
		SecurityRemoteTimeout = {
			ID = "0003",
			Message = "Client Security Remote Send Timeout",
		},
		StaminaSurpass = {
			ID = "0004",
			Message = "Player assumed to be bypassing max stamina.",
		},
		--- Kick message displayed when firing a Remote instance too many times in a short time.
		RemoteExhaustion = {
			ID = "0005",
			Message = "Player assumed to be exhausting a (handled) Remote instance purposefully.",
		},
	},
}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

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

	if Char:FindFirstChild("Role") and Char.Role.Value == "Survivor" then
		Char.Killer.Value = sourcePlayer
	end
	
	reason = reason or "HAHAHA https://www.youtube.com/watch?v=L8XbI9aJOXk" --OnlyIvo

	if Char:FindFirstChild("PlayerAttributes") and Char.PlayerAttributes:FindFirstChild("Effects") and Char.PlayerAttributes.Effects:FindFirstChild("Resistance") then
		inflictedDamage /= Char.PlayerAttributes.Effects.Resistance.Value + 1 --since lvl 1 should do the trick already
	end
	if Char.Effects:FindFirstChild("Blocking") == nil then
		targetHumanoid:TakeDamage(inflictedDamage)
	else
		self:ApplyEffect(sourcePlayer.Character:FindFirstChildOfClass("Humanoid"), "Slowness", 6, 2, "KillerSpecific")
		self:ApplyEffect(sourcePlayer.Character:FindFirstChildOfClass("Humanoid"), "Helpless", 1, 2, "KillerSpecific")
	end
	
	--NOTE: this is from Driftwood and you can use it as an example.
	if Char.Effects:FindFirstChild("Domino Effect") and table.find(DominoEffectModule.Attacks, reason) then
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
			Network:FireClientConnection(Player, "ShowJokeSettingImage", "REMOTE_EVENT", true, Char:FindFirstChild("Role") and Char.Role.Value or "Survivor")
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

	EffectValue.Parent = char:FindFirstChild("Effects")
	
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
function CommonFunctions:GrantRewardToPlayer(Player: Player, Money: number?, EXP: number?)
	local MoneyGranted = Money ~= nil and Money > 0 and Money or 0
	local EXPGranted = EXP ~= EXP and EXP > 0 and EXP or 0
	
	--if none are granted somehow
	if MoneyGranted <= 0 and EXPGranted <= 0 then
		return
	end

	--if only EXP is granted
	if MoneyGranted <= 0 then
		self:GrantEXPToPlayer(Player, EXP, true)
		return
	end

	--if only money is granted
	if EXPGranted <= 0 then
		self:UpdatePlayerStat(Player, "Currency.Money", MoneyGranted)
		Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", MoneyGranted)
		return
	end

	--if both are granted
	self:UpdatePlayerStat(Player, "Currency.Money", MoneyGranted)
	self:GrantEXPToPlayer(Player, EXPGranted, false)
	Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", MoneyGranted, EXPGranted)
end

function CommonFunctions:GrantEXPToPlayer(Player: Player, amount: number, visual: boolean)
	Network:FireClientConnection(Player, "GrantReward", "REMOTE_EVENT", 0, amount)
end

--- Updates a player's stat specified by a `string` path.
--- Stats are all either `int`s or `number`s.
function CommonFunctions:UpdatePlayerStat(Player: Player, path: string, amount: number)
    if not Player:FindFirstChild("PlayerData") then
        repeat task.wait(0.1)
        until Player:FindFirstChild("PlayerData")
    end

    local splitPath = CommonUtils:SplitStringPath(path)
    local PlayerStats = Player.PlayerData.Stats
    if #splitPath == 1 then
        PlayerStats:FindFirstChild(splitPath[1]).Value += amount
    else
        local Stat = PlayerStats
        for _, step in splitPath do
            Stat = Stat:FindFirstChild(step)
        end
        Stat.Value += amount
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

return CommonFunctions
