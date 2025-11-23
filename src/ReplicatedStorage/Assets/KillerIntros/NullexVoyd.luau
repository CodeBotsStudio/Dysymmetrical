return {
    Behaviour = function(_, Intro)
    	local TweenService = game:GetService("TweenService")
    
    	local Group = script:FindFirstChildOfClass("Frame"):Clone()
        Group.Parent = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("KillerIntros")
		table.insert(Intro.Disposables, Group)
    	local Frame = Group.Background
    	Frame.BackgroundTransparency = 0
    
    	local Text = Frame.TextLabel
    	Text.TextTransparency = 1
    	local InitialText = Text.Text
    
    	task.spawn(function()
    		while Frame and Text do
    			Text.Text = Text.Text.."."
    			if Text.Text == InitialText.."...." then
    				Text.Text = InitialText.."."
    			end
    			task.wait(0.35)
    		end
    	end)

    	Group:FindFirstChildOfClass("Sound"):Play()
    
    	TweenService:Create(Text, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    
    	task.wait(2.5)
    
    	for _, i in Group:GetDescendants() do
    		-- if i:IsA("Frame") then
    		-- 	TweenService:Create(i, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
    		-- elseif i:IsA("TextLabel") then
			if i:IsA("TextLabel") then
    			TweenService:Create(i, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    		end
    	end
    
    	task.wait(0.5)
    	Group:Destroy()
    end
}