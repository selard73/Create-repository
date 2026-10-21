-- reveal7 (Oct 20 2026), three small changes, previewed in an iPad play test first (Shannon: "that looks great!"):
--  1. SeaGlassClient: the pick-up reveal (Shannon: "when you pick one up can you do a pretty reveal on the screen like you do
--     with the squirrels?") - the piece pops up in a round gold-rimmed window mid-screen, spinning, gold diamonds twinkling
--     round it, its name and "You have N"; 2.5 s (rare ones bigger, 3.2 s); the acorn pick-up chime. Flat screens; VR keeps
--     the toast. While it shows, PlayerGui attribute PromptsHidden = true.
--  2. PromptClient: prompt buttons step aside while PromptsHidden is set (so a "Pick up" pill never sits on the reveal).
--  3. Bottles: Shannon: "instead of a reply washes up tomorrow, do 'Expect a reply in 24 hours'" - every player-facing
--     "tomorrow" line in BottleClient and BottleServer.
-- Run in Studio EDIT. Backs every script up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local function replaceOnce(src, find, repl, what)
	local a, b = src:find(find, 1, true)
	assert(a, what .. ": text not found - nothing changed")
	assert(not src:find(find, b + 1, true), what .. ": text found twice - nothing changed")
	return src:sub(1, a - 1) .. repl .. src:sub(b + 1)
end
local function replaceAll(src, find, repl, want, what)
	local out, n, i = {}, 0, 1
	while true do
		local a, b = src:find(find, i, true)
		if not a then break end
		table.insert(out, src:sub(i, a - 1)); table.insert(out, repl); i = b + 1; n += 1
		if n > 20 then break end
	end
	table.insert(out, src:sub(i))
	assert(n == want, string.format("%s: expected %d, found %d - nothing changed", what, want, n))
	return table.concat(out)
end

-- ---------- 1. SeaGlassClient ----------
local sgc = workspace.SeaGlass.SeaGlassClient
local sgSrc = sgc.Source
assert(not sgSrc:find("PromptsHidden", 1, true), "SeaGlassClient already patched")
local revealCode = [[
-- the pick-up reveal (Oct 20 2026, Shannon: "when you pick one up can you do a pretty reveal on the screen like you do with
-- the squirrels?"): the piece pops up in a round gold-rimmed window in the middle of the screen, spinning, gold diamonds
-- twinkling round it, its name and how many you have; 2.5 s (rare ones bigger, 3.2 s), the acorn pick-up chime. Flat
-- screens (VR keeps the toast). While it shows, the prompt buttons step aside (PlayerGui attribute PromptsHidden, read by
-- PromptClient) so a "Pick up" button never sits on it. (A ViewportFrame draws Glass as pale silver, so the glass here is
-- smooth plastic in its own colour.)
local RunService = game:GetService("RunService")
local function pieceModel(kind)
	local m = Instance.new("Model"); m.Name = "Piece"
	local body = Instance.new("Part"); body.Name = "Body"; body.Anchored = true; body.CanCollide = false; body.CastShadow = false; body.Color = kind.colour
	local cf = CFrame.new()
	if kind.glass then body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.55, 0.28, 0.45); body.Material = Enum.Material.SmoothPlastic; body.Transparency = 0.08; body.Reflectance = 0.05
	elseif kind.shell == "scallop" then body.Shape = Enum.PartType.Cylinder; body.Size = Vector3.new(0.14, 0.62, 0.62); body.Material = Enum.Material.SmoothPlastic; cf = CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(-30), 0, 0)
	elseif kind.shell == "spiral" then body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.3, 0.3, 0.58); body.Material = Enum.Material.SmoothPlastic
	elseif kind.pearl then body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.5, 0.5, 0.5); body.Material = Enum.Material.SmoothPlastic; body.Reflectance = 0.3
	else body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.42, 0.26, 0.3); body.Material = Enum.Material.SmoothPlastic; body.Reflectance = 0.05 end
	body.CFrame = cf; body.Parent = m; m.PrimaryPart = body
	return m
end
local revealHolder, revealSeq = nil, 0
local function pickReveal(id, count)
	local kind = R.byId[id]
	local camNow = workspace.CurrentCamera
	if not kind or not camNow then return false end
	if revealHolder then revealHolder:Destroy(); revealHolder = nil end
	revealSeq += 1; local my = revealSeq
	local rare = kind.rare == true or kind.pearl == true
	local life = rare and 3.2 or 2.5
	local v = camNow.ViewportSize
	local size = math.floor(math.clamp(math.min(v.X, v.Y) * (rare and 0.34 or 0.27), 120, rare and 290 or 230))
	local holder = Instance.new("Frame"); holder.Name = "PickReveal"; holder.AnchorPoint = Vector2.new(0.5, 0.5); holder.Position = UDim2.fromScale(0.5, 0.4)
	holder.Size = UDim2.fromOffset(size + 120, size + 84); holder.BackgroundTransparency = 1; holder.ZIndex = 40
	local sc = Instance.new("UIScale"); sc.Scale = 0.15; sc.Parent = holder
	local vp = Instance.new("ViewportFrame"); vp.AnchorPoint = Vector2.new(0.5, 0); vp.Position = UDim2.new(0.5, 0, 0, 0); vp.Size = UDim2.fromOffset(size, size)
	vp.BackgroundColor3 = C(250, 240, 214); vp.BackgroundTransparency = 0.05; vp.ZIndex = 41; vp.Parent = holder
	vp.Ambient = C(170, 165, 160); vp.LightColor = C(255, 250, 235); vp.LightDirection = Vector3.new(-0.5, -1, -0.6)
	local vc = Instance.new("UICorner"); vc.CornerRadius = UDim.new(0.5, 0); vc.Parent = vp
	local rim = stroke(vp, GOLD, 5)
	local cam = Instance.new("Camera"); cam.FieldOfView = 30; cam.Parent = vp; vp.CurrentCamera = cam
	local m = pieceModel(kind); m.Parent = vp
	local _, sz = m:GetBoundingBox()
	local d = math.max(sz.X, sz.Y, sz.Z) * 0.5 / math.tan(math.rad(15)) * 2.6
	local name = Instance.new("TextLabel"); name.AnchorPoint = Vector2.new(0.5, 0); name.Position = UDim2.new(0.5, 0, 0, size + 8); name.Size = UDim2.new(1, 0, 0, 36)
	name.BackgroundTransparency = 1; name.FontFace = FONT; name.TextSize = rare and 34 or 30; name.TextColor3 = GOLD; name.Text = kind.name .. "!"; name.ZIndex = 42; name.Parent = holder
	local ns = Instance.new("UIStroke"); ns.Color = BROWN; ns.Thickness = 3; ns.Parent = name
	local sub = Instance.new("TextLabel"); sub.AnchorPoint = Vector2.new(0.5, 0); sub.Position = UDim2.new(0.5, 0, 0, size + 46); sub.Size = UDim2.new(1, 0, 0, 26)
	sub.BackgroundTransparency = 1; sub.FontFace = FONT; sub.TextSize = 21; sub.TextColor3 = CREAM; sub.Text = "You have " .. tostring(count); sub.ZIndex = 42; sub.Parent = holder
	local ss = Instance.new("UIStroke"); ss.Color = BROWN; ss.Thickness = 2.5; ss.Parent = sub
	local stars, n = {}, rare and 10 or 7
	for i = 1, n do                                                       -- little gold diamonds, each twinkling on its own beat
		local a = (i / n) * math.pi * 2 + 0.3
		local r = size * (0.6 + 0.08 * (i % 2))
		local s = Instance.new("Frame"); s.AnchorPoint = Vector2.new(0.5, 0.5); s.BorderSizePixel = 0; s.ZIndex = 43
		s.BackgroundColor3 = (i % 2 == 0) and C(255, 252, 228) or GOLD
		s.Position = UDim2.new(0.5, math.cos(a) * r, 0, size / 2 + math.sin(a) * r); s.Parent = holder
		local st = Instance.new("UIStroke"); st.Color = C(150, 100, 20); st.Thickness = 1.5; st.Parent = s
		table.insert(stars, {s = s, st = st, ph = i * 1.7, base = 12 + (i % 3) * 5})
	end
	local snd = Instance.new("Sound"); snd.SoundId = "rbxassetid://123582256549202"; snd.Volume = 1.2; snd.Parent = holder
	holder.Parent = gui; revealHolder = holder
	pg:SetAttribute("PromptsHidden", true)
	snd:Play()
	TweenService:Create(sc, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	local t0 = os.clock()
	local conn; conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > life or not holder.Parent then conn:Disconnect(); return end
		local ang = t * 2.2
		cam.CFrame = CFrame.lookAt(Vector3.new(math.sin(ang) * d, d * 0.42, math.cos(ang) * d), Vector3.zero)
		if t < life - 0.5 then
			for _, e in ipairs(stars) do
				local k = 0.5 + 0.5 * math.sin(t * 5 + e.ph)
				local px = e.base * (0.7 + 0.4 * k)
				e.s.Size = UDim2.fromOffset(px, px); e.s.Rotation = 45 + t * 60 + e.ph * 20; e.s.BackgroundTransparency = 0.3 * (1 - k)
			end
		end
	end)
	task.delay(life - 0.5, function()
		if not holder.Parent then return end
		local fi = TweenInfo.new(0.5)
		TweenService:Create(sc, fi, {Scale = 0.85}):Play()
		TweenService:Create(vp, fi, {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
		TweenService:Create(rim, fi, {Transparency = 1}):Play()
		for _, l in ipairs({name, sub}) do TweenService:Create(l, fi, {TextTransparency = 1}):Play() end
		TweenService:Create(ns, fi, {Transparency = 1}):Play(); TweenService:Create(ss, fi, {Transparency = 1}):Play()
		for _, e in ipairs(stars) do TweenService:Create(e.s, fi, {BackgroundTransparency = 1}):Play(); TweenService:Create(e.st, fi, {Transparency = 1}):Play() end
	end)
	task.delay(life, function()
		if revealSeq == my then pg:SetAttribute("PromptsHidden", nil); revealHolder = nil end
	end)
	Debris:AddItem(holder, life + 0.1)
	return true
end
]]
sgSrc = replaceOnce(sgSrc, "ev.OnClientEvent:Connect(function(what, a, b, c, d)", revealCode .. "ev.OnClientEvent:Connect(function(what, a, b, c, d)", "SeaGlassClient OnClientEvent")
sgSrc = replaceOnce(sgSrc,
	[[showToast(string.format("%s! You have %d.", name, count), rare and 4 or 2.5)]],
	[[local okr, shown = false, false
		if not UIS.VREnabled then okr, shown = pcall(pickReveal, a, count) end   -- the reveal on a flat screen; the toast in VR (or if it failed)
		if not (okr and shown) then showToast(string.format("%s! You have %d.", name, count), rare and 4 or 2.5) end]],
	"SeaGlassClient found toast")

-- ---------- 2. PromptClient ----------
local pc = workspace.PromptUI.PromptClient
local pcSrc = pc.Source
assert(not pcSrc:find("PromptsHidden", 1, true), "PromptClient already patched")
pcSrc = replaceOnce(pcSrc, [[or active=="book"
]], [[or active=="book" or pg:GetAttribute("PromptsHidden")==true   -- (Oct 20: a pick-up reveal is on screen)
]], "PromptClient blocked line")

-- ---------- 3. Bottles: "Expect a reply in 24 hours" ----------
local bcl, bsv = workspace.Bottles.BottleClient, workspace.Bottles.BottleServer
local bcSrc, bsSrc = bcl.Source, bsv.Source
bcSrc = replaceAll(bcSrc, "A reply will wash up here tomorrow!", "Expect a reply in 24 hours!", 2, "BottleClient out-at-sea lines")
bcSrc = replaceAll(bcSrc, "One bottle a day. A reply washes up tomorrow.", "One bottle a day. Expect a reply in 24 hours.", 1, "BottleClient status line")
bcSrc = replaceAll(bcSrc, "Off it goes! Come back to the kiosk tomorrow for a reply.", "Off it goes! Expect a reply at the kiosk in 24 hours.", 1, "BottleClient toss line")
bsSrc = replaceAll(bsSrc, "Your bottle is already out at sea. Come back to the kiosk tomorrow!", "Your bottle is already out at sea. Expect a reply in 24 hours!", 1, "BottleServer reminder")

-- ---------- backups, then write ----------
for _, pair in ipairs({{sgc, "SeaGlassClient_pre_reveal7"}, {pc, "PromptClient_pre_reveal7"}, {bcl, "BottleClient_pre_reveal7"}, {bsv, "BottleServer_pre_reveal7"}}) do
	local b = pair[1]:Clone(); b.Name = pair[2]; b.Enabled = false; b.Parent = backup
end
SES:UpdateSourceAsync(sgc, function() return sgSrc end)
SES:UpdateSourceAsync(pc, function() return pcSrc end)
SES:UpdateSourceAsync(bcl, function() return bcSrc end)
SES:UpdateSourceAsync(bsv, function() return bsSrc end)
return "reveal7 installed (SeaGlassClient, PromptClient, BottleClient, BottleServer; backups *_pre_reveal7)"
