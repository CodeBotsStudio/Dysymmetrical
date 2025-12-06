--!nocheck

--TODO: mayyyyyyybe use janitor in this and link it to the character

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Utils = require(ReplicatedStorage.Modules.Utils)
local Network = require(ReplicatedStorage.Modules.Network)
local Sounds = require(ReplicatedStorage.Modules.Sounds)
local Signal = require(ReplicatedStorage.Utils.Signal)

local AbilityType = {}

--- Class used for character abilities.
export type Ability = {
    --- The display name.
    Name: string,
    --- The description used in the character's info.
    Description: string,
    --- The image of the ability in the GUI when playing.
    RenderImage: string,
    --- If the image should have a UICorner just in case it's not round.
    UICorner: boolean,
    --- If it's passive (to hide it in the GUI).
    Passive: boolean,

    --- Internal function to initialize the ability's generally used variables and connections.
    Init: (self: Ability, charModule: any, owner: Player) -> (),
    --- Empty function to execute extra code right after the ability is initialized using `Init`.
    ExtraInit: (self: Ability) -> (),
    --- Empty function to execute extra code right before the ability gets destroyed using `Destroy`.
    OnRemove: (self: Ability) -> (),
    --- Reloads the animation to be `newId`.
    ReloadAnimation: (self: Ability, newId: string) -> (),
    --- Plays the use animation for this ability. Mainly used internally.
    PlayUseAnimation: (self: Ability) -> (),
    --- Destroys the ability, disconnecting any connections it might have, cancelling any threads...
    Destroy: (self: Ability) -> (),

    --- CLIENT FUNCTION: Attempts to use the ability by checking if it's possible in the first place.
    AttemptUse: (self: Ability) -> (),
    --- Modifies the `UsesLeft` property in both client and server.
    --- 
    --- SHOULD ONLY BE USED IN SERVER.
    ChangeAbilityCharges: (self: Ability, Type: "Set" | "Add" | "Take", amount: number) -> (),

    --- The name of the input used for the ability, set up in `InputManager`.
    InputName: string,
    --- Literally the behaviour of the ability; what it does. Write your ability here.
    Behaviour: (self: Ability) -> (),

    --- The animation ID of the use animation.
    UseAnimation: string,
    --- The track that `UseAnimation` is tied to.
    UseAnimationTrack: AnimationTrack,
    --- Toggle that lets you not play the use animation when using this ability.
    PlayUseAnimationOnUse: boolean,
    --- The time it'll take to transition between the currently playing animation and this one and viceversa.
    --- 
    --- Overrides `Character.Config.AnimationTransitionTime` for `self.UseAnimation`'s transition time.
    UseAnimationTransitionTime: number,

    --- The cooldown setting of the ability / how long it takes to recharge. It can also be changed dynamically.
    Cooldown: number,
    --- The timer for the cooldown to finish. Don't tamper with this unless you know what you're doing!
    CooldownTimer: number,
    --- Will be true if the ability is on cooldown.
    OnCooldown: boolean,
    --- Utility to check if the ability can legally be used.
    CanUse: (self: Ability) -> boolean,
    --- Extra, custom conditions to add to `Ability:CanUse()` instead of replacing the latter.
    --- 
    --- Must return a `boolean`.
    UseConditions: (self: Ability) -> boolean,

    --- The duration of the ability. Mainly used to disable input until it finishes. Doesn't need to be the literal length.
    Duration: number,

    --- If `true`, when using this ability, it'll disable every ability for `Duration` time.
    DisableOtherAbilitiesOnPerform: boolean,
    --- If `true`, when using this ability, it'll disable the Slash ability for `Duration` time.
    --- Only works if the character is a killer and if `DisableOtherAbilitiesOnPerform` is `true`.
    DisableSlashOnPerform: boolean,

    --- The uses / charges left for this ability. Won't matter if uses aren't limited.
    UsesLeft: number,

    --- Settings for uses / charges.
    UseSettings: {
        --- If false, the ability won't care about uses / charges.
        Limited: boolean,
        --- Initial uses / charges for an ability when starting a round.
        InitialUses: number,
    },

    Signals: {
        ChargesChanged: Signal.Signal,
        Used: Signal.Signal,
    },

    --- Connections and threads that make the ability work. Add any `task.delay()`s or `RBXScriptConnection`s here.
    Connections: {RBXScriptConnection | thread},
    --- The owner of the ability.
    Owner: Player,
    --- The properties of this ability's owner.
    OwnerProperties: {
        --this is hybrid (client & server)
        --- The Character of the owner player. Also gettable through `Owner.Character`.
        Character: Model,
        --- The owner's character's HumanoidRootPart instance for usage. Also gettable through `Owner.Character:FindFirstChild("HumanoidRootPart")`.
        HRP: BasePart,
        --this is server
        --- See `ServerScriptService.System.CommonFunctions`.
        CommonFunctions: any,
        --the rest are all from client
        --- See `StarterPlayerScripts.InputManager`.
        InputManager: any,
        --- See `StarterCharacterScripts.PlayerAttributeScripts.SpeedManager`.
        SpeedManager: any,
        --- See `StarterCharacterScripts.PlayerAttributeScripts.FOVManager`.
        FOVManager: any,
        --- See `StarterCharacterScripts.PlayerAttributeScripts.EffectManager`.
        EffectManager: any,
        --- See `StarterCharacterScripts.Miscellaneous.EmoteManager`.
        EmoteManager: any,
        --- See `StarterCharacterScripts.Miscellaneous.TurnToMoveDirection`.
        TurnToMoveDirection: any,
    },
    --- The source module where the ability comes from. Contains all character info.
    CharModule: any,
}

--- Ability preset for customization.
function AbilityType.GetDefaultAbilitySettings(): Ability
    return {
        Name = "Ability",
        Description = "Does something",
        RenderImage = "rbxassetid://9759886280",
        UICorner = true,
        Passive = false,
        
        Init = function(self: Ability, charModule: any, plr: Player)
            self.Owner = plr
            self.CharModule = charModule
            self.UsesLeft = self.UseSettings.InitialUses
            if RunService:IsServer() then
                Utils.Misc.Print("Initting "..self.Name.." ability for "..plr.Name)

                --is this exploitable? yes.
                --do i give a fuck? no.
                --thanks byfron.

                self.OwnerProperties = {
                    Character = self.Owner.Character,
                    HRP = Utils.Instance.FindFirstChild(self.Owner.Character, "HumanoidRootPart"),
                    CommonFunctions = require(ServerScriptService.System.CommonFunctions),
                }

                table.insert(self.Connections, Network:SetConnection("UsePlayerAbility", "REMOTE_EVENT", function(player: Player, abilityName: string)
                    if player == plr and abilityName == self.Name and self:CanUse() then
                        task.defer(function()
                            if self.CharModule.Config.Voicelines and self.CharModule.Config.Voicelines[self.Name] then
                                Sounds:PlayVoiceline(self.Owner.Character, self.CharModule.Config.Voicelines[self.Name])
                            end
                        end)

                        --cooldown stuffs
                        self.OnCooldown = true
                        self.CooldownTimer = self.Cooldown
                        task.spawn(function()
                            --NOTE: this is still network stability dependant in the way that you may have to wait 0.1s more for the ability to not be on cooldown because e.g. if it waits 0.19s because of framerate or anything it will reduce 0.1s and wait another 0.1s but the change is so little i can't care enough to change it back
                            while self.CooldownTimer > 0 do
                                -- gets the amount the server waits
                                local WaitAmount = task.wait(0.1)
                                -- floors that onto how much it's been waiting to e.g. drain 0.1s if it waits 0.12s and 0.2s if it waits more than 0.21s
                                WaitAmount = math.floor(WaitAmount * 10) / 10
                                -- reduces cooldown timer
                                self.CooldownTimer -= WaitAmount
                            end
                            self.CooldownTimer = 0
                            self.OnCooldown = false
                        end)

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
                        if self.Behaviour then
                            self:Behaviour()
                        end
                    end
                end))

                --clearing ability connections to dispose of this code when the player gets readded
                table.insert(self.Connections, plr.CharacterAdded:Connect(function()
                    self:Destroy()
                end))

                --executes any extra initialization code that the ability might need
                if self.ExtraInit then
                    self:ExtraInit()
                end

                return
            end

            self.OwnerProperties = {
                Character = self.Owner.Character,
                HRP = Utils.Instance.FindFirstChild(self.Owner.Character, "HumanoidRootPart"),
                InputManager = require(self.Owner.PlayerScripts.InputManager),
                SpeedManager = require(self.Owner.Character.PlayerAttributeScripts.SpeedManager),
                FOVManager = require(self.Owner.Character.PlayerAttributeScripts.FOVManager),
                EffectManager = require(self.Owner.Character.PlayerAttributeScripts.EffectManager),
                EmoteManager = require(self.Owner.Character.Miscellaneous.EmoteManager),
                TurnToMoveDirection = require(self.Owner.PlayerScripts.Miscellaneous.TurnToMoveDirection),
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
                table.insert(self.Connections, self.OwnerProperties.InputManager.DefaultActions[self.InputName].Pressed:Connect(function()
                    self:AttemptUse()
                end))
            end

            table.insert(self.Connections, Network:SetConnection("UsePlayerAbility", "REMOTE_EVENT", function(abilityName: string)
                if abilityName == self.Name then
                    --disables ability keys for preventing the usage of a different ability while using it
                    if self.DisableOtherAbilitiesOnPerform then
                        local inputsToCancelLater = {}
                        for _, input in self.OwnerProperties.InputManager.DefaultActions do
                            if input.Name:lower():find("ability") or (input.Name:lower():find("slash") and self.DisableSlashOnPerform) then
                                input.Enabled = false
                                table.insert(inputsToCancelLater, input)
                            end
                        end
                        table.insert(self.Connections, task.delay(if self.UseAnimationTrack then self.UseAnimationTrack.Length else self.Duration, function()
                            for _, input in inputsToCancelLater do
                                input.Enabled = true
                            end
                        end))
                    end
                    --cooldown stuffs
                    self.OnCooldown = true
                    self.CooldownTimer = self.Cooldown
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

            table.insert(self.Connections, Network:SetConnection("ChangeAbilityCharges", "REMOTE_EVENT", function(abilityName: string, Type: "Set" | "Add" | "Take", amount: number)
                if abilityName == self.Name then
                    self:ChangeAbilityCharges(Type, amount)
                end
            end))

            --clearing ability connections to dispose of this code when the player gets readded
            table.insert(self.Connections, self.Owner.CharacterAdded:Connect(function()
                self:Destroy()
            end))

            --executes any extra initialization code that the ability might need
            if self.ExtraInit then
                self:ExtraInit()
            end
        end,

        ExtraInit = nil,
        OnRemove = nil,

        ReloadAnimation = function(self: Ability, id: string)
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

        Destroy = function(self: Ability)
            if self.OnRemove then
                self:OnRemove()
            end
            for _, connection in self.Connections do
                if typeof(connection) == "thread" then
                    task.cancel(connection)
                else
                    connection:Disconnect()
                end
            end
            table.clear(self.Connections)

            self.CooldownTimer = 0
            self.OnCooldown = false
        end,

        AttemptUse = function(self: Ability)
            if RunService:IsServer() then
                return
            end

            --NOTE: this is handled this way (by making separate cooldowns in both server and client) so that it's possible to prevent network calls if it's impossible to use the ability in client
            if self:CanUse() then
                Network:FireServerConnection("UsePlayerAbility", "REMOTE_EVENT", self.Name) --i know this is insecure but sue me lol
            end
        end,

        ChangeAbilityCharges = function(self: Ability, Type:"Add" | "Set" | "Take", amount: number)
            if Type == "Set" then
                self.UsesLeft = amount
            elseif Type == "Add" then
                self.UsesLeft += amount
            elseif Type == "Take" then
                self.UsesLeft -= amount
            end

            self.Signals.ChargesChanged:Fire(self.UsesLeft)
            if RunService:IsServer() then
                Network:FireClientConnection(self.Owner, "ChangeAbilityCharges", "REMOTE_EVENT", self.Name, Type, amount)
            end
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

        --read
        CanUse = function(self: Ability): boolean
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
            and self.Owner.Character:FindFirstChildOfClass("Humanoid").Health > 0 --if the player's alive
            and not self.Owner.Character:FindFirstChild("HumanoidRootPart").Anchored --if the player isn't restrained by initial round setup
            and not self.Owner.Character:GetAttribute("Executing")
            and not Emoting
            and not EffectPrevention
            and not OnCooldown
            and self:UseConditions() --any extra conditions added by the ability's definition in `Ability:UseConditions()`
        end,
        UseConditions = function(_self: Ability): boolean
            return true
        end,
        
        Duration = 0.4,

        DisableOtherAbilitiesOnPerform = true,
        DisableSlashOnPerform = true,

        UsesLeft = 1,

        UseSettings = {
            Limited = false,
            InitialUses = 1,
        },

        Signals = {
            ChargesChanged = Signal.new(),
            Used = Signal.new(),
        },

        Connections = {},
    }
end

function AbilityType.GetDefaultPassiveAbilitySettings()
    return Utils.Type.DeepTableOverwrite({
        Passive = true,

        Init = function(self: Ability, charModule: any, plr: Player)
            self.Owner = plr
            self.CharModule = charModule
            self.UsesLeft = self.UseSettings.InitialUses
            if RunService:IsServer() then
                Utils.Misc.Print("Initting "..self.Name.." ability for "..plr.Name)

                --is this exploitable? yes.
                --do i give a fuck? no.
                --thanks byfron.

                self.OwnerProperties = {
                    Character = self.Owner.Character,
                    HRP = Utils.Instance.FindFirstChild(self.Owner.Character, "HumanoidRootPart"),
                    CommonFunctions = require(ServerScriptService.System.CommonFunctions),
                }

                --clearing ability connections to dispose of this code when the player gets readded
                table.insert(self.Connections, plr.CharacterAdded:Connect(function()
                    self:Destroy()
                end))

                --executes any extra initialization code that the ability might need
                if self.ExtraInit then
                    self:ExtraInit()
                end

                return
            end

            self.OwnerProperties = {
                Character = self.Owner.Character,
                HRP = Utils.Instance.FindFirstChild(self.Owner.Character, "HumanoidRootPart"),
                InputManager = require(self.Owner.PlayerScripts.InputManager),
                SpeedManager = require(self.Owner.Character.PlayerAttributeScripts.SpeedManager),
                FOVManager = require(self.Owner.Character.PlayerAttributeScripts.FOVManager),
                EffectManager = require(self.Owner.Character.PlayerAttributeScripts.EffectManager),
                EmoteManager = require(self.Owner.Character.Miscellaneous.EmoteManager),
                TurnToMoveDirection = require(self.Owner.PlayerScripts.Miscellaneous.TurnToMoveDirection),
            }

            --clearing ability connections to dispose of this code when the player gets readded
            table.insert(self.Connections, self.Owner.CharacterAdded:Connect(function()
                self:Destroy()
            end))

            --executes any extra initialization code that the ability might need
            if self.ExtraInit then
                self:ExtraInit()
            end
        end,
        ReloadAnimation = function(self: Ability, id: string)
            warn("Ability \""..self.Name.."\" is a Passive, so no use animation can be assigned to it!")
        end,
        PlayUseAnimation = function(self)
            warn("Ability \""..self.Name.."\" is a Passive, so no use animation is available!")
        end,
        AttemptUse = function(self: Ability)
            warn("Ability \""..self.Name.."\" is a Passive, so it can't be used through input!")
        end,
        ChangeAbilityCharges = function(self: Ability, _Type: "Add" | "Set" | "Take", _amount: number)
            warn("Ability \""..self.Name.."\" is a Passive, so charges aren't applied!")
        end,

        PlayUseAnimationOnUse = false,

        Cooldown = 0,

        CanUse = function(_self: Ability): boolean
            return true
        end,
        UseConditions = function(_self: Ability): boolean
            return true
        end,

        Duration = 0,

        DisableOtherAbilitiesOnPerform = false,
        DisableSlashOnPerform = false,
    }, AbilityType.GetDefaultAbilitySettings())
end

--- Creates an ability with the settings specified in `Props`.
--- Every property that has to be there has a fallback, so not all properties have to be written there if the default values are fine.
function AbilityType.CreateAbility(Props: Ability): Ability
    Props = Props or {}

    local Final = Props.Passive and
        AbilityType.GetDefaultPassiveAbilitySettings() or
        AbilityType.GetDefaultAbilitySettings()
    
    Utils.Type.DeepTableOverwrite(Final, Props)

    return Final
end

return AbilityType