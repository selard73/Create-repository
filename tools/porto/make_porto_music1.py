#!/usr/bin/env python3
"""Builds tools/porto/porto_music1.lua (job 20): map music comes back for players who reach Porto by travel or the boat.
TravelServer (arrival in Porto) and BoatServer (boarding) set the character's NoMusic from before Porto had music, and
nothing in Porto cleared it, so the music stayed off until a respawn. A watcher in PortoActivities clears NoMusic once the
character stands on its own feet past the dock line (MapMusic.PortoZ, -594), not seated, not falling, and not silenced
by the opera. First a READ-ONLY scan: every script mentioning NoMusic; aborts if another enabled script sets it.
Updates tools/porto/src/PortoActivities.lua. Run from the repo root: python3 tools/porto/make_porto_music1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/porto/src/PortoActivities.lua"

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

F1 = "-- ---------- the opera duet: a Listen prompt and the aria ----------\n"
R1 = "local operaHushed = {}   -- characters the opera has silenced (the music watcher at the end leaves them alone)\n" + F1
F2 = "\tlocal hushed = {}\n"
R2 = "\tlocal hushed = operaHushed\n"
F3 = '\nprint("PortoActivities: ready")'
R3 = '''
-- ---------- the map music after travel or the boat (Shannon, Oct 9) ----------
-- Travel to Porto and the boat set NoMusic (from before Porto had music) and nothing cleared it, so arrivals heard no
-- music until they respawned. Once a character stands on its own feet in Porto (past the dock line, not seated, not
-- falling) and the opera is not singing to it, the flag goes and MapMusic.MusicClient plays the Porto track again.
local MapMusic = workspace:FindFirstChild("MapMusic")
task.spawn(function()
	while true do
		task.wait(1)
		local portoZ = MapMusic and MapMusic:GetAttribute("PortoZ") or -594
		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and char:GetAttribute("NoMusic") and not operaHushed[char] and root.Position.Z < portoZ
				and hum.SeatPart == nil and hum.FloorMaterial ~= Enum.Material.Air then
				char:SetAttribute("NoMusic", nil)
			end
		end
	end
end)
''' + F3
src = SRC.read_text(encoding="utf-8")
if R2 in src: src = src.replace(R3, F3).replace(R2, F2).replace(R1, F1)
for f in (F1, F2, F3): assert src.count(f) == 1, f
N = len(src.encode())
out = src.replace(F1, R1).replace(F2, R2).replace(F3, R3)

lua = r'''-- porto/porto_music1 (job 20): EDIT mode. The map music comes back for players who reach Porto by travel or the boat.
-- READ-ONLY scan first (QQ MUS lines: every script that mentions NoMusic); it stops if an enabled script other than
-- TravelServer / BoatServer / PortoActivities / MusicClient sets NoMusic. Then three exact finds in
-- workspace.PortoPassport.PortoActivities (the job 19 text, @@N@@ chars), compiled before writing;
-- original -> ServerStorage.HudBackup.PortoActivities_pre_music1.
if game:GetService("RunService"):IsRunning() then warn("QQ MUS ABORT - Play mode") return end
local KNOWN = {TravelServer = true, BoatServer = true, PortoActivities = true, MusicClient = true}
local other = 0
for _, root in ipairs({workspace, game:GetService("ServerScriptService"), game:GetService("ReplicatedStorage"), game:GetService("StarterPlayer"), game:GetService("StarterGui")}) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("LuaSourceContainer") and d.Source:find("NoMusic", 1, true) then
			local on = not d:IsA("BaseScript") or d.Enabled
			local sets = d.Source:find('"NoMusic", true', 1, true) ~= nil
			print(string.format("QQ MUS %s | %s | enabled=%s sets=%s", d:GetFullName(), d.ClassName, tostring(on), tostring(sets)))
			if on and sets and not KNOWN[d.Name] then other += 1 end
		end
	end
end
if other > 0 then warn("QQ MUS ABORT - another script sets NoMusic (listed above); nothing changed") return end
local PP = workspace:FindFirstChild("PortoPassport")
local s = PP and PP:FindFirstChild("PortoActivities")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ MUS ABORT - missing workspace.PortoPassport.PortoActivities") return end
if #s.Source ~= @@N@@ then warn(string.format("QQ MUS ABORT - PortoActivities is %d chars, expected @@N@@ (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a or o:find(p[1], b + 1, true) then warn("QQ MUS ABORT - find " .. i .. " does not match exactly once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ MUS ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "PortoActivities_pre_music1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ MUS DONE: PortoActivities %d -> %d chars; backup ServerStorage.HudBackup.PortoActivities_pre_music1", @@N@@, #s.Source))
'''
for k, v in {"N": str(N), "F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2), "F3": L(F3), "R3": L(R3)}.items():
    lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/porto_music1.lua").write_text(lua, encoding="utf-8")
SRC.write_text(out, encoding="utf-8")
print("porto_music1.lua", len(lua.encode()), "; PortoActivities", N, "->", len(out.encode()))
