-- the Sky Diving Squirrel speaks in the game's speech bubble: the garden's (GardenClient bubble(), copied) - a cream bubble
-- with a brown outline and a tail, up-right of the speaker (camera-relative, so it never sits on his Talk prompt), FredokaOne
-- brown text - with one of Shannon's squirrel sounds from the Lagoon's SpeechSounds. A long line comes as several bubbles.
local PAPER, INK, FONT = Color3.fromRGB(255, 250, 240), Color3.fromRGB(120, 80, 46), Enum.Font.FredokaOne
local TEXT_INK = Color3.fromRGB(64, 42, 22)
local sqBubble = nil
local function squirrelBubble(model, text, secs, withSound)
	local anchor = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
	if not (anchor and text) then return end
	if sqBubble and sqBubble.Parent then sqBubble:Destroy() end
	local W = 250
	local rows = math.max(1, math.ceil(#text * 9 / (W - 24)))                -- FredokaOne 17 px is about 9 px a letter
	local H = 20 + 20 * rows
	local bg = Instance.new("BillboardGui"); bg.Name = "SquirrelBubble"; bg.Size = UDim2.fromOffset(W, H)
	bg.StudsOffset = Vector3.new(0, 0.8, 0); bg.ExtentsOffset = Vector3.new(0.9, 1.0, 0)   -- up and to the right of him
	bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.MaxDistance = 80; bg.Adornee = anchor
	local f = Instance.new("Frame"); f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = PAPER; f.BorderSizePixel = 0; f.ZIndex = 2; f.Parent = bg
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = f
	local st = Instance.new("UIStroke"); st.Color = INK; st.Thickness = 1.5; st.Parent = f
	local tail = Instance.new("Frame"); tail.AnchorPoint = Vector2.new(0.5, 0.5); tail.Position = UDim2.new(0.16, 0, 1, -3); tail.Size = UDim2.fromOffset(13, 13)
	tail.Rotation = 45; tail.BackgroundColor3 = PAPER; tail.BorderSizePixel = 0; tail.ZIndex = 1; tail.Parent = bg
	local ts = Instance.new("UIStroke"); ts.Color = INK; ts.Thickness = 1.5; ts.Parent = tail
	local cover = Instance.new("Frame"); cover.Position = UDim2.new(0.16, -8, 1, -12); cover.Size = UDim2.fromOffset(16, 11)
	cover.BackgroundColor3 = PAPER; cover.BorderSizePixel = 0; cover.ZIndex = 3; cover.Parent = bg
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -16, 1, -10); l.Position = UDim2.fromOffset(8, 5); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = 17; l.TextWrapped = true; l.TextColor3 = TEXT_INK; l.Text = text; l.ZIndex = 4; l.Parent = f
	bg.Parent = player:WaitForChild("PlayerGui")
	sqBubble = bg
	if withSound then
		local lag = workspace:FindFirstChild("Lagoon")
		local ids = {}
		for d in tostring(lag and lag:GetAttribute("SpeechSounds") or "73324775979494, 90860503936571, 9119556839"):gmatch("%d+") do table.insert(ids, d) end
		if #ids > 0 then
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. ids[math.random(#ids)]; s.Volume = 0.9
			s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 10; s.RollOffMaxDistance = 80; s.Parent = anchor
			s:Play(); game:GetService("Debris"):AddItem(s, 8)
			task.delay((lag and lag:GetAttribute("SpeechMax")) or 4, function()
				if s.Parent and s.IsPlaying then game:GetService("TweenService"):Create(s, TweenInfo.new(0.5), {Volume = 0}):Play() end
			end)
		end
	end
	task.delay(secs or 3.5, function() if bg.Parent then bg:Destroy() end end)
end
local function squirrelSay(lines)
	local sq = workspace:FindFirstChild("parachute_squirrel_color")
	if not sq then return end
	local prompt = sq:FindFirstChild("ChutePrompt", true)                    -- his Talk prompt steps aside while he speaks
	task.spawn(function()
		if prompt then prompt.Enabled = false end
		for i, line in ipairs(lines) do
			squirrelBubble(sq, line, 3.5, i == 1)
			task.wait(3.6)
		end
		if prompt and prompt.Parent then prompt.Enabled = true end
	end)
end
