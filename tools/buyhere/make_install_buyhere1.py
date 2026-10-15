#!/usr/bin/env python3
"""Builds tools/buyhere/install_buyhere1.lua (job 110): the buy-here cards at the zipline's launch (forest tower) and the hang glider's
ramp (Sandstone Climb). workspace.BuyHere {BuyHereClient (RunContext Client)} + attributes Enabled, Spots (JSON). Re-runnable (the old
folder -> HudBackup.BuyHere_pre_n). Its body also runs as a play-test PREVIEW. Run from the repo root."""
import pathlib, json
HERE = pathlib.Path(__file__).resolve().parent
CLIENT = (HERE / "src/BuyHereClient.lua").read_text(encoding="utf-8")
assert "]===]" not in CLIENT
SPOTS = [
    {"item": "ziphandle", "anchor": "Zipline/StationPost", "dy": 4, "range": 45, "title": "Zip line handle", "blurb": "Grab on and fly out over the farm"},
    {"item": "glider", "anchor": "HangGlider/Ramp", "dy": 6, "range": 50, "title": "Hang glider", "blurb": "Take off from the ramp and glide into the Rue"},
]
spots = json.dumps(SPOTS, separators=(",", ":"))
assert "]==]" not in spots
lua = '''-- install_buyhere1.lua (Studio EDIT; re-runnable; its body also runs as a play-test PREVIEW). Job 110: a "Buy here" card at the
-- zipline's launch and at the hang glider's ramp for players who do not own the item (Shannon, Oct 15 2026). workspace.BuyHere:
-- BuyHereClient (@@CLEN@@ chars) + attributes Enabled, Spots (JSON; edit a spot in Studio, no code). Undo: delete workspace.BuyHere.
local SS = game:GetService("ServerStorage")
local CLIENT = [===[
@@CLIENT@@]===]
do local ok, f, err = pcall(function() return loadstring(CLIENT) end); if ok and not f then print("QQ BUYHERE ABORT: BuyHereClient does not compile: " .. tostring(err)) return end end
local old = workspace:FindFirstChild("BuyHere")
if old then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("BuyHere_pre_" .. n) do n += 1 end
	old.Name = "BuyHere_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "BuyHere"
F:SetAttribute("Enabled", true)
F:SetAttribute("Spots", [==[@@SPOTS@@]==])
local c = Instance.new("Script"); c.Name = "BuyHereClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
local zl = workspace:FindFirstChild("Zipline"); local launch = zl and zl:FindFirstChild("StationPost", true)
local hg = workspace:FindFirstChild("HangGlider"); local ramp = hg and hg:FindFirstChild("Ramp")
print(string.format("QQ BUYHERE DONE: workspace.BuyHere (BuyHereClient %d chars; 2 spots: Zipline/StationPost %s, HangGlider/Ramp %s)%s", #c.Source, launch and "found" or "NOT FOUND", ramp and "found" or "NOT FOUND", old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
for k, v in {"@@CLEN@@": str(len(CLIENT)), "@@CLIENT@@": CLIENT, "@@SPOTS@@": spots}.items():
    assert lua.count(k) == 1; lua = lua.replace(k, v)
assert "@@" not in lua
(HERE / "install_buyhere1.lua").write_text(lua, encoding="utf-8")
print("install_buyhere1.lua", len(lua.encode()), "bytes; client", len(CLIENT))
