#!/usr/bin/env python3
"""Builds tools/porto/seaglass8.lua (job 51): the real cause of Bella's panel hanging off the right of a phone screen. The
runner's note after job 50: Studio's panel is still built with AnchorPoint (0.5, 0.5) (seaglass5's anchoring line never
reached Studio), so the layout's Position (1, -4) put the panel's CENTRE on the screen edge; job 50's clamp pulls it back a
frame later. The layout now sets the anchor itself. One exact find in workspace.SeaGlass.SeaGlassClient (after job 50, about
15822 chars); original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass8. Run from the repo root.
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
F1 = '\tpanel.Position = UDim2.new(1, phone() and -4 or -14, 0.5, 0)   -- a phone: hard against the right edge (Oct 9)\n'
R1 = '\tpanel.AnchorPoint = Vector2.new(1, 0.5)   -- anchored by its right edge (the construction line still said the centre; half of it hung off a phone - Oct 9)\n' + F1
N = 15822   # Studio after job 50 (the runner's count)
src = ROOT / "tools/porto/src/SeaGlassClient.lua"; t = src.read_text(encoding="utf-8")
if F1 in t and R1 not in t: assert t.count(F1) == 1; t = t.replace(F1, R1); src.write_text(t, encoding="utf-8")
else: assert R1 in t
lua = r'''-- porto/seaglass8 (job 51): EDIT mode. Bella's panel anchored by its right edge in the layout itself (Studio still builds
-- it centre-anchored, so Position (1, -4) hung half of it off a phone screen). One exact find in
-- workspace.SeaGlass.SeaGlassClient (after job 50, about @@N@@ chars); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass8. Output "QQ SG8".
if game:GetService("RunService"):IsRunning() then warn("QQ SG8 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG8 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - @@N@@) > 60 then warn(string.format("QQ SG8 ABORT - SeaGlassClient is %d chars, expected about @@N@@ (job 50 not run yet, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
if o:find(@@R1@@, 1, true) then warn("QQ SG8 ABORT - already patched; nothing changed") return end
local a, b = o:find(@@F1@@, 1, true)
if not a then warn("QQ SG8 ABORT - the position line was not found; nothing changed. Source is " .. before .. " chars") return end
if o:find(@@F1@@, b + 1, true) then warn("QQ SG8 ABORT - the find matches more than once; nothing changed") return end
o = o:sub(1, a - 1) .. @@R1@@ .. o:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ SG8 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass8"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG8 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass8", before, #s.Source))
'''
for k, v in {"N": str(N), "F1": L(F1), "R1": L(R1)}.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/seaglass8.lua").write_text(lua, encoding="utf-8")
print("seaglass8.lua", len(lua.encode()), "chars; expects SeaGlassClient about", N)
