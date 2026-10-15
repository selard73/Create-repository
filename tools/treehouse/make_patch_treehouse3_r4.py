#!/usr/bin/env python3
"""Builds tools/treehouse/patch_treehouse3_r4.lua (job 122): the finished Homebase's sign reads "<display name>'s / Homebase Treehouse"
(Shannon, Oct 15 2026: "why does the sign say Treehouse est. today.? welcome home? Maybe once its done it should Selbell's Homebase
Treehouse?"). Everything from jobs 119 and 121 stays. Replaces workspace.Treehouse.TreehouseClient (old -> HudBackup.TreehouseClient_pre_r4_n).
Run from the repo root."""
from pathlib import Path
HERE = Path(__file__).resolve().parent
CLIENT = (HERE / "src/TreehouseClient3.lua").read_text(encoding="utf-8")
assert "]===]" not in CLIENT and "local function finale" in CLIENT and "local function seatAt" in CLIENT and "'s\\n\" .. NAME" in CLIENT
lua = '''-- patch_treehouse3_r4.lua (job 122; Studio EDIT; re-runnable; also a play-test preview). The Homebase client: a piece's own sound,
-- the first look held 4.5 s, and the finale (the finished house, fireworks, "Welcome home, <name>!"). Replaces workspace.Treehouse's
-- TreehouseClient (%d chars); the old one -> HudBackup.TreehouseClient_pre_r4_n. Output "QQ TREE122".
if game:GetService("RunService"):IsRunning() then print("QQ TREE122 (play test: preview only)") end
local SS = game:GetService("ServerStorage")
local F = workspace:FindFirstChild("Treehouse")
if not (F and F:GetAttribute("Tree")) then print("QQ TREE122 ABORT: workspace.Treehouse is not here") return end
local CLIENT = [===[
%s]===]
do local ok, f, err = pcall(function() return loadstring(CLIENT) end); if ok and not f then print("QQ TREE122 ABORT: does not compile: " .. tostring(err)) return end end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Treehouse r122") end)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
for k, v in pairs({PieceSound = "rbxassetid://16480570986", PieceSoundSpeed = 1.5, PieceSoundVolume = 0.55}) do if F:GetAttribute(k) == nil then F:SetAttribute(k, v) end end
local old = F:FindFirstChild("TreehouseClient")
if old and old:IsA("BaseScript") and old.Source == CLIENT then print("QQ TREE122 DONE (already this client, " .. #CLIENT .. " chars)") return end
local kept
if old then
	old.Enabled = false
	local n = 1; while hb:FindFirstChild("TreehouseClient_pre_r4_" .. n) do n += 1 end
	kept = old:Clone(); kept.Name = "TreehouseClient_pre_r4_" .. n; kept.Parent = hb
	old:Destroy()
end
local c = Instance.new("Script"); c.Name = "TreehouseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Treehouse r122") end)
print(string.format("QQ TREE122 DONE: TreehouseClient %%d chars%%s; PieceSound %%s at %%sx", #c.Source, kept and ("; the old one is HudBackup." .. kept.Name) or "", tostring(F:GetAttribute("PieceSound")), tostring(F:GetAttribute("PieceSoundSpeed"))))
''' % (len(CLIENT), CLIENT)
(HERE / "patch_treehouse3_r4.lua").write_text(lua, encoding="utf-8")
print("patch_treehouse3_r4.lua", len(lua.encode()), "bytes")
