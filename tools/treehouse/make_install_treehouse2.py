#!/usr/bin/env python3
"""Builds tools/treehouse/install_treehouse2.lua (job 111): the HOMEBASE TREEHOUSE moves into a hollow cut into the bank behind the
zip line tower's left (Shannon: "put it in a corner to the left of the zip line tower ... clear a space ... an open area clearly
designated"; her answer to the edge question: "Move the edge out"). What the installer does, in order:
 1. the back rim: terrain Grass filled from z 62 to 84 (x -52..16) up to y 9, so the hollow has a bank behind it where the ridge used
    to fall away to nothing (the terrain ends at z ~75-80);
 2. the floor: terrain Grass up to y 0.1 under the whole hollow (the ridge's foot dips to -3.8 at the edge);
 3. the bowl: stepped cylinders of air cut into the ridge above y 0.1 (radius 27 at the floor, narrowing with height) centred on the site;
 4. the dirt: a disk of terrain Ground (radius 15) at the floor round the oak - "please excuse the dirt";
 5. the edge: the forest's invisible north wall (found by search - two folders are named Boundary) is split either side of the
    hollow's mouth, and a U of the same wall (same height, transparency, collision) goes round the hollow's back and sides;
 6. the dressing pines on the site go to HudBackup.TreehouseCleared_n (never squirrels, walls, the tower);
 7. the oak (taller: the trunk rises through the roof), a ring of ten stones at radius 15, and the Treehouse folder with
    TreehouseServer + TreehouseClient2 (the roomier house with the balcony, the sign's three states, the first-piece reveal);
 8. TWELVE pieces all in the forest: p1 in sight of the spawn, p2..p12 each beside a forest squirrel.
Re-runnable: the terrain steps are idempotent, the wall split is skipped when the U already exists, the old Treehouse folder goes to
HudBackup. Its body also runs as a play-test PREVIEW (terrain and all - discarded on stop). Run from the repo root."""
import pathlib, json, math
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "src/TreehouseServer.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src/TreehouseClient2.lua").read_text(encoding="utf-8")
for s in (SERVER, CLIENT): assert "]===]" not in s
SPAWN = (3, 1)
SITE = {"x": -18, "z": 47}                                   # the hollow's centre, behind the tower's left (the tower at (-23, 5), the edge at z 25)
SITE["yaw"] = round(math.degrees(math.atan2(SPAWN[0] - SITE["x"], SPAWN[1] - SITE["z"])), 1)   # local +z faces the spawn (the hollow's mouth)
PIECES = [
    {"id": "p1",  "x": 14,  "z": -8,   "kind": "planks",   "yaw": 30},    # in sight of the spawn - the first piece, the reveal
    {"id": "p2",  "x": -10, "z": -42,  "kind": "rope",     "yaw": 0},     # by the surfing squirrel
    {"id": "p3",  "x": 22,  "z": -46,  "kind": "planks",   "yaw": 70},    # by the fairy squirrel
    {"id": "p4",  "x": 55,  "z": -14,  "kind": "shingles", "yaw": 15},    # by the parachute squirrel
    {"id": "p5",  "x": -12, "z": -88,  "kind": "planks",   "yaw": 100},   # by Baking Betty
    {"id": "p6",  "x": 86,  "z": -36,  "kind": "rope",     "yaw": 40},    # by the super squirrel
    {"id": "p7",  "x": 58,  "z": -108, "kind": "shingles", "yaw": 0},     # by the scientist
    {"id": "p8",  "x": 76,  "z": -118, "kind": "planks",   "yaw": 55},    # by the ski squirrel
    {"id": "p9",  "x": 36,  "z": -131, "kind": "lantern",  "yaw": 20},    # by the ballerina
    {"id": "p10", "x": 2,   "z": -144, "kind": "planks",   "yaw": 80},    # by Gordo
    {"id": "p11", "x": -37, "z": -138, "kind": "shingles", "yaw": 10},    # by the buccaneer
    {"id": "p12", "x": 72,  "z": -148, "kind": "lantern",  "yaw": 60},    # by the rainy-day squirrel
]
assert len({p["id"] for p in PIECES}) == 12
pieces_json = json.dumps(PIECES, separators=(",", ":")); site_json = json.dumps(SITE, separators=(",", ":"))
for s in (pieces_json, site_json): assert "]==]" not in s
TEMPLATE = '''-- install_treehouse2.lua (Studio EDIT; re-runnable; its body also runs as a play-test PREVIEW - terrain included, discarded on stop).
-- Job 111: the HOMEBASE TREEHOUSE in a hollow cut into the bank behind the zip line tower's left (Shannon, Oct 15 2026: "put it in a
-- corner to the left of the zip line tower ... clear a space ... an open area clearly designated for the treehouse"; "Move the edge out").
-- Terrain: a back rim, a floor, a stepped bowl, a dirt disk; the invisible north edge split round the hollow with a U of wall; the
-- dressing pines on the site to HudBackup; the oak, ten stones, the sign; TreehouseServer (@@SLEN@@) + TreehouseClient2 (@@CLEN@@);
-- twelve pieces all in the forest (p1 in sight of the spawn, the rest beside squirrels). Everything logged for undo in
-- HudBackup.Treehouse2_log. No DataStore, no publish. Output "QQ TREE".
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local T = workspace.Terrain
local SERVER = [===[
@@SERVER@@]===]
local CLIENT = [===[
@@CLIENT@@]===]
do
	for _, s in ipairs({{"TreehouseServer", SERVER}, {"TreehouseClient2", CLIENT}}) do
		local ok, f, err = pcall(function() return loadstring(s[2]) end)
		if ok and not f then print("QQ TREE ABORT: " .. s[1] .. " does not compile: " .. tostring(err)) return end
	end
end
local SITE = HttpService:JSONDecode([==[@@SITE@@]==])
local PIECES = HttpService:JSONDecode([==[@@PIECES@@]==])
local FLOOR = 0.1
local log = {}
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Treehouse2") end)
local SX, SZ = SITE.x, SITE.z
-- ---------- 1-4: the terrain ----------
-- the back rim (the ridge fell to nothing past z ~75): grass up to y 9 from z 62 to 84, so the hollow has a bank behind it
T:FillBlock(CFrame.new((SX - 34 + SX + 34) / 2, (9 - 14) / 2, 73), Vector3.new(68, 23, 22), Enum.Material.Grass)
-- the floor: grass up to the forest's level under the whole hollow (the ridge's foot dips below it near the edge)
T:FillCylinder(CFrame.new(SX, (FLOOR - 8) / 2, SZ), 8 + FLOOR, 29, Enum.Material.Grass)
-- the bowl: air above the floor, narrowing with height (the crest is y 10-14; 17 clears it)
for _, step in ipairs({{0, 4, 27}, {4, 8, 25.5}, {8, 12, 24}, {12, 17, 22.5}}) do
	local y1, y2, r = FLOOR + step[1], FLOOR + step[2], step[3]
	T:FillCylinder(CFrame.new(SX, (y1 + y2) / 2, SZ), y2 - y1, r, Enum.Material.Air)
end
-- the dirt round the oak
T:FillCylinder(CFrame.new(SX, FLOOR - 1, SZ), 2.2, 15, Enum.Material.Ground)
print(string.format("QQ TREE terrain: rim to y 9 behind z 62..84, floor at %.1f, a bowl of radius 27 cut to y 17, dirt radius 15, centred (%d, %d)", FLOOR, SX, SZ))
-- ---------- 5: the edge ----------
local edge
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("BasePart") and p.Name == "Wall" and p.Size.X > 200 and math.abs(p.Position.Z - 25) < 1.5 and p.Size.Y > 40 then edge = p break end
end
if not edge then print("QQ TREE edge: the north wall (Wall, ~233 x 1 at z 25) was NOT found - the hollow is open to the bank; tell the cloud thread") end
local MOUTH_L, MOUTH_R, BACK = SX - 30, SX + 30, SZ + 23                 -- the mouth's x range along the old edge, the U's back z
if edge and not edge.Parent:FindFirstChild("HollowWallBack") then
	local wf = edge.Parent
	local y, h = edge.Position.Y, edge.Size.Y
	local x1, x2 = edge.Position.X - edge.Size.X / 2, edge.Position.X + edge.Size.X / 2
	local function wall(name, cx, cz, sx, sz)
		local w = edge:Clone(); w.Name = name; w.Size = Vector3.new(sx, h, sz); w.CFrame = CFrame.new(cx, y, cz); w.Parent = wf
		return w
	end
	log.edge = {name = edge.Name, size = tostring(edge.Size), cframe = tostring(edge.CFrame)}
	wall("HollowWallBack", (MOUTH_L + MOUTH_R) / 2, BACK, MOUTH_R - MOUTH_L + 2, edge.Size.Z)
	wall("HollowWallLeft", MOUTH_L, (edge.Position.Z + BACK) / 2, edge.Size.Z, BACK - edge.Position.Z)
	wall("HollowWallRight", MOUTH_R, (edge.Position.Z + BACK) / 2, edge.Size.Z, BACK - edge.Position.Z)
	wall("Wall", (x1 + MOUTH_L) / 2, edge.Position.Z, MOUTH_L - x1, edge.Size.Z)          -- the old wall's west part
	edge.Size = Vector3.new(x2 - MOUTH_R, h, edge.Size.Z); edge.CFrame = CFrame.new((MOUTH_R + x2) / 2, y, edge.Position.Z)   -- the old part keeps the east
	print(string.format("QQ TREE edge: the north wall opens between x %d and %d; a U of wall round the hollow to z %d", MOUTH_L, MOUTH_R, BACK))
elseif edge then print("QQ TREE edge: already opened (HollowWallBack exists)") end
-- ---------- 6: the dressing on the site ----------
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local cleared = 0
local clearedF
for _, m in ipairs(workspace:GetDescendants()) do
	if m:IsA("Model") and m.Parent and m.Parent.Name == "Dressing" then
		local cf = m:GetPivot()
		if math.sqrt((cf.X - SX) ^ 2 + (cf.Z - SZ) ^ 2) <= 31 and cf.Z > 18 then
			if not clearedF then local n = 1; while hb:FindFirstChild("TreehouseCleared_" .. n) do n += 1 end; clearedF = Instance.new("Folder"); clearedF.Name = "TreehouseCleared_" .. n; clearedF.Parent = hb end
			m.Parent = clearedF; cleared += 1
		end
	end
end
print(string.format("QQ TREE dressing cleared from the site: %d%s", cleared, clearedF and (" (HudBackup." .. clearedF.Name .. ")") or ""))
-- ---------- 8: the pieces' ground (the forest - unchanged terrain, rays are fine) ----------
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {T}
local rpA = RaycastParams.new(); rpA.FilterType = Enum.RaycastFilterType.Exclude
local skip = {}
for _, n in ipairs({"Treehouse", "Treehouse_local"}) do local f = workspace:FindFirstChild(n); if f then table.insert(skip, f) end end
for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
rpA.FilterDescendantsInstances = skip
local function ground(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpA)
	local t = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpT)
	local ty = t and t.Position.Y or nil
	if not h then return nil, "nothing", ty end
	local what = (h.Instance == T) and ("terrain " .. h.Material.Name) or h.Instance.Name
	return h.Position.Y, what, ty, h.Instance, h
end
local function open(x, z)
	local y, what, ty, inst, h = ground(x, z)
	if not y then return nil, what end
	if inst == T then if h and h.Material == Enum.Material.Water then return nil, what end; return y, what end
	local n = inst.Name:lower()
	if n:find("trunk") or n:find("foliage") or n:find("leaf") or n:find("roof") or n:find("canopy") then return nil, what .. " at y " .. string.format("%.1f", y) end
	if ty and y > ty + 2.5 then return nil, what .. string.format(" at y %.1f (terrain %.1f)", y, ty) end
	return y, what
end
local placed, skipped = {}, {}
for _, pc in ipairs(PIECES) do
	local y, what = open(pc.x, pc.z)
	local dx, dz = 0, 0
	if not y then
		for _, r in ipairs({6, 12, 18, 24}) do
			for i = 0, 7 do
				local a = i * math.pi / 4
				local tx, tz = pc.x + r * math.sin(a), pc.z + r * math.cos(a)
				local y2, w2 = open(tx, tz)
				if y2 then y, what, dx, dz = y2, w2, tx - pc.x, tz - pc.z break end
			end
			if y then break end
		end
	end
	if y then
		pc.x, pc.z, pc.y = pc.x + dx, pc.z + dz, y + 0.05
		table.insert(placed, pc)
		print(string.format("QQ TREE piece %s (%s) at (%.0f, %.1f, %.0f) on %s%s", pc.id, pc.kind, pc.x, pc.y, pc.z, what, (dx ~= 0 or dz ~= 0) and string.format(" (nudged %.0f, %.0f)", dx, dz) or ""))
	else
		table.insert(skipped, pc.id .. " (" .. tostring(what) .. ")")
		print(string.format("QQ TREE piece %s SKIPPED - no open ground within 24 studs of (%.0f, %.0f): %s", pc.id, pc.x, pc.z, tostring(what)))
	end
end
-- ---------- 7: the folder, the oak, the stones, the scripts ----------
local RS = game:GetService("ReplicatedStorage")
local old = workspace:FindFirstChild("Treehouse")
if old then
	local n = 1; while hb:FindFirstChild("Treehouse_pre_" .. n) do n += 1 end
	old.Name = "Treehouse_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "Treehouse"
F:SetAttribute("Enabled", true)
F:SetAttribute("Tree", HttpService:JSONEncode({x = SX, y = FLOOR, z = SZ, yaw = SITE.yaw}))
F:SetAttribute("Pieces", HttpService:JSONEncode(placed))
if not RS:FindFirstChild("TreehousePick") then local e = Instance.new("RemoteEvent"); e.Name = "TreehousePick"; e.Parent = RS end
local Oak = Instance.new("Model"); Oak.Name = "Oak"; Oak.Parent = F
local base = CFrame.new(SX, FLOOR, SZ) * CFrame.Angles(0, math.rad(SITE.yaw), 0)
local BARK, BARK2 = Color3.fromRGB(96, 66, 40), Color3.fromRGB(84, 56, 34)
local LEAF, LEAF2 = Color3.fromRGB(74, 124, 54), Color3.fromRGB(98, 148, 62)
local function mk(shape, size, color, cf, material, collide, parent)
	local p = Instance.new("Part"); p.Shape = shape; p.Size = size; p.Color = color; p.Material = material
	p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = collide == true; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.CFrame = cf; p.Parent = parent or Oak
	return p
end
local V, B = Enum.PartType.Cylinder, Enum.PartType.Ball
mk(V, Vector3.new(7.2, 6.6, 6.6), BARK, base * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkLow"
mk(V, Vector3.new(15.4, 4.8, 4.8), BARK, base * CFrame.new(0, 14.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkHigh"   -- rises through the roof (ridge y 20.75)
mk(B, Vector3.new(5, 5, 5), BARK2, base * CFrame.new(0, 22.2, 0), Enum.Material.Wood, false).Name = "Crown"
for i = 1, 5 do
	local a = math.rad(i * 72 + 20)
	mk(V, Vector3.new(4.8, 1.8, 1.8), BARK2, base * CFrame.Angles(0, a, 0) * CFrame.new(3.8, 0.55, 0) * CFrame.Angles(0, 0, math.rad(-16)), Enum.Material.Wood, true).Name = "Root"
end
for i = 1, 4 do
	local a = math.rad(i * 90 + 45)
	mk(V, Vector3.new(10, 1.6, 1.6), BARK2, base * CFrame.Angles(0, a, 0) * CFrame.new(4.4, 24.2, 0) * CFrame.Angles(0, 0, math.rad(34)), Enum.Material.Wood, false).Name = "Branch"
end
for i = 1, 6 do
	local a = math.rad(i * 60)
	mk(B, Vector3.new(12, 12, 12), (i % 2 == 0) and LEAF or LEAF2, base * CFrame.new(7.2 * math.sin(a), 28.2, 7.2 * math.cos(a)), Enum.Material.Grass, false).Name = "Leaves"
end
mk(B, Vector3.new(11, 11, 11), LEAF, base * CFrame.new(0, 32.4, 0), Enum.Material.Grass, false).Name = "Leaves"
mk(B, Vector3.new(8.5, 8.5, 8.5), LEAF2, base * CFrame.new(11.5 * math.sin(math.rad(30)), 25.6, 11.5 * math.cos(math.rad(30))), Enum.Material.Grass, false).Name = "Leaves"
mk(B, Vector3.new(8.5, 8.5, 8.5), LEAF, base * CFrame.new(11.5 * math.sin(math.rad(210)), 25.2, 11.5 * math.cos(math.rad(210))), Enum.Material.Grass, false).Name = "Leaves"
-- the ring of stones at the dirt's edge, a gap at the mouth for the path in
local Stones = Instance.new("Model"); Stones.Name = "Stones"; Stones.Parent = F
local STONE = Color3.fromRGB(150, 146, 138)
for i = 0, 9 do
	local a = math.rad(i * 36 + 18)
	if math.abs(i * 36 + 18 - 0) > 30 then
		local s = mk(B, Vector3.new(2.4 + (i % 3) * 0.5, 1.6 + (i % 2) * 0.4, 2.2 + (i % 3) * 0.4), STONE, base * CFrame.new(15.2 * math.sin(a), 0.4, 15.2 * math.cos(a)) * CFrame.Angles(0, a, math.rad(10)), Enum.Material.Slate, true, Stones)
		s.Name = "Stone"
	end
end
local s = Instance.new("Script"); s.Name = "TreehouseServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "TreehouseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
local lv = hb:FindFirstChild("Treehouse2_log") or Instance.new("StringValue"); lv.Name = "Treehouse2_log"; lv.Parent = hb
log.site = {x = SX, z = SZ, floor = FLOOR, bowl = 27, rim = "z 62..84 to y 9", mouth = {MOUTH_L, MOUTH_R}, back = BACK}; log.cleared = clearedF and clearedF.Name or nil
lv.Value = HttpService:JSONEncode(log)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Treehouse2") end)
print(string.format("QQ TREE DONE: Homebase Treehouse at (%d, %.1f, %d) yaw %.1f in its hollow; %d pieces placed%s; TreehouseServer %d, TreehouseClient %d chars%s",
	SX, FLOOR, SZ, SITE.yaw, #placed, #skipped > 0 and (", skipped " .. table.concat(skipped, ", ")) or "", #s.Source, #c.Source, old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
out = TEMPLATE
for key, val in {"@@SERVER@@": SERVER, "@@CLIENT@@": CLIENT, "@@SLEN@@": str(len(SERVER)), "@@CLEN@@": str(len(CLIENT)), "@@SITE@@": site_json, "@@PIECES@@": pieces_json}.items():
    assert out.count(key) == 1, key
    out = out.replace(key, val)
assert "@@" not in out
(HERE / "install_treehouse2.lua").write_text(out, encoding="utf-8")
print(f"install_treehouse2.lua {len(out.encode())} bytes; site {site_json}")
