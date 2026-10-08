-- v15 (PLAY, CLIENT view): buy three portraits in a row through the real store call, each after the last is hung
local RS = game:GetService("RunService")
if not RS:IsClient() or not RS:IsRunning() then warn("QQ P12 ABORT - Play, client view") return end
local p = game.Players.LocalPlayer
local G = workspace.PortraitGallery
local hung = 0
G.PortraitDone.OnClientEvent:Connect(function(what, info)
	if what == "hung" then hung += 1; warn("QQ P12 hung #" .. hung .. " " .. tostring(type(info) == "table" and info.modelKey)) end
	if what == "reveal" then warn("QQ P12 reveal variant " .. tostring(type(info) == "table" and info.variant)) end
	if what == "deferred" then warn("QQ P12 DEFERRED") end
end)
task.spawn(function()
	for n = 1, 3 do
		local deadline = os.clock() + 20
		while (G:GetAttribute("SessionUser") or p:GetAttribute("PortraitSitting")) and os.clock() < deadline do task.wait(0.5) end
		local ok, why = game.ReplicatedStorage.ShopBuy:InvokeServer("portrait")
		warn("QQ P12 buy #" .. n .. " -> " .. tostring(ok) .. " " .. tostring(why))
		local want = n
		deadline = os.clock() + 60
		while hung < want and os.clock() < deadline do task.wait(0.5) end
		if hung < want then warn("QQ P12 STOP - portrait #" .. n .. " was not hung in 60 s") return end
		p.PlayerGui:SetAttribute("OpenPanel", nil)
		task.wait(3)
	end
	warn("QQ P12 DONE - three portraits bought and hung")
end)
