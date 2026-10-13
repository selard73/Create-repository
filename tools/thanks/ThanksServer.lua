-- ThanksServer (workspace.Thanks): acorn thank-you gifts for named players, paid the next time they join (Shannon, Oct 13
-- 2026: three players wrote to the mayor; "how can we best do that for next time they log in?"). HOW TO ADD A GIFT, in Studio,
-- no code: in workspace.Thanks.Gifts add a StringValue whose Name is the player's USERNAME (as on their profile, not the
-- display name) and whose Value is the number of acorns (1000). Optional attribute Note on it = the message they see; the
-- default is the folder's attribute DefaultNote. The gift is paid once: the player's save gets Item_thanks_<giftId> = 1
-- (giftId = the StringValue's attribute Id, or its name lower-cased when there is none), so the same gift never repeats
-- even if the StringValue stays; a second gift to the same person needs a new Id (e.g. "note2"). Paid through the game's own
-- ledger (ReplicatedStorage.AwardAcorns + the Acorns attribute, AwardItems for the flag), never the DataStore directly.
-- The player sees a card: "A thank-you from the mayor" / note / "1000 acorns are in your purse". Studio: the owner can test
-- with a StringValue in their own name.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local gifts = F:WaitForChild("Gifts")
local ev = F:WaitForChild("ThanksEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local function item(p, id) return tonumber(p:GetAttribute("Item_" .. id)) or 0 end
local function giftId(v) local id = v:GetAttribute("Id"); return (type(id) == "string" and id ~= "" and id or v.Name):lower():gsub("[^%w_]", "_") end
local function giftsFor(p)
	local out = {}
	local name = p.Name:lower()
	for _, v in ipairs(gifts:GetChildren()) do
		if v:IsA("StringValue") and v.Name:lower() == name then
			local n = tonumber(v.Value)
			if n and n > 0 and n <= (F:GetAttribute("MaxGift") or 5000) then table.insert(out, {v = v, n = math.floor(n)}) end
		end
	end
	return out
end
local busy = {}
local function pay(p)
	if busy[p] then return end
	busy[p] = true
	local t0 = os.clock()
	while p.Parent and not p:GetAttribute("SaveLoaded") and os.clock() - t0 < 60 do task.wait(0.5) end
	if not (p.Parent and p:GetAttribute("SaveLoaded")) then busy[p] = nil return end
	task.wait(F:GetAttribute("Delay") or 8)   -- (let the arrival settle)
	if not p.Parent then busy[p] = nil return end
	local total, notes = 0, {}
	for _, g in ipairs(giftsFor(p)) do
		local flag = "thanks_" .. giftId(g.v)
		if item(p, flag) == 0 then
			awardItems:Fire(p, flag, 1)
			awardAcorns:Fire(p, g.n)
			p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + g.n)
			total += g.n
			local note = g.v:GetAttribute("Note"); if type(note) ~= "string" or note == "" then note = F:GetAttribute("DefaultNote") or "Thank you for writing to the mayor!" end
			table.insert(notes, note)
			print(string.format("Thanks: %d acorns to %s (%s)", g.n, p.Name, flag))
		end
	end
	if total > 0 then ev:FireClient(p, {acorns = total, note = notes[1], title = F:GetAttribute("Title") or "A thank-you from the mayor"}) end
	busy[p] = nil
end
Players.PlayerAdded:Connect(function(p) task.spawn(pay, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(pay, p) end
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
print("ThanksServer: ready (" .. #gifts:GetChildren() .. " gift lines)")
