-- the Sky Diving Squirrel speaks in a comic speech bubble over him, up and to the right (camera-relative, so it never sits on
-- his Talk prompt): the bubble is a drawn image (italy/bubble/bubble_blob.png: an irregular rounded blob with a thin brown
-- outline and a small tail at the bottom left - the shape of her reference, Oct 1 2026) with a faint shadow copy behind it;
-- the text in BuilderSans Medium. It is drawn in a ScreenGui pinned to his position every frame rather than a BillboardGui:
-- the 3D pass tone-maps world-space GUIs and a white bubble came out cream (her note). It scales in and fades out. One of
-- Shannon's squirrel sounds from the Lagoon's SpeechSounds with the first line; a long line comes as several bubbles.
local BUBBLE_IMAGE = "rbxassetid://98516368118872"                          -- uploaded with the Import 3D carrier
local SHADOW, TEXT_INK = Color3.fromRGB(30, 20, 30), Color3.fromRGB(55, 45, 42)
local TEXT_FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
local TweenService = game:GetService("TweenService")
local BUBBLE_MAX_DIST = 80
local sqBubble = nil
local function bubbleGui()
	local pg = player:WaitForChild("PlayerGui")
	local g = pg:FindFirstChild("SquirrelBubbleGui")
	if not g then
		g = Instance.new("ScreenGui"); g.Name = "SquirrelBubbleGui"; g.ResetOnSpawn = false; g.IgnoreGuiInset = false
		g.DisplayOrder = 5; g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; g.Parent = pg
	end
	return g
end
local function squirrelBubble(model, text, secs, withSound)
	local anchor = model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true))
	if not (anchor and text) then return end
	if sqBubble and sqBubble.Parent then sqBubble:Destroy() end
	secs = secs or 3.5
	local W, H = 158, 119                                                      -- the image is 440 x 330; the text wraps into short lines
	if #text > 30 then W, H = 194, 145 end
	if #text > 55 then W, H = 229, 172 end
	if #text > 90 then W, H = 264, 198 end
	local root = Instance.new("Frame"); root.Name = "SquirrelBubble"; root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Size = UDim2.fromOffset(W, H); root.BackgroundTransparency = 1; root.Visible = false
	local scale = Instance.new("UIScale"); scale.Scale = 0.86; scale.Parent = root
	local function pic(name, pos, colour, z, transparency)
		local i = Instance.new("ImageLabel"); i.Name = name; i.Size = UDim2.fromScale(1, 1); i.Position = pos; i.BackgroundTransparency = 1
		i.Image = BUBBLE_IMAGE; i.ImageColor3 = colour; i.ImageTransparency = transparency or 0; i.ScaleType = Enum.ScaleType.Stretch; i.ZIndex = z; i.Parent = root
		return i
	end
	local shadow = pic("Shadow", UDim2.fromOffset(2, 3), SHADOW, 1, 0.9)        -- faint, just a lift off the scene
	local paper = pic("Paper", UDim2.fromOffset(0, 0), Color3.new(1, 1, 1), 2)
	local l = Instance.new("TextLabel"); l.AnchorPoint = Vector2.new(0.5, 0.5); l.Position = UDim2.fromScale(0.5, 0.455); l.Size = UDim2.new(0.66, 0, 0.58, 0)
	l.BackgroundTransparency = 1; l.FontFace = TEXT_FONT; l.TextSize = 15; l.TextWrapped = true; l.TextColor3 = TEXT_INK; l.Text = text; l.ZIndex = 3; l.Parent = root
	root.Parent = bubbleGui()
	sqBubble = root
	-- pinned to him: up and to the right in camera space, like a BillboardGui with an ExtentsOffset, but drawn flat
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not (root.Parent and anchor.Parent) then if conn then conn:Disconnect() end; return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local ext = anchor.Size
		local world = anchor.Position + Vector3.new(0, 1.5, 0) + cam.CFrame.RightVector * (0.9 * ext.X / 2) + cam.CFrame.UpVector * (1.0 * ext.Y / 2)
		local p, onScreen = cam:WorldToScreenPoint(world)
		local dist = (world - cam.CFrame.Position).Magnitude
		root.Visible = p.Z > 0 and dist <= BUBBLE_MAX_DIST
		root.Position = UDim2.fromOffset(p.X, p.Y)
	end)
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
		if not root.Parent then return end
		local ti = TweenInfo.new(0.3)
		TweenService:Create(shadow, ti, {ImageTransparency = 1}):Play()
		TweenService:Create(paper, ti, {ImageTransparency = 1}):Play()
		TweenService:Create(l, ti, {TextTransparency = 1}):Play()
	end)
	task.delay(secs, function() if conn then conn:Disconnect() end; if root.Parent then root:Destroy() end end)
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
