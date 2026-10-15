#!/usr/bin/env python3
"""Builds tools/treehouse/install_treehouse1.lua (job 103): the forest treehouse. workspace.Treehouse {Oak (Model, shared: trunk,
roots, branches, canopy), TreehouseServer (RunContext Server), TreehouseClient (RunContext Client)}; attributes Enabled, Tree (JSON
x/y/z/yaw), Pieces (JSON [{id, x, y, z, kind, yaw, far}]); ReplicatedStorage.TreehousePick (RemoteEvent). The oak stands 32 studs
south of the forest spawn (survey103: the kit trees are two-part models with trunks 1.3-4.4 wide, none can carry a house; the ground
there is flat terrain grass at y 0.1, nothing within 18 studs). Twelve pieces: eight along the forest (the first two in sight of the
spawn), two in Rue de Noisette, two at the chateau. The installer rays the ground at every spot and nudges a spot that lands on a
roof or a tree; a spot with no open ground near it is skipped and reported. Re-runnable (the old folder -> HudBackup.Treehouse_pre_n).
Its body also runs as a play-test PREVIEW. Run from the repo root: python3 tools/treehouse/make_install_treehouse1.py"""
import pathlib, json, math
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "src/TreehouseServer.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src/TreehouseClient.lua").read_text(encoding="utf-8")
for s in (SERVER, CLIENT): assert "]===]" not in s
SPAWN = (3, 1)                                   # the forest spawn pad (survey103)
TREE = {"x": -4, "z": -30}
TREE["yaw"] = round(math.degrees(math.atan2(SPAWN[0] - TREE["x"], SPAWN[1] - TREE["z"])), 1)   # local +z faces the spawn (CFrame.Angles(0, yaw, 0) turns +z to (sin, 0, cos))
PIECES = [
    {"id": "p1",  "x": 14,  "z": -8,   "kind": "planks",   "yaw": 30},    # in sight of the spawn (14 studs)
    {"id": "p2",  "x": -12, "z": -12,  "kind": "rope",     "yaw": 0},     # in sight of the spawn (17 studs)
    {"id": "p3",  "x": 22,  "z": -30,  "kind": "planks",   "yaw": 70},    # between the two pines south-east
    {"id": "p4",  "x": -20, "z": -40,  "kind": "shingles", "yaw": 15},    # by the surfing squirrel
    {"id": "p5",  "x": 30,  "z": -60,  "kind": "planks",   "yaw": 100},   # past the fairy squirrel
    {"id": "p6",  "x": -12, "z": -85,  "kind": "rope",     "yaw": 40},    # by Baking Betty
    {"id": "p7",  "x": 60,  "z": -105, "kind": "shingles", "yaw": 0},     # by the scientist
    {"id": "p8",  "x": 70,  "z": -140, "kind": "planks",   "yaw": 55},    # by the rainy-day squirrel, deep in the forest
    {"id": "p9",  "x": 210, "z": -70,  "kind": "lantern",  "yaw": 20, "far": True},   # Rue de Noisette, near its spawn
    {"id": "p10", "x": 300, "z": -90,  "kind": "planks",   "yaw": 80, "far": True},   # Rue de Noisette, by the bird feeder
    {"id": "p11", "x": 455, "z": -75,  "kind": "shingles", "yaw": 10, "far": True},   # the chateau, by Farmer Fernand
    {"id": "p12", "x": 560, "z": -110, "kind": "lantern",  "yaw": 60, "far": True},   # the chateau, past the truffle hunter
]
assert len({p["id"] for p in PIECES}) == 12
pieces_json = json.dumps(PIECES, separators=(",", ":"))
tree_json = json.dumps(TREE, separators=(",", ":"))
for s in (pieces_json, tree_json): assert "]==]" not in s
TEMPLATE = '''-- install_treehouse1.lua (Studio EDIT mode; re-runnable; its body also runs as a play-test PREVIEW). Job 103: the forest treehouse
-- (Shannon, Oct 15 2026: pieces strewn through the French map, a count, the house built piece by piece - "that will keep people longer
-- at the start"). Builds workspace.Treehouse: the Oak (shared; a fat trunk, roots, four branches, a canopy of leaf balls) @@TREEWHERE@@,
-- TreehouseServer (@@SLEN@@ chars) + TreehouseClient (@@CLEN@@ chars), attributes Tree / Pieces (JSON; edit a spot in Studio, no code) and
-- ReplicatedStorage.TreehousePick. The house, the sign, the pieces and the prompts are per player (the client). Twelve pieces; every
-- spot's ground is rayed here and a spot on a roof or in a tree is nudged, a spot with no open ground near it is skipped and reported.
-- Undo: delete workspace.Treehouse (the old one is in ServerStorage.HudBackup). No DataStore, no publish. Output "QQ TREE".
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local SERVER = [===[
@@SERVER@@]===]
local CLIENT = [===[
@@CLIENT@@]===]
do   -- the compile check, where loadstring can run (both sources are compiled with the luau CLI before every push)
	for _, s in ipairs({{"TreehouseServer", SERVER}, {"TreehouseClient", CLIENT}}) do
		local ok, f, err = pcall(function() return loadstring(s[2]) end)
		if ok and not f then print("QQ TREE ABORT: " .. s[1] .. " does not compile: " .. tostring(err)) return end
	end
end
local TREE = HttpService:JSONDecode([==[@@TREE@@]==])
local PIECES = HttpService:JSONDecode([==[@@PIECES@@]==])
local T = workspace.Terrain
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {T}
local rpA = RaycastParams.new(); rpA.FilterType = Enum.RaycastFilterType.Exclude
local old = workspace:FindFirstChild("Treehouse")
local skip = {}
for _, n in ipairs({"Treehouse", "Treehouse_local"}) do local f = workspace:FindFirstChild(n); if f then table.insert(skip, f) end end
rpA.FilterDescendantsInstances = skip
local function ground(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpA)
	local t = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpT)
	local ty = t and t.Position.Y or nil
	if not h then return nil, "nothing", ty end
	local what = (h.Instance == T) and ("terrain " .. h.Material.Name) or h.Instance.Name
	return h.Position.Y, what, ty, h.Instance
end
-- open ground = terrain, or a part no higher than 2.5 studs above the terrain under it (a path, a dais, a slab); not a tree, not a roof
local function open(x, z)
	local y, what, ty, inst = ground(x, z)
	if not y then return nil, what end
	if inst == T then return y, what end
	local n = inst.Name:lower()
	if n:find("trunk") or n:find("foliage") or n:find("leaf") or n:find("roof") then return nil, what .. " at y " .. string.format("%.1f", y) end
	if ty and y > ty + 2.5 then return nil, what .. string.format(" at y %.1f (terrain %.1f)", y, ty) end
	return y, what
end
-- ---------- the oak's ground: flat terrain under the trunk and the roots ----------
local ty, twhat = open(TREE.x, TREE.z)
if not ty then print("QQ TREE ABORT - no open ground at the oak's spot (" .. TREE.x .. ", " .. TREE.z .. "): " .. tostring(twhat)) return end
for i = 0, 3 do
	local a = i * math.pi / 2
	local y2, w2 = open(TREE.x + 5 * math.sin(a), TREE.z + 5 * math.cos(a))
	if not y2 or math.abs(y2 - ty) > 1.5 then print(string.format("QQ TREE ABORT - the ground 5 studs from the oak's spot is not flat open ground (%s, y %s vs %.1f)", tostring(w2), y2 and string.format("%.1f", y2) or "none", ty)) return end
end
TREE.y = ty
print(string.format("QQ TREE oak at (%d, %.1f, %d) on %s, yaw %.1f (its +z faces the spawn)", TREE.x, ty, TREE.z, twhat, TREE.yaw))
-- ---------- the pieces' ground, nudged off roofs and trees ----------
local placed, skipped = {}, {}
for _, pc in ipairs(PIECES) do
	local y, what = open(pc.x, pc.z)
	local dx, dz = 0, 0
	if not y then
		for _, r in ipairs({6, 12}) do
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
		print(string.format("QQ TREE piece %s (%s%s) at (%.0f, %.1f, %.0f) on %s%s", pc.id, pc.kind, pc.far and ", beyond the gate" or "", pc.x, pc.y, pc.z, what, (dx ~= 0 or dz ~= 0) and string.format(" (nudged %.0f, %.0f)", dx, dz) or ""))
	else
		table.insert(skipped, pc.id .. " (" .. tostring(what) .. ")")
		print(string.format("QQ TREE piece %s SKIPPED - no open ground within 12 studs of (%d, %d): %s", pc.id, pc.x, pc.z, tostring(what)))
	end
end
if #placed < 10 then print("QQ TREE ABORT - only " .. #placed .. " pieces could be placed; nothing changed") return end
-- ---------- the old folder away ----------
if old then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Treehouse_pre_" .. n) do n += 1 end
	old.Name = "Treehouse_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
-- ---------- the folder, the remote, the oak ----------
local F = Instance.new("Folder"); F.Name = "Treehouse"
F:SetAttribute("Enabled", true)
F:SetAttribute("Tree", HttpService:JSONEncode({x = TREE.x, y = TREE.y, z = TREE.z, yaw = TREE.yaw}))
F:SetAttribute("Pieces", HttpService:JSONEncode(placed))
if not RS:FindFirstChild("TreehousePick") then local e = Instance.new("RemoteEvent"); e.Name = "TreehousePick"; e.Parent = RS end
local Oak = Instance.new("Model"); Oak.Name = "Oak"; Oak.Parent = F
local base = CFrame.new(TREE.x, TREE.y, TREE.z) * CFrame.Angles(0, math.rad(TREE.yaw), 0)
local BARK, BARK2 = Color3.fromRGB(96, 66, 40), Color3.fromRGB(84, 56, 34)
local LEAF, LEAF2 = Color3.fromRGB(74, 124, 54), Color3.fromRGB(98, 148, 62)
local function mk(shape, size, color, cf, material, collide)
	local p = Instance.new("Part"); p.Shape = shape; p.Size = size; p.Color = color; p.Material = material
	p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = collide == true; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.CFrame = cf; p.Parent = Oak
	return p
end
local V = Enum.PartType.Cylinder
mk(V, Vector3.new(7.2, 6.2, 6.2), BARK, base * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkLow"
mk(V, Vector3.new(9.6, 4.6, 4.6), BARK, base * CFrame.new(0, 11.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkHigh"
mk(Enum.PartType.Ball, Vector3.new(4.8, 4.8, 4.8), BARK2, base * CFrame.new(0, 16.4, 0), Enum.Material.Wood, false).Name = "Crown"
for i = 1, 5 do
	local a = math.rad(i * 72 + 20)
	mk(V, Vector3.new(4.6, 1.7, 1.7), BARK2, base * CFrame.Angles(0, a, 0) * CFrame.new(3.6, 0.55, 0) * CFrame.Angles(0, 0, math.rad(-16)), Enum.Material.Wood, true).Name = "Root"
end
for i = 1, 4 do
	local a = math.rad(i * 90 + 45)
	mk(V, Vector3.new(9.5, 1.5, 1.5), BARK2, base * CFrame.Angles(0, a, 0) * CFrame.new(4.2, 15.3, 0) * CFrame.Angles(0, 0, math.rad(34)), Enum.Material.Wood, false).Name = "Branch"
end
for i = 1, 6 do
	local a = math.rad(i * 60)
	mk(Enum.PartType.Ball, Vector3.new(11, 11, 11), (i % 2 == 0) and LEAF or LEAF2, base * CFrame.new(6.6 * math.sin(a), 20.8, 6.6 * math.cos(a)), Enum.Material.Grass, false).Name = "Leaves"
end
mk(Enum.PartType.Ball, Vector3.new(10, 10, 10), LEAF, base * CFrame.new(0, 24.8, 0), Enum.Material.Grass, false).Name = "Leaves"
mk(Enum.PartType.Ball, Vector3.new(8, 8, 8), LEAF2, base * CFrame.new(9 * math.sin(math.rad(30)), 18.4, 9 * math.cos(math.rad(30))), Enum.Material.Grass, false).Name = "Leaves"
mk(Enum.PartType.Ball, Vector3.new(8, 8, 8), LEAF, base * CFrame.new(9 * math.sin(math.rad(210)), 18.0, 9 * math.cos(math.rad(210))), Enum.Material.Grass, false).Name = "Leaves"
local s = Instance.new("Script"); s.Name = "TreehouseServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "TreehouseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ TREE DONE: workspace.Treehouse (oak at (%d, %.1f, %d); %d pieces placed%s; TreehouseServer %d, TreehouseClient %d chars; RS.TreehousePick)%s",
	TREE.x, TREE.y, TREE.z, #placed, #skipped > 0 and (", skipped " .. table.concat(skipped, ", ")) or "", #s.Source, #c.Source, old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
out = TEMPLATE
subs = {"@@SERVER@@": SERVER, "@@CLIENT@@": CLIENT, "@@SLEN@@": str(len(SERVER)), "@@CLEN@@": str(len(CLIENT)),
        "@@TREE@@": tree_json, "@@PIECES@@": pieces_json,
        "@@TREEWHERE@@": f"at ({TREE['x']}, {TREE['z']}), {math.hypot(SPAWN[0]-TREE['x'], SPAWN[1]-TREE['z']):.0f} studs south of the forest spawn"}
for key, val in subs.items():
    assert out.count(key) == 1, key
    out = out.replace(key, val)
assert "@@" not in out
(HERE / "install_treehouse1.lua").write_text(out, encoding="utf-8")
print(f"install_treehouse1.lua {len(out.encode())} bytes; server {len(SERVER)} chars; client {len(CLIENT)} chars; tree {tree_json}")
