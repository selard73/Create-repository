from pathlib import Path
p = Path(__file__).parent / "make_squirrel_scripts.py"
s = p.read_text(encoding="utf-8")

old = '''-- 4. finds
local found = {}          -- userId -> { [id] = true }
local function foundList(player)
	local t = found[player.UserId]
	if not t then t = {}; found[player.UserId] = t end
	return t
end
local function count(t) local n = 0 for _ in pairs(t) do n += 1 end return n end
sync.OnServerInvoke = function(player)
	local list = {}
	if PER_PLAYER then
		for id in pairs(foundList(player)) do table.insert(list, id) end
	else'''
new = '''-- 4. finds, saved per player in a DataStore so they survive leaving and rejoining
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
local function foundList(player)
	local t = found[player.UserId]
	if not t then t = {}; found[player.UserId] = t end
	return t
end
local function count(t) local n = 0 for _ in pairs(t) do n += 1 end return n end
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
			local t = foundList(player)
			if type(data) == "table" and type(data.found) == "table" then
				for _, id in ipairs(data.found) do t[id] = true end
			end
			print(string.format("SquirrelSetup: loaded %d saved finds for %s", count(t), player.Name))
		else
			canSave[uid] = false
			warn("SquirrelSetup: could not load finds for " .. player.Name .. " (" .. tostring(data) .. "); this session will not be saved")
		end
	end
	loaded[uid] = true
	player:SetAttribute("SquirrelsFound", count(foundList(player)))
end
local function savePlayer(player)
	local uid = player.UserId
	if not store or not canSave[uid] or not loaded[uid] then return end
	local list = {}
	for id in pairs(foundList(player)) do table.insert(list, id) end
	local ok, err = pcall(function()
		store:UpdateAsync("u" .. uid, function(old)
			-- merge with whatever is already saved, so two servers never erase each other's finds
			local merged = {}
			if type(old) == "table" and type(old.found) == "table" then for _, id in ipairs(old.found) do merged[id] = true end end
			for _, id in ipairs(list) do merged[id] = true end
			local out = {}
			for id in pairs(merged) do table.insert(out, id) end
			return {found = out, updated = os.time()}
		end)
	end)
	if ok then dirty[uid] = nil else warn("SquirrelSetup: save failed for " .. player.Name .. ": " .. tostring(err)) end
end
Players.PlayerAdded:Connect(loadPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadPlayer, player) end
Players.PlayerRemoving:Connect(function(player)
	if dirty[player.UserId] then savePlayer(player) end
	task.delay(5, function() found[player.UserId] = nil; loaded[player.UserId] = nil; canSave[player.UserId] = nil; dirty[player.UserId] = nil end)
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
	else'''
assert old in s; s = s.replace(old, new)

old = '''	if PER_PLAYER then
		local t = foundList(player)
		if t[id] then return end
		t[id] = true
		player:SetAttribute("SquirrelsFound", count(t))
		ev:FireClient(player, id)                      -- only this player sees it turn to colour'''
new = '''	if PER_PLAYER then
		local t = foundList(player)
		if t[id] then return end
		t[id] = true
		dirty[player.UserId] = true
		player:SetAttribute("SquirrelsFound", count(t))
		ev:FireClient(player, id)                      -- only this player sees it turn to colour'''
assert old in s; s = s.replace(old, new)

# the old PlayerAdded / initial attribute lines are superseded
old = '''Players.PlayerAdded:Connect(function(player) player:SetAttribute("SquirrelsFound", 0) end)
for _, player in ipairs(Players:GetPlayers()) do player:SetAttribute("SquirrelsFound", count(foundList(player))) end
'''
assert old in s; s = s.replace(old, '')
p.write_text(s, encoding="utf-8"); print("patched")
