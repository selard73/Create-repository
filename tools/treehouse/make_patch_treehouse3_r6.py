#!/usr/bin/env python3
"""Builds tools/treehouse/patch_treehouse3_r6.lua (job 124): each Homebase piece plays the next slice of one construction recording
(Shannon, Oct 15 2026: "take different short clips of this for the sound of picking up a piece? to make it sound like its a build?
6186807867"). Folder attributes (set if absent): PieceClipSound "rbxassetid://6186807867", PieceClips "" (auto: evenly spaced),
PieceClipLength 1.0, PieceClipVolume 0.6; the bell (PieceSound) stays as the fallback. Includes jobs 122 + 123. Replaces
workspace.Treehouse.TreehouseClient (old -> HudBackup.TreehouseClient_pre_r6_n). Run from the repo root."""
from pathlib import Path
HERE = Path(__file__).resolve().parent
CLIENT = (HERE / "src/TreehouseClient3.lua").read_text(encoding="utf-8")
assert "]===]" not in CLIENT and "local function finale" in CLIENT and "local function seatAt" in CLIENT and "p.Touched:Connect" in CLIENT and "PlaybackRegion" in CLIENT and "'s\\n\" .. NAME" in CLIENT
lua = '''-- patch_treehouse3_r6.lua (job 124; Studio EDIT; re-runnable; also a play-test preview). The Homebase client: a piece's own sound,
-- the first look held 4.5 s, and the finale (the finished house, fireworks, "Welcome home, <name>!"). Replaces workspace.Treehouse's
-- TreehouseClient (%d chars); the old one -> HudBackup.TreehouseClient_pre_r6_n. Output "QQ TREE124".
if game:GetService("RunService"):IsRunning() then print("QQ TREE124 (play test: preview only)") end
local SS = game:GetService("ServerStorage")
local F = workspace:FindFirstChild("Treehouse")
if not (F and F:GetAttribute("Tree")) then print("QQ TREE124 ABORT: workspace.Treehouse is not here") return end
local CLIENT = [===[
%s]===]
do local ok, f, err = pcall(function() return loadstring(CLIENT) end); if ok and not f then print("QQ TREE124 ABORT: does not compile: " .. tostring(err)) return end end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Treehouse r124") end)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
for k, v in pairs({PieceSound = "rbxassetid://16480570986", PieceSoundSpeed = 1.5, PieceSoundVolume = 0.55, PieceClipSound = "rbxassetid://6186807867", PieceClips = "", PieceClipLength = 1.0, PieceClipVolume = 0.6}) do if F:GetAttribute(k) == nil then F:SetAttribute(k, v) end end
local old = F:FindFirstChild("TreehouseClient")
if old and old:IsA("BaseScript") and old.Source == CLIENT then print("QQ TREE124 DONE (already this client, " .. #CLIENT .. " chars)") return end
local kept
if old then
	old.Enabled = false
	local n = 1; while hb:FindFirstChild("TreehouseClient_pre_r6_" .. n) do n += 1 end
	kept = old:Clone(); kept.Name = "TreehouseClient_pre_r6_" .. n; kept.Parent = hb
	old:Destroy()
end
local c = Instance.new("Script"); c.Name = "TreehouseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Treehouse r124") end)
print(string.format("QQ TREE124 DONE: TreehouseClient %%d chars%%s; PieceSound %%s at %%sx", #c.Source, kept and ("; the old one is HudBackup." .. kept.Name) or "", tostring(F:GetAttribute("PieceSound")), tostring(F:GetAttribute("PieceSoundSpeed"))))
''' % (len(CLIENT), CLIENT)
(HERE / "patch_treehouse3_r6.lua").write_text(lua, encoding="utf-8")
print("patch_treehouse3_r6.lua", len(lua.encode()), "bytes")
