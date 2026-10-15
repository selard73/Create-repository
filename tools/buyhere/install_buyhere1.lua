-- install_buyhere1.lua (Studio EDIT; re-runnable; its body also runs as a play-test PREVIEW). Job 110: a "Buy here" card at the
-- zipline's launch and at the hang glider's ramp for players who do not own the item (Shannon, Oct 15 2026). workspace.BuyHere:
-- BuyHereClient (5141 chars) + attributes Enabled, Spots (JSON; edit a spot in Studio, no code). Undo: delete workspace.BuyHere.
local SS = game:GetService("ServerStorage")
local CLIENT = [===[
-- BuyHereClient (workspace.BuyHere, RunContext Client). Job 110 (Shannon, Oct 15 2026: "put a button or icon at the top of the tower
-- where you zipline and the top of the cliff where you handglide to let them buy it right from that spot ... a lot of games do
-- that"). A small floating card at each spot - the zipline's launch on the forest tower, the hang glider's ramp on the Sandstone
-- Climb - for a player who does not own the item yet: the name, the two prices (acorns from the Acorn Store's Price_<id>, Robux from
-- the Game Pass on workspace.Passes) and a "Buy here" button that opens the Acorn Store at that item's row, where both buttons
-- live. The card is this player's only (a BillboardGui in their PlayerGui), hides the moment the item is theirs, and shows within
-- Range studs. Spots come from the folder's attribute Spots (JSON: [{item, anchor = "Folder/Child/...", dy, title, blurb, range}]).
local Players = game:GetService("Players")
local MPS = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, GREEN = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(70, 170, 110)
local FONT = Enum.Font.FredokaOne
local ROBUX = utf8.char(0xE002)
local function spots()
	local ok, t = pcall(function() return HttpService:JSONDecode(F:GetAttribute("Spots") or "[]") end)
	return (ok and type(t) == "table") and t or {}
end
local function findAnchor(spec)
	local o = workspace
	for name in string.gmatch(spec, "[^/]+") do
		o = o:WaitForChild(name, 120)
		if not o then return nil end
	end
	if o:IsA("BasePart") then return o end
	if o:IsA("Model") then return o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart", true) end
	return o:FindFirstChildWhichIsA("BasePart", true)
end
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p; return c end
local function makeCard(spot)
	local anchor = findAnchor(spot.anchor or "")
	if not anchor then warn("BuyHere: no anchor " .. tostring(spot.anchor)) return end
	local item = spot.item
	local bb = Instance.new("BillboardGui"); bb.Name = "BuyHere_" .. item; bb.Adornee = anchor
	bb.Size = UDim2.fromOffset(230, 96); bb.StudsOffset = Vector3.new(0, tonumber(spot.dy) or 4, 0)
	bb.MaxDistance = tonumber(spot.range) or 45; bb.AlwaysOnTop = false; bb.ResetOnSpawn = false; bb.Active = true; bb.Enabled = false; bb.Parent = pg
	local card = Instance.new("Frame"); card.Size = UDim2.fromScale(1, 1); card.BackgroundColor3 = NAVY; card.BackgroundTransparency = 0.08; card.Parent = bb
	corner(card, 14)
	local st = Instance.new("UIStroke"); st.Color = GOLD; st.Thickness = 2; st.Parent = card
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -16, 0, 26); title.Position = UDim2.fromOffset(8, 6); title.BackgroundTransparency = 1
	title.Font = FONT; title.TextSize = 19; title.TextColor3 = GOLD; title.Text = spot.title or item; title.Parent = card
	local price = Instance.new("TextLabel"); price.Size = UDim2.new(1, -16, 0, 20); price.Position = UDim2.fromOffset(8, 32); price.BackgroundTransparency = 1
	price.Font = FONT; price.TextSize = 15; price.TextColor3 = CREAM; price.Text = "..."; price.Parent = card
	local btn = Instance.new("TextButton"); btn.AnchorPoint = Vector2.new(0.5, 1); btn.Position = UDim2.new(0.5, 0, 1, -8); btn.Size = UDim2.fromOffset(150, 30)
	btn.BackgroundColor3 = GREEN; btn.Font = FONT; btn.TextSize = 16; btn.TextColor3 = Color3.new(1, 1, 1); btn.Text = "Buy here"; btn.Parent = card
	corner(btn, 10)
	local shop = workspace:FindFirstChild("Shop")
	local passes = workspace:FindFirstChild("Passes")
	local robux = nil
	local function refreshPrice()
		local acorns = shop and shop:GetAttribute("Price_" .. item)
		local a = (type(acorns) == "number") and (tostring(acorns) .. " acorns") or nil
		local r = robux and (ROBUX .. " " .. tostring(robux)) or nil
		price.Text = (a and r) and (a .. "   or   " .. r) or (a or r or "")
	end
	refreshPrice()
	if shop then shop:GetAttributeChangedSignal("Price_" .. item):Connect(refreshPrice) end
	task.spawn(function()
		local passId = passes and tonumber(passes:GetAttribute("Pass_" .. item)) or 0
		if passId > 0 then
			local ok, info = pcall(function() return MPS:GetProductInfo(passId, Enum.InfoType.GamePass) end)
			if ok and type(info) == "table" and info.PriceInRobux then robux = info.PriceInRobux; refreshPrice() end
		end
	end)
	btn.Activated:Connect(function()
		local openAt = shop and shop:FindFirstChild("OpenAt")
		if openAt then openAt:Fire(item) end
	end)
	local function update()
		local owned = (tonumber(player:GetAttribute("Item_" .. item)) or 0) > 0
		bb.Enabled = (not owned) and F:GetAttribute("Enabled") ~= false
	end
	player:GetAttributeChangedSignal("Item_" .. item):Connect(update)
	player:GetAttributeChangedSignal("SaveLoaded"):Connect(update)
	F:GetAttributeChangedSignal("Enabled"):Connect(update)
	update()
end
for _, s in ipairs(spots()) do task.spawn(makeCard, s) end
print("BuyHere: " .. #spots() .. " spot(s)")
]===]
do local ok, f, err = pcall(function() return loadstring(CLIENT) end); if ok and not f then print("QQ BUYHERE ABORT: BuyHereClient does not compile: " .. tostring(err)) return end end
local old = workspace:FindFirstChild("BuyHere")
if old then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("BuyHere_pre_" .. n) do n += 1 end
	old.Name = "BuyHere_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "BuyHere"
F:SetAttribute("Enabled", true)
F:SetAttribute("Spots", [==[[{"item":"ziphandle","anchor":"Zipline/StationPost","dy":4,"range":45,"title":"Zip line handle","blurb":"Grab on and fly out over the farm"},{"item":"glider","anchor":"HangGlider/Ramp","dy":6,"range":50,"title":"Hang glider","blurb":"Take off from the ramp and glide into the Rue"}]]==])
local c = Instance.new("Script"); c.Name = "BuyHereClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
local zl = workspace:FindFirstChild("Zipline"); local launch = zl and zl:FindFirstChild("StationPost", true)
local hg = workspace:FindFirstChild("HangGlider"); local ramp = hg and hg:FindFirstChild("Ramp")
print(string.format("QQ BUYHERE DONE: workspace.BuyHere (BuyHereClient %d chars; 2 spots: Zipline/StationPost %s, HangGlider/Ramp %s)%s", #c.Source, launch and "found" or "NOT FOUND", ramp and "found" or "NOT FOUND", old and ("; the old folder is HudBackup." .. old.Name) or ""))
