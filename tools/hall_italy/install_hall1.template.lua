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
do local f, err = loadstring(SERVER); if not f then print("QQ BELV ABORT: HallServer does not compile: " .. tostring(err)) return end end
local CH = workspace:FindFirstChild("Champion")
if not (CH and CH:FindFirstChild("ChampionServer")) then print("QQ BELV ABORT: workspace.Champion.ChampionServer not found (it makes the statues)") return end
if not workspace:FindFirstChild("PortoKeeper") then print("QQ BELV ABORT: workspace.PortoKeeper not found (it keeps the Guardian list)") return end
local C = Color3.fromRGB
local STONE, TRIM, MAJOLICA, TERRA, GOLD, GOLD_D, GOLD_DD, CREAM, IRON = C(232, 226, 210), C(240, 236, 226), C(52, 110, 150), C(178, 92, 62), C(255, 206, 64), C(214, 160, 44), C(190, 136, 40), C(250, 244, 228), C(52, 50, 48)
local MOSAIC, SEA = C(222, 212, 190), C(78, 150, 186)

-- ---------------------------------------------------------------- the ground ----
local F = Instance.new("Folder"); F.Name = "HallOfGuardians"
local old = workspace:FindFirstChild("HallOfGuardians")
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Exclude; rpT.FilterDescendantsInstances = {F, old}
local function groundAt(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpT)
	if h and not (h.Instance == workspace.Terrain and h.Material == Enum.Material.Water) then return h.Position.Y end
	return nil
end
local samples, lowest, highest = {}, math.huge, -math.huge
local centreY = groundAt(CX, CZ)
for i = 0, 7 do
	local a = i * math.pi / 4
	local y = groundAt(CX + 15 * math.sin(a), CZ + 15 * math.cos(a))
	if y then table.insert(samples, y); lowest = math.min(lowest, y); highest = math.max(highest, y) end
end
if not centreY or #samples < 6 then print("QQ BELV ABORT: no ground under the terrace (water or nothing at the centre or round it); nothing built") return end
local g = math.min(centreY, lowest + 1.0) - 0.1                       -- the floor's base: near the centre's height, never more than a stud over the lowest edge
local BASE = CFrame.new(CX, g, CZ) * CFrame.Angles(0, YAW, 0)
local function at(x, y, z) return BASE * CFrame.new(x, y, z) end
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
local RT = 17                                                          -- the terrace's radius
disc("Skirt", RT + 0.2, 3.0, -1.5, STONE, Enum.Material.Limestone, belv)
disc("Rim", RT + 0.5, 0.3, 0.15, TERRA, Enum.Material.Slate, belv)
disc("Floor", RT, 0.6, 0.3, MOSAIC, Enum.Material.Marble, belv)
disc("MosaicRing", 6.2, 0.06, 0.63, GOLD, Enum.Material.SmoothPlastic, belv, false).Reflectance = 0.1
disc("MosaicSea", 5.5, 0.08, 0.66, SEA, Enum.Material.Slate, belv, false)
disc("MosaicHeart", 1.6, 0.06, 0.72, GOLD, Enum.Material.SmoothPlastic, belv, false).Reflectance = 0.1
part("Step", Vector3.new(12, 0.3, 2.4), at(0, 0.15, -(RT + 0.9)), STONE, Enum.Material.Limestone, belv)
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
	part("Shaft", Vector3.new(6.6, 1.5, 1.5), at(0, Y0 + 3.0 + 3.3, RW) * CFrame.Angles(0, 0, math.pi / 2), STONE, Enum.Material.Limestone, col, Enum.PartType.Cylinder)
	part("Capital", Vector3.new(2.2, 0.4, 2.2), at(0, Y0 + 9.6 + 0.2, RW), TRIM, Enum.Material.Marble, col)
	part("Plinth", Vector3.new(1.4, 0.3, 1.4), at(0, Y0 + 10.0 + 0.15, RW), GOLD_D, Enum.Material.SmoothPlastic, col)
	makeKey(3.4, at(0, Y0 + 10.3, RW), col)
end

-- ---------------------------------------------------------------- the lanterns at the horns ----
for _, s in ipairs({-1, 1}) do
	local th = s * ARC / 2
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
	part("Frame", Vector3.new(7.6, 3.2, 0.14), at(0, Y0 + 2.9, LZ + 0.02) * CFrame.Angles(math.rad(52), 0, 0), GOLD_D, Enum.Material.SmoothPlastic, lect, nil, false)
	local plaque = part("Plaque", Vector3.new(7.2, 2.8, 0.2), at(0, Y0 + 2.9, LZ) * CFrame.Angles(math.rad(52), 0, 0), MAJOLICA, Enum.Material.SmoothPlastic, lect, nil, false)
	local psg = Instance.new("SurfaceGui"); psg.Name = "Words"; psg.Face = Enum.NormalId.Front; psg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	psg.PixelsPerStud = 70; psg.LightInfluence = 0.3; psg.Parent = plaque
	local function line(name, y, h, size, font, colour, text)
		local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 12, 0, y); l.Size = UDim2.new(1, -24, 0, h)
		l.Font = font; l.TextScaled = true; l.TextColor3 = colour; l.TextWrapped = true; l.Text = text; l.Parent = psg
		local cap = Instance.new("UITextSizeConstraint"); cap.MaxTextSize = size; cap.Parent = l
		return l
	end
	-- (7.2 x 2.8 studs = 504 x 196 px at 70 per stud)
	line("Title", 6, 42, 38, Enum.Font.Antique, GOLD, "BELVEDERE DEI GUARDIANI")
	line("Sub", 48, 24, 19, Enum.Font.Antique, CREAM, "THE GUARDIANS OF THE HARBOUR OF PORTO NOCCIOLA")
	line("Roll", 76, 76, 26, Enum.Font.FredokaOne, CREAM, "")
	line("Foot", 156, 30, 16, Enum.Font.Merriweather, CREAM, "Each of them found every squirrel of Porto Nocciola.")
end

-- ---------------------------------------------------------------- Porto's own trees and benches ----
-- (copies of the town's models, their tags and scripts removed so a copy joins nothing the original is part of)
local found = {}
local function copyOf(name, scale, lx, lz, faceZ)
	local src
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and d.Name == name and not d:IsDescendantOf(F) and not (old and d:IsDescendantOf(old)) then src = d break end
	end
	if not src then found[name] = (found[name] or 0); return end
	local c = src:Clone(); c.Name = "Belv_" .. name:gsub("%s+", "_")
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BaseScript") then d:Destroy() else for _, t in ipairs(CS:GetTags(d)) do CS:RemoveTag(d, t) end end
	end
	for _, t in ipairs(CS:GetTags(c)) do CS:RemoveTag(c, t) end
	for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
	pcall(function() c:ScaleTo(c:GetScale() * scale) end)
	local want = at(lx, 0, lz).Position
	local gy = groundAt(want.X, want.Z)
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
	copyOf("Harbour bench", 1.0, s * 9.5, 1.5, true)                                                    -- facing the sea, inside the crescent
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
local s = Instance.new("Script"); s.Name = "HallServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
F.Parent = workspace
local names = {}
for _, n in ipairs({"Italian cypress", "Lemon tree", "Harbour bench"}) do table.insert(names, n .. " " .. tostring(found[n] or 0)) end
print(string.format("QQ BELV DONE: workspace.HallOfGuardians at (%.0f, %.1f, %.0f) yaw %.0f (ground centre %.1f, edges %.1f..%.1f); terrace R %d, parapet %d segments, 7 slots; copies: %s; HallServer %d chars%s", CX, g, CZ, math.deg(YAW), centreY, lowest, highest, RT, NSEG, table.concat(names, ", "), #s.Source, old and ("; the old folder is HudBackup." .. old.Name) or ""))
