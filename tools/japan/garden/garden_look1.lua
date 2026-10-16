-- garden_look1.lua (job 125, the Momiji Garden LOOK TEST; a play-test PREVIEW first, then Studio EDIT on her word; re-runnable).
-- Places the Blender pieces from ServerStorage.JapanGardenKit (import out1/*.fbx there, one Model per file, named after the file) around
-- the canal's red bridge (~6101, -215): the taiko bridge in place of LanternStreet's "Canal footbridge" at z -215 (the old one ->
-- HudBackup), the waterfall over the canal's south end (the weir), a torii on the path west of the bridge, two autumn maples and a
-- pine, four stone lanterns at the bridge ends (lit), rocks at the waterfall's foot, and stepping slabs from the bridge's east end
-- toward the falls. The flat "Vermilion maple"s within 30 studs go to HudBackup too. No parts are built: only the imported meshes.
-- Output "QQ GARDEN".
local SS = game:GetService("ServerStorage")
local KIT = SS:FindFirstChild("JapanGardenKit")
if not KIT then print("QQ GARDEN ABORT: ServerStorage.JapanGardenKit is missing - import tools/japan/garden/out1/*.fbx there first") return end
local J = workspace:FindFirstChild("JapanMap")
if not J then print("QQ GARDEN ABORT: no workspace.JapanMap") return end
local BB = {
	["torii"] = {min = Vector3.new(-9.881, 0.0, -0.85), max = Vector3.new(9.881, 16.843, 1.1)},
	["lantern"] = {min = Vector3.new(-1.55, 0.0, -1.342), max = Vector3.new(1.55, 5.566, 1.342)},
	["bridge"] = {min = Vector3.new(-20.232, -2.4, -4.4), max = Vector3.new(20.232, 8.6, 4.4)},
	["maple_a"] = {min = Vector3.new(-5.727, -0.046, -5.657), max = Vector3.new(5.364, 9.639, 4.668)},
	["maple_b"] = {min = Vector3.new(-4.909, -0.056, -5.891), max = Vector3.new(5.128, 10.535, 5.688)},
	["pine"] = {min = Vector3.new(-5.87, -0.186, -5.552), max = Vector3.new(6.83, 8.686, 3.381)},
	["rocks"] = {min = Vector3.new(-2.704, -0.462, -2.328), max = Vector3.new(2.418, 1.394, 2.366)},
	["slabs"] = {min = Vector3.new(-1.861, 0.0, -1.962), max = Vector3.new(2.07, 0.35, 2.063)},
	["waterfall"] = {min = Vector3.new(-8.555, -0.414, -6.462), max = Vector3.new(8.742, 10.425, 3.761)},
	["rocks/Rock1"] = {min = Vector3.new(-1.551, -0.392, -1.823), max = Vector3.new(1.714, 1.14, 1.387)},
	["slabs/Slab1"] = {min = Vector3.new(-1.338, 0.0, -1.277), max = Vector3.new(1.37, 0.35, 1.546)},
	["rocks/Rock2"] = {min = Vector3.new(-2.704, -0.462, -2.328), max = Vector3.new(2.418, 1.394, 2.366)},
	["slabs/Slab2"] = {min = Vector3.new(-1.861, 0.0, -1.962), max = Vector3.new(2.07, 0.35, 2.063)},
	["rocks/Rock3"] = {min = Vector3.new(-1.098, -0.347, -1.303), max = Vector3.new(1.166, 1.03, 1.089)},
	["slabs/Slab3"] = {min = Vector3.new(-1.336, 0.0, -1.039), max = Vector3.new(1.034, 0.35, 1.101)}
}
local COL = {
	Torii_Red = Color3.new(0.8, 0.2, 0.13),
	Torii_Black = Color3.new(0.13, 0.12, 0.12),
	Torii_Plaque = Color3.new(0.2, 0.16, 0.14),
	Lantern_Stone = Color3.new(0.62, 0.62, 0.6),
	Lantern_Paper = Color3.new(1.0, 0.88, 0.62),
	Bridge_Red = Color3.new(0.82, 0.18, 0.12),
	Bridge_Deck = Color3.new(0.55, 0.38, 0.24),
	Bridge_Gold = Color3.new(0.93, 0.74, 0.3),
	Bridge_Stone = Color3.new(0.58, 0.57, 0.55),
	Maple_Bark = Color3.new(0.36, 0.25, 0.19),
	Maple_Red = Color3.new(0.86, 0.24, 0.16),
	Maple_Orange = Color3.new(0.95, 0.52, 0.18),
	Maple_Gold = Color3.new(0.98, 0.74, 0.28),
	Pine_Bark = Color3.new(0.3, 0.22, 0.18),
	Pine_Needles = Color3.new(0.2, 0.42, 0.26),
	Rock_Grey = Color3.new(0.55, 0.55, 0.54),
	Rock_Moss = Color3.new(0.42, 0.58, 0.3),
	Slab_Stone = Color3.new(0.66, 0.65, 0.62),
	Fall_Rock = Color3.new(0.5, 0.5, 0.5),
	Fall_Moss = Color3.new(0.4, 0.56, 0.3),
	Fall_Water = Color3.new(0.72, 0.88, 0.97),
	Fall_Foam = Color3.new(0.95, 0.98, 1.0)
}
local function colourKey(name)                                            -- "A_Maple_Red" -> Maple_Red, "Rock2_Moss" -> Rock_Moss, "Slab3" -> Slab_Stone
	local n = name:gsub("^[AB]_", ""):gsub("^Rock%d_", "Rock_")
	if n:match("^Slab%d") then return "Slab_Stone" end
	return n
end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Momiji garden look test") end)
local old = J:FindFirstChild("MomijiGarden")
if old then local n = 1; while hb:FindFirstChild("MomijiGarden_pre_" .. n) do n += 1 end; old.Name = "MomijiGarden_pre_" .. n; old.Parent = hb end
local G = Instance.new("Folder"); G.Name = "MomijiGarden"; G.Parent = J
local replaced = hb:FindFirstChild("MomijiGardenReplaced") or Instance.new("Folder"); replaced.Name = "MomijiGardenReplaced"; replaced.Parent = hb
local missing, made, meshes = {}, 0, 0
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local key = colourKey(p.Name)
			p.Anchored = true; p.CastShadow = true; p.Material = Enum.Material.SmoothPlastic
			if COL[key] then p.Color = COL[key] else table.insert(missing, p.Name) end
			p.CanCollide = (key == "Bridge_Deck" or key == "Bridge_Red" or key == "Bridge_Stone" or key:match("^Torii_") ~= nil or key == "Lantern_Stone"
				or key == "Rock_Grey" or key == "Rock_Moss" or key == "Slab_Stone" or key == "Fall_Rock" or key == "Fall_Moss" or key:match("_Bark$") ~= nil)
			p.CanQuery = p.CanCollide; p.CanTouch = false
			if p:IsA("MeshPart") and (key == "Bridge_Deck" or key == "Slab_Stone") then pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end) end
			if key == "Lantern_Paper" then
				p.Material = Enum.Material.Neon
				local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 214, 150); l.Range = 12; l.Brightness = 1.2; l.Shadows = false; l.Parent = p
			elseif key == "Fall_Water" then
				p.Material = Enum.Material.Glass; p.Transparency = 0.25; p.CastShadow = false
				pcall(function() p.DoubleSided = true end)
			elseif key == "Fall_Foam" then p.Transparency = 0.15; p.CastShadow = false end
			meshes += 1
		end
	end
end
-- place a copy of a kit model (or of one group inside it) so its Blender origin lands on `at`, turned by `yaw` degrees
local function place(kitName, at, yaw, group, label)
	local src = KIT:FindFirstChild(kitName)
	if not src then table.insert(missing, kitName); return nil end
	local m
	if group then
		m = Instance.new("Model")
		for _, p in ipairs(src:GetDescendants()) do
			if p:IsA("BasePart") and (p.Name == group or p.Name:sub(1, #group + 1) == group .. "_") then p:Clone().Parent = m end
		end
		if #m:GetChildren() == 0 then table.insert(missing, kitName .. "/" .. group); return nil end
	else
		m = src:Clone()
	end
	m.Name = label or (group or kitName)
	local box = BB[group and (kitName .. "/" .. group) or kitName]
	local cf, size = m:GetBoundingBox()
	local expect = (box.min + box.max) / 2                                -- the box centre, relative to the Blender origin
	m.WorldPivot = CFrame.new(cf.Position - expect)
	m:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.rad(yaw or 0), 0))
	dress(m); m.Parent = G; made += 1
	return m
end
-- 1. the old footbridge at z -215 and the flat maples nearby go to HudBackup
local hidden = {}
for _, d in ipairs(J:GetDescendants()) do
	if d:IsA("Model") and d.Parent and not d:IsDescendantOf(G) then
		local ok, cf = pcall(function() return d:GetPivot() end)
		if ok and (d.Name == "Canal footbridge" and math.abs(cf.Z + 215) < 6) or (ok and d.Name:lower():find("vermilion maple") and (Vector3.new(cf.X, 0, cf.Z) - Vector3.new(6101, 0, -215)).Magnitude < 30) then
			table.insert(hidden, d)
		end
	end
end
for _, d in ipairs(hidden) do d:SetAttribute("GardenWasIn", d.Parent:GetFullName()); d.Parent = replaced end
print(string.format("QQ GARDEN replaced (to HudBackup.MomijiGardenReplaced): %d - %s", #hidden, (function() local t = {}; for _, d in ipairs(hidden) do table.insert(t, d.Name) end; return table.concat(t, ", ") end)()))
-- 2. the pieces
place("bridge", Vector3.new(6101, 0.3, -215), 0, nil, "TaikoBridge")
place("waterfall", Vector3.new(6101, 1.0, -222.5), 0, nil, "Waterfall")    -- its front (+Z) looks north up the canal
place("torii", Vector3.new(6058, 0, -215), 90, nil, "Torii")              -- the path passes through it along X
place("maple_a", Vector3.new(6131, 0, -236), 20, nil, "MapleA")
place("maple_b", Vector3.new(6071, 0, -238), -40, nil, "MapleB")
place("pine", Vector3.new(6129, 0, -202), 200, nil, "BlackPine")
for i, at in ipairs({Vector3.new(6077, 0, -209), Vector3.new(6077, 0, -221), Vector3.new(6125, 0, -209), Vector3.new(6125, 0, -221)}) do place("lantern", at, 0, nil, "StoneLantern" .. i) end
place("rocks", Vector3.new(6089, 0.4, -228), 30, "Rock2", "RockA")
place("rocks", Vector3.new(6113, 0.4, -227), -20, "Rock1", "RockB")
place("rocks", Vector3.new(6119, 0.2, -232), 70, "Rock3", "RockC")
for i, s in ipairs({{6124, -224, "Slab1"}, {6126.5, -228.5, "Slab2"}, {6124.5, -233, "Slab3"}, {6127, -237.5, "Slab1"}}) do place("slabs", Vector3.new(s[1], 0.02, s[2]), i * 37, s[3], "Slab" .. i) end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Momiji garden look test") end)
if #missing > 0 then print("QQ GARDEN missing or uncoloured: " .. table.concat(missing, ", ")) end
print(string.format("QQ GARDEN DONE: workspace.JapanMap.MomijiGarden - %d pieces, %d meshes; no parts built", made, meshes))
