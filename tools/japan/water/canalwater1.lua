-- canalwater1.lua (job 125): clear water over the canal - a canal-zone state in StarterPlayerScripts.JapanWaterAppearance (exact-string
-- patch; anchors counted once; backup to ServerStorage.HudBackup; compiled before writing; idempotent by the CANALWATER1 marker).
-- Studio EDIT on Shannon's word, then publish and restart servers. Output "QQ CANALWATER1".
local SS = game:GetService("ServerStorage")
local sps = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local s = sps and sps:FindFirstChild("JapanWaterAppearance")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ CANALWATER1 ABORT: StarterPlayerScripts.JapanWaterAppearance not found") return end
local src = s.Source
if src:find("CANALWATER1", 1, true) then print("QQ CANALWATER1 already applied (marker present) - nothing changed") return end
print(string.format("QQ CANALWATER1 source: %d bytes (expected %d)", #src, 1204))
local EDITS = {
	{[==[local active=false;local saved={};local elapsed=0]==],
	 [==[local active=false;local canalOn=false;local saved={};local elapsed=0]==]},
	{[==[ and p.Position.Z<850  if inside and not active then]==],
	 [==[ and p.Position.Z<850  local canal=inside and p.Position.X>6080 and p.Position.X<6125 and p.Position.Z>-230 and p.Position.Z<110 --[[CANALWATER1: clear water over the canal's dark bed]]  if inside and not active then]==]},
	{[==[active=true  elseif not inside and active then restore();active=false end end)]==],
	 [==[active=true;canalOn=false  elseif not inside and active then restore();active=false;canalOn=false end  if active and canal~=canalOn then canalOn=canal;if canal then terrain.WaterTransparency=.9;terrain.WaterReflectance=.1 else terrain.WaterTransparency=.32;terrain.WaterReflectance=.45 end end end)]==]}
}
local out = src
for i, e in ipairs(EDITS) do
	local a, b = e[1], e[2]
	local n, pos = 0, 1
	while true do local f = out:find(a, pos, true); if not f then break end; n += 1; pos = f + 1 end
	if n ~= 1 then print(string.format("QQ CANALWATER1 ABORT: anchor %d found %d times (want 1) - the script differs from the pushed source", i, n)) return end
	local f = out:find(a, 1, true)
	out = out:sub(1, f - 1) .. b .. out:sub(f + #a)
end
local fn, err = loadstring(out)
if not fn then print("QQ CANALWATER1 ABORT: the patched script does not compile: " .. tostring(err)) return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bk = s:Clone(); bk.Name = "JapanWaterAppearance_pre_canalwater1"; bk.Disabled = true; bk.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before canalwater1") end)
s.Source = out
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after canalwater1") end)
print(string.format("QQ CANALWATER1 DONE: JapanWaterAppearance patched (%d -> %d bytes): over the canal (x 6080..6125, z -230..110) WaterTransparency 0.9 / WaterReflectance 0.1, elsewhere in Japan 0.32 / 0.45 as before; backup HudBackup.JapanWaterAppearance_pre_canalwater1. Publish, then restart servers.", #src, #out))
