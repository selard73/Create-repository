#!/usr/bin/env python3
"""install_chatter1.lua: squirrel chatter (Shannon, Oct 11 2026) - workspace.SquirrelChatter {ChatterLines (ModuleScript),
ChatterClient (Script, RunContext Client)}. The Porto Nocciola squirrels and both church mice talk to passers-by through the
SquirrelBubble. Re-runnable: an existing folder goes to ServerStorage.HudBackup.SquirrelChatter_pre_<n> (attributes kept).
Attributes on the folder (tune live): Range 10 (studs), Chance 0.55, Cooldown 120 (s, per squirrel, +-30%), Gap 9 (s between
any two lines), Linger 45 (s standing among them), Secs 4.2 (bubble), TalkUnfound false, Enabled true.
"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
LINES = (HERE / "src" / "ChatterLines.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src" / "ChatterClient.lua").read_text(encoding="utf-8")
assert "]===]" not in LINES and "]===]" not in CLIENT
INSTALLER = f'''-- install_chatter1.lua (Studio EDIT mode; re-runnable). Job 88. Squirrel chatter: the Porto squirrels and both church mice
-- talk to passers-by (scattered: one at a time, by chance, with rests). workspace.SquirrelChatter with ChatterLines
-- ({len(LINES)} chars) and ChatterClient ({len(CLIENT)} chars). Undo: delete workspace.SquirrelChatter. No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
if not RS:FindFirstChild("SquirrelBubble") then print("QQ CHATTER ABORT: ReplicatedStorage.SquirrelBubble not found") return end
local LINES = [===[
{LINES}]===]
local CLIENT = [===[
{CLIENT}]===]
for _, pair in ipairs({{{{"lines", LINES}}, {{"client", CLIENT}}}}) do
	local f, err = loadstring(pair[2]); if not f then print("QQ CHATTER ABORT: the " .. pair[1] .. " module does not compile: " .. tostring(err)) return end
end
local okL, tbl = pcall(loadstring(LINES)); if not (okL and type(tbl) == "table") then print("QQ CHATTER ABORT: the lines module does not return a table: " .. tostring(tbl)) return end
local ids, lines, missing = 0, 0, {{}}
for id, e in pairs(tbl) do
	ids += 1; lines += (type(e.lines) == "table" and #e.lines or 0)
	if not (workspace:FindFirstChild(id .. "_color") or workspace:FindFirstChild(id .. "_gray")) then table.insert(missing, id) end
end
table.sort(missing)
local old = workspace:FindFirstChild("SquirrelChatter")
local attrs = {{}}
if old then
	for k, v in pairs(old:GetAttributes()) do attrs[k] = v end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("SquirrelChatter_pre_" .. n) do n += 1 end
	old.Name = "SquirrelChatter_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetChildren()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "SquirrelChatter"
local defaults = {{Range = 10, Chance = 0.55, Cooldown = 120, Gap = 9, Linger = 45, Secs = 4.2, TalkUnfound = false, Enabled = true}}
for k, v in pairs(defaults) do if attrs[k] ~= nil then F:SetAttribute(k, attrs[k]) else F:SetAttribute(k, v) end end
local m = Instance.new("ModuleScript"); m.Name = "ChatterLines"; m.Source = LINES; m.Parent = F
local c = Instance.new("Script"); c.Name = "ChatterClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ CHATTER DONE: workspace.SquirrelChatter (ChatterLines %d, ChatterClient %d chars; %d speakers, %d lines; Range %s, Chance %s, Cooldown %s, Gap %s, Linger %s, Secs %s, TalkUnfound %s, Enabled %s)%s%s",
	#m.Source, #c.Source, ids, lines, tostring(F:GetAttribute("Range")), tostring(F:GetAttribute("Chance")), tostring(F:GetAttribute("Cooldown")), tostring(F:GetAttribute("Gap")), tostring(F:GetAttribute("Linger")), tostring(F:GetAttribute("Secs")), tostring(F:GetAttribute("TalkUnfound")), tostring(F:GetAttribute("Enabled")),
	#missing > 0 and ("; NO MODEL in workspace for: " .. table.concat(missing, ", ")) or "; every speaker has a model",
	old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
(HERE / "install_chatter1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
print("install_chatter1.lua written:", len(INSTALLER))
