-- the Sky Diving Squirrel speaks in a comic speech bubble over him, up and to the right (camera-relative, so it never sits on
-- his Talk prompt): the bubble is a drawn image (italy/bubble/bubble_blob.png: an irregular rounded blob with a thin brown
-- outline and a small tail at the bottom left - the shape of her reference, Oct 1 2026), white, with a soft shadow copy
-- behind it; the text in BuilderSans Medium. It scales in and fades out. One of Shannon's squirrel sounds from the Lagoon's
-- SpeechSounds with the first line; a long line comes as several bubbles.
local BUBBLE_IMAGE = "rbxassetid://98516368118872"                                   -- uploaded with the Import 3D carrier
local SHADOW, TEXT_INK = Color3.fromRGB(30, 20, 30), Color3.fromRGB(55, 45, 42)
local TEXT_FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
local TweenService = game:GetService("TweenService")
local sqBubble = nil
local function squirrelBubble(model, text, secs, withSound)
	local anchor = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
	if not (anchor and text) then return end
	if sqBubble and sqBubble.Parent then sqBubble:Destroy() end
	secs = secs or 3.5
	local W, H = 180, 135                                                      -- the image is 440 x 330; the text wraps into short lines
	if #text > 30 then W, H = 220, 165 end
	if #text > 55 then W, H = 260, 195 end
	if #text > 90 then W, H = 300, 225 end
	local bg = Instance.new("BillboardGui"); bg.Name = "SquirrelBubble"; bg.Size = UDim2.fromOffset(W + 8, H + 8)
	bg.StudsOffset = Vector3.new(0, 1.5, 0); bg.ExtentsOffset = Vector3.new(0.9, 1.0, 0)   -- up and to the right of him
	bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.MaxDistance = 80; bg.Adornee = anchor
	-- everything sits in one frame so the whole bubble scales in together
	local root = Instance.new("Frame"); root.Name = "Root"; root.AnchorPoint = Vector2.new(0.5, 0.5); root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(W, H); root.BackgroundTransparency = 1; root.Parent = bg
	local scale = Instance.new("UIScale"); scale.Scale = 0.86; scale.Parent = root
	local function pic(name, pos, colour, z, transparency)
		local i = Instance.new("ImageLabel"); i.Name = name; i.Size = UDim2.fromScale(1, 1); i.Position = pos; i.BackgroundTransparency = 1
		i.Image = BUBBLE_IMAGE; i.ImageColor3 = colour; i.ImageTransparency = transparency or 0; i.ScaleType = Enum.ScaleType.Stretch; i.ZIndex = z; i.Parent = root
		return i
	end
	local shadow = pic("Shadow", UDim2.fromOffset(3, 5), SHADOW, 1, 0.8)
	local paper = pic("Paper", UDim2.fromOffset(0, 0), Color3.new(1, 1, 1), 2)
	local l = Instance.new("TextLabel"); l.AnchorPoint = Vector2.new(0.5, 0.5); l.Position = UDim2.fromScale(0.5, 0.455); l.Size = UDim2.new(0.66, 0, 0.58, 0)
	l.BackgroundTransparency = 1; l.FontFace = TEXT_FONT; l.TextSize = 16; l.TextWrapped = true; l.TextColor3 = TEXT_INK; l.Text = text; l.ZIndex = 3; l.Parent = root
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
		TweenService:Create(shadow, ti, {ImageTransparency = 1}):Play()
		TweenService:Create(paper, ti, {ImageTransparency = 1}):Play()
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
