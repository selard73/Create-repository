-- v22 (PLAY, CLIENT view): outfit test - buy a portrait once outfit A is on, and again once outfit B is on
local RS = game:GetService("RunService")
if not RS:IsClient() or not RS:IsRunning() then warn("QQ P19 ABORT - Play, client view") return end
local p = game.Players.LocalPlayer
local G = workspace.PortraitGallery
local hung = 0
G.PortraitDone.OnClientEvent:Connect(function(what, info)
	if what == "hung" then hung += 1; warn("QQ P19 hung #" .. hung) end
	if what == "reveal" then warn("QQ P19 reveal variant " .. tostring(type(info) == "table" and info.variant)) end
	if what == "deferred" then warn("QQ P19 DEFERRED") end
end)
task.spawn(function()
	for n, want in ipairs({"A", "B"}) do
		local deadline = os.clock() + 60
		repeat task.wait(0.5) until p:GetAttribute("QQOutfit") == want or os.clock() > deadline
		if p:GetAttribute("QQOutfit") ~= want then warn("QQ P19 STOP - outfit " .. want .. " never came on") return end
		task.wait(2.5)
		p.PlayerGui:SetAttribute("OpenPanel", nil)
		local ok, why = game.ReplicatedStorage.ShopBuy:InvokeServer("portrait")
		warn("QQ P19 buy in outfit " .. want .. " -> " .. tostring(ok) .. " " .. tostring(why))
		if not ok then return end
		deadline = os.clock() + 60
		repeat task.wait(0.5) until hung >= n or os.clock() > deadline
		if hung < n then warn("QQ P19 STOP - portrait " .. n .. " not hung") return end
	end
	warn("QQ P19 DONE - two sittings, two outfits")
end)
