-- the Sky Diving Squirrel speaks in a comic speech bubble over him, up and to the right (camera-relative, so it never sits on
-- his Talk prompt): a white OVAL with a thin red-to-purple rim, a small tail at the bottom left and a soft shadow - her
-- reference image (clipboard, Oct 1 2026 09:23) - with the text in BuilderSans Medium. It scales in and fades out. One of
-- Shannon's squirrel sounds from the Lagoon's SpeechSounds with the first line; a long line comes as several bubbles.
local CIRCLE = "rbxassetid://3570695787"                                    -- a plain white disc; stretched it is the oval
local PAPER, SHADOW, TEXT_INK = Color3.fromRGB(255, 255, 255), Color3.fromRGB(30, 20, 30), Color3.fromRGB(55, 45, 42)
local RIM_A, RIM_B = Color3.fromRGB(232, 48, 72), Color3.fromRGB(118, 58, 200)   -- red at the top left, purple at the bottom right
local TEXT_FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
local TweenService = game:GetService("TweenService")
local function rimGradient(parent)
	local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(RIM_A, RIM_B); g.Rotation = 25; g.Parent = parent
end
local sqBubble = nil
local function squirrelBubble(model, text, secs, withSound)
	local anchor = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
	if not (anchor and text) then return end
	if sqBubble and sqBubble.Parent then sqBubble:Destroy() end
	secs = secs or 3.5
	local W = 300
	local rows = math.max(1, math.ceil(#text * 8.5 / (W * 0.74)))            -- the text sits in the oval's inner three quarters
	local H = 36 + 22 * rows
	local bg = Instance.new("BillboardGui"); bg.Name = "SquirrelBubble"; bg.Size = UDim2.fromOffset(W + 8, H + 16)
	bg.StudsOffset = Vector3.new(0, 0.8, 0); bg.ExtentsOffset = Vector3.new(0.9, 1.0, 0)   -- up and to the right of him
	bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.MaxDistance = 80; bg.Adornee = anchor
	-- everything sits in one frame so the whole bubble scales in together
	local root = Instance.new("Frame"); root.Name = "Root"; root.AnchorPoint = Vector2.new(0.5, 0.5); root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(W, H); root.BackgroundTransparency = 1; root.Parent = bg
	local scale = Instance.new("UIScale"); scale.Scale = 0.86; scale.Parent = root
	local function disc(name, size, pos, colour, z, transparency)
		local i = Instance.new("ImageLabel"); i.Name = name; i.Size = size; i.Position = pos; i.BackgroundTransparency = 1
		i.Image = CIRCLE; i.ImageColor3 = colour; i.ImageTransparency = transparency or 0; i.ScaleType = Enum.ScaleType.Stretch; i.ZIndex = z; i.Parent = root
		return i
	end
	local shadow = disc("Shadow", UDim2.new(1, 2, 1, 2), UDim2.fromOffset(2, 5), SHADOW, 1, 0.8)
	local rim = disc("Rim", UDim2.new(1, 4, 1, 4), UDim2.fromOffset(-2, -2), Color3.new(1, 1, 1), 2)
	rimGradient(rim)
	local paper = disc("Paper", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), PAPER, 3)
	-- the tail: a small diamond whose top half hides under the oval; its rim carries the same gradient
	local tx, ty = 0.22, 0.914                                                 -- where the oval's lower edge passes at 22% across
	local tail = Instance.new("Frame"); tail.Name = "Tail"; tail.AnchorPoint = Vector2.new(0.5, 0.5); tail.Position = UDim2.new(tx, 0, ty, 3)
	tail.Size = UDim2.fromOffset(16, 16); tail.Rotation = 45; tail.BackgroundColor3 = PAPER; tail.BorderSizePixel = 0; tail.ZIndex = 2; tail.Parent = root
	local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 2); tc.Parent = tail
	local ts = Instance.new("UIStroke"); ts.Color = Color3.new(1, 1, 1); ts.Thickness = 2; ts.Parent = tail
	rimGradient(ts)
	local cover = Instance.new("Frame"); cover.Name = "Cover"; cover.AnchorPoint = Vector2.new(0.5, 0.5); cover.Position = UDim2.new(tx, 0, ty, -3)
	cover.Size = UDim2.fromOffset(14, 8); cover.BackgroundColor3 = PAPER; cover.BorderSizePixel = 0; cover.ZIndex = 4; cover.Parent = root
	local l = Instance.new("TextLabel"); l.AnchorPoint = Vector2.new(0.5, 0.5); l.Position = UDim2.fromScale(0.5, 0.48); l.Size = UDim2.new(0.74, 0, 0.78, 0)
	l.BackgroundTransparency = 1; l.FontFace = TEXT_FONT; l.TextSize = 16; l.TextWrapped = true; l.TextColor3 = TEXT_INK; l.Text = text; l.ZIndex = 5; l.Parent = root
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
		for _, o in ipairs({shadow, rim, paper}) do TweenService:Create(o, ti, {ImageTransparency = 1}):Play() end
		for _, o in ipairs({tail, cover}) do TweenService:Create(o, ti, {BackgroundTransparency = 1}):Play() end
		TweenService:Create(ts, ti, {Transparency = 1}):Play()
		TweenService:Create(l, ti, {TextTransparency = 1}):Play()
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
