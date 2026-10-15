-- croc/croc_portrait1 (job 113): EDIT mode. Three exact-string patches (Shannon, Oct 15 2026): (1) workspace.Lagoon.CrocClient - the
-- all-free card shows to onlookers once a session, always to the rescuers, whose card adds "Heroes should have a portrait done! The
-- painter is waiting by the river."; (2) workspace.PortraitGallery.PortraitServer - a hung portrait fires "hungall" to everyone;
-- (3) workspace.PortraitGallery.PortraitClient - "hungall" shows "<name>'s new portrait is hanging in the painter's gallery by the
-- river." Each anchor is counted before anything changes; each result is compiled; originals -> ServerStorage.HudBackup.<Name>_pre_crocportrait1.
-- Independent: a script that fails its checks is skipped and the others still go in. Output lines "QQ CROCP".
if game:GetService("RunService"):IsRunning() then print("QQ CROCP ABORT - Play mode") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local MARK = [===[
CROCPORTRAIT1_20261015]===]
local function patch(label, s, pairs_)
	if not (s and s:IsA("LuaSourceContainer")) then print("QQ CROCP " .. label .. ": script not found; skipped") return false end
	local o = s.Source
	if o:find(MARK, 1, true) then print("QQ CROCP " .. label .. ": already patched (" .. #o .. " chars)") return true end
	local n = o
	for i, pr in ipairs(pairs_) do
		local a, b = n:find(pr[1], 1, true)
		if not a then print("QQ CROCP " .. label .. ": anchor " .. i .. " not found; nothing changed - tell the cloud thread") return false end
		if n:find(pr[1], b + 1, true) then print("QQ CROCP " .. label .. ": anchor " .. i .. " matches more than once; nothing changed") return false end
		n = n:sub(1, a - 1) .. pr[2] .. n:sub(b + 1)
	end
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ CROCP " .. label .. ": patched source does not compile: " .. tostring(err) .. "; nothing changed") return false end
	local bn = s.Name .. "_pre_crocportrait1"
	if not backup:FindFirstChild(bn) then local c = s:Clone(); c.Name = bn; c.Enabled = false; c.Parent = backup end
	s.Source = n
	print(string.format("QQ CROCP %s: %d -> %d chars; backup HudBackup.%s", label, #o, #n, bn))
	return true
end
local Lg = workspace:FindFirstChild("Lagoon")
local G = workspace:FindFirstChild("PortraitGallery")
local r1 = patch("CrocClient", Lg and Lg:FindFirstChild("CrocClient"), {{[===[
local function celebrate(names)
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
]===], [===[
local celebratedOnce = false                                                   -- CROCPORTRAIT1_20261015: onlookers see the all-free card once a session; the rescuers always do
local function celebrate(names)
	local mine = false
	for _, n in ipairs(type(names) == "table" and names or {}) do if n == player.DisplayName then mine = true end end
	if not mine and celebratedOnce then return end
	celebratedOnce = true
	local pg = player:FindFirstChildOfClass("PlayerGui"); if not pg then return end
]===]}, {[===[
	line("Madame Margaux says merci, " .. who .. "!", 52, 40, 18, C(240, 196, 110))
]===], [===[
	line("Madame Margaux says merci, " .. who .. "!", 52, 40, 18, C(240, 196, 110))
	if mine then card.Size = UDim2.fromOffset(390, 138); line("Heroes should have a portrait done! The painter is waiting by the river.", 92, 40, 15, C(255, 244, 214)) end   -- (CROCPORTRAIT1: Shannon's line for the heroes)
]===]}})
local r2 = patch("PortraitServer", G and G:FindFirstChild("PortraitServer"), {{[===[
 if player.Parent then done:FireClient(player,"hung",{late=late==true,modelKey=model.Name})end
 return true
end
]===], [===[
 if player.Parent then done:FireClient(player,"hung",{late=late==true,modelKey=model.Name})end
 if player.Parent then done:FireAllClients("hungall",player.DisplayName,player.UserId)end   -- CROCPORTRAIT1_20261015: everyone hears a portrait was hung
 return true
end
]===]}})
local r3 = patch("PortraitClient", G and G:FindFirstChild("PortraitClient"), {{[===[
done.OnClientEvent:Connect(function(what, late)
	if what ~= "hung" and what ~= "deferred" then return end
	local v=player.PlayerGui:FindFirstChild("PortraitViewer");if what=="hung"and v and v.Page.Visible then return end
]===], [===[
done.OnClientEvent:Connect(function(what, late, uid)
	if what ~= "hung" and what ~= "deferred" and what ~= "hungall" then return end
	if what == "hungall" and uid == player.UserId then return end   -- CROCPORTRAIT1_20261015: the sitter has their own note
	local v=player.PlayerGui:FindFirstChild("PortraitViewer");if what=="hung"and v and v.Page.Visible then return end
]===]}, {[===[
	if what=="deferred"then note.Text="Your paid portrait is still being prepared. You do not need to buy it again; the painter is retrying automatically, even if you leave."end
]===], [===[
	if what=="deferred"then note.Text="Your paid portrait is still being prepared. You do not need to buy it again; the painter is retrying automatically, even if you leave."end
	if what=="hungall"then note.Text=tostring(late).."'s new portrait is hanging in the painter's gallery by the river."end
]===]}})
if r2 and not r3 then print("QQ CROCP NOTE: the server now fires 'hungall' but the client patch did not go in - harmless (the client ignores it), but the game-wide line will not show until it does") end
print(string.format("QQ CROCP DONE: CrocClient %s, PortraitServer %s, PortraitClient %s", tostring(r1), tostring(r2), tostring(r3)))
