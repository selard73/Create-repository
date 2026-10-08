-- give44_probe1 v1: READ-ONLY. (a) SquirrelSetup: how a find is recorded + what is sent to the client + any Studio/test
-- hooks; (b) remotes/bindables in ReplicatedStorage; (c) which scripts read the Found_* / FoundIds / SquirrelsFound
-- attributes (the HUD, the gates, the boat); (d) a coarse material + height map of the plunge pool and its shores.
local function src(s) local ok, t = pcall(function() return s.Source end); return ok and t or nil end
local function lines(t) local out = {}; for line in (t .. "\n"):gmatch("(.-)\n") do out[#out + 1] = line end; return out end
local setup = workspace.SquirrelScripts:FindFirstChild("SquirrelSetup")
local ss = setup and src(setup)
if ss then
	local L = lines(ss)
	print("QQ G4 SquirrelSetup " .. #L .. " lines; printing 140-240 and 325-381")
	local function dump(a, b) for n = a, math.min(b, #L) do print(string.format("QQ G4 %d: %s", n, L[n]:gsub("^%s+", ""):sub(1, 150))) end end
	dump(140, 240)
	dump(325, 381)
	local keys = {"isstudio", "studio", "remote", "bindable", "datastore", "owner", "debug", "cheat", "unlock", "giveall", "require"}
	local n = 0
	for i, line in ipairs(L) do
		local l = line:lower()
		for _, k in ipairs(keys) do
			if l:find(k, 1, true) then print(string.format("QQ G4 key[%s] %d: %s", k, i, line:gsub("^%s+", ""):sub(1, 140))); n += 1; break end
		end
		if n >= 40 then break end
	end
end
local rs = game:GetService("ReplicatedStorage")
local names = {}
for _, c in ipairs(rs:GetChildren()) do names[#names + 1] = c.Name .. "[" .. c.ClassName .. "]" end
for i = 1, #names, 8 do print("QQ G4 RS: " .. table.concat(names, ", ", i, math.min(i + 7, #names))) end
-- who reads the find attributes
local roots = {workspace, game:GetService("ServerScriptService"), game:GetService("StarterGui"), game:GetService("StarterPlayer"), rs, game:GetService("ServerStorage")}
local hits = 0
for _, root in ipairs(roots) do
	for _, d in ipairs(root:GetDescendants()) do
		if (d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript")) and d ~= setup then
			local t = src(d)
			if t and (t:find("SquirrelsFound", 1, true) or t:find("FoundIds", 1, true) or t:find("Found_", 1, true) or t:find("/44", 1, true) or t:find("FoundCount", 1, true)) then
				local shown = 0
				for i, line in ipairs(lines(t)) do
					if line:find("SquirrelsFound", 1, true) or line:find("FoundIds", 1, true) or line:find("Found_", 1, true) or line:find("/44", 1, true) or line:find("FoundCount", 1, true) then
						print(string.format("QQ G4 reader %s %d: %s", d:GetFullName(), i, line:gsub("^%s+", ""):sub(1, 130)))
						shown += 1; hits += 1
						if shown >= 5 then break end
					end
				end
			end
		end
		if hits > 60 then break end
	end
end
-- the pool and its shores
local SEA_Y = -52.9
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {workspace.Terrain}; rp.IgnoreWater = false
local matc = {[Enum.Material.Water] = "w", [Enum.Material.Grass] = "g", [Enum.Material.LeafyGrass] = "l", [Enum.Material.Sand] = "s", [Enum.Material.Sandstone] = "S", [Enum.Material.Rock] = "r", [Enum.Material.Ground] = "d", [Enum.Material.Mud] = "m", [Enum.Material.Basalt] = "b", [Enum.Material.Slate] = "t"}
local X0, X1, Z0, Z1, STEP = 100, 280, -556, -700, 6
local header = {}
for x = X0, X1, STEP do header[#header + 1] = (x % 30 == 0) and string.format("%3d", x):sub(-1) or " " end
print("QQ G4 map cols x=" .. X0 .. ".." .. X1 .. " step " .. STEP .. " (water w grass g leafy l sand s sandstone S rock r ground d none .)")
for z = Z0, Z1, -STEP do
	local row, hrow = {}, {}
	for x = X0, X1, STEP do
		local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -140, 0), rp)
		if hit then
			row[#row + 1] = matc[hit.Material] or "o"
			local h = hit.Position.Y - SEA_Y
			hrow[#hrow + 1] = (hit.Material == Enum.Material.Water) and "~" or (h < 0 and "-" or tostring(math.min(9, math.floor(h / 3))))
		else
			row[#row + 1] = "."; hrow[#hrow + 1] = "."
		end
	end
	print(string.format("QQ G4 z%5d |%s| |%s|", z, table.concat(row), table.concat(hrow)))
end
print("QQ G4 DONE")
