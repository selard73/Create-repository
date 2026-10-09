#!/usr/bin/env python3
"""Builds tools/vr/wardrobe_vr1.lua (job 44): the Passport's Wardrobe tab finds its page on the VR window. WardrobeClient
waits on PassportGui.Page by name; once the VR window has moved PassportGui's children onto its canvas (box named
PassportGui under the SurfaceGui VRWindow in PlayerGui), that wait never ends and the wardrobe tab stays empty in a
headset. The lookup now looks in both places until the page shows up. One exact find in the Script named
WardrobeClient (found anywhere in the workspace); original -> ServerStorage.HudBackup.WardrobeClient_pre_vr1.
Run from the repo root: python3 tools/vr/make_wardrobe_vr1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
F1 = 'local passport=pg:WaitForChild("PassportGui"):WaitForChild("Page")\n'
R1 = ('local passport do -- the page lives on the ScreenGui, or on the VR window\'s canvas in a headset (Oct 9 2026)\n'
      ' local pgui=pg:WaitForChild("PassportGui")\n'
      ' repeat\n'
      '  local vrw=pg:FindFirstChild("VRWindow");local box=vrw and vrw:FindFirstChild("PassportGui")\n'
      '  passport=(box and box:FindFirstChild("Page")) or pgui:FindFirstChild("Page")\n'
      '  if not passport then task.wait(0.2) end\n'
      ' until passport\n'
      'end\n')
src = ROOT / "village/dresses/WardrobeClient.lua"
assert src.read_text(encoding="utf-8").count(F1) == 1
lua = r'''-- vr/wardrobe_vr1 (job 44): EDIT mode. The Wardrobe tab finds its Passport page on the VR window too. One exact find in
-- the Script named WardrobeClient; compiled before writing; original -> ServerStorage.HudBackup.WardrobeClient_pre_vr1.
-- Output lines "QQ WARD".
if game:GetService("RunService"):IsRunning() then warn("QQ WARD ABORT - Play mode") return end
local found = {}
for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Script") and d.Name == "WardrobeClient" then table.insert(found, d) end end
if #found ~= 1 then warn("QQ WARD ABORT - expected one WardrobeClient in the workspace, found " .. #found) return end
local s = found[1]
local a, b = s.Source:find(@@F1@@, 1, true)
if not a or s.Source:find(@@F1@@, b + 1, true) then warn(string.format("QQ WARD ABORT - the find does not match exactly once in %s (%d chars); nothing changed", s:GetFullName(), #s.Source)) return end
local o = s.Source:sub(1, a - 1) .. @@R1@@ .. s.Source:sub(b + 1)
local f, err = loadstring(o)
if not f then warn("QQ WARD ABORT - patched source does not compile: " .. tostring(err)) return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "WardrobeClient_pre_vr1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ WARD DONE: %s %d chars; backup ServerStorage.HudBackup.WardrobeClient_pre_vr1", s:GetFullName(), #s.Source))
'''
for k, v in {"F1": L(F1), "R1": L(R1)}.items(): lua = lua.replace("@@" + k + "@@", v)
(ROOT / "tools/vr/wardrobe_vr1.lua").write_text(lua, encoding="utf-8")
print("wardrobe_vr1.lua", len(lua.encode()), "chars")
