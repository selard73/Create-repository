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
    {"name": "Harbour gulls", "kind": "gull", "x": 225, "y": 22, "z": -670, "r": 34, "n": 3, "band": 8, "range": 500},   # (v7: three, high up - Shannon: fewer in the air, only the high ones)
    {"name": "Lighthouse gulls", "kind": "gull", "x": 520, "y": 92, "z": -1178, "r": 28, "n": 3, "band": 10, "range": 500},
    {"name": "Village swallows", "kind": "swallow", "x": 262, "y": 30, "z": -58, "r": 30, "n": 3, "band": 6, "range": 400},   # (v6: three, not eight)
    # perched (round 3: Shannon's rigged Meshy pelican and gull; round 4: the spots runner 7 settled in the preview)
    {"name": "Pelican on the quay", "kind": "pelican", "perch": True, "x": 232.5, "y": -46.56, "z": -667.6, "yaw": 280, "n": 1, "height": 2.6, "range": 220},   # (v7: Shannon, live: "that pelican is huge compared to the squirrel and boat" - 2.6 tall, was 4.2; tune by eye)
    {"name": "Gulls on the harbour rail", "kind": "gull", "perch": True, "x": 231.6, "y": -46.56, "z": -673.4, "yaw": 102, "n": 3, "height": 1.4, "range": 220,
     "offsets": [[0, 0, 0, 0], [7.5, 0, 0.6, 50], [-5.5, 0, 0.9, -70]]},   # (v7: not in a row - one here, one well along the rail turned to the sea, one back the other way; dx along the rail, dy up, dz across, yaw; tune in Studio)
    {"name": "Gulls at the lighthouse", "kind": "gull", "perch": True, "x": 526, "y": 3.5, "z": -1170, "yaw": 300, "n": 2, "gap": 2.4, "height": 1.4, "range": 260},
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
local T = Instance.new("Folder"); T.Name = "Templates"; T.Parent = F   -- (Templates.Gull / Pelican = the rigged standing meshes for the perches; Templates.GullFlying / PelicanFlying = wings-spread meshes for the flocks)
if old then local ot = old:FindFirstChild("Templates"); if ot then for _, m in ipairs(ot:GetChildren()) do m:Clone().Parent = T end end end
for _, m in ipairs(T:GetChildren()) do if m:IsA("Model") then m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent end end   -- (v4: a template must reach every client whole - her imports sit far away, and a streamed-out template is an empty Model)
if old then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Birds_pre_" .. n) do n += 1 end
	old.Name = "Birds_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local c = Instance.new("Script"); c.Name = "BirdsClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ BIRDS DONE: workspace.Birds (BirdsClient %d chars; 6 sites: 3 flocks + 3 perches; mesh templates: Templates.Gull / Templates.Pelican for the perches, Templates.GullFlying / PelicanFlying for the flocks)%s", #c.Source, old and ("; the old folder is HudBackup." .. old.Name) or ""))
'''
out = TEMPLATE
for key, val in {"@@CLEN@@": str(len(CLIENT)), "@@CLIENT@@": CLIENT, "@@SITES@@": sites_json}.items():
    assert out.count(key) == 1, key
    out = out.replace(key, val)
assert "@@" not in out
(HERE / "install_birds1.lua").write_text(out, encoding="utf-8")
print(f"install_birds1.lua {len(out.encode())} bytes; client {len(CLIENT)} chars; sites {sites_json}")
