#!/usr/bin/env python3
"""Builds tools/treehouse/install_treehouse3.lua (job 112): the HOMEBASE TREEHOUSE MOVES to Shannon's spot ("I want it where my player is
standing now ... you will have to remove some trees"), with a bigger room and no trunk inside ("the inside area needs to be bigger and
maybe remove the tree trunk going through the middle"). What the installer does, in order:
 1. the OLD hollow (job 111) put back: the old Treehouse folder to HudBackup.Treehouse_pre_n (its oak, stones, sign, scripts go with it);
    the dressing pines from HudBackup.TreehouseCleared_n back to Boundary.Dressing; the U of wall (HollowWallBack/Left/Right) removed and
    the north edge wall re-joined into one part; the dirt disk re-grassed. The dell's terrain stays (a grassy nook; Shannon: fine);
 2. the NEW site: trees, rocks, mushrooms, bushes, stumps and ferns within CLEAR_R of the spot (by parent folder + name, never squirrels,
    towers, the spawn, anything scripted) go to HudBackup.TreehouseCleared_n (a new folder); the ground is NOT re-cut - the stilts reach
    3 studs into it - except that a disk of terrain Grass turns to Ground (ReplaceMaterial keeps the shape) round the oak;
 3. the oak BEHIND the house: the trunk at local z -13.5 (outside the back wall), roots round it, two branches reaching under the deck,
    the crown round and above the roof; a ring of ten stones at radius 20; the folder with TreehouseServer + TreehouseClient3 (22 x 22
    deck on six stilts, 22 x 8 balcony, 19 x 19 room with a window each side, furniture at the walls, the middle open floor);
 4. the TWELVE pieces, unchanged (p1 in sight of the spawn, the rest beside forest squirrels).
Re-runnable; the body also runs as a play-test PREVIEW (discarded on stop). Run from the repo root.
FILL IN before building: SITE (x, z, floor y from runner 7's reading) and CLEAR_R / CLEAR_NAMES from the list of what stands there."""
import pathlib, json, math, sys
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "src/TreehouseServer.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src/TreehouseClient3.lua").read_text(encoding="utf-8")
for s in (SERVER, CLIENT): assert "]===]" not in s
SPAWN = (3, 1)
# ---- the site: FILL IN from runner 7's reading ----
SITE = {"x": -107, "z": 4, "floor": 0.06}                  # runner 7, Oct 15: her character at (-107.38, 3.29, 4.40), terrain Grass y 0.06, flat (dips 0.3 at 24 studs west); the north edge wall at z 25, the west at x -130
CLEAR_R = 26                                                # studs round the house centre cleared of forest props (pine_mid_s19 at 27 and pine_tall_s14 at 27.4 stay)
CLEAR_PARENTS = ["Forest", "Foliage", "Rocks", "Trees", "Nature", "Props", "Mushrooms", "Bushes"]   # not Boundary.Dressing: the edge trees along z 25 / x -130 are the forest's backdrop and stay
CLEAR_NAMES = ["tree", "pine", "oak", "birch", "rock", "stone", "boulder", "mushroom", "bush", "stump", "log", "fern", "shrub", "flower", "grass", "foliage", "canopy", "trunk"]
KEEP_NAMES = ["squirrel", "tower", "spawn", "zip", "station", "glider", "ramp", "treehouse", "piece", "sign", "shop", "bench", "path", "road", "bridge", "gate", "wall", "fence"]
if SITE is None:
    print("make_install_treehouse3.py: SITE is not filled in yet (x, z, floor) - waiting on runner 7's reading of Shannon's spot"); sys.exit(1)
SITE["yaw"] = round(math.degrees(math.atan2(SPAWN[0] - SITE["x"], SPAWN[1] - SITE["z"])), 1)   # local +z faces the spawn
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
# a piece within the new site's clearing would sit under the house: push it out
for p in PIECES:
    d = math.hypot(p["x"] - SITE["x"], p["z"] - SITE["z"])
    assert d > CLEAR_R + 4, f"piece {p['id']} is {d:.0f} studs from the new site - move it"
J = lambda v: json.dumps(v, separators=(",", ":"))
for s in (J(PIECES), J(SITE), J(CLEAR_PARENTS), J(CLEAR_NAMES), J(KEEP_NAMES)): assert "]==]" not in s
TEMPLATE = '''-- install_treehouse3.lua (Studio EDIT; re-runnable; its body also runs as a play-test PREVIEW - discarded on stop).
-- Job 112: the HOMEBASE TREEHOUSE MOVES to Shannon's spot (@@SX@@, @@SZ@@), a bigger room, no trunk inside. The old hollow is put back
-- (folder to HudBackup, pines back, the wall re-joined, the dirt re-grassed; the dell's terrain stays). At the new site the forest props
-- within @@CLEAR_R@@ studs go to HudBackup.TreehouseCleared_n; a disk of Ground round the oak; the oak BEHIND the house; ten stones;
-- TreehouseServer (@@SLEN@@) + TreehouseClient3 (@@CLEN@@); twelve pieces unchanged. Log HudBackup.Treehouse3_log. No DataStore, no publish. Output "QQ TREE".
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local T = workspace.Terrain
local SERVER = [===[
@@SERVER@@]===]
local CLIENT = [===[
@@CLIENT@@]===]
do
	for _, s in ipairs({{"TreehouseServer", SERVER}, {"TreehouseClient3", CLIENT}}) do
		local ok, f, err = pcall(function() return loadstring(s[2]) end)
		if ok and not f then print("QQ TREE ABORT: " .. s[1] .. " does not compile: " .. tostring(err)) return end
	end
end
local SITE = HttpService:JSONDecode([==[@@SITE@@]==])
local PIECES = HttpService:JSONDecode([==[@@PIECES@@]==])
local CLEAR_PARENTS = HttpService:JSONDecode([==[@@CLEAR_PARENTS@@]==])
local CLEAR_NAMES = HttpService:JSONDecode([==[@@CLEAR_NAMES@@]==])
local KEEP_NAMES = HttpService:JSONDecode([==[@@KEEP_NAMES@@]==])
local CLEAR_R = @@CLEAR_R@@
local SX, SZ, FLOOR = SITE.x, SITE.z, SITE.floor
local log = {}
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Treehouse3") end)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
-- ---------- 1: the old hollow put back ----------
local old = workspace:FindFirstChild("Treehouse")
local oldSite
if old then
	pcall(function() oldSite = HttpService:JSONDecode(old:GetAttribute("Tree")) end)
	local n = 1; while hb:FindFirstChild("Treehouse_pre_" .. n) do n += 1 end
	old.Name = "Treehouse_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
	log.old = old.Name
end
do	-- the pines back from the LAST TreehouseCleared_n that still holds models, to the first Dressing folder
	local dressing
	for _, f in ipairs(workspace:GetDescendants()) do if f:IsA("Folder") and f.Name == "Dressing" then dressing = f break end end
	local back, from = 0, nil
	for n = 9, 1, -1 do
		local cf = hb:FindFirstChild("TreehouseCleared_" .. n)
		if cf and #cf:GetChildren() > 0 and dressing then
			for _, m in ipairs(cf:GetChildren()) do m.Parent = dressing; back += 1 end
			from = cf.Name; break
		end
	end
	print(string.format("QQ TREE old hollow: %d dressing models back%s", back, from and (" from HudBackup." .. from) or " (nothing to put back)"))
	log.pinesBack = back
end
do	-- the wall: the U goes, the two "Wall" parts at z 25 re-join into one
	local removed = 0
	local walls, wf = {}, nil
	for _, p in ipairs(workspace:GetDescendants()) do
		if p:IsA("BasePart") then
			if p.Name == "HollowWallBack" or p.Name == "HollowWallLeft" or p.Name == "HollowWallRight" then p:Destroy(); removed += 1
			elseif p.Name == "Wall" and p.Size.X > 20 and math.abs(p.Position.Z - 25) < 1.5 and p.Size.Y > 40 then table.insert(walls, p); wf = p.Parent end
		end
	end
	if #walls >= 2 then
		local x1, x2 = math.huge, -math.huge
		for _, w in ipairs(walls) do x1 = math.min(x1, w.Position.X - w.Size.X / 2); x2 = math.max(x2, w.Position.X + w.Size.X / 2) end
		local keep = walls[1]
		keep.Size = Vector3.new(x2 - x1, keep.Size.Y, keep.Size.Z); keep.CFrame = CFrame.new((x1 + x2) / 2, keep.Position.Y, keep.Position.Z)
		for i = 2, #walls do walls[i]:Destroy() end
		print(string.format("QQ TREE old hollow: the U of wall removed (%d parts); the north edge re-joined x %d..%d", removed, x1, x2))
	else
		print(string.format("QQ TREE old hollow: the U of wall removed (%d parts); the north edge is already one part (%d found)", removed, #walls))
	end
	log.wall = {removed = removed, joined = #walls}
end
if oldSite then	-- the old dirt disk back to grass (ReplaceMaterial keeps the shape)
	local r = Region3.new(Vector3.new(oldSite.x - 18, oldSite.y - 6, oldSite.z - 18), Vector3.new(oldSite.x + 18, oldSite.y + 2, oldSite.z + 18)):ExpandToGrid(4)
	T:ReplaceMaterial(r, 4, Enum.Material.Ground, Enum.Material.Grass)
	print(string.format("QQ TREE old hollow: the dirt re-grassed round (%d, %d)", oldSite.x, oldSite.z))
end
-- ---------- 2: the new site's clearing ----------
local function lower(s) return string.lower(s or "") end
local function matches(name, list) local n = lower(name); for _, k in ipairs(list) do if n:find(k, 1, true) then return true end end; return false end
local function parentOk(inst)
	local a = inst.Parent
	while a and a ~= workspace do
		for _, k in ipairs(CLEAR_PARENTS) do if a.Name == k then return true end end
		a = a.Parent
	end
	return false
end
local function hasScript(inst) for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BaseScript") then return true end end; return false end
local cleared, kept, clearedF = 0, {}, nil
local seen = {}
for _, inst in ipairs(workspace:GetDescendants()) do
	if (inst:IsA("Model") or inst:IsA("BasePart")) and inst.Parent and not seen[inst] and inst ~= T then
		local top = inst
		while top.Parent and top.Parent ~= workspace and not (top.Parent:IsA("Folder")) do top = top.Parent end   -- the model under its folder
		if not seen[top] then
			seen[top] = true
			local ok, cf = pcall(function() return top:GetPivot() end)
			if ok and cf and math.sqrt((cf.X - SX) ^ 2 + (cf.Z - SZ) ^ 2) <= CLEAR_R then
				local keepIt = matches(top.Name, KEEP_NAMES) or top:FindFirstChildOfClass("Humanoid") or hasScript(top) or game:GetService("Players"):GetPlayerFromCharacter(top)
				if not keepIt and parentOk(top) and matches(top.Name, CLEAR_NAMES) then
					if not clearedF then local n = 1; while hb:FindFirstChild("TreehouseCleared_" .. n) do n += 1 end; clearedF = Instance.new("Folder"); clearedF.Name = "TreehouseCleared_" .. n; clearedF.Parent = hb end
					top:SetAttribute("ClearedFrom", top.Parent:GetFullName()); top.Parent = clearedF; cleared += 1
				elseif not keepIt then
					table.insert(kept, top:GetFullName() .. string.format(" (%.0f, %.0f)", cf.X, cf.Z))
				end
			end
		end
	end
end
print(string.format("QQ TREE cleared from the site: %d%s", cleared, clearedF and (" (HudBackup." .. clearedF.Name .. ", each with a ClearedFrom attribute)") or ""))
if #kept > 0 then print("QQ TREE left standing within " .. CLEAR_R .. " (not on the lists): " .. table.concat(kept, " | ")) end
log.cleared = clearedF and clearedF.Name or nil; log.kept = kept
-- the dirt round the oak (and under the house): Grass -> Ground in a 22-stud disk, the shape untouched
do
	local r = Region3.new(Vector3.new(SX - 24, FLOOR - 6, SZ - 24), Vector3.new(SX + 24, FLOOR + 2, SZ + 24)):ExpandToGrid(4)
	T:ReplaceMaterial(r, 4, Enum.Material.Grass, Enum.Material.Ground)
end
-- ---------- 3: the pieces' ground ----------
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
-- ---------- 4: the folder, the oak behind the house, the stones, the scripts ----------
local RS = game:GetService("ReplicatedStorage")
local F = Instance.new("Folder"); F.Name = "Treehouse"
F:SetAttribute("Enabled", true)
F:SetAttribute("Tree", HttpService:JSONEncode({x = SX, y = FLOOR, z = SZ, yaw = SITE.yaw}))
F:SetAttribute("Pieces", HttpService:JSONEncode(placed))
if not RS:FindFirstChild("TreehousePick") then local e = Instance.new("RemoteEvent"); e.Name = "TreehousePick"; e.Parent = RS end
local Oak = Instance.new("Model"); Oak.Name = "Oak"; Oak.Parent = F
local base = CFrame.new(SX, FLOOR, SZ) * CFrame.Angles(0, math.rad(SITE.yaw), 0)
local TZ = -13.5                                                           -- the trunk's local z: outside the room's back wall (z -9.5) and the deck (z -11)
local BARK, BARK2 = Color3.fromRGB(96, 66, 40), Color3.fromRGB(84, 56, 34)
local LEAF, LEAF2 = Color3.fromRGB(74, 124, 54), Color3.fromRGB(98, 148, 62)
local function mk(shape, size, color, cf, material, collide, parent)
	local p = Instance.new("Part"); p.Shape = shape; p.Size = size; p.Color = color; p.Material = material
	p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = collide == true; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.CFrame = cf; p.Parent = parent or Oak
	return p
end
local V, B = Enum.PartType.Cylinder, Enum.PartType.Ball
local tb = base * CFrame.new(0, 0, TZ)                                     -- the trunk's foot
mk(V, Vector3.new(9, 7.2, 7.2), BARK, tb * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkLow"     -- y -1..8, 3 into the ground
mk(V, Vector3.new(18, 4.8, 4.8), BARK, tb * CFrame.new(0, 16, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkHigh"   -- y 7..25, behind the back wall, past the ridge (21.5)
mk(B, Vector3.new(5, 5, 5), BARK2, tb * CFrame.new(0, 25, 0), Enum.Material.Wood, false).Name = "Crown"
for i = 1, 5 do
	local a = math.rad(i * 72 + 20)
	mk(V, Vector3.new(5.2, 1.8, 1.8), BARK2, tb * CFrame.Angles(0, a, 0) * CFrame.new(4.2, 0.55, 0) * CFrame.Angles(0, 0, math.rad(-16)), Enum.Material.Wood, true).Name = "Root"
end
for _, x in ipairs({-5, 5}) do                                              -- two limbs from the trunk reaching under the deck (y 8 -> 9.4), as if they carried it
	mk(V, Vector3.new(15, 1.6, 1.6), BARK2, base * CFrame.new(x, 8.7, TZ + 7) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(-5)) * CFrame.Angles(0, 0, 0), Enum.Material.Wood, false).Name = "Limb"
end
for i = 1, 4 do
	local a = math.rad(i * 90 + 45)
	mk(V, Vector3.new(11, 1.6, 1.6), BARK2, tb * CFrame.Angles(0, a, 0) * CFrame.new(4.8, 27, 0) * CFrame.Angles(0, 0, math.rad(34)), Enum.Material.Wood, false).Name = "Branch"
end
for i = 1, 6 do
	local a = math.rad(i * 60)
	mk(B, Vector3.new(13, 13, 13), (i % 2 == 0) and LEAF or LEAF2, tb * CFrame.new(8 * math.sin(a), 30.5, 8 * math.cos(a)), Enum.Material.Grass, false).Name = "Leaves"   -- bottoms y 24, above the ridge
end
mk(B, Vector3.new(12, 12, 12), LEAF, tb * CFrame.new(0, 35, 0), Enum.Material.Grass, false).Name = "Leaves"
mk(B, Vector3.new(9, 9, 9), LEAF2, tb * CFrame.new(12.5 * math.sin(math.rad(30)), 28.5, 12.5 * math.cos(math.rad(30))), Enum.Material.Grass, false).Name = "Leaves"
mk(B, Vector3.new(9, 9, 9), LEAF, tb * CFrame.new(12.5 * math.sin(math.rad(210)), 28, 12.5 * math.cos(math.rad(210))), Enum.Material.Grass, false).Name = "Leaves"
-- the ring of stones at the dirt's edge, a gap at the mouth for the path in
local Stones = Instance.new("Model"); Stones.Name = "Stones"; Stones.Parent = F
local STONE = Color3.fromRGB(150, 146, 138)
for i = 0, 9 do
	local a = math.rad(i * 36 + 18)
	local dgap = (i * 36 + 18 + 180) % 360 - 180
	if math.abs(dgap) > 30 then
		local s = mk(B, Vector3.new(2.4 + (i % 3) * 0.5, 1.6 + (i % 2) * 0.4, 2.2 + (i % 3) * 0.4), STONE, base * CFrame.new(21 * math.sin(a), 0.4, -3 + 21 * math.cos(a)) * CFrame.Angles(0, a, math.rad(10)), Enum.Material.Slate, true, Stones)
		s.Name = "Stone"
	end
end
local s = Instance.new("Script"); s.Name = "TreehouseServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "TreehouseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
local lv = hb:FindFirstChild("Treehouse3_log") or Instance.new("StringValue"); lv.Name = "Treehouse3_log"; lv.Parent = hb
log.site = {x = SX, y = FLOOR, z = SZ, yaw = SITE.yaw, clearR = CLEAR_R}
lv.Value = HttpService:JSONEncode(log)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Treehouse3") end)
print(string.format("QQ TREE DONE: Homebase Treehouse at (%d, %.1f, %d) yaw %.1f, the trunk behind the house; %d pieces placed%s; TreehouseServer %d, TreehouseClient %d chars%s",
	SX, FLOOR, SZ, SITE.yaw, #placed, #skipped > 0 and (", skipped " .. table.concat(skipped, ", ")) or "", #s.Source, #c.Source, log.old and ("; the old folder is HudBackup." .. log.old) or ""))
'''
out = TEMPLATE
for key, val in {"@@SERVER@@": SERVER, "@@CLIENT@@": CLIENT, "@@SLEN@@": str(len(SERVER)), "@@CLEN@@": str(len(CLIENT)), "@@SITE@@": J(SITE), "@@PIECES@@": J(PIECES),
                 "@@CLEAR_PARENTS@@": J(CLEAR_PARENTS), "@@CLEAR_NAMES@@": J(CLEAR_NAMES), "@@KEEP_NAMES@@": J(KEEP_NAMES), "@@CLEAR_R@@": str(CLEAR_R)}.items():
    assert out.count(key) >= 1, key
    out = out.replace(key, val)
out = out.replace("@@SX@@", str(SITE["x"])).replace("@@SZ@@", str(SITE["z"]))
assert "@@" not in out
(HERE / "install_treehouse3.lua").write_text(out, encoding="utf-8")
print(f"install_treehouse3.lua {len(out.encode())} bytes; site {J(SITE)}")
