#!/usr/bin/env python3
"""Builds tools/statues/armfix1.lua (job 107): the statues' second right arm (Shannon, Oct 15 2026: "giving the statues 2 arms on the
right hand side, one that holds up the acorn and the original arm the player avatar has"). Every statue (the fountain's, the Hall of
Fame's, the Guardian of the Harbour) comes from one function, Champion.MakeStatue in workspace.Champion.ChampionServer, which builds
the avatar, parents it, waits six frames, then carves the arms. Two ways to get a second, unposed right arm on the same spot, both
seen in the code: (a) two builds overlapping (the keeper retries, a Hall refresh) - both parent a figure called "Figure" to the same
folder, the earlier one is never taken down; (b) a build that fails after parenting (the pose step threw) leaves a figure with its
arms down, and the retry stands a posed one in it. Every other body part overlaps exactly, so only the raised arm shows twice.
Two exact-string patches: MakeStatue runs one build at a time (a 60 s queue, pcall'd so a failure frees the queue), and a figure of
the same name already in the target folder is destroyed before the new one is parented. Backup HudBackup.ChampionServer_pre_armfix1;
marker ARMFIX1. Self-test on the repo's copy (village/build_champion.lua) with the luau CLI. Run from the repo root."""
import pathlib, subprocess, os
ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent
MARK = "ARMFIX1"
P = [
 ('mk.OnInvoke = function(rec, o) return makeFigure(rec, o) end\n',
  'local making = false   -- ARMFIX1_20261015: one figure at a time - two overlapping builds left two statues on one spot (one posed, one not)\n'
  'mk.OnInvoke = function(rec, o)\n'
  '\tlocal t0 = os.clock()\n'
  '\twhile making and os.clock() - t0 < 60 do task.wait(0.1) end\n'
  '\tmaking = true\n'
  '\tlocal ok, m, a, r, l = pcall(makeFigure, rec, o)\n'
  '\tmaking = false\n'
  '\tif not ok then error(m) end\n'
  '\treturn m, a, r, l\n'
  'end\n'),
 ('\tif hum then hum:Destroy() end\n\tstoneify(model)\n',
  '\t-- ARMFIX1 round 2 (runner 7 reproduced it on nana3365308\'s "T2_Ballet_Sleeves", a LAYERED jacket): a WrapLayer top deforms with the\n'
  '\t-- living rig, not with the carved pose, so its sleeve stays where the arm was - a thin second arm beside the raised one. Marble wears\n'
  '\t-- no cloth: layered upper-body clothing comes off before the carving; layered pants and shoes keep (no arms in them).\n'
  '\tdo\n'
  '\t\tlocal UPPER = {Jacket = true, Shirt = true, TShirt = true, Sweater = true, DressSkirt = true}\n'
  '\t\tfor _, acc in ipairs(model:GetChildren()) do\n'
  '\t\t\tif acc:IsA("Accessory") and acc:FindFirstChildWhichIsA("WrapLayer", true) then\n'
  '\t\t\t\tlocal okT, t = pcall(function() return acc.AccessoryType.Name end)\n'
  '\t\t\t\tif okT and UPPER[t] then acc:Destroy() end\n'
  '\t\t\tend\n'
  '\t\tend\n'
  '\tend\n'
  '\tif hum then hum:Destroy() end\n\tstoneify(model)\n'),
 ('\tmodel.Parent = o.parent or F\n',
  '\tdo   -- ARMFIX1: a figure of this name already on the spot (an earlier build never taken down, or one left half-posed by a failed build) goes first\n'
  '\t\tlocal par = o.parent or F\n'
  '\t\tfor _, s in ipairs(par:GetChildren()) do\n'
  '\t\t\tif s ~= model and s:IsA("Model") and s.Name == model.Name and s:FindFirstChild("RightHand") then s:Destroy() end\n'
  '\t\tend\n'
  '\tend\n'
  '\tmodel.Parent = o.parent or F\n'),
]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
src = (HERE / "studio_2026-10-15/ChampionServer.lua").read_text(encoding="utf-8")   # the live export (34338 bytes, verified by runner 7)
assert len(src.encode("utf-8")) == 34338, len(src.encode("utf-8"))
assert MARK not in src
test = src
for i, (f, r) in enumerate(P):
    assert test.count(f) == 1, (i, test.count(f))
    test = test.replace(f, r)
chk = HERE / "check"; chk.mkdir(exist_ok=True)
(chk / "ChampionServer_armfix1.lua").write_text(test, encoding="utf-8")
luau = os.environ.get("LUAU_COMPILE")
if luau:
    res = subprocess.run([luau, "--null", str(chk / "ChampionServer_armfix1.lua")], capture_output=True, text=True)
    assert "Error" not in (res.stdout + res.stderr), res.stdout + res.stderr
    print("self-test: the patched ChampionServer compiles")
lua = r'''-- statues/armfix1 (job 107): EDIT mode. Statues no longer get a second right arm: workspace.Champion.ChampionServer's MakeStatue
-- builds one figure at a time and removes a same-named figure already on the spot before parenting the new one (Shannon, Oct 15 2026).
-- Three exact-string patches (round 2 adds: layered upper-body clothing comes off the figure before the carving - the reproduced cause), counted first; compiled where loadstring runs; original -> ServerStorage.HudBackup.ChampionServer_pre_armfix1.
-- Output "QQ ARM".
if game:GetService("RunService"):IsRunning() then print("QQ ARM ABORT - Play mode") return end
local CH = workspace:FindFirstChild("Champion")
local s = CH and CH:FindFirstChild("ChampionServer")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ ARM ABORT - missing workspace.Champion.ChampionServer") return end
local o = s.Source
print("QQ ARM ChampionServer is " .. #o .. " chars")
if o:find("ARMFIX1", 1, true) then print("QQ ARM DONE (already patched): ChampionServer " .. #o) return end
local P = {{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}}
for i, p in ipairs(P) do
	local a, b = o:find(p[1], 1, true)
	if not a then print("QQ ARM ABORT - anchor " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then print("QQ ARM ABORT - anchor " .. i .. " matches more than once; nothing changed") return end
end
local n = o
for _, p in ipairs(P) do local a, b = n:find(p[1], 1, true); n = n:sub(1, a - 1) .. p[2] .. n:sub(b + 1) end
do
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ ARM ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
if not backup:FindFirstChild("ChampionServer_pre_armfix1") then local c = s:Clone(); if c then c.Name = "ChampionServer_pre_armfix1"; c.Enabled = false; c.Parent = backup end end
s.Source = n
print(string.format("QQ ARM DONE: ChampionServer %d -> %d chars; backup ServerStorage.HudBackup.ChampionServer_pre_armfix1", #o, #n))
'''
for k, v in {"F1": L(P[0][0]), "R1": L(P[0][1]), "F2": L(P[1][0]), "R2": L(P[1][1]), "F3": L(P[2][0]), "R3": L(P[2][1])}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(HERE / "armfix1.lua").write_text(lua, encoding="utf-8")
print("armfix1.lua", len(lua.encode()), "bytes")
