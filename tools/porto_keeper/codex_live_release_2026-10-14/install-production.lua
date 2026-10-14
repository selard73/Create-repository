local rows={{name="SquirrelSetup",path="Workspace.SquirrelScripts.SquirrelSetup",before=[====[-- SquirrelSetup (server)
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
	if mesh:GetAttribute("GrayTexture") and not isGray(mesh) then table.insert(colours, mesh)          -- already set up (saved place)
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
		-- Oct 7 2026: a world-aligned box of the parts (GetBoundingBox follows the pivot's axes, turned on imported squirrels, so
		-- they sank 0.15-0.2 studs: Shannon saw the keeper's feet in the lighthouse's stone)
		local function worldBox(m)
			local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
			for _, p in ipairs(m:GetDescendants()) do
				if p:IsA("BasePart") then
					local cf, s = p.CFrame, p.Size / 2
					local e = Vector3.new(
						math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
						math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
						math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z)
					lo = lo:Min(cf.Position - e) hi = hi:Max(cf.Position + e)
				end
			end
			return lo, hi
		end
		local lo0, hi0 = worldBox(model)
		model:ScaleTo(model:GetScale() * targetH / mesh.Size.Y)
		local lo1, hi1 = worldBox(model)
		local c0, c1 = (lo0 + hi0) / 2, (lo1 + hi1) / 2
		model:PivotTo(model:GetPivot() + Vector3.new(c0.X - c1.X, lo0.Y - lo1.Y, c0.Z - c1.Z))
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
local FindsEpoch = require(script.Parent:WaitForChild("FindsEpoch"))
local findEpoch, findRevision, saving, resetting = {}, {}, {}, {}
local sessionPlayer, loading, leaving = {}, {}, {}
local italyAdditions, italyConfirmed, italyAcks = {}, {}, {}
local collectedEv = ReplicatedStorage:FindFirstChild("SquirrelCollectedServer") or Instance.new("BindableEvent")
assert(collectedEv:IsA("BindableEvent"), "SquirrelCollectedServer must be server-only")
collectedEv.Name = "SquirrelCollectedServer"; collectedEv.Parent = ReplicatedStorage
local dirty = {}          -- userId -> true when there is something new to save
local Journal=require(workspace:WaitForChild("Passport"):WaitForChild("Journal"))
local Http=game:GetService("HttpService")
local passportPending={}
local passportLoaded={}
local owedItems = {}      -- userId -> {itemId = delta}; same reasoning as the purse below, per item
local owed = {}           -- userId -> acorns earned but not yet written, applied as a DELTA so that two
                          -- servers adding to the same purse cannot overwrite one another
-- Italy durable completion helpers: only confirmed saved intents can be replayed.
local function pendingItaly(player)
    local uid=player.UserId
    if sessionPlayer[uid]~=player or not canSave[uid] then return {} end
    return FindsEpoch.pending(italyConfirmed[uid],uid,findEpoch[uid] or 0,italyAcks[uid])
end
local function emitItaly(player)
    local attempts=pendingItaly(player)
    if #attempts>0 then collectedEv:Fire(player,attempts) end
end
local function acknowledgeItaly(player,claimId)
    local uid=player.UserId
    if sessionPlayer[uid]~=player or type(claimId)~="string" then return end
    for _,rec in ipairs(pendingItaly(player)) do
        if rec.claimId==claimId then
            italyAcks[uid]=italyAcks[uid] or {};italyAcks[uid][claimId]=true;dirty[uid]=true;return
        end
    end
end
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
    local deadline = os.clock() + 60
    while (saving[uid] or resetting[uid] or leaving[uid] or loading[uid]) and os.clock() < deadline do task.wait(0.1) end
    if saving[uid] or resetting[uid] or leaving[uid] or loading[uid] or player.Parent ~= Players then
        warn("SquirrelSetup: previous session still busy; rejoin required"); return
    end
    local previousSession = sessionPlayer[uid]
    sessionPlayer[uid], loading[uid] = player, true
    found[uid], loaded[uid], dirty[uid] = {}, false, nil
    if previousSession and previousSession ~= player then
        owed[uid], owedItems[uid], passportPending[uid], passportLoaded[uid] = nil, nil, nil, nil
    end
    findEpoch[uid], findRevision[uid] = 0, 0
    italyAdditions[uid], italyConfirmed[uid], italyAcks[uid] = {}, {}, {}
	local studioFullFindsPreview = RunService:IsStudio() and uid == 9611145467
	canSave[uid] = not studioFullFindsPreview
	if store and not studioFullFindsPreview then
		local ok, data
		for attempt = 1, 3 do
			ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
			if ok then break end
			task.wait(1.5)
		end
        if sessionPlayer[uid] ~= player or player.Parent ~= Players then loading[uid]=nil; return end
        if ok then
            local valid, epoch = pcall(FindsEpoch.read, data)
            if valid then findEpoch[uid] = epoch; italyConfirmed[uid] = type(data)=="table" and FindsEpoch.copy(data.italyAttempts or {}) or {} else canSave[uid] = false; warn("SquirrelSetup: invalid reset generation; saving and daily awards disabled") end
			passportLoaded[uid]=Journal.merge(type(data)=="table" and data.passport or {},passportPending[uid] or {})
			local t = foundList(player)
			if type(data) == "table" and type(data.found) == "table" then
				for _, id in ipairs(data.found) do
					local sid = (tostring(id):gsub("_color$", ""))
					if not byId[sid] then local base = sid:match("^(.-)_%d+$") if base and byId[base] then sid = base end end   -- Oct 7 2026: "pogo_squirrel_2" finds (twin mix-up) count as pogo_squirrel
					t[sid] = true
				end
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
		-- Oct 8 2026: workspace.PortoGates.StudioFreshPorto (Studio only) = play Porto through from the start: France found, Porto not
		local pgFresh = workspace:FindFirstChild("PortoGates") and workspace.PortoGates:GetAttribute("StudioFreshPorto")
		for _, squirrel in ipairs(Registry.squirrels) do
			if not (pgFresh and squirrel.map == "porto") then allFinds[squirrel.id] = true end
		end
		-- StudioPortoCartUnlock: show the France/Porto cart prompts and Passport city tab.
		player:SetAttribute('Item_porto', math.max(1, tonumber(player:GetAttribute('Item_porto')) or 0))
		print('SquirrelSetup: Studio owner preview has ' .. tostring(count(allFinds)) .. ' of ' .. tostring(#Registry.squirrels) .. ' squirrels')
	end
	loading[uid] = nil
	loaded[uid] = true
	player:SetAttribute("SaveLoaded", true)
	if player:GetAttribute("Acorns") == nil then player:SetAttribute("Acorns", 0) end
	player:SetAttribute("SquirrelsFound", count(foundList(player)))
	publishCounts(player)
    emitItaly(player)
end
local function savePlayer(player)
	local uid = player.UserId
	if not store or not canSave[uid] or not loaded[uid] or saving[uid] or resetting[uid] or sessionPlayer[uid] ~= player then return false end
    saving[uid] = true
    local epoch, revision, stale = findEpoch[uid] or 0, findRevision[uid] or 0, false
    local movedItaly, movedAcks = FindsEpoch.copy(italyAdditions[uid] or {}), FindsEpoch.copy(italyAcks[uid] or {})
	local list = {}
	for id in pairs(foundList(player)) do table.insert(list, id) end
	local movedPassport=Journal.merge(passportPending[uid] or {},{})
	local gain = owed[uid] or 0                                   -- captured BEFORE the call: UpdateAsync can
	local movedItems = {}                                         -- likewise, a snapshot of the item deltas
	for id, d in pairs(owedItems[uid] or {}) do movedItems[id] = d end
	local ok, err = pcall(function()                              -- re-run its callback, and more can be earned
		return store:UpdateAsync("u" .. uid, function(old)                -- while it is in flight
            stale = FindsEpoch.read(old) ~= epoch
            if stale then return nil end
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
			return FindsEpoch.write(old, epoch, {found = out, area = area, acorns = acorns, items = items, italyAttempts=FindsEpoch.mergeAttempts(type(old)=="table" and old.italyAttempts, movedItaly, movedAcks), passport=Journal.merge(type(old)=="table" and old.passport or {},movedPassport), updated = os.time()})
		end)
	end)
    saving[uid] = nil
    if stale then
        canSave[uid] = false
        warn("SquirrelSetup: newer reset detected; stale session cannot save or compete; rejoin required")
        return
    end
	if ok then
        italyConfirmed[uid] = type(err)=="table" and FindsEpoch.copy(err.italyAttempts or {}) or {}
        for key,rec in pairs(movedItaly) do
            if italyAdditions[uid] and italyAdditions[uid][key] and italyAdditions[uid][key].claimId==rec.claimId then italyAdditions[uid][key]=nil end
        end
        for id in pairs(movedAcks) do if italyAcks[uid] then italyAcks[uid][id]=nil end end
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
        if (findRevision[uid] or 0) ~= revision or (owed[uid] or 0) ~= 0 or next(owedItems[uid] or {}) or next(italyAdditions[uid] or {}) or next(italyAcks[uid] or {}) then dirty[uid] = true end
        emitItaly(player)
	else
		warn("SquirrelSetup: save failed for " .. player.Name .. ": " .. tostring(err))
	end
    return ok and not stale
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
    local uid = player.UserId
    if sessionPlayer[uid] ~= player then return end
    leaving[uid] = true
    local deadline = os.clock() + 60
    while (saving[uid] or resetting[uid] or loading[uid]) and os.clock() < deadline do task.wait(0.1) end
	if dirty[uid] then savePlayer(player) end
    leaving[uid] = nil
	task.delay(5, function()
		local uid = player.UserId
		if Players:GetPlayerByUserId(uid) then return end   -- Oct 8 2026: back in this server already - keep the new load
		if sessionPlayer[uid] ~= player or saving[uid] or resetting[uid] or loading[uid] then return end
		italyAdditions[uid]=nil;italyConfirmed[uid]=nil;italyAcks[uid]=nil
		sessionPlayer[uid]=nil; findEpoch[uid]=nil; findRevision[uid]=nil; saving[uid]=nil; resetting[uid]=nil
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
 if not hrp or not hum or hum.Health<=0 or not loaded[player.UserId] or resetting[player.UserId] or leaving[player.UserId] or sessionPlayer[player.UserId] ~= player or (hrp.Position-mesh.Position).Magnitude>(folder:GetAttribute("ClickDistance") or 32)+mesh.Size.Magnitude/2 then return end
	if PER_PLAYER then
		local t = foundList(player)
		if t[id] then return end
		t[id] = true
        findRevision[player.UserId] = (findRevision[player.UserId] or 0) + 1
		dirty[player.UserId] = true
		player:SetAttribute("SquirrelsFound", count(t))
		publishCounts(player)
        local entry = byId[id]
        if canSave[player.UserId] and store and entry and entry.map == "porto" and player:GetAttribute("Found_porto") == 44 then
            local uid, epoch, at = player.UserId, findEpoch[player.UserId] or 0, os.time()
            local daily=workspace:FindFirstChild("Daily")
            local offset=daily and daily:GetAttribute("DayOffsetHours") or 9
            italyAdditions[uid]=italyAdditions[uid] or {}
            italyAdditions[uid][tostring(epoch)]=FindsEpoch.newAttempt(uid,player.DisplayName,player.Name,epoch,at,offset,Http:GenerateGUID(false))
            -- No yield occurs between recording the 44th find and staging this intent.
            -- The next save writes BOTH in the same player-key UpdateAsync transaction.
            task.spawn(function()
                local deadline = os.clock() + 45
                while saving[uid] and os.clock() < deadline do task.wait(0.1) end
                if resetting[uid] or findEpoch[uid] ~= epoch or sessionPlayer[uid] ~= player or not canSave[uid] then return end
                -- savePlayer emits only the intents returned by the confirmed datastore save.
                -- Lost responses leave the outbox durable for a later save or rejoin to recover.
                if not savePlayer(player) then warn("SquirrelSetup: Italy completion save pending; daily attempt will recover after persistence") end
            end)
        end
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

-- Oct 8 2026 (Ethan could not collect any squirrels in Porto): Roblox ignores ClickDetectors while a Tool is held - the
-- slingshot, the crab trap, the camera - so SquirrelToolClick (client, in this folder) passes such a click on here, and
-- onFound makes exactly the checks a normal click gets (alive, loaded, close enough, not found yet).
local toolClick = ReplicatedStorage:FindFirstChild("SquirrelClick") or Instance.new("RemoteEvent")
toolClick.Name = "SquirrelClick"; toolClick.Parent = ReplicatedStorage
toolClick.OnServerEvent:Connect(function(player, id)
	if type(id) ~= "string" then return end
	local mesh = squirrels[id]
	if mesh then onFound(player, modelOf(mesh), id, mesh) end
end)

-- ---- reset: wipe this player's finds on request (the "Reset progress" button asks twice before sending it) ----
local resetEv = ReplicatedStorage:FindFirstChild("SquirrelReset") or Instance.new("RemoteEvent")
resetEv.Name = "SquirrelReset"; resetEv.Parent = ReplicatedStorage
local resetAt = {}
resetEv.OnServerEvent:Connect(function(player)
    local uid = player.UserId
    if not loaded[uid] or resetting[uid] or leaving[uid] or sessionPlayer[uid] ~= player or os.clock() - (resetAt[uid] or -60) < 5 then return end
    if not store or not canSave[uid] then warn("SquirrelSetup: reset refused because this save is unavailable"); return end
    resetAt[uid], resetting[uid] = os.clock(), true
    local deadline = os.clock() + 45
    while saving[uid] and os.clock() < deadline do task.wait(0.1) end
    if saving[uid] then resetting[uid]=nil; warn("SquirrelSetup: reset timed out waiting for save"); return end
    local expected, token = findEpoch[uid] or 0, Http:GenerateGUID(false)
    local saved, lastError
    for attempt = 1, 3 do
        local stale = false
        local ok, result = pcall(function()
            return store:UpdateAsync("u" .. uid, function(old)
                local out = FindsEpoch.reset(old, expected, os.time(), token)
                stale = out == nil
                if not out then return nil end
                out.passport = Journal.merge(out.passport or {}, passportPending[uid] or {})
                return out
            end)
        end)
        if ok and result and result.findsResetToken == token then saved=result; break end
        if stale then canSave[uid]=false; lastError="a newer reset exists; rejoin required"; break end
        lastError=tostring(result)
        if attempt < 3 then task.wait(attempt) end
    end
    if not saved then
        -- A lost response could mean the reset committed. Freeze saving/awards until rejoin;
        -- never put the old finds back or pretend an unconfirmed reset succeeded.
        canSave[uid]=false; resetting[uid]=nil
        warn("SquirrelSetup: reset not confirmed; rejoin before saving or competing: " .. tostring(lastError))
        return
    end
    found[uid] = {}
    italyAdditions[uid] = {}
    italyConfirmed[uid] = FindsEpoch.copy(saved.italyAttempts or {})
    findEpoch[uid] = FindsEpoch.read(saved)
    findRevision[uid] = (findRevision[uid] or 0) + 1
    dirty[uid] = true -- keep any acorns/items earned while the reset request was in flight
    player:SetAttribute("SquirrelsFound", 0)
    publishCounts(player)
    resetting[uid] = nil
    resetEv:FireClient(player)
    emitItaly(player)
    print("SquirrelSetup: " .. player.Name .. " reset finds; generation " .. findEpoch[uid])
end)

-- ---- the section a player was last in: SpawnReturn sets the attribute, this saves it with the next batch ----
local function watchArea(player)
	player:GetAttributeChangedSignal("Area"):Connect(function()
		if loaded[player.UserId] and player:GetAttribute("Area") ~= player:GetAttribute("SavedArea") then
			dirty[player.UserId] = true                     -- landing back in the section they left is not a change
		end
	end)
end
local function watchDais(player)                                   -- the last dais touched is what gets saved now
	player:GetAttributeChangedSignal("Dais"):Connect(function()
		if loaded[player.UserId] and player:GetAttribute("Dais") ~= player:GetAttribute("SavedArea") then dirty[player.UserId] = true end
	end)
end
Players.PlayerAdded:Connect(watchDais)
for _, player in ipairs(Players:GetPlayers()) do watchDais(player) end
Players.PlayerAdded:Connect(watchArea)
for _, player in ipairs(Players:GetPlayers()) do watchArea(player) end


-- Startup/periodic recovery handshake. These are server-only Bindables, never remotes.
local getItaly=ReplicatedStorage:FindFirstChild("GetItalyAttempts") or Instance.new("BindableFunction")
assert(getItaly:IsA("BindableFunction"));getItaly.Name="GetItalyAttempts";getItaly.OnInvoke=pendingItaly;getItaly.Parent=ReplicatedStorage
local ackItaly=ReplicatedStorage:FindFirstChild("AckItalyAttempt") or Instance.new("BindableEvent")
assert(ackItaly:IsA("BindableEvent"));ackItaly.Name="AckItalyAttempt";ackItaly.Parent=ReplicatedStorage
ackItaly.Event:Connect(acknowledgeItaly)
]====],after=[====[-- SquirrelSetup (server)
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
	if mesh:GetAttribute("GrayTexture") and not isGray(mesh) then table.insert(colours, mesh)          -- already set up (saved place)
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
		-- Oct 7 2026: a world-aligned box of the parts (GetBoundingBox follows the pivot's axes, turned on imported squirrels, so
		-- they sank 0.15-0.2 studs: Shannon saw the keeper's feet in the lighthouse's stone)
		local function worldBox(m)
			local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
			for _, p in ipairs(m:GetDescendants()) do
				if p:IsA("BasePart") then
					local cf, s = p.CFrame, p.Size / 2
					local e = Vector3.new(
						math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
						math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
						math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z)
					lo = lo:Min(cf.Position - e) hi = hi:Max(cf.Position + e)
				end
			end
			return lo, hi
		end
		local lo0, hi0 = worldBox(model)
		model:ScaleTo(model:GetScale() * targetH / mesh.Size.Y)
		local lo1, hi1 = worldBox(model)
		local c0, c1 = (lo0 + hi0) / 2, (lo1 + hi1) / 2
		model:PivotTo(model:GetPivot() + Vector3.new(c0.X - c1.X, lo0.Y - lo1.Y, c0.Z - c1.Z))
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
local FindsEpoch = require(script.Parent:WaitForChild("FindsEpoch"))
local findEpoch, findRevision, saving, resetting = {}, {}, {}, {}
local sessionPlayer, loading, leaving = {}, {}, {}
local italyAdditions, italyConfirmed, italyAcks = {}, {}, {}
local collectedEv = ReplicatedStorage:FindFirstChild("SquirrelCollectedServer") or Instance.new("BindableEvent")
assert(collectedEv:IsA("BindableEvent"), "SquirrelCollectedServer must be server-only")
collectedEv.Name = "SquirrelCollectedServer"; collectedEv.Parent = ReplicatedStorage
-- Transient proof of a find made in this session; never stored or used for award eligibility.
local freshCelebration = ReplicatedStorage:FindFirstChild("ItalyCelebrationFresh") or Instance.new("BindableEvent")
assert(freshCelebration:IsA("BindableEvent"), "ItalyCelebrationFresh must be server-only")
freshCelebration.Name = "ItalyCelebrationFresh"; freshCelebration.Parent = ReplicatedStorage
local dirty = {}          -- userId -> true when there is something new to save
local Journal=require(workspace:WaitForChild("Passport"):WaitForChild("Journal"))
local Http=game:GetService("HttpService")
local passportPending={}
local passportLoaded={}
local owedItems = {}      -- userId -> {itemId = delta}; same reasoning as the purse below, per item
local owed = {}           -- userId -> acorns earned but not yet written, applied as a DELTA so that two
                          -- servers adding to the same purse cannot overwrite one another
-- Italy durable completion helpers: only confirmed saved intents can be replayed.
local function pendingItaly(player)
    local uid=player.UserId
    if sessionPlayer[uid]~=player or not canSave[uid] then return {} end
    return FindsEpoch.pending(italyConfirmed[uid],uid,findEpoch[uid] or 0,italyAcks[uid])
end
local function emitItaly(player)
    local attempts=pendingItaly(player)
    if #attempts>0 then collectedEv:Fire(player,attempts) end
end
local function acknowledgeItaly(player,claimId)
    local uid=player.UserId
    if sessionPlayer[uid]~=player or type(claimId)~="string" then return end
    for _,rec in ipairs(pendingItaly(player)) do
        if rec.claimId==claimId then
            italyAcks[uid]=italyAcks[uid] or {};italyAcks[uid][claimId]=true;dirty[uid]=true;return
        end
    end
end
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
    local deadline = os.clock() + 60
    while (saving[uid] or resetting[uid] or leaving[uid] or loading[uid]) and os.clock() < deadline do task.wait(0.1) end
    if saving[uid] or resetting[uid] or leaving[uid] or loading[uid] or player.Parent ~= Players then
        warn("SquirrelSetup: previous session still busy; rejoin required"); return
    end
    local previousSession = sessionPlayer[uid]
    sessionPlayer[uid], loading[uid] = player, true
    found[uid], loaded[uid], dirty[uid] = {}, false, nil
    if previousSession and previousSession ~= player then
        owed[uid], owedItems[uid], passportPending[uid], passportLoaded[uid] = nil, nil, nil, nil
    end
    findEpoch[uid], findRevision[uid] = 0, 0
    italyAdditions[uid], italyConfirmed[uid], italyAcks[uid] = {}, {}, {}
	local studioFullFindsPreview = RunService:IsStudio() and uid == 9611145467
	canSave[uid] = not studioFullFindsPreview
	if store and not studioFullFindsPreview then
		local ok, data
		for attempt = 1, 3 do
			ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
			if ok then break end
			task.wait(1.5)
		end
        if sessionPlayer[uid] ~= player or player.Parent ~= Players then loading[uid]=nil; return end
        if ok then
            local valid, epoch = pcall(FindsEpoch.read, data)
            if valid then findEpoch[uid] = epoch; italyConfirmed[uid] = type(data)=="table" and FindsEpoch.copy(data.italyAttempts or {}) or {} else canSave[uid] = false; warn("SquirrelSetup: invalid reset generation; saving and daily awards disabled") end
			passportLoaded[uid]=Journal.merge(type(data)=="table" and data.passport or {},passportPending[uid] or {})
			local t = foundList(player)
			if type(data) == "table" and type(data.found) == "table" then
				for _, id in ipairs(data.found) do
					local sid = (tostring(id):gsub("_color$", ""))
					if not byId[sid] then local base = sid:match("^(.-)_%d+$") if base and byId[base] then sid = base end end   -- Oct 7 2026: "pogo_squirrel_2" finds (twin mix-up) count as pogo_squirrel
					t[sid] = true
				end
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
		-- Oct 8 2026: workspace.PortoGates.StudioFreshPorto (Studio only) = play Porto through from the start: France found, Porto not
		local pgFresh = workspace:FindFirstChild("PortoGates") and workspace.PortoGates:GetAttribute("StudioFreshPorto")
		for _, squirrel in ipairs(Registry.squirrels) do
			if not (pgFresh and squirrel.map == "porto") then allFinds[squirrel.id] = true end
		end
		-- StudioPortoCartUnlock: show the France/Porto cart prompts and Passport city tab.
		player:SetAttribute('Item_porto', math.max(1, tonumber(player:GetAttribute('Item_porto')) or 0))
		print('SquirrelSetup: Studio owner preview has ' .. tostring(count(allFinds)) .. ' of ' .. tostring(#Registry.squirrels) .. ' squirrels')
	end
	loading[uid] = nil
	loaded[uid] = true
	player:SetAttribute("SaveLoaded", true)
	if player:GetAttribute("Acorns") == nil then player:SetAttribute("Acorns", 0) end
	player:SetAttribute("SquirrelsFound", count(foundList(player)))
	publishCounts(player)
    emitItaly(player)
end
local function savePlayer(player)
	local uid = player.UserId
	if not store or not canSave[uid] or not loaded[uid] or saving[uid] or resetting[uid] or sessionPlayer[uid] ~= player then return false end
    saving[uid] = true
    local epoch, revision, stale = findEpoch[uid] or 0, findRevision[uid] or 0, false
    local movedItaly, movedAcks = FindsEpoch.copy(italyAdditions[uid] or {}), FindsEpoch.copy(italyAcks[uid] or {})
	local list = {}
	for id in pairs(foundList(player)) do table.insert(list, id) end
	local movedPassport=Journal.merge(passportPending[uid] or {},{})
	local gain = owed[uid] or 0                                   -- captured BEFORE the call: UpdateAsync can
	local movedItems = {}                                         -- likewise, a snapshot of the item deltas
	for id, d in pairs(owedItems[uid] or {}) do movedItems[id] = d end
	local ok, err = pcall(function()                              -- re-run its callback, and more can be earned
		return store:UpdateAsync("u" .. uid, function(old)                -- while it is in flight
            stale = FindsEpoch.read(old) ~= epoch
            if stale then return nil end
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
			return FindsEpoch.write(old, epoch, {found = out, area = area, acorns = acorns, items = items, italyAttempts=FindsEpoch.mergeAttempts(type(old)=="table" and old.italyAttempts, movedItaly, movedAcks), passport=Journal.merge(type(old)=="table" and old.passport or {},movedPassport), updated = os.time()})
		end)
	end)
    saving[uid] = nil
    if stale then
        canSave[uid] = false
        warn("SquirrelSetup: newer reset detected; stale session cannot save or compete; rejoin required")
        return
    end
	if ok then
        italyConfirmed[uid] = type(err)=="table" and FindsEpoch.copy(err.italyAttempts or {}) or {}
        for key,rec in pairs(movedItaly) do
            if italyAdditions[uid] and italyAdditions[uid][key] and italyAdditions[uid][key].claimId==rec.claimId then italyAdditions[uid][key]=nil end
        end
        for id in pairs(movedAcks) do if italyAcks[uid] then italyAcks[uid][id]=nil end end
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
        if (findRevision[uid] or 0) ~= revision or (owed[uid] or 0) ~= 0 or next(owedItems[uid] or {}) or next(italyAdditions[uid] or {}) or next(italyAcks[uid] or {}) then dirty[uid] = true end
        emitItaly(player)
	else
		warn("SquirrelSetup: save failed for " .. player.Name .. ": " .. tostring(err))
	end
    return ok and not stale
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
    local uid = player.UserId
    if sessionPlayer[uid] ~= player then return end
    leaving[uid] = true
    local deadline = os.clock() + 60
    while (saving[uid] or resetting[uid] or loading[uid]) and os.clock() < deadline do task.wait(0.1) end
	if dirty[uid] then savePlayer(player) end
    leaving[uid] = nil
	task.delay(5, function()
		local uid = player.UserId
		if Players:GetPlayerByUserId(uid) then return end   -- Oct 8 2026: back in this server already - keep the new load
		if sessionPlayer[uid] ~= player or saving[uid] or resetting[uid] or loading[uid] then return end
		italyAdditions[uid]=nil;italyConfirmed[uid]=nil;italyAcks[uid]=nil
		sessionPlayer[uid]=nil; findEpoch[uid]=nil; findRevision[uid]=nil; saving[uid]=nil; resetting[uid]=nil
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
 if not hrp or not hum or hum.Health<=0 or not loaded[player.UserId] or resetting[player.UserId] or leaving[player.UserId] or sessionPlayer[player.UserId] ~= player or (hrp.Position-mesh.Position).Magnitude>(folder:GetAttribute("ClickDistance") or 32)+mesh.Size.Magnitude/2 then return end
	if PER_PLAYER then
		local t = foundList(player)
		if t[id] then return end
		t[id] = true
        findRevision[player.UserId] = (findRevision[player.UserId] or 0) + 1
		dirty[player.UserId] = true
		player:SetAttribute("SquirrelsFound", count(t))
		publishCounts(player)
        local entry = byId[id]
        if canSave[player.UserId] and store and entry and entry.map == "porto" and player:GetAttribute("Found_porto") == 44 then
            local uid, epoch, at = player.UserId, findEpoch[player.UserId] or 0, os.time()
            local daily=workspace:FindFirstChild("Daily")
            local offset=daily and daily:GetAttribute("DayOffsetHours") or 9
            italyAdditions[uid]=italyAdditions[uid] or {}
            italyAdditions[uid][tostring(epoch)]=FindsEpoch.newAttempt(uid,player.DisplayName,player.Name,epoch,at,offset,Http:GenerateGUID(false))
            freshCelebration:Fire(player, italyAdditions[uid][tostring(epoch)])
            -- No yield occurs between recording the 44th find and staging this intent.
            -- The next save writes BOTH in the same player-key UpdateAsync transaction.
            task.spawn(function()
                local deadline = os.clock() + 45
                while saving[uid] and os.clock() < deadline do task.wait(0.1) end
                if resetting[uid] or findEpoch[uid] ~= epoch or sessionPlayer[uid] ~= player or not canSave[uid] then return end
                -- savePlayer emits only the intents returned by the confirmed datastore save.
                -- Lost responses leave the outbox durable for a later save or rejoin to recover.
                if not savePlayer(player) then warn("SquirrelSetup: Italy completion save pending; daily attempt will recover after persistence") end
            end)
        end
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

-- Oct 8 2026 (Ethan could not collect any squirrels in Porto): Roblox ignores ClickDetectors while a Tool is held - the
-- slingshot, the crab trap, the camera - so SquirrelToolClick (client, in this folder) passes such a click on here, and
-- onFound makes exactly the checks a normal click gets (alive, loaded, close enough, not found yet).
local toolClick = ReplicatedStorage:FindFirstChild("SquirrelClick") or Instance.new("RemoteEvent")
toolClick.Name = "SquirrelClick"; toolClick.Parent = ReplicatedStorage
toolClick.OnServerEvent:Connect(function(player, id)
	if type(id) ~= "string" then return end
	local mesh = squirrels[id]
	if mesh then onFound(player, modelOf(mesh), id, mesh) end
end)

-- ---- reset: wipe this player's finds on request (the "Reset progress" button asks twice before sending it) ----
local resetEv = ReplicatedStorage:FindFirstChild("SquirrelReset") or Instance.new("RemoteEvent")
resetEv.Name = "SquirrelReset"; resetEv.Parent = ReplicatedStorage
local resetAt = {}
resetEv.OnServerEvent:Connect(function(player)
    local uid = player.UserId
    if not loaded[uid] or resetting[uid] or leaving[uid] or sessionPlayer[uid] ~= player or os.clock() - (resetAt[uid] or -60) < 5 then return end
    if not store or not canSave[uid] then warn("SquirrelSetup: reset refused because this save is unavailable"); return end
    resetAt[uid], resetting[uid] = os.clock(), true
    local deadline = os.clock() + 45
    while saving[uid] and os.clock() < deadline do task.wait(0.1) end
    if saving[uid] then resetting[uid]=nil; warn("SquirrelSetup: reset timed out waiting for save"); return end
    local expected, token = findEpoch[uid] or 0, Http:GenerateGUID(false)
    local saved, lastError
    for attempt = 1, 3 do
        local stale = false
        local ok, result = pcall(function()
            return store:UpdateAsync("u" .. uid, function(old)
                local out = FindsEpoch.reset(old, expected, os.time(), token)
                stale = out == nil
                if not out then return nil end
                out.passport = Journal.merge(out.passport or {}, passportPending[uid] or {})
                return out
            end)
        end)
        if ok and result and result.findsResetToken == token then saved=result; break end
        if stale then canSave[uid]=false; lastError="a newer reset exists; rejoin required"; break end
        lastError=tostring(result)
        if attempt < 3 then task.wait(attempt) end
    end
    if not saved then
        -- A lost response could mean the reset committed. Freeze saving/awards until rejoin;
        -- never put the old finds back or pretend an unconfirmed reset succeeded.
        canSave[uid]=false; resetting[uid]=nil
        warn("SquirrelSetup: reset not confirmed; rejoin before saving or competing: " .. tostring(lastError))
        return
    end
    found[uid] = {}
    italyAdditions[uid] = {}
    italyConfirmed[uid] = FindsEpoch.copy(saved.italyAttempts or {})
    findEpoch[uid] = FindsEpoch.read(saved)
    findRevision[uid] = (findRevision[uid] or 0) + 1
    dirty[uid] = true -- keep any acorns/items earned while the reset request was in flight
    player:SetAttribute("SquirrelsFound", 0)
    publishCounts(player)
    resetting[uid] = nil
    resetEv:FireClient(player)
    emitItaly(player)
    print("SquirrelSetup: " .. player.Name .. " reset finds; generation " .. findEpoch[uid])
end)

-- ---- the section a player was last in: SpawnReturn sets the attribute, this saves it with the next batch ----
local function watchArea(player)
	player:GetAttributeChangedSignal("Area"):Connect(function()
		if loaded[player.UserId] and player:GetAttribute("Area") ~= player:GetAttribute("SavedArea") then
			dirty[player.UserId] = true                     -- landing back in the section they left is not a change
		end
	end)
end
local function watchDais(player)                                   -- the last dais touched is what gets saved now
	player:GetAttributeChangedSignal("Dais"):Connect(function()
		if loaded[player.UserId] and player:GetAttribute("Dais") ~= player:GetAttribute("SavedArea") then dirty[player.UserId] = true end
	end)
end
Players.PlayerAdded:Connect(watchDais)
for _, player in ipairs(Players:GetPlayers()) do watchDais(player) end
Players.PlayerAdded:Connect(watchArea)
for _, player in ipairs(Players:GetPlayers()) do watchArea(player) end


-- Startup/periodic recovery handshake. These are server-only Bindables, never remotes.
local getItaly=ReplicatedStorage:FindFirstChild("GetItalyAttempts") or Instance.new("BindableFunction")
assert(getItaly:IsA("BindableFunction"));getItaly.Name="GetItalyAttempts";getItaly.OnInvoke=pendingItaly;getItaly.Parent=ReplicatedStorage
local ackItaly=ReplicatedStorage:FindFirstChild("AckItalyAttempt") or Instance.new("BindableEvent")
assert(ackItaly:IsA("BindableEvent"));ackItaly.Name="AckItalyAttempt";ackItaly.Parent=ReplicatedStorage
ackItaly.Event:Connect(acknowledgeItaly)
]====]},{name="PortoKeeperServer",path="Workspace.PortoKeeper.PortoKeeperServer",before=[====[-- Guardian of the Harbour: first fresh Italy completion per 09:00 UTC day.
-- Daily ledger is separate from player saves; the historical "first" record is read-only.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local BadgeService = game:GetService("BadgeService")
local MessagingService = game:GetService("MessagingService")
local Http = game:GetService("HttpService")
local F = script.Parent
local ev = RS:WaitForChild("PortoKeeperEvent")
local collected = RS:WaitForChild("SquirrelCollectedServer")
local getAttempts = RS:WaitForChild("GetItalyAttempts")
local acknowledge = RS:WaitForChild("AckItalyAttempt")
local STUDIO = RunService:IsStudio()
local Core = require(F:WaitForChild("DailyKeeperCore"))
local Store = require(F:WaitForChild("DailyKeeperStore"))
local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
local ALL_ID, PORTO_ID = Core.registry(Registry.squirrels)
local registryTotal = 0
for _ in pairs(PORTO_ID) do registryTotal += 1 end
assert(registryTotal == Core.NEED and (tonumber(F:GetAttribute("Need")) or 44) == Core.NEED, "Italy daily award requires the 44-squirrel registry")
local daily = workspace:FindFirstChild("Daily")
local OFFSET = daily and daily:GetAttribute("DayOffsetHours") or 9
local TOPIC = "PortoKeeperDaily_v2"
local function need() return Core.NEED end
local function title() return F:GetAttribute("Title") or "Guardian of the Harbour" end
local function dateOf(rec)
    return os.date("!%B %d, %Y", rec.day and (rec.day * 86400 + 43200) or rec.t)
end
local GOLD, GOLD_D, GOLD_DD = Color3.new(1, 0.807843, 0.25098), Color3.new(0.839216, 0.627451, 0.172549), Color3.new(0.745098, 0.533333, 0.156863)

-- ---- the key ----
local function part(name, size, color, shape)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color; p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false
	if shape then p.Shape = shape end
	return p
end
local KEY_H = 3.6   -- the key below is drawn 3.6 tall at s = 1
local function keyPose(s)
	return {
		Shaft = {CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(2.3 * s, 0.34 * s, 0.34 * s), GOLD, Enum.PartType.Cylinder},
		Nut = {CFrame.new(0, 1.57 * s, 0), Vector3.new(0.95 * s, 0.95 * s, 0.95 * s), GOLD, Enum.PartType.Ball},
		Cap = {CFrame.new(0, 2.01 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.36 * s, 1.06 * s, 1.06 * s), GOLD_D, Enum.PartType.Cylinder},
		Lip = {CFrame.new(0, 1.81 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.14 * s, 0.9 * s, 0.9 * s), GOLD_DD, Enum.PartType.Cylinder},
		Stem = {CFrame.new(0, 2.25 * s, 0), Vector3.new(0.17 * s, 0.26 * s, 0.17 * s), GOLD_DD, nil},
		Bit1 = {CFrame.new(0.38 * s, -0.95 * s, 0), Vector3.new(0.5 * s, 0.3 * s, 0.34 * s), GOLD, nil},
		Bit2 = {CFrame.new(0.3 * s, -0.55 * s, 0), Vector3.new(0.34 * s, 0.3 * s, 0.34 * s), GOLD, nil},
	}
end
local function extents(m)
	local lo, hi = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local h = p.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
			end end end
		end
	end
	return lo, hi
end
-- a key `height` tall, standing with its bottom at (x, bottomY, z), turned by yaw
local function makeKey(height, x, bottomY, z, yaw, parent)
	local s = height / KEY_H
	local k = Instance.new("Model"); k.Name = "Key"
	local pose = keyPose(s)
	for name, d in pairs(pose) do local p = part(name, d[2], d[3], d[4]); p.CFrame = d[1]; p.Parent = k end
	k.PrimaryPart = k.Shaft
	local lo = extents(k)
	local base = CFrame.new(x, bottomY - lo.Y, z) * CFrame.Angles(0, yaw, 0)
	for name, d in pairs(pose) do k[name].CFrame = base * d[1] end
	k.WorldPivot = CFrame.new(x, bottomY + height / 2, z)
	k.Parent = parent
	return k
end
local function facingYaw() local f = F:GetAttribute("Facing") or Vector3.new(0, 0, -1) return math.atan2(f.X, f.Z) + math.pi end

-- ---- the plaque ----
local words = F:WaitForChild("Plinth"):WaitForChild("Plaque"):WaitForChild("Words")
local function setPlaque(rec)
	words.Title.Text = title():upper()
	words.Day.Text = "OF PORTO NOCCIOLA / DAILY GUARDIAN"
	if rec then
		words.Who.Text = tostring(rec.name or "?")
		words.Note.Text = "First to find all " .. tostring(rec.total or need()) .. " squirrels of Porto Nocciola, on " .. dateOf(rec)
	else
		words.Who.Text = "Awaiting today's Guardian"
		words.Note.Text = "Be the first to find all " .. tostring(need()) .. " squirrels of Porto Nocciola today. Returning with all 44 does not count; reset your finds to try again."
	end
end

-- ---- the statue ----
local function buildStatue(rec)
	for _, n in ipairs({"Figure", "Key", "GiantAcorn"}) do local o = F:FindFirstChild(n); if o then o:Destroy() end end
	setPlaque(rec)
	local PX, PZ, TOP = F:GetAttribute("PlinthX"), F:GetAttribute("PlinthZ"), F:GetAttribute("TopY")
	local FX = F:GetAttribute("FigureX") or PX
	if not rec then
		makeKey(F:GetAttribute("RestKeyHeight") or 3.4, PX, TOP, PZ, facingYaw(), F)
		return true
	end
	local mk = (workspace:WaitForChild("Champion", 30) and workspace.Champion:WaitForChild("MakeStatue", 30))
	local model, acorn
	if mk then
		local ok, m, a = pcall(function() return mk:Invoke(rec, {x = FX, top = TOP, z = PZ, parent = F, name = "Figure", scale = F:GetAttribute("Scale") or 1.5, look = F:GetAttribute("Facing") or Vector3.new(0, 0, -1)}) end)
		if ok then model, acorn = m, a else warn("PortoKeeper: MakeStatue failed: " .. tostring(m)) end
	end
	if acorn then acorn:Destroy() end
	if model then
		-- the key in the raised hand, sized to the figure like the French acorn (a share of the body height)
		local holdSide = (workspace.Champion:GetAttribute("HoldHand") == "Right") and "Right" or "Left"
		local hand = model:FindFirstChild(holdSide .. "Hand")
		local lo, hi = extents(model)
		local bodyH = hi.Y - lo.Y
		local h = math.clamp(bodyH * (F:GetAttribute("KeyShare") or 0.42), 1.5, 6)
		if hand then
			makeKey(h, hand.Position.X, hand.Position.Y + hand.Size.Y / 2 - 0.15, hand.Position.Z, facingYaw(), F)
		else
			makeKey(h, FX, hi.Y, PZ, facingYaw(), F)
		end
		print(string.format("PortoKeeper: the statue of %s stands by the lighthouse", tostring(rec.name)))
	else
		makeKey(F:GetAttribute("RestKeyHeight") or 3.4, PX, TOP, PZ, facingYaw(), F)
	end
	return model ~= nil
end


-- Neither this adapter nor its debug preview opens production stores in Studio.
local getOptions = Instance.new("DataStoreGetOptions")
getOptions.UseCache = false
local persistence = Store.new(Core, nil, {
    now=os.time, wait=task.wait, offsetHours=OFFSET, getOptions=getOptions,
    openStore=function()
        if STUDIO then return nil end
        return DSS:GetDataStore("PortoKeeper_v1")
    end,
})
local renderer = Core.renderer(buildStatue, task.spawn, function(err)
    warn("PortoKeeper: statue build will retry: " .. tostring(err))
end)
local badgeBusy, badgeDone, announced, pending = {}, {}, {}, {}

local function giveBadge(player)
    local id = tonumber(F:GetAttribute("Badge_key")) or 0
    local uid = player.UserId
    if STUDIO or id <= 0 or badgeBusy[uid] or badgeDone[uid] then return end
    badgeBusy[uid] = true
    task.spawn(function()
        local ok, has = pcall(BadgeService.UserHasBadgeAsync, BadgeService, uid, id)
        if ok and not has then ok, has = pcall(BadgeService.AwardBadgeAsync, BadgeService, uid, id) end
        badgeDone[uid] = ok and has == true
        badgeBusy[uid] = nil
        if not badgeDone[uid] then warn("PortoKeeper: badge delivery will retry for " .. uid) end
    end)
end

local function applyTitles()
    local state = persistence.snapshot()
    if not state then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if state.winners[tostring(player.UserId)] then
            player:SetAttribute("PortoKeeperTitle", title())
            giveBadge(player)
        end
    end
end

local function renderCurrent()
    local now = os.time()
    local rec = Core.current(persistence.snapshot(), now, OFFSET)
    local key = tostring(Core.day(now, OFFSET)) .. ":" .. (rec and rec.claimId or "waiting")
    local missing = rec and not F:FindFirstChild("Figure") or not rec and not F:FindFirstChild("Key")
    renderer.request(key, rec, missing)
end

local function announce(rec)
    if not rec or rec.day ~= Core.day(os.time(), OFFSET) or announced[rec.claimId] then return end
    ev:FireAllClients("crowned", rec)
    announced[rec.claimId] = true
end

local function excluded(player)
    return Core.excluded(player.UserId, game.CreatorId, game.CreatorType == Enum.CreatorType.User, F:GetAttribute("NoKeeperUserIds"))
end

-- The source is the confirmed player-save outbox, including recovery after a crash.
-- Each player's generations are settled in order; an outage never skips ahead.
local function processAttempts(player)
    if STUDIO or player:GetAttribute("SaveLoaded") ~= true or pending[player.UserId] then return end
    local ok, attempts = pcall(getAttempts.Invoke, getAttempts, player)
    if not ok or type(attempts) ~= "table" or #attempts == 0 then return end
    pending[player.UserId] = true
    task.spawn(function()
        local ran, failure = pcall(function()
            for _, rec in ipairs(attempts) do
                local settled = false
                if excluded(player) then
                    acknowledge:Fire(player, rec.claimId)
                    settled = true
                else
                    for attempt = 1, 6 do
                        local outcome, holder, err = persistence.claim(rec)
                        if outcome ~= "unavailable" then
                            applyTitles()
                            renderCurrent()
                            if outcome == "won" then
                                announce(holder)
                                if player.Parent == Players and holder.day ~= Core.day(os.time(), OFFSET) then
                                    ev:FireClient(player, "recovered", holder)
                                end
                                local sent, messageError = pcall(MessagingService.PublishAsync, MessagingService, TOPIC, {claimId=holder.claimId})
                                if not sent then warn("PortoKeeper: notification failed; polling will recover: " .. tostring(messageError)) end
                            elseif player.Parent == Players then
                                if outcome == "already" then ev:FireClient(player, "already")
                                elseif outcome == "late" then ev:FireClient(player, "late", {name=holder and holder.name or "another player",day=rec.day,claimId=rec.claimId})
                                elseif outcome == "attempted" then ev:FireClient(player, "reset_needed")
                                else ev:FireClient(player, "unavailable") end
                            end
                            acknowledge:Fire(player, rec.claimId)
                            settled = true
                            break
                        end
                        warn("PortoKeeper: durable completion pending; retry " .. attempt .. ": " .. tostring(err))
                        if attempt < 6 then task.wait(10) end
                    end
                end
                if not settled then
                    if player.Parent == Players then ev:FireClient(player, "unavailable") end
                    break
                end
            end
        end)
        pending[player.UserId] = nil
        if not ran then warn("PortoKeeper: pending completion will retry: " .. tostring(failure)) end
    end)
end
collected.Event:Connect(processAttempts)

local subscription
task.spawn(function()
    while true do
        if not STUDIO then
            local ok, err = persistence.refresh()
            if ok then applyTitles(); renderCurrent()
            else warn("PortoKeeper: cannot refresh daily winner: " .. tostring(err)) end
            for _, player in ipairs(Players:GetPlayers()) do processAttempts(player) end
            if not subscription then
                local subscribed, result = pcall(MessagingService.SubscribeAsync, MessagingService, TOPIC, function(message)
                    task.spawn(function()
                        local fresh = persistence.refresh()
                        if fresh then
                            applyTitles(); renderCurrent()
                            local rec = Core.current(persistence.snapshot(), os.time(), OFFSET)
                            if type(message.Data) == "table" and rec and message.Data.claimId == rec.claimId then announce(rec) end
                        end
                    end)
                end)
                if subscribed then subscription = result
                else warn("PortoKeeper: messaging unavailable; polling active: " .. tostring(result)) end
            end
        end
        task.wait(30)
    end
end)
-- Rollover and missing avatars are handled throughout the server's life, not only its first minute.
task.spawn(function()
    while true do renderCurrent(); task.wait(5) end
end)
Players.PlayerAdded:Connect(function() task.defer(applyTitles) end)
Players.PlayerRemoving:Connect(function(player) badgeBusy[player.UserId]=nil; badgeDone[player.UserId]=nil end)
print("PortoKeeper: daily Guardian ready; fresh 44th find, 09:00 UTC boundary, one win per player")
]====],after=[====[-- Guardian of the Harbour: first fresh Italy completion per 09:00 UTC day.
-- Daily ledger is separate from player saves; the historical "first" record is read-only.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local BadgeService = game:GetService("BadgeService")
local MessagingService = game:GetService("MessagingService")
local Http = game:GetService("HttpService")
local F = script.Parent
local ev = RS:WaitForChild("PortoKeeperEvent")
local collected = RS:WaitForChild("SquirrelCollectedServer")
local getAttempts = RS:WaitForChild("GetItalyAttempts")
local acknowledge = RS:WaitForChild("AckItalyAttempt")
local STUDIO = RunService:IsStudio()
local Core = require(F:WaitForChild("DailyKeeperCore"))
local Celebration = require(F:WaitForChild("KeeperCelebration"))
local freshCelebration = RS:WaitForChild("ItalyCelebrationFresh")
local Store = require(F:WaitForChild("DailyKeeperStore"))
local Registry = require(workspace.SquirrelScripts.SquirrelRegistry)
local ALL_ID, PORTO_ID = Core.registry(Registry.squirrels)
local registryTotal = 0
for _ in pairs(PORTO_ID) do registryTotal += 1 end
assert(registryTotal == Core.NEED and (tonumber(F:GetAttribute("Need")) or 44) == Core.NEED, "Italy daily award requires the 44-squirrel registry")
local daily = workspace:FindFirstChild("Daily")
local OFFSET = daily and daily:GetAttribute("DayOffsetHours") or 9
local TOPIC = "PortoKeeperDaily_v2"
local function need() return Core.NEED end
local function title() return F:GetAttribute("Title") or "Guardian of the Harbour" end
local function dateOf(rec)
    return os.date("!%B %d, %Y", rec.day and (rec.day * 86400 + 43200) or rec.t)
end
local GOLD, GOLD_D, GOLD_DD = Color3.new(1, 0.807843, 0.25098), Color3.new(0.839216, 0.627451, 0.172549), Color3.new(0.745098, 0.533333, 0.156863)

-- ---- the key ----
local function part(name, size, color, shape)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color; p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false
	if shape then p.Shape = shape end
	return p
end
local KEY_H = 3.6   -- the key below is drawn 3.6 tall at s = 1
local function keyPose(s)
	return {
		Shaft = {CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(2.3 * s, 0.34 * s, 0.34 * s), GOLD, Enum.PartType.Cylinder},
		Nut = {CFrame.new(0, 1.57 * s, 0), Vector3.new(0.95 * s, 0.95 * s, 0.95 * s), GOLD, Enum.PartType.Ball},
		Cap = {CFrame.new(0, 2.01 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.36 * s, 1.06 * s, 1.06 * s), GOLD_D, Enum.PartType.Cylinder},
		Lip = {CFrame.new(0, 1.81 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.14 * s, 0.9 * s, 0.9 * s), GOLD_DD, Enum.PartType.Cylinder},
		Stem = {CFrame.new(0, 2.25 * s, 0), Vector3.new(0.17 * s, 0.26 * s, 0.17 * s), GOLD_DD, nil},
		Bit1 = {CFrame.new(0.38 * s, -0.95 * s, 0), Vector3.new(0.5 * s, 0.3 * s, 0.34 * s), GOLD, nil},
		Bit2 = {CFrame.new(0.3 * s, -0.55 * s, 0), Vector3.new(0.34 * s, 0.3 * s, 0.34 * s), GOLD, nil},
	}
end
local function extents(m)
	local lo, hi = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local h = p.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
			end end end
		end
	end
	return lo, hi
end
-- a key `height` tall, standing with its bottom at (x, bottomY, z), turned by yaw
local function makeKey(height, x, bottomY, z, yaw, parent)
	local s = height / KEY_H
	local k = Instance.new("Model"); k.Name = "Key"
	local pose = keyPose(s)
	for name, d in pairs(pose) do local p = part(name, d[2], d[3], d[4]); p.CFrame = d[1]; p.Parent = k end
	k.PrimaryPart = k.Shaft
	local lo = extents(k)
	local base = CFrame.new(x, bottomY - lo.Y, z) * CFrame.Angles(0, yaw, 0)
	for name, d in pairs(pose) do k[name].CFrame = base * d[1] end
	k.WorldPivot = CFrame.new(x, bottomY + height / 2, z)
	k.Parent = parent
	return k
end
local function facingYaw() local f = F:GetAttribute("Facing") or Vector3.new(0, 0, -1) return math.atan2(f.X, f.Z) + math.pi end

-- ---- the plaque ----
local words = F:WaitForChild("Plinth"):WaitForChild("Plaque"):WaitForChild("Words")
local function setPlaque(rec)
	words.Title.Text = title():upper()
	words.Day.Text = "OF PORTO NOCCIOLA / DAILY GUARDIAN"
	if rec then
		words.Who.Text = tostring(rec.name or "?")
		words.Note.Text = "First to find all " .. tostring(rec.total or need()) .. " squirrels of Porto Nocciola, on " .. dateOf(rec)
	else
		words.Who.Text = "Awaiting today's Guardian"
		words.Note.Text = "Be the first to find all " .. tostring(need()) .. " squirrels of Porto Nocciola today. Returning with all 44 does not count; reset your finds to try again."
	end
end

-- ---- the statue ----
local function buildStatue(rec)
	for _, n in ipairs({"Figure", "Key", "GiantAcorn"}) do local o = F:FindFirstChild(n); if o then o:Destroy() end end
	setPlaque(rec)
	local PX, PZ, TOP = F:GetAttribute("PlinthX"), F:GetAttribute("PlinthZ"), F:GetAttribute("TopY")
	local FX = F:GetAttribute("FigureX") or PX
	if not rec then
		makeKey(F:GetAttribute("RestKeyHeight") or 3.4, PX, TOP, PZ, facingYaw(), F)
		return true
	end
	local mk = (workspace:WaitForChild("Champion", 30) and workspace.Champion:WaitForChild("MakeStatue", 30))
	local model, acorn
	if mk then
		local ok, m, a = pcall(function() return mk:Invoke(rec, {x = FX, top = TOP, z = PZ, parent = F, name = "Figure", scale = F:GetAttribute("Scale") or 1.5, look = F:GetAttribute("Facing") or Vector3.new(0, 0, -1)}) end)
		if ok then model, acorn = m, a else warn("PortoKeeper: MakeStatue failed: " .. tostring(m)) end
	end
	if acorn then acorn:Destroy() end
	if model then
		-- the key in the raised hand, sized to the figure like the French acorn (a share of the body height)
		local holdSide = (workspace.Champion:GetAttribute("HoldHand") == "Right") and "Right" or "Left"
		local hand = model:FindFirstChild(holdSide .. "Hand")
		local lo, hi = extents(model)
		local bodyH = hi.Y - lo.Y
		local h = math.clamp(bodyH * (F:GetAttribute("KeyShare") or 0.42), 1.5, 6)
		if hand then
			makeKey(h, hand.Position.X, hand.Position.Y + hand.Size.Y / 2 - 0.15, hand.Position.Z, facingYaw(), F)
		else
			makeKey(h, FX, hi.Y, PZ, facingYaw(), F)
		end
		print(string.format("PortoKeeper: the statue of %s stands by the lighthouse", tostring(rec.name)))
	else
		makeKey(F:GetAttribute("RestKeyHeight") or 3.4, PX, TOP, PZ, facingYaw(), F)
	end
	return model ~= nil
end


-- Neither this adapter nor its debug preview opens production stores in Studio.
local getOptions = Instance.new("DataStoreGetOptions")
getOptions.UseCache = false
local persistence = Store.new(Core, nil, {
    now=os.time, wait=task.wait, offsetHours=OFFSET, getOptions=getOptions,
    openStore=function()
        if STUDIO then return nil end
        return DSS:GetDataStore("PortoKeeper_v1")
    end,
})
local renderer = Core.renderer(buildStatue, task.spawn, function(err)
    warn("PortoKeeper: statue build will retry: " .. tostring(err))
end)
local badgeBusy, badgeDone, pending = {}, {}, {}
local celebrationGate = Celebration.new(function() return workspace:GetServerTimeNow() end, function(at) return Core.day(at, OFFSET) end)
freshCelebration.Event:Connect(function(player, rec) celebrationGate.markFresh(player, rec) end)

local function giveBadge(player)
    local id = tonumber(F:GetAttribute("Badge_key")) or 0
    local uid = player.UserId
    if STUDIO or id <= 0 or badgeBusy[uid] or badgeDone[uid] then return end
    badgeBusy[uid] = true
    task.spawn(function()
        local ok, has = pcall(BadgeService.UserHasBadgeAsync, BadgeService, uid, id)
        if ok and not has then ok, has = pcall(BadgeService.AwardBadgeAsync, BadgeService, uid, id) end
        badgeDone[uid] = ok and has == true
        badgeBusy[uid] = nil
        if not badgeDone[uid] then warn("PortoKeeper: badge delivery will retry for " .. uid) end
    end)
end

local function applyTitles()
    local state = persistence.snapshot()
    if not state then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if state.winners[tostring(player.UserId)] then
            player:SetAttribute("PortoKeeperTitle", title())
            giveBadge(player)
        end
    end
end

local function renderCurrent()
    local now = os.time()
    local rec = Core.current(persistence.snapshot(), now, OFFSET)
    local key = tostring(Core.day(now, OFFSET)) .. ":" .. (rec and rec.claimId or "waiting")
    local missing = rec and not F:FindFirstChild("Figure") or not rec and not F:FindFirstChild("Key")
    renderer.request(key, rec, missing)
end

local function announce(rec)
    if not celebrationGate.allows(rec) then return false end
    ev:FireAllClients("crowned", rec)
    celebrationGate.mark(rec) -- FireAllClients does not yield; failed delivery can retry.
    return true
end

local function excluded(player)
    return Core.excluded(player.UserId, game.CreatorId, game.CreatorType == Enum.CreatorType.User, F:GetAttribute("NoKeeperUserIds"))
end

-- The source is the confirmed player-save outbox, including recovery after a crash.
-- Each player's generations are settled in order; an outage never skips ahead.
local function processAttempts(player)
    if STUDIO or player:GetAttribute("SaveLoaded") ~= true or pending[player.UserId] then return end
    local ok, attempts = pcall(getAttempts.Invoke, getAttempts, player)
    if not ok or type(attempts) ~= "table" or #attempts == 0 then return end
    pending[player.UserId] = true
    task.spawn(function()
        local ran, failure = pcall(function()
            for _, rec in ipairs(attempts) do
                local settled = false
                if excluded(player) then
                    acknowledge:Fire(player, rec.claimId)
                    settled = true
                else
                    for attempt = 1, 6 do
                        local outcome, holder, err = persistence.claim(rec)
                        if outcome ~= "unavailable" then
                            applyTitles()
                            renderCurrent()
                            if outcome == "won" then
                                local live = celebrationGate.localRecord(player, holder)
                                if live and announce(live) then
                                    local sent, messageError = pcall(MessagingService.PublishAsync, MessagingService, TOPIC,
                                        {claimId=live.claimId, celebrationVersion=live.celebrationVersion, celebrationAt=live.celebrationAt})
                                    if not sent then warn("PortoKeeper: celebration broadcast failed; saved award is safe: " .. tostring(messageError)) end
                                end
                                if player.Parent == Players and holder.day ~= Core.day(os.time(), OFFSET) then
                                    ev:FireClient(player, "recovered", holder)
                                end
                            elseif player.Parent == Players then
                                if outcome == "already" then ev:FireClient(player, "already")
                                elseif outcome == "late" then ev:FireClient(player, "late", {name=holder and holder.name or "another player",day=rec.day,claimId=rec.claimId})
                                elseif outcome == "attempted" then ev:FireClient(player, "reset_needed")
                                else ev:FireClient(player, "unavailable") end
                            end
                            acknowledge:Fire(player, rec.claimId)
                            settled = true
                            break
                        end
                        warn("PortoKeeper: durable completion pending; retry " .. attempt .. ": " .. tostring(err))
                        if attempt < 6 then task.wait(10) end
                    end
                end
                if not settled then
                    if player.Parent == Players then ev:FireClient(player, "unavailable") end
                    break
                end
            end
        end)
        pending[player.UserId] = nil
        if not ran then warn("PortoKeeper: pending completion will retry: " .. tostring(failure)) end
    end)
end
collected.Event:Connect(processAttempts)

local subscription
task.spawn(function()
    while true do
        if not STUDIO then
            local ok, err = persistence.refresh()
            if ok then applyTitles(); renderCurrent()
            else warn("PortoKeeper: cannot refresh daily winner: " .. tostring(err)) end
            for _, player in ipairs(Players:GetPlayers()) do processAttempts(player) end
            if not subscription then
                local subscribed, result = pcall(MessagingService.SubscribeAsync, MessagingService, TOPIC, function(message)
                    task.spawn(function()
                        local fresh = persistence.refresh()
                        if fresh then
                            applyTitles(); renderCurrent()
                            local rec = Core.current(persistence.snapshot(), os.time(), OFFSET)
                            local live = celebrationGate.remoteRecord(rec, message.Data)
                            if live then announce(live) end
                        end
                    end)
                end)
                if subscribed then subscription = result
                else warn("PortoKeeper: messaging unavailable; polling active: " .. tostring(result)) end
            end
        end
        task.wait(30)
    end
end)
-- Rollover and missing avatars are handled throughout the server's life, not only its first minute.
task.spawn(function()
    while true do renderCurrent(); task.wait(5) end
end)
Players.PlayerAdded:Connect(function() task.defer(applyTitles) end)
Players.PlayerRemoving:Connect(function(player) celebrationGate.forget(player); badgeBusy[player.UserId]=nil; badgeDone[player.UserId]=nil end)
print("PortoKeeper: daily Guardian ready; fresh 44th find, 09:00 UTC boundary, one win per player")
]====]},{name="PortoKeeperClient",path="Workspace.PortoKeeper.PortoKeeperClient",before=[====[-- PortoKeeperClient: a banner and a chat line when someone becomes the Guardian of the Harbour; a quiet note to late finders.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ev = RS:WaitForChild("PortoKeeperEvent")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local function chat(text)
	pcall(function() StarterGui:SetCore("ChatMakeSystemMessage", {Text = text, Color = C(255, 214, 90), Font = Enum.Font.GothamBold, TextSize = 18}) end)
end
local function banner(big, small)
	local pg = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui"); gui.Name = "PortoKeeperBanner"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 26; gui.Parent = pg
	local f = Instance.new("Frame"); f.AnchorPoint = Vector2.new(0.5, 0); f.Position = UDim2.new(0.5, 0, 0, -140); f.Size = UDim2.fromOffset(620, 110)
	f.BackgroundColor3 = C(28, 32, 60); f.BackgroundTransparency = 0.08; f.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 18); corner.Parent = f
	local stroke = Instance.new("UIStroke"); stroke.Color = C(232, 191, 74); stroke.Thickness = 4; stroke.Parent = f
	local t1 = Instance.new("TextLabel"); t1.Size = UDim2.new(1, -30, 0, 54); t1.Position = UDim2.new(0, 15, 0, 10); t1.BackgroundTransparency = 1
	t1.Font = Enum.Font.FredokaOne; t1.TextScaled = true; t1.TextColor3 = C(255, 222, 110); t1.Text = big; t1.Parent = f
	local t2 = Instance.new("TextLabel"); t2.Size = UDim2.new(1, -30, 0, 32); t2.Position = UDim2.new(0, 15, 0, 66); t2.BackgroundTransparency = 1
	t2.Font = Enum.Font.Merriweather; t2.TextScaled = true; t2.TextColor3 = C(255, 246, 220); t2.Text = small; t2.Parent = f
	local sc = Instance.new("UIScale"); sc.Parent = f
	local vw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	sc.Scale = math.min(1, (vw - 24) / 620)
	TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 70)}):Play()
	task.delay(9, function()
		TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -140)}):Play()
		task.wait(0.5); gui:Destroy()
	end)
end
local receipts = {}
ev.OnClientEvent:Connect(function(what, a)
	if what == "crowned" and type(a) == "table" then
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

]====],after=[====[-- PortoKeeperClient: a banner and a chat line when someone becomes the Guardian of the Harbour; a quiet note to late finders.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local TextChatService = game:GetService("TextChatService")
local F = script.Parent
local Celebration = require(F:WaitForChild("KeeperCelebration"))
local daily = workspace:FindFirstChild("Daily")
local OFFSET = daily and daily:GetAttribute("DayOffsetHours") or 9
local celebrationGate = Celebration.new(function() return workspace:GetServerTimeNow() end,
    function(at) return math.floor((at - OFFSET * 3600) / 86400) end)
local ev = RS:WaitForChild("PortoKeeperEvent")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local function chat(text)
    task.spawn(function()
        local ok, err = pcall(function()
            local channels = TextChatService:WaitForChild("TextChannels", 5)
            local channel = channels and channels:WaitForChild("RBXGeneral", 5)
            assert(channel, "RBXGeneral unavailable")
            local safe = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
            channel:DisplaySystemMessage(safe)
        end)
        if not ok then warn("PortoKeeper: chat announcement unavailable: " .. tostring(err)) end
    end)
end
local function showBanner(big, small)
	local pg = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui"); gui.Name = "PortoKeeperBanner"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 26; gui.Parent = pg
	local f = Instance.new("Frame"); f.AnchorPoint = Vector2.new(0.5, 0); f.Position = UDim2.new(0.5, 0, 0, -140); f.Size = UDim2.fromOffset(620, 110)
	f.BackgroundColor3 = C(28, 32, 60); f.BackgroundTransparency = 0.08; f.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 18); corner.Parent = f
	local stroke = Instance.new("UIStroke"); stroke.Color = C(232, 191, 74); stroke.Thickness = 4; stroke.Parent = f
	local t1 = Instance.new("TextLabel"); t1.Size = UDim2.new(1, -30, 0, 54); t1.Position = UDim2.new(0, 15, 0, 10); t1.BackgroundTransparency = 1
	t1.Font = Enum.Font.FredokaOne; t1.TextScaled = true; t1.TextColor3 = C(255, 222, 110); t1.Text = big; t1.Parent = f
	local t2 = Instance.new("TextLabel"); t2.Size = UDim2.new(1, -30, 0, 32); t2.Position = UDim2.new(0, 15, 0, 66); t2.BackgroundTransparency = 1
	t2.Font = Enum.Font.Merriweather; t2.TextScaled = true; t2.TextColor3 = C(255, 246, 220); t2.Text = small; t2.Parent = f
	local sc = Instance.new("UIScale"); sc.Parent = f
	local vw = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 1000
	sc.Scale = math.min(1, (vw - 24) / 620)
	TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 70)}):Play()
	task.delay(9, function()
		TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -140)}):Play()
		task.wait(0.5); gui:Destroy()
	end)
end
local pg = player:WaitForChild("PlayerGui")
local function dailyCardUp()                          -- the daily acorns card is showing (nothing goes on top of it: Shannon)
	local dg = pg:FindFirstChild("DailyGui")
	local dc = dg and dg:FindFirstChild("DailyCard")
	return dc ~= nil and dc:IsA("GuiObject") and dc.Visible and dg.Enabled
end
local function titleBannerUp()                        -- the honours' "You are now a ..." banner (finding all 44 brings both at once)
	local hb = pg:FindFirstChild("HonourBar")
	local b = hb and hb:FindFirstChild("Banner")
	return b ~= nil and b:IsA("GuiObject") and b.Visible
end
local function banner(big, small)
    task.spawn(function()
        local started = os.clock()
        task.wait(0.3)
        while (dailyCardUp() or titleBannerUp()) and os.clock() - started < 90 do task.wait(0.3) end
        showBanner(big, small)
    end)
end

-- France-style fireworks across Italy; cosmetic instances exist only on each client.
-- Surveyed Italy launch sites: {x, z, ground height}; exclude the French maps.
local SITES = {{240,-580,-48.625},{360,-600,-44.0234},{490,-640,-0.8497},
    {250,-800,-52.9219},{370,-810,-40.2748},{490,-840,16.5684},
    {250,-1010,-52.9219},{365,-1070,-52.9219},{490,-1130,1.4023}}
local COLOURS = {C(255, 60, 60), C(255, 150, 40), C(255, 230, 60), C(80, 230, 90), C(60, 220, 255), C(80, 120, 255), C(180, 90, 255), C(255, 90, 200)}
local function sound(id, parent, vol)
	if not id or id == "" then return end
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol; s.RollOffMaxDistance = 700; s.RollOffMinDistance = 40; s.Parent = parent; pcall(function() s:Play() end)
	Debris:AddItem(s, 6)
end
local function threeColours(first)
	local picks, used = {first}, {[first] = true}
	for _ = 1, 30 do
		if #picks >= 3 then break end
		local c = COLOURS[math.random(1, #COLOURS)]
		if not used[c] then used[c] = true; picks[#picks + 1] = c end
	end
	return picks
end
local function rocket(x, z, groundY)
	local colour = COLOURS[math.random(1, #COLOURS)]
	local topY = groundY + math.random(80, 120)
	-- a bright spark going up with only a short, faint wisp behind it (Shannon: "less of a tail traveling up")
	local r = Instance.new("Part"); r.Name = "ItalyFireworkRocket"; r.Shape = Enum.PartType.Ball; r.Size = Vector3.new(0.45, 0.45, 0.45); r.Anchored = true; r.CanCollide = false; r.CanQuery = false; r.CanTouch = false
	r.CastShadow = false; r.Material = Enum.Material.Neon; r.Color = colour; r.CFrame = CFrame.new(x, groundY + 4, z); r.Parent = workspace; Debris:AddItem(r, 5)
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.08, 0); a0.Parent = r
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.08, 0); a1.Parent = r
	local tr = Instance.new("Trail"); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.035; tr.LightEmission = 1; tr.FaceCamera = true
	tr.Color = ColorSequence.new(colour); tr.Transparency = NumberSequence.new(0.7, 1); tr.WidthScale = NumberSequence.new(1, 0); tr.Parent = r
	sound(F:GetAttribute("FireworkLaunch"), r, 0.5)
	local up = TweenService:Create(r, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(x + math.random(-6, 6), topY, z + math.random(-6, 6))})
	up:Play()
	up.Completed:Connect(function()
		local at = r.CFrame
		r.Transparency = 1
		local b = Instance.new("Part"); b.Anchored = true; b.CanCollide = false; b.CanQuery = false; b.CanTouch = false; b.Transparency = 1; b.Size = Vector3.new(1, 1, 1); b.CFrame = at; b.Parent = workspace
		local att = Instance.new("Attachment"); att.Parent = b
		-- three colours in every burst, big bright stars that read against a daytime sky, and a glitter of white
		local picks = threeColours(colour)
		picks[#picks + 1] = C(255, 250, 225)
		for k, col in ipairs(picks) do
			local white = k == #picks
			local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.LightEmission = 1; pe.LightInfluence = 0
			pe.Brightness = 2; pe.Color = ColorSequence.new(col); pe.Speed = NumberRange.new(white and 20 or 34, white and 30 or 52)
			pe.SpreadAngle = Vector2.new(180, 180); pe.Drag = 2.2; pe.Acceleration = Vector3.new(0, -9, 0); pe.Lifetime = NumberRange.new(1.6, 2.6)
			pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, white and 1.4 or 3.2), NumberSequenceKeypoint.new(0.6, white and 1 or 2.2), NumberSequenceKeypoint.new(1, 0)})
			pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0.15), NumberSequenceKeypoint.new(1, 1)})
			pe.Rate = 0; pe.Parent = att; pe:Emit(white and 20 or 34)
		end
		-- and a flash of the main colour as it goes
		local ball = Instance.new("Part"); ball.Shape = Enum.PartType.Ball; ball.Material = Enum.Material.Neon; ball.Color = colour; ball.CastShadow = false
		ball.Anchored = true; ball.CanCollide = false; ball.CanQuery = false; ball.CanTouch = false; ball.Size = Vector3.new(2, 2, 2); ball.Transparency = 0.2; ball.CFrame = at; ball.Parent = workspace
		TweenService:Create(ball, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(14, 14, 14), Transparency = 1}):Play()
		Debris:AddItem(ball, 0.6)
		local light = Instance.new("PointLight"); light.Color = colour; light.Brightness = 6; light.Range = 60; light.Parent = b
		TweenService:Create(light, TweenInfo.new(0.5), {Brightness = 0}):Play()
		sound(F:GetAttribute("FireworkPop"), b, 0.8)
		Debris:AddItem(b, 3); Debris:AddItem(r, 0.7)
	end)
end
local showing = false
local function fireworks(secs)
	if showing then return end
	showing = true
	local id = "rbxassetid://9114447178" -- same show audio as France; visuals do not depend on audio
	if id and id ~= "" then
		local s = Instance.new("Sound"); s.Name = "ItalyFireworkShow"; s.SoundId = id; s.Looped = true; s.Volume = F:GetAttribute("FireworkVolume") or 0.6
		s.Parent = game:GetService("SoundService"); pcall(function() s:Play() end)
		task.delay(secs + 1, function()
			local t = TweenService:Create(s, TweenInfo.new(2), {Volume = 0}); t:Play()
			t.Completed:Connect(function() s:Destroy() end)
		end)
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < secs do
			-- most of the show goes up over whichever map this screen is looking at; now and then one over a far map
			local cam = workspace.CurrentCamera
			local here = cam and cam.CFrame.Position or Vector3.zero
			local order = {}
			for k, st in ipairs(SITES) do order[k] = {s = st, d = (Vector2.new(st[1], st[2]) - Vector2.new(here.X, here.Z)).Magnitude} end
			table.sort(order, function(a, b) return a.d < b.d end)
			for k, chance in ipairs({1, 0.8, 0.55}) do
				if math.random() < chance then local st = order[k].s; rocket(st[1], st[2], st[3]) end
			end
			if math.random() < 0.25 then local st = order[math.random(4, #order)].s; rocket(st[1], st[2], st[3]) end
			task.wait(0.35 + math.random() * 0.2)
		end
		showing = false
	end)
end


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

]====]}}
local moduleSource=[====[-- Cosmetic event guards only. No services, award decisions, or saved-data changes.
local Celebration = {}
Celebration.VERSION = 1
Celebration.MAX_DELAY = 120

function Celebration.new(clock, day)
    local startedAt = clock()
    local seen, fresh = {}, {}
    local api = {}
    function api.markFresh(player, rec)
        if type(rec) ~= "table" or rec.uid ~= player.UserId or type(rec.claimId) ~= "string" then return end
        fresh[player] = fresh[player] or {}
        fresh[player][rec.claimId] = true
    end
    function api.forget(player) fresh[player] = nil end
    function api.allows(rec)
        if type(rec) ~= "table" or type(rec.claimId) ~= "string" or seen[rec.claimId]
            or rec.celebrationVersion ~= Celebration.VERSION or type(rec.celebrationAt) ~= "number" then return false end
        local now, at = clock(), rec.celebrationAt
        return at == at and at >= startedAt and at <= now + 5 and now - at <= Celebration.MAX_DELAY
            and rec.day == day(now)
    end
    function api.mark(rec) seen[rec.claimId] = true end
    function api.accept(rec)
        if not api.allows(rec) then return false end
        api.mark(rec)
        return true
    end
    function api.localRecord(player, rec)
        if type(rec) ~= "table" or rec.uid ~= player.UserId or not fresh[player] or not fresh[player][rec.claimId] then return nil end
        local result = {}
        for k, v in pairs(rec) do result[k] = v end
        result.celebrationVersion = Celebration.VERSION
        result.celebrationAt = clock()
        return api.allows(result) and result or nil
    end
    function api.remoteRecord(rec, message)
        if type(rec) ~= "table" or type(message) ~= "table" or rec.claimId ~= message.claimId then return nil end
        local result = {}
        for k, v in pairs(rec) do result[k] = v end
        result.celebrationVersion = message.celebrationVersion
        result.celebrationAt = message.celebrationAt
        return api.allows(result) and result or nil
    end
    return api
end
return Celebration
]====]
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"Edit only")
assert(game.GameId==10766369535 and game.PlaceId==117372258657114,"Exact LIVE universe/place required")
assert(workspace:GetAttribute("PrivateTestCopy")~=true,"Private test copy prohibited")
local function norm(s)return (s:gsub("\r\n","\n"))end
local function resolve(path)
 local x=game;for name in path:gmatch("[^%.]+")do x=assert(x:FindFirstChild(name),path)end;return x
end
local changes=0
for _,row in ipairs(rows)do
 row.target=resolve(row.path);assert(row.target:IsA("Script") and row.target.Enabled)
 row.original=row.target.Source;row.skip=norm(row.original)==norm(row.after)
 assert(row.skip or norm(row.original)==norm(row.before),"Source changed: "..row.path)
 assert(loadstring(row.after),"Compile failed: "..row.name)
 if not row.skip then changes+=1 end
end
assert(loadstring(moduleSource),"Guard module compile failed")
local existing=workspace.PortoKeeper:FindFirstChild("KeeperCelebration")
if changes==0 and existing then
 assert(existing:IsA("ModuleScript") and norm(existing.Source)==norm(moduleSource),"Module differs")
 return game:GetService("HttpService"):JSONEncode({alreadyInstalled=true,sourceChanges=0})
end
assert(changes==3 and not existing,"Partial install; inspect")
local ss=game:GetService("ServerStorage")
local backupName="PortoCelebrationBackup_20261014"
assert(not ss:FindFirstChild(backupName),"Backup exists; inspect")
local backup=Instance.new("Folder");backup.Name=backupName;backup.Parent=ss
for _,row in ipairs(rows)do local saved=row.target:Clone();saved.Enabled=false;saved.Parent=backup end
local module=Instance.new("ModuleScript");module.Name="KeeperCelebration";module.Source=moduleSource
local ok,err=pcall(function()
 module.Parent=workspace.PortoKeeper
 for _,row in ipairs(rows)do row.target.Source=row.after end
end)
if not ok then
 for _,row in ipairs(rows)do row.target.Source=row.original end
 module:Destroy();error(err)
end
return game:GetService("HttpService"):JSONEncode({installed=true,sourceChanges=3,newModules=1,backup=backup:GetFullName(),universeId=game.GameId,placeId=game.PlaceId,published=false,checkedUtc=os.date("!%Y-%m-%dT%H:%M:%SZ")})
