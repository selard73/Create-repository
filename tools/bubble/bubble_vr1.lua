-- bubble/bubble_vr1 (job 55): EDIT mode. Squirrel speech bubbles beside the speaker's head in VR (flat screens unchanged).
-- One exact find in ReplicatedStorage.SquirrelBubble (5785 chars, the repo's copy of the module); compiled before writing;
-- original -> ServerStorage.HudBackup.SquirrelBubble_pre_vr1. Output "QQ BUB".
if game:GetService("RunService"):IsRunning() then warn("QQ BUB ABORT - Play mode") return end
local m = game:GetService("ReplicatedStorage"):FindFirstChild("SquirrelBubble")
if not (m and m:IsA("ModuleScript")) then warn("QQ BUB ABORT - ReplicatedStorage.SquirrelBubble missing") return end
if #m.Source ~= 5785 then warn(string.format("QQ BUB ABORT - SquirrelBubble is %d chars, expected 5785 (differs from the repo copy, or already patched); nothing changed", #m.Source)) return end
local o = m.Source
local a, b = o:find([===[
function Bubble.say(speaker, text, opts)
	opts = opts or {}
	local anchor = anchorOf(speaker)
	local g = gui()
	if not (anchor and g and type(text) == "string" and text ~= "") then return nil end
]===], 1, true)
if not a then warn("QQ BUB ABORT - the head of Bubble.say was not found; nothing changed") return end
if o:find([===[
function Bubble.say(speaker, text, opts)
	opts = opts or {}
	local anchor = anchorOf(speaker)
	local g = gui()
	if not (anchor and g and type(text) == "string" and text ~= "") then return nil end
]===], b + 1, true) then warn("QQ BUB ABORT - the find matches more than once; nothing changed") return end
o = o:sub(1, a - 1) .. [===[
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
	if VR then return sayVR(anchor, text, opts) end
]===] .. o:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ BUB ABORT - patched module does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = m:Clone(); c.Name = "SquirrelBubble_pre_vr1"; c.Parent = backup
m.Source = o
print(string.format("QQ BUB DONE: SquirrelBubble %d -> %d chars; backup ServerStorage.HudBackup.SquirrelBubble_pre_vr1", 5785, #m.Source))
