local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Types)
local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Janitor = require(ReplicatedStorage.Packages.Janitor)
local Signal = require(ReplicatedStorage.Utils.Signal)

local AbilityType = {}

function AbilityType.GetDefaultSettings(): Types.Ability
    return {
        Name = "Ability",
        RenderImage = "rbxassetid://9759886280",
        UICorner = true,
        Passive = false,
        
        Init = function(self: Types.Ability, charModule: Types.Killer | Types.Survivor, plr: Player)
            self.Owner = plr
            self.CharModule = charModule
            self.UsesLeft = self.UseSettings.InitialUses

            self.Janitor = Janitor.new()
            self.Janitor:LinkToInstance(self.Owner.Character)

            --clearing ability stuff to dispose of this code when the player gets readded
            self.Janitor:Add(function()
                self:Destroy()
            end, true)

            if plr.Character:FindFirstChild("Effects") then
                self:AddConnection(plr.Character:FindFirstChild("Effects").ChildAdded:Connect(function(newChild: Instance)
                    if newChild.Name == "Stunned" then
                        for _, Connection in self.StunnableConnections do
                            if typeof(Connection) == "thread" then
                                if coroutine.running() ~= Connection then
                                    task.cancel(Connection)
                                end
                            else
                                Connection:Disconnect()
                            end
                        end
                    end
                end))
            end

            if RunService:IsServer() then
                Utils.Misc.Print("Initting "..self.Name.." ability for "..plr.Name)

                --is this exploitable? yes.
                --do i give a fuck? no.
                --thanks byfron.

                self.OwnerProperties = {
                    Character = self.Owner.Character,
                    Humanoid = self.Owner.Character:FindFirstChildWhichIsA("Humanoid"),
                    HRP = Utils.Character.GetRootPart(self.Owner),
                }

                self:AddConnection(Network:SetConnection("UsePlayerAbility", "REMOTE_EVENT", function(player: Player, abilityName: string)
                    if player == plr and abilityName == self.Name and self:CanUse() then
                        task.defer(function()
                            if self.CharModule.Config.Voicelines and self.CharModule.Config.Voicelines[self.Name] then
                                Sounds.PlayVoiceline(self.Owner.Character, self.CharModule.Config.Voicelines[self.Name])
                            end
                        end)

                        --cooldown stuffs
                        if self.AutomaticCooldown then
                            self:SetOnCooldown()
                        end

                        --decreasing uses left if it's supposed to be limited
                        if self.UseSettings.Limited then
                            task.spawn(function()
                                self:ChangeAbilityCharges("Set", self.UsesLeft - 1)
                            end)
                        end

                        task.spawn(function()
                            self.Signals.Used:Fire()
                        end)
                        Network:FireClientConnection(self.Owner, "UsePlayerAbility", "REMOTE_EVENT", self.Name)

                        task.spawn(function()
                            if self.Behaviour then
                                self:Behaviour()
                            end
                        end)
                    end
                end))

                --executes any extra initialization code that the ability might need
                if self.ExtraInit then
                    self:ExtraInit()
                end

                return
            end

            self.OwnerProperties = {
                Character = self.Owner.Character,
                Humanoid = self.Owner.Character:FindFirstChildWhichIsA("Humanoid"),
                HRP = Utils.Character.GetRootPart(self.Owner),
                InputManager = require(self.Owner.PlayerScripts.InputManager),
                SpeedManager = require(self.Owner.Character.PlayerAttributeScripts.SpeedManager),
                FOVManager = require(self.Owner.Character.PlayerAttributeScripts.FOVManager),
                EffectManager = require(self.Owner.Character.PlayerAttributeScripts.EffectManager),
                EmoteManager = require(self.Owner.Character.Miscellaneous.EmoteManager),
                TurnToMoveDirection = require(self.Owner.PlayerScripts.Miscellaneous.TurnToMoveDirection),
                Sprinting = require(self.Owner.Character.PlayerAbilities.Default.Sprinting),
                AnimationManager = require(self.Owner.Character.AnimationManager),
            }

            if #self.UseAnimation > 0 then
                --nesting in pcall so that if there's nothing it doesn't matter
                pcall(function()
                    local AnimName = self.Name:gsub(" ", "").."UseAnim"
                    charModule.GameplayConfig.Cache.Animations[AnimName] = Utils.Character.LoadAnimationFromID(self.Owner.Character, self.UseAnimation)
                    self.UseAnimationTrack = charModule.GameplayConfig.Cache.Animations[AnimName]
                end)
            end

            if self.OwnerProperties.InputManager.DefaultActions[self.InputName] ~= nil then
                self:AddConnection(self.OwnerProperties.InputManager.DefaultActions[self.InputName].Pressed:Connect(function()
                    self:AttemptUse()
                end))
            end

            self:AddConnection(Network:SetConnection("UsePlayerAbility", "REMOTE_EVENT", function(abilityName: string)
                if abilityName == self.Name then
                    --disables ability keys for preventing the usage of a different ability while using it
                    if self.DisableOtherAbilitiesOnPerform then
                        self:DisableAllAbilities(self.Duration)
                    end

                    --cooldown stuffs
                    if self.AutomaticCooldown then
                        self:SetOnCooldown()
                    end
                    --plays any existant use animation
                    task.defer(function()
                        if self.PlayUseAnimationOnUse then
                            self:PlayUseAnimation()
                        end
                    end)
                    task.spawn(function()
                        self.Signals.Used:Fire()
                    end)
                    --ability stuffs
                    if self.Behaviour then
                        task.spawn(function()
                            self:Behaviour()
                        end)
                    end
                end
            end))

            self:AddConnection(Network:SetConnection("ChangeAbilityCharges", "REMOTE_EVENT", function(abilityName: string, Type: "Set" | "Add" | "Take", amount: number)
                if abilityName == self.Name then
                    self:ChangeAbilityCharges(Type, amount)
                end
            end))

            --executes any extra initialization code that the ability might need
            if self.ExtraInit then
                self:ExtraInit()
            end
        end,

        ExtraInit = nil,
        OnRemove = nil,

        ReloadAnimation = function(self: Types.Ability, id: string)
            self.UseAnimationTrack = Utils.Character.LoadAnimationFromID(self.Owner.Character, id)
            local AnimName = self.Name:gsub(" ", "").."UseAnim"
            self.CharModule.GameplayConfig.Cache.Animations[AnimName] = Utils.Character.LoadAnimationFromID(self.Owner.Character, id)
            self.UseAnimationTrack = self.CharModule.GameplayConfig.Cache.Animations[AnimName]
        end,

        PlayUseAnimation = function(self)
            if self.UseAnimationTrack then
                self.UseAnimationTrack:Play(self.UseAnimationTransitionTime)
	            self.OwnerProperties.TurnToMoveDirection:AddHeadPreventionFactor(self.Name)
                task.delay(self.UseAnimationTrack.Length - (1/20 * 2), function()
                    self.UseAnimationTrack:Stop(self.UseAnimationTransitionTime)
	                self.OwnerProperties.TurnToMoveDirection:RemoveHeadPreventionFactor(self.Name)
                end)
            end
        end,

        Destroy = function(self: Types.Ability)
            if self.OnRemove then
                self:OnRemove()
            end

            for _, signal in self.Signals do
                signal:DisconnectAll()
            end

            self.CooldownTimer = 0
            self.OnCooldown = false
        end,

        AttemptUse = function(self: Types.Ability)
            if RunService:IsServer() then
                return
            end

            --NOTE: this is handled this way (by making separate cooldowns in both server and client) so that it's possible to prevent network calls if it's impossible to use the ability in client
            if self:CanUse() then
                Network:FireServerConnection("UsePlayerAbility", "REMOTE_EVENT", self.Name) --i know this is insecure but sue me lol
            end
        end,

        ChangeAbilityCharges = function(self: Types.Ability, Type: "Add" | "Set" | "Take", amount: number)
            if Type == "Set" then
                self.UsesLeft = amount
            elseif Type == "Add" then
                self.UsesLeft += amount
            elseif Type == "Take" then
                self.UsesLeft -= amount
            end

            self.Signals.ChargesChanged:Fire(amount)
            if RunService:IsServer() then
                Network:FireClientConnection(self.Owner, "ChangeAbilityCharges", "REMOTE_EVENT", self.Name, Type, amount)
            end
        end,
        
        DisableAllAbilities = function(self: Types.Ability, Duration: number?, DisableSlash: boolean?)
            if RunService:IsServer() then
                return
            end
            
            if DisableSlash == nil then
                DisableSlash = self.DisableSlashOnPerform
            end
            local inputsToCancelLater = {}
            for _, input in self.OwnerProperties.InputManager.DefaultActions do
                if input.Name:lower():find("ability") or (input.Name:lower():find("slash") and DisableSlash) then
                    input.Enabled = false
                    table.insert(inputsToCancelLater, input)
                end
            end
            if Duration then
                self:AddConnection(task.delay(Duration, function()
                    for _, input in inputsToCancelLater do
                        input.Enabled = true
                    end
                end))
            end
        end,

        SetOnCooldown = function(self: Types.Ability, duration: number?)
            if not workspace:GetAttribute("CooldownsEnabled") then
                return
            end

            duration = duration or self.Cooldown

            if self.OnCooldown then
                self.CooldownTimer = duration
                return
            end

            self.OnCooldown = true
            self.CooldownTimer = duration

            if RunService:IsServer() then
                -- task.spawn(function()
                --     --NOTE: this is still network stability dependant in the way that you may have to wait 0.1s more for the ability to not be on cooldown because e.g. if it waits 0.19s because of framerate or anything it will reduce 0.1s and wait another 0.1s but the change is so little i can't care enough to change it back
                --     while self.CooldownTimer > 0 do
                --         -- gets the amount the server waits
                --         local WaitAmount = task.wait(0.1)
                --         -- floors that onto how much it's been waiting to e.g. drain 0.1s if it waits 0.12s and 0.2s if it waits more than 0.21s
                --         WaitAmount = math.floor(WaitAmount * 10) / 10
                --         -- reduces cooldown timer
                --         self.CooldownTimer -= WaitAmount
                --     end
                --     self.CooldownTimer = 0
                --     self.OnCooldown = false
                -- end)

                --so this is obv more optimized but that removes the ability to read cooldown amounts on server, might work on it later
                self:AddConnection(task.delay(duration, function()
                    self.CooldownTimer = 0
                    self.OnCooldown = false
                end))
            else
                task.spawn(function()
                    --NOTE: this is still network stability dependant in the way that you may have to wait 0.1s more for the ability to not be on cooldown because e.g. if it waits 0.19s because of framerate or anything it will reduce 0.1s and wait another 0.1s but the change is so little i can't care enough to change it back
                    while self.CooldownTimer > 0 do
                        -- gets the amount the client waits
                        local WaitAmount = task.wait(0.1)
                        -- floors that onto how much it's been waiting to e.g. drain 0.1s if it waits 0.12s and 0.2s if it waits more than 0.21s
                        WaitAmount = math.floor(WaitAmount * 10) / 10
                        -- reduces cooldown timer
                        self.CooldownTimer -= WaitAmount
                    end
                    self.CooldownTimer = 0
                    self.OnCooldown = false
                end)
            end

            self.Signals.CooldownSet:Fire(duration)
        end,

        AddConnection = function<T>(self: Types.Ability, Connection: T & (RBXScriptConnection | thread)): T & (RBXScriptConnection | thread)
            self.Janitor:Add(Connection,
                if typeof(Connection) == "thread" then
                    true
                else
                    "Disconnect"
            )

            return Connection
        end,

        StunnableConnections = {},
        AddStunnableConnection = function<T>(self: Types.Ability, Connection: T & (RBXScriptConnection | thread)): T & (RBXScriptConnection | thread)
            self:AddConnection(Connection)
            table.insert(self.StunnableConnections, Connection)

            return Connection
        end,

        InputName = "FirstAbility",
        Behaviour = nil,

        UseAnimation = "",
        UseAnimationTrack = nil,
        PlayUseAnimationOnUse = true,
        UseAnimationTransitionTime = 0.1,

        Cooldown = 5,
        CooldownTimer = 0,
        OnCooldown = false,
        AutomaticCooldown = true,

        --read
        CanUse = function(self: Types.Ability): boolean
            --if it's limited then it should have to have enough uses left
            local EnoughUses = true
            if workspace:GetAttribute("ChargesEnabled") and self.UseSettings.Limited then
                EnoughUses = self.UsesLeft > 0
            end

            --if the ability is on cooldown or not
            local OnCooldown = false
            if workspace:GetAttribute("CooldownsEnabled") and self.OnCooldown then
                OnCooldown = true
            end

            --if the player isn't stunned, thus can be conscious OR has hope (UNDERTALE REFERENCE????)
            local EffectPrevention = false
            if RunService:IsServer() then
                if self.Owner.Character.Effects:FindFirstChild("Stunned") or self.Owner.Character.Effects:FindFirstChild("Helpless") then
                    EffectPrevention = true
                end
            else
                if self.OwnerProperties.EffectManager.Effects["Stunned"] or self.OwnerProperties.EffectManager.Effects["Helpless"] then
                    EffectPrevention = true
                end
            end

            --if the player isn't emoting
            local Emoting
            if RunService:IsServer() then
                Emoting = self.OwnerProperties.Character:GetAttribute("Emoting") == true
            else
                Emoting = self.OwnerProperties.EmoteManager.CurrentlyPlayingEmote ~= nil
            end

            return EnoughUses
            and self.OwnerProperties.Humanoid.Health > 0 --if the player's alive
            and not self.OwnerProperties.HRP.Anchored --if the player isn't restrained by initial round setup
            and not self.Owner.Character:GetAttribute("Executing")
            and not Emoting
            and not EffectPrevention
            and not OnCooldown
            and self:UseConditions() --any extra conditions added by the ability's definition in `Ability:UseConditions()`
        end,
        UseConditions = function(_self: Types.Ability): boolean
            return true
        end,
        
        Duration = 0.4,

        DisableOtherAbilitiesOnPerform = true,
        DisableSlashOnPerform = true,

        UsesLeft = 1,

        UseSettings = {
            Limited = false,
            InitialUses = 5,
        },

        Signals = {
            ChargesChanged = Signal.new(),
            Used = Signal.new(),
            CooldownSet = Signal.new(),
        },
    }
end

--- ## DEPRECATED: Use `Ability.GetDefaultSettings()` instead.
--- Ability preset for customization.
@deprecated
function AbilityType.GetDefaultAbilitySettings(): Types.Ability
    return AbilityType.GetDefaultSettings()
end

--- ## DEPRECATED: Use `Ability.GetDefaultPassiveSettings()` instead.
function AbilityType.GetDefaultPassiveSettings(): Types.Ability
    return Utils.Type.DeepTableOverwrite({
        Passive = true,

        Init = function(self: Types.Ability, charModule: Types.Killer | Types.Survivor, plr: Player)
            self.Owner = plr
            self.CharModule = charModule
            self.UsesLeft = self.UseSettings.InitialUses

            self.Janitor = Janitor.new()
            self.Janitor:LinkToInstance(self.Owner.Character)

            --clearing ability stuff to dispose of this code when the player gets readded
            self.Janitor:Add(function()
                self:Destroy()
            end, true)

            if RunService:IsServer() then
                Utils.Misc.Print("Initting "..self.Name.." ability for "..plr.Name)

                --is this exploitable? yes.
                --do i give a fuck? no.
                --thanks byfron.

                self.OwnerProperties = {
                    Character = self.Owner.Character,
                    Humanoid = self.Owner.Character:FindFirstChildWhichIsA("Humanoid"),
                    HRP = Utils.Character.GetRootPart(self.Owner),
                }

                --executes any extra initialization code that the ability might need
                if self.ExtraInit then
                    self:ExtraInit()
                end

                return
            end

            self.OwnerProperties = {
                Character = self.Owner.Character,
                Humanoid = self.Owner.Character:FindFirstChildWhichIsA("Humanoid"),
                HRP = Utils.Character.GetRootPart(self.Owner),
                InputManager = require(self.Owner.PlayerScripts.InputManager),
                SpeedManager = require(self.Owner.Character.PlayerAttributeScripts.SpeedManager),
                FOVManager = require(self.Owner.Character.PlayerAttributeScripts.FOVManager),
                EffectManager = require(self.Owner.Character.PlayerAttributeScripts.EffectManager),
                EmoteManager = require(self.Owner.Character.Miscellaneous.EmoteManager),
                TurnToMoveDirection = require(self.Owner.PlayerScripts.Miscellaneous.TurnToMoveDirection),
            }

            --executes any extra initialization code that the ability might need
            if self.ExtraInit then
                self:ExtraInit()
            end
        end,
        ReloadAnimation = function(self: Types.Ability, id: string)
            warn("Ability \""..self.Name.."\" is a Passive, so no use animation can be assigned to it!")
        end,
        PlayUseAnimation = function(self: Types.Ability)
            warn("Ability \""..self.Name.."\" is a Passive, so no use animation is available!")
        end,
        AttemptUse = function(self: Types.Ability)
            warn("Ability \""..self.Name.."\" is a Passive, so it can't be used through input!")
        end,
        ChangeAbilityCharges = function(self: Types.Ability, _Type: "Add" | "Set" | "Take", _amount: number)
            warn("Ability \""..self.Name.."\" is a Passive, so charges aren't applied!")
        end,

        PlayUseAnimationOnUse = false,

        Cooldown = 0,

        CanUse = function(_self: Types.Ability): boolean
            return true
        end,
        UseConditions = function(_self: Types.Ability): boolean
            return true
        end,

        Duration = 0,

        DisableOtherAbilitiesOnPerform = false,
        DisableSlashOnPerform = false,

        Signals = {},
    }, AbilityType.GetDefaultSettings())
end

--- ## DEPRECATED: use `Ability.GetDefaultPassiveSettings()` instead.
@deprecated
function AbilityType.GetDefaultPassiveAbilitySettings(): Types.Ability
    return AbilityType.GetDefaultPassiveSettings()
end

--- Creates an ability with the settings specified in `Props`.
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
function AbilityType.New(Props: Types.Ability): Types.Ability
    Props = Props or {}

    return Utils.Type.DeepTableOverwrite(
        Props.Passive and
            AbilityType.GetDefaultPassiveSettings() or
            AbilityType.GetDefaultSettings(),

        Props
    )
end

--- ## DEPRECATED: use `Ability.New()` instead.
--- Creates an ability with the settings specified in `Props`.
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
@deprecated
function AbilityType.CreateAbility(Props: Types.Ability): Types.Ability
    return AbilityType.New(Props)
end

return AbilityType