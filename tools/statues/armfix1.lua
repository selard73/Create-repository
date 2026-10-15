-- statues/armfix1 (job 107): EDIT mode. Statues no longer get a second right arm: workspace.Champion.ChampionServer's MakeStatue
-- builds one figure at a time and removes a same-named figure already on the spot before parenting the new one (Shannon, Oct 15 2026).
-- Two exact-string patches, counted first; compiled where loadstring runs; original -> ServerStorage.HudBackup.ChampionServer_pre_armfix1.
-- Output "QQ ARM".
if game:GetService("RunService"):IsRunning() then print("QQ ARM ABORT - Play mode") return end
local CH = workspace:FindFirstChild("Champion")
local s = CH and CH:FindFirstChild("ChampionServer")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ ARM ABORT - missing workspace.Champion.ChampionServer") return end
local o = s.Source
print("QQ ARM ChampionServer is " .. #o .. " chars")
if o:find("ARMFIX1", 1, true) then print("QQ ARM DONE (already patched): ChampionServer " .. #o) return end
local P = {{[===[
mk.OnInvoke = function(rec, o) return makeFigure(rec, o) end
]===], [===[
local making = false   -- ARMFIX1_20261015: one figure at a time - two overlapping builds left two statues on one spot (one posed, one not)
mk.OnInvoke = function(rec, o)
	local t0 = os.clock()
	while making and os.clock() - t0 < 60 do task.wait(0.1) end
	making = true
	local ok, m, a, r, l = pcall(makeFigure, rec, o)
	making = false
	if not ok then error(m) end
	return m, a, r, l
end
]===]}, {[===[
	model.Parent = o.parent or F
]===], [===[
	do   -- ARMFIX1: a figure of this name already on the spot (an earlier build never taken down, or one left half-posed by a failed build) goes first
		local par = o.parent or F
		for _, s in ipairs(par:GetChildren()) do
			if s ~= model and s:IsA("Model") and s.Name == model.Name and s:FindFirstChild("RightHand") then s:Destroy() end
		end
	end
	model.Parent = o.parent or F
]===]}}
for i, p in ipairs(P) do
	local a, b = o:find(p[1], 1, true)
	if not a then print("QQ ARM ABORT - anchor " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then print("QQ ARM ABORT - anchor " .. i .. " matches more than once; nothing changed") return end
end
local n = o
for _, p in ipairs(P) do local a, b = n:find(p[1], 1, true); n = n:sub(1, a - 1) .. p[2] .. n:sub(b + 1) end
do
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ ARM ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
if not backup:FindFirstChild("ChampionServer_pre_armfix1") then local c = s:Clone(); if c then c.Name = "ChampionServer_pre_armfix1"; c.Enabled = false; c.Parent = backup end end
s.Source = n
print(string.format("QQ ARM DONE: ChampionServer %d -> %d chars; backup ServerStorage.HudBackup.ChampionServer_pre_armfix1", #o, #n))
