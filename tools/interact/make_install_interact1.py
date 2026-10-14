#!/usr/bin/env python3
"""Builds tools/interact/install_interact1.lua (job 98): what players interact with, counted for the Creator Dashboard.
workspace.Interact {InteractServer}; attributes Enabled true, Repeat 60, Budget 90 (LogPrints unset = prints in Studio only).
Re-runnable: an old Interact folder goes to ServerStorage.HudBackup.Interact_pre_n with its script disabled.
Run from the repo root: python3 tools/interact/make_install_interact1.py"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
SERVER = (HERE / "src/InteractServer.lua").read_text(encoding="utf-8")
assert "]===]" not in SERVER
TEMPLATE = '''-- install_interact1.lua (Studio EDIT mode; re-runnable). Job 98: what players interact with, counted for the Creator Dashboard
-- (Shannon, Oct 14 2026: "a tool that will count and give info on how far each player gets and what they interact with"; "how far"
-- is the funnel, job 95). workspace.Interact: InteractServer (@@SLEN@@ chars) listens to what the game already fires - every prompt
-- triggered, click, seat, tool equipped or used, area entered, item gained - and sends AnalyticsService custom events
-- Interact_<kind> with Device / Cohort (from the funnel) / Name fields, once per player per thing per minute, at most Budget per
-- server per minute. Nothing else is patched. Events leave only a published place; in Studio the server prints what it would send.
-- Undo: delete workspace.Interact. No DataStore, no publish. Output lines start with "QQ INTERACT".
local SS = game:GetService("ServerStorage")
local SERVER = [===[
@@SERVER@@]===]
do   -- the compile check, where loadstring can run: the sources are compiled with the luau CLI before every push
	local ok, f, err = pcall(function() return loadstring(SERVER) end)
	if ok and not f then print("QQ INTERACT ABORT: the server does not compile: " .. tostring(err)) return end
end
local old = workspace:FindFirstChild("Interact")
local F = Instance.new("Folder"); F.Name = "Interact"
F:SetAttribute("Enabled", true); F:SetAttribute("Repeat", 60); F:SetAttribute("Budget", 90)
if old then
	for k, v in pairs(old:GetAttributes()) do F:SetAttribute(k, v) end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Interact_pre_" .. n) do n += 1 end
	old.Name = "Interact_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local s = Instance.new("Script"); s.Name = "InteractServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
F.Parent = workspace
print(string.format("QQ INTERACT DONE: workspace.Interact (InteractServer %d chars; Enabled %s, Repeat %s, Budget %s)%s", #s.Source, tostring(F:GetAttribute("Enabled")), tostring(F:GetAttribute("Repeat")), tostring(F:GetAttribute("Budget")), old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
out = TEMPLATE
for key, val in {"@@SLEN@@": str(len(SERVER)), "@@SERVER@@": SERVER}.items():
    assert out.count(key) == 1, key
    out = out.replace(key, val)
assert "@@" not in out
(HERE / "install_interact1.lua").write_text(out, encoding="utf-8")
print(f"install_interact1.lua {len(out.encode())} bytes; server {len(SERVER)} chars")
