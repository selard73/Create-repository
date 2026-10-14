-- PortoKeeperClient: a banner and a chat line when someone becomes the Guardian of the Harbour; a quiet note to late finders.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ev = RS:WaitForChild("PortoKeeperEvent")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local function chat(text)
	pcall(function() StarterGui:SetCore("ChatMakeSystemMessage", {Text = text, Color = C(255, 214, 90), Font = Enum.Font.GothamBold, TextSize = 18}) end)
end
local function banner(big, small)
	local pg = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui"); gui.Name = "PortoKeeperBanner"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 26; gui.Parent = pg
	local f = Instance.new("Frame"); f.AnchorPoint = Vector2.new(0.5, 0); f.Position = UDim2.new(0.5, 0, 0, -140); f.Size = UDim2.fromOffset(620, 110)
	f.BackgroundColor3 = C(28, 32, 60); f.BackgroundTransparency = 0.08; f.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 18); corner.Parent = f
	local stroke = Instance.new("UIStroke"); stroke.Color = C(232, 191, 74); stroke.Thickness = 4; stroke.Parent = f
	local t1 = Instance.new("TextLabel"); t1.Size = UDim2.new(1, -30, 0, 54); t1.Position = UDim2.new(0, 15, 0, 10); t1.BackgroundTransparency = 1
	t1.Font = Enum.Font.FredokaOne; t1.TextScaled = true; t1.TextColor3 = C(255, 222, 110); t1.Text = big; t1.Parent = f
	local t2 = Instance.new("TextLabel"); t2.Size = UDim2.new(1, -30, 0, 32); t2.Position = UDim2.new(0, 15, 0, 66); t2.BackgroundTransparency = 1
	t2.Font = Enum.Font.Merriweather; t2.TextScaled = true; t2.TextColor3 = C(255, 246, 220); t2.Text = small; t2.Parent = f
	local sc = Instance.new("UIScale"); sc.Parent = f
	local vw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	sc.Scale = math.min(1, (vw - 24) / 620)
	TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 70)}):Play()
	task.delay(9, function()
		TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -140)}):Play()
		task.wait(0.5); gui:Destroy()
	end)
end
ev.OnClientEvent:Connect(function(what, a)
	if what == "crowned" and type(a) == "table" then
		local t = workspace:FindFirstChild("PortoKeeper") and workspace.PortoKeeper:GetAttribute("Title") or "Guardian of the Harbour"
		if a.uid == player.UserId then
			banner("You are the " .. t .. "!", "Your statue stands by the lighthouse, holding the harbour key")
		else
			banner(tostring(a.name) .. " is the " .. t .. "!", "First today to find all " .. tostring(a.total or 44) .. " squirrels of Porto Nocciola")
		end
		chat(string.format("%s found all %d squirrels of Porto Nocciola first today and is the %s. Their statue stands by the lighthouse.", tostring(a.name), tonumber(a.total) or 44, t))
	elseif what == "late" then
		chat(string.format("You found every squirrel in Porto Nocciola! %s got there first today. To compete on another day, reset your finds and collect all 44 again.", tostring(a)))
    elseif what == "reset_needed" then
        chat("To compete on another day, reset your finds and collect all 44 Italy squirrels again.")
    elseif what == "unavailable" then
        chat("Your Guardian result could not be confirmed. Rejoin to check your title. If you did not win, reset your finds before competing again.")
	elseif what == "already" then
		chat("You already hold the harbour key, Guardian.")
	end
end)

