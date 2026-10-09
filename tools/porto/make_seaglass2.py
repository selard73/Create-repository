#!/usr/bin/env python3
"""Builds tools/porto/seaglass2.lua (job 32): sea glass and shells on EVERY beach, and more of them. Shannon, Oct 9:
"more shells scattered on both of the beaches, not just the one beach by Bella". SeaGlassServer (Studio: 8319 chars
after job 18) scattered Count=8 pieces in one box (BoxMin/BoxMax) round Bella. Now workspace.SeaGlass can carry several
boxes: BoxMin/BoxMax (beach 1), Box2Min/Box2Max, Box3Min/Box3Max ... each with its own spots and its own count
(Count, Count2, Count3 ...; default Count). Pieces picked up on any beach count for Bella's recipes as before (making
still happens next to her). The installer also sets the attributes: Count 12 on Bella's beach and the box + count of each
other beach from the job 31 survey (BOXES below). Original -> ServerStorage.HudBackup.SeaGlassServer_pre_seaglass2.
Run from the repo root: python3 tools/porto/make_seaglass2.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/porto/src/SeaGlassServer.lua"

# other beaches, from the job 31 survey: (name, min xyz, max xyz, count). Filled in once the survey is back.
BOXES = [
]
COUNT1 = 12

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

F1 = '''local spots = {}
local function findSpots()
	local a = G:GetAttribute("BoxMin"); local b = G:GetAttribute("BoxMax")
	if typeof(a) ~= "Vector3" then a = Vector3.new(388, -60, -1095) end
	if typeof(b) ~= "Vector3" then b = Vector3.new(445, -40, -1046) end
	local rng = Random.new(7)
	local tries = 0
	while #spots < 40 and tries < 400 do
		tries += 1
		local x, z = rng:NextNumber(a.X, b.X), rng:NextNumber(a.Z, b.Z)
		local hit = workspace:Raycast(Vector3.new(x, b.Y + 20, z), Vector3.new(0, -(b.Y - a.Y + 40), 0), tparams)
		if hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Sand and hit.Normal.Y > 0.8 then
			local pos = hit.Position
			local ok = (pos - bellaPos).Magnitude >= 3.5
			if ok then for _, s in ipairs(spots) do if (s - pos).Magnitude < 2.6 then ok = false break end end end
			if ok and #workspace:GetPartBoundsInRadius(pos, 1.3, oparams) > 0 then ok = false end
			if ok then table.insert(spots, pos) end
		end
	end
	print(string.format("SeaGlassServer: %d spots on the sand (%d tries)", #spots, tries))
end
findSpots()
if #spots < 8 then warn("SeaGlassServer: not enough sand spots; set BoxMin/BoxMax on workspace.SeaGlass") end
'''
R1 = '''-- every beach (Oct 9 2026, Shannon: "more shells scattered on both of the beaches"): box 1 is BoxMin/BoxMax, then
-- Box2Min/Box2Max, Box3Min/Box3Max ... each box keeps its own spots and its own count (Count, Count2, Count3 ...)
local boxes = {}        -- {min, max, spots = {}, count = n}
do
	local i = 1
	while true do
		local suffix = i == 1 and "" or tostring(i)
		local a, b = G:GetAttribute("Box" .. suffix .. "Min"), G:GetAttribute("Box" .. suffix .. "Max")
		if i == 1 then
			if typeof(a) ~= "Vector3" then a = Vector3.new(388, -60, -1095) end
			if typeof(b) ~= "Vector3" then b = Vector3.new(445, -40, -1046) end
		elseif typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then break end
		table.insert(boxes, {min = a, max = b, spots = {}, count = num("Count" .. suffix, num("Count", 8))})
		i += 1
	end
end
local function findSpots(box, seed)
	local a, b, spots = box.min, box.max, box.spots
	local rng = Random.new(seed)
	local tries = 0
	while #spots < math.max(40, box.count * 4) and tries < 600 do
		tries += 1
		local x, z = rng:NextNumber(a.X, b.X), rng:NextNumber(a.Z, b.Z)
		local hit = workspace:Raycast(Vector3.new(x, b.Y + 20, z), Vector3.new(0, -(b.Y - a.Y + 40), 0), tparams)
		if hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Sand and hit.Normal.Y > 0.8 then
			local pos = hit.Position
			local ok = (pos - bellaPos).Magnitude >= 3.5
			if ok then for _, s in ipairs(spots) do if (s - pos).Magnitude < 2.6 then ok = false break end end end
			if ok and #workspace:GetPartBoundsInRadius(pos, 1.3, oparams) > 0 then ok = false end
			if ok then table.insert(spots, pos) end
		end
	end
	print(string.format("SeaGlassServer: beach %d: %d spots on the sand (%d tries) for %d pieces", seed - 6, #spots, tries, box.count))
end
for i, box in ipairs(boxes) do findSpots(box, 6 + i) end
for i, box in ipairs(boxes) do if #box.spots < box.count then warn(string.format("SeaGlassServer: beach %d has only %d sand spots; check its Box%sMin/Max on workspace.SeaGlass", i, #box.spots, i == 1 and "" or tostring(i))) end end
'''
F2 = '''local used = {}      -- [spotIndex] = piece model
local rng = Random.new()
local function freeSpot()
	local free = {}
	for i in ipairs(spots) do if not used[i] then table.insert(free, i) end end
	if #free == 0 then return nil end
	return free[rng:NextInteger(1, #free)]
end
local taking = {}
local function spawnOne()
	local i = freeSpot()
	if not i then return end
	local kind = pickKind(rng)
	local m, pr = build(kind, spots[i], rng)
	used[i] = m
'''
R2 = '''local used = {}      -- [box][spotIndex] = piece model
local rng = Random.new()
local function freeSpot(box)
	used[box] = used[box] or {}
	local free = {}
	for i in ipairs(box.spots) do if not used[box][i] then table.insert(free, i) end end
	if #free == 0 then return nil end
	return free[rng:NextInteger(1, #free)]
end
local taking = {}
local function spawnOne(box)
	local i = freeSpot(box)
	if not i then return end
	local kind = pickKind(rng)
	local m, pr = build(kind, box.spots[i], rng)
	used[box][i] = m
'''
F3 = '''		used[i] = nil
		m:Destroy()
		task.delay(rng:NextNumber(num("RespawnMin", 45), num("RespawnMax", 90)), spawnOne)
	end)
end
for _ = 1, num("Count", 8) do spawnOne() end
'''
R3 = '''		used[box][i] = nil
		m:Destroy()
		task.delay(rng:NextNumber(num("RespawnMin", 45), num("RespawnMax", 90)), function() spawnOne(box) end)
	end)
end
for _, box in ipairs(boxes) do for _ = 1, box.count do spawnOne(box) end end
'''
src = SRC.read_text(encoding="utf-8")
if R1 in src: src = src.replace(R3, F3).replace(R2, F2).replace(R1, F1)
for f in (F1, F2, F3): assert src.count(f) == 1, f[:50]
N = len(src.encode())
out = src.replace(F1, R1).replace(F2, F2 and R2).replace(F3, R3)

def v3(t): return "Vector3.new(%s, %s, %s)" % tuple(t)
attrs = ['G:SetAttribute("Count", %d)' % COUNT1]
for i, (name, lo, hi, count) in enumerate(BOXES, start=2):
    attrs.append('G:SetAttribute("Box%dMin", %s); G:SetAttribute("Box%dMax", %s); G:SetAttribute("Count%d", %d)   -- %s' % (i, v3(lo), i, v3(hi), i, count, name))
lua = r'''-- porto/seaglass2 (job 32): EDIT mode. Sea glass and shells on every beach, more of them. Three exact finds in
-- workspace.SeaGlass.SeaGlassServer (@@N@@ chars, the job 18 text); compiled before writing; original ->
-- ServerStorage.HudBackup.SeaGlassServer_pre_seaglass2. Then the beach boxes and counts go on workspace.SeaGlass as
-- attributes (box 1 = Bella's beach keeps BoxMin/BoxMax). Output lines start with "QQ SG2".
if game:GetService("RunService"):IsRunning() then warn("QQ SG2 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassServer")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ SG2 ABORT - missing workspace.SeaGlass.SeaGlassServer") return end
if #s.Source ~= @@N@@ then warn(string.format("QQ SG2 ABORT - SeaGlassServer is %d chars, expected @@N@@ (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ SG2 ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ SG2 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ SG2 ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassServer_pre_seaglass2"; c.Enabled = false; c.Parent = backup
s.Source = o
@@ATTRS@@
local list = {}
for k, v in pairs(G:GetAttributes()) do if tostring(k):find("^Box") or tostring(k):find("^Count") then table.insert(list, k .. "=" .. tostring(v)) end end
table.sort(list)
print(string.format("QQ SG2 DONE: SeaGlassServer %d chars; %s; backup ServerStorage.HudBackup.SeaGlassServer_pre_seaglass2", #s.Source, table.concat(list, "; ")))
'''
for k, v in {"N": str(N), "F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2), "F3": L(F3), "R3": L(R3), "ATTRS": "\n".join(attrs)}.items():
    lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/seaglass2.lua").write_text(lua, encoding="utf-8")
SRC.write_text(out, encoding="utf-8")
print("seaglass2.lua", len(lua.encode()), "chars; SeaGlassServer", N, "->", len(out.encode()), "; beaches:", 1 + len(BOXES))
