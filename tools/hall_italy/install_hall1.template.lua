-- install_hall1.lua (Studio EDIT mode; re-runnable; its body also runs as a play-test PREVIEW on the test server). Job 94:
-- the Belvedere dei Guardiani - the Italian Hall of Fame on the Prato dei Fiori, every Guardian of the Harbour of Porto
-- Nocciola in marble with the harbour key, standing together in a crescent above the sea (Shannon, Oct 14 2026: "make this
-- hall of fame look distinctively different from the one in France"; site E). workspace.HallOfGuardians: Belvedere (a round
-- mosaic terrace, a low parapet with a majolica band, the centre column with the gold key, two lanterns, the lectern with the
-- roll of the Guardians, the trees and benches cloned from Porto's own), HallServer (@@SERVER_LEN@@ chars: pedestals and statues from
-- the Guardian list at run time). Undo: delete workspace.HallOfGuardians (an older one is HudBackup.HallOfGuardians_pre_n).
-- No DataStore, no publish. Output lines start with "QQ BELV".
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CX, CZ, YAW = @@CX@@, @@CZ@@, math.rad(@@YAW@@)              -- the terrace's centre; yaw 0 = the front faces north (-z)
local SERVER = [===[
@@SERVER@@]===]
do   -- the compile check, where loadstring can run (a Script has none and the call itself throws): the sources are compiled with the luau CLI before every push
	local ok, f, err = pcall(function() return loadstring(SERVER) end)
	if ok and not f then print("QQ BELV ABORT: HallServer does not compile: " .. tostring(err)) return end
end
local CH = workspace:FindFirstChild("Champion")
if not (CH and CH:FindFirstChild("ChampionServer")) then print("QQ BELV ABORT: workspace.Champion.ChampionServer not found (it makes the statues)") return end
if not workspace:FindFirstChild("PortoKeeper") then print("QQ BELV ABORT: workspace.PortoKeeper not found (it keeps the Guardian list)") return end
local C = Color3.fromRGB
local STONE, TRIM, MAJOLICA, TERRA, GOLD, GOLD_D, GOLD_DD, CREAM, IRON = C(232, 226, 210), C(240, 236, 226), C(52, 110, 150), C(178, 92, 62), C(255, 206, 64), C(214, 160, 44), C(190, 136, 40), C(250, 244, 228), C(52, 50, 48)
local MOSAIC, SEA = C(222, 212, 190), C(78, 150, 186)
local RT = 17                                                          -- the terrace's radius

-- ---------------------------------------------------------------- the ground ----
local F = Instance.new("Folder"); F.Name = "HallOfGuardians"
local old = workspace:FindFirstChild("HallOfGuardians")
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Exclude; rpT.FilterDescendantsInstances = {F, old}
local function groundAt(x, z)                                        -- the first visible thing under the sky (invisible volumes skipped), never water
	local from = Vector3.new(x, 300, z)
	for _ = 1, 6 do
		local h = workspace:Raycast(from, Vector3.new(0, -600, 0), rpT)
		if not h then return nil end
		if h.Instance == workspace.Terrain then
			if h.Material == Enum.Material.Water then return nil end
			return h.Position.Y, h.Instance
		end
		if h.Instance.Transparency < 1 then return h.Position.Y, h.Instance end
		from = h.Position - Vector3.new(0, 0.05, 0)
	end
	return nil
end
local rpTerr = RaycastParams.new(); rpTerr.FilterType = Enum.RaycastFilterType.Include; rpTerr.FilterDescendantsInstances = {workspace.Terrain}
local samples, lowest, highest = {}, math.huge, -math.huge
local centreY = groundAt(CX, CZ)
for i = 0, 11 do
	local a = i * math.pi / 6
	local y = groundAt(CX + 17.5 * math.sin(a), CZ + 17.5 * math.cos(a))
	if y then table.insert(samples, y); lowest = math.min(lowest, y); highest = math.max(highest, y) end
end
if not centreY or #samples < 10 then print("QQ BELV ABORT: no ground under the terrace's rim (water or nothing at the centre or round it); nothing built") return end
if highest - lowest > 3 then print(string.format("QQ BELV ABORT: the ground rises %.1f studs across the terrace (edges %.1f..%.1f); too steep for one floor; nothing built", highest - lowest, lowest, highest)) return end
-- what stands round the terrace (r 19 and 21): anything more than a stud above the terrain there is reported
local standing = {}
for _, r in ipairs({19, 21}) do
	for i = 0, 23 do
		local a = i * math.pi / 12
		local x, z = CX + r * math.sin(a), CZ + r * math.cos(a)
		local y, inst = groundAt(x, z)
		local t = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpTerr)
		if y and inst and inst ~= workspace.Terrain and t and y > t.Position.Y + 1 then
			local top = inst; while top.Parent and top.Parent ~= workspace do top = top.Parent end
			standing[top.Name] = (standing[top.Name] or 0) + 1
		end
	end
end
local g = math.max(centreY, highest - 0.5) - 0.1                      -- the floor's base: its top never below the highest edge; the skirt covers the downhill side
local BASE = CFrame.new(CX, g, CZ) * CFrame.Angles(0, YAW, 0)
local function at(x, y, z) return BASE * CFrame.new(x, y, z) end
-- what stands INSIDE the footprint (r up to RT + 3.5, the step and the entrance trees included): a BIG thing (a tree, a wall,
-- a path slab, a bench: a box over 4 studs across or 3 tall) means this is the wrong spot - abort with its name; small props
-- (flowers, grass) under the terrace or the step are set aside into ServerStorage.HudBackup.HallOfGuardians_props_n with
-- their places kept (undo: move them back). Distances are measured to each part's OWN box (its rotation respected), so a long
-- handrail forty studs away does not count.
local function distXZ(d)
	local lp = d.CFrame:PointToObjectSpace(Vector3.new(CX, d.Position.Y, CZ))
	local h = d.Size / 2
	local cp = d.CFrame:PointToWorldSpace(Vector3.new(math.clamp(lp.X, -h.X, h.X), math.clamp(lp.Y, -h.Y, h.Y), math.clamp(lp.Z, -h.Z, h.Z)))
	local dx, dz = cp.X - CX, cp.Z - CZ
	return math.sqrt(dx * dx + dz * dz)
end
local countCache = {}
local function partCount(m)
	local n = countCache[m]
	if n == nil then
		n = 0
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then n += 1; if n > 150 then break end end end
		countCache[m] = n
	end
	return n
end
local function thingOf(p)
	local m = p.Parent
	while m and m ~= workspace do
		if m:IsA("Model") and partCount(m) <= 150 then return m end
		m = m.Parent
	end
	return p
end
local function boxOf(parts)
	local lo, hi = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, p in ipairs(parts) do
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
			local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
		end end end
	end
	return lo, hi
end
local inside = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d ~= workspace.Terrain and d.Transparency < 1 and not d:IsDescendantOf(F) and not (old and d:IsDescendantOf(old)) then
		local p = d.Position
		if distXZ(d) <= RT + 3.5 then
			local t = workspace:Raycast(Vector3.new(p.X, 300, p.Z), Vector3.new(0, -600, 0), rpTerr)
			if p.Y + d.Size.Y / 2 > (t and t.Position.Y or -1e9) + 0.5 then
				local th = thingOf(d)
				inside[th] = inside[th] or {}
				table.insert(inside[th], d)
			end
		end
	end
end
local bigs, props = {}, {}
for th, parts in pairs(inside) do
	local lo, hi = boxOf(parts)
	if hi.X - lo.X > 4 or hi.Z - lo.Z > 4 or hi.Y - lo.Y > 3 then
		local nearest = math.huge
		for _, d in ipairs(parts) do nearest = math.min(nearest, distXZ(d)) end
		table.insert(bigs, th.Name .. string.format(" (x %.0f..%.0f z %.0f..%.0f, %.1f studs from the centre)", lo.X, hi.X, lo.Z, hi.Z, nearest))
	else
		-- parked only when it stands under the terrace itself or under the step
		local under = false
		for _, d in ipairs(parts) do
			local l = BASE:PointToObjectSpace(d.Position)
			if distXZ(d) <= RT + 0.6 or (math.abs(l.X) <= 6.3 and l.Z <= -(RT + 0.5) and l.Z >= -(RT + 3.6)) then under = true break end
		end
		if under then table.insert(props, th) end
	end
end
if #bigs > 0 then table.sort(bigs); print("QQ BELV ABORT: standing inside the terrace's footprint at (" .. CX .. ", " .. CZ .. "): " .. table.concat(bigs, "; ") .. "; pick another centre; nothing built") return end
local function part(name, size, cf, colour, material, parent, shape, collide)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = (collide ~= false)
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local function disc(name, radius, thick, y, colour, material, parent, collide)        -- a flat round slab, its axis upright
	return part(name, Vector3.new(thick, radius * 2, radius * 2), at(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), colour, material, parent, Enum.PartType.Cylinder, collide)
end
local belv = Instance.new("Model"); belv.Name = "Belvedere"; belv.Parent = F

-- ---------------------------------------------------------------- the terrace ----
-- (RT, the terrace's radius, is set at the top)
disc("Skirt", RT + 0.2, 3.0, -1.5, STONE, Enum.Material.Limestone, belv)
disc("Rim", RT + 0.5, 0.3, 0.15, TERRA, Enum.Material.Slate, belv)
disc("Floor", RT, 0.6, 0.3, MOSAIC, Enum.Material.Marble, belv)
disc("MosaicRing", 6.2, 0.06, 0.63, GOLD, Enum.Material.SmoothPlastic, belv, false).Reflectance = 0.1
disc("MosaicSea", 5.5, 0.08, 0.66, SEA, Enum.Material.Slate, belv, false)
disc("MosaicHeart", 1.6, 0.06, 0.72, GOLD, Enum.Material.SmoothPlastic, belv, false).Reflectance = 0.1
part("Step", Vector3.new(12, 0.32, 2.4), at(0, 0.16, -(RT + 0.9)), STONE, Enum.Material.Limestone, belv)
local Y0 = 0.6                                                         -- the floor's top

-- ---------------------------------------------------------------- the parapet, the sea side ----
local RW, NSEG, ARC = 15.6, 16, math.rad(170)                          -- the wall's radius, its segments, how far round it goes
local segL = 2 * RW * math.sin(ARC / NSEG / 2) + 0.2
for i = 1, NSEG do
	local th = -ARC / 2 + (i - 0.5) * ARC / NSEG
	local x, z = RW * math.sin(th), RW * math.cos(th)
	local turn = CFrame.Angles(0, th, 0)
	part("Wall", Vector3.new(segL, 2.2, 0.7), at(x, Y0 + 1.1, z) * turn, STONE, Enum.Material.Limestone, belv)
	part("Band", Vector3.new(segL, 0.45, 0.8), at(x, Y0 + 1.3, z) * turn, MAJOLICA, Enum.Material.SmoothPlastic, belv, nil, false)
	part("Cap", Vector3.new(segL + 0.1, 0.3, 1.0), at(x, Y0 + 2.35, z) * turn, TRIM, Enum.Material.Marble, belv)
end

-- ---------------------------------------------------------------- the column with the harbour key ----
local KEY_H = 3.6
local function keyPose(s)
	return {
		Shaft = {CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(2.3 * s, 0.34 * s, 0.34 * s), GOLD, Enum.PartType.Cylinder},
		Nut = {CFrame.new(0, 1.57 * s, 0), Vector3.new(0.95 * s, 0.95 * s, 0.95 * s), GOLD, Enum.PartType.Ball},
		Cap = {CFrame.new(0, 2.01 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.36 * s, 1.06 * s, 1.06 * s), GOLD_D, Enum.PartType.Cylinder},
		Lip = {CFrame.new(0, 1.81 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.14 * s, 0.9 * s, 0.9 * s), GOLD_DD, Enum.PartType.Cylinder},
		Stem = {CFrame.new(0, 2.25 * s, 0), Vector3.new(0.17 * s, 0.26 * s, 0.17 * s), GOLD_DD, nil},
		Bit1 = {CFrame.new(0.38 * s, -0.95 * s, 0), Vector3.new(0.5 * s, 0.3 * s, 0.34 * s), GOLD, nil},
		Bit2 = {CFrame.new(0.3 * s, -0.55 * s, 0), Vector3.new(0.34 * s, 0.3 * s, 0.34 * s), GOLD, nil},
	}
end
local function makeKey(height, cfBottom, parent)                      -- a key standing on cfBottom, its face along cfBottom's -z
	local s = height / KEY_H
	local k = Instance.new("Model"); k.Name = "Key"
	local pose = keyPose(s)
	local lo = math.huge
	for name, d in pairs(pose) do
		local p = part(name, d[2], d[1], d[3], Enum.Material.SmoothPlastic, k, d[4], false); p.CanQuery = false; p.Reflectance = 0.08
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do lo = math.min(lo, (p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y) end end end
	end
	local base = cfBottom * CFrame.new(0, -lo, 0) * CFrame.Angles(0, math.pi, 0)
	for name, d in pairs(pose) do k[name].CFrame = base * d[1] end
	k.WorldPivot = cfBottom * CFrame.new(0, height / 2, 0)
	k.Parent = parent
	return k
end
do
	local col = Instance.new("Model"); col.Name = "Column"; col.Parent = belv
	part("Base", Vector3.new(2.4, 0.5, 2.4), at(0, Y0 + 2.5 + 0.25, RW), TRIM, Enum.Material.Marble, col)
	part("Shaft", Vector3.new(8.6, 1.5, 1.5), at(0, Y0 + 3.0 + 4.3, RW) * CFrame.Angles(0, 0, math.pi / 2), STONE, Enum.Material.Limestone, col, Enum.PartType.Cylinder)
	part("Capital", Vector3.new(2.2, 0.4, 2.2), at(0, Y0 + 11.6 + 0.2, RW), TRIM, Enum.Material.Marble, col)
	part("Plinth", Vector3.new(1.4, 0.3, 1.4), at(0, Y0 + 12.0 + 0.15, RW), GOLD_D, Enum.Material.SmoothPlastic, col)
	makeKey(3.4, at(0, Y0 + 12.3, RW), col)
end

-- ---------------------------------------------------------------- the lanterns at the horns ----
for _, s in ipairs({-1, 1}) do
	local th = s * (ARC / 2 - math.rad(2))
	local x, z = RW * math.sin(th), RW * math.cos(th)
	local m = Instance.new("Model"); m.Name = "Lantern"; m.Parent = belv
	part("Foot", Vector3.new(0.9, 0.3, 0.9), at(x, Y0 + 2.5 + 0.15, z), IRON, Enum.Material.Metal, m)
	part("Post", Vector3.new(0.4, 3.8, 0.4), at(x, Y0 + 2.8 + 1.9, z), IRON, Enum.Material.Metal, m, nil, false)
	local lamp = part("Lamp", Vector3.new(0.9, 0.9, 0.9), at(x, Y0 + 6.6 + 0.45, z), C(255, 214, 140), Enum.Material.Neon, m, Enum.PartType.Ball, false)
	local lt = Instance.new("PointLight"); lt.Range = 16; lt.Brightness = 1.0; lt.Color = C(255, 214, 150); lt.Shadows = false; lt.Parent = lamp
	part("Hood", Vector3.new(1.2, 0.2, 1.2), at(x, Y0 + 7.5 + 0.1, z), IRON, Enum.Material.Metal, m, nil, false)
end

-- ---------------------------------------------------------------- the lectern with the roll of the Guardians ----
do
	local lect = Instance.new("Model"); lect.Name = "Lectern"; lect.Parent = F
	local LZ = -(RT - 3.6)
	part("Post", Vector3.new(1.6, 2.4, 1.1), at(0, Y0 + 1.2, LZ), STONE, Enum.Material.Limestone, lect)
	part("Frame", Vector3.new(7.6, 3.2, 0.14), at(0, Y0 + 2.9, LZ + 0.02) * CFrame.Angles(math.rad(52), 0, 0), TRIM, Enum.Material.Marble, lect, nil, false)
	local plaque = part("Plaque", Vector3.new(7.2, 2.8, 0.2), at(0, Y0 + 2.9, LZ) * CFrame.Angles(math.rad(52), 0, 0), TERRA, Enum.Material.SmoothPlastic, lect, nil, false)   -- (terracotta with cream letters: Shannon's pick, Oct 14)
	local psg = Instance.new("SurfaceGui"); psg.Name = "Words"; psg.Face = Enum.NormalId.Front; psg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	psg.PixelsPerStud = 70; psg.LightInfluence = 0.3; psg.Parent = plaque
	local function line(name, y, h, size, font, colour, text)
		local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 12, 0, y); l.Size = UDim2.new(1, -24, 0, h)
		l.Font = font; l.TextScaled = true; l.TextColor3 = colour; l.TextWrapped = true; l.Text = text; l.Parent = psg
		local cap = Instance.new("UITextSizeConstraint"); cap.MaxTextSize = size; cap.Parent = l
		return l
	end
	-- (7.2 x 2.8 studs = 504 x 196 px at 70 per stud)
	line("Title", 6, 42, 38, Enum.Font.Antique, CREAM, "BELVEDERE DEI GUARDIANI")
	line("Sub", 48, 24, 19, Enum.Font.Antique, CREAM, "THE GUARDIANS OF THE HARBOUR OF PORTO NOCCIOLA")
	line("Roll", 76, 76, 26, Enum.Font.FredokaOne, CREAM, "")
	line("Foot", 156, 30, 16, Enum.Font.Merriweather, CREAM, "Each of them found every squirrel of Porto Nocciola.")
end

-- ---------------------------------------------------------------- Porto's own trees and benches ----
-- (copies of the town's models, their tags and scripts removed so a copy joins nothing the original is part of)
local found, sources = {}, {}
do
	local want = {["Italian cypress"] = true, ["Lemon tree"] = true}                                    -- (no benches: Shannon, Oct 14, "I don't think we need benches there")
	for _, d in ipairs(workspace:GetDescendants()) do
		if want[d.Name] and d:IsA("Model") and not sources[d.Name] and not d:IsDescendantOf(F) and not (old and d:IsDescendantOf(old)) then sources[d.Name] = d end
	end
end
local function copyOf(name, scale, lx, lz, faceZ)
	local src = sources[name]
	if not src then found[name] = (found[name] or 0); return end
	local c = src:Clone(); c.Name = "Belv_" .. name:gsub("%s+", "_")
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BaseScript") then d:Destroy() else for _, t in ipairs(CS:GetTags(d)) do CS:RemoveTag(d, t) end end
	end
	for _, t in ipairs(CS:GetTags(c)) do CS:RemoveTag(c, t) end
	for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
	pcall(function() c:ScaleTo(c:GetScale() * scale) end)
	local want = at(lx, 0, lz).Position
	local gy
	if lx * lx + lz * lz < RT * RT then gy = at(0, Y0, 0).Position.Y + 0.1 else gy = groundAt(want.X, want.Z) end   -- inside: on the floor's top
	if not gy then c:Destroy(); found[name] = (found[name] or 0); return end
	local cf, size = c:GetBoundingBox()
	local pivot = c:GetPivot()
	if faceZ then                                                       -- turned so its front (-z) looks along the belvedere's +z (out to sea)
		c:PivotTo(CFrame.new(pivot.Position) * BASE.Rotation * CFrame.Angles(0, math.pi, 0))
		cf, size = c:GetBoundingBox()
	end
	c:PivotTo(c:GetPivot() + Vector3.new(want.X - cf.Position.X, gy - (cf.Position.Y - size.Y / 2) - 0.1, want.Z - cf.Position.Z))
	c.Parent = belv
	found[name] = (found[name] or 0) + 1
end
for _, s in ipairs({-1, 1}) do
	copyOf("Italian cypress", 1.0, s * 18 * math.sin(math.rad(52)), 18 * math.cos(math.rad(52)))       -- behind the parapet's shoulders
	copyOf("Lemon tree", 0.9, s * 8.5, -(RT + 2.6))                                                    -- either side of the step
end

-- ---------------------------------------------------------------- the folder, its settings, the script ----
F:SetAttribute("Base", BASE)
F:SetAttribute("FloorTop", Y0); F:SetAttribute("Slots", 7); F:SetAttribute("Radius", 12.6); F:SetAttribute("ArcDeg", 150)
F:SetAttribute("Scale", 1.35); F:SetAttribute("KeyShare", 0.42); F:SetAttribute("RestKeyHeight", 2.6); F:SetAttribute("Total", 44)
F:SetAttribute("Rebuild", 0)
-- a play-test preview (no Guardian list on the test server): three sample Guardians so the crescent can be seen with statues
if RunService:IsRunning() then
	F:SetAttribute("PreviewJson", HttpService:JSONEncode({
		{no = 1, uid = 9611145467, name = "SelBell", user = "SelBell", t = 1791676800, total = 44},
		{no = 2, uid = 4161205246, name = "dakota", user = "mentallyunstable_xo", t = 1791763200, total = 44},
		{no = 3, uid = 7902108387, name = "blizzy_1718", user = "blizzy_1718", t = 1791849600, total = 44},
	}))
else
	F:SetAttribute("PreviewJson", "")
end
if old then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("HallOfGuardians_pre_" .. n) do n += 1 end
	old.Name = "HallOfGuardians_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
-- the small props under the terrace, set aside with their places kept
local parked = 0
if #props > 0 then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("HallOfGuardians_props_" .. n) do n += 1 end
	local pf = Instance.new("Folder"); pf.Name = "HallOfGuardians_props_" .. n; pf.Parent = hb
	for _, th in ipairs(props) do th:SetAttribute("ParkedFrom", th.Parent and th.Parent:GetFullName() or ""); th.Parent = pf; parked += 1 end   -- (the undo: back to ParkedFrom)
end
local s = Instance.new("Script"); s.Name = "HallServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
F.Parent = workspace
local names, near = {}, {}
for _, n in ipairs({"Italian cypress", "Lemon tree"}) do table.insert(names, n .. " " .. tostring(found[n] or 0)) end
for n, k in pairs(standing) do table.insert(near, n .. " x" .. k) end
print(string.format("QQ BELV DONE: workspace.HallOfGuardians at (%.0f, %.1f, %.0f) yaw %.0f (ground centre %.1f, edges %.1f..%.1f); terrace R %d, parapet %d segments, 7 slots; copies: %s; %d small props set aside (HudBackup.HallOfGuardians_props_*); HallServer %d chars%s", CX, g, CZ, math.deg(YAW), centreY, lowest, highest, RT, NSEG, table.concat(names, ", "), parked, #s.Source, old and ("; the old folder is HudBackup." .. old.Name) or ""))
if #near > 0 then print("QQ BELV NOTE: standing within 19-21 studs of the centre (more than a stud above the terrain): " .. table.concat(near, ", ")) end
