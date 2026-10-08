
-- SquirrelSetup (server)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = script.Parent

local function isSquirrelMesh(p)
	return p:IsA("MeshPart") and p:FindFirstChild("Tail2", true) ~= nil and p:FindFirstChild("Root", true) ~= nil
end
local function getTex(mesh)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then return sa.ColorMap end
	return mesh.TextureID
end
local function setTex(mesh, id)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then sa.ColorMap = id else mesh.TextureID = id end
end

if folder:GetAttribute("FoundSound") == nil then folder:SetAttribute("FoundSound", "rbxassetid://1845415163") end
if folder:GetAttribute("NameTagSeconds") == nil then folder:SetAttribute("NameTagSeconds", 3.2) end
if folder:GetAttribute("MaskImage") == nil then folder:SetAttribute("MaskImage", "rbxassetid://77268792392056") end   -- white square, transparent circle
local PER_PLAYER = folder:GetAttribute("PerPlayer")
if PER_PLAYER == nil then PER_PLAYER = true; folder:SetAttribute("PerPlayer", true) end
local TARGET_HEIGHT = folder:GetAttribute("TargetHeight") or 2.9      -- studs tall; the meshes come in at 2.4
folder:SetAttribute("TargetHeight", TARGET_HEIGHT)

local ev = ReplicatedStorage:FindFirstChild("SquirrelFound") or Instance.new("RemoteEvent")
ev.Name = "SquirrelFound"; ev.Parent = ReplicatedStorage
local sync = ReplicatedStorage:FindFirstChild("SquirrelSync") or Instance.new("RemoteFunction")
sync.Name = "SquirrelSync"; sync.Parent = ReplicatedStorage

-- 1. collect every squirrel mesh in the Workspace
local meshes = {}
for _, p in ipairs(workspace:GetDescendants()) do if isSquirrelMesh(p) then table.insert(meshes, p) end end
local function modelOf(mesh) return mesh:FindFirstAncestorOfClass("Model") or mesh end
local function baseName(inst)
	local n = string.lower(modelOf(inst).Name .. " " .. inst.Name)
	n = n:gsub("_gray", ""):gsub("gray", ""):gsub("_color", ""):gsub("color", ""):gsub("%s+", " ")
	return n
end
local function isGray(inst) return string.find(string.lower(modelOf(inst).Name .. " " .. inst.Name), "gray") ~= nil end

-- 2. pair colour + gray by base name (fallback: identical mesh size)
local grays, colours = {}, {}
for _, mesh in ipairs(meshes) do
	if mesh:GetAttribute("GrayTexture") then table.insert(colours, mesh)          -- already set up (saved place)
	elseif isGray(mesh) then table.insert(grays, mesh) else table.insert(colours, mesh) end
end
for _, c in ipairs(colours) do
	if not c:GetAttribute("GrayTexture") then
		local twin
		for i, g in ipairs(grays) do
			if baseName(g) == baseName(c) then twin = g; table.remove(grays, i); break end
		end
		if not twin then
			for i, g in ipairs(grays) do
				if (g.Size - c.Size).Magnitude < 0.01 * c.Size.Magnitude then twin = g; table.remove(grays, i); break end
			end
		end
		if twin then
			c:SetAttribute("GrayTexture", getTex(twin)); c:SetAttribute("ColorTexture", getTex(c))
			modelOf(twin).Parent = nil
			print("SquirrelSetup: paired", modelOf(c):GetFullName(), "with its gray twin")
		else
			c:SetAttribute("ColorTexture", getTex(c))
			warn("SquirrelSetup: no gray twin found for " .. modelOf(c):GetFullName() .. " (import the _gray FBX too, name must contain 'gray'); it will start in colour")
		end
	end
end
for _, g in ipairs(grays) do warn("SquirrelSetup: unpaired gray squirrel " .. modelOf(g):GetFullName()) end

-- display names (shown on the floating tag when found); matched against the model name, first hit wins.
-- Set a DisplayName attribute on a squirrel model to override.
-- the registry: names, bios, maps, framing. Edit SquirrelRegistry, not this script.
local Registry = require(folder:WaitForChild("SquirrelRegistry"))
local byId = {}
for _, e in ipairs(Registry.squirrels) do byId[e.id] = e end
local THIS_MAP = folder:GetAttribute("MapId") or "forest"
folder:SetAttribute("MapId", THIS_MAP)
local function baseId(model)
	local n = model.Name:lower():gsub("_color$", ""):gsub("_gray$", "")
	return n
end
-- 3. set each one up
local squirrels = {}     -- id -> mesh
local function setup(mesh)
	local model = modelOf(mesh)
	local entry = byId[baseId(model)]
	if entry then
		model:SetAttribute("SquirrelId", entry.id)
		if not model:GetAttribute("DisplayName") then model:SetAttribute("DisplayName", entry.name) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", entry.bio or "") end
	else
		warn("SquirrelSetup: " .. model.Name .. " is not in SquirrelRegistry; add it there (id = '" .. baseId(model) .. "')")
		if not model:GetAttribute("SquirrelId") then model:SetAttribute("SquirrelId", baseId(model)) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", "A squirrel of mystery. Nobody knows where they came from, least of all them.") end
	end
	if model == mesh then     -- bare MeshPart: wrap it so ScaleTo / PivotTo work
		local wrap = Instance.new("Model"); wrap.Name = mesh.Name; wrap.Parent = mesh.Parent; mesh.Parent = wrap; model = wrap
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = true; p.CanTouch = true end
	end
	model.PrimaryPart = model.PrimaryPart or mesh
	-- scale to TargetHeight, keeping the feet where they are
	local targetH = model:GetAttribute("TargetHeight") or TARGET_HEIGHT   -- a squirrel whose prop sticks up (the kite) sets its own
	if math.abs(mesh.Size.Y - targetH) > 0.02 then
		local cf0, sz0 = model:GetBoundingBox()
		local bottom = cf0.Position.Y - sz0.Y / 2
		model:ScaleTo(model:GetScale() * targetH / mesh.Size.Y)
		local cf1, sz1 = model:GetBoundingBox()
		model:PivotTo(model:GetPivot() + Vector3.new(cf0.Position.X - cf1.Position.X, bottom - (cf1.Position.Y - sz1.Y / 2), cf0.Position.Z - cf1.Position.Z))
	end
	local id = model:GetAttribute("SquirrelId")
	if not id or squirrels[id] then
		id = baseId(model); local k = 1
		while squirrels[id] do k += 1; id = baseId(model) .. "_" .. k end
		model:SetAttribute("SquirrelId", id)
	end
	squirrels[id] = mesh
	CollectionService:AddTag(model, "Squirrel")
	if not PER_PLAYER then
		local gray = mesh:GetAttribute("GrayTexture")
		if gray and not model:GetAttribute("Found") then setTex(mesh, gray) end
		if model:GetAttribute("Found") == nil then model:SetAttribute("Found", false) end
	end
	return model, id
end
local total = 0
for _, mesh in ipairs(colours) do setup(mesh); total += 1 end
folder:SetAttribute("Total", total)
local mapTotal = 0
for _, e in ipairs(Registry.squirrels) do if e.map == THIS_MAP then mapTotal += 1 end end
folder:SetAttribute("MapTotal", mapTotal); folder:SetAttribute("AllTotal", #Registry.squirrels)
print(string.format("SquirrelSetup: %d squirrels ready (%s)", total, PER_PLAYER and "per-player finds" or "shared finds"))

-- 4. finds, saved per player in a DataStore so they survive leaving and rejoining
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local USE_STORE = folder:GetAttribute("UseDataStore")
if USE_STORE == nil then USE_STORE = true; folder:SetAttribute("UseDataStore", true) end
local STORE_KEY = folder:GetAttribute("SaveKey") or "SquirrelFinds_v1"
folder:SetAttribute("SaveKey", STORE_KEY)
local store
if USE_STORE and PER_PLAYER then
	local ok, err = pcall(function() store = DataStoreService:GetDataStore(STORE_KEY) end)
	if not ok then warn("SquirrelSetup: DataStore unavailable, finds will not be saved: " .. tostring(err)); store = nil end
end
local found = {}          -- userId -> { [id] = true }
local loaded = {}         -- userId -> true once the DataStore load finished (or was skipped)
local canSave = {}        -- userId -> false when the load failed (never overwrite good data with an empty list)
local dirty = {}          -- userId -> true when there is something new to save
local Journal=require(workspace:WaitForChild("Passport"):WaitForChild("Journal"))
local Http=game:GetService("HttpService")
local passportPending={}
local passportLoaded={}
local owedItems = {}      -- userId -> {itemId = delta}; same reasoning as the purse below, per item
local owed = {}           -- userId -> acorns earned but not yet written, applied as a DELTA so that two
                          -- servers adding to the same purse cannot overwrite one another
local function foundList(player)
	local t = found[player.UserId]
	if not t then t = {}; found[player.UserId] = t end
	return t
end
local function count(t) local n = 0 for _ in pairs(t) do n += 1 end return n end
local function publishCounts(player)
	local t = foundList(player)
	local per = {}
	for _, e in ipairs(Registry.squirrels) do if t[e.id] then per[e.map] = (per[e.map] or 0) + 1 end end
	for _, m in ipairs(Registry.maps) do player:SetAttribute("Found_" .. m.id, per[m.id] or 0) end
	local ids = {}
	for id in pairs(t) do table.insert(ids, id) end
	table.sort(ids)
	player:SetAttribute("FoundIds", table.concat(ids, ","))
end
local function loadPlayer(player)
	local uid = player.UserId
	canSave[uid] = true
	if store then
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
			local area = player:GetAttribute("Area") or (type(old) == "table" and old.area) or nil
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
 player:SetAttribute("PassportJournal",Http:JSONEncode(passportLoaded[uid]))
 dirty[uid]=true
end)
Players.PlayerAdded:Connect(loadPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadPlayer, player) end
Players.PlayerRemoving:Connect(function(player)
	if dirty[player.UserId] then savePlayer(player) end
	task.delay(5, function()
		local uid = player.UserId
		found[uid] = nil; loaded[uid] = nil; canSave[uid] = nil; dirty[uid] = nil
		owed[uid] = nil; owedItems[uid] = nil;passportPending[uid]=nil;passportLoaded[uid]=nil
	end)
end)
-- save anything new every few seconds rather than on every single click
task.spawn(function()
	while true do
		task.wait(8)
		for _, player in ipairs(Players:GetPlayers()) do if dirty[player.UserId] then savePlayer(player) end end
	end
end)
game:BindToClose(function()
	if not store then return end
	for _, player in ipairs(Players:GetPlayers()) do if dirty[player.UserId] then savePlayer(player) end end
end)
sync.OnServerInvoke = function(player)
	local list = {}
	if PER_PLAYER then
		local waited = 0
		while not loaded[player.UserId] and waited < 15 do task.wait(0.25); waited += 0.25 end
		for id in pairs(foundList(player)) do table.insert(list, id) end
	else
		for id, mesh in pairs(squirrels) do if modelOf(mesh):GetAttribute("Found") then table.insert(list, id) end end
	end
	return list
end
local function onFound(player, model, id, mesh)
 local char=player and player.Character;local hrp=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not hrp or not hum or hum.Health<=0 or not loaded[player.UserId] or (hrp.Position-mesh.Position).Magnitude>(folder:GetAttribute("ClickDistance") or 32)+mesh.Size.Magnitude/2 then return end
	if PER_PLAYER then
		local t = foundList(player)
		if t[id] then return end
		t[id] = true
		dirty[player.UserId] = true
		player:SetAttribute("SquirrelsFound", count(t))
		publishCounts(player)
		ev:FireClient(player, id)                      -- only this player sees it turn to colour
	else
		if model:GetAttribute("Found") then return end
		model:SetAttribute("Found", true)
		setTex(mesh, mesh:GetAttribute("ColorTexture"))
		local n = 0
		for _, m2 in pairs(squirrels) do if modelOf(m2):GetAttribute("Found") then n += 1 end end
		folder:SetAttribute("FoundCount", n)
		ev:FireAllClients(id, player)                  -- everyone sees the reveal
	end
 local e=byId[id];local area=e and e.map or "forest"
 local areas={forest="Great Acorn Forest",village="Rue de Noisette",domaine="Château de l'Acorn"}
 local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"find",{name=model:GetAttribute("DisplayName") or (e and e.name) or id,area=areas[area] or area}) end
	print(string.format("SquirrelSetup: %s found %s", player.Name, id))
end
-- FindBy attribute on the folder: "click" (default), "touch", or "both"
local FIND_BY = folder:GetAttribute("FindBy")
if FIND_BY == nil then FIND_BY = "both"; folder:SetAttribute("FindBy", "both") end
local CLICK_DIST = folder:GetAttribute("ClickDistance") or 32
folder:SetAttribute("ClickDistance", CLICK_DIST)
for id, mesh in pairs(squirrels) do
	local model = modelOf(mesh)
	if FIND_BY == "click" or FIND_BY == "both" then
		for _, old in ipairs(mesh:GetChildren()) do if old:IsA("ClickDetector") then old:Destroy() end end
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = CLICK_DIST
		-- Cursor attribute on the folder: "hand" (Roblox's pointing-hand default), "arrow" (no change), or an asset id
		local cur = folder:GetAttribute("Cursor") or "hand"
		folder:SetAttribute("Cursor", cur)
		if cur == "arrow" then cd.CursorIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
		elseif cur ~= "hand" and cur ~= "" then cd.CursorIcon = cur end
		cd.Parent = mesh
		cd.MouseClick:Connect(function(player) onFound(player, model, id, mesh) end)
	end
	if FIND_BY == "touch" or FIND_BY == "both" then
		local debounce = {}
		mesh.Touched:Connect(function(hit)
			local char = hit:FindFirstAncestorOfClass("Model")
			local player = char and Players:GetPlayerFromCharacter(char)
			if not player then return end
			if debounce[player] and os.clock() - debounce[player] < 1 then return end
			debounce[player] = os.clock()
			onFound(player, model, id, mesh)
		end)
	end
end

-- ---- reset: wipe this player's finds on request (the "Reset progress" button asks twice before sending it) ----
local resetEv = ReplicatedStorage:FindFirstChild("SquirrelReset") or Instance.new("RemoteEvent")
resetEv.Name = "SquirrelReset"; resetEv.Parent = ReplicatedStorage
local resetAt = {}
resetEv.OnServerEvent:Connect(function(player)
	local uid = player.UserId
	if os.clock() - (resetAt[uid] or -60) < 5 then return end          -- one wipe at a time
	resetAt[uid] = os.clock()
	found[uid] = {}
	dirty[uid] = nil
	if store and canSave[uid] then
		local ok, err = pcall(function()
			-- a true wipe of the FINDS, not a merge - but the purse survives it. Resetting which squirrels you
			-- have found is not a reason to take away acorns that were earned separately.
			store:UpdateAsync("u" .. uid, function(old)
				return {found = {}, acorns = (type(old) == "table" and tonumber(old.acorns)) or 0, items=type(old)=="table" and old.items or {}, passport=Journal.merge(type(old)=="table" and old.passport or {},passportPending[uid] or {}), updated = os.time()}
			end)
		end)
		if not ok then warn("SquirrelSetup: reset save failed for " .. player.Name .. ": " .. tostring(err)) end
	end
	player:SetAttribute("SquirrelsFound", 0)
	publishCounts(player)
	resetEv:FireClient(player)
	print("SquirrelSetup: " .. player.Name .. " reset their progress")
end)

-- ---- the section a player was last in: SpawnReturn sets the attribute, this saves it with the next batch ----
local function watchArea(player)
	player:GetAttributeChangedSignal("Area"):Connect(function()
		if loaded[player.UserId] and player:GetAttribute("Area") ~= player:GetAttribute("SavedArea") then
			dirty[player.UserId] = true                     -- landing back in the section they left is not a change
		end
	end)
end
Players.PlayerAdded:Connect(watchArea)
for _, player in ipairs(Players:GetPlayers()) do watchArea(player) end
