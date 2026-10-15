#!/usr/bin/env python3
"""Builds tools/treehouse/patch_treehouse3_r2.lua (job 119): three changes to the installed Homebase client (Shannon, Oct 15 2026):
 1. a piece has its own sound, not the squirrel fanfare - the harbour bell's ding at 1.5x (folder attributes PieceSound /
    PieceSoundSpeed / PieceSoundVolume, so she can swap in any sound later without code);
 2. the first-piece look holds 4.5 s (was ~5.3);
 3. the last piece: the camera flies to the finished house, fireworks over it and confetti on the deck for 4.5 s, the fanfare, the
    banner "Welcome home, <display name>!", then back, then the built card.
The installed TreehouseClient is disabled, cloned to HudBackup.TreehouseClient_pre_r2_n and replaced by a fresh Script. Studio EDIT,
re-runnable; also a play-test preview. No DataStore, no publish. Output "QQ TREE119". Run from the repo root."""
from pathlib import Path
HERE = Path(__file__).resolve().parent
CLIENT = (HERE / "src/TreehouseClient3.lua").read_text(encoding="utf-8")
assert "]===]" not in CLIENT and "local function finale" in CLIENT and "pieceSound()" in CLIENT
lua = '''-- patch_treehouse3_r2.lua (job 119; Studio EDIT; re-runnable; also a play-test preview). The Homebase client: a piece's own sound,
-- the first look held 4.5 s, and the finale (the finished house, fireworks, "Welcome home, <name>!"). Replaces workspace.Treehouse's
-- TreehouseClient (%d chars); the old one -> HudBackup.TreehouseClient_pre_r2_n. Output "QQ TREE119".
if game:GetService("RunService"):IsRunning() then print("QQ TREE119 (play test: preview only)") end
local SS = game:GetService("ServerStorage")
local F = workspace:FindFirstChild("Treehouse")
if not (F and F:GetAttribute("Tree")) then print("QQ TREE119 ABORT: workspace.Treehouse is not here") return end
local CLIENT = [===[
%s]===]
do local ok, f, err = pcall(function() return loadstring(CLIENT) end); if ok and not f then print("QQ TREE119 ABORT: does not compile: " .. tostring(err)) return end end
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Treehouse r119") end)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
for k, v in pairs({PieceSound = "rbxassetid://16480570986", PieceSoundSpeed = 1.5, PieceSoundVolume = 0.55}) do if F:GetAttribute(k) == nil then F:SetAttribute(k, v) end end
local old = F:FindFirstChild("TreehouseClient")
if old and old:IsA("BaseScript") and old.Source == CLIENT then print("QQ TREE119 DONE (already this client, " .. #CLIENT .. " chars)") return end
local kept
if old then
	old.Enabled = false
	local n = 1; while hb:FindFirstChild("TreehouseClient_pre_r2_" .. n) do n += 1 end
	kept = old:Clone(); kept.Name = "TreehouseClient_pre_r2_" .. n; kept.Parent = hb
	old:Destroy()
end
local c = Instance.new("Script"); c.Name = "TreehouseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Treehouse r119") end)
print(string.format("QQ TREE119 DONE: TreehouseClient %%d chars%%s; PieceSound %%s at %%sx", #c.Source, kept and ("; the old one is HudBackup." .. kept.Name) or "", tostring(F:GetAttribute("PieceSound")), tostring(F:GetAttribute("PieceSoundSpeed"))))
''' % (len(CLIENT), CLIENT)
(HERE / "patch_treehouse3_r2.lua").write_text(lua, encoding="utf-8")
print("patch_treehouse3_r2.lua", len(lua.encode()), "bytes")
