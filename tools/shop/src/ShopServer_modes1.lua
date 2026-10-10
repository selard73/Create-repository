local Players = game:GetService("Players")
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
	crabtrap   = {once = true},                           -- Oct 4 2026: the crab game at Porto Nocciola (workspace.CrabGame)
	camera     = {once = true},                           -- Oct 8 2026: the postcard camera (workspace.PhotoGame)
	zoomies    = {repeatable = true, clock = "zoomiesuntil", home = "Speed", minutes = "ZoomiesMinutes"},   -- a stretch of speed; buying again adds to it
	-- Oct 10 2026: the Fontana del Limone's modes (workspace.FountainModes): the whole server's fountain for Minutes, one mode at a time
	spaghetti  = {repeatable = true, mode = "spaghetti"},
	frogs      = {repeatable = true, mode = "frogs"},
	petals     = {repeatable = true, mode = "petals"},
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
	-- the Fontana del Limone likewise runs one bought mode at a time (workspace.FountainModes)
	local function modeTaken()
		local FM = workspace:FindFirstChild("FountainModes")
		local untilT = FM and FM:GetAttribute("ActiveUntil") or 0
		local left = untilT - workspace:GetServerTimeNow()
		if FM and (FM:GetAttribute("ActiveMode") or "") ~= "" and left > 0 then
			left = math.ceil(left)
			return string.format("the fountain is busy - free in %d:%02d", math.floor(left / 60), left % 60)
		end
		return nil
	end
	if item.mode and modeTaken() then return false, modeTaken() end

	-- Enforced HERE, not merely greyed out in the panel: a button that only looks disabled is one a
	-- modified client clicks anyway, and it would take the acorns.
	if F:GetAttribute("Selling") ~= true and F:GetAttribute("Sell_" .. id) ~= true then
		return false, "not on sale yet"
	end

	-- Two clicks arriving together must not spend the money twice. The flag goes up before anything is read,
	-- because the whole check-then-deduct sequence has to be indivisible.
	if busy[player] then return false, "one at a time" end
	busy[player] = true
	local portraitReservation
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
		if item.mode and modeTaken() then return false, modeTaken() end

		if id=="portrait" then
			local gallery=workspace:FindFirstChild("PortraitGallery")
			local chair=gallery and gallery:FindFirstChild("SitterChair")
			local seat=chair and chair:FindFirstChild("PortraitSeat")
			if not player:GetAttribute("SaveLoaded")then return false,"your progress is still loading"end
			local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health<=0 then return false,"try again when your character is ready"end
			if not gallery or not gallery:GetAttribute("PortraitReady") or not seat then return false,"the painter is getting ready"end
			if gallery:GetAttribute("SessionUser") or seat.Occupant then return false,"the painter is finishing another portrait; try again shortly"end
			local need=(workspace:FindFirstChild("Boundary") and workspace.Boundary:GetAttribute("Need"))or 10
			if (player:GetAttribute("Found_forest")or 0)<need then return false,"unlock the Rue to visit the painter"end
			local prepare=gallery:FindFirstChild("PortraitPrepare")
			if not prepare or not prepare:IsA("BindableFunction")then return false,"the painter is getting ready"end
			gallery:SetAttribute("SessionUser",player.UserId)
			portraitReservation=prepare
			local ready,message=prepare:Invoke(player,"prepare")
			if not ready then return false,message end
			-- Preparing assets and reserving their save can yield; check the purse again.
			have=player:GetAttribute("Acorns")or 0
			if have<price then return false,"not enough acorns"end
			if not player.Parent then return false,"player left"end
		end
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
		if item.mode then
			-- the Fontana del Limone runs this mode for Minutes (workspace.FountainModes): ActiveMode, ActiveUntil (server time), ActiveBy
			local FM = workspace:FindFirstChild("FountainModes")
			local minutes = (FM and FM:GetAttribute("Minutes")) or 10
			if FM then FM:SetAttribute("ActiveBy", player.DisplayName); FM:SetAttribute("ActiveUntil", math.floor(workspace:GetServerTimeNow() + minutes * 60)); FM:SetAttribute("ActiveMode", item.mode) end
		end
		return true, price
	end)
	if portraitReservation and (not ok or res~=true)then pcall(function()portraitReservation:Invoke(player,"cancel")end)end
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
