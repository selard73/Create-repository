#!/usr/bin/env python3
"""Builds tools/funnel/install_funnel1.lua (job 95): the onboarding funnel for the Creator Dashboard. workspace.Funnel
{FunnelEvent (RemoteEvent), FunnelServer, FunnelClient (RunContext Client)}; attributes Enabled true, ForceNew false,
LogPrints true. Re-runnable: an old Funnel folder goes to ServerStorage.HudBackup.Funnel_pre_n with its scripts disabled.
Run from the repo root: python3 tools/funnel/make_install_funnel1.py"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "src/FunnelServer.lua").read_text(encoding="utf-8")
CLIENT = (HERE / "src/FunnelClient.lua").read_text(encoding="utf-8")
assert "]===]" not in SERVER and "]===]" not in CLIENT
TEMPLATE = '''-- install_funnel1.lua (Studio EDIT mode; re-runnable). Job 95: the onboarding funnel for the Creator Dashboard (Shannon, Oct 11
-- 2026: "33 % still playing at 5 min, 20 % at 10 min"; she cannot watch new players herself). workspace.Funnel: FunnelEvent,
-- FunnelServer (@@SLEN@@ chars: six steps from the player attributes the game already keeps - Joined, First squirrel, Five squirrels,
-- Second area, All 44 in France, Reached Italy - for first-session players, with Device and Cohort breakdowns; MapOpened as a
-- custom event), FunnelClient (@@CLEN@@ chars: the device kind and the first map open). Events leave only a published place; in
-- Studio the server prints what it would send ("Funnel: step ..."). Undo: delete workspace.Funnel (Item_funnel = 1 stays on the
-- saves of players it marked as new; harmless). No DataStore, no publish. Output lines start with "QQ FUNNEL".
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
if not RS:FindFirstChild("AwardItems") then print("QQ FUNNEL ABORT: ReplicatedStorage.AwardItems not found (the cohort mark needs the game's own ledger)") return end
local SERVER = [===[
@@SERVER@@]===]
local CLIENT = [===[
@@CLIENT@@]===]
do   -- the compile check, where loadstring can run: the sources are compiled with the luau CLI before every push
	for _, pair in ipairs({{"server", SERVER}, {"client", CLIENT}}) do
		local ok, f, err = pcall(function() return loadstring(pair[2]) end)
		if ok and not f then print("QQ FUNNEL ABORT: the " .. pair[1] .. " does not compile: " .. tostring(err)) return end
	end
end
local old = workspace:FindFirstChild("Funnel")
local F = Instance.new("Folder"); F.Name = "Funnel"
F:SetAttribute("Enabled", true); F:SetAttribute("ForceNew", false); F:SetAttribute("LogPrints", true)
if old then
	for k, v in pairs(old:GetAttributes()) do F:SetAttribute(k, v) end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Funnel_pre_" .. n) do n += 1 end
	old.Name = "Funnel_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local ev = Instance.new("RemoteEvent"); ev.Name = "FunnelEvent"; ev.Parent = F
local s = Instance.new("Script"); s.Name = "FunnelServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "FunnelClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ FUNNEL DONE: workspace.Funnel (FunnelServer %d, FunnelClient %d chars; Enabled %s, ForceNew %s, LogPrints %s)%s", #s.Source, #c.Source, tostring(F:GetAttribute("Enabled")), tostring(F:GetAttribute("ForceNew")), tostring(F:GetAttribute("LogPrints")), old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
out = TEMPLATE
for key, val in {"@@SLEN@@": str(len(SERVER)), "@@CLEN@@": str(len(CLIENT)), "@@SERVER@@": SERVER, "@@CLIENT@@": CLIENT}.items():
    assert out.count(key) == 1, key
    out = out.replace(key, val)
assert "@@" not in out
(HERE / "install_funnel1.lua").write_text(out, encoding="utf-8")
print(f"install_funnel1.lua {len(out.encode())} bytes; server {len(SERVER)}, client {len(CLIENT)} chars")
