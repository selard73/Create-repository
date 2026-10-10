#!/usr/bin/env python3
"""Builds tools/porto/seaglass12.lua (job 62): Bella's reveal in VR "a little too big and in your face" (Shannon, Oct 10):
a touch smaller (1.15x instead of 1.5x) and a little farther off (3.3 studs instead of 2.8). Two exact finds in
workspace.SeaGlass.SeaGlassClient after job 57 (about 18853 chars); original -> HudBackup.SeaGlassClient_pre_seaglass12.
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
F1 = '\t\tbase = rcf * CFrame.new(0, -0.35, -2.8)\n'
R1 = '\t\tbase = rcf * CFrame.new(0, -0.3, -3.3)   -- (a little farther off: "slightly smaller please", Oct 10)\n'
F2 = '\t\tpcall(m.ScaleTo, m, 1.5)\n'
R2 = '\t\tpcall(m.ScaleTo, m, 1.15)\n'
PAIRS = [(F1, R1), (F2, R2)]
N = 18853   # Studio after job 57 (the runner's count)
src = ROOT / "tools/porto/src/SeaGlassClient.lua"; t = src.read_text(encoding="utf-8")
if R1 not in t:
    for a, b in PAIRS: assert t.count(a) == 1, a[:50]; t = t.replace(a, b)
    src.write_text(t, encoding="utf-8")
lua = r'''-- porto/seaglass12 (job 62): EDIT mode. Bella's reveal in VR a touch smaller and farther off. Two exact finds in
-- workspace.SeaGlass.SeaGlassClient (after job 57, about @@N@@ chars); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass12. Output "QQ SG12".
if game:GetService("RunService"):IsRunning() then warn("QQ SG12 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG12 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - @@N@@) > 60 then warn(string.format("QQ SG12 ABORT - SeaGlassClient is %d chars, expected about @@N@@ (job 57 not run, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ SG12 ABORT - find " .. i .. " not found (already patched?); nothing changed. Source is " .. before .. " chars") return end
	if o:find(p[1], b + 1, true) then warn("QQ SG12 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ SG12 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass12"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG12 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass12", before, #s.Source))
'''
rep = {"N": str(N)}
for i, (a, b) in enumerate(PAIRS, 1): rep["F%d" % i] = L(a); rep["R%d" % i] = L(b)
for k, v in rep.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/seaglass12.lua").write_text(lua, encoding="utf-8")
print("seaglass12.lua", len(lua.encode()), "chars; expects SeaGlassClient about", N)
