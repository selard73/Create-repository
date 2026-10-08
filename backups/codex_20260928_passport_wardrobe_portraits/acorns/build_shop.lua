-- Shop: spending acorns. Everything here is decided on the SERVER - the price, whether you can afford it, and
-- whether you already own it - because a client that is trusted with a price is a client that gets things free.
--
-- Nothing in this script writes to the DataStore. It fires the two events that SquirrelSetup listens for, and
-- that one script, which already owns the key, records both the spend and the item. Spending is simply a
-- negative award; the purse was built as a running delta from the start so that this would work.
--
-- Prices live as attributes on workspace.Shop (Price_seed, Price_backpack, ...), so re-pricing the whole shop
-- is editing numbers in the Properties panel rather than shipping code.
--
-- WHAT IS LOCAL AND WHAT IS NOT: most things bought here change only the buyer's own screen - their plot, their
-- paintings - so nobody can take the one vegetable plot. The backpack is an exception, because a worn thing nobody
-- else can see is not worth nine hundred acorns; so is the fountain colour since Sep 26 (Shannon: everybody sees it,
-- one colour at a time for the whole server). Buying is recorded here; what each item DOES is built elsewhere.
-- Run in edit mode: require(workspace.Shop.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")

	-- SquirrelSetup connects to this at load, so it has to exist in the saved place, not be made at run time
	local awardItems = RS:FindFirstChild("AwardItems")
	if not awardItems then
		awardItems = Instance.new("BindableEvent"); awardItems.Name = "AwardItems"; awardItems.Parent = RS
	end
	local buy = RS:FindFirstChild("ShopBuy")
	if not buy then buy = Instance.new("RemoteFunction"); buy.Name = "ShopBuy"; buy.Parent = RS end
	if not RS:FindFirstChild("ShopSaid") then local e = Instance.new("RemoteEvent"); e.Name = "ShopSaid"; e.Parent = RS end   -- the answer to a prompt purchase

	local F = workspace:FindFirstChild("Shop")
	if not F then F = Instance.new("Folder"); F.Name = "Shop"; F.Parent = workspace end

	-- id, what it is called, what it costs, and whether you may have more than one
	local ITEMS = {
		{id = "seed",      price = 15,  repeatable = true},
		{id = "ziphandle", price = 60,  once = true},
		{id = "bubbles",   price = 15,  repeatable = true},       -- ten minutes of your colour (30 while it was for keeps)
		{id = "binoculars",price = 0,   once = true, robux = true},   -- a Game Pass; the row prompts Robux, never acorns
		{id = "portrait",  price = 120, repeatable = true},
		{id = "slingshot", price = 45,  once = true},          -- 150 until Sep 24 2026 (Shannon: "too expensive")
		{id = "cheese",    price = 8,   repeatable = true},       -- eaten on the spot; the CheeseServer takes it from there
		{id = "backpack",  price = 900, once = true},
		{id = "zoomies",   price = 25,  repeatable = true},       -- ZoomiesMinutes of speed (Sep 25 2026, Shannon: never for good)
		{id = "glider",    price = 1000, once = true},            -- the hang glider (Sep 27 2026, Shannon: "a thousand acorns")
	}
	for _, it in ipairs(ITEMS) do
		local key = "Price_" .. it.id
		local now = F:GetAttribute(key)
		if it.robux then
			F:SetAttribute(key, nil)                                 -- no acorn price to show or to charge
		elseif opts[it.id] then
			F:SetAttribute(key, opts[it.id])
		elseif now == nil or now == 0 then
			-- A price of zero is never deliberate; it is what the mime's row was left holding from the days
			-- when he took whatever you offered and the price lived in the button instead. Filling in only
			-- MISSING prices quietly kept him free.
			F:SetAttribute(key, it.price)
		end
	end
	F:SetAttribute("TipMax", nil)                          -- nothing takes a variable amount any more
	F:SetAttribute("Price_zipticket", nil)                 -- the ticket became a handle you keep
	F:SetAttribute("Price_bubbles", 15)                    -- re-priced Sep 24 2026 with the ten-minute clock (Shannon: "more like 15")
	F:SetAttribute("Price_slingshot", 45)                  -- re-priced Sep 24 2026 (Shannon: "too expensive" at 150)
	F:SetAttribute("Sell_zoomies", true)                   -- on sale from the start (Sep 25 2026)
	F:SetAttribute("Sell_glider", true)                    -- on sale from the start (Sep 27 2026)
	F:SetAttribute("Sell_zipticket", nil)
	-- One switch per item, beside the shop-wide one: Selling puts the whole store on sale, Sell_<id> puts one
	-- finished thing on sale while the rest still say "soon". Set here so they show up in Properties.
	for _, it in ipairs(ITEMS) do
		if F:GetAttribute("Sell_" .. it.id) == nil then F:SetAttribute("Sell_" .. it.id, false) end
	end
	-- The store does not open while everything in it is inert. Selling somebody a seed packet that does
	-- nothing is worse than not selling them anything. Flip this to true the moment one item works.
	-- Open: whether the purse opens the store. Selling: whether anything in it can be bought. The shop can
	-- be looked at before it works, which is where it is now - the catalogue is worth seeing and none of it
	-- does anything yet. Flip Selling to true as each item is built.
	F:SetAttribute("Open", opts.open ~= false)
	F:SetAttribute("Selling", opts.selling == true)

	local old = F:FindFirstChild("ShopServer"); if old then old:Destroy() end
	local SRC = [==[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local buy = RS:WaitForChild("ShopBuy")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local said = RS:WaitForChild("ShopSaid")

local ITEMS = {
	seed       = {repeatable = true},
	-- the ride crosses both boundaries, so it is a reward for having earned your way there rather than a
	-- paid shortcut past the gates: the farm has to be open to you before a handle can be sold. Bought once
	-- and kept; the ride itself checks Item_ziphandle at the top of the tower.
	ziphandle  = {once = true, needsArea = "village"},
	bubbles    = {repeatable = true, palette = 6},        -- pick one of six colours; the colour is kept as Item_fountaincolour
	binoculars = {once = true, robux = true},               -- owned through the Game Pass, never bought here
	portrait   = {repeatable = true},
	slingshot  = {once = true},
	cheese     = {repeatable = true},
	backpack   = {once = true},	-- the hang glider takes off from the Sandstone Climb's summit in the Chateau, so it is sold once the Chateau is open
	-- to you (like the zipline handle); bought once and kept - the ramp checks Item_glider (workspace.HangGlider)
	glider     = {once = true, needsArea = "village"},
	zoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it
}

local busy = {}                                        -- one purchase at a time per player

local function purchase(player, id, variant)
	if typeof(id) ~= "string" then return false, "no such thing" end
	local item = ITEMS[id]
	if not item then return false, "no such thing" end

	-- Robux items are never sold for acorns, whatever a client asks for
	if item.robux then return false, "Robux only" end

	-- a colour has to be one of the palette (whether the fountain is free is checked again just before paying)
	if item.palette then
		variant = tonumber(variant)
		if not variant or variant < 1 or variant > item.palette or variant % 1 ~= 0 then return false, "pick a colour" end
	end
	-- THE FOUNTAIN IS THE WHOLE SERVER'S (Shannon, Sep 26: "when somebody turns the fountain color with bubbles, I want
	-- everybody to be able to see it ... It can only be chosen if it's not currently colored"): one colour at a time
	local function fountainTaken()
		local FC = workspace:FindFirstChild("FountainColour")
		local untilT = FC and FC:GetAttribute("ActiveUntil") or 0
		local left = untilT - workspace:GetServerTimeNow()
		if FC and (FC:GetAttribute("ActiveColour") or 0) > 0 and left > 0 then
			left = math.ceil(left)
			return string.format("the fountain is taken - free in %d:%02d", math.floor(left / 60), left % 60)
		end
		return nil
	end
	if item.palette and fountainTaken() then return false, fountainTaken() end

	-- Enforced HERE, not merely greyed out in the panel: a button that only looks disabled is one a
	-- modified client clicks anyway, and it would take the acorns.
	if F:GetAttribute("Selling") ~= true and F:GetAttribute("Sell_" .. id) ~= true then
		return false, "not on sale yet"
	end

	-- Two clicks arriving together must not spend the money twice. The flag goes up before anything is read,
	-- because the whole check-then-deduct sequence has to be indivisible.
	if busy[player] then return false, "one at a time" end
	busy[player] = true
	local ok, res, why = pcall(function()
		-- Every item has one price now. The mime used to take whatever you offered, which meant a text box, a
		-- keyboard on a phone and a way to mistype a fortune into a hat; three acorns is simply what it costs.
		local price = F:GetAttribute("Price_" .. id)
		if type(price) ~= "number" then return false, "no price set" end

		if item.once and (player:GetAttribute("Item_" .. id) or 0) > 0 then
			return false, "you already have one"
		end

		if item.needsArea then
			local B
			for _, b in ipairs(workspace:GetChildren()) do
				if b.Name == "Boundary" and b:FindFirstChild("Walls") then B = b end
			end
			local need = (B and B:GetAttribute("Need")) or 10
			if (player:GetAttribute("Found_" .. item.needsArea) or 0) < need then
				return false, string.format("find %d in the Rue first", need)
			end
		end

		-- the purse as the SERVER sees it. A client cannot change an attribute the server set, so this is the
		-- real balance rather than whatever the shop panel happens to be showing.
		local have = player:GetAttribute("Acorns") or 0
		if have < price then return false, "not enough acorns" end
		if item.palette and fountainTaken() then return false, fountainTaken() end   -- (nothing yields between here and taking it)

		awardAcorns:Fire(player, -price)               -- spending is a negative award, same ledger, same merge
		player:SetAttribute("Acorns", have - price)
		awardItems:Fire(player, id, 1)
		if item.clock then
			-- a timed thing: its clock is an item whose COUNT is the moment it runs out (server time, whole seconds),
			-- moved by a delta like everything else. Buying again while it runs adds to what is left.
			local home = workspace:FindFirstChild(item.home or "")
			local minutes = (home and home:GetAttribute(item.minutes or "")) or 10
			local cur = player:GetAttribute("Item_" .. item.clock) or 0
			local from = math.max(cur, math.floor(workspace:GetServerTimeNow()))
			awardItems:Fire(player, item.clock, from + minutes * 60 - cur)
		end
		if item.palette then
			-- the whole server's fountain runs this colour for Minutes (on workspace.FountainColour) from now: ActiveColour,
			-- ActiveUntil (server time) and ActiveBy there, which every player's FountainClient draws and the shop panel
			-- counts down; it belongs to this server (the buyer leaving doesn't stop it). Shannon: "10 minutes ... just set it".
			local FC = workspace:FindFirstChild("FountainColour")
			local minutes = (FC and FC:GetAttribute("Minutes")) or 10
			if FC then
				FC:SetAttribute("ActiveBy", player.DisplayName)
				FC:SetAttribute("ActiveUntil", math.floor(workspace:GetServerTimeNow() + minutes * 60))
				FC:SetAttribute("ActiveColour", variant)
				local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"bubbles",{colour=({"pink","orange","gold","green","blue","violet"})[variant]}) end
			end
		end
		return true, price
	end)
	busy[player] = nil
	if not ok then
		warn("ShopServer: purchase of " .. tostring(id) .. " failed - " .. tostring(res))
		return false, "something went wrong"
	end
	return res, why
end

buy.OnServerInvoke = function(player, id, variant) return purchase(player, id, variant) end

-- Some things are bought where they are, from a prompt in the world, rather than from the panel. Same
-- purchase, same checks, same ledger - only the way you ask for it differs.
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, player)
	local id = prompt:GetAttribute("ShopItem")
	if type(id) == "string" and id ~= "" then
		local ok, why = purchase(player, id)
		said:FireClient(player, id, ok, why)                -- a prompt has no panel to write on; the client toasts it
	end
end)

Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
print("ShopServer: ready")
]==]
	local s = Instance.new("Script"); s.Name = "ShopServer"; s.RunContext = Enum.RunContext.Server
	s.Source = SRC; s.Parent = F

	local shown = {}
	for _, it in ipairs(ITEMS) do
		table.insert(shown, string.format("%s %s", it.id,
			it.donation and "(you choose)" or tostring(F:GetAttribute("Price_" .. it.id))))
	end
	print("Shop: " .. table.concat(shown, ", ") .. "; prices are attributes on workspace.Shop")
end
