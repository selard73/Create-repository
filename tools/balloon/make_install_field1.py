#!/usr/bin/env python3
"""Builds tools/balloon/install_field1.lua (job 33) and tools/balloon/balloon_undo1.lua. ONE Studio script (EDIT mode):
takes the balloon Shannon imported (a Model holding a MeshPart "Envelope"; Workspace.balloon_meshy after job 23), makes it
the template in ServerStorage (anchored, colours for the untextured pieces, a Neon flame with a light), and builds
workspace.BalloonField on the far shore (survey, job 22: grass round 106,-48,-648) with the BalloonServer / BalloonClient
scripts from tools/balloon/src and the RemoteEvent RS.BalloonEvent. Nothing else is touched. Refuses to run if the field
exists already (run balloon_undo1 first) or the imported balloon cannot be found. Output lines "QQ FIELD".
Run from the repo root: python3 tools/balloon/make_install_field1.py
"""
import pathlib
ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/balloon/src"
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
server = (SRC / "BalloonServer.lua").read_text(encoding="utf-8")
client = (SRC / "BalloonClient.lua").read_text(encoding="utf-8")

lua = r'''-- balloon/install_field1 (job 33): EDIT mode. The hot air balloon field on the far shore (Shannon, Oct 9 2026).
-- Needs the balloon she imported (File > Import 3D of balloon_meshy.fbx: a Model with MeshParts Envelope, Basket, Rigging,
-- Burner, Flame). Makes it ServerStorage.BalloonTemplate, builds workspace.BalloonField with its scripts, RS.BalloonEvent.
-- Undo: tools/balloon/balloon_undo1.lua. Output lines start with "QQ FIELD".
if game:GetService("RunService"):IsRunning() then warn("QQ FIELD ABORT - Play mode") return end
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
if workspace:FindFirstChild("BalloonField") then warn("QQ FIELD ABORT - workspace.BalloonField exists already; run balloon_undo1 first") return end
local tpl = SS:FindFirstChild("BalloonTemplate")
if not tpl then
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("MeshPart") and d.Name == "Envelope" then local m = d:FindFirstAncestorWhichIsA("Model"); if m and m:FindFirstChild("Basket", true) then tpl = m break end end
	end
end
if not tpl then warn("QQ FIELD ABORT - no imported balloon (a Model with MeshParts Envelope and Basket) in the workspace") return end
-- the template: anchored, no collisions (the field adds its own basket floor), colours for the untextured pieces
local COLOURS = {Rigging = {Color3.fromRGB(190, 160, 110), Enum.Material.SmoothPlastic}, Burner = {Color3.fromRGB(160, 162, 168), Enum.Material.Metal}, Flame = {Color3.fromRGB(255, 140, 30), Enum.Material.Neon}}
local names = {}
for _, d in ipairs(tpl:GetDescendants()) do
	if d:IsA("BasePart") then
		d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
		local c = COLOURS[d.Name]
		if c then d.Color = c[1]; d.Material = c[2] end
		if d.Name == "Flame" then
			d.CastShadow = false
			local l = d:FindFirstChildOfClass("PointLight") or Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 170, 70); l.Brightness = 1.5; l.Range = 16; l.Shadows = false; l.Parent = d
		end
		table.insert(names, d.Name)
	end
end
local basket = tpl:FindFirstChild("Basket", true)
if basket then tpl.PrimaryPart = basket end
-- the pivot sits at the basket floor (the model was exported that way); keep it there whatever Studio did on import
do
	local lo = math.huge
	for _, d in ipairs(tpl:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Basket" then lo = math.min(lo, d.Position.Y - d.Size.Y / 2) end end
	if lo < math.huge then local p = tpl:GetPivot(); tpl.WorldPivot = CFrame.new(p.Position.X, lo, p.Position.Z) end
end
tpl.Name = "BalloonTemplate"; tpl.Parent = SS
local evt = RS:FindFirstChild("BalloonEvent") or Instance.new("RemoteEvent"); evt.Name = "BalloonEvent"; evt.Parent = RS
local F = Instance.new("Folder"); F.Name = "BalloonField"
F:SetAttribute("Center", Vector3.new(106, -48.5, -648)); F:SetAttribute("Need", 44)
F:SetAttribute("PadYours", Vector3.new(96, 0, -646)); F:SetAttribute("PadYaw", 70); F:SetAttribute("PadTethered", Vector3.new(128, 0, -676))
F:SetAttribute("DriftCenter", Vector3.new(120, 15, -650)); F:SetAttribute("DriftRadius", 75); F:SetAttribute("DriftHeights", "10,25"); F:SetAttribute("DriftPeriods", "150,110")
F:SetAttribute("RiseHeight", 85); F:SetAttribute("RiseTime", 16); F:SetAttribute("HoverTime", 8); F:SetAttribute("GustTime", 18); F:SetAttribute("StormTime", 12); F:SetAttribute("SignTime", 6)
F:SetAttribute("GustDir", Vector3.new(0.45, 0, -1)); F:SetAttribute("GustSpeed", 22); F:SetAttribute("ThunderSoundId", 0); F:SetAttribute("WindSoundId", 0)
local sv = Instance.new("Script"); sv.Name = "BalloonServer"; sv.RunContext = Enum.RunContext.Server; sv.Source = @@SERVER@@; sv.Parent = F
local cl = Instance.new("Script"); cl.Name = "BalloonClient"; cl.RunContext = Enum.RunContext.Client; cl.Source = @@CLIENT@@; cl.Parent = F
for _, s in ipairs({sv, cl}) do local f, err = loadstring(s.Source); if not f then warn("QQ FIELD ABORT - " .. s.Name .. " does not compile: " .. tostring(err)); F:Destroy(); return end end
F.Parent = workspace
print(string.format("QQ FIELD DONE: template %s (%s) -> ServerStorage.BalloonTemplate; workspace.BalloonField with BalloonServer %d / BalloonClient %d chars; RS.BalloonEvent", tpl.Name, table.concat(names, ","), #sv.Source, #cl.Source))
'''
for k, v in {"SERVER": L(server), "CLIENT": L(client)}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/balloon/install_field1.lua").write_text(lua, encoding="utf-8")
undo = r'''-- balloon/balloon_undo1: EDIT mode. Removes workspace.BalloonField and RS.BalloonEvent; the template goes back to the
-- workspace as balloon_meshy (so install_field1 can run again). Output "QQ FIELD".
if game:GetService("RunService"):IsRunning() then warn("QQ FIELD ABORT - Play mode") return end
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local F = workspace:FindFirstChild("BalloonField"); if F then F:Destroy() end
local e = RS:FindFirstChild("BalloonEvent"); if e then e:Destroy() end
local t = SS:FindFirstChild("BalloonTemplate")
if t then t.Name = "balloon_meshy"; t:PivotTo(CFrame.new(554.4, 4.4, -1105.2)); t.Parent = workspace end
print("QQ FIELD UNDONE: field and event removed; template back in the workspace as balloon_meshy")
'''
(ROOT / "tools/balloon/balloon_undo1.lua").write_text(undo, encoding="utf-8")
print("install_field1.lua", len(lua.encode()), "chars; server", len(server.encode()), "client", len(client.encode()))
