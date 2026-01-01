--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TypeUtils = require(script.Parent.TypeUtils)
local Janitor = require(ReplicatedStorage.Packages.Janitor)

local InstanceUtils = {}

--- Equivalent of `Instance.ChildAdded:Connect()` but managed by Janitor.
function InstanceUtils.ObserveChildren(
	parent: Instance,
	callback: (child: Instance, childJanitor: Janitor.Janitor) -> (),
	predicate: (child: Instance) -> boolean?
)
	local mainJanitor = Janitor.new()
	mainJanitor:LinkToInstance(parent)

	local function onChildAdded(child: Instance)
		if predicate and not predicate(child) then
			return
		end
		callback(child, mainJanitor:AddObject(Janitor, nil, child))
	end

	for _, child in parent:GetChildren() do
		task.spawn(onChildAdded, child)
	end
	mainJanitor:Add(parent.ChildAdded:Connect(onChildAdded))
	mainJanitor:Add(parent.ChildRemoved:Connect(function(child: Instance)
		mainJanitor:Remove(child)
	end))

	return mainJanitor
end

--- Equivalent of `Instance.DescendantAdded:Connect()` but managed by Janitor.
function InstanceUtils.ObserveDescendants(
	parent: Instance,
	callback: (descendant: Instance, descendantJanitor: Janitor.Janitor) -> (),
	paredicate: (descendant: Instance) -> boolean?
)
	local mainJanitor = Janitor.new()
	mainJanitor:LinkToInstance(parent)

	local function onDescendantAdded(descendant: Instance)
		if paredicate and not paredicate(descendant) then
			return
		end
		callback(descendant, mainJanitor:AddObject(Janitor, nil, descendant))
	end

	for _, descendant in parent:GetDescendants() do
		task.spawn(onDescendantAdded, descendant)
	end
	mainJanitor:Add(parent.DescendantAdded:Connect(onDescendantAdded))
	mainJanitor:Add(parent.DescendantRemoving:Connect(function(descendant: Instance)
		mainJanitor:Remove(descendant)
	end))

	return mainJanitor
end

--- Equivalent of `Instance.ChildAdded:Connect()` but only for children of a specific class and managed by Janitor.
function InstanceUtils.ObserveChildrenWhichIsA(
	parent: Instance,
	className: string,
	callback: (child: Instance, childJanitor: Janitor.Janitor) -> ()
)
	return InstanceUtils.ObserveChildren(parent, callback, function(child: Instance)
		return child:IsA(className)
	end)
end

--- Equivalent of `Instance.DescendantAdded:Connect()` but only for descendants of a specific class and managed by Janitor.
function InstanceUtils.ObserveDescendantsWhichIsA(
	parent: Instance,
	className: string,
	callback: (descendant: Instance, descendantJanitor: Janitor.Janitor) -> ()
)
	return InstanceUtils.ObserveDescendants(parent, callback, function(descendant: Instance)
		return descendant:IsA(className)
	end)
end

--- Equivalent of `Instance.ChildAdded:Connect()` but only for children of a specific name and managed by Janitor.
function InstanceUtils.ObserveChildrenOfName(
	parent: Instance,
	name: string,
	callback: (child: Instance, childJanitor: Janitor.Janitor) -> ()
)
	return InstanceUtils.ObserveChildren(parent, callback, function(child: Instance)
		return child.Name == name
	end)
end

--- Equivalent of `Instance.DescendantAdded:Connect()` but only for descendants of a specific name and managed by Janitor.
function InstanceUtils.ObserveDescendantsOfName(
	parent: Instance,
	name: Instance,
	callback: (descendant: Instance, descendantJanitor: Janitor.Janitor) -> ()
)
	return InstanceUtils.ObserveDescendants(parent, callback, function(descendant: Instance)
		return descendant.Name == name
	end)
end

--- Executes a callback when the `Parent` property of an `Instance` changes.
function InstanceUtils.ObserveParent(
	instance: Instance,
	callback: (parent: Instance, parentJanitor: Janitor.Janitor) -> (),
	predicate: (parent: Instance) -> boolean?
)
	return InstanceUtils.ObserveProperty(instance, "Parent", callback, predicate)
end

--- Behaves like `WaitForChild()` but uses `...ChildWhichIsA()` which lets you look for a specific type of `Instance`.
--- 
--- ⚠️ THIS FUNCTION YIELDS!
function InstanceUtils.WaitForChildWhichIsA(parent: Instance, className: string, timeout: number?)
	-- local child = parent:FindFirstChildWhichIsA(className)
	-- if child then
	-- 	return child
	-- end

	-- local connection
	-- connection = parent.ChildAdded:Connect(function(newChild: Instance)
	-- 	if newChild:IsA(className) then
	-- 		child = newChild
	-- 	end
	-- end)

	-- local timer = 0
	-- while parent and parent.Parent and not child and (timeout == nil or timer < timeout) do
	-- 	timer += task.wait()
	-- end

	-- connection:Disconnect()

	-- return child

    local existing = parent:FindFirstChildWhichIsA(className)
    if existing then
        return existing
    end

    local thread = coroutine.running()
    local connection
    
    connection = parent.ChildAdded:Connect(function(child)
        if child:IsA(className) then
            connection:Disconnect()
            task.spawn(thread, child)
        end
    end)

    if timeout then
        task.delay(timeout, function()
            if connection then
                connection:Disconnect()
                task.spawn(thread)
            end
        end)
    end

    return coroutine.yield()
end

--- Executes a callback when a specific property of an `Instance` changes.
function InstanceUtils.ObserveProperty(
	instance: Instance,
	propertyName: string,
	callback: (value: any, propertyJanitor: Janitor.Janitor) -> (),
	predicate: ((value: any) -> boolean)?
)
	local mainJanitor = Janitor.new()
	mainJanitor:LinkToInstance(instance)

	local function onPropertyChanged()
		if predicate and not predicate(instance[propertyName]) then
			return
		end
		
		callback(instance[propertyName], mainJanitor:AddObject(Janitor, nil, "LastValue"))
	end
	task.spawn(onPropertyChanged)
	mainJanitor:Add(instance:GetPropertyChangedSignal(propertyName):Connect(onPropertyChanged))

	return mainJanitor
end

--- Executes a callback when a specific attribute of an `Instance` changes.
function InstanceUtils.ObserveAttribute(
	instance: Instance,
	attributeName: string,
	callback: (value: any, propertyJanitor: Janitor.Janitor) -> (),
	predicate: ((value: any) -> boolean)?
)
	local mainJanitor = Janitor.new()
	mainJanitor:LinkToInstance(instance)

	local function onAttributeChanged()
		local value = instance:GetAttribute(attributeName)
		if predicate and not predicate(value) then
			return
		end
		
		callback(value, mainJanitor:AddObject(Janitor, nil, "LastValue"))
	end
	task.spawn(onAttributeChanged)
	mainJanitor:Add(instance:GetAttributeChangedSignal(attributeName):Connect(onAttributeChanged))
	
	return mainJanitor
end

--- Equivalent to `Instance:WaitForChild()` but it uses `Instance:FindFirstChild()` first to check if it's already there and not have to do `Instance:WaitForChild()`.
function InstanceUtils.FindFirstChild(Parent: Instance, ChildPath: string, Timeout: number?): Instance
    if not Parent then
        warn("[Utils.Instance.FindFirstChild()] `Parent` is nil!")
        return
    end

    local SplitPath = TypeUtils.SplitStringPath(ChildPath)

    local Result = Parent

    for _, step in SplitPath do
        local P = Result

        Result = P:FindFirstChild(step) or ((Timeout or 3) > 0 and P:WaitForChild(step, Timeout or 3) or nil)

        if not Result then
            break
        end
    end

    if not Result or Result == Parent then
        -- warn("[Utils.Instance.FindFirstChild()] Couldn't find \""..Parent.Name.."."..ChildPath.."\"!", debug.traceback())
        return
    end

    return Result
end

--- Tries to get an instance from a set path with a string.
--- The syntax is exactly the same as in another language when looking for a variable (e. g. "ReplicatedStorage.Modules.Utils").
--- It's useful when sending an object's path between peers (S2C / C2S) to save bandwidth by using a string instead of an Instance reference.
function InstanceUtils.GetInstanceFromPath(path: string): Instance
    local Names = TypeUtils.SplitStringPath(path)
    
    local Inst
	for index, step in Names do
		if index == 1 then
			Inst = game:GetService(step)
		elseif Inst then
			Inst = Inst:FindFirstChild(step)
		end
	end

    if Inst then
        return Inst
    elseif workspace:GetAttribute("DebugAllowed") then
        warn("[Utils:GetInstanceFromPath()] Instance not found for path: " .. path)
    end

    return
end

--- Gets a character's module from a specific type.
--- It also supports skins using `skinName` as an optional last parameter.
function InstanceUtils.GetCharacterModule(charType: "Survivor" | "Killer", charName: string, skinName: string?, doWarn: boolean?): ModuleScript
	if doWarn == nil then
		doWarn = true
	end

    local CharFolder = ReplicatedStorage.Characters

    local Module

    --checks if a skin exists and assigns it
    if skinName ~= nil and #skinName > 0 then
        Module = CharFolder["Skins"][charType.."s"]:FindFirstChild(charName)
        if Module then
            Module = Module:FindFirstChild(skinName)
        end
    end

    --replaces with the default character if it hasn't found the skin or if there wasn't one from the start
    if not Module then
        Module = CharFolder[charType.."s"]:FindFirstChild(charName)
    end

    --obv errors if there's none
    if not Module then

        -- Was erroring on that warn statement, as skins are optional– but you cannot concatenate a string with nil, so if no skin was specified, this error-handling message... Caused an error, lol.
        if not skinName then
            skinName = "[N/A]"
        end

		if doWarn then
        	warn("Can't find character module! ("..charType..", "..charName..", "..skinName..")")
        	warn(debug.traceback())
		end
        return
    end

    return Module
end

--- Gets an emote's module. Just used as a shortcut, and also serves use for tracing errors (it has a custom error message).
function InstanceUtils.GetEmoteModule(EmoteName: string): ModuleScript
    local EmoteFolder = ReplicatedStorage.Assets.Emotes

    local Module = EmoteFolder:FindFirstChild(EmoteName)

    --obv errors if there's none
    if not Module then
        -- error("Can't find emote module! ("..EmoteName..")")
        return
    end

    return Module
end

--- Gets an effect's module.
--- Also supports subfolders in `ReplicatedStorage.Effects`.
function InstanceUtils.GetEffectModule(name: string, subfolder: string?, module: boolean?)
    if module == nil then
        module = false
    end
    
	local Effect: ModuleScript

	if subfolder and #subfolder > 0 then
        Effect = InstanceUtils.FindFirstChild(ReplicatedStorage.Effects, subfolder.."."..name, false)
	else
        Effect = InstanceUtils.FindFirstChild(ReplicatedStorage.Effects, name, false)
	end

    if not Effect:IsA("ModuleScript") then
        return
    end

    return module and Effect or TypeUtils.CopyTable(require(Effect))
end

--- Returns an achievement's data table through an `AchievementGroup.AchievementName` path.
function InstanceUtils.GetAchievementData(path: string)
    local steps = TypeUtils.SplitStringPath(path)
    
    local Achievement = require(ReplicatedStorage.Assets.Achievements)
    for _, step in steps do
        Achievement = Achievement[step]
    end

    return Achievement
end



--- Returns a completely invisible, uncollidable, undetectable, 1 cubic stud sized part in CFrame `cf` and parented to `parent`.
function InstanceUtils.GetInvisPart(cf: CFrame?, parent: Instance?): Part
    local Part = Instance.new("Part")
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CanTouch = false
    Part.Transparency = 1
    Part.CastShadow = false
    Part.Anchored = true
    Part.Size = Vector3.one

    if cf then
        Part.CFrame = cf
    end
    if parent then
        Part.Parent = parent
    end

    return Part
end

return InstanceUtils
