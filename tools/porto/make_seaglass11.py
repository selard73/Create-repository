#!/usr/bin/env python3
"""Builds tools/porto/seaglass11.lua (job 57): Bella's reveal in VR. Shannon (VR, Oct 10): "it spawns halfway in the
stairway; the reveal should make the item appear on top of everything else on the screen for a moment, front and center,
even in VR". In a headset the made thing now appears 2.8 studs in front of your eyes where you are looking at that moment
(not pinned to your head), a little larger, rising only a little, spinning and sparkling as before. Two exact finds in
workspace.SeaGlass.SeaGlassClient after job 53 (about 18492 chars; the lift line is found in either of its two forms);
original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass11. Run from the repo root.
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
F1 = '\tlocal look = cam and Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z) or Vector3.new(0, 0, -1)\n'
R1 = ('\tif UIS.VREnabled and cam then   -- VR: in front of your eyes, where you look at this moment (Shannon: "front and center, even in VR")\n'
      '\t\tlocal okc, rcf = pcall(cam.GetRenderCFrame, cam); rcf = okc and rcf or cam.CFrame\n'
      '\t\tbase = rcf * CFrame.new(0, -0.35, -2.8)\n'
      '\t\tpcall(m.ScaleTo, m, 1.5)\n'
      '\tend\n'
      '\tlocal look = cam and Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z) or Vector3.new(0, 0, -1)\n')
F2A = '\t\tlocal lift = 2.4 * k + 0.15 * math.sin(t * 2.2)\n'   # Studio (never patched)
F2B = '\t\tlocal lift = 1.8 * k + 0.15 * math.sin(t * 2.2)\n'   # the repo src
R2 = '\t\tlocal lift = (UIS.VREnabled and 0.45 or 1.8) * k + 0.15 * math.sin(t * 2.2)   -- (in VR it is already at eye level)\n'
N = 18492   # Studio after job 53 (the runner's count)
src = ROOT / "tools/porto/src/SeaGlassClient.lua"; t = src.read_text(encoding="utf-8")
if R1 not in t:
    assert t.count(F1) == 1; t = t.replace(F1, R1)
    f2 = F2A if F2A in t else F2B; assert t.count(f2) == 1; t = t.replace(f2, R2)
    src.write_text(t, encoding="utf-8")
lua = r'''-- porto/seaglass11 (job 57): EDIT mode. Bella's reveal in VR: in front of your eyes, front and centre. Two exact finds in
-- workspace.SeaGlass.SeaGlassClient (after job 53, about @@N@@ chars); compiled before writing;
-- original -> ServerStorage.HudBackup.SeaGlassClient_pre_seaglass11. Output "QQ SG11".
if game:GetService("RunService"):IsRunning() then warn("QQ SG11 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local s = G and G:FindFirstChild("SeaGlassClient")
if not s then warn("QQ SG11 ABORT - missing workspace.SeaGlass.SeaGlassClient") return end
if math.abs(#s.Source - @@N@@) > 60 then warn(string.format("QQ SG11 ABORT - SeaGlassClient is %d chars, expected about @@N@@ (job 53 not run, or changed); nothing changed", #s.Source)) return end
local o = s.Source
local before = #o
local function one(src, find, rep, what)
	local a, b = src:find(find, 1, true)
	if not a then return nil, what .. " not found" end
	if src:find(find, b + 1, true) then return nil, what .. " matches more than once" end
	return src:sub(1, a - 1) .. rep .. src:sub(b + 1)
end
local err
o, err = one(o, @@F1@@, @@R1@@, "the look line"); if not o then warn("QQ SG11 ABORT - " .. err .. " (already patched?); nothing changed") return end
local o2 = one(o, @@F2A@@, @@R2@@, "the lift line (2.4)")
if not o2 then o2, err = one(o, @@F2B@@, @@R2@@, "the lift line (1.8)") end
if not o2 then warn("QQ SG11 ABORT - " .. err .. "; nothing changed") return end
o = o2
local f, cerr = loadstring(o)
if not f then warn("QQ SG11 ABORT - patched source does not compile: " .. tostring(cerr)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "SeaGlassClient_pre_seaglass11"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ SG11 DONE: SeaGlassClient %d -> %d chars; backup ServerStorage.HudBackup.SeaGlassClient_pre_seaglass11", before, #s.Source))
'''
for k, v in {"N": str(N), "F1": L(F1), "R1": L(R1), "F2A": L(F2A), "F2B": L(F2B), "R2": L(R2)}.items(): lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/porto/seaglass11.lua").write_text(lua, encoding="utf-8")
print("seaglass11.lua", len(lua.encode()), "chars; expects SeaGlassClient about", N, "-> src now", len(t.encode()))
