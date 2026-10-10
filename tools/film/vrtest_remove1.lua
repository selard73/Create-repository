-- film/vrtest_remove1 (job 58): EDIT mode. Shannon (Oct 10): "remove the yellow and blue buttons put there earlier when
-- doing testing to fix the ground glitch" - the VR test switches (workspace.FilmMode.VRTestClient: glowing pads with
-- "Shadows OFF/ON" and "Plain floor" prompts at the bottom funicular stop and the square). The script goes to
-- ServerStorage.HudBackup (disabled) and any pad left in the workspace (a part whose prompt says Shadows or Plain floor,
-- or whose name starts with VRTest) goes to ServerStorage.HudBackup.VRTestPads. Nothing else is touched. Output "QQ VRT".
if game:GetService("RunService"):IsRunning() then warn("QQ VRT ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local FM = workspace:FindFirstChild("FilmMode")
local sc = FM and FM:FindFirstChild("VRTestClient")
local moved = {}
if sc then sc.Enabled = false; sc.Parent = backup; table.insert(moved, "FilmMode.VRTestClient (script)") end
local pads = backup:FindFirstChild("VRTestPads") or Instance.new("Folder"); pads.Name = "VRTestPads"; pads.Parent = backup
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") then
		local txt = (d.ObjectText .. " " .. d.ActionText):lower()
		if txt:find("shadows off", 1, true) or txt:find("shadows on", 1, true) or txt:find("plain floor", 1, true) then
			local pad = d:FindFirstAncestorWhichIsA("BasePart") or d.Parent
			if pad and pad.Parent ~= pads then table.insert(moved, pad:GetFullName()); pad.Parent = pads end
		end
	end
end
for _, d in ipairs(workspace:GetDescendants()) do
	if d.Name:sub(1, 6) == "VRTest" and d.Parent ~= pads then table.insert(moved, d:GetFullName()); d.Parent = pads end
end
if #pads:GetChildren() == 0 then pads:Destroy() end
game:GetService("ChangeHistoryService"):SetWaypoint("VR test switches removed")
print("QQ VRT DONE: moved to ServerStorage.HudBackup: " .. (#moved > 0 and table.concat(moved, " | ") or "nothing found (no VRTestClient, no pads with Shadows/Plain floor prompts in the workspace)"))
