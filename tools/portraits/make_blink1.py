#!/usr/bin/env python3
"""Builds tools/portraits/blink1.lua (job 97): the portrait blink fix for phones and VR. Three exact-string patches of
workspace.PortraitGallery.PortraitClient (the live text = village/build_portraits.lua's CLIENT string + job 27's vr1 patches):
 1. the mount keeps a signature of everything the picture shows (model key, render token, the sitter model's size, every
    GuiObject's Visible / Size / Position / Image); a refresh whose signature is unchanged does NOT swap the mount - no swap,
    nothing to blink;
 2. when it must swap, the new mount is parented first and the old one destroyed 0.12 s later, after the new viewport has
    rendered, so the sitter never blinks out.
Self-test here: the patches are applied to the repo's CLIENT string (with the vr1 lines added as Studio has them) and the result
compiled with the luau CLI. Run from the repo root: python3 tools/portraits/make_blink1.py
"""
import pathlib, re, subprocess, os
ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent

def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"

F1 = "local mounted,queued,stopped=nil,false,false\n"
R1 = "local mounted,queued,stopped,lastSig=nil,false,false,nil\n"
F2 = "   local copy=picture:Clone();copy.Name=slot.Name;copy.Adornee=c;copy.Enabled=true;copy.ResetOnSpawn=false\n"
R2 = '''   -- (Oct 14 2026, the blink on phones and VR) a swap only when something the picture shows has changed: the model key, the
   -- render token, the sitter model's size, any GuiObject's Visible / Size / Position / Image. A refresh that changes nothing
   -- keeps the mount it has - no swap, nothing to blink.
   local sigParts={tostring(key),tostring(vp and vp:GetAttribute("RenderToken")),stored and tostring(#stored:GetDescendants()) or "0"}
   for _,o in ipairs(picture:GetDescendants()) do
    if o:IsA("GuiObject") then sigParts[#sigParts+1]=o.Name..tostring(o.Visible)..tostring(o.Size)..tostring(o.Position)..(o:IsA("ImageLabel") and o.Image or "") end
   end
   local sig=table.concat(sigParts,"|")
   if mounted and mounted.Parent and sig==lastSig then return end
   lastSig=sig
''' + F2
F3 = "   copy.Parent=galleryPictures\n   picture.Enabled=false -- local only; the server continues updating its template\n   if mounted then mounted:Destroy() end\n   mounted=copy\n"
R3 = '''   copy.Parent=galleryPictures
   picture.Enabled=false -- local only; the server continues updating its template
   local old=mounted
   mounted=copy
   -- (Oct 14 2026) the new picture is up before the old one goes: destroyed 0.12 s later, once the new viewport has rendered
   if old then task.delay(0.12,function() if old~=mounted then old:Destroy() end end) end
'''
VR_MARK = "VR headsets render ViewportFrames unreliably"

# ---- self-test on the repo's CLIENT, with the vr1 lines added as job 27 added them in Studio ----
src = (ROOT / "village/build_portraits.lua").read_text(encoding="utf-8")
client = re.search(r"local CLIENT = \[==\[\n(.*?)\]==\]", src, re.S).group(1)
vr1 = [("local UIS=game:GetService(\"UserInputService\")\n", "local UIS=game:GetService(\"UserInputService\")\nlocal VR=UIS.VREnabled -- VR headsets render ViewportFrames unreliably: the sitter's bust picture stands in (Oct 9 2026)\n"),
       ("   if cm then frameViewport(cv,cm) end\n", "   if cm then frameViewport(cv,cm) end\n   if VR and cv and cv.Visible then\n    local uid=tostring(cv:GetAttribute(\"GalleryModelKey\") or \"\"):match(\"^(%d+)\");local pic=copy:FindFirstChild(\"Portrait\")\n    if uid and pic then pic.Image=\"rbxthumb://type=AvatarBust&id=\"..uid..\"&w=420&h=420\";pic.Visible=true;cv.Visible=false end\n   end\n")]
live = client
for a, b in vr1:
    assert live.count(a) == 1, a[:40]
    live = live.replace(a, b)
for a, b in [(F1, R1), (F2, R2), (F3, R3)]:
    assert live.count(a) == 1, a[:60]
    live = live.replace(a, b)
chk = HERE / "check"; chk.mkdir(exist_ok=True)
(chk / "PortraitClient_patched.lua").write_text(live, encoding="utf-8")
luau = os.environ.get("LUAU_COMPILE")
if luau:
    r = subprocess.run([luau, "--null", str(chk / "PortraitClient_patched.lua")], capture_output=True, text=True)
    assert "Error" not in (r.stdout + r.stderr), r.stdout + r.stderr
    print("self-test: the patched client compiles")
else:
    print("self-test: compile it with: luau-compile --null", chk / "PortraitClient_patched.lua")

lua = r'''-- portraits/blink1 (job 97): EDIT mode. The portrait blink on phones and VR (Shannon: "the characters in them continuously
-- blinking in and out on mobile and VR, but not on desktop"; "only the character, not the easel"). PortraitClient clones the whole
-- picture into PlayerGui and swaps it for a fresh clone on many triggers; the sitter is a ViewportFrame that needs a frame or more
-- to render, so on a slow device every swap shows the character blink out and in. Two changes, exact-string patches of
-- workspace.PortraitGallery.PortraitClient (the job 27 vr1 text): (1) a swap only when something the picture shows has changed;
-- (2) the new picture up before the old one goes (destroyed 0.12 s later). Every anchor counted before anything changes; the
-- result compiled where loadstring runs; original -> ServerStorage.HudBackup.PortraitClient_pre_blink1. Output lines "QQ BLINK1".
if game:GetService("RunService"):IsRunning() then print("QQ BLINK1 ABORT - Play mode") return end
local G = workspace:FindFirstChild("PortraitGallery")
local s = G and G:FindFirstChild("PortraitClient")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ BLINK1 ABORT - missing workspace.PortraitGallery.PortraitClient") return end
local o = s.Source
print(string.format("QQ BLINK1 PortraitClient is %d chars; vr1 text %s", #o, o:find(@@VR@@, 1, true) and "present" or "ABSENT"))
if o:find("sig==lastSig", 1, true) then print("QQ BLINK1 DONE (already patched): PortraitClient " .. #o) return end
if not o:find(@@VR@@, 1, true) then print("QQ BLINK1 ABORT - this is not the job 27 (vr1) text; nothing changed") return end
local P = {{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}}
for i, p in ipairs(P) do
	local a, b = o:find(p[1], 1, true)
	if not a then print("QQ BLINK1 ABORT - anchor " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then print("QQ BLINK1 ABORT - anchor " .. i .. " matches more than once; nothing changed") return end
end
local n = o
for _, p in ipairs(P) do local a, b = n:find(p[1], 1, true); n = n:sub(1, a - 1) .. p[2] .. n:sub(b + 1) end
do
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ BLINK1 ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
if not backup:FindFirstChild("PortraitClient_pre_blink1") then local c = s:Clone(); c.Name = "PortraitClient_pre_blink1"; c.Enabled = false; c.Parent = backup end
s.Source = n
print(string.format("QQ BLINK1 DONE: PortraitClient %d -> %d chars; backup ServerStorage.HudBackup.PortraitClient_pre_blink1", #o, #n))
'''
for k, v in {"F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2), "F3": L(F3), "R3": L(R3), "VR": L(VR_MARK)}.items():
    assert lua.count("@@" + k + "@@") == 1, k
    lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(HERE / "blink1.lua").write_text(lua, encoding="utf-8")
print("blink1.lua", len(lua.encode()), "bytes")
