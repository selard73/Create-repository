#!/usr/bin/env python3
"""install_chatter1.lua: squirrel chatter (Shannon, Oct 11 2026) - workspace.SquirrelChatter {ChatterLines (ModuleScript),
ChatterClient (Script, RunContext Client)}. The Porto Nocciola squirrels and both church mice talk to passers-by through the
SquirrelBubble. Also patches ReplicatedStorage.SquirrelBubble (vr1 8415 -> vr2: Bubble.talking() and newest-wins, so two
bubbles never show together; backup HudBackup.SquirrelBubble_pre_vr2). Re-runnable: an existing folder goes to
ServerStorage.HudBackup.SquirrelChatter_pre_<n> (attributes kept); an already patched module is left alone.
Attributes on the folder (tune live): Range 10 (studs), Chance 0.55, Cooldown 120 (s, per squirrel, +-30%), Gap 9 (s between
any two lines), Linger 45 (s standing among them), Secs 4.2 (bubble), PillRange 8 (no line while an interact pill shows
within that many studs of the speaker), TalkUnfound false, Enabled true.
"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
LINES = (HERE / "src" / "ChatterLines.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src" / "ChatterClient.lua").read_text(encoding="utf-8")
assert "]===]" not in LINES and "]===]" not in CLIENT
# the SquirrelBubble patch (vr1 -> vr2): Bubble.talking() and "newest wins"; anchored on two exact lines of the live module
V1 = (HERE.parent / "bubble" / "SquirrelBubble.module.vr1.lua").read_text(encoding="utf-8")
V2 = (HERE.parent / "bubble" / "SquirrelBubble.module.vr2.lua").read_text(encoding="utf-8")
A1 = 'local current = setmetatable({}, {__mode = "k"})                               -- speaker part -> its bubble (a new line replaces the old)\n'
A2 = '\tif not (anchor and g and type(text) == "string" and text ~= "") then return nil end\n'
I1 = V2[V2.index(A1) + len(A1):V2.index("local function gui()")]
I2 = V2[V2.index(A2) + len(A2):V2.index("\tif VR then return sayVR(anchor, text, opts) end")]
assert V1.count(A1) == 1 and V1.count(A2) == 1 and V1.replace(A1, A1 + I1).replace(A2, A2 + I2) == V2
for piece in (A1, A2, I1, I2): assert "]==]" not in piece
INSTALLER = f'''-- install_chatter1.lua (Studio EDIT mode; re-runnable). Job 88. Squirrel chatter: the Porto squirrels and both church mice
-- talk to passers-by (scattered: one at a time, by chance, with rests). workspace.SquirrelChatter with ChatterLines
-- ({len(LINES)} chars) and ChatterClient ({len(CLIENT)} chars). Undo: delete workspace.SquirrelChatter. No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local bub = RS:FindFirstChild("SquirrelBubble")
if not (bub and bub:IsA("ModuleScript")) then print("QQ CHATTER ABORT: ReplicatedStorage.SquirrelBubble not found") return end
-- the SquirrelBubble patch first: Bubble.talking() (is any bubble up) and newest-wins (a new bubble replaces any other); {len(V1)} -> {len(V2)} chars
local bubNote
if #bub.Source == {len(V2)} and bub.Source:find("function Bubble.talking()", 1, true) then
	bubNote = "; SquirrelBubble already patched ({len(V2)})"
elseif #bub.Source == {len(V1)} then
	local A1, A2 = [==[{A1}]==], [==[{A2}]==]
	local I1, I2 = [==[{I1}]==], [==[{I2}]==]
	local src = bub.Source
	local a1, b1 = src:find(A1, 1, true); local a2, b2 = src:find(A2, 1, true)
	if not (a1 and a2 and not src:find(A1, b1 + 1, true) and not src:find(A2, b2 + 1, true)) then print("QQ CHATTER ABORT: SquirrelBubble is {len(V1)} chars but its anchors are not where expected; nothing changed") return end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("SquirrelBubble_pre_vr2") then local bk = bub:Clone(); bk.Name = "SquirrelBubble_pre_vr2"; bk.Parent = hb end
	local out = src:sub(1, b1) .. I1 .. src:sub(b1 + 1)
	a2, b2 = out:find(A2, 1, true)
	out = out:sub(1, b2) .. I2 .. out:sub(b2 + 1)
	if #out ~= {len(V2)} then print(string.format("QQ CHATTER ABORT: the patched SquirrelBubble would be %d chars, expected {len(V2)}; nothing changed", #out)) return end
	local f, err = loadstring(out); if not f then print("QQ CHATTER ABORT: the patched SquirrelBubble does not compile: " .. tostring(err)) return end
	bub.Source = out
	bubNote = "; SquirrelBubble {len(V1)} -> " .. #bub.Source .. " (backup HudBackup.SquirrelBubble_pre_vr2)"
else
	print(string.format("QQ CHATTER ABORT: SquirrelBubble is %d chars, expected {len(V1)} (the vr1 module) or {len(V2)} (already patched); nothing changed", #bub.Source)) return
end
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
local defaults = {{Range = 10, Chance = 0.55, Cooldown = 120, Gap = 9, Linger = 45, Secs = 4.2, PillRange = 8, TalkUnfound = false, Enabled = true}}
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
