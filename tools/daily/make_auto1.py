#!/usr/bin/env python3
"""Builds tools/daily/daily_auto1.lua (job 35): the Daily Acorns card collects itself. Shannon, Oct 9 (VR): "it's nice to
click Collect and see the acorns go in, but on the VR if you don't see it, it ends up covering up other things. If the
person doesn't click Collect after maybe fifteen seconds, just have it collect itself and go away." The card's Collect
action becomes a function the button and a timer share; the timer (attribute AutoCollect on workspace.Daily, default 15 s)
collects if the card is still waiting. Patches workspace.Daily.DailyClient by exact finds taken from
boundary/build_daily.lua's CLIENT text; original -> ServerStorage.HudBackup.DailyClient_pre_auto1.
Run from the repo root: python3 tools/daily/make_auto1.py
"""
import pathlib, re
ROOT = pathlib.Path(__file__).resolve().parents[2]
build = (ROOT / "boundary/build_daily.lua").read_text(encoding="utf-8")
m = re.search(r"local CLIENT\s*=\s*\[(=*)\[(.*?)\]\1\]", build, re.S)
client = m.group(2)
def L(s, lvl="==="):
    assert ("]" + lvl + "]") not in s
    return "[" + lvl + "[\n" + s + "]" + lvl + "]"
def one(s):
    assert client.count(s) == 1, s[:70]
    return s
F1 = one("local function showCard(state)\n")
R1 = "local collect, autoToken   -- Collect's action (set below); the auto-collect timer (Shannon, Oct 9 2026, VR) shares it\n" + F1
F2 = one("\tcard.Visible = true; shown = true\n")
R2 = F2 + ('\tlocal mine = {}; autoToken = mine\n'
           '\ttask.delay(tonumber(script.Parent:GetAttribute("AutoCollect")) or 15, function()\n'
           '\t\tif autoToken == mine and shown and btn.Text == "Collect" and collect then collect() end   -- nobody pressed it: collect and go\n'
           '\tend)\n')
F3 = one('btn.Activated:Connect(function()\n\tif busy then return end\n\tbusy = true\n\tlocal ok, res = action:InvokeServer("claim")\n')
R3 = 'collect = function()\n\tif busy then return end\n\tbusy = true\n\tlocal ok, res = action:InvokeServer("claim")\n'
F4 = one("\tbusy = false\nend)\n")
R4 = "\tbusy = false\nend\nbtn.Activated:Connect(function() collect() end)\n"
out = client
for a, b in ((F1, R1), (F2, R2), (F3, R3), (F4, R4)): out = out.replace(a, b)
chk = ROOT / "tools/daily/check"; chk.mkdir(parents=True, exist_ok=True)
(chk / "DailyClient.lua").write_text(out, encoding="utf-8")
lua = r'''-- daily/daily_auto1 (job 35): EDIT mode. The Daily Acorns card collects itself after AutoCollect seconds (15) if nobody
-- pressed Collect. Four exact finds in workspace.Daily.DailyClient; compiled before writing; original ->
-- ServerStorage.HudBackup.DailyClient_pre_auto1. Output lines start with "QQ AUTO".
if game:GetService("RunService"):IsRunning() then warn("QQ AUTO ABORT - Play mode") return end
local D = workspace:FindFirstChild("Daily")
local s = D and D:FindFirstChild("DailyClient")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ AUTO ABORT - missing workspace.Daily.DailyClient") return end
print("QQ AUTO DailyClient is " .. #s.Source .. " chars")
local o = s.Source
for i, p in ipairs({{@@F1@@, @@R1@@}, {@@F2@@, @@R2@@}, {@@F3@@, @@R3@@}, {@@F4@@, @@R4@@}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ AUTO ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ AUTO ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ AUTO ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "DailyClient_pre_auto1"; c.Enabled = false; c.Parent = backup
s.Source = o
if D:GetAttribute("AutoCollect") == nil then D:SetAttribute("AutoCollect", 15) end
print(string.format("QQ AUTO DONE: DailyClient %d chars; AutoCollect %s s; backup ServerStorage.HudBackup.DailyClient_pre_auto1", #s.Source, tostring(D:GetAttribute("AutoCollect"))))
'''
for k, v in {"F1": L(F1), "R1": L(R1), "F2": L(F2), "R2": L(R2), "F3": L(F3), "R3": L(R3), "F4": L(F4), "R4": L(R4)}.items():
    assert lua.count("@@" + k + "@@") == 1; lua = lua.replace("@@" + k + "@@", v)
assert "@@" not in lua
(ROOT / "tools/daily/daily_auto1.lua").write_text(lua, encoding="utf-8")
print("daily_auto1.lua", len(lua.encode()), "chars; build CLIENT", len(client.encode()), "chars; check copy tools/daily/check/DailyClient.lua")
