-- travel_probe1 v1: READ-ONLY. Facts for the travel-boards build: streaming, the landing shore east of the plunge pool
-- (ground height + material grid), free ground round the three spawn daises for a signpost, MusicClient areas,
-- BoatClient landing lines, SpawnReturnServer anchor strings, and whether Travel / Spawn_porto already exist.
local SEA_Y = -52.9
print("QQ TP streaming=" .. tostring(workspace.StreamingEnabled) .. " autoloads=" .. tostring(game:GetService("Players").CharacterAutoLoads))
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.IgnoreWater = false
local skip = {}
for _, o in ipairs(workspace:GetChildren()) do if o:FindFirstChildWhichIsA("Humanoid") then skip[#skip + 1] = o end end
rp.FilterDescendantsInstances = skip
local function hit(x, z, top)
	return workspace:Raycast(Vector3.new(x, top or 40, z), Vector3.new(0, -(top or 40) - 130, 0), rp)
end
local function sym(h)
	if not h then return "." end
	if h.Instance == workspace.Terrain then
		local m = h.Material
		if m == Enum.Material.Water then return "W" end
		if h.Position.Y > SEA_Y + 1.5 then return (m == Enum.Material.Sand and "s" or m == Enum.Material.Grass and "g" or m == Enum.Material.Rock and "r" or m == Enum.Material.Sandstone and "S" or "#") end
		return "~"
	end
	return "P"
end
-- the coarse picture: x 140..320 step 10 (19 columns), z -540..-700 step 10
print("QQ TP MAP columns x=140..320 step 10; W water, s sand, g grass, r rock, S sandstone, # other land above sea, ~ land at sea level, P part, . nothing")
for z = -540, -700, -10 do
	local row = {}
	for x = 140, 320, 10 do row[#row + 1] = sym(hit(x, z)) end
	print(string.format("QQ TP MAP z %4d |%s|", z, table.concat(row)))
end
-- the fine grid over the candidate shore: x 200..260 step 5, z -560..-620 step 5, height above the sea + material
print("QQ TP SHORE x=200..260 step 5: height above sea (studs) and material letter; - = water, . = nothing")
for z = -560, -620, -5 do
	local row = {}
	for x = 200, 260, 5 do
		local h = hit(x, z)
		if not h then row[#row + 1] = "   ." elseif h.Instance == workspace.Terrain and h.Material == Enum.Material.Water then row[#row + 1] = "   -"
		else row[#row + 1] = string.format("%3d%s", math.floor(h.Position.Y - SEA_Y + 0.5), sym(h)) end
	end
	print(string.format("QQ TP SHORE z %4d |%s|", z, table.concat(row, " ")))
end
-- round the daises: ground at 7.5 and 9.5 studs out in 8 directions, and anything within 2.5 studs of that spot
local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude
for _, id in ipairs({"forest", "village", "domaine"}) do
	local sp = workspace:FindFirstChild("Spawn_" .. id)
	local dais = workspace:FindFirstChild("SpawnDais_" .. id)
	if sp then
		local c = sp.Position
		print(string.format("QQ TP DAIS %s spawn (%.1f,%.1f,%.1f) yaw %.0f dais=%s", id, c.X, c.Y, c.Z, math.deg(select(2, sp.CFrame:ToEulerAnglesYXZ())), tostring(dais ~= nil)))
		local ex = {sp}; if dais then ex[#ex + 1] = dais end
		for _, o in ipairs(skip) do ex[#ex + 1] = o end
		op.FilterDescendantsInstances = ex
		local rp2 = RaycastParams.new(); rp2.FilterType = Enum.RaycastFilterType.Exclude; rp2.FilterDescendantsInstances = ex
		for k = 0, 7 do
			local a = k * math.pi / 4
			local parts = {}
			for _, r in ipairs({7.5, 9.5}) do
				local x, z = c.X + math.sin(a) * r, c.Z + math.cos(a) * r
				local h = workspace:Raycast(Vector3.new(x, c.Y + 20, z), Vector3.new(0, -60, 0), rp2)
				local near = workspace:GetPartBoundsInRadius(Vector3.new(x, c.Y + 1.5, z), 2.5, op)
				local names = {}
				for _, q in ipairs(near) do if q ~= workspace.Terrain and #names < 3 then local m = q:FindFirstAncestorOfClass("Model"); names[#names + 1] = (m and m.Name or q.Name) end end
				parts[#parts + 1] = string.format("r%.1f: %s y%.1f%s", r, h and (h.Instance == workspace.Terrain and tostring(h.Material):gsub("Enum.Material.", "") or h.Instance.Name) or "none", h and h.Position.Y or 0, #names > 0 and (" near[" .. table.concat(names, ",") .. "]") or "")
			end
			print(string.format("QQ TP DAIS %s dir %3d (dx %+.0f dz %+.0f): %s", id, math.floor(math.deg(a) + 0.5), math.sin(a), math.cos(a), table.concat(parts, " | ")))
		end
	else
		print("QQ TP DAIS " .. id .. " missing")
	end
end
-- scripts: anchor strings
local function src(o) local ok, t = pcall(function() return o.Source end); return ok and t or "" end
local sr = workspace:FindFirstChild("SpawnReturn") and workspace.SpawnReturn:FindFirstChild("SpawnReturnServer")
if sr then
	local t = src(sr)
	for _, k in ipairs({"local ORDER = {\"forest\", \"village\", \"domaine\"}", "local RANK = {forest = 1, village = 2, domaine = 3}", "local function areaAt(pos)\n\tfor _, a in ipairs(EDGE) do if pos.X >= a[2] then return a[1] end end\n\treturn \"forest\"\nend", "local function target(player)", "return ORDER[math.min(want, reach)]", "Players.CharacterAutoLoads = false"}) do
		print(string.format("QQ TP SR anchor %q -> %s", k:sub(1, 40), tostring(t:find(k, 1, true) ~= nil)))
	end
	print("QQ TP SR lines " .. select(2, t:gsub("\n", "\n")) .. " porto=" .. tostring(t:find("porto", 1, true) ~= nil))
else
	print("QQ TP SR missing")
end
local mc = workspace:FindFirstChild("MapMusic") and workspace.MapMusic:FindFirstChild("MusicClient")
if mc then
	local n = 0
	for line in (src(mc) .. "\n"):gmatch("(.-)\n") do
		n += 1
		if line:find("AREAS", 1, true) or line:find("{id = ", 1, true) or line:find("local function areaAt", 1, true) or line:find("switchTo(nil)", 1, true) then print(string.format("QQ TP MC %d: %s", n, line:gsub("^%s+", ""):sub(1, 160))) end
	end
end
local bc = workspace:FindFirstChild("Boat") and workspace.Boat:FindFirstChild("BoatClient")
if bc then
	local n = 0
	for line in (src(bc) .. "\n"):gmatch("(.-)\n") do
		n += 1
		if line:find("landed", 1, true) or line:find("seaY", 1, true) and line:find("if ", 1, true) then print(string.format("QQ TP BC %d: %s", n, line:gsub("^%s+", ""):sub(1, 160))) end
	end
end
print("QQ TP Travel exists=" .. tostring(workspace:FindFirstChild("Travel") ~= nil) .. " Spawn_porto=" .. tostring(workspace:FindFirstChild("Spawn_porto") ~= nil) .. " SpawnDais_porto=" .. tostring(workspace:FindFirstChild("SpawnDais_porto") ~= nil))
local n = 0
for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("SpawnLocation") then n += 1 end end
print("QQ TP SpawnLocations=" .. n .. " Boundary.Need=" .. tostring(workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need")))
print("QQ TP DONE")
