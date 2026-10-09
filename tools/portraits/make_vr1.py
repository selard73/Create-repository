#!/usr/bin/env python3
"""Builds tools/portraits/vr1.lua (job 27): the garden gallery's portraits in a VR headset. Shannon, Oct 9: "in the french
section, the portraits had the characters in them blinking in and out". The sitters are ViewportFrames (a 3D clone of the
player in a SurfaceGui); VR headsets render ViewportFrames unreliably, so in VR the client shows the sitter's avatar bust
picture (rbxthumb) in the same frame instead, both on the easels and on the big "Garden portrait" page. Desktop and phone
are unchanged. Patches workspace.PortraitGallery.PortraitClient by exact finds from village/build_portraits.lua; every
find once, result compiled; original -> ServerStorage.HudBackup.PortraitClient_pre_vr1.
Run from the repo root: python3 tools/portraits/make_vr1.py
"""
import pathlib, re
ROOT = pathlib.Path(__file__).resolve().parents[2]
build = (ROOT / "village/build_portraits.lua").read_text(encoding="utf-8")
m = re.search(r"local CLIENT\s*=\s*\[(=*)\[(.*?)\]\1\]", build, re.S)
client = m.group(2)

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
def one(s):
    assert client.count(s) == 1, s[:70]
    return s

BUST = '"rbxthumb://type=AvatarBust&id="..uid.."&w=420&h=420"'
F1 = one('local UIS=game:GetService("UserInputService")\n')
R1 = F1 + 'local VR=UIS.VREnabled -- VR headsets render ViewportFrames unreliably: the sitter\'s bust picture stands in (Oct 9 2026)\n'
F2 = one('   if cm then frameViewport(cv,cm) end\n')
R2 = F2 + ('   if VR and cv and cv.Visible then\n'
           '    local uid=tostring(cv:GetAttribute("GalleryModelKey") or ""):match("^(%d+)");local pic=copy:FindFirstChild("Portrait")\n'
           '    if uid and pic then pic.Image=' + BUST + ';pic.Visible=true;cv.Visible=false end\n'
           '   end\n')
F3 = one('   local copy=child:Clone();copy.Parent=painting\n   if copy:IsA("ViewportFrame")then\n')
R3 = ('   local copy=child:Clone();copy.Parent=painting\n'
      '   if VR and copy:IsA("ViewportFrame")then copy.Visible=false\n'
      '   elseif VR and copy.Name=="Portrait" then\n'
      '    local uid=tostring(pv and pv:GetAttribute("GalleryModelKey") or ""):match("^(%d+)")\n'
      '    if uid then copy.Image=' + BUST + ';copy.Visible=true end\n'
      '   elseif copy:IsA("ViewportFrame")then\n')
out = client
for a, b in ((F1, R1), (F2, R2), (F3, R3)): out = out.replace(a, b)
chk = ROOT / "tools/portraits/check"; chk.mkdir(parents=True, exist_ok=True)
(chk / "PortraitClient.lua").write_text(out, encoding="utf-8")

lua = r'''-- portraits/vr1 (job 27): EDIT mode. In a VR headset the gallery shows each sitter's avatar bust picture instead of the
-- ViewportFrame (which blinks in VR). Three exact finds in workspace.PortraitGallery.PortraitClient; compiled before
-- writing; original -> ServerStorage.HudBackup.PortraitClient_pre_vr1. Output lines start with "QQ VRP".
if game:GetService("RunService"):IsRunning() then warn("QQ VRP ABORT - Play mode") return end
local G = workspace:FindFirstChild("PortraitGallery")
local s = G and G:FindFirstChild("PortraitClient")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ VRP ABORT - missing workspace.PortraitGallery.PortraitClient") return end
print("QQ VRP PortraitClient is " .. #s.Source .. " chars")
local o = s.Source
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ VRP ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ VRP ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ VRP ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "PortraitClient_pre_vr1"; c.Enabled = false; c.Parent = backup
s.Source = o
print(string.format("QQ VRP DONE: PortraitClient %d chars; backup ServerStorage.HudBackup.PortraitClient_pre_vr1", #s.Source))
'''
for k, v in {"F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2), "F3": L(F3), "R3": L(R3)}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/portraits/vr1.lua").write_text(lua, encoding="utf-8")
print("vr1.lua", len(lua.encode()), "chars; check copy tools/portraits/check/PortraitClient.lua")
