-- install_thanks1.lua (Studio EDIT mode; re-runnable). Job 92: acorn thank-you gifts paid the next time a named player joins.
-- workspace.Thanks: Gifts (StringValues: Name = username, Value = acorns; attributes Id, Note), ThanksServer (3427 chars),
-- ThanksClient (3485 chars), ThanksEvent. To add a gift later: a StringValue under workspace.Thanks.Gifts, no code. Undo:
-- delete workspace.Thanks (gifts already paid stay paid: Item_thanks_<id> on the player's save). No publish.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
for _, need in ipairs({"AwardItems", "AwardAcorns"}) do if not RS:FindFirstChild(need) then print("QQ THANKS ABORT: ReplicatedStorage." .. need .. " not found") return end end
local SERVER = [===[
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
]===]
local CLIENT = [===[
-- ThanksClient (workspace.Thanks, RunContext Client): the thank-you card (daily-card look). Shown when the server pays a gift;
-- on top of everything until closed (Shannon's rule); never while another panel is open (waits for a clear moment).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = F:WaitForChild("ThanksEvent")
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, DEEP = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(84, 48, 18)
local FONT = Enum.Font.FredokaOne
local phone = (function() local ok, pi = pcall(function() return UIS.PreferredInput end); if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end; return UIS.TouchEnabled and not UIS.MouseEnabled end)()
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o end
local gui = Instance.new("ScreenGui"); gui.Name = "ThanksGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.Enabled = false; gui.Parent = pg
local W, H = 320, 168
local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, phone and 78 or 110)
card.Size = UDim2.fromOffset(W, H); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Parent = gui; corner(card, 16)
local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2; cs.Parent = card
local function text(t, size, colour, y, h)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(16, y); l.Size = UDim2.fromOffset(W - 32, h); l.BackgroundTransparency = 1
	l.Font = FONT; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.Parent = card
	return l
end
local title = text("A thank-you from the mayor", 20, CREAM, 10, 26)
local note = text("", 14, GOLD, 38, 56)
local sum = text("", 15, CREAM, 94, 22)
local ok = Instance.new("TextButton"); ok.AnchorPoint = Vector2.new(0.5, 1); ok.Position = UDim2.new(0.5, 0, 1, -10); ok.Size = UDim2.fromOffset(150, 34)
ok.BackgroundColor3 = GOLD; ok.BorderSizePixel = 0; ok.Font = FONT; ok.TextSize = 17; ok.TextColor3 = DEEP; ok.Text = "Thank you!"; ok.Parent = card; corner(ok, 12)
local function close() gui.Enabled = false; if pg:GetAttribute("OpenPanel") == "thanks" then pg:SetAttribute("OpenPanel", nil) end end
ok.Activated:Connect(close)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if gui.Enabled and pg:GetAttribute("OpenPanel") ~= "thanks" then gui.Enabled = false end end)
ev.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then return end
	title.Text = tostring(info.title or "A thank-you from the mayor"); note.Text = tostring(info.note or "")
	sum.Text = string.format("%d acorns are in your purse.", tonumber(info.acorns) or 0)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 120 do
			local daily = pg:FindFirstChild("DailyGui"); local dcard = daily and daily:FindFirstChild("DailyCard")
			local dailyUp = daily ~= nil and daily.Enabled and dcard ~= nil and dcard.Visible
			if pg:GetAttribute("OpenPanel") == nil and not dailyUp then pg:SetAttribute("OpenPanel", "thanks"); gui.Enabled = true; return end
			task.wait(1)
		end
		pg:SetAttribute("OpenPanel", "thanks"); gui.Enabled = true   -- (two minutes of panels: show it anyway; the acorns are already theirs)
	end)
end)
print("ThanksClient: ready")
]===]
for _, pair in ipairs({{"server", SERVER}, {"client", CLIENT}}) do
	local f, err = loadstring(pair[2]); if not f then print("QQ THANKS ABORT: the " .. pair[1] .. " does not compile: " .. tostring(err)) return end
end
local GIFTS = {
	{name = "mentallyunstable_xo", acorns = 1000},
	{name = "blizzy_1718", acorns = 1000},
}
local old = workspace:FindFirstChild("Thanks")
local F = Instance.new("Folder"); F.Name = "Thanks"
F:SetAttribute("Title", "A thank-you from the mayor"); F:SetAttribute("DefaultNote", [==[Thank you for writing to the mayor! Your letter made our day.]==]); F:SetAttribute("Delay", 8); F:SetAttribute("MaxGift", 5000)
local gifts = Instance.new("Folder"); gifts.Name = "Gifts"; gifts.Parent = F
local carried = 0
if old then
	for k, v in pairs(old:GetAttributes()) do F:SetAttribute(k, v) end
	local og = old:FindFirstChild("Gifts")
	if og then for _, v in ipairs(og:GetChildren()) do if v:IsA("StringValue") then v:Clone().Parent = gifts; carried += 1 end end end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Thanks_pre_" .. n) do n += 1 end
	old.Name = "Thanks_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local added = 0
for _, g in ipairs(GIFTS) do
	local dup = false
	for _, v in ipairs(gifts:GetChildren()) do if v.Name:lower() == g.name:lower() and (v:GetAttribute("Id") or "") == "note1" then dup = true end end
	if not dup then local v = Instance.new("StringValue"); v.Name = g.name; v.Value = tostring(g.acorns); v:SetAttribute("Id", "note1"); v.Parent = gifts; added += 1 end
end
local ev = Instance.new("RemoteEvent"); ev.Name = "ThanksEvent"; ev.Parent = F
local s = Instance.new("Script"); s.Name = "ThanksServer"; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "ThanksClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
local names = {}
for _, v in ipairs(gifts:GetChildren()) do table.insert(names, v.Name .. "=" .. v.Value) end
print(string.format("QQ THANKS DONE: workspace.Thanks (server %d, client %d chars); gifts: %s (%d added, %d carried over)%s", #s.Source, #c.Source, table.concat(names, ", "), added, carried, old and ("; the old folder is HudBackup." .. old.Name) or ""))
