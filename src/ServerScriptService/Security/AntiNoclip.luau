local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Utils = require(ReplicatedStorage.Modules.Utils)
local CommonFunctions = require(ServerScriptService.System.CommonFunctions)
local AntiNoclip = {
	Kick = false,
	VisualizePart = false,
	Margin = 1
}

function AntiNoclip._SetupPart(Character, RootPart, Humanoid)
	local NoclipPart = Instance.new("Part")
	NoclipPart.Size = Vector3.new(1.5, 1.9, 0.8)
	NoclipPart.CanCollide = true
	NoclipPart.Transparency = AntiNoclip.VisualizePart and 0 or 1
	NoclipPart:AddTag("Transparent")
	NoclipPart.Name = "AntiNoclipBrain"
	NoclipPart.CollisionGroup = RootPart.CollisionGroup
	NoclipPart.Parent = Character
	local Weld = Instance.new("Weld")
	Weld.Part0 = NoclipPart
	Weld.Part1 = RootPart
	Weld.Parent = NoclipPart
	
	NoclipPart.Destroying:Connect(function()
		if Humanoid and Humanoid.Health > 0 then
			NoclipPart = AntiNoclip._SetupPart(Character, RootPart)
		end
	end)
	
	Weld.Destroying:Connect(function()
		if Humanoid and Humanoid.Health and Humanoid.Health > 0 then
			if Humanoid and Humanoid.Health > 0 then
				NoclipPart:Destroy()
				NoclipPart = AntiNoclip._SetupPart(Character, RootPart)
			end
		end
	end)
	
	return NoclipPart
end

function AntiNoclip:Init()
    Utils.Player.ObservePlayers(function(Player)
        Utils.Character.ObserveCharacter(Player, function(Character: Model)
        	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        	local HumanoidRootPart = Utils.Character.GetRootPart(Character)
        	local NoclipPart = AntiNoclip._SetupPart(Character, HumanoidRootPart)

            local RayParams = RaycastParams.new()
            RayParams.FilterType = Enum.RaycastFilterType.Exclude

            local Filter = {}

			--checks properly if you're noclipping every second
			--this is done due to the next issue:
				--if you were noclipping RIGHT at the time of a check, you would be instantly kicked / killed.
				--with THIS single variable, it properly checks every second and leaves a bit more margin for anyone bugged.
			--yes -Dyscarn
			local NoclipTime = 0

            task.spawn(function()
                while task.wait(0.4) do
                    if not Character or not Humanoid or Humanoid.Health <= 0 then
                        break
                    end

                    table.clear(Filter)

                    for _, plr in Players:GetPlayers() do
                        if plr.Character then
                            table.insert(Filter, plr.Character)
                        end
                    end

                    for _, Part in workspace:GetDescendants() do
                        if not Part:IsA("BasePart") or Part.CanCollide or PhysicsService:CollisionGroupsAreCollidable(HumanoidRootPart.CollisionGroup, Part.CollisionGroup) then
							continue
                        end
                        
						table.insert(Filter, Part)
                    end

                    RayParams.FilterDescendantsInstances = Filter --i have to change this every time for no reason??????
                end
            end)
        
			-- failsafe
			--while true do
        	while Character and Character.Parent and Humanoid and Humanoid.Health > 0 do
				local TimePast = task.wait(0.09)
				local Found = false
				for _, Part in NoclipPart:GetTouchingParts() do
					if Part:IsA("Part") and not Part.Parent:FindFirstChild("Humanoid") then 
						if not Found then
							Found = true
						end

						local Origin = NoclipPart.Position
						local Direction = (Part.Position - NoclipPart.Position)

						local RayResults = workspace:Raycast(Origin, Direction, RayParams)
				
						if not RayResults or not RayResults.Instance then
							NoclipTime += TimePast
							if NoclipTime > self.Margin then
								if self.Kick then
									CommonFunctions.KickPlayer(Player, CommonFunctions.KickIDs.Noclipping)
								else
									Humanoid.Health = 0 --REPLACE WITH KICKING
								end
								continue
							end
						else
							NoclipTime = 0
						end
					end
				end

				if not Found then
					NoclipTime = 0
				end
        	end
        end)
    end)
end

return AntiNoclip
