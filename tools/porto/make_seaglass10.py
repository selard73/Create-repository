#!/usr/bin/env python3
"""Builds tools/porto/seaglass10.lua (job 53): Shannon on desktop after job 52: "we need to make the same change for the
reveal for bella that we did on phone, you cannot see the reveal; and please also edge the picker modal a little to the
left". The on-screen reveal window now shows on every flat screen (desktop, phone, tablet; VR keeps the world reveal),
a little smaller on a big screen; the panel sits 30 px in from the right edge on a desktop (14 on a phone, which she
called perfect). Three exact finds in workspace.SeaGlass.SeaGlassClient after job 52 (about 18296 chars);
original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass10. Run from the repo root.
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
F1 = '\tif phone() then pcall(screenReveal, m:Clone()) end   -- a phone: big and on top; the world one below carries on (and its sound)\n'
R1 = '\tif not UIS.VREnabled then pcall(screenReveal, m:Clone()) end   -- every flat screen (desktop too - Shannon): big and on top; the world one below carries on (and its sound); VR keeps the world one\n'
F2 = '\tpanel.Position = UDim2.new(1, -14, 0.5, 0)   -- 14 px off the right edge on every screen (Shannon\'s phone: "zero space")\n'
R2 = '\tpanel.Position = UDim2.new(1, phone() and -14 or -30, 0.5, 0)   -- 14 px off the right edge on a phone ("perfect"), 30 on a desktop ("a little to the left") - Shannon, Oct 9\n'
F3 = '\tlocal size = math.floor(math.min(v.Y * 0.64, v.X * 0.42))\n'
R3 = '\tlocal size = math.floor(math.min(v.Y * (phone() and 0.64 or 0.5), v.X * 0.42))   -- a phone needs most of its height; a desktop half\n'
PAIRS = [(F1, R1), (F2, R2), (F3, R3)]
N = 18296   # Studio after job 52 (the runner's count)
src = ROOT / "tools/porto/src/SeaGlassClient.lua"; t = src.read_text(encoding="utf-8")
if R1 not in t:
    for a, b in PAIRS: assert t.count(a) == 1, a[:60]; t = t.replace(a, b)
    src.write_text(t, encoding="utf-8")
lua = r'''-- porto/seaglass10 (job 53): EDIT mode. Bella's reveal window on every flat screen (desktop too), the panel 30 px in on a
-- desktop. Three exact finds in workspace.SeaGlass.SeaGlassClient (after job 52, about @@N@@ chars); compiled before
-- writing; original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass10. Output "QQ SG10".
if game:GetService("RunService"):IsRunning() then warn("QQ SG10 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG10 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - @@N@@) > 60 then warn(string.format("QQ SG10 ABORT - SeaGlassClient is %d chars, expected about @@N@@ (job 52 not run, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ SG10 ABORT - find " .. i .. " not found (already patched?); nothing changed. Source is " .. before .. " chars") return end
	if o:find(p[1], b + 1, true) then warn("QQ SG10 ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ SG10 ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass10"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG10 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass10", before, #s.Source))
'''
rep = {"N": str(N)}
for i, (a, b) in enumerate(PAIRS, 1): rep["F%d" % i] = L(a); rep["R%d" % i] = L(b)
for k, v in rep.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/seaglass10.lua").write_text(lua, encoding="utf-8")
print("seaglass10.lua", len(lua.encode()), "chars; expects SeaGlassClient about", N, "-> src now", len(t.encode()))
