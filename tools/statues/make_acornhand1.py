#!/usr/bin/env python3
"""Builds tools/statues/acornhand1.lua (job 107c): the giant acorn rests in the statue's PALM (the hand's grip attachment) instead of
on top of the hand part's box. Runner 7 on Captin_crunch65's statue: a body package whose LeftHand part is 2.85 studs tall (the visible
hand is far lower), so the acorn sat on the box's top, about a head above the statue. One exact-string patch of
workspace.Champion.ChampionServer (self-tested on the live, armfix1-patched copy); the old spot stays as the fallback when a rig has
no grip attachment. Backup HudBackup.ChampionServer_pre_acornhand1; marker ACORNHAND1. Run from the repo root (LUAU_COMPILE=path)."""
import pathlib, subprocess, os
HERE = pathlib.Path(__file__).resolve().parent
F1 = '\t\t\tplaceOn(a, holding.Position.X, holding.Position.Y + holding.Size.Y / 2 - 0.2, holding.Position.Z)   -- resting on the raised hand\n'
R1 = ('\t\t\t-- ACORNHAND1_20261015: the acorn rests in the PALM (the hand\'s grip attachment), whatever the body package\'s hand box - a package\n'
      '\t\t\t-- with a 2.85-stud hand part put the acorn a head above the visible hand (Shannon\'s "star" statue); the old spot is the fallback\n'
      '\t\t\tlocal grip = holding:FindFirstChild(holdSide .. "GripAttachment")\n'
      '\t\t\tif grip then placeOn(a, grip.WorldPosition.X, grip.WorldPosition.Y + 0.15, grip.WorldPosition.Z)\n'
      '\t\t\telse placeOn(a, holding.Position.X, holding.Position.Y + holding.Size.Y / 2 - 0.2, holding.Position.Z) end   -- resting on the raised hand\n')
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
live = (HERE / "check/ChampionServer_armfix1.lua").read_text(encoding="utf-8")
assert live.count(F1) == 1 and "ACORNHAND1" not in live and "local holdSide" in live
chk = HERE / "check"; (chk / "ChampionServer_acornhand1.lua").write_text(live.replace(F1, R1), encoding="utf-8")
luau = os.environ.get("LUAU_COMPILE")
if luau:
    r = subprocess.run([luau, "--null", str(chk / "ChampionServer_acornhand1.lua")], capture_output=True, text=True)
    assert "Error" not in (r.stdout + r.stderr), r.stdout + r.stderr
    print("self-test: the patched ChampionServer compiles")
lua = r'''-- statues/acornhand1 (job 107c): EDIT mode. The giant acorn rests in the statue's palm (the hand's grip attachment), not on top of
-- the hand part's box (Shannon's "star" statue: a long-handed body package put it a head above the hand). One exact-string patch of
-- workspace.Champion.ChampionServer; counted first; compiled where loadstring runs; backup HudBackup.ChampionServer_pre_acornhand1.
-- Statues already standing keep their acorn until they are rebuilt. Output "QQ ACORN".
if game:GetService("RunService"):IsRunning() then print("QQ ACORN ABORT - Play mode") return end
local CH = workspace:FindFirstChild("Champion")
local s = CH and CH:FindFirstChild("ChampionServer")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ ACORN ABORT - missing workspace.Champion.ChampionServer") return end
local o = s.Source
if o:find("ACORNHAND1", 1, true) then print("QQ ACORN DONE (already patched): " .. #o) return end
local F1, R1 = @@F1@@, @@R1@@
local a, b = o:find(F1, 1, true)
if not a then print("QQ ACORN ABORT - anchor not found (" .. #o .. " chars); nothing changed") return end
if o:find(F1, b + 1, true) then print("QQ ACORN ABORT - anchor matches more than once; nothing changed") return end
local n = o:sub(1, a - 1) .. R1 .. o:sub(b + 1)
do local ok, f, err = pcall(function() return loadstring(n) end); if ok and not f then print("QQ ACORN ABORT - patched source does not compile: " .. tostring(err)) return end end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
if not hb:FindFirstChild("ChampionServer_pre_acornhand1") then local c = s:Clone(); if c then c.Name = "ChampionServer_pre_acornhand1"; c.Enabled = false; c.Parent = hb end end
s.Source = n
print(string.format("QQ ACORN DONE: ChampionServer %d -> %d chars; backup HudBackup.ChampionServer_pre_acornhand1", #o, #n))
'''
for k, v in {"@@F1@@": L(F1), "@@R1@@": L(R1)}.items():
    assert lua.count(k) == 1; lua = lua.replace(k, v)
(HERE / "acornhand1.lua").write_text(lua, encoding="utf-8")
print("acornhand1.lua", len(lua.encode()), "bytes")
