#!/usr/bin/env python3
"""Builds tools/japan/garden/garden_look2.lua (job 125, LOOK TEST 2 - the waterway): everything from look test 1 that Shannon approved
(the taiko bridge, torii, lanterns, pine, rocks, stepping slabs, waterfall; NOT the orange maples - "the orange trees clash") plus the
waterway fix ("the waterway where the bridge is need SERIOUS fixing", "the edge of this waterway looks unfinished", "this walkway is
lifted right off the ground"), and the KOI POND closing the stream's north end (Shannon via runner 7: "waterfall -> natural stream ->
KOI POND, not to the sea", "stepping stones and lanterns around it", rail / station / arrival court untouched). Kit =
ServerStorage.JapanGardenKit: out1's nine Models + out2's canal_edge, canal_edge_b, reeds, pond_rim, stepstone, lilies, and the koi:
Shannon's Meshy koi as a Model "koi_meshy" when she has imported it, else out2's koi.fbx. Placed by bounding box (out1/out2
pieces.json + pieces_2b.json). Run from the repo root."""
import json, pathlib, re, ast
HERE = pathlib.Path(__file__).resolve().parent
info = json.load(open(HERE / "out1/pieces.json")); info.update(json.load(open(HERE / "out2/pieces.json"))); info.update(json.load(open(HERE / "out2/pieces_2b.json")))
COL = {}
for g in ("gen_garden1.py", "gen_garden2.py", "gen_garden2b.py"):
    COL.update(ast.literal_eval(re.search(r"COL = (\{.*?\})\n", (HERE / g).read_text(), re.S).group(1)))
def v3(v): return "Vector3.new(%s, %s, %s)" % tuple(v)
bb = ",\n".join('\t["%s"] = {min = %s, max = %s}' % (k, v3(v["min"]), v3(v["max"])) for k, v in info.items())
cols = ",\n".join('\t%s = Color3.new(%s, %s, %s)' % (k, *v) for k, v in COL.items())
lua = r'''-- garden_look2.lua (job 125, LOOK TEST 2: the waterway; a play-test PREVIEW first, then Studio EDIT on her word; re-runnable).
-- 1. finds the canal from LanternStreet's two "Canal stone bank" parts; 2. TERRAIN: the canal's water lowered from 1.3 to -0.6 (a garden
-- stream sunk into the lawn), terrain rock poking above the new water cleared, no water left under the old banks; 3. RETIRES to
-- HudBackup.MomijiGardenReplaced: both concrete banks, the black JP_Canal_Rocks_* strips, the three "Canal footbridge"s, their "approach
-- steps", the "Canal weir"; 4. LEVELS every floating "Walkway" part (bottom > 0.4) flat on the lawn, top at 0.2 (old CFrame kept as an
-- attribute); 5. PLACES only imported meshes: a taiko bridge at each old footbridge, the stone canal edge both sides (two block
-- patterns alternating), rocks and reed clumps along it, the waterfall at the canal's south end, and look test 1's torii, pine, four lit
-- lanterns and stepping slabs; 6. the KOI POND at the north end: the channel's bed raised to about -3 all along (a garden stream, not a
-- 10-deep trough), a half-round stone rim with its moss lip closing the last 12.5 of the channel (its tails meet the edge segments), seven
-- stepping stones across, six koi swimming slow circles (Shannon's Meshy koi "koi_meshy" when in the kit, else out2's koi.fbx; a Client
-- script moves them), lily pads, three lanterns round it. The "River end foundation closure" blocks are lowered 0.3 flush with the lawn.
-- No parts are built. Output "QQ GARDEN2".
local SS = game:GetService("ServerStorage")
local T = workspace.Terrain
local KIT = SS:FindFirstChild("JapanGardenKit")
local J = workspace:FindFirstChild("JapanMap")
if not (KIT and J) then print("QQ GARDEN2 ABORT: ServerStorage.JapanGardenKit or workspace.JapanMap missing") return end
for _, n in ipairs({"torii", "lantern", "bridge", "pine", "rocks", "slabs", "waterfall", "canal_edge", "canal_edge_b", "reeds", "pond_rim", "stepstone", "lilies"}) do
	if not KIT:FindFirstChild(n) then print("QQ GARDEN2 ABORT: the kit has no Model '" .. n .. "' - import tools/japan/garden/out2/*.fbx too") return end
end
local KOI = KIT:FindFirstChild("koi_meshy") or KIT:FindFirstChild("koi")
if not KOI then print("QQ GARDEN2 ABORT: the kit has neither 'koi_meshy' (Shannon's Meshy koi) nor 'koi' (out2/koi.fbx)") return end
local MESHY_KOI = KOI.Name == "koi_meshy"
local MESHY_KOI_FACING = CFrame.Angles(0, 0, 0)      -- which way the Meshy fish points: identity = its -Z (Roblox forward). If they swim backwards or sideways, set e.g. CFrame.Angles(0, math.rad(180), 0) or math.rad(90)
print("QQ GARDEN2 koi: " .. (MESHY_KOI and "Shannon's Meshy koi (kit 'koi_meshy')" or "out2/koi.fbx (no 'koi_meshy' in the kit)"))
local BB = {
@@BB@@
}
local COL = {
@@COL@@
}
local function colourKey(name)
	local n = name:gsub("^[ABP]_", ""):gsub("^Rock%d_", "Rock_"):gsub("^Step%d_", "Step_")
	if n:match("^Slab%d") then return "Slab_Stone" end
	return n
end
local SOLID = {Bridge_Deck = true, Bridge_Red = true, Bridge_Stone = true, Torii_Red = true, Torii_Black = true, Lantern_Stone = true, Rock_Grey = true,
	Rock_Moss = true, Slab_Stone = true, Fall_Rock = true, Fall_Moss = true, Pine_Bark = true, Edge_Stone = true, Edge_Moss = true, Step_Stone = true, Step_Moss = true}
-- ---------- 1. the canal ----------
local banks = {}
for _, d in ipairs(J:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Canal stone bank" then table.insert(banks, d) end end
if #banks ~= 2 then print("QQ GARDEN2 ABORT: expected 2 'Canal stone bank' parts, found " .. #banks) return end
table.sort(banks, function(a, b) return a.Position.X < b.Position.X end)
local WEST = banks[1].Position.X + banks[1].Size.X / 2                      -- the water-side faces
local EAST = banks[2].Position.X - banks[2].Size.X / 2
local CX = (WEST + EAST) / 2
local Z1 = math.min(banks[1].Position.Z - banks[1].Size.Z / 2, banks[2].Position.Z - banks[2].Size.Z / 2)
local Z2 = math.max(banks[1].Position.Z + banks[1].Size.Z / 2, banks[2].Position.Z + banks[2].Size.Z / 2)
local RF = 12.5                                                              -- the pond rim's water-face radius (the channel is 25 wide)
local ZC = Z1 + 8 + 8 * math.floor((Z2 + 1 - RF - Z1 - 8) / 8)                -- the pond's centre line: the arc reaches Z2 or so, the tails (8) meet the edge segments without a gap
print(string.format("QQ GARDEN2 canal: water faces x %.1f / %.1f (centre %.1f), z %.1f .. %.1f; the koi pond's centre line z %.0f, its rim's apex z %.1f", WEST, EAST, CX, Z1, Z2, ZC, ZC + RF))
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Momiji garden look test 2") end)
-- ---------- 2. the terrain: the water down to -0.6, the bed up to about -3, rock above the water cleared, no water under the old banks ----------
-- (Roblox draws a row's surface at (its top - 2) + 4 x occupancy: the -4..0 row at 0.35 = y -0.6, the -8..-4 row at 0.75 = y -3)
local WL = -0.6
local tw, tr, tb, tbed = 0, 0, 0, 0
do
	local x0, x1 = math.floor((WEST - 8) / 4) * 4, math.ceil((EAST + 8) / 4) * 4
	local zA, zB = math.floor((Z1 - 2) / 4) * 4, math.ceil((Z2 + 2) / 4) * 4
	for zs = zA, zB - 1, 64 do
		local r = Region3.new(Vector3.new(x0, -8, zs), Vector3.new(x1, 8, math.min(zs + 64, zB)))
		local ch = T:ReadVoxelChannels(r, 4, {"SolidMaterial", "SolidOccupancy", "LiquidOccupancy"})
		local SM, SO, LO = ch.SolidMaterial, ch.SolidOccupancy, ch.LiquidOccupancy
		for ix = 1, #SO do
			local x = x0 + (ix - 0.5) * 4
			local inCanal = x > WEST and x < EAST
			for iy = 1, #SO[ix] do
				local y0 = -8 + (iy - 1) * 4
				for iz = 1, #SO[ix][iy] do
					if inCanal then
						if y0 >= 0 then
							if LO[ix][iy][iz] > 0 then LO[ix][iy][iz] = 0; tw += 1 end
							if SO[ix][iy][iz] > 0 then SO[ix][iy][iz] = 0; tr += 1 end
						elseif y0 == -4 then
							LO[ix][iy][iz] = 0.35                               -- the new surface at -0.6
							if SO[ix][iy][iz] > 0.2 then SO[ix][iy][iz] = 0.2; tr += 1 end   -- (her "crystal rocks" in the pool: down to -1.2, under the water)
						elseif y0 == -8 then
							if SO[ix][iy][iz] < 0.75 then SO[ix][iy][iz] = 0.75; SM[ix][iy][iz] = Enum.Material.Ground; tbed += 1 end   -- the bed up to -3
							LO[ix][iy][iz] = 0
						end
					elseif y0 >= -4 and LO[ix][iy][iz] > 0 then
						LO[ix][iy][iz] = 0; tb += 1                          -- nothing wet under the new stone edge
					end
				end
			end
		end
		T:WriteVoxelChannels(r, 4, {SolidMaterial = SM, SolidOccupancy = SO, LiquidOccupancy = LO})
	end
end
print(string.format("QQ GARDEN2 terrain: water lowered to %.1f (%d water cells above it cleared), %d rock cells cut down, %d wet cells under the banks dried, the bed raised to -3 in %d cells (Ground)", WL, tw, tr, tb, tbed))
-- ---------- 3. retire the trough, the black strips, the old bridges and steps, the weir ----------
local replaced = hb:FindFirstChild("MomijiGardenReplaced") or Instance.new("Folder"); replaced.Name = "MomijiGardenReplaced"; replaced.Parent = hb
local retire, bridgesZ = {}, {}
local function near(cf, r) return math.abs(cf.X - CX) < r end
for _, d in ipairs(J:GetDescendants()) do
	if d.Parent and not d:IsDescendantOf(replaced) then
		local ok, cf = pcall(function() return d:IsA("Model") and d:GetPivot() or (d:IsA("BasePart") and d.CFrame) end)
		if ok and cf then
			if d.Name == "Canal stone bank" or (d:IsA("BasePart") and d.Name:match("^JP_Canal_Rocks")) then table.insert(retire, d)
			elseif d:IsA("Model") and d.Name == "Canal footbridge" then table.insert(retire, d); table.insert(bridgesZ, cf.Z)
			elseif d.Name:lower():find("approach steps") and near(cf, 30) then table.insert(retire, d)
			elseif d.Name == "Canal weir" then table.insert(retire, d)
			elseif d:IsA("BasePart") and (d.Name == "Shallow river bank" or d.Name:lower():find("shore ramp")) and near(cf, 25) and cf.Y + d.Size.Y / 2 > WL - 0.4 then table.insert(retire, d) end
		end
	end
end
local seen = {}
for _, d in ipairs(retire) do
	local up = d.Parent; local inner = false
	while up and up ~= J do if seen[up] then inner = true end; up = up.Parent end
	if not inner then seen[d] = true; d:SetAttribute("GardenWasIn", d.Parent:GetFullName()); d.Parent = replaced end
end
local nret = 0; for _ in pairs(seen) do nret += 1 end
table.sort(bridgesZ)
print(string.format("QQ GARDEN2 retired %d (banks, black strips, footbridges at z %s, approach steps, the weir, bank supports above the new water) -> HudBackup.MomijiGardenReplaced", nret,
	(function() local t = {}; for _, z in ipairs(bridgesZ) do table.insert(t, string.format("%.0f", z)) end; return table.concat(t, " / ") end)()))
local lowered = 0
for _, d in ipairs(J:GetDescendants()) do
	if d:IsA("BasePart") and d.Name == "River end foundation closure" and near(d.CFrame, 30) and d:GetAttribute("GardenOldCF") == nil then
		d:SetAttribute("GardenOldCF", d.CFrame); d.CFrame = d.CFrame - Vector3.new(0, d.Position.Y + d.Size.Y / 2, 0); lowered += 1   -- its top flush with the lawn at 0
	end
end
print(string.format("QQ GARDEN2 'River end foundation closure' blocks lowered flush with the lawn: %d", lowered))
-- ---------- 4. the floating walkways, flat on the lawn ----------
local levelled = 0
for _, d in ipairs(J:GetDescendants()) do
	if d:IsA("BasePart") and d.Name == "Walkway" and d.Size.Y < 4 and near(d.CFrame, 60) and d.Position.Z > Z1 - 20 and d.Position.Z < Z2 + 10 then   -- (the station's walkway at z 139 is not touched)
		local bottom = d.Position.Y - d.Size.Y / 2
		local tilt = math.deg(math.acos(math.clamp(d.CFrame.UpVector.Y, -1, 1)))
		if bottom > 0.4 or tilt > 0.8 then
			if d:GetAttribute("GardenOldCF") == nil then d:SetAttribute("GardenOldCF", d.CFrame) end
			local look = d.CFrame.LookVector; local yaw = math.atan2(-look.X, -look.Z)
			d.CFrame = CFrame.new(d.Position.X, 0.2 - d.Size.Y / 2, d.Position.Z) * CFrame.Angles(0, yaw, 0)
			levelled += 1
		end
	end
end
print(string.format("QQ GARDEN2 canal walkways levelled flat on the lawn (top 0.2): %d", levelled))
-- ---------- 5. the meshes ----------
local old = J:FindFirstChild("MomijiGarden")
if old then local n = 1; while hb:FindFirstChild("MomijiGarden_pre_" .. n) do n += 1 end; old.Name = "MomijiGarden_pre_" .. n; old.Parent = hb end
local G = Instance.new("Folder"); G.Name = "MomijiGarden"; G.Parent = J
local made, meshes, missing = 0, 0, {}
local function dress(m)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local key = colourKey(p.Name)
			p.Anchored = true; p.Material = Enum.Material.SmoothPlastic; p.CastShadow = true
			if COL[key] then p.Color = COL[key] else table.insert(missing, p.Name) end
			p.CanCollide = SOLID[key] == true; p.CanQuery = p.CanCollide; p.CanTouch = false
			if p:IsA("MeshPart") and (key == "Bridge_Deck" or key == "Slab_Stone" or key == "Edge_Moss" or key == "Edge_Stone") then pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end) end
			if key == "Lantern_Paper" then
				p.Material = Enum.Material.Neon
				local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 214, 150); l.Range = 12; l.Brightness = 1.2; l.Shadows = false; l.Parent = p
			elseif key == "Fall_Water" then p.Material = Enum.Material.Glass; p.Transparency = 0.25; p.CastShadow = false; pcall(function() p.DoubleSided = true end)
			elseif key == "Fall_Foam" then p.Transparency = 0.15; p.CastShadow = false
			elseif key == "Reed_Leaf" or key == "Reed_Flower" or key == "Lily_Flower" then p.CastShadow = false; pcall(function() p.DoubleSided = true end)
			elseif key:sub(1, 4) == "Koi_" then p.CastShadow = false end
			meshes += 1
		end
	end
end
local function place(kitName, at, yaw, group, label, scale, parent)
	local src = KIT:FindFirstChild(kitName)
	if not src then table.insert(missing, kitName) return nil end
	local m
	if group then
		m = Instance.new("Model")
		for _, p in ipairs(src:GetDescendants()) do if p:IsA("BasePart") and (p.Name == group or p.Name:sub(1, #group + 1) == group .. "_") then p:Clone().Parent = m end end
		if #m:GetChildren() == 0 then table.insert(missing, kitName .. "/" .. group) return nil end
	else m = src:Clone() end
	m.Name = label or kitName
	local box = BB[group and (kitName .. "/" .. group) or kitName]
	local cf = m:GetBoundingBox()
	m.WorldPivot = CFrame.new(cf.Position - (box.min + box.max) / 2)
	if scale and scale ~= 1 then pcall(function() m:ScaleTo(scale) end) end
	m:PivotTo(CFrame.new(at) * CFrame.Angles(0, math.rad(yaw or 0), 0))
	dress(m); m.Parent = parent or G; made += 1
	return m
end
local rnd = Random.new(1001)
-- the bridges, on the lawn at each old crossing
if #bridgesZ == 0 then bridgesZ = {-215} end
local function nearBridge(z, r) for _, bz in ipairs(bridgesZ) do if math.abs(z - bz) < r then return true end end; return false end
for i, bz in ipairs(bridgesZ) do place("bridge", Vector3.new(CX, 0.0, bz), 0, nil, "TaikoBridge" .. i) end
-- the stone edge, both sides, alternating patterns
local EF = Instance.new("Folder"); EF.Name = "CanalEdge"; EF.Parent = G
local k = 0
for z = Z1 + 4, ZC - 8 - 3.99, 8 do
	k += 1
	place(k % 2 == 0 and "canal_edge" or "canal_edge_b", Vector3.new(WEST - 0.2, 0, z), 0, nil, "EdgeW" .. k, 1, EF)
	place(k % 2 == 1 and "canal_edge" or "canal_edge_b", Vector3.new(EAST + 0.2, 0, z), 180, nil, "EdgeE" .. k, 1, EF)
end
-- rocks and reeds along the edge (none on the bridges)
local RF = Instance.new("Folder"); RF.Name = "EdgeRocksAndReeds"; RF.Parent = G
local nr, nd = 0, 0
for z = Z1 + 6, ZC - 12, 9 do
	if not nearBridge(z, 8) then
		for _, side in ipairs({-1, 1}) do
			if rnd:NextNumber() < 0.7 then
				local face = side < 0 and WEST or EAST
				local inWater = rnd:NextNumber() < 0.45
				local x = face - side * (inWater and rnd:NextNumber(0.6, 1.8) or -rnd:NextNumber(0.4, 1.6))
				place("rocks", Vector3.new(x, inWater and (WL - 0.3) or 0.05, z + rnd:NextNumber(-3, 3)), rnd:NextInteger(0, 359), "Rock" .. rnd:NextInteger(1, 3), "EdgeRock", rnd:NextNumber(0.7, 1.4), RF)
				nr += 1
			end
		end
	end
end
for z = Z1 + 10, ZC - 12, 16 do
	if not nearBridge(z, 9) then
		local side = (math.floor(z / 16) % 2 == 0) and -1 or 1
		local face = side < 0 and WEST or EAST
		place("reeds", Vector3.new(face - side * 0.9, WL, z + rnd:NextNumber(-2, 2)), rnd:NextInteger(0, 359), nil, "Reeds", rnd:NextNumber(0.9, 1.2), RF)
		nd += 1
	end
end
-- ---------- 6. the koi pond at the north end ----------
local PF = Instance.new("Folder"); PF.Name = "KoiPond"; PF.Parent = G
place("pond_rim", Vector3.new(CX, 0, ZC), 0, nil, "PondRim", 1, PF)
local nstep = 0
for i = 0, 6 do                                                              -- seven stepping stones across, west lawn to east lawn, tops at -0.1
	place("stepstone", Vector3.new(WEST + 2 + 3.5 * i, -0.1, ZC + 4 + (i % 2 == 0 and -0.8 or 0.8)), rnd:NextInteger(0, 359), "Step" .. (i % 3 + 1), "SteppingStone" .. (i + 1), 1, PF)
	nstep += 1
end
for i, d in ipairs({{-19, 9}, {19, 9}, {0, 21}}) do place("lantern", Vector3.new(CX + d[1], 0, ZC + d[2]), 0, nil, "PondLantern" .. i, 1, PF) end
for i, d in ipairs({{7.5, 7, 0}, {-7, -4, 120}, {8, -7, 250}}) do place("lilies", Vector3.new(CX + d[1], WL, ZC + d[2]), d[3], nil, "Lilies" .. i, rnd:NextNumber(0.85, 1.1), PF) end
-- the koi: each a Model with its pivot at its centre, FORWARD = the pivot's -Z; the swim script moves it round a circle (attributes)
local koiNames = MESHY_KOI and {KOI.Name} or {"Koi_Orange", "Koi_White", "Koi_Gold"}
local nkoi = 0
for i, c in ipairs({{0, -6, 3.2}, {4, 2, 2.4}, {-5, 3, 2.8}, {6, -2, 2.0}, {-2, 8, 2.6}, {-7, -5, 1.8}}) do
	local m
	if MESHY_KOI then
		m = KOI:Clone(); m.Name = "Koi" .. i
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false end end
		local cf, size = m:GetBoundingBox()
		local long = math.max(size.X, size.Y, size.Z)
		if long > 0 then pcall(function() m:ScaleTo(2.4 / long) end) end
		cf = m:GetBoundingBox()
		m.WorldPivot = CFrame.new(cf.Position) * MESHY_KOI_FACING
		m.Parent = PF; made += 1
	else
		m = place("koi", Vector3.new(CX, WL - 0.6, ZC), 0, koiNames[(i - 1) % 3 + 1], "Koi" .. i, rnd:NextNumber(0.85, 1.15), PF)
		if m then local cf = m:GetBoundingBox(); m.WorldPivot = CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(-90), 0) end   -- (built along +x: its -Z is then the head)
	end
	if m then
		m:SetAttribute("SwimCX", CX + c[1]); m:SetAttribute("SwimCZ", ZC + c[2]); m:SetAttribute("SwimR", c[3]); m:SetAttribute("SwimY", WL - 0.7)
		m:SetAttribute("SwimSpeed", (i % 2 == 0 and 1 or -1) * rnd:NextNumber(0.18, 0.3)); m:SetAttribute("SwimPhase", rnd:NextNumber(0, 6.28))
		m:PivotTo(CFrame.new(CX + c[1] + c[3], WL - 0.7, ZC + c[2]))
		nkoi += 1
	end
end
local swim = Instance.new("Script"); swim.Name = "KoiSwim"; swim.RunContext = Enum.RunContext.Client
swim.Source = [==[
-- the koi swim slow circles (attributes SwimCX/SwimCZ/SwimR/SwimY/SwimSpeed/SwimPhase on each Koi Model); client-side, synced by server time
local RunService = game:GetService("RunService")
local folder = script.Parent
RunService.Heartbeat:Connect(function()
	local t = workspace:GetServerTimeNow()
	for _, m in ipairs(folder:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("SwimR") then
			local cx, cz, r = m:GetAttribute("SwimCX"), m:GetAttribute("SwimCZ"), m:GetAttribute("SwimR")
			local a = m:GetAttribute("SwimPhase") + t * m:GetAttribute("SwimSpeed")
			local wob = math.sin(t * 1.7 + m:GetAttribute("SwimPhase") * 3)
			local pos = Vector3.new(cx + r * math.cos(a), m:GetAttribute("SwimY") + 0.12 * wob, cz + r * math.sin(a))
			local dir = m:GetAttribute("SwimSpeed") > 0 and 1 or -1
			local tangent = Vector3.new(-math.sin(a), 0, math.cos(a)) * dir
			m:PivotTo(CFrame.lookAt(pos, pos + tangent) * CFrame.Angles(0, 0, 0.12 * wob))
		end
	end
end)
]==]
swim.Parent = PF
print(string.format("QQ GARDEN2 koi pond: rim at z %.0f (apex %.1f), %d stepping stones, %d koi (%s), 3 lanterns, 3 lily clusters, KoiSwim client script", ZC, ZC + RF, nstep, nkoi, MESHY_KOI and "Meshy" or "koi.fbx"))
-- look test 1's approved pieces, by the garden bridge (the southernmost crossing)
local BZ = bridgesZ[1]
place("waterfall", Vector3.new(CX, WL - 0.3, Z1 - 1.5), 0, nil, "Waterfall")
place("torii", Vector3.new(CX - 43, 0, BZ), 90, nil, "Torii")
place("pine", Vector3.new(CX + 28, 0, BZ + 13), 200, nil, "BlackPine")
for i, d in ipairs({{-24, 6}, {-24, -6}, {24, 6}, {24, -6}}) do place("lantern", Vector3.new(CX + d[1], 0, BZ + d[2]), 0, nil, "StoneLantern" .. i) end
for i, s in ipairs({{23, -9, "Slab1"}, {25.5, -13.5, "Slab2"}, {23.5, -18, "Slab3"}, {26, -22.5, "Slab1"}}) do place("slabs", Vector3.new(CX + s[1], 0.02, BZ + s[2]), i * 37, s[3], "Slab" .. i) end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Momiji garden look test 2") end)
if #missing > 0 then print("QQ GARDEN2 missing or uncoloured: " .. table.concat(missing, ", ")) end
print(string.format("QQ GARDEN2 DONE: MomijiGarden - %d pieces (%d bridges, %d edge segments, %d rocks, %d reed clumps, the koi pond), %d meshes; no parts built", made, #bridgesZ, k * 2, nr, nd, meshes))
'''
lua = lua.replace("@@BB@@", bb).replace("@@COL@@", cols)
assert "@@" not in lua
(HERE / "garden_look2.lua").write_text(lua, encoding="utf-8")
print("garden_look2.lua", len(lua.encode()), "bytes")
