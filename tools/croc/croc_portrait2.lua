-- croc/croc_portrait2 (job 113 round 2): EDIT mode, after croc_portrait1. The croc all-free card and the top-of-screen notes take
-- turns (runner 7's phone check): (1) workspace.Lagoon.CrocClient celebrate() waits up to 8 s while the DailyCard is down or the
-- PortraitNote shows; (2) workspace.PortraitGallery.PortraitClient's note waits up to 7 s while PlayerGui.CrocToast is up. Each anchor
-- counted first, each result compiled, originals -> ServerStorage.HudBackup.<Name>_pre_crocportrait2. Output lines "QQ CROCP2".
if game:GetService("RunService"):IsRunning() then print("QQ CROCP2 ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local MARK = [===[
CROCPORTRAIT2_20261015]===]
local function patch(label, s, find, repl)
	if not (s and s:IsA("LuaSourceContainer")) then print("QQ CROCP2 " .. label .. ": script not found; skipped") return false end
	local o = s.Source
	if o:find(MARK, 1, true) then print("QQ CROCP2 " .. label .. ": already patched (" .. #o .. " chars)") return true end
	local a, b = o:find(find, 1, true)
	if not a then print("QQ CROCP2 " .. label .. ": anchor not found (is croc_portrait1 in?); nothing changed") return false end
	if o:find(find, b + 1, true) then print("QQ CROCP2 " .. label .. ": anchor matches more than once; nothing changed") return false end
	local n = o:sub(1, a - 1) .. repl .. o:sub(b + 1)
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ CROCP2 " .. label .. ": patched source does not compile: " .. tostring(err) .. "; nothing changed") return false end
	local bn = s.Name .. "_pre_crocportrait2"
	if not backup:FindFirstChild(bn) then local c = s:Clone(); c.Name = bn; c.Enabled = false; c.Parent = backup end
	s.Source = n
	print(string.format("QQ CROCP2 %s: %d -> %d chars; backup HudBackup.%s", label, #o, #n, bn))
	return true
end
local Lg = workspace:FindFirstChild("Lagoon")
local G = workspace:FindFirstChild("PortraitGallery")
local r1 = patch("CrocClient", Lg and Lg:FindFirstChild("CrocClient"), [===[
	celebratedOnce = true
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
]===], [===[
	celebratedOnce = true
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
	-- CROCPORTRAIT2_20261015: the top of the screen is shared - wait (up to 8 s) while the daily card is down or the portrait note shows
	local function busy()
		local dg = pg:FindFirstChild("DailyGui"); local dc = dg and dg:FindFirstChild("DailyCard", true)
		if dc and dg.Enabled and dc.Visible and dc.Position.Y.Offset > -100 then return true end
		local pn = pg:FindFirstChild("PortraitNote"); local nt = pn and pn:FindFirstChildOfClass("TextLabel")
		if nt and nt.TextTransparency < 0.9 then return true end
		return false
	end
	local t0 = os.clock(); while busy() and os.clock() - t0 < 8 do task.wait(0.25) end
]===])
local r2 = patch("PortraitClient", G and G:FindFirstChild("PortraitClient"), [===[
	if what == "hungall" and uid == player.UserId then return end   -- CROCPORTRAIT1_20261015: the sitter has their own note
]===], [===[
	if what == "hungall" and uid == player.UserId then return end   -- CROCPORTRAIT1_20261015: the sitter has their own note
	do local t0 = os.clock(); while player.PlayerGui:FindFirstChild("CrocToast") and os.clock() - t0 < 7 do task.wait(0.25) end end   -- CROCPORTRAIT2_20261015: after the croc card
]===])
print(string.format("QQ CROCP2 DONE: CrocClient %s, PortraitClient %s", tostring(r1), tostring(r2)))
