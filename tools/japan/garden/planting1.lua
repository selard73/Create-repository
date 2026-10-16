-- planting1.lua (job 125): the railway strip's blue irises -> clipped azalea mounds and hydrangea clumps (a play-test PREVIEW first;
-- Studio EDIT on her word; re-runnable). 1. finds the "Blue iris" / "Iris stem" parts in JapanMap.Landscape (or, on a re-run, the retired
-- ones in HudBackup.IrisReplaced) and groups the blooms into clusters (three in a row 0.35 apart); 2. RETIRES all of them to
-- HudBackup.IrisReplaced (attribute IrisWasIn); 3. PLACES one clump per cluster from the kit: azalea (one blossom colour kept per clump:
-- pink / white / magenta) or hydrangea, random yaw and size. Meshes only. Output "QQ PLANTING1".
local SS = game:GetService("ServerStorage")
local KIT = SS:FindFirstChild("JapanGardenKit")
local J = workspace:FindFirstChild("JapanMap")
if not (KIT and J) then print("QQ PLANTING1 ABORT: ServerStorage.JapanGardenKit or workspace.JapanMap missing") return end
for _, n in ipairs({"azalea", "hydrangea"}) do
	if not KIT:FindFirstChild(n) then print("QQ PLANTING1 ABORT: the kit has no Model '" .. n .. "' - import tools/japan/garden/out4/*.fbx") return end
end
local BB = {
	["azalea"] = {min = Vector3.new(-1.766, -0.569, -1.657), max = Vector3.new(1.765, 1.759, 1.651)},
	["hydrangea"] = {min = Vector3.new(-1.499, -0.189, -1.502), max = Vector3.new(1.469, 1.84, 1.506)}
}
local COL = {
	Azalea_Leaf = Color3.new(0.22, 0.42, 0.2),
	Azalea_Pink = Color3.new(0.93, 0.45, 0.62),
	Azalea_White = Color3.new(0.96, 0.95, 0.9),
	Azalea_Magenta = Color3.new(0.8, 0.22, 0.48),
	Hydrangea_Leaf = Color3.new(0.26, 0.48, 0.24),
	Hydrangea_Bloom = Color3.new(0.52, 0.56, 0.84)
}
local HYDRANGEA_SHARE = 0.28                                                -- about one clump in four is a hydrangea (a touch of blue stays on the strip)
local AZALEA_COLOURS = {"Azalea_Pink", "Azalea_Pink", "Azalea_Pink", "Azalea_White", "Azalea_White", "Azalea_Magenta"}   -- pink 3 : white 2 : magenta 1
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("IrisReplaced") or Instance.new("Folder"); bak.Name = "IrisReplaced"; bak.Parent = hb
-- ---------- 1. the irises and their clusters ----------
local land = J:FindFirstChild("Landscape")
local blooms, stems = {}, {}
local function collect(folder)
	for _, d in ipairs(folder:GetChildren()) do
		if d:IsA("BasePart") then
			if d.Name == "Blue iris" then table.insert(blooms, d) elseif d.Name == "Iris stem" then table.insert(stems, d) end
		end
	end
end
if land then collect(land) end
local fromBackup = false
if #blooms == 0 then collect(bak); fromBackup = true end                   -- a re-run: the first run retired them
if #blooms == 0 then print("QQ PLANTING1 ABORT: no 'Blue iris' parts in JapanMap.Landscape nor in HudBackup.IrisReplaced") return end
table.sort(blooms, function(a, b) if math.abs(a.Position.Z - b.Position.Z) > 0.3 then return a.Position.Z < b.Position.Z end return a.Position.X < b.Position.X end)
local clusters = {}
for _, b in ipairs(blooms) do
	local c = clusters[#clusters]
	if c and math.abs(b.Position.Z - c.z) < 0.3 and b.Position.X - c.lastX < 0.6 then
		c.n += 1; c.sx += b.Position.X; c.lastX = b.Position.X
	else
		table.insert(clusters, {n = 1, sx = b.Position.X, z = b.Position.Z, lastX = b.Position.X})
	end
end
print(string.format("QQ PLANTING1 found %d blooms + %d stems%s -> %d clusters, x %.0f .. %.0f, z %.0f .. %.0f", #blooms, #stems,
	fromBackup and " (from HudBackup.IrisReplaced, a re-run)" or " in JapanMap.Landscape", #clusters, blooms[1].Position.X, blooms[#blooms].Position.X,
	blooms[1].Position.Z, blooms[#blooms].Position.Z))
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before planting1") end)
-- ---------- 2. retire them ----------
local retired = 0
if not fromBackup then
	for _, list in ipairs({blooms, stems}) do
		for _, d in ipairs(list) do d:SetAttribute("IrisWasIn", d.Parent:GetFullName()); d.Parent = bak; retired += 1 end
	end
end
print(string.format("QQ PLANTING1 retired %d iris parts -> HudBackup.IrisReplaced", retired))
-- ---------- 3. the clumps ----------
local old = J:FindFirstChild("MomijiPlanting")
if old then local prev = hb:FindFirstChild("MomijiPlanting_prev"); if prev then prev:Destroy() end; old.Name = "MomijiPlanting_prev"; old.Parent = hb end
local G = Instance.new("Folder"); G.Name = "MomijiPlanting"; G.Parent = J
local made, meshes, missing = 0, 0, {}
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true; p.Material = Enum.Material.SmoothPlastic; p.CastShadow = true
			if COL[p.Name] then p.Color = COL[p.Name] else table.insert(missing, p.Name) end
			local leaf = p.Name == "Azalea_Leaf" or p.Name == "Hydrangea_Leaf"
			p.CanCollide = leaf; p.CanQuery = leaf; p.CanTouch = false
			meshes += 1
		end
	end
end
local function place(kitName, at, yaw, scale, keepBlossom)
	local src = KIT:FindFirstChild(kitName)
	local m = src:Clone()
	if keepBlossom then
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") and p.Name:sub(1, 7) == "Azalea_" and p.Name ~= "Azalea_Leaf" and p.Name ~= keepBlossom then p:Destroy() end
		end
	end
	local box = BB[kitName]
	local cf = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position - (box.min + box.max) / 2)
	if scale ~= 1 then pcall(function() m:ScaleTo(scale) end) end
	m:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.rad(yaw), 0))
	m.Name = keepBlossom and ("Azalea_" .. keepBlossom:sub(8)) or "Hydrangea"
	dress(m); m.Parent = G; made += 1
	return m
end
local rnd = Random.new(4040)
local nA, nH = 0, 0
for i, c in ipairs(clusters) do
	local x = c.sx / c.n
	local at = Vector3.new(x + rnd:NextNumber(-0.3, 0.3), 0, c.z + rnd:NextNumber(-0.3, 0.3))
	if rnd:NextNumber() < HYDRANGEA_SHARE then
		place("hydrangea", at, rnd:NextInteger(0, 359), rnd:NextNumber(0.9, 1.2), nil); nH += 1
	else
		place("azalea", at, rnd:NextInteger(0, 359), rnd:NextNumber(0.85, 1.25), AZALEA_COLOURS[rnd:NextInteger(1, #AZALEA_COLOURS)]); nA += 1
	end
end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after planting1") end)
if #missing > 0 then print("QQ PLANTING1 uncoloured: " .. table.concat(missing, ", ")) end
print(string.format("QQ PLANTING1 DONE: JapanMap.MomijiPlanting - %d clumps (%d azaleas, %d hydrangeas) for %d clusters, %d meshes; no parts built", made, nA, nH, #clusters, meshes))
