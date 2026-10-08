-- ShopPanel: the store itself, opened by the purse square in the corner.
--
-- It is painted in the squirrel panel's own colours - parchment face, walnut rim, gold edge, acorn-brown ink -
-- so it reads as another page of the same book rather than a window from a different game.
--
-- The panel never sends a price. It asks the server for an item by name and the server decides what that costs
-- and whether you can have it; the numbers shown here are only what is painted on the label. Prices are read
-- live from workspace.Shop, so changing one in the Properties panel changes the shop in front of the player.
-- Run in edit mode: require(workspace.ShopPanel.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local F = workspace:FindFirstChild("Shop")
	assert(F, "ShopPanel: run build_shop first")
	local old = F:FindFirstChild("ShopClient"); if old then old:Destroy() end

	local SRC = [==[
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local buy = RS:WaitForChild("ShopBuy")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local ROBUX = utf8.char(0xE002)                 -- the official Robux symbol, in Roblox's own fonts

local RGB = Color3.fromRGB
local FACE, FACE_DEEP, RIM = RGB(250, 241, 219), RGB(234, 220, 189), RGB(118, 80, 46)
local SLOT, SLOT_EDGE = RGB(228, 212, 179), RGB(162, 131, 90)
local EDGE, INK, INK_DIM = RGB(203, 150, 48), RGB(64, 42, 22), RGB(132, 108, 80)
local GOLD, BTN_INK = RGB(255, 202, 62), RGB(84, 48, 18)
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = o; return c end
local function stroke(o, col, th, tr)
	local st = Instance.new("UIStroke"); st.Color = col; st.Thickness = th; st.Transparency = tr or 0
	st.Parent = o; return st
end

-- what each thing is, in the player's words. The server owns ids and prices; this owns the label and the joke.
local ITEMS = {
	-- the mime is tipped at his hat, in the street, not from a menu
	{id = "seed",       name = "Seed packet",     blurb = "Plant it in the garden. Nobody knows what comes up."},
	{id = "ziphandle",  name = "Zipline handle",  blurb = "Yours to keep. Grab on at the top of the forest tower and fly out over the farm.", once = true},
	{id = "bubbles",    name = "Fountain colour", blurb = "Tip it in and the fountain runs your colour, bubbles and all, for ten minutes - for everyone here.", palette = 6},
	{id = "binoculars", name = "Spotter's binoculars", blurb = "Hiding squirrels glow red - even through the trees. Robux only.", once = true, robux = true},
	{id = "zoomies",    name = "Zoomies",         blurb = "Ten minutes of running faster, everywhere. Buy again for ten more. Not on the race clock."},
	{id = "portrait",   name = "Sit for a portrait", blurb = "The painter paints you and sets you on an easel in his gallery by the river - the twelve newest sitters stay."},
	{id = "slingshot",  name = "Slingshot",       blurb = "There is a hoop in the forest. An acorn a shot; sink one and win three.", once = true},
	{id = "backpack",   name = "Backpack",        blurb = "Carry your things, and your favourite squirrel, on your back.", once = true},
	{id = "glider",     name = "Hang glider",     blurb = "Yours to keep. Take off from the top of the Sandstone Climb and glide into the Rue.", once = true},
}

local gui = Instance.new("ScreenGui")
gui.Name = "ShopPanel"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 7
gui.Enabled = false; gui.Parent = pg

local shade = Instance.new("TextButton")                 -- tap anywhere outside to close
shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = RGB(20, 12, 6)
shade.BackgroundTransparency = 0.45; shade.Text = ""; shade.AutoButtonColor = false
shade.BorderSizePixel = 0; shade.ZIndex = 1; shade.Parent = gui

local W, H = 440, 470
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(W, H); panel.BackgroundColor3 = FACE; panel.BorderSizePixel = 0
panel.ZIndex = 2; panel.Parent = gui
corner(panel, UDim.new(0, 22))
stroke(panel, RIM, 4, 0)
local scale = Instance.new("UIScale"); scale.Parent = panel

-- a phone held sideways has little room; shrink the whole page rather than letting it run off the edge
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min((vp.Y - 40) / H, (vp.X - 40) / W), 0.5, 1)
end
-- The camera may not exist yet when this runs, and asking an absent camera for its size quietly gives the
-- default 1280x720 - which is bigger than a phone, so the panel would never shrink. Wait for it.
task.spawn(function()
	for _ = 1, 40 do
		if workspace.CurrentCamera then break end
		task.wait(0.25)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
end)
fit()

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(24, 18); title.Size = UDim2.fromOffset(W - 140, 34)
title.BackgroundTransparency = 1; title.Text = "Acorn Store"; title.TextXAlignment = Enum.TextXAlignment.Left
title.FontFace = FONT; title.TextSize = 28; title.TextColor3 = RGB(58, 36, 16); title.ZIndex = 3
title.Parent = panel

-- the purse, so the decision and the balance are on the same page
local purse = Instance.new("TextLabel")
purse.AnchorPoint = Vector2.new(1, 0); purse.Position = UDim2.new(1, -58, 0, 20)
purse.Size = UDim2.fromOffset(110, 30); purse.BackgroundColor3 = SLOT; purse.BorderSizePixel = 0
purse.FontFace = FONT; purse.TextSize = 19; purse.TextColor3 = INK; purse.Text = "0"; purse.ZIndex = 3
purse.Parent = panel
corner(purse, UDim.new(0, 10)); stroke(purse, SLOT_EDGE, 2, 0.3)

local close = Instance.new("TextButton")
close.AnchorPoint = Vector2.new(1, 0); close.Position = UDim2.new(1, -18, 0, 18)
close.Size = UDim2.fromOffset(32, 32); close.BackgroundColor3 = SLOT; close.BorderSizePixel = 0
close.FontFace = FONT; close.TextSize = 20; close.TextColor3 = INK; close.Text = "X"
close.AutoButtonColor = false; close.ZIndex = 3; close.Parent = panel
corner(close, UDim.new(0, 10)); stroke(close, SLOT_EDGE, 2, 0.3)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(16, 62); list.Size = UDim2.fromOffset(W - 32, H - 78)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = RIM; list.CanvasSize = UDim2.new(); list.ZIndex = 3
list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.Parent = panel
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 10)
lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = list

local rows = {}
-- THE FOUNTAIN IS EVERYONE'S (Shannon, Sep 26: "when somebody turns the fountain color with bubbles, I want everybody to
-- be able to see it ... It can only be chosen if it's not currently colored"): one colour at a time for the whole
-- server; while it runs, the row says whose colour it is and when it's free again, and no swatch can be bought
local COLOUR_NAMES = {"pink", "orange", "gold", "green", "blue", "violet"}
local function fountainNow()
	local FC = workspace:FindFirstChild("FountainColour")
	local idx = FC and FC:GetAttribute("ActiveColour") or 0
	local untilT = FC and FC:GetAttribute("ActiveUntil") or 0
	local left = untilT - workspace:GetServerTimeNow()
	if idx > 0 and left > 0 then return idx, math.ceil(left), (FC:GetAttribute("ActiveBy") or "someone") end
	return 0, 0, nil
end
local function mmss(s) return string.format("%d:%02d", math.floor(s / 60), s % 60) end
local function priceOf(item)
	return F:GetAttribute("Price_" .. item.id)
end

-- One record per row, held beside the frame rather than on it: Roblox will not let you invent fields on an
-- Instance, so row.note would simply throw.
local function say(rec, text, good)
	rec.note.Text = text
	rec.note.TextColor3 = good and RGB(64, 112, 48) or RGB(150, 52, 30)
	rec.note.TextTransparency = 0
	TweenService:Create(rec.note, TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1.1),
		{TextTransparency = 1}):Play()
end

-- on sale if the whole store is, or if this one thing has been switched on by itself
local function onSale(item)
	return F:GetAttribute("Selling") == true or F:GetAttribute("Sell_" .. item.id) == true
end

local busy = false
local function attempt(item, rec, amount)
	if busy then return end
	busy = true
	if rec.btn then rec.btn.Text = "..." end
	local ok, res, why = pcall(function() return buy:InvokeServer(item.id, amount) end)
	busy = false
	if rec.btn then rec.btn.Text = rec.label end
	if not ok then say(rec, "the shop did not answer", false) return end
	if res then
		say(rec, item.id == "tip" and "he tips his hat" or "bought", true)
	else
		say(rec, tostring(why or "no"), false)
	end
end

for i, item in ipairs(ITEMS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 84); row.BackgroundColor3 = FACE_DEEP; row.BorderSizePixel = 0
	row.LayoutOrder = i; row.ZIndex = 3; row.Parent = list
	corner(row, UDim.new(0, 14)); stroke(row, SLOT_EDGE, 2, 0.45)

	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(14, 9); name.Size = UDim2.fromOffset(228, 22)
	name.BackgroundTransparency = 1; name.Text = item.name; name.TextXAlignment = Enum.TextXAlignment.Left
	name.FontFace = FONT; name.TextSize = 19; name.TextColor3 = RGB(58, 36, 16); name.ZIndex = 4
	name.Parent = row

	local blurb = Instance.new("TextLabel")
	-- 228 wide, stopping at x242: the three tip buttons reach back to x253, so nothing can run under them
	blurb.Position = UDim2.fromOffset(14, 32); blurb.Size = UDim2.fromOffset(item.palette and 196 or 228, 44)   -- room for the swatches
	blurb.BackgroundTransparency = 1; blurb.Text = item.blurb; blurb.TextWrapped = true
	blurb.TextXAlignment = Enum.TextXAlignment.Left; blurb.TextYAlignment = Enum.TextYAlignment.Top
	blurb.FontFace = FONT; blurb.TextSize = 13; blurb.TextColor3 = INK_DIM; blurb.ZIndex = 4
	blurb.Parent = row

	local note = Instance.new("TextLabel")
	note.AnchorPoint = Vector2.new(1, 1); note.Position = UDim2.new(1, -12, 1, -6)
	note.Size = UDim2.fromOffset(150, 16); note.BackgroundTransparency = 1; note.Text = ""
	note.TextXAlignment = Enum.TextXAlignment.Right; note.FontFace = FONT; note.TextSize = 13
	note.TextTransparency = 1; note.ZIndex = 4; note.Parent = row

	local rec = {frame = row, note = note, label = "", blurb = blurb}
	rows[item.id] = rec

	if item.palette then
		-- SIX SWATCHES instead of a button, each the buy button for its colour; the colours come from the same
		-- attributes the fountain itself reads, so the shop and the fountain can never disagree
		local FC = workspace:FindFirstChild("FountainColour")
		rec.swatches = {}
		local n = item.palette
		for i = 1, n do
			local sw = Instance.new("TextButton"); sw.Name = "Swatch" .. i; sw.Text = ""
			sw.AnchorPoint = Vector2.new(1, 0); sw.Position = UDim2.new(1, -12 - (n - i) * 28, 0, 14)
			sw.Size = UDim2.fromOffset(24, 24); sw.BorderSizePixel = 0; sw.AutoButtonColor = false; sw.ZIndex = 4
			sw.BackgroundColor3 = (FC and FC:GetAttribute("Colour" .. i)) or RGB(200, 200, 200)
			sw.Parent = row
			corner(sw, UDim.new(1, 0)); stroke(sw, RGB(84, 48, 18), 2, 0.25)
			sw.MouseButton1Click:Connect(function()
				if not onSale(item) then say(rec, "not in the shop yet", false) return end
				local runIdx, left = fountainNow()
				if runIdx > 0 then say(rec, "the fountain is taken - free in " .. mmss(left), false) return end
				attempt(item, rec, i)
			end)
			rec.swatches[i] = sw
		end
		local pl = Instance.new("TextLabel"); pl.Name = "PriceLabel"; pl.AnchorPoint = Vector2.new(1, 0); pl.Position = UDim2.new(1, -12, 0, 42)
		pl.Size = UDim2.fromOffset(n * 28, 18); pl.BackgroundTransparency = 1; pl.FontFace = FONT; pl.TextSize = 14
		pl.TextColor3 = INK_DIM; pl.TextXAlignment = Enum.TextXAlignment.Right; pl.Text = ""; pl.ZIndex = 4; pl.Parent = row
		rec.priceLabel = pl
	else
	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0); btn.Position = UDim2.new(1, -12, 0, 12)
	btn.Size = UDim2.fromOffset(120, 34); btn.BackgroundColor3 = GOLD; btn.BorderSizePixel = 0
	btn.FontFace = FONT; btn.TextSize = 18; btn.TextColor3 = BTN_INK
	btn.AutoButtonColor = false; btn.ZIndex = 4; btn.Parent = row
	corner(btn, UDim.new(0, 10)); stroke(btn, RGB(150, 98, 36), 2, 0.2)
	rec.btn = btn
	btn.MouseButton1Click:Connect(function()
		if item.id == "backpack" and (player:GetAttribute("Item_backpack") or 0) > 0 then
			local BW = workspace:FindFirstChild("BackpackWear"); local ev = BW and BW:FindFirstChild("ToggleWear")
			if ev then ev:FireServer() else say(rec, "the backpack is not answering", false) end
			return
		end
		if item.robux then
			-- a Game Pass: Roblox's own purchase prompt does the selling; the server grants the item when it completes
			if (player:GetAttribute("Item_" .. item.id) or 0) > 0 then say(rec, "already yours", true) return end
			local B = workspace:FindFirstChild(item.passHome or "Binoculars")
			local passId = B and tonumber(B:GetAttribute(item.passAttr or "BinocularsPassId")) or 0
			if passId <= 0 then say(rec, "coming soon", false) return end
			game:GetService("MarketplaceService"):PromptGamePassPurchase(player, passId)
			return
		end
		if not onSale(item) then say(rec, "not in the shop yet", false) return end
		attempt(item, rec)
	end)
	end
end

-- ---- answers to purchases made from a prompt in the world (the cheese stand): a toast, since there is no row
local said = RS:WaitForChild("ShopSaid")
local saidGui = Instance.new("ScreenGui"); saidGui.Name = "ShopSaid"; saidGui.ResetOnSpawn = false; saidGui.IgnoreGuiInset = true; saidGui.DisplayOrder = 8; saidGui.Parent = pg
local saidLabel = Instance.new("TextLabel"); saidLabel.AnchorPoint = Vector2.new(0.5, 1); saidLabel.Position = UDim2.new(0.5, 0, 1, -118); saidLabel.Size = UDim2.fromOffset(380, 44)
saidLabel.BackgroundColor3 = RGB(58, 36, 16); saidLabel.BackgroundTransparency = 0.1; saidLabel.BorderSizePixel = 0; saidLabel.FontFace = FONT; saidLabel.TextSize = 20
saidLabel.TextColor3 = GOLD; saidLabel.Text = ""; saidLabel.Visible = false; saidLabel.Parent = saidGui
corner(saidLabel, UDim.new(0, 14)); stroke(saidLabel, GOLD, 2, 0.2)
local saidAt = 0
said.OnClientEvent:Connect(function(id, ok, why)
	if ok and id == "cheese" then return end                   -- the eating says it
	local text = ok and "Bought!" or (why == "not on sale yet" and "Coming soon" or tostring(why or "no"))
	saidLabel.Text = text; saidLabel.Visible = true
	local t = os.clock(); saidAt = t
	task.delay(3, function() if saidAt == t then saidLabel.Visible = false end end)
end)

-- ---- ACORN PACKS: Robux straight into the purse. Developer Products; the id of each lives on workspace.AcornPacks as
-- Product_<key> (0 until Shannon creates it on the Creator Hub) and what it grants as Acorns_<key>. The price is whatever
-- the product says, read from Roblox, so re-pricing is done there and nowhere else. The ReceiptRouter grants the acorns.
local PACKS = {
	{key = "handful", name = "A handful of acorns",     blurb = "Tipped straight into your purse. A slingshot's worth, or a portrait with change."},
	{key = "basket",  name = "A basket of acorns",      blurb = "The painter could do the whole family."},
	{key = "barrow",  name = "A wheelbarrow of acorns", blurb = "A backpack's worth, and a portrait to celebrate."},
}
local PK = workspace:WaitForChild("AcornPacks", 10)
local packRows, packPrice = {}, {}
local refreshPacks
local function fetchPackPrice(pk)
	local id = PK and PK:GetAttribute("Product_" .. pk.key) or 0
	if id <= 0 or packPrice[pk.key] ~= nil then return end
	packPrice[pk.key] = "..."
	task.spawn(function()
		local ok, info = pcall(function() return MarketplaceService:GetProductInfo(id, Enum.InfoType.Product) end)
		packPrice[pk.key] = (ok and info and info.PriceInRobux) or false
		refreshPacks()
	end)
end
local packHeader = Instance.new("TextLabel")
packHeader.Size = UDim2.new(1, 0, 0, 30); packHeader.BackgroundTransparency = 1; packHeader.LayoutOrder = 50; packHeader.ZIndex = 3
packHeader.Text = "Acorn packs  -  Robux, straight into your purse"; packHeader.TextXAlignment = Enum.TextXAlignment.Left
packHeader.FontFace = FONT; packHeader.TextSize = 16; packHeader.TextColor3 = RGB(58, 36, 16); packHeader.Visible = false; packHeader.Parent = list
for i, pk in ipairs(PACKS) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 74); row.BackgroundColor3 = FACE_DEEP; row.BorderSizePixel = 0
	row.LayoutOrder = 50 + i; row.ZIndex = 3; row.Visible = false; row.Parent = list
	corner(row, UDim.new(0, 14)); stroke(row, SLOT_EDGE, 2, 0.45)
	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(14, 9); name.Size = UDim2.fromOffset(240, 22); name.BackgroundTransparency = 1
	name.TextXAlignment = Enum.TextXAlignment.Left; name.FontFace = FONT; name.TextSize = 19; name.TextColor3 = RGB(58, 36, 16); name.ZIndex = 4; name.Parent = row
	local blurb = Instance.new("TextLabel")
	blurb.Position = UDim2.fromOffset(14, 32); blurb.Size = UDim2.fromOffset(240, 36); blurb.BackgroundTransparency = 1
	blurb.Text = pk.blurb; blurb.TextWrapped = true; blurb.TextXAlignment = Enum.TextXAlignment.Left; blurb.TextYAlignment = Enum.TextYAlignment.Top
	blurb.FontFace = FONT; blurb.TextSize = 13; blurb.TextColor3 = INK_DIM; blurb.ZIndex = 4; blurb.Parent = row
	local note = Instance.new("TextLabel")
	note.AnchorPoint = Vector2.new(1, 1); note.Position = UDim2.new(1, -12, 1, -6); note.Size = UDim2.fromOffset(150, 16)
	note.BackgroundTransparency = 1; note.Text = ""; note.TextXAlignment = Enum.TextXAlignment.Right; note.FontFace = FONT
	note.TextSize = 13; note.TextTransparency = 1; note.ZIndex = 4; note.Parent = row
	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(1, 0); btn.Position = UDim2.new(1, -12, 0, 12); btn.Size = UDim2.fromOffset(120, 34)
	btn.BackgroundColor3 = GOLD; btn.BorderSizePixel = 0; btn.FontFace = FONT; btn.TextSize = 18; btn.TextColor3 = BTN_INK
	btn.AutoButtonColor = false; btn.ZIndex = 4; btn.Parent = row
	corner(btn, UDim.new(0, 10)); stroke(btn, RGB(150, 98, 36), 2, 0.2)
	local rec = {frame = row, note = note, btn = btn, name = name, label = ""}
	packRows[pk.key] = rec
	btn.MouseButton1Click:Connect(function()
		local id = PK and PK:GetAttribute("Product_" .. pk.key) or 0
		if id > 0 then
			MarketplaceService:PromptProductPurchase(player, id)      -- Roblox's own prompt sells it; the router grants it
		elseif RunService:IsStudio() and PK then
			PK.PackTry:FireServer(pk.key)                              -- free while testing, until the product exists
		else
			say(rec, "coming soon", false)
		end
	end)
end
refreshPacks = function()
	local studio = RunService:IsStudio()
	local anyLive = studio
	for _, pk in ipairs(PACKS) do
		local rec = packRows[pk.key]
		local id = PK and PK:GetAttribute("Product_" .. pk.key) or 0
		local n = PK and PK:GetAttribute("Acorns_" .. pk.key) or 0
		rec.name.Text = string.format("%s  (%d)", pk.name, n)
		if id > 0 then
			anyLive = true
			fetchPackPrice(pk)
			local price = packPrice[pk.key]
			rec.label = (type(price) == "number") and (ROBUX .. " " .. tostring(price)) or (ROBUX .. " ...")
		elseif studio then
			rec.label = "try (Studio)"
		else
			rec.label = "soon"
		end
		rec.btn.Text = rec.label
		local live = id > 0 or studio
		rec.btn.BackgroundColor3 = live and GOLD or RGB(214, 202, 176)
		rec.btn.TextColor3 = live and BTN_INK or INK_DIM
	end
	packHeader.Visible = anyLive
	for _, pk in ipairs(PACKS) do packRows[pk.key].frame.Visible = anyLive end
end
refreshPacks()
if PK then
	for _, pk in ipairs(PACKS) do
		PK:GetAttributeChangedSignal("Product_" .. pk.key):Connect(function() packPrice[pk.key] = nil; refreshPacks() end)
		PK:GetAttributeChangedSignal("Acorns_" .. pk.key):Connect(refreshPacks)
	end
	-- the toast: its own ScreenGui, because the panel's is disabled whenever the store is closed (Roblox's prompt closes it)
	local toastGui = Instance.new("ScreenGui"); toastGui.Name = "PackToast"; toastGui.ResetOnSpawn = false; toastGui.IgnoreGuiInset = true
	toastGui.DisplayOrder = 8; toastGui.Parent = pg
	local toast = Instance.new("TextLabel"); toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118)   -- above the hotbar, under any panel
	toast.Size = UDim2.fromOffset(380, 44); toast.BackgroundColor3 = RGB(58, 36, 16); toast.BackgroundTransparency = 0.1; toast.BorderSizePixel = 0
	toast.FontFace = FONT; toast.TextSize = 20; toast.TextColor3 = GOLD; toast.Text = ""; toast.Visible = false; toast.Parent = toastGui
	corner(toast, UDim.new(0, 14)); stroke(toast, GOLD, 2, 0.2)
	local toastAt = 0
	PK.PackBought.OnClientEvent:Connect(function(key, n)
		toast.Text = string.format("+%d acorns!  The squirrels thank you.", n)
		toast.Visible = true
		local t = os.clock(); toastAt = t
		task.delay(3.5, function() if toastAt == t then toast.Visible = false end end)
		local rec = packRows[key]; if rec then say(rec, "+" .. tostring(n) .. " acorns", true) end
	end)
end

-- Everything that can change while the panel is open: the balance, what a thing costs, and whether you own it
-- already. Redrawn rather than reasoned about, so the page can never disagree with the server.
local function refresh()
	local have = player:GetAttribute("Acorns") or 0
	purse.Text = tostring(have) .. "  acorns"
	for _, item in ipairs(ITEMS) do
		local rec = rows[item.id]
		if rec and rec.swatches then
			local price = priceOf(item)
			local selling = onSale(item)
			local runIdx, left, by = fountainNow()
			if runIdx > 0 then                                          -- someone's colour is running: whose, and until when
				rec.priceLabel.Text = "free in " .. mmss(left)
				if rec.blurb then rec.blurb.Text = string.format("In use: %s's %s. Free again in %s.", tostring(by), COLOUR_NAMES[runIdx] or "colour", mmss(left)) end
			else
				rec.priceLabel.Text = selling and (type(price) == "number" and (tostring(price) .. " acorns") or "-") or "soon"
				if rec.blurb then rec.blurb.Text = item.blurb end
			end
			local can = selling and type(price) == "number" and have >= price and runIdx == 0
			for i, sw in ipairs(rec.swatches) do
				sw.BackgroundTransparency = (can or i == runIdx) and 0 or 0.55
				local st = sw:FindFirstChildOfClass("UIStroke")
				if st then st.Color = (i == runIdx) and RGB(255, 246, 220) or RGB(84, 48, 18); st.Thickness = (i == runIdx) and 3 or 2; st.Transparency = (i == runIdx) and 0 or 0.25 end
			end
		elseif rec and rec.btn then
			local price = priceOf(item)
			local owned = (player:GetAttribute("Item_" .. item.id) or 0) > 0
			local label
			if item.id == "backpack" and owned then                    -- the bag comes off and goes back on from here
				label = ((player:GetAttribute("Item_bagoff") or 0) > 0) and "Wear it" or "Take it off"
			elseif item.once and owned then
				label = "owned"
			elseif item.robux then
				label = "Robux"
			elseif type(price) ~= "number" then
				label = "-"
			else
				label = tostring(price) .. " acorns"
			end
			-- Nothing is for sale yet, so every button says so rather than pretending to work. The price stays
			-- on show above it, because knowing what things will cost is the point of looking.
			local selling = item.robux or onSale(item)              -- a Robux row is sold by Roblox's prompt
			if not selling then label = "soon" end
			rec.label = label
			if rec.btn.Text ~= "..." then rec.btn.Text = label end
			-- greyed when you cannot have it, either because it is already yours or you are short
			local affordable = selling and not (item.once and owned) and (item.robux or (type(price) == "number" and have >= price))
			if item.id == "backpack" and owned then affordable = true end       -- the wear switch is always live
			rec.btn.BackgroundColor3 = affordable and GOLD or RGB(214, 202, 176)
			rec.btn.TextColor3 = affordable and BTN_INK or INK_DIM
			if item.passAttr then                                       -- a pass row stays hidden until its pass exists
				local home = workspace:FindFirstChild(item.passHome or "")
				rec.frame.Visible = (home ~= nil) and (tonumber(home:GetAttribute(item.passAttr)) or 0) > 0
			end
		end
	end
end
refresh()
player:GetAttributeChangedSignal("Acorns"):Connect(refresh)
player:GetAttributeChangedSignal("Item_bagoff"):Connect(refresh)
do                                                     -- the fountain is the server's: its colour and clock, and the countdown
	local FCw = workspace:FindFirstChild("FountainColour")
	if FCw then for _, a in ipairs({"ActiveColour", "ActiveUntil", "ActiveBy"}) do FCw:GetAttributeChangedSignal(a):Connect(refresh) end end
	task.spawn(function()
		local was = false
		while true do
			task.wait(1)
			local running = fountainNow() > 0
			if gui.Enabled and (running or was) then refresh() end
			was = running
		end
	end)
end
F:GetAttributeChangedSignal("Selling"):Connect(refresh)
for _, item in ipairs(ITEMS) do
	player:GetAttributeChangedSignal("Item_" .. item.id):Connect(refresh)
	F:GetAttributeChangedSignal("Price_" .. item.id):Connect(refresh)
	F:GetAttributeChangedSignal("Sell_" .. item.id):Connect(refresh)
end

local function setOpen(on)
	gui.Enabled = on
	if on then
		refresh()
		scale.Scale = 0.001
		fit()
		local want = scale.Scale
		scale.Scale = want * 0.86
		TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Scale = want}):Play()
	end
end
close.MouseButton1Click:Connect(function() setOpen(false) end)
shade.MouseButton1Click:Connect(function() setOpen(false) end)

-- OPEN AT A ROW: something in the world can open the store at its own row (the hang glider's ramp, for somebody who has
-- no glider yet: "see it in the Acorn Store"). workspace.Shop.OpenAt:Fire(id) - the row scrolls into view and its edge
-- glows gold for a moment.
task.spawn(function()
	local openAt = F:WaitForChild("OpenAt", 20)
	if not openAt then return end
	openAt.Event:Connect(function(id)
		if F:GetAttribute("Open") == false then return end
		if not gui.Enabled then setOpen(true) end
		local rec = rows[id]
		if not rec then return end
		local index = 1
		for i, item in ipairs(ITEMS) do if item.id == id then index = i end end
		list.CanvasPosition = Vector2.new(0, math.max(0, (index - 1) * 94 - 6))      -- rows are 84 tall with 10 between
		local st = rec.frame:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = GOLD; st.Thickness = 3; st.Transparency = 0
			task.delay(1.8, function() st.Color = SLOT_EDGE; st.Thickness = 2; st.Transparency = 0.45 end)
		end
	end)
end)

-- hang it off the purse square in the corner, whenever the bar turns up
task.spawn(function()
	for attempt = 1, 120 do
		local bar = pg:FindFirstChild("HudBar")
		local square = bar and bar:FindFirstChild("Bar") and bar.Bar:FindFirstChild("Purse")
		if square and square:IsA("TextButton") then
			square.MouseButton1Click:Connect(function()
				-- the purse always shows your count; it only OPENS the store when there is something in it
				-- worth buying. workspace.Shop.Open is the switch.
				if F:GetAttribute("Open") == false then return end
				setOpen(not gui.Enabled)
			end)
			F:GetAttributeChangedSignal("Open"):Connect(function()
				if F:GetAttribute("Open") == false and gui.Enabled then setOpen(false) end
			end)
			return
		end
		task.wait(0.5)
	end
	warn("ShopPanel: never found the purse button; the store cannot be opened")
end)
]==]
	if not F:FindFirstChild("OpenAt") then local e = Instance.new("BindableEvent"); e.Name = "OpenAt"; e.Parent = F end
	local s = Instance.new("Script"); s.Name = "ShopClient"; s.RunContext = Enum.RunContext.Client
	s.Source = SRC; s.Parent = F
	print("ShopPanel: installed - opens from the purse square in the top right")
end
