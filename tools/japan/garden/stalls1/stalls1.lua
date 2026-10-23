-- stalls1.lua (Oct 22 2026): Shannon on the market stalls: "put the taiyaki stall to the left of the mochi stall and add another
-- stall on the right of the shaved ice stall ... make it look like a shaved ice stall, right now it looks like dimsum or hotpot or
-- grilled meat". Kit japan_kit38_stalls3.fbx (stalls1/gen_stalls3.py; v3 after her verdict on v2 "toddler plastic toys": the ice,
-- cups and takoyaki are sculpted, noise-roughened meshes with baked colour/roughness/normal textures (SurfaceAppearance); her
-- photos: cups on trays with spoons, mini 氷 flags, the rainbow bear; her reference stall: blue wave noren with 氷, a blue かき氷
-- banner - NOT the giant bowl on the roof, NOT the carp streamer): kakigori_a, kakigori_b, kori_flag, takoyaki_a, takoyaki_b.
--  1. a loose import of the kit is anchored into ServerStorage.JapanGardenKit
--  2. the Taiyaki stall turns to face the way the Mochi stall faces and moves beside it (customer's left = west), fronts in line,
--     2.5 studs between them; its old pivot is kept in Stalls1WasPivot
--  3. a copy of the Taiyaki stall becomes the Takoyaki stall, next along the row (left of the taiyaki), signs たこ焼き Takoyaki
--     stall, its taiyaki goods replaced by the takoyaki pan + boats
--  4. the Shaved ice stall's two "Food display" models (the dim-sum look) move to HudBackup.Stalls1Originals; the kakigori sets
--     take their spots on the counter; the 氷 flag stands at the counter's end
-- Guarded by JapanMap attribute Stalls1. Output "QQ STALLS1".
local SS = game:GetService("ServerStorage")
local J = workspace:FindFirstChild("JapanMap")
local mk = J and J:FindFirstChild("Outdoor market revision")
local KIT = SS:FindFirstChild("JapanGardenKit")
local hb = SS:FindFirstChild("HudBackup")
if not (mk and KIT and hb) then return "QQ STALLS1 ABORT: market, JapanGardenKit or HudBackup missing" end
if J:GetAttribute("Stalls1") then return "QQ STALLS1 already installed (" .. tostring(J:GetAttribute("Stalls1")) .. ") - nothing done" end
local out = {}
local function say(s) table.insert(out, "QQ STALLS1 " .. s) end
local function key(p) return (p.Name:gsub("%.%d+$", "")) end
local function find(m, name) for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") and key(d) == name then return d end end end
local PIECES = {"kakigori_a", "kakigori_b", "kori_flag", "takoyaki_a", "takoyaki_b"}
-- 1. adopt a loose import
local function findLoose(name)
	for _, top in ipairs(workspace:GetChildren()) do
		if top:IsA("Model") and top ~= J then
			if top.Name == name then return top end
			local m = top:FindFirstChild(name, true)
			if m and m:IsA("Model") then return m, top end
		end
	end
end
for _, n in ipairs(PIECES) do
	if not KIT:FindFirstChild(n) then
		local m, wrapper = findLoose(n)
		if not m then return "QQ STALLS1 ABORT: no '" .. n .. "' in JapanGardenKit or workspace - import japan_kit38_stalls3.fbx first" end
		if n == "kakigori_b" and not find(m, "KG_MoundBlue") then return "QQ STALLS1 ABORT: that is an OLD kit (no textured mounds) - delete it and import japan_kit38_stalls3.fbx" end
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
		m.Parent = KIT
		if wrapper and #wrapper:GetDescendants() == 0 then wrapper:Destroy() end
		say("kit: " .. n .. " anchored and stored")
	end
end
local shaved, taiyaki, mochi = mk:FindFirstChild("Shaved ice stall"), mk:FindFirstChild("Taiyaki stall"), mk:FindFirstChild("Mochi stall")
if not (shaved and taiyaki and mochi) then return "QQ STALLS1 ABORT: a stall is missing" end
if mk:FindFirstChild("Takoyaki stall") then return "QQ STALLS1 ABORT: Takoyaki stall already exists" end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before stalls1") end)
local bk = hb:FindFirstChild("Stalls1Originals") or Instance.new("Folder"); bk.Name = "Stalls1Originals"; bk.Parent = hb

-- geometry helpers
local function flat(v) return Vector3.new(v.X, 0, v.Z).Unit end
local function halfAlong(p, n)
	local cf, s = p.CFrame, p.Size
	return (math.abs(cf.RightVector:Dot(n)) * s.X + math.abs(cf.UpVector:Dot(n)) * s.Y + math.abs(cf.LookVector:Dot(n)) * s.Z) / 2
end
local function extent(model, origin, n)                           -- min/max of the model's parts along n, relative to origin
	local lo, hi = math.huge, -math.huge
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			local c = (p.Position - origin):Dot(n); local h = halfAlong(p, n)
			lo = math.min(lo, c - h); hi = math.max(hi, c + h)
		end
	end
	return lo, hi
end
local GAP = 2.5
local mp = mochi:GetPivot()
local look, right = flat(mp.LookVector), flat(mp.RightVector)        -- the stall faces `look` (the customer side); `right` = the customer's left
local R = CFrame.lookAt(Vector3.zero, look).Rotation
local _, mFront = extent(mochi, mp.Position, look)
local _, mRight = extent(mochi, mp.Position, right)

-- 2. taiyaki beside mochi
local tp0 = taiyaki:GetPivot()
taiyaki:SetAttribute("Stalls1WasPivot", tp0)
local keep = taiyaki:Clone(); keep.Name = "TaiyakiStall_pre_stalls1"; keep.Parent = bk
taiyaki:PivotTo(CFrame.new(tp0.Position) * R)                     -- turned in place to face as the mochi does
local tp = taiyaki:GetPivot()
local _, tFront = extent(taiyaki, tp.Position, look)
local tLo, tHi = extent(taiyaki, tp.Position, right)
local pos = tp.Position + look * (mFront - tFront) + right * ((mp.Position - tp.Position):Dot(right) + mRight + GAP - tLo)
taiyaki:PivotTo(CFrame.new(pos) * R)
local tp1 = taiyaki:GetPivot()
say(string.format("Taiyaki stall: turned %.0f deg to face as the Mochi stall, moved to (%.1f, %.1f) beside it (fronts in line, gap %.1f)",
	math.deg(math.atan2(look:Cross(flat(tp0.LookVector)).Y, look:Dot(flat(tp0.LookVector)))), tp1.X, tp1.Z, GAP))

-- 3. the takoyaki stall: a copy, next along the row
local tako = taiyaki:Clone()
tako.Name = "Takoyaki stall"
tako:SetAttribute("Stalls1WasPivot", nil)
tako:SetAttribute("Stalls1Added", true)
tako:PivotTo(CFrame.new(tp1.Position + right * (tHi - tLo + GAP)) * R)   -- moved BEFORE the goods spots are read (first run had them on the taiyaki's counter)
local spots = {}
for _, c in ipairs(tako:GetChildren()) do
	if c:IsA("Model") and c.Name == "Food display" then
		local cf, sz = c:GetBoundingBox()
		table.insert(spots, Vector3.new(cf.X, cf.Y - sz.Y / 2, cf.Z))
		c:Destroy()
	end
end
local relabel = 0
for _, d in ipairs(tako:GetDescendants()) do
	if d:IsA("TextLabel") then
		local t = d.Text
		t = t:gsub("たい焼き", "たこ焼き"):gsub("Taiyaki", "Takoyaki")
		if t ~= d.Text then d.Text = t; relabel += 1 end
	end
end
tako.Parent = mk
local kp = tako:GetPivot()
say(string.format("Takoyaki stall: a copy of the Taiyaki stall at (%.1f, %.1f), %d sign labels renamed, %d goods spots freed", kp.X, kp.Z, relabel, #spots))

-- 4. dress the counters
local C = Color3.fromRGB
local SP, GL, MET, WD = Enum.Material.SmoothPlastic, Enum.Material.Glass, Enum.Material.Metal, Enum.Material.Wood
local LOOK = {
	KG_Iron = {MET, C(40, 42, 46)}, KG_Enamel = {SP, C(238, 230, 210)}, KG_Chrome = {MET, C(200, 204, 210)}, KG_Wood = {WD, C(140, 102, 64)},
	KG_Tray = {MET, C(178, 184, 189)}, KG_Ice = {GL, C(214, 236, 250), 0.25}, KG_Glass = {GL, C(220, 236, 245), 0.45}, KG_Snow = {SP, C(252, 252, 255)},
	KG_SyrupRed = {SP, C(220, 30, 46)}, KG_SyrupGreen = {SP, C(76, 184, 64)}, KG_SyrupBlue = {SP, C(46, 140, 230)}, KG_SyrupYellow = {SP, C(250, 209, 51)},
	KG_Orange = {SP, C(250, 140, 38)}, KG_Pink = {SP, C(242, 140, 166)}, KG_Knob = {SP, C(191, 38, 31)}, KG_FlagPole = {WD, C(64, 51, 41)},
	KG_FlagCloth = {SP, C(41, 97, 191)}, KG_Cup = {SP, C(245, 240, 224)}, KG_CupStripe = {SP, C(46, 115, 204)}, KG_Cookie = {SP, C(199, 140, 71)},
	KG_Choco = {SP, C(56, 31, 20)}, KG_MiniStick = {WD, C(217, 191, 140)}, KG_MiniFlag1 = {SP, C(250, 250, 250)}, KG_MiniFlag2 = {SP, C(250, 250, 250)},
	KG_Cream = {SP, C(252, 250, 242)}, KG_Straw = {SP, C(242, 140, 166)},
	TK_IronDark = {MET, C(51, 51, 54)}, TK_Iron = {MET, C(26, 26, 28)}, TK_Ball = {SP, C(219, 158, 71)}, TK_Sauce = {GL, C(77, 41, 20)},
	TK_Mayo = {SP, C(250, 245, 224)}, TK_Nori = {SP, C(36, 71, 31)}, TK_Bonito = {SP, C(204, 158, 115)}, TK_Paper = {SP, C(242, 230, 199)},
	TK_Chrome = {MET, C(200, 204, 210)}, TK_SauceBottle = {SP, C(89, 51, 26)}, TK_MayoBottle = {SP, C(245, 242, 230)}, TK_RedCap = {SP, C(204, 31, 26)},
	TK_YellowCap = {SP, C(242, 191, 38)}, TK_Glass = {GL, C(220, 236, 245), 0.45}, TK_Bamboo = {WD, C(204, 178, 115)}, TK_Pick = {SP, C(224, 204, 153)},
}
local unknown = {}
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = true
			if p:IsA("MeshPart") then p.DoubleSided = false end
			if p:FindFirstChildWhichIsA("SurfaceAppearance") or (p:IsA("MeshPart") and p.TextureID ~= "") then   -- v3: baked textures
				p.Material = Enum.Material.Plastic; p.Color = C(255, 255, 255); p.Transparency = 0
			else
				local d = LOOK[key(p)]
				if not d then unknown[key(p)] = true; d = {SP, C(200, 200, 200)} end
				p.Material = d[1]; p.Color = d[2]; p.Transparency = d[3] or 0
			end
		end
	end
end
-- the kit may come in turned 180 (the vending kit did): each set names a mesh that must sit on the vendor's (back) or customer's side
local SIDE = {kakigori_a = {"KG_Enamel", -1}, kakigori_b = {"KG_Choco", 1}, takoyaki_a = {"TK_Bamboo", 1}, takoyaki_b = {"TK_Glass", -1}}
local function thinFaces(p)
	local s = p.Size
	if s.Z <= s.X and s.Z <= s.Y then return Enum.NormalId.Front, Enum.NormalId.Back
	elseif s.X <= s.Y then return Enum.NormalId.Right, Enum.NormalId.Left else return Enum.NormalId.Top, Enum.NormalId.Bottom end
end
local function wave(parent, y0, h, bandColour, dotColour)                -- a band with half-circles along its top edge
	local band = Instance.new("Frame"); band.Position = UDim2.fromScale(0, y0); band.Size = UDim2.fromScale(1, h); band.BackgroundColor3 = bandColour; band.BorderSizePixel = 0; band.Parent = parent
	for i = 0, 3 do
		local w = Instance.new("Frame"); w.AnchorPoint = Vector2.new(0.5, 0.5); w.Position = UDim2.fromScale(0.125 + i * 0.25, 0); w.Size = UDim2.fromScale(0.28, 0.5)
		w.BackgroundColor3 = dotColour; w.BorderSizePixel = 0; w.Parent = band
		local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(1, 0); cr.Parent = w
	end
	return band
end
local function koriLabel(parent, text, colour, pos, size, stroke)
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Position = pos; t.Size = size
	t.Font = Enum.Font.Garamond; t.TextScaled = true; t.TextColor3 = colour; t.Text = text; t.Parent = parent
	if stroke then local u = Instance.new("UIStroke"); u.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; u.Color = stroke; u.Thickness = 2; u.Parent = t end
	return t
end
local function koriCard(part, pps)                                       -- a white card: red 氷 over a blue wave (both thin faces)
	local a, b = thinFaces(part)
	for _, face in ipairs({a, b}) do
		local sg = Instance.new("SurfaceGui"); sg.Name = "Kori" .. face.Name; sg.Face = face
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = pps; sg.LightInfluence = 0.8; sg.Parent = part
		local bg = Instance.new("Frame"); bg.Size = UDim2.fromScale(1, 1); bg.BackgroundColor3 = C(250, 250, 247); bg.BorderSizePixel = 0; bg.Parent = sg
		wave(bg, 0.78, 0.22, C(38, 97, 191), C(250, 250, 247))
		koriLabel(bg, "氷", C(204, 31, 26), UDim2.fromScale(0.08, 0.06), UDim2.fromScale(0.84, 0.68))
	end
end
local function placeSet(name, base, facing, parent)
	local m = KIT[name]:Clone(); m.Name = name
	dress(m)
	m.WorldPivot = CFrame.new(m:GetPivot().Position)
	local cf, sz = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position.X, cf.Position.Y - sz.Y / 2, cf.Position.Z)
	m:PivotTo(CFrame.lookAt(base, base + facing))
	local s = SIDE[name]
	if s then
		local marker = find(m, s[1])
		local c2 = m:GetBoundingBox()
		if marker and ((marker.Position - c2.Position):Dot(facing) * s[2] < 0) then
			m:PivotTo(CFrame.lookAt(base, base - facing))
		end
	end
	m:SetAttribute("Stalls1Set", true)
	m.Parent = parent
	return m
end
local function counterTop(stall)
	local c = stall:FindFirstChild("Service counter")
	return c.Position.Y + c.Size.Y / 2
end
-- shaved ice: old goods out, kakigori in
local sLook = flat(shaved:GetPivot().LookVector)
local sTop = counterTop(shaved)
local sSpots = {}
for _, c in ipairs(shaved:GetChildren()) do
	if c:IsA("Model") and c.Name == "Food display" then
		local cf = c:GetBoundingBox()
		table.insert(sSpots, Vector3.new(cf.X, sTop, cf.Z))
		c:SetAttribute("Stalls1From", c:GetFullName()); c.Name = "ShavedIce_FoodDisplay_pre_stalls1"; c.Parent = bk
	end
end
assert(#sSpots == 2, "shaved ice stall: expected 2 Food display models, found " .. #sSpots)
placeSet("kakigori_a", sSpots[1], sLook, shaved)
local kb = placeSet("kakigori_b", sSpots[2], sLook, shaved)
for _, p in ipairs(kb:GetDescendants()) do
	if p:IsA("BasePart") and key(p):match("^KG_MiniFlag") then koriCard(p, 400) end
end
say("Shaved ice stall: 2 old food displays moved to HudBackup.Stalls1Originals; kakigori shaver / ice / syrups / straws + striped cups, the blue one, the rainbow bear and the strawberry one on the counter")
-- the noren curtains along the awning: blue with a white wave, a red 氷 on every other one (her reference)
do
	local n = 0
	for _, p in ipairs(shaved:GetDescendants()) do
		if p:IsA("BasePart") and p.Name == "Separate noren curtain" then
			n += 1
			if p:GetAttribute("Stalls1WasColor") == nil then p:SetAttribute("Stalls1WasColor", p.Color) end
			p.Color = C(41, 97, 191)
			local a, b = thinFaces(p)
			for _, face in ipairs({a, b}) do
				local sg = Instance.new("SurfaceGui"); sg.Name = "Noren" .. face.Name; sg.Face = face
				sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 80; sg.LightInfluence = 0.8; sg.Parent = p
				local bg = Instance.new("Frame"); bg.Size = UDim2.fromScale(1, 1); bg.BackgroundTransparency = 1; bg.Parent = sg
				wave(bg, 0.7, 0.3, C(250, 250, 247), C(41, 97, 191))
				if n % 2 == 1 then koriLabel(bg, "氷", C(204, 31, 26), UDim2.fromScale(0.15, 0.04), UDim2.fromScale(0.7, 0.6), C(250, 250, 247)) end
			end
		end
	end
	say(n .. " noren curtains on the awning now blue with a white wave, 氷 on every other one")
end
-- the 氷 flag at the counter's end, on the ground
do
	local deck = shaved:FindFirstChild("Stall deck")
	local sRight = flat(shaved:GetPivot().RightVector)
	local dLo, dHi = extent(shaved, deck.Position, sRight)
	local fx = deck.Position + sLook * 5.0 + sRight * (dHi + 1.0)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {KIT}
	local h = workspace:Raycast(Vector3.new(fx.X, 20, fx.Z), Vector3.new(0, -40, 0), rp)
	local gy = h and h.Position.Y or 0.3
	local flag = placeSet("kori_flag", Vector3.new(fx.X, gy, fx.Z), sLook, shaved)
	local cloth = find(flag, "KG_FlagCloth")
	cloth.CanCollide = false
	local a, b = thinFaces(cloth)
	for _, face in ipairs({a, b}) do                                  -- her reference banner: blue, white かき氷 down it, a white wave at the foot
		local sg = Instance.new("SurfaceGui"); sg.Name = "Kori" .. face.Name; sg.Face = face
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 60; sg.LightInfluence = 0.8; sg.Parent = cloth
		local bg = Instance.new("Frame"); bg.Size = UDim2.fromScale(1, 1); bg.BackgroundTransparency = 1; bg.Parent = sg
		wave(bg, 0.84, 0.16, C(250, 250, 247), C(41, 97, 191))
		koriLabel(bg, "か\nき\n氷", C(250, 250, 247), UDim2.fromScale(0.1, 0.04), UDim2.fromScale(0.8, 0.76))
	end
	say(string.format("かき氷 banner at (%.1f, %.1f) on the ground by the counter's end", fx.X, fx.Z))
end
-- takoyaki: its sets where the taiyaki goods were
local kTop = counterTop(tako)
placeSet("takoyaki_a", Vector3.new(spots[1].X, kTop, spots[1].Z), look, tako)
placeSet("takoyaki_b", Vector3.new(spots[2].X, kTop, spots[2].Z), look, tako)
say("Takoyaki stall: pan on its burner, bottles, bonito jar, picks + three boats of takoyaki on the counter")

-- overlaps: what the moved / new stalls run into (the ground they stand on excepted)
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {taiyaki, tako, shaved, KIT, workspace.Terrain}
local hit = {}
for _, m in ipairs({taiyaki, tako}) do
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			for _, q in ipairs(workspace:GetPartsInPart(p, op)) do
				if q.Transparency < 0.95 and q.Position.Y + q.Size.Y / 2 > 0.6 then hit[q.Parent.Name .. "/" .. q.Name] = true end
			end
		end
	end
end
local hits = {}; for k in pairs(hit) do table.insert(hits, k) end
local unk = {}; for k in pairs(unknown) do table.insert(unk, k) end
if #unk > 0 then say("UNKNOWN mesh names (grey): " .. table.concat(unk, ", ")) end
say(#hits > 0 and ("OVERLAPS " .. table.concat(hits, " | ")) or "no overlaps with anything else")
J:SetAttribute("Stalls1", "2026-10-22")
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after stalls1") end)
say("DONE - EDIT INSTALLED; NOT PUBLISHED")
return table.concat(out, "\n")
