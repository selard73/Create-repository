#!/usr/bin/env python3
"""Builds tools/treehouse/patch_treehouse2_r3.lua: Homebase round 3 as a PATCH over the installed round 2 (runner 7's ask, Oct 15 2026),
not a fresh install. Two fixes:
 1. the floor level with the forest: the hollow's top voxel row (y -4..0) set to occupancy 0.52 wherever it is fuller, so its surface
    draws at y ~0.1 (runner 7's measurement: a row draws at (row top - 2) + 4 x occupancy; the forest's row is 0.52) and the oak's
    roots show;
 2. the sign's post moved behind the board (z 17.6), never across the bottom text line - plus the round-3 room furniture (table, stools,
    mug, window shelf and plant, rug and cushion), all in TreehouseClient2.lua: the installed TreehouseClient is disabled, cloned to
    HudBackup.TreehouseClient_pre_r3_n, and replaced by a fresh Script with the new source (in play, the fresh client restarts cleanly:
    it clears the older client's Treehouse_local folder and TreehouseGui itself).
Runs in Studio EDIT (re-runnable) and as a play-test PREVIEW (discarded on stop). No DataStore, no publish. Output "QQ TREE3".
Run from the repo root."""
from pathlib import Path
HERE = Path(__file__).resolve().parent
CLIENT = (HERE / "src/TreehouseClient2.lua").read_text(encoding="utf-8")
assert "]===]" not in CLIENT
assert "L(-9, 1.5, 17.6)" in CLIENT and "the mug" in CLIENT and "a round rug" in CLIENT
TEMPLATE = '''-- patch_treehouse2_r3.lua (Studio EDIT; re-runnable; also a play-test PREVIEW - discarded on stop). Homebase round 3 as a PATCH over the
-- installed round 2: (1) the hollow's top voxel row to the forest's occupancy 0.52 (surface y ~0.1, the roots show); (2) TreehouseClient
-- replaced by TreehouseClient2 round 3 (@@CLEN@@ chars: the sign's post behind the board, furniture in the room), the old one disabled and
-- kept as HudBackup.TreehouseClient_pre_r3_n. Needs workspace.Treehouse from install_treehouse2.lua. No DataStore, no publish. Output "QQ TREE3".
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local T = workspace.Terrain
local CLIENT = [===[@@CLIENT@@]===]
do
	local ok, f, err = pcall(function() return loadstring(CLIENT) end)
	if ok and not f then print("QQ TREE3 ABORT: TreehouseClient2 does not compile: " .. tostring(err)) return end
end
local F = workspace:FindFirstChild("Treehouse")
if not (F and F:GetAttribute("Tree")) then print("QQ TREE3 ABORT: workspace.Treehouse (install_treehouse2.lua) is not here - nothing to patch") return end
local TREE = HttpService:JSONDecode(F:GetAttribute("Tree"))
local SX, SZ = TREE.x, TREE.z
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Treehouse2 r3") end)
-- ---------- 1: the floor's level ----------
-- a voxel row draws its surface at (row top - 2) + 4 x occupancy, so a FULL top row (y -4..0) renders 2 studs high; the forest's row sits
-- at 0.52 -> y 0.1. The hollow's top row is set to 0.52 wherever it is fuller: inside the bowl (radius 31) and the mouth (x +-26, z 16..32).
local FLOOR_OCC = 0.52
do
	local r = Region3.new(Vector3.new(math.floor((SX - 34) / 4) * 4, -4, math.floor((SZ - 34) / 4) * 4), Vector3.new(math.ceil((SX + 34) / 4) * 4, 0, math.ceil((SZ + 34) / 4) * 4))
	local ch = T:ReadVoxelChannels(r, 4, {"SolidOccupancy"})
	local SO = ch.SolidOccupancy
	local n, seen = 0, 0
	for ix = 1, #SO do for iy = 1, #SO[ix] do for iz = 1, #SO[ix][iy] do
		local x, z = r.CFrame.Position.X - r.Size.X / 2 + (ix - 0.5) * 4, r.CFrame.Position.Z - r.Size.Z / 2 + (iz - 0.5) * 4
		local inside = math.sqrt((x - SX) ^ 2 + (z - SZ) ^ 2) <= 31 or (math.abs(x - SX) <= 26 and z >= 16 and z <= 32)
		if inside then seen += 1; if SO[ix][iy][iz] > FLOOR_OCC then SO[ix][iy][iz] = FLOOR_OCC; n += 1 end end
	end end end
	T:WriteVoxelChannels(r, 4, {SolidOccupancy = SO})
	print(string.format("QQ TREE3 floor: the top voxel row set to %.2f over %d of %d cells in the hollow (surface y ~0.1)", FLOOR_OCC, n, seen))
	-- readback at the oak's foot and at the mouth
	for _, q in ipairs({{SX, SZ, "the oak"}, {SX, SZ + 24, "the mouth"}, {SX - 20, SZ - 10, "the left"}, {SX + 20, SZ - 10, "the right"}}) do
		local rr = Region3.new(Vector3.new(math.floor(q[1] / 4) * 4, -4, math.floor(q[2] / 4) * 4), Vector3.new(math.floor(q[1] / 4) * 4 + 4, 0, math.floor(q[2] / 4) * 4 + 4))
		local c2 = T:ReadVoxelChannels(rr, 4, {"SolidOccupancy", "SolidMaterial"})
		print(string.format("QQ TREE3 readback %s: occupancy %.2f %s -> surface y ~%.1f", q[3], c2.SolidOccupancy[1][1][1], tostring(c2.SolidMaterial[1][1][1]), -2 + 4 * c2.SolidOccupancy[1][1][1]))
	end
end
-- ---------- 2: the client ----------
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local old = F:FindFirstChild("TreehouseClient")
local kept
if old then
	if old:IsA("BaseScript") and old.Source == CLIENT then
		print("QQ TREE3 client: already round 3 (" .. #CLIENT .. " chars) - left as is")
	else
		old.Enabled = false
		local n = 1; while hb:FindFirstChild("TreehouseClient_pre_r3_" .. n) do n += 1 end
		kept = old:Clone(); kept.Name = "TreehouseClient_pre_r3_" .. n; kept.Parent = hb
		old:Destroy(); old = nil
	end
else
	print("QQ TREE3 client: no TreehouseClient in workspace.Treehouse - a fresh one is made")
end
if not old then
	local c = Instance.new("Script"); c.Name = "TreehouseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	print(string.format("QQ TREE3 client: TreehouseClient replaced, %d chars%s", #c.Source, kept and ("; the round-2 copy is HudBackup." .. kept.Name) or ""))
end
local lv = hb:FindFirstChild("Treehouse2_log")
if lv then pcall(function() local l = HttpService:JSONDecode(lv.Value); l.round3 = {floorOcc = FLOOR_OCC, client = #CLIENT, kept = kept and kept.Name or nil}; lv.Value = HttpService:JSONEncode(l) end) end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Treehouse2 r3") end)
print(string.format("QQ TREE3 DONE: the floor's top row at %.2f round (%d, %d); the sign's post behind the board; the room furnished", FLOOR_OCC, SX, SZ))
'''
out = TEMPLATE.replace("@@CLIENT@@", CLIENT).replace("@@CLEN@@", str(len(CLIENT)))
(HERE / "patch_treehouse2_r3.lua").write_text(out, encoding="utf-8")
print("patch_treehouse2_r3.lua", len(out.encode()), "bytes")
