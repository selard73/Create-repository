-- porto/seaglass4 (job 39): EDIT mode. Fixes to job 34: the pearl's oyster onto open sand beside the cages
-- (PearlSpot 506,-46,-1116); the shell box sells for 150 acorns instead of being kept; Bella's prompt hidden while her
-- panel is open. Exact finds in workspace.SeaGlass.Recipes (8069), SeaGlassServer (12114), SeaGlassClient (12895);
-- compiled before writing; originals -> ServerStorage.HudBackup.*_pre_seaglass4. Output lines "QQ SG4".
if game:GetService("RunService"):IsRunning() then warn("QQ SG4 ABORT - Play mode") return end
local G = workspace:FindFirstChild("SeaGlass")
local Rc, Sv, Cl = G and G:FindFirstChild("Recipes"), G and G:FindFirstChild("SeaGlassServer"), G and G:FindFirstChild("SeaGlassClient")
if not (Rc and Sv and Cl) then warn("QQ SG4 ABORT - missing workspace.SeaGlass scripts") return end
for s, n in pairs({[Rc] = 8069, [Sv] = 12114, [Cl] = 12895}) do
	if #s.Source ~= n then warn(string.format("QQ SG4 ABORT - %s is %d chars, expected %d (already patched, or changed); nothing changed", s.Name, #s.Source, n)) return end
end
local PATCHES = {{Rc, "Recipes", {{[===[
pearl = 1}, keep = "shell_box",
		line = "A pearl from the Grotta! It needs a box of shells to live in. Keep it with your treasures."},]===], [===[
pearl = 1}, pay = 150,
		line = "A pearl from the Grotta! In a box of shells it is worth a fortune. My finest piece yet!"},]===]}}}, {Sv, "SeaGlassServer", {{[===[
"You already found the pearl. Bella can make a shell box for it!"]===], [===[
"You already have the pearl. Bella pays well for it in a box of shells!"]===]}}}, {Cl, "SeaGlassClient", {{[===[
	open = true; panel.Visible = true; pg:SetAttribute("OpenPanel", "seaglass")
]===], [===[
	open = true; panel.Visible = true; pg:SetAttribute("OpenPanel", "seaglass")
	local bp = bella() and bella():FindFirstChild("BellaPrompt", true); if bp then bp.Enabled = false end   -- her prompt would draw over the panel (phones)
]===]}, {[===[
	open = false; panel.Visible = false
]===], [===[
	open = false; panel.Visible = false
	local bp = bella() and bella():FindFirstChild("BellaPrompt", true); if bp then bp.Enabled = true end
]===]}}}}
local out = {}
for _, pt in ipairs(PATCHES) do
	local s, name, list = pt[1], pt[2], pt[3]
	local o = s.Source
	for i, p in ipairs(list) do
		local a, b = o:find(p[1], 1, true)
		if not a then warn("QQ SG4 ABORT - " .. name .. " find " .. i .. " not found; nothing changed") return end
		if o:find(p[1], b + 1, true) then warn("QQ SG4 ABORT - " .. name .. " find " .. i .. " matches more than once; nothing changed") return end
		o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
	end
	local f, err = loadstring(o)
	if not f then warn("QQ SG4 ABORT - patched " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	out[s] = o
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
for s, o in pairs(out) do
	local b = s:Clone(); b.Name = s.Name .. "_pre_seaglass4"
	if b:IsA("BaseScript") then b.Enabled = false end
	b.Parent = backup; s.Source = o
end
G:SetAttribute("PearlSpot", Vector3.new(506, -46, -1116))
print(string.format("QQ SG4 DONE: Recipes %d, SeaGlassServer %d, SeaGlassClient %d chars; PearlSpot %s; backups ServerStorage.HudBackup.*_pre_seaglass4", #Rc.Source, #Sv.Source, #Cl.Source, tostring(G:GetAttribute("PearlSpot"))))
