-- GENERATED: actual client receipt handler, with output captured by mocks.
return function(d)
local ev,player,workspace,os=d.ev,d.player,d.workspace,d.os
local banner,chat=d.banner,d.chat
local celebrationGate=d.celebrationGate or {accept=function()return false end}
local fireworks=d.fireworks or function()end
local warn=d.warn or function()end
local receipts = {}
ev.OnClientEvent:Connect(function(what, a)
	if what == "crowned" and type(a) == "table" then
        if not celebrationGate.accept(a) then return end
        local showOk, showError = pcall(fireworks, 25)
        if not showOk then warn("PortoKeeper: fireworks unavailable: " .. tostring(showError)) end
		local t = workspace:FindFirstChild("PortoKeeper") and workspace.PortoKeeper:GetAttribute("Title") or "Guardian of the Harbour"
		if a.uid == player.UserId then
			banner("You are the " .. t .. "!", "Your statue stands by the lighthouse, holding the harbour key")
		else
			banner(tostring(a.name) .. " is the " .. t .. "!", "First today to find all " .. tostring(a.total or 44) .. " squirrels of Porto Nocciola")
		end
		chat(string.format("%s found all %d squirrels of Porto Nocciola first today and is the %s. Their statue stands by the lighthouse.", tostring(a.name), tonumber(a.total) or 44, t))
    elseif what == "recovered" and type(a) == "table" then
        if receipts[a.claimId] then return end
        receipts[a.claimId] = true
        chat("Your Guardian award for " .. os.date("!%B %d, %Y", a.day * 86400 + 43200) .. " is confirmed. You keep your title; the lighthouse displays today's winner.")
    elseif what == "late" then
        local record = type(a) == "table" and a or {name=tostring(a)}
        if record.claimId and receipts[record.claimId] then return end
        if record.claimId then receipts[record.claimId] = true end
        local date = record.day and (" for " .. os.date("!%B %d, %Y", record.day * 86400 + 43200)) or " today"
        chat("You found every squirrel in Porto Nocciola! " .. tostring(record.name) .. " holds the award" .. date .. ". To compete on another day, reset your finds and collect all 44 again.")
    elseif what == "reset_needed" then
        chat("To compete on another day, reset your finds and collect all 44 Italy squirrels again.")
    elseif what == "unavailable" then
        chat("Your Guardian result is pending. We will retry automatically and when you rejoin, for the day you completed Italy.")
	elseif what == "already" then
		chat("You already hold the harbour key, Guardian.")
	end
end)


end
