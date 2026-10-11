#!/usr/bin/env python3
"""install_chatter1.lua: squirrel chatter (Shannon, Oct 11 2026) - workspace.SquirrelChatter {ChatterLines (ModuleScript),
ChatterClient (Script, RunContext Client)}. The Porto Nocciola squirrels and both church mice talk to passers-by through the
SquirrelBubble. Also swaps ReplicatedStorage.SquirrelBubble from vr1 (8415) to vr2 (Bubble.talking() and newest-wins, so two
bubbles never show together; the bubble beside the speaker's head instead of over it, kept on the screen under the HUD row;
backup HudBackup.SquirrelBubble_pre_vr2). Re-runnable: an existing folder goes to ServerStorage.HudBackup.SquirrelChatter_pre_<n>
(attributes kept); a module already at vr2 is left alone; any other module aborts the whole install.
Attributes on the folder (tune live): Range 10 (studs), Chance 0.55, Cooldown 120 (s, per squirrel, +-30%), Gap 9 (s between
any two lines), Linger 45 (s standing among them), Secs 4.2 (bubble), PillRange 8 (VR: no line while an interact pill shows
within that many studs of the speaker; on a screen any pill blocks), PendingSecs 6 (a picked line waits that long for its moment),
TalkUnfound false, Enabled true.
"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
LINES = (HERE / "src" / "ChatterLines.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src" / "ChatterClient.lua").read_text(encoding="utf-8")
assert "]===]" not in LINES and "]===]" not in CLIENT
# the SquirrelBubble swap (vr1 -> vr2): Bubble.talking(), "newest wins", and the bubble beside the head instead of over it
V1 = (HERE.parent / "bubble" / "SquirrelBubble.module.vr1.lua").read_text(encoding="utf-8")
V2 = (HERE.parent / "bubble" / "SquirrelBubble.module.vr2.lua").read_text(encoding="utf-8")
assert "]==]" not in V1 and "]==]" not in V2 and len(V1) == 8415
INSTALLER = f'''-- install_chatter1.lua (Studio EDIT mode; re-runnable). Job 88. Squirrel chatter: the Porto squirrels and both church mice
-- talk to passers-by (scattered: one at a time, by chance, with rests). workspace.SquirrelChatter with ChatterLines
-- ({len(LINES)} chars) and ChatterClient ({len(CLIENT)} chars). Undo: delete workspace.SquirrelChatter. No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local bub = RS:FindFirstChild("SquirrelBubble")
if not (bub and bub:IsA("ModuleScript")) then print("QQ CHATTER ABORT: ReplicatedStorage.SquirrelBubble not found") return end
-- every compile check before the first change, so an ABORT always means nothing changed
local LINES = [===[
{LINES}]===]
local CLIENT = [===[
{CLIENT}]===]
for _, pair in ipairs({{{{"lines", LINES}}, {{"client", CLIENT}}}}) do
	local f, err = loadstring(pair[2]); if not f then print("QQ CHATTER ABORT: the " .. pair[1] .. " module does not compile: " .. tostring(err)) return end
end
local okL, tbl = pcall(loadstring(LINES)); if not (okL and type(tbl) == "table") then print("QQ CHATTER ABORT: the lines module does not return a table: " .. tostring(tbl)) return end
-- the SquirrelBubble swap first: Bubble.talking() (is any bubble up), newest-wins (a new bubble replaces any other), and the
-- bubble drawn beside the speaker's head instead of over it; {len(V1)} -> {len(V2)} chars, the whole Source, only when it is exactly vr1
local V1 = [==[
{V1}]==]
local V2 = [==[
{V2}]==]
local bubNote
if bub.Source == V2 then
	bubNote = "; SquirrelBubble already vr2 ({len(V2)})"
elseif bub.Source == V1 then
	local f, err = loadstring(V2); if not f then print("QQ CHATTER ABORT: the vr2 SquirrelBubble does not compile: " .. tostring(err)) return end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("SquirrelBubble_pre_vr2") then local bk = bub:Clone(); bk.Name = "SquirrelBubble_pre_vr2"; bk.Parent = hb end
	bub.Source = V2
	bubNote = "; SquirrelBubble {len(V1)} -> " .. #bub.Source .. " (backup HudBackup.SquirrelBubble_pre_vr2)"
else
	print(string.format("QQ CHATTER ABORT: SquirrelBubble is %d chars and not the vr1 module (expected {len(V1)}) nor vr2 ({len(V2)}); nothing changed", #bub.Source)) return
end
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
local defaults = {{Range = 10, Chance = 0.55, Cooldown = 120, Gap = 9, Linger = 45, Secs = 4.2, PillRange = 8, PendingSecs = 6, TalkUnfound = false, Enabled = true}}
for k, v in pairs(defaults) do if attrs[k] ~= nil then F:SetAttribute(k, attrs[k]) else F:SetAttribute(k, v) end end
local m = Instance.new("ModuleScript"); m.Name = "ChatterLines"; m.Source = LINES; m.Parent = F
local c = Instance.new("Script"); c.Name = "ChatterClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ CHATTER DONE: workspace.SquirrelChatter (ChatterLines %d, ChatterClient %d chars; %d speakers, %d lines; Range %s, Chance %s, Cooldown %s, Gap %s, Linger %s, Secs %s, TalkUnfound %s, Enabled %s)%s%s",
	#m.Source, #c.Source, ids, lines, tostring(F:GetAttribute("Range")), tostring(F:GetAttribute("Chance")), tostring(F:GetAttribute("Cooldown")), tostring(F:GetAttribute("Gap")), tostring(F:GetAttribute("Linger")), tostring(F:GetAttribute("Secs")), tostring(F:GetAttribute("TalkUnfound")), tostring(F:GetAttribute("Enabled")),
	#missing > 0 and ("; NO MODEL in workspace for: " .. table.concat(missing, ", ")) or "; every speaker has a model",
	(old and ("; the old folder is HudBackup." .. old.Name) or "") .. bubNote))
'''
(HERE / "install_chatter1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
print("install_chatter1.lua written:", len(INSTALLER))
