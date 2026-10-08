-- CameraServer (workspace.PhotoGame): the postcard camera at Porto Nocciola (Oct 8 2026, Shannon: "buy a CAMERA in the acorn
-- shop; the activities list photos to take ... the player takes the photo, then SELLS the photos to the Postcard Squirrel").
-- Her picks: camera 50 acorns; photos 20 each, the whale 40; one of each in your bag at a time (sell, then shoot again);
-- the whale's spout lasts 5 s (PortoWhale SpoutSecs). CameraClient frames the shot and names what it caught; this script
-- checks it could be true (you own and hold the camera, you are near enough, the whale really is spouting) and keeps the
-- ledger through AwardItems / AwardAcorns: Item_camera (bought in the Acorn Store), Item_photo_<id> (in your bag, 0 or 1),
-- Item_photosold_<id> (lifetime). The progress save is never touched from here.
-- v3 (Oct 8 late, Shannon: "I want it to actually show the photos"): the bag only COUNTS photos, so where each one was taken
-- (camera spot, look, zoom, and where the whale / pizza were) is kept in this script's OWN small store, PhotoAlbum_v1
-- (key u<userId>), so the album can take the same picture again after a rejoin. Studio never reads or writes it; a player
-- whose album could not be read is never saved over.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local G = script.Parent
local kit = RS:WaitForChild("PhotoGame")
local ev = kit:WaitForChild("PhotoEvent")
local Subjects = require(kit:WaitForChild("Subjects"))
local awardAcorns = RS:WaitForChild("AwardAcorns")
local awardItems = RS:WaitForChild("AwardItems")
local TOOL = "Camera"
local function num(name, default) local v = G:GetAttribute(name) return type(v) == "number" and v or default end

-- ---------- the camera rides in the hotbar, like the crab trap (Item_stow_camera = put away from the Acorn Store) ----------
local function giveCamera(p)
	local own = (p:GetAttribute("Item_camera") or 0) > 0
	local stowed = (p:GetAttribute("Item_stow_camera") or 0) > 0
	local char = p.Character
	local pack = p:FindFirstChildOfClass("Backpack")
	local have = (pack and pack:FindFirstChild(TOOL)) or (char and char:FindFirstChild(TOOL))
	if own and not stowed then
		if have or not char then return end
		local tmpl = SS:FindFirstChild("CameraTool")
		if not tmpl then warn("CameraServer: no ServerStorage.CameraTool") return end
		local t = tmpl:Clone() t.Name = TOOL
		t.Parent = pack or p
	elseif have then
		have:Destroy()
	end
end
local function watch(p)
	p.CharacterAdded:Connect(function() task.wait(0.6) giveCamera(p) end)
	p:GetAttributeChangedSignal("Item_camera"):Connect(function() giveCamera(p) end)
	p:GetAttributeChangedSignal("Item_stow_camera"):Connect(function() giveCamera(p) end)
	if p.Character then task.defer(giveCamera, p) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- ---------- the whale's timetable, worked out exactly as its WhaleClient does (same route, speed, pauses, server clock) ----------
local whale = workspace:FindFirstChild("PortoWhale")
local W
local function buildWhale()
	if not whale then return nil end
	local function wn(name, d) local v = whale:GetAttribute(name) return typeof(v) == "number" and v or d end
	local route = {}
	for x, z in string.gmatch(whale:GetAttribute("Route") or "", "([-%d%.]+),([-%d%.]+)") do table.insert(route, Vector3.new(tonumber(x), 0, tonumber(z))) end
	local n = #route
	if n < 3 then return nil end
	local blowIdx = {}
	for i in string.gmatch(whale:GetAttribute("BlowAt") or "1", "%d+") do blowIdx[tonumber(i)] = true end
	local function P(i) return route[((i - 1) % n) + 1] end
	local function cr(i, u)
		local p0, p1, p2, p3 = P(i - 1), P(i), P(i + 1), P(i + 2)
		local u2, u3 = u * u, u * u * u
		return 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (-p0 + 3 * p1 - 3 * p2 + p3) * u3)
	end
	local stations, acc, first, last = {}, 0, nil, nil
	for i = 1, n do
		if blowIdx[i] then table.insert(stations, {s = acc, pos = route[i]}) end
		for k = 0, 23 do
			local p = cr(i, k / 24)
			if last then acc += (p - last).Magnitude end
			last = p; first = first or p
		end
	end
	acc += (first - last).Magnitude
	if #stations == 0 then stations = {{s = 0, pos = route[1]}} end
	table.sort(stations, function(a, b) return a.s < b.s end)
	local BLOW, SPEED = wn("BlowDur", 12), wn("Speed", 7)
	local segs, T = {}, 0
	for k, st in ipairs(stations) do
		table.insert(segs, {t0 = T, pos = st.pos}) T += BLOW
		local s2 = (stations[k + 1] and stations[k + 1].s) or (stations[1].s + acc)
		local dur = (s2 - st.s) / SPEED
		if dur > 0.01 then T += dur end
	end
	return {segs = segs, T = T, lag = wn("TimeLag", 0), y = wn("WaterY", -52.9)}
end
-- where the whale is spouting now (with a second's grace either side for the network), or nil
local function spoutAt()
	W = W or buildWhale()
	if not W then return nil end
	local spout = (whale and whale:GetAttribute("SpoutSecs")) or 2
	local t = (workspace:GetServerTimeNow() - W.lag) % W.T
	for _, sg in ipairs(W.segs) do
		local bt = t - sg.t0
		if bt >= 2 - 1 and bt < 2 + spout + 1.5 then return Vector3.new(sg.pos.X, W.y, sg.pos.Z) end
	end
	return nil
end

local function centreOf(name)
	local m = workspace:FindFirstChild(name)
	if not (m and m:IsA("Model")) then return nil end
	return m:GetBoundingBox().Position
end
-- could this player have taken this picture from where they stand?
local function plausible(s, pos)
	if s.id == "whale" then
		local at = spoutAt()
		if not at then return false, "spout" end
		return (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(at.X, 0, at.Z)).Magnitude <= num("WhaleMaxDist", 300) + 40, "far"
	end
	local reach = num("MaxDist", 45) + 20
	for _, name in ipairs({s.model, s.model2}) do
		local c = centreOf(name)
		if not c or (c - pos).Magnitude > reach then return false, "far" end
	end
	return true
end

-- ---------- THE ALBUM'S PICTURES (v3): where each kept photo was taken, in PhotoAlbum_v1 ----------
local STUDIO = RunService:IsStudio()
local store
if not STUDIO then
	local ok, err = pcall(function() store = DataStoreService:GetDataStore("PhotoAlbum_v1") end)
	if not ok then warn("CameraServer: no album store (" .. tostring(err) .. ")") end
end
local albums, loaded, dirty = {}, {}, {}
local function fin(n, lim) return type(n) == "number" and n == n and math.abs(n) <= lim end
local function vec3(t, lim) return type(t) == "table" and fin(t[1], lim) and fin(t[2], lim) and fin(t[3], lim) end
local function cf12(t)
	if type(t) ~= "table" then return false end
	for i = 1, 12 do if not fin(t[i], 1e5) then return false end end
	return true
end
local function rnd(n, k) local m = 10 ^ k return math.floor(n * m + 0.5) / m end
-- a photo's record, checked and trimmed (kind = what it was kept as; trusted = read back from the store)
local function clean(m, kind, trusted)
	if type(m) ~= "table" then return nil end
	local k = m.k
	if type(k) ~= "string" or #k < 4 or #k > 16 or k:find("[^%w]") then return nil end
	kind = kind or m.id
	if type(kind) ~= "string" or not (kind == "view" or Subjects.byId[kind]) then return nil end
	if not (vec3(m.p, 1e5) and vec3(m.l, 2) and fin(m.f, 200)) then return nil end
	if Vector3.new(m.l[1], m.l[2], m.l[3]).Magnitude < 0.5 then return nil end
	local out = {k = k, id = kind, t = (trusted and fin(m.t, 1e11)) and m.t or os.time(),
		p = {rnd(m.p[1], 2), rnd(m.p[2], 2), rnd(m.p[3], 2)}, l = {rnd(m.l[1], 3), rnd(m.l[2], 3), rnd(m.l[3], 3)}, f = rnd(math.clamp(m.f, 5, 120), 1)}
	if type(m.x) == "table" then
		local x = {}
		if cf12(m.x.w) then x.w = {} for i = 1, 12 do x.w[i] = rnd(m.x.w[i], 3) end end
		if cf12(m.x.z) then x.z = {} for i = 1, 12 do x.z[i] = rnd(m.x.z[i], 3) end end
		if m.x.sp == true and x.w then x.sp = true end
		if next(x) then out.x = x end
	end
	return out
end
local function sendAlbum(p) if p.Parent then ev:FireClient(p, "album", albums[p] or {}) end end
-- keep only as many pictures of each kind as the bag holds (the newest ones)
local function prune(p)
	local list = albums[p]
	if not list then return end
	table.sort(list, function(a, b) return a.t > b.t end)
	local keep, seen = {}, {}
	for _, m in ipairs(list) do
		local have = m.id == "view" and (p:GetAttribute("Item_photo_view") or 0) or (p:GetAttribute("Item_photo_" .. m.id) or 0)
		seen[m.id] = (seen[m.id] or 0) + 1
		if seen[m.id] <= have then table.insert(keep, m) end
	end
	table.sort(keep, function(a, b) return a.t < b.t end)
	albums[p] = keep
end
local function changed(p)                                          -- after the bag has caught up with the change
	task.delay(0.3, function()
		if not p.Parent then return end
		prune(p); dirty[p] = true; sendAlbum(p)
	end)
end
local function loadAlbum(p)
	albums[p] = albums[p] or {}
	if not store then loaded[p] = true; sendAlbum(p) return end
	for attempt = 1, 3 do
		local ok, data = pcall(function() return store:GetAsync("u" .. p.UserId) end)
		if ok then
			if type(data) == "table" and type(data.photos) == "table" then
				for i, m in ipairs(data.photos) do
					if i > 12 then break end
					local c = clean(m, nil, true)
					if c then table.insert(albums[p], c) end
				end
			end
			loaded[p] = true
			break
		end
		if not p.Parent then return end
		task.wait(2 * attempt)
	end
	if not loaded[p] then warn("CameraServer: could not read the album of " .. p.Name .. " - it won't be saved this visit") end
	sendAlbum(p)
end
local function saveAlbum(p)
	if not (store and loaded[p] and dirty[p]) then return end
	dirty[p] = nil
	local rec = {v = 1, photos = albums[p] or {}, updated = os.time()}
	local ok, err = pcall(function() store:SetAsync("u" .. p.UserId, rec) end)
	if not ok then dirty[p] = true; warn("CameraServer: album save failed (" .. tostring(err) .. ")") end
end
Players.PlayerAdded:Connect(function(p) task.spawn(loadAlbum, p) end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(loadAlbum, p) end
task.spawn(function()
	while true do
		task.wait(15)
		local list = {}
		for p in pairs(dirty) do table.insert(list, p) end
		for _, p in ipairs(list) do if p.Parent then task.spawn(saveAlbum, p) end end
	end
end)
game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(saveAlbum, p) end
	task.wait(2)
end)

local lastShot, busy = {}, {}
ev.OnServerEvent:Connect(function(p, what, id, meta)
	if what == "album?" then if loaded[p] or not store then sendAlbum(p) end return end
	if what ~= "shot" then return end
	local key = type(meta) == "table" and type(meta.k) == "string" and #meta.k <= 16 and meta.k or nil
	-- THE ALBUM (Shannon, Oct 8: "if you take a photo you don't want you can delete it; slots for up to 4 - to take another you
	-- have to sell or delete one"): every photo takes a slot - a postcard (Item_photo_<id>) or just a view (Item_photo_view)
	local function used()
		local n = p:GetAttribute("Item_photo_view") or 0
		for _, x in ipairs(Subjects) do n += p:GetAttribute("Item_photo_" .. x.id) or 0 end
		return n
	end
	-- remember where it was taken - only from about where the player stands
	local function keep(kind)
		local c0 = p.Character
		local r0 = c0 and c0:FindFirstChild("HumanoidRootPart")
		local m = clean(meta, kind, false)
		if m and r0 and (Vector3.new(m.p[1], m.p[2], m.p[3]) - r0.Position).Magnitude <= 30 then
			albums[p] = albums[p] or {}
			for i = #albums[p], 1, -1 do if albums[p][i].k == m.k then table.remove(albums[p], i) end end
			table.insert(albums[p], m)
		end
		changed(p)
	end
	if id == "view" then
		local c0 = p.Character
		if (p:GetAttribute("Item_camera") or 0) < 1 or not (c0 and c0:FindFirstChild(TOOL)) then return end
		if used() >= num("Slots", 4) then ev:FireClient(p, "full", id, key) return end
		awardItems:Fire(p, "photo_view", 1)
		ev:FireClient(p, "kept", id, used() + 1, key)
		keep("view")
		return
	end
	local now = os.clock()
	if now - (lastShot[p] or 0) < num("Cooldown", 0.8) * 0.8 then return end
	lastShot[p] = now
	local s = type(id) == "string" and Subjects.byId[id]
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not s or not root then return end
	if (p:GetAttribute("Item_camera") or 0) < 1 or not char:FindFirstChild(TOOL) then return end
	local ok = plausible(s, root.Position)
	if not ok then ev:FireClient(p, "nope", id, key) return end
	if (p:GetAttribute("Item_photo_" .. id) or 0) >= 1 then ev:FireClient(p, "have", id, key) return end
	if used() >= num("Slots", 4) then ev:FireClient(p, "full", id, key) return end
	awardItems:Fire(p, "photo_" .. id, 1)
	ev:FireClient(p, "got", id, key)
	keep(id)
end)

-- ---------- deleting a photo from the album (key = which picture; older photos have none) ----------
ev.OnServerEvent:Connect(function(p, what, id, key)
	if what ~= "delete" or type(id) ~= "string" then return end
	local item = (id == "view" and "photo_view") or (Subjects.byId[id] and ("photo_" .. id))
	if item and (p:GetAttribute("Item_" .. item) or 0) > 0 then
		awardItems:Fire(p, item, -1)
		if type(key) == "string" and albums[p] then
			for i = #albums[p], 1, -1 do if albums[p][i].k == key then table.remove(albums[p], i) end end
		end
		ev:FireClient(p, "deleted", id)
		changed(p)
	end
end)

-- ---------- THE POSTCARD SQUIRREL BUYS THEM (a prompt by him; each client shows it only while it has photos) ----------
local prompt = G:WaitForChild("SellSpot"):WaitForChild("SellPrompt")
prompt.Triggered:Connect(function(p)
	if busy[p] then return end
	busy[p] = true
	local sold, pay, all = {}, 0, true
	for _, s in ipairs(Subjects) do
		local n = p:GetAttribute("Item_photo_" .. s.id) or 0
		local before = p:GetAttribute("Item_photosold_" .. s.id) or 0
		if n >= 1 then
			awardItems:Fire(p, "photo_" .. s.id, -n)
			awardItems:Fire(p, "photosold_" .. s.id, 1)
			pay += num(s.pay, s.id == "whale" and 40 or 20)
			table.insert(sold, s.id)
			before += 1
		end
		if before < 1 then all = false end
	end
	if #sold > 0 then
		awardAcorns:Fire(p, pay)                                   -- same ledger the shop spends from
		p:SetAttribute("Acorns", (p:GetAttribute("Acorns") or 0) + pay)
		if all then                                                 -- every postcard has been sold at least once: the Passport stamp
			local passport = RS:FindFirstChild("PassportActivity")
			if passport then passport:Fire(p, "photos", {prize = pay}) end
		end
		changed(p)
	end
	busy[p] = nil
	ev:FireClient(p, "sold", sold, pay, all and #sold > 0)
end)
Players.PlayerRemoving:Connect(function(p)
	lastShot[p] = nil busy[p] = nil
	saveAlbum(p)
	albums[p] = nil; loaded[p] = nil; dirty[p] = nil
end)
print("CameraServer: ready - four postcards, the Postcard Squirrel is buying" .. (STUDIO and " (album store off in Studio)" or ""))
