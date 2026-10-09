#!/usr/bin/env python3
"""Builds tools/champion/once1.lua (job 26): the Grand Keeper statue (France) once per player, and counted on France's
squirrels only. Shannon, Oct 9 VR test: "you could only get one statue once as a player in each map; so far it has given
me the statue twice in the France map". Why twice: the Champion counted every tagged squirrel (44 France + 44 Porto = 88
since Oct 7) and let a player win again at a higher total; her first statue was at 44, her second at 88.
Job 24 (Oct 9) showed Studio's ChampionServer (34314 chars) already counts France's squirrels only (an Oct 3 patch),
so the one change is hallHas: once per player. The find is checked against village/build_champion.lua too. Original -> ServerStorage.HudBackup.ChampionServer_pre_once1.
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
# the build's own server text, patched, for the syntax check
srv = re.search(r"local SERVER = \[==\[(.*?)\]==\]", build, re.S).group(1)
for a, b in ((F1, R1),):
    assert srv.count(a) == 1, a[:60]; srv = srv.replace(a, b)
chk = ROOT / "tools/champion/check"; chk.mkdir(parents=True, exist_ok=True)
(chk / "ChampionServer.lua").write_text(srv, encoding="utf-8")

lua = r'''-- champion/once1 (job 26): EDIT mode. The Grand Keeper statue once per player: a Keeper never wins again, whatever the
-- squirrel total becomes. One exact find in workspace.Champion.ChampionServer (34314 chars, the job 24 text); compiled
-- before writing; original -> ServerStorage.HudBackup.ChampionServer_pre_once1.
-- Output lines start with "QQ ONCE".
if game:GetService("RunService"):IsRunning() then warn("QQ ONCE ABORT - Play mode") return end
local C = workspace:FindFirstChild("Champion")
local s = C and C:FindFirstChild("ChampionServer")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ ONCE ABORT - missing workspace.Champion.ChampionServer") return end
if #s.Source ~= 34314 then warn(string.format("QQ ONCE ABORT - ChampionServer is %d chars, expected 34314 (already patched, or changed); nothing changed", #s.Source)) return end
local o = s.Source
for i, p in ipairs({{@@F1@@, @@R1@@}}) do
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
for k, v in {"F1": L(F1), "R1": L(R1)}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/champion/once1.lua").write_text(lua, encoding="utf-8")
print("once1.lua", len(lua.encode()), "chars; check copy tools/champion/check/ChampionServer.lua")
