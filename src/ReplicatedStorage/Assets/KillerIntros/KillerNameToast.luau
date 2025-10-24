return function(Parent: ScreenGui, name: string, plrNames: {string})
	local TweenService = game:GetService("TweenService")
	
	local Group = script:FindFirstChildOfClass("Frame"):Clone()
    Group.Parent = Parent

	for _, i in Group:GetDescendants() do
		if i:IsA("Frame") then
			i.BackgroundTransparency = 1
		elseif i:IsA("TextLabel") then
			i.TextTransparency = 1
		end
	end

	local Frame = Group.Frame
	Frame.KillerName.Text = name
	Frame.PlayerName.Text = "("..plrNames[1]..")"

	task.wait(1)

	for _, i in Group:GetDescendants() do
		if i:IsA("Frame") then
			TweenService:Create(i, TweenInfo.new(1), {BackgroundTransparency = 0}):Play()
		elseif i:IsA("TextLabel") then
			TweenService:Create(i, TweenInfo.new(1), {TextTransparency = 0}):Play()
		end
	end

	task.wait(3)

	for _, i in Group:GetDescendants() do
		if i:IsA("Frame") then
			TweenService:Create(i, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
		elseif i:IsA("TextLabel") then
			TweenService:Create(i, TweenInfo.new(1), {TextTransparency = 1}):Play()
		end
	end

	task.wait(1.5)
	Group:Destroy()
end