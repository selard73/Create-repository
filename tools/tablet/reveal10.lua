-- reveal10 (Oct 20 2026): Shannon: "make it actual roblox glass material". A ViewportFrame cannot draw Glass (it comes out
-- pale silver) or light passing through anything, so the reveal's piece now floats in the REAL world, just in front of the
-- camera, centred in a gold ring on the screen (the ring has no fill: a fill would cover the piece). Real Glass, real light;
-- the shells keep their textures. Uses ReplicatedStorage.SeaGlassRevealPieces (AI-generated Oct 20; Shannon chose the
-- second glass shard and the second cowrie - this renames them to "seaglass" / "shell_cowrie" and removes the first tries).
-- The beach pieces are unchanged. Run in Studio EDIT; backs SeaGlassClient up first. No DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
local kit = game:GetService("ReplicatedStorage"):FindFirstChild("SeaGlassRevealPieces")
assert(backup and kit, "missing HudBackup or SeaGlassRevealPieces")

-- ---------- the kit: keep the chosen ones under plain names ----------
for _, pair in ipairs({{"seaglass", "seaglass_v2"}, {"shell_cowrie", "shell_cowrie_v2"}}) do
	local first, chosen = kit:FindFirstChild(pair[1]), kit:FindFirstChild(pair[2])
	if chosen then
		if first then first:Destroy() end
		chosen.Name = pair[1]
	end
end
for _, n in ipairs({"seaglass", "shell_scallop", "shell_spiral", "shell_cowrie", "pearl"}) do assert(kit:FindFirstChild(n), "kit is missing " .. n) end

-- ---------- SeaGlassClient: the reveal block ----------
local sgc = workspace.SeaGlass.SeaGlassClient
local src = sgc.Source
local startMark = "-- the pick-up reveal (Oct 20 2026"
local endMark = "ev.OnClientEvent:Connect(function(what, a, b, c, d)"
local a = src:find(startMark, 1, true)
local e = src:find(endMark, 1, true)
assert(a and e and e > a, "SeaGlassClient: reveal block not found - nothing changed")
assert(not src:find(startMark, a + 1, true), "SeaGlassClient: two reveal blocks - nothing changed")
local block = [[
-- the pick-up reveal (Oct 20 2026, Shannon: "when you pick one up can you do a pretty reveal on the screen like you do with
-- the squirrels?" ... "make it actual roblox glass material"): the piece itself floats in the REAL world just in front of
-- your view, centred in a gold ring in the middle of the screen, spinning, gold diamonds twinkling round the ring, its name
-- and how many you have; 3 s (rare ones bigger, 3.8 s), the acorn pick-up chime. Real 3D, not a ViewportFrame (which cannot
-- draw Glass or light through it), so the sea glass is real Glass and the shells keep their textures - the models are in
-- ReplicatedStorage.SeaGlassRevealPieces (made Oct 20; the beach pieces are unchanged). Flat screens (VR keeps the toast).
-- While it shows, the prompt buttons step aside (PlayerGui attribute PromptsHidden, read by PromptClient).
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local revealKit = RS:FindFirstChild("SeaGlassRevealPieces")
local function primitive(kind)                                          -- (only if the kit is missing)
	local m = Instance.new("Model"); m.Name = "Piece"
	local body = Instance.new("Part"); body.Name = "Body"; body.Color = kind.colour; body.Shape = Enum.PartType.Ball
	body.Size = kind.glass and Vector3.new(0.55, 0.28, 0.45) or Vector3.new(0.45, 0.3, 0.4); body.Material = Enum.Material.SmoothPlastic
	body.Parent = m; m.PrimaryPart = body
	return m
end
local function revealModel(kind)
	local src = revealKit and revealKit:FindFirstChild(kind.glass and "seaglass" or kind.id)
	local m = src and src:Clone() or primitive(kind)
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false; d.CastShadow = false end
		if kind.glass then
			if d:IsA("SurfaceAppearance") then d:Destroy() end
			if d:IsA("MeshPart") then d.TextureID = "" end
			if d:IsA("BasePart") then d.Color = kind.colour; d.Material = Enum.Material.Glass; d.Transparency = 0.4; d.Reflectance = 0.1 end
		end
	end
	local cf = m:GetBoundingBox()
	m.WorldPivot = cf                                                    -- (spin about its own middle)
	return m
end
local revealHolder, revealPiece, revealSeq = nil, nil, 0
local function pickReveal(id, count)
	local kind = R.byId[id]
	local camNow = workspace.CurrentCamera
	if not kind or not camNow then return false end
	if revealHolder then revealHolder:Destroy(); revealHolder = nil end
	if revealPiece then revealPiece:Destroy(); revealPiece = nil end
	revealSeq += 1; local my = revealSeq
	local rare = kind.rare == true or kind.pearl == true
	local life = rare and 3.8 or 3.0
	local v = camNow.ViewportSize
	local size = math.floor(math.clamp(math.min(v.X, v.Y) * (rare and 0.34 or 0.27), 120, rare and 290 or 230))
	local holder = Instance.new("Frame"); holder.Name = "PickReveal"; holder.AnchorPoint = Vector2.new(0.5, 0.5); holder.Position = UDim2.fromScale(0.5, 0.4)
	holder.Size = UDim2.fromOffset(size + 120, size + 84); holder.BackgroundTransparency = 1; holder.ZIndex = 40
	local sc = Instance.new("UIScale"); sc.Scale = 0.15; sc.Parent = holder
	local ring = Instance.new("Frame"); ring.Name = "Ring"; ring.AnchorPoint = Vector2.new(0.5, 0); ring.Position = UDim2.new(0.5, 0, 0, 0); ring.Size = UDim2.fromOffset(size, size)
	ring.BackgroundTransparency = 1; ring.ZIndex = 41; ring.Parent = holder
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0.5, 0); rc.Parent = ring
	local rim = stroke(ring, GOLD, 5)
	local name = Instance.new("TextLabel"); name.AnchorPoint = Vector2.new(0.5, 0); name.Position = UDim2.new(0.5, 0, 0, size + 8); name.Size = UDim2.new(1, 0, 0, 36)
	name.BackgroundTransparency = 1; name.FontFace = FONT; name.TextSize = rare and 34 or 30; name.TextColor3 = GOLD; name.Text = kind.name .. "!"; name.ZIndex = 42; name.Parent = holder
	local ns = Instance.new("UIStroke"); ns.Color = BROWN; ns.Thickness = 3; ns.Parent = name
	local sub = Instance.new("TextLabel"); sub.AnchorPoint = Vector2.new(0.5, 0); sub.Position = UDim2.new(0.5, 0, 0, size + 46); sub.Size = UDim2.new(1, 0, 0, 26)
	sub.BackgroundTransparency = 1; sub.FontFace = FONT; sub.TextSize = 21; sub.TextColor3 = CREAM; sub.Text = "You have " .. tostring(count); sub.ZIndex = 42; sub.Parent = holder
	local ss = Instance.new("UIStroke"); ss.Color = BROWN; ss.Thickness = 2.5; ss.Parent = sub
	local stars, n = {}, rare and 10 or 7
	for i = 1, n do                                                       -- little gold diamonds on the top and sides of the ring
		local ang = math.rad(160 + (i - 1) * 220 / math.max(1, n - 1))
		local r = size * (0.6 + 0.08 * (i % 2))
		local s = Instance.new("Frame"); s.AnchorPoint = Vector2.new(0.5, 0.5); s.BorderSizePixel = 0; s.ZIndex = 43
		s.BackgroundColor3 = (i % 2 == 0) and C(255, 252, 228) or GOLD
		s.Position = UDim2.new(0.5, math.cos(ang) * r, 0, size / 2 + math.sin(ang) * r); s.Parent = holder
		local st = Instance.new("UIStroke"); st.Color = C(150, 100, 20); st.Thickness = 1.5; st.Parent = s
		table.insert(stars, {s = s, st = st, ph = i * 1.7, base = 12 + (i % 3) * 5})
	end
	-- the piece, in the world just in front of the camera (under the camera: only this player sees it)
	local m = revealModel(kind)
	local _, ext = m:GetBoundingBox()
	local E = math.max(ext.X, ext.Y, ext.Z)
	local parts = {}
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, {p = d, t = d.Transparency}) end end
	local light = Instance.new("PointLight"); light.Brightness = 1.2; light.Range = 6; light.Shadows = false; light.Color = C(255, 248, 230)
	light.Parent = m:FindFirstChildWhichIsA("BasePart", true)
	m.Parent = camNow
	local snd = Instance.new("Sound"); snd.SoundId = "rbxassetid://123582256549202"; snd.Volume = 1.2; snd.Parent = holder
	holder.Parent = gui; revealHolder = holder; revealPiece = m
	pg:SetAttribute("PromptsHidden", true)
	snd:Play()
	TweenService:Create(sc, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	local t0 = os.clock()
	local conn; conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > life or not holder.Parent or not m.Parent then conn:Disconnect(); return end
		local cam = workspace.CurrentCamera
		local px = ring.AbsoluteSize.Y                                   -- (the ring's size on screen, pop included)
		if cam and px >= 4 then
			local centre = ring.AbsolutePosition + GuiService:GetGuiInset() + ring.AbsoluteSize / 2
			local ray = cam:ViewportPointToRay(centre.X, centre.Y)
			local dist = E / (0.62 * px / cam.ViewportSize.Y * 2 * math.tan(math.rad(cam.FieldOfView) / 2))   -- fills ~62 % of the ring
			m:PivotTo(CFrame.new(ray.Origin + ray.Direction * dist) * cam.CFrame.Rotation * CFrame.Angles(math.rad(35), 0, 0) * CFrame.Angles(0, t * 2.2, 0))
		end
		if t < life - 0.5 then
			for _, e in ipairs(stars) do
				local k = 0.5 + 0.5 * math.sin(t * 5 + e.ph)
				local spx = e.base * (0.7 + 0.4 * k)
				e.s.Size = UDim2.fromOffset(spx, spx); e.s.Rotation = 45 + t * 60 + e.ph * 20; e.s.BackgroundTransparency = 0.3 * (1 - k)
			end
		else
			local f = math.clamp((t - (life - 0.5)) / 0.5, 0, 1)
			for _, q in ipairs(parts) do q.p.Transparency = q.t + (1 - q.t) * f end
			light.Brightness = 1.2 * (1 - f)
		end
	end)
	task.delay(life - 0.5, function()
		if not holder.Parent then return end
		local fi = TweenInfo.new(0.5)
		TweenService:Create(sc, fi, {Scale = 0.85}):Play()
		TweenService:Create(rim, fi, {Transparency = 1}):Play()
		for _, l in ipairs({name, sub}) do TweenService:Create(l, fi, {TextTransparency = 1}):Play() end
		TweenService:Create(ns, fi, {Transparency = 1}):Play(); TweenService:Create(ss, fi, {Transparency = 1}):Play()
		for _, e in ipairs(stars) do TweenService:Create(e.s, fi, {BackgroundTransparency = 1}):Play(); TweenService:Create(e.st, fi, {Transparency = 1}):Play() end
	end)
	task.delay(life, function()
		if revealSeq == my then pg:SetAttribute("PromptsHidden", nil); revealHolder = nil; revealPiece = nil end
	end)
	Debris:AddItem(holder, life + 0.1); Debris:AddItem(m, life + 0.1)
	return true
end
]]
local newSrc = src:sub(1, a - 1) .. block .. src:sub(e)
local bk = sgc:Clone(); bk.Name = "SeaGlassClient_pre_reveal10"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(sgc, function() return newSrc end)
return "reveal10 installed; kit: " .. #kit:GetChildren() .. " models"
