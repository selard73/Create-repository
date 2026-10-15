#!/usr/bin/env python3
"""Builds tools/birds/install_birds1.lua (job 100): ambient birds - gulls circling the harbour and the lighthouse, swallows over
the French village; client-side only, no gameplay. workspace.Birds {BirdsClient (RunContext Client)}; attributes Enabled true,
Sites (JSON). Re-runnable: an old Birds folder goes to ServerStorage.HudBackup.Birds_pre_n. Heights: the Porto harbour's quay is
at y -47 (sea level about -50), the lighthouse top at 74 on a terrace at 2, the French village ground about 2-4.
Run from the repo root: python3 tools/birds/make_install_birds1.py"""
import pathlib, json
HERE = pathlib.Path(__file__).resolve().parent
CLIENT = (HERE / "src/BirdsClient.lua").read_text(encoding="utf-8")
assert "]===]" not in CLIENT
SITES = [
    {"name": "Harbour gulls", "kind": "gull", "x": 225, "y": -12, "z": -670, "r": 30, "n": 6, "band": 10, "range": 500},
    {"name": "Harbour pelican", "kind": "pelican", "x": 215, "y": -36, "z": -690, "r": 34, "n": 1, "band": 2, "range": 500},
    {"name": "Lighthouse gulls", "kind": "gull", "x": 520, "y": 86, "z": -1178, "r": 26, "n": 5, "band": 12, "range": 500},
    {"name": "Village swallows", "kind": "swallow", "x": 262, "y": 30, "z": -58, "r": 34, "n": 8, "band": 8, "range": 400},
]
sites_json = json.dumps(SITES, separators=(",", ":"))
assert "]==]" not in sites_json
TEMPLATE = '''-- install_birds1.lua (Studio EDIT mode; re-runnable; its body also runs as a play-test PREVIEW). Job 100: ambient birds (Shannon,
-- Oct 15 2026: "and some birds?"): gulls circling the harbour and the lighthouse, swallows darting over the French village in
-- figure-eights; purely visual, client-side (nothing replicates, nothing to touch), flocks asleep while the camera is far.
-- workspace.Birds: BirdsClient (@@CLEN@@ chars) + attributes Enabled, Sites (JSON: name, kind, x, y, z, r, n, band, range - edit
-- the attribute in Studio to move a flock, no code). Undo: delete workspace.Birds. No DataStore, no publish. "QQ BIRDS".
local SS = game:GetService("ServerStorage")
local CLIENT = [===[
@@CLIENT@@]===]
do   -- the compile check, where loadstring can run: the source is compiled with the luau CLI before every push
	local ok, f, err = pcall(function() return loadstring(CLIENT) end)
	if ok and not f then print("QQ BIRDS ABORT: BirdsClient does not compile: " .. tostring(err)) return end
end
local old = workspace:FindFirstChild("Birds")
local F = Instance.new("Folder"); F.Name = "Birds"
F:SetAttribute("Enabled", true)
F:SetAttribute("Sites", [==[@@SITES@@]==])
local T = Instance.new("Folder"); T.Name = "Templates"; T.Parent = F   -- (a mesh Gull / Pelican / Swallow dropped in here replaces the part-built bird of that kind)
if old then local ot = old:FindFirstChild("Templates"); if ot then for _, m in ipairs(ot:GetChildren()) do m:Clone().Parent = T end end end
if old then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Birds_pre_" .. n) do n += 1 end
	old.Name = "Birds_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local c = Instance.new("Script"); c.Name = "BirdsClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ BIRDS DONE: workspace.Birds (BirdsClient %d chars; 4 sites: harbour gulls, a harbour pelican, lighthouse gulls, village swallows; mesh templates under workspace.Birds.Templates when she adds them)%s", #c.Source, old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
out = TEMPLATE
for key, val in {"@@CLEN@@": str(len(CLIENT)), "@@CLIENT@@": CLIENT, "@@SITES@@": sites_json}.items():
    assert out.count(key) == 1, key
    out = out.replace(key, val)
assert "@@" not in out
(HERE / "install_birds1.lua").write_text(out, encoding="utf-8")
print(f"install_birds1.lua {len(out.encode())} bytes; client {len(CLIENT)} chars; sites {sites_json}")
