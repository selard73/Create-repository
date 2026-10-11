-- SquirrelBubble (ReplicatedStorage, client): the one way every squirrel speaks to a player (Shannon, Oct 1 2026: "all the
-- bubbles should look the same"). A drawn comic bubble (italy/bubble/bubble_blob.png) in BuilderSans Medium, drawn flat in a
-- ScreenGui pinned to the speaker every frame (world-space GUIs get tone-mapped and looked cream), a faint shadow, a
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
local current = setmetatable({}, {__mode = "k"})                               -- speaker part -> its bubble (a new line replaces the old)
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
	task.delay(secs, function() if bg.Parent then bg:Destroy() end end)
	return bg
end
function Bubble.say(speaker, text, opts)
	opts = opts or {}
	local anchor = anchorOf(speaker)
	local g = gui()
	if not (anchor and g and type(text) == "string" and text ~= "") then return nil end
	for a, b in pairs(current) do if a ~= anchor and b.Parent then b:Destroy() end end   -- (newest wins: one bubble at a time; the ambient chatter never starts over another, so this only cuts a chatter line short for a scripted one)
	if VR then return sayVR(anchor, text, opts) end
	local old = current[anchor]; if old and old.Parent then old:Destroy() end
	local secs = opts.secs or 3.5
	local W, H = 158, 119                                                      -- the image is 440 x 330; the text wraps into short lines
	if #text > 30 then W, H = 194, 145 end
	if #text > 55 then W, H = 229, 172 end
	if #text > 90 then W, H = 264, 198 end
	local root = Instance.new("Frame"); root.Name = "SquirrelBubble"; root.AnchorPoint = Vector2.new(0.5, 0.5)
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
	-- pinned to the speaker: up and to the right in camera space, like a BillboardGui with an ExtentsOffset, but drawn flat
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not (root.Parent and anchor.Parent) then if conn then conn:Disconnect() end; return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local ext = anchor.Size
		local world = anchor.Position + Vector3.new(0, 1.5, 0) + cam.CFrame.RightVector * (0.9 * ext.X / 2) + cam.CFrame.UpVector * (1.0 * ext.Y / 2)
		local p = cam:WorldToScreenPoint(world)
		local dist = (world - cam.CFrame.Position).Magnitude
		root.Visible = p.Z > 0 and dist <= MAX_DIST
		root.Position = UDim2.fromOffset(p.X, p.Y)
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
	task.delay(secs, function() if conn then conn:Disconnect() end; if root.Parent then root:Destroy() end end)
	return root
end
return Bubble
