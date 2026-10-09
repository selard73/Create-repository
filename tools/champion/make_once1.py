#!/usr/bin/env python3
"""Builds tools/champion/once1.lua (job 26): the Grand Keeper statue (France) once per player, and counted on France's
squirrels only. Shannon, Oct 9 VR test: "you could only get one statue once as a player in each map; so far it has given
me the statue twice in the France map". Why twice: the Champion counted every tagged squirrel (44 France + 44 Porto = 88
since Oct 7) and let a player win again at a higher total; her first statue was at 44, her second at 88.
Patches workspace.Champion.ChampionServer by exact finds taken from village/build_champion.lua (the build the script came
from); every find must hit once and the result must compile. Original -> ServerStorage.HudBackup.ChampionServer_pre_once1.
Run from the repo root: python3 tools/champion/make_once1.py
"""
import pathlib, re
ROOT = pathlib.Path(__file__).resolve().parents[2]
build = (ROOT / "village/build_champion.lua").read_text(encoding="utf-8")

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
def one(s):
    assert build.count(s) == 1, s[:70]
    return s

F1 = one("\tfor _, e in ipairs(hall) do if e.uid == uid and (tonumber(e.total) or 44) >= total then return true end end\n")
R1 = "\tfor _, e in ipairs(hall) do if e.uid == uid then return true end end   -- once per player, whatever the total (Shannon, Oct 9 2026)\n"
m = re.search(r"local function totalSquirrels\(\)\n.*?\n\treturn n\nend\n", build, re.S)
F2 = one(m.group(0))
R2 = '''-- France only (Shannon, Oct 9 2026): the Keeper is French Squirrel Country's statue; Porto Nocciola has its own Guardian.
local frenchIds, FRANCE = {}, {forest = true, village = true, domaine = true}
pcall(function()
	local reg = require(workspace:WaitForChild("SquirrelScripts", 10):WaitForChild("SquirrelRegistry", 10))
	for _, e in ipairs(reg.squirrels or {}) do if FRANCE[e.map] then frenchIds[e.id] = true end end
end)
local function isPorto(m, id)
	if next(frenchIds) then return not frenchIds[id] end
	local ok, p = pcall(function() return m:GetPivot().Position end)   -- no registry to ask: Porto lies south of z -400
	return ok and p.Z < -400
end
local function totalSquirrels()
	local ids, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and not ids[id] and not isPorto(m, id) then ids[id] = true; n += 1 end
	end
	return n
end
local function frenchFound(pl) return (pl:GetAttribute("Found_forest") or 0) + (pl:GetAttribute("Found_village") or 0) + (pl:GetAttribute("Found_domaine") or 0) end
'''
F3 = one('\t\tlocal last = tonumber(player:GetAttribute("SquirrelsFound")) or 0\n')
R3 = "\t\tlocal last = frenchFound(player)\n"
F4 = one('\t\t\tlocal now = tonumber(player:GetAttribute("SquirrelsFound")) or 0\n')
R4 = "\t\t\tlocal now = frenchFound(player)\n"
# the build's own server text, patched, for the syntax check
srv = re.search(r"local SERVER = \[==\[(.*?)\]==\]", build, re.S).group(1)
for a, b in ((F1, R1), (F2, R2), (F3, R3), (F4, R4)):
    assert srv.count(a) == 1, a[:60]; srv = srv.replace(a, b)
chk = ROOT / "tools/champion/check"; chk.mkdir(parents=True, exist_ok=True)
(chk / "ChampionServer.lua").write_text(srv, encoding="utf-8")

lua = r'''-- champion/once1 (job 26): EDIT mode. The Grand Keeper statue once per player, counted on France's 44 squirrels only
-- (Porto's 44 no longer raise the bar to 88 or let a Keeper win again). Four exact finds in
-- workspace.Champion.ChampionServer; compiled before writing; original -> ServerStorage.HudBackup.ChampionServer_pre_once1.
-- Output lines start with "QQ ONCE".
if game:GetService("RunService"):IsRunning() then warn("QQ ONCE ABORT - Play mode") return end
local C = workspace:FindFirstChild("Champion")
local s = C and C:FindFirstChild("ChampionServer")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ ONCE ABORT - missing workspace.Champion.ChampionServer") return end
print("QQ ONCE ChampionServer is " .. #s.Source .. " chars")
local o = s.Source
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}, {@@F4@@, @@R4@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ ONCE ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ ONCE ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ ONCE ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "ChampionServer_pre_once1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ ONCE DONE: ChampionServer %d chars; backup ServerStorage.HudBackup.ChampionServer_pre_once1", #s.Source))
'''
for k, v in {"F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2), "F3": L(F3), "R3": L(R3), "F4": L(F4), "R4": L(R4)}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/champion/once1.lua").write_text(lua, encoding="utf-8")
print("once1.lua", len(lua.encode()), "chars; check copy tools/champion/check/ChampionServer.lua")
