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
