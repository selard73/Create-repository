-- canalwater2.lua (job 125): teal, deeper-looking water over the canal - a patch over canalwater1's result in
-- StarterPlayerScripts.JapanWaterAppearance (exact-string; anchor counted once; backup to ServerStorage.HudBackup; compiled before
-- writing; idempotent by the CANALWATER2 marker; needs CANALWATER1). Studio EDIT, then publish and restart servers. Output "QQ CANALWATER2".
local SS = game:GetService("ServerStorage")
local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local s = sps and sps:FindFirstChild("JapanWaterAppearance")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ CANALWATER2 ABORT: StarterPlayerScripts.JapanWaterAppearance not found") return end
local src = s.Source
if src:find("CANALWATER2", 1, true) then print("QQ CANALWATER2 already applied (marker present) - nothing changed") return end
if not src:find("CANALWATER1", 1, true) then print("QQ CANALWATER2 ABORT: canalwater1 is not applied (no CANALWATER1 marker) - run canalwater1.lua first") return end
print(string.format("QQ CANALWATER2 source: %d bytes (expected %d)", #src, 1608))
local EDITS = {
	{[==[if canal then terrain.WaterTransparency=.9;terrain.WaterReflectance=.1 else terrain.WaterTransparency=.32;terrain.WaterReflectance=.45 end]==],
	 [==[if canal then terrain.WaterColor=Color3.fromRGB(40,104,112);terrain.WaterTransparency=.68;terrain.WaterReflectance=.2 --[[CANALWATER2: teal, deeper-looking]] else terrain.WaterColor=Color3.fromRGB(24,112,151);terrain.WaterTransparency=.32;terrain.WaterReflectance=.45 end]==]}
}
local out = src
for i, e in ipairs(EDITS) do
	local a, b = e[1], e[2]
	local n, pos = 0, 1
	while true do local f = out:find(a, pos, true); if not f then break end; n += 1; pos = f + 1 end
	if n ~= 1 then print(string.format("QQ CANALWATER2 ABORT: anchor %d found %d times (want 1) - the script differs from canalwater1's result", i, n)) return end
	local f = out:find(a, 1, true)
	out = out:sub(1, f - 1) .. b .. out:sub(f + #a)
end
local fn, err = loadstring(out)
if not fn then print("QQ CANALWATER2 ABORT: the patched script does not compile: " .. tostring(err)) return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bk = s:Clone(); bk.Name = "JapanWaterAppearance_pre_canalwater2"; bk.Disabled = true; bk.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before canalwater2") end)
s.Source = out
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after canalwater2") end)
print(string.format("QQ CANALWATER2 DONE: JapanWaterAppearance patched (%d -> %d bytes): over the canal WaterColor (40,104,112), WaterTransparency 0.68, WaterReflectance 0.2; elsewhere in Japan (24,112,151) / 0.32 / 0.45; backup HudBackup.JapanWaterAppearance_pre_canalwater2. Publish, then restart servers.", #src, #out))
