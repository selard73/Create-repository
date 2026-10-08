-- the Sky Diving Squirrel speaks in a speech bubble over him, up and to the right (camera-relative, so it never sits on his
-- Talk prompt): warm white, softly rounded, a thin tan rim and a soft shadow instead of a hard outline, a small tail, the
-- text in BuilderSans Medium (her picks, Oct 1 2026). It scales in and fades out. One of Shannon's squirrel sounds from the
-- Lagoon's SpeechSounds with the first line; a long line comes as several bubbles.
local PAPER, RIM, SHADOW, TEXT_INK = Color3.fromRGB(255, 252, 246), Color3.fromRGB(196, 170, 140), Color3.fromRGB(60, 40, 20), Color3.fromRGB(70, 48, 30)
local TEXT_FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
local TweenService = game:GetService("TweenService")
local sqBubble = nil
local function squirrelBubble(model, text, secs, withSound)
	local anchor = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
	if not (anchor and text) then return end
	if sqBubble and sqBubble.Parent then sqBubble:Destroy() end
	secs = secs or 3.5
	local W = 260
	local rows = math.max(1, math.ceil(#text * 8.5 / (W - 40)))              -- BuilderSans Medium 16 px is about 8.5 px a letter
	local H = 26 + 20 * rows
	local R = 20                                                               -- softly rounded: a bubble, not a box, not a pill
	local bg = Instance.new("BillboardGui"); bg.Name = "SquirrelBubble"; bg.Size = UDim2.fromOffset(W, H + 10)
	bg.StudsOffset = Vector3.new(0, 0.8, 0); bg.ExtentsOffset = Vector3.new(0.9, 1.0, 0)   -- up and to the right of him
	bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.MaxDistance = 80; bg.Adornee = anchor
	-- everything sits in one frame so the whole bubble scales in together
	local root = Instance.new("Frame"); root.Name = "Root"; root.AnchorPoint = Vector2.new(0.5, 0.5); root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromScale(1, 1); root.BackgroundTransparency = 1; root.Parent = bg
	local scale = Instance.new("UIScale"); scale.Scale = 0.86; scale.Parent = root
	local shadow = Instance.new("Frame"); shadow.Size = UDim2.new(1, 0, 0, H); shadow.Position = UDim2.fromOffset(0, 3)
	shadow.BackgroundColor3 = SHADOW; shadow.BackgroundTransparency = 0.82; shadow.BorderSizePixel = 0; shadow.ZIndex = 1; shadow.Parent = root
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, R); sc.Parent = shadow
	local f = Instance.new("Frame"); f.Size = UDim2.new(1, 0, 0, H); f.BackgroundColor3 = PAPER; f.BorderSizePixel = 0; f.ZIndex = 2; f.Parent = root
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, R); c.Parent = f
	local st = Instance.new("UIStroke"); st.Color = RIM; st.Thickness = 1; st.Transparency = 0.15; st.Parent = f
	local tail = Instance.new("Frame"); tail.AnchorPoint = Vector2.new(0.5, 0.5); tail.Position = UDim2.new(0.18, 0, 0, H - 3); tail.Size = UDim2.fromOffset(12, 12)
	tail.Rotation = 45; tail.BackgroundColor3 = PAPER; tail.BorderSizePixel = 0; tail.ZIndex = 1; tail.Parent = root
	local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 2); tc.Parent = tail
	local ts = Instance.new("UIStroke"); ts.Color = RIM; ts.Thickness = 1; ts.Transparency = 0.15; ts.Parent = tail
	local cover = Instance.new("Frame"); cover.Position = UDim2.new(0.18, -8, 0, H - 12); cover.Size = UDim2.fromOffset(16, 11)
	cover.BackgroundColor3 = PAPER; cover.BorderSizePixel = 0; cover.ZIndex = 3; cover.Parent = root
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -36, 0, H - 14); l.Position = UDim2.fromOffset(18, 7); l.BackgroundTransparency = 1
	l.FontFace = TEXT_FONT; l.TextSize = 16; l.TextWrapped = true; l.TextColor3 = TEXT_INK; l.Text = text; l.ZIndex = 4; l.Parent = root
	bg.Parent = player:WaitForChild("PlayerGui")
	sqBubble = bg
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
	if withSound then
		local lag = workspace:FindFirstChild("Lagoon")
		local ids = {}
		for d in tostring(lag and lag:GetAttribute("SpeechSounds") or "73324775979494, 90860503936571, 9119556839"):gmatch("%d+") do table.insert(ids, d) end
		if #ids > 0 then
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. ids[math.random(#ids)]; s.Volume = 0.9
			s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 10; s.RollOffMaxDistance = 80; s.Parent = anchor
			s:Play(); game:GetService("Debris"):AddItem(s, 8)
			task.delay((lag and lag:GetAttribute("SpeechMax")) or 4, function()
				if s.Parent and s.IsPlaying then TweenService:Create(s, TweenInfo.new(0.5), {Volume = 0}):Play() end
			end)
		end
	end
	task.delay(secs - 0.3, function()
		if not bg.Parent then return end
		local ti = TweenInfo.new(0.3)
		for _, o in ipairs({f, tail, cover, shadow}) do TweenService:Create(o, ti, {BackgroundTransparency = 1}):Play() end
		TweenService:Create(l, ti, {TextTransparency = 1}):Play()
		TweenService:Create(st, ti, {Transparency = 1}):Play()
		TweenService:Create(ts, ti, {Transparency = 1}):Play()
	end)
	task.delay(secs, function() if bg.Parent then bg:Destroy() end end)
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
