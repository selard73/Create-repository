-- portraits/blink1 (job 97): EDIT mode. The portrait blink on phones and VR (Shannon: "the characters in them continuously
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
local VRM = [===[
VR headsets render ViewportFrames unreliably]===]
print(string.format("QQ BLINK1 PortraitClient is %d chars; vr1 text %s", #o, o:find(VRM, 1, true) and "present" or "ABSENT"))
if o:find("sig==lastSig", 1, true) then print("QQ BLINK1 DONE (already patched): PortraitClient " .. #o) return end
if not o:find(VRM, 1, true) then print("QQ BLINK1 ABORT - this is not the job 27 (vr1) text; nothing changed") return end
local P = {{[===[
local mounted,queued,stopped=nil,false,false
]===], [===[
local mounted,queued,stopped,lastSig=nil,false,false,nil
]===]}, {[===[
   local copy=picture:Clone();copy.Name=slot.Name;copy.Adornee=c;copy.Enabled=true;copy.ResetOnSpawn=false
]===], [===[
   -- (Oct 14 2026, the blink on phones and VR) a swap only when something the picture shows has changed: the model key, the
   -- render token, the sitter model's size, any GuiObject's Visible / Size / Position / Image. A refresh that changes nothing
   -- keeps the mount it has - no swap, nothing to blink.
   local sigParts={tostring(key),tostring(vp and vp:GetAttribute("RenderToken")),stored and tostring(#stored:GetDescendants()) or "0"}
   for _,o in ipairs(picture:GetDescendants()) do
    if o:IsA("GuiObject") then sigParts[#sigParts+1]=o.Name..tostring(o.Visible)..tostring(o.Size)..tostring(o.Position)..(o:IsA("ImageLabel") and o.Image or "") end
   end
   local sig=table.concat(sigParts,"|")
   if mounted and mounted.Parent and sig==lastSig then return end
   lastSig=sig
   local copy=picture:Clone();copy.Name=slot.Name;copy.Adornee=c;copy.Enabled=true;copy.ResetOnSpawn=false
]===]}, {[===[
   copy.Parent=galleryPictures
   picture.Enabled=false -- local only; the server continues updating its template
   if mounted then mounted:Destroy() end
   mounted=copy
]===], [===[
   copy.Parent=galleryPictures
   picture.Enabled=false -- local only; the server continues updating its template
   local old=mounted
   mounted=copy
   -- (Oct 14 2026) the new picture is up before the old one goes: destroyed 0.12 s later, once the new viewport has rendered
   if old then task.delay(0.12,function() if old~=mounted then old:Destroy() end end) end
]===]}}
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
