#!/usr/bin/env python3
"""ride_persist1.lua: the funicolare stays loaded for a balloon rider for the whole ride (Shannon, Oct 10, VR: "the far side
where the funicolare is fades in and out when on the balloon ride"). Streaming drops the model at that distance on her
headset. Atomic (job 75) brought the whole model in and out together, so it popped as a unit. Now:
  - "15 Funicolare".ModelStreamingMode = PersistentPerPlayer (others still see it stream as a whole, like Atomic);
  - BalloonField attribute RidePersistent = "PortoNocciola/15 Funicolare" (";"-separated workspace paths; add more later);
  - BalloonServer: ridePersist(p, true) at boarding, ridePersist(p, false) at home (a leaver is dropped by Roblox itself).
Exact-string patch of the live 10373-char BalloonServer, backup HudBackup.BalloonServer_pre_ride1.
"""
import pathlib
HERE = pathlib.Path(__file__).resolve().parent
SRC = (HERE / "src" / "BalloonServer.lua").read_text(encoding="utf-8")
assert len(SRC) == 10373, len(SRC)

def patch(src, old, new):
    assert src.count(old) == 1, (src.count(old), old[:80])
    return src.replace(old, new)

NEW = SRC
NEW = patch(NEW, "local function flight(p)\n", '''-- WHAT THE RIDER MUST KEEP SEEING from up there (Shannon, Oct 10: the funicolare "fades in and out" on the ride - streaming
-- drops it at that distance on a headset): every model named in the folder's RidePersistent attribute (workspace paths,
-- ";" apart; the installer sets them to ModelStreamingMode PersistentPerPlayer) stays loaded for the rider for the ride.
local function ridePersist(p, on)
	for path in string.gmatch(tostring(F:GetAttribute("RidePersistent") or ""), "[^;]+") do
		local m = workspace
		for seg in string.gmatch(path, "[^/]+") do m = m and m:FindFirstChild(seg) end
		if m and m:IsA("Model") then
			pcall(function() if on then m:AddPersistentPlayer(p) else m:RemovePersistentPlayer(p) end end)
		end
	end
end
local function flight(p)
''')
NEW = patch(NEW, '\tev:FireAllClients("phase", p, "board", 2)\n', '\tridePersist(p, true)\n\tev:FireAllClients("phase", p, "board", 2)\n')
NEW = patch(NEW, '\tev:FireAllClients("phase", p, "home", 2)\n', '\tridePersist(p, false)\n\tev:FireAllClients("phase", p, "home", 2)\n')
assert "]===]" not in NEW
OLD_LEN, NEW_LEN = len(SRC), len(NEW)

INSTALLER = f'''-- ride_persist1.lua (Studio EDIT mode; re-runnable). Job 77.
-- The funicolare stays loaded for a balloon rider for the whole ride (Shannon, Oct 10, VR: "the far side where the
-- funicolare is fades in and out when on the balloon ride"). "15 Funicolare" -> ModelStreamingMode PersistentPerPlayer
-- (for everyone else it still streams as one whole, as Atomic did); BalloonField.RidePersistent names it; BalloonServer adds
-- the rider at boarding and drops them at home ({OLD_LEN} -> {NEW_LEN} chars; backup HudBackup.BalloonServer_pre_ride1).
-- Undo: BalloonServer.Source = HudBackup.BalloonServer_pre_ride1.Source; the model back to Atomic. No publish.
local SS = game:GetService("ServerStorage")
local town = workspace:FindFirstChild("PortoNocciola"); local M = town and town:FindFirstChild("15 Funicolare")
if not (M and M:IsA("Model")) then print("QQ RIDE ABORT: workspace.PortoNocciola['15 Funicolare'] not found") return end
local bf = workspace:FindFirstChild("BalloonField"); local bs = bf and bf:FindFirstChild("BalloonServer")
if not bs then print("QQ RIDE ABORT: workspace.BalloonField.BalloonServer not found") return end
local NEW = [===[
{NEW}]===]
local already = bs.Source == NEW
if not already then
	if #bs.Source ~= {OLD_LEN} then print(string.format("QQ RIDE ABORT: BalloonServer is %d chars, expected {OLD_LEN} (not the job 33 text; export it first); nothing changed", #bs.Source)) return end
	local f, err = loadstring(NEW); if not f then print("QQ RIDE ABORT: the new server does not compile: " .. tostring(err)) return end
end
if M:GetAttribute("StreamingWas") == nil then M:SetAttribute("StreamingWas", M.ModelStreamingMode.Name) end
M.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
if bf:GetAttribute("RidePersistent") == nil then bf:SetAttribute("RidePersistent", "PortoNocciola/15 Funicolare") end
if not already then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	if not hb:FindFirstChild("BalloonServer_pre_ride1") then local b = Instance.new("ModuleScript"); b.Name = "BalloonServer_pre_ride1"; b.Source = bs.Source; b.Parent = hb end
	bs.Source = NEW
end
print(string.format("QQ RIDE DONE: %s is %s; BalloonField.RidePersistent = %s; BalloonServer %d chars%s", M:GetFullName(), M.ModelStreamingMode.Name,
	tostring(bf:GetAttribute("RidePersistent")), #bs.Source, already and " (already patched)" or " (backup HudBackup.BalloonServer_pre_ride1)"))
'''
(HERE / "ride_persist1.lua").write_text(INSTALLER, encoding="utf-8", newline="\n")
(HERE / "src" / "BalloonServer_ride1.lua").write_text(NEW, encoding="utf-8", newline="\n")
print("ride_persist1.lua written:", OLD_LEN, "->", NEW_LEN)
