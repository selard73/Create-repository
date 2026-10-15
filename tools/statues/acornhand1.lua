-- statues/acornhand1 (job 107c): EDIT mode. The giant acorn rests in the statue's palm (the hand's grip attachment), not on top of
-- the hand part's box (Shannon's "star" statue: a long-handed body package put it a head above the hand). One exact-string patch of
-- workspace.Champion.ChampionServer; counted first; compiled where loadstring runs; backup HudBackup.ChampionServer_pre_acornhand1.
-- Statues already standing keep their acorn until they are rebuilt. Output "QQ ACORN".
if game:GetService("RunService"):IsRunning() then print("QQ ACORN ABORT - Play mode") return end
local CH = workspace:FindFirstChild("Champion")
local s = CH and CH:FindFirstChild("ChampionServer")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ ACORN ABORT - missing workspace.Champion.ChampionServer") return end
local o = s.Source
if o:find("ACORNHAND1", 1, true) then print("QQ ACORN DONE (already patched): " .. #o) return end
local F1, R1 = [===[
			placeOn(a, holding.Position.X, holding.Position.Y + holding.Size.Y / 2 - 0.2, holding.Position.Z)   -- resting on the raised hand
]===], [===[
			-- ACORNHAND1_20261015: the acorn rests in the PALM (the hand's grip attachment), whatever the body package's hand box - a package
			-- with a 2.85-stud hand part put the acorn a head above the visible hand (Shannon's "star" statue); the old spot is the fallback
			local grip = holding:FindFirstChild(holdSide .. "GripAttachment")
			if grip then placeOn(a, grip.WorldPosition.X, grip.WorldPosition.Y + 0.15, grip.WorldPosition.Z)
			else placeOn(a, holding.Position.X, holding.Position.Y + holding.Size.Y / 2 - 0.2, holding.Position.Z) end   -- resting on the raised hand
]===]
local a, b = o:find(F1, 1, true)
if not a then print("QQ ACORN ABORT - anchor not found (" .. #o .. " chars); nothing changed") return end
if o:find(F1, b + 1, true) then print("QQ ACORN ABORT - anchor matches more than once; nothing changed") return end
local n = o:sub(1, a - 1) .. R1 .. o:sub(b + 1)
do local ok, f, err = pcall(function() return loadstring(n) end); if ok and not f then print("QQ ACORN ABORT - patched source does not compile: " .. tostring(err)) return end end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
if not hb:FindFirstChild("ChampionServer_pre_acornhand1") then local c = s:Clone(); if c then c.Name = "ChampionServer_pre_acornhand1"; c.Enabled = false; c.Parent = hb end end
s.Source = n
print(string.format("QQ ACORN DONE: ChampionServer %d -> %d chars; backup HudBackup.ChampionServer_pre_acornhand1", #o, #n))
