	canSave[uid] = not studioFullFindsPreview
	if store and not studioFullFindsPreview then
		local ok, data
		for attempt = 1, 3 do
			ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
			if ok then break end
			task.wait(1.5)
		end
		if ok then
			passportLoaded[uid]=Journal.merge(type(data)=="table" and data.passport or {},passportPending[uid] or {})
			local t = foundList(player)
			if type(data) == "table" and type(data.found) == "table" then
				for _, id in ipairs(data.found) do t[(tostring(id):gsub("_color$", ""))] = true end
			end
			if type(data) == "table" and type(data.area) == "string" then player:SetAttribute("SavedArea", data.area) end
			if type(data) == "table" and type(data.items) == "table" then
				for id, n in pairs(data.items) do
					if type(id) == "string" and tonumber(n) then
						player:SetAttribute("Item_" .. id, tonumber(n) + ((owedItems[uid] or {})[id] or 0))
					end
				end
			end
			if type(data) == "table" and tonumber(data.acorns) then
				player:SetAttribute("Acorns", tonumber(data.acorns) + (owed[uid] or 0))
			end
			print(string.format("SquirrelSetup: loaded %d saved finds for %s", count(t), player.Name))
		else
			canSave[uid] = false
			warn("SquirrelSetup: could not load finds for " .. player.Name .. " (" .. tostring(data) .. "); this session will not be saved")
		end
	end
	passportLoaded[uid]=Journal.merge(passportLoaded[uid] or {},passportPending[uid] or {})
	player:SetAttribute("PassportJournal",Http:JSONEncode(passportLoaded[uid]))
	if studioFullFindsPreview then
		local allFinds = foundList(player)
		for _, squirrel in ipairs(Registry.squirrels) do allFinds[squirrel.id] = true end
		-- StudioPortoCartUnlock: show the France/Porto cart prompts and Passport city tab.
		player:SetAttribute('Item_porto', math.max(1, tonumber(player:GetAttribute('Item_porto')) or 0))
		print('SquirrelSetup: Studio owner preview has ' .. tostring(count(allFinds)) .. ' of ' .. tostring(#Registry.squirrels) .. ' squirrels')
	end
	loaded[uid] = true
	player:SetAttribute("SaveLoaded", true)
	if player:GetAttribute("Acorns") == nil then player:SetAttribute("Acorns", 0) end
	player:SetAttribute("SquirrelsFound", count(foundList(player)))
	publishCounts(player)
end
local function savePlayer(player)
	local uid = player.UserId
	if not store or not canSave[uid] or not loaded[uid] then return end
	local list = {}
	for id in pairs(foundList(player)) do table.insert(list, id) end
	local movedPassport=Journal.merge(passportPending[uid] or {},{})
	local gain = owed[uid] or 0                                   -- captured BEFORE the call: UpdateAsync can
	local movedItems = {}                                         -- likewise, a snapshot of the item deltas
	for id, d in pairs(owedItems[uid] or {}) do movedItems[id] = d end
	local ok, err = pcall(function()                              -- re-run its callback, and more can be earned
		store:UpdateAsync("u" .. uid, function(old)                -- while it is in flight
			-- merge with whatever is already saved, so two servers never erase each other's finds
			local merged = {}
			if type(old) == "table" and type(old.found) == "table" then for _, id in ipairs(old.found) do merged[id] = true end end
			for _, id in ipairs(list) do merged[id] = true end
			local out = {}
			for id in pairs(merged) do table.insert(out, id) end
			local area = player:GetAttribute("Dais") or player:GetAttribute("SavedArea") or player:GetAttribute("Area") or (type(old) == "table" and old.area) or nil   -- the last dais touched (Oct 4 2026)
			-- acorns are a purse, not a set: add what was earned to what is there rather than replacing it
			local acorns = ((type(old) == "table" and tonumber(old.acorns)) or 0) + gain
			-- the same treatment for owned things: add what changed, never replace the list
			local items = {}
			if type(old) == "table" and type(old.items) == "table" then
				for id, n in pairs(old.items) do items[id] = tonumber(n) or 0 end
			end
			for id, d in pairs(movedItems) do
				local n = (items[id] or 0) + d
				items[id] = n > 0 and n or nil                    -- a count of zero is simply not owned
			end
			return {found = out, area = area, acorns = acorns, items = items, passport=Journal.merge(type(old)=="table" and old.passport or {},movedPassport), updated = os.time()}
		end)
	end)
	if ok then
		dirty[uid] = nil
		for id,record in pairs(movedPassport) do
		 if passportPending[uid] and passportPending[uid][id] and passportPending[uid][id].at==record.at then passportPending[uid][id]=nil end
		end
		if next(passportPending[uid] or {}) then dirty[uid]=true end
		owed[uid] = (owed[uid] or 0) - gain                        -- only what actually went in, never more
		local pend = owedItems[uid]
		if pend then
			for id, d in pairs(movedItems) do
				local left = (pend[id] or 0) - d
				pend[id] = left ~= 0 and left or nil
			end
		end
	else
		warn("SquirrelSetup: save failed for " .. player.Name .. ": " .. tostring(err))
	end
end
-- The acorn server never touches the DataStore. It fires this, and the one script that owns the key writes it.
local awardEv = game:GetService("ReplicatedStorage"):FindFirstChild("AwardAcorns")
if awardEv and awardEv:IsA("BindableEvent") then
	awardEv.Event:Connect(function(player, n)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		n = tonumber(n) or 0
		if n == 0 then return end
		owed[player.UserId] = (owed[player.UserId] or 0) + n
		dirty[player.UserId] = true
	end)
end
-- Granting or taking away an item. The shop never touches the DataStore; it fires this, and the one script
-- that owns the key records it. A negative n is how something is consumed.
local itemEv = game:GetService("ReplicatedStorage"):FindFirstChild("AwardItems")
if itemEv and itemEv:IsA("BindableEvent") then
	itemEv.Event:Connect(function(player, id, n)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
		if type(id) ~= "string" or id == "" then return end
		n = tonumber(n) or 0
		if n == 0 then return end
		local uid = player.UserId
		owedItems[uid] = owedItems[uid] or {}
		owedItems[uid][id] = (owedItems[uid][id] or 0) + n
		local have = (player:GetAttribute("Item_" .. id) or 0) + n
		player:SetAttribute("Item_" .. id, have > 0 and have or 0)
		dirty[uid] = true
	end)
end
local passportSave=ReplicatedStorage:WaitForChild("PassportSave")
passportSave.Event:Connect(function(player,id,record)
 if typeof(player)~="Instance" or not player:IsA("Player") then return end
 local clean=Journal.clean(id,record);if not clean then return end
 local uid=player.UserId
 passportPending[uid]=Journal.merge(passportPending[uid] or {},{[id]=clean})
 passportLoaded[uid]=Journal.merge(passportLoaded[uid] or {},{[id]=clean})