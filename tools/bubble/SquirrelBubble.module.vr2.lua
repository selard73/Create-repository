-- SquirrelBubble (ReplicatedStorage, client): the one way every squirrel speaks to a player (Shannon, Oct 1 2026: "all the
-- bubbles should look the same"). A drawn comic bubble (italy/bubble/bubble_blob.png) in BuilderSans Medium, drawn flat in a
-- ScreenGui pinned beside the speaker every frame (world-space GUIs get tone-mapped and looked cream), a faint shadow, a
-- scale-in and a fade-out, and one of her squirrel sounds from workspace.Lagoon's SpeechSounds (SpeechMax cuts it short).
--   Bubble.say(speaker, text, opts) -> the bubble frame
--   speaker = a Model or a BasePart; opts.secs (3.5), opts.sound (true), opts.sounds (an id list string), opts.volume (0.9)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Bubble = {}
local IMAGE = "rbxassetid://98516368118872"
local SHADOW, INK = Color3.fromRGB(30, 20, 30), Color3.fromRGB(55, 45, 42)
local FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
local MAX_DIST = 80
local current = {}                                                             -- speaker part -> its bubble (a new line replaces the old; cleared when it goes)
local TOP_GUARD = 24                                                           -- inset-space px kept clear under the HUD row
local UIS = game:GetService("UserInputService")
local PHONE = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()
local COLUMN_GUARD, COLUMN_BOTTOM = PHONE and 62 or 0, 170                    -- phones: the HUD column at the right edge (x -58..-10, inset y to 166)
function Bubble.talking()                                                      -- is any bubble up, on a screen or in VR?
	for _, b in pairs(current) do if b.Parent then return true end end
	return false
end
local function gui()
	local player = Players.LocalPlayer
	local pg = player and player:FindFirstChildOfClass("PlayerGui")
	if not pg then return nil end
	local g = pg:FindFirstChild("SquirrelBubbleGui")
	if not g then
		g = Instance.new("ScreenGui"); g.Name = "SquirrelBubbleGui"; g.ResetOnSpawn = false; g.IgnoreGuiInset = false
		g.DisplayOrder = 5; g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; g.Parent = pg
	end
	return g
end
local function anchorOf(speaker)
	if typeof(speaker) ~= "Instance" then return nil end
	if speaker:IsA("BasePart") then return speaker end
	if speaker:IsA("Model") then return speaker.PrimaryPart or speaker:FindFirstChildWhichIsA("BasePart", true) end
	return speaker:FindFirstChildWhichIsA("BasePart", true)
end
local function playSound(anchor, opts)
	local lag = workspace:FindFirstChild("Lagoon")
	local list = opts.sounds or (lag and lag:GetAttribute("SpeechSounds")) or "73324775979494, 90860503936571, 9119556839"
	local ids = {}
	for d in tostring(list):gmatch("%d+") do table.insert(ids, d) end
	if #ids == 0 then return end
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. ids[math.random(#ids)]; s.Volume = opts.volume or 0.9
	s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = 10; s.RollOffMaxDistance = 80; s.Parent = anchor
	s:Play(); Debris:AddItem(s, 8)
	task.delay((lag and lag:GetAttribute("SpeechMax")) or 4, function()
		if s.Parent and s.IsPlaying then TweenService:Create(s, TweenInfo.new(0.5), {Volume = 0}):Play() end
	end)
end
-- VR (Shannon, Oct 9: the flat bubble on the head-following window "does not work well ... better just have those come up
-- beside the speaker's head in the game"): the same paper bubble as a BillboardGui beside the speaker's head, in the world
local VR = game:GetService("VRService").VREnabled
local function sayVR(anchor, text, opts)
	local old = current[anchor]; if old and old.Parent then old:Destroy() end
	local secs = opts.secs or 3.5
	local W, H = 158, 119
	if #text > 30 then W, H = 194, 145 end
	if #text > 55 then W, H = 229, 172 end
	if #text > 90 then W, H = 264, 198 end
	local ext = anchor.Size
	local bg = Instance.new("BillboardGui"); bg.Name = "SquirrelBubbleVR"; bg.Size = UDim2.fromScale(W / 40, H / 40); bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.MaxDistance = MAX_DIST
	bg.StudsOffset = Vector3.new(0.45 * ext.X + W / 80, 0.5 * ext.Y + H / 80 + 0.4, 0)   -- up and to the right of the head, as on a screen
	bg.Adornee = anchor
	local root = Instance.new("Frame"); root.Size = UDim2.fromScale(1, 1); root.BackgroundTransparency = 1; root.Parent = bg
	local scale = Instance.new("UIScale"); scale.Scale = 0.86; scale.Parent = root
	local function pic(name, pos, colour, z, transparency)
		local i = Instance.new("ImageLabel"); i.Name = name; i.Size = UDim2.fromScale(1, 1); i.Position = pos; i.BackgroundTransparency = 1
		i.Image = IMAGE; i.ImageColor3 = colour; i.ImageTransparency = transparency or 0; i.ScaleType = Enum.ScaleType.Stretch; i.ZIndex = z; i.Parent = root
		return i
	end
	local shadow = pic("Shadow", UDim2.fromScale(0.012, 0.025), SHADOW, 1, 0.9)
	local paper = pic("Paper", UDim2.fromScale(0, 0), Color3.new(1, 1, 1), 2)
	local l = Instance.new("TextLabel"); l.AnchorPoint = Vector2.new(0.5, 0.5); l.Position = UDim2.fromScale(0.5, 0.455); l.Size = UDim2.new(0.66, 0, 0.58, 0)
	l.BackgroundTransparency = 1; l.FontFace = FONT; l.TextScaled = true; l.TextWrapped = true; l.TextColor3 = INK; l.Text = text; l.ZIndex = 3; l.Parent = root
	bg.Parent = anchor
	current[anchor] = bg
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
	if opts.sound ~= false then playSound(anchor, opts) end
	task.delay(secs - 0.3, function()
		if not bg.Parent then return end
		local ti = TweenInfo.new(0.3)
		TweenService:Create(shadow, ti, {ImageTransparency = 1}):Play(); TweenService:Create(paper, ti, {ImageTransparency = 1}):Play(); TweenService:Create(l, ti, {TextTransparency = 1}):Play()
	end)
	task.delay(secs, function() if bg.Parent then bg:Destroy() end; if current[anchor] == bg then current[anchor] = nil end end)
	return bg
end
function Bubble.say(speaker, text, opts)
	opts = opts or {}
	local anchor = anchorOf(speaker)
	local g = gui()
	if not (anchor and g and type(text) == "string" and text ~= "") then return nil end
	for a, b in pairs(current) do if a ~= anchor then if b.Parent then b:Destroy() end; current[a] = nil end end   -- (newest wins: one bubble at a time; the ambient chatter never starts over another, so this only cuts a chatter line short for a scripted one)
	if VR then return sayVR(anchor, text, opts) end
	local old = current[anchor]; if old and old.Parent then old:Destroy() end
	local secs = opts.secs or 3.5
	local W, H = 158, 119                                                      -- the image is 440 x 330; the text wraps into short lines
	if #text > 30 then W, H = 194, 145 end
	if #text > 55 then W, H = 229, 172 end
	if #text > 90 then W, H = 264, 198 end
	local root = Instance.new("Frame"); root.Name = "SquirrelBubble"; root.AnchorPoint = Vector2.new(0, 1)   -- (hung by its bottom-left corner, placed beside the speaker every frame)
	root.Size = UDim2.fromOffset(W, H); root.BackgroundTransparency = 1; root.Visible = false
	local scale = Instance.new("UIScale"); scale.Scale = 0.86; scale.Parent = root
	local function pic(name, pos, colour, z, transparency)
		local i = Instance.new("ImageLabel"); i.Name = name; i.Size = UDim2.fromScale(1, 1); i.Position = pos; i.BackgroundTransparency = 1
		i.Image = IMAGE; i.ImageColor3 = colour; i.ImageTransparency = transparency or 0; i.ScaleType = Enum.ScaleType.Stretch; i.ZIndex = z; i.Parent = root
		return i
	end
	local shadow = pic("Shadow", UDim2.fromOffset(2, 3), SHADOW, 1, 0.9)
	local paper = pic("Paper", UDim2.fromOffset(0, 0), Color3.new(1, 1, 1), 2)
	local l = Instance.new("TextLabel"); l.AnchorPoint = Vector2.new(0.5, 0.5); l.Position = UDim2.fromScale(0.5, 0.455); l.Size = UDim2.new(0.66, 0, 0.58, 0)
	l.BackgroundTransparency = 1; l.FontFace = FONT; l.TextSize = 15; l.TextWrapped = true; l.TextColor3 = INK; l.Text = text; l.ZIndex = 3; l.Parent = root
	root.Parent = g
	current[anchor] = root
	-- beside the speaker: the speaker part's box is projected to the screen each frame and the bubble hangs off its right
	-- side (or its left side, mirrored, when the right has no room), its bottom at the box's top when that fits under the
	-- HUD row, else alongside at body level. The side is picked once per bubble and only changes when it stops fitting and
	-- the other side would. The tail sits a third of the way in from the speaker's side, so when the bubble is wholly above
	-- the box it leans over the head by that much; alongside, it keeps fully clear. Never clamped into the speaker: with no
	-- room on either side it overhangs the screen's edge instead.
	local conn, side, flipped = nil, nil, false
	conn = RunService.RenderStepped:Connect(function()
		if not (root.Parent and anchor.Parent) then if conn then conn:Disconnect() end; return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local cf, hs = anchor.CFrame, anchor.Size / 2
		local x0, x1, y0, n = math.huge, -math.huge, math.huge, 0
		for i = 0, 7 do
			local c = cf * Vector3.new(i % 2 == 0 and -hs.X or hs.X, math.floor(i / 2) % 2 == 0 and -hs.Y or hs.Y, i < 4 and -hs.Z or hs.Z)
			local q = cam:WorldToScreenPoint(c)
			if q.Z > 0 then x0, x1, y0, n = math.min(x0, q.X), math.max(x1, q.X), math.min(y0, q.Y), n + 1 end
		end
		local dist = (anchor.Position - cam.CFrame.Position).Magnitude
		root.Visible = n > 0 and dist <= MAX_DIST
		if n == 0 then return end
		local gs, w, h = g.AbsoluteSize, root.AbsoluteSize.X, root.AbsoluteSize.Y
		local y = math.clamp(y0 - 2, TOP_GUARD + h, math.max(TOP_GUARD + h, gs.Y - 4))
		local lean = 0.33 * w * math.clamp(1 - (y - (y0 - 2)) / math.max(1, 0.25 * h), 0, 1)   -- (full lean when wholly above the box, none once pushed down alongside it)
		local rightEdge = gs.X - 4 - ((COLUMN_GUARD > 0 and y - h < COLUMN_BOTTOM) and COLUMN_GUARD or 0)
		local xr, xl = x1 + 6 - lean, x0 - 6 + lean - w                     -- the left edge on the right side / on the left side
		local roomR, roomL = rightEdge - xr - w, xl - 4
		if side == nil or (side == 1 and roomR < 0 and roomL >= 0) or (side == -1 and roomL < 0 and roomR >= 0) then
			side = (roomR >= 0 or roomR >= roomL) and 1 or -1
		end
		root.Position = UDim2.fromOffset(side == 1 and xr or xl, y)
		local flip = side == -1
		if flip ~= flipped then
			flipped = flip
			for _, i in ipairs({shadow, paper}) do i.ImageRectOffset = flip and Vector2.new(440, 0) or Vector2.new(0, 0); i.ImageRectSize = flip and Vector2.new(-440, 330) or Vector2.new(0, 0) end
		end
	end)
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
	if opts.sound ~= false then playSound(anchor, opts) end
	task.delay(secs - 0.3, function()
		if not root.Parent then return end
		local ti = TweenInfo.new(0.3)
		TweenService:Create(shadow, ti, {ImageTransparency = 1}):Play()
		TweenService:Create(paper, ti, {ImageTransparency = 1}):Play()
		TweenService:Create(l, ti, {TextTransparency = 1}):Play()
	end)
	task.delay(secs, function() if conn then conn:Disconnect() end; if root.Parent then root:Destroy() end; if current[anchor] == root then current[anchor] = nil end end)
	return root
end
return Bubble
