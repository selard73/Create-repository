-- TitleClient: the honour pill on screen, and the celebration when a title is earned (banner, sparkles, fanfare, chat).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local H = script.Parent
local ev = H:WaitForChild("HonourEarned")
local C = Color3.fromRGB
local COLOURS = {C(205, 127, 50), C(200, 204, 212), C(240, 196, 60), C(46, 150, 214)}
local function medallion(parent, size, colour)                        -- a round medal with a little acorn drawn from frames
	local m = Instance.new("Frame"); m.Name = "Medal"; m.Size = UDim2.new(0, size, 0, size); m.BackgroundColor3 = colour; m.BorderSizePixel = 0; m.Parent = parent
	local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0.5, 0); mc.Parent = m
	local ring = Instance.new("UIStroke"); ring.Color = C(80, 52, 30); ring.Thi0.45, 0); cc.Parent = cap
	local stem = Instance.new("Frame"); stem.Size = UDim2.new(0.08, 0, 0.14, 0); stem.Position = UDim2.new(0.46, 0, 0.1, 0); stem.BackgroundColor3 = C(80, 52, 30); stem.BorderSizePixel = 0; stem.Parent = m
	return m
end
local gui = Instance.new("ScreenGui"); gui.Name = "HonourBar"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = player:WaitForChild("PlayerGui")
local pill = Instance.new("Frame"); pill.Name = "Pill"; pill.Size = UDim2.new(0, 400, 0, 44); pill.Position = UDim2.new(0.5, -200, 0, 10); pill.BackgroundColor3 = C(38, 30, 52)
pill.BackgroundTransparency = 0.15; pill.BorderSizePixel = 0; pill.Visible = false; pill.Parent = gui
local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 22); pc.Parent = pill
local ps = Instance.new("UIStroke"); ps.Color = C(240, 200, 90); ps.Thickness = 2; ps.Parent = pill
local pm = medallion(pill, 34, COLOURS[1]); pmbel on a single line.
local TextService = game:GetService("TextService")
local pillW = 400
local function fitTitle()
	local avail = pillW - 52 - 10
	local size = 24
	while size > 10 do
		local b = TextService:GetTextSize(pt.Text, size, pt.Font, Vector2.new(4000, 100))
		if b.X <= avail then break end
		size -= 1
	end
	pt.TextSize = size
end
-- THE WIDTH COMES FROM THE SCREEN. A fixed 400 ran into the buttons top-left (menu, chat, mic, Hint: about 330 px)
-- and the counters top-right (about 220 px) on a phone (Shannon). The pill takes what is left between them, at
-- most 400, at least 230, and TextScaled shrinks the longest title to fit.
local function fitPill()
	local cam = workspace.CurrentCamera
	local vw = cam and cam.ViewportSize.X or 1280
	local w = math.clamp(vw - 2 * 345, 230, 400)
	pillW = w
	pill.Size = UDim2.new(0, w, 0, 44); pill.Position = UDim2.new(0.5, -w / 2, 0, 10)
	fitTitle()
end
fitPiller"; banner.Size = UDim2.new(0, 640, 0, 120); banner.Position = UDim2.new(0.5, -320, 0.3, 0); banner.BackgroundColor3 = C(38, 30, 52)
banner.BackgroundTransparency = 0.1; banner.BorderSizePixel = 0; banner.Visible = false; banner.Parent = gui
local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 18); bc.Parent = banner
local bs = Instance.new("UIStroke"); bs.Color = C(240, 200, 90); bs.Thickness = 3; bs.Parent = banner
local bm = medallion(banner, 72, COLOURS[1]); bm.Position = UDim2.new(0, 22, 0.5, -36)
local b1 = Instance.new("TextLabel"); b1.Size = UDim2.new(1, -120, 0, 40); b1.Position = UDim2.new(0, 108, 0, 18); b1.BackgroundTransparency = 1
b1.Font = Enum.Font.FredokaOne; b1.TextSize = 26; b1.TextColor3 = C(255, 246, 220); b1.TextXAlignment = Enum.TextXAlignment.Left; b1.Text = ""; b1.Parent = banner
local b2 = Instance.new("TextLabel"); b2.Size = UDim2.new(1, -120, 0, 44); b2.Position =! You are now a"
	b2.Text = title
	banner.Visible = true; banner.Position = UDim2.new(0.5, -320, 0.24, 0)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -320, 0.3, 0)}):Play()
	local t = os.clock(); shownAt = t
	task.delay(6, function() if shownAt == t then banner.Visible = false end end)
	local s = Instance.new("Sound"); s.SoundId = "rbxassetid://1845415163"; s.Volume = 0.6; s.Parent = gui; s:Play(); Debris:AddItem(s, 6)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if head then
		local a = Instance.new("Attachment"); a.Position = Vector3.new(0, 1, 0); a.Parent = head
		local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new(COLOURS[tier] or COLOURS[1], C(255, 250, 220)); pe.Size = NumberSequence.new(0.6, 0); peplaySystemMessage(string.format("%s is now a %s!", who.DisplayName, title)) end   -- ("a": everyone who finds all 44 is a Squirrel Sage)
	end)
end)
