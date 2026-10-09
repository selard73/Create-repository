-- portraits/vr1 (job 27): EDIT mode. In a VR headset the gallery shows each sitter's avatar bust picture instead of the
-- ViewportFrame (which blinks in VR). Three exact finds in workspace.PortraitGallery.PortraitClient; compiled before
-- writing; original -> ServerStorage.HudBackup.PortraitClient_pre_vr1. Output lines start with "QQ VRP".
if game:GetService("RunService"):IsRunning() then warn("QQ VRP ABORT - Play mode") return end
local G = workspace:FindFirstChild("PortraitGallery")
local s = G and G:FindFirstChild("PortraitClient")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ VRP ABORT - missing workspace.PortraitGallery.PortraitClient") return end
print("QQ VRP PortraitClient is " .. #s.Source .. " chars")
local o = s.Source
for i, p in ipairs({{[===[
local UIS=game:GetService("UserInputService")
]===], [===[
local UIS=game:GetService("UserInputService")
local VR=UIS.VREnabled -- VR headsets render ViewportFrames unreliably: the sitter's bust picture stands in (Oct 9 2026)
]===]}, {[===[
   if cm then frameViewport(cv,cm) end
]===], [===[
   if cm then frameViewport(cv,cm) end
   if VR and cv and cv.Visible then
    local uid=tostring(cv:GetAttribute("GalleryModelKey") or ""):match("^(%d+)");local pic=copy:FindFirstChild("Portrait")
    if uid and pic then pic.Image="rbxthumb://type=AvatarBust&id="..uid.."&w=420&h=420";pic.Visible=true;cv.Visible=false end
   end
]===]}, {[===[
   local copy=child:Clone();copy.Parent=painting
   if copy:IsA("ViewportFrame")then
]===], [===[
   local copy=child:Clone();copy.Parent=painting
   if VR and copy:IsA("ViewportFrame")then copy.Visible=false
   elseif VR and copy.Name=="Portrait" then
    local uid=tostring(pv and pv:GetAttribute("GalleryModelKey") or ""):match("^(%d+)")
    if uid then copy.Image="rbxthumb://type=AvatarBust&id="..uid.."&w=420&h=420";copy.Visible=true end
   elseif copy:IsA("ViewportFrame")then
]===]}}) do
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
