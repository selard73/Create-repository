-- HallServer (workspace.HallOfGuardians): the Belvedere dei Guardiani on the Prato dei Fiori, round 6 - the French display
-- concept in the Italian style (Shannon, Oct 14: "when I said make it different, I meant the same display concept, just a
-- different model or style"): ONE pedestal in the centre of the crescent, one Guardian of the Harbour at a time, the newest
-- first, Older / Newer buttons, a plaque with name, date and count, everyone on the lectern roll. France's mechanism
-- (workspace.HallOfFame): this server makes each statue once (Champion.MakeStatue, the same marble figure as every other statue
-- in the game, the acorn swapped for the harbour key), out of sight below the terrace, keeps it in ReplicatedStorage.HallStatues
-- and hands its name to whoever asks (HallStatue); HallClient clones the one it shows into a folder of its own, so every player
-- scrolls their own view. The Guardian list is READ from the Guardian's own store (PortoKeeper_v1: the historical "first" record
-- and Codex's daily ledger "daily_v2"), once a minute and again whenever the lighthouse plaque names a new winner, and published
-- to the clients as the folder's HallJson attribute. Nothing here ever writes a DataStore; Codex's PortoKeeperServer is untouched.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DSS = game:GetService("DataStoreService")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local STUDIO = RunService:IsStudio()
local CH = workspace:WaitForChild("Champion", 60)
local makeStatue = CH and CH:WaitForChild("MakeStatue", 60)
local K = workspace:WaitForChild("PortoKeeper", 60)
local fn = F:WaitForChild("HallStatue")
local function num(name, default) local v = tonumber(F:GetAttribute(name)); return v or default end
local SPOT, LOOK = F:GetAttribute("Spot"), F:GetAttribute("Look")       -- the pedestal's top centre; the way the statue faces
if typeof(SPOT) ~= "Vector3" then SPOT = Vector3.new() end
if typeof(LOOK) ~= "Vector3" then LOOK = Vector3.new(0, 0, -1) end
local DROP = 300                                                       -- statues are made this far below the terrace, out of sight
local C = Color3.fromRGB
local GOLD, GOLD_D, GOLD_DD = C(255, 206, 64), C(214, 160, 44), C(190, 136, 40)

-- ---- the Guardian list, read from the Guardian's own store ----
-- PortoKeeper_v1 "first" = the historical first Guardian (Darkknight, Oct 11 2026; read-only for everyone, Codex's rule too);
-- PortoKeeper_v1 "daily_v2" = Codex's ledger {version = 2, days = {[dayIndex] = rec}, winners = {[uid] = rec}, ...} with
-- rec = {uid, name, t, day, claimId, epoch, total, durable}; one Guardian per 09:00 UTC day. The hall's order: the first
-- Guardian is No. 1, then every day's Guardian in day order. Reads only; never a write.
local store
if not STUDIO then pcall(function() store = DSS:GetDataStore("PortoKeeper_v1") end) end
local getOptions = Instance.new("DataStoreGetOptions"); getOptions.UseCache = false
local current = {}                                                     -- the last list read (kept while the store is unreachable)
local function compose(first, daily)
	local out, seen = {}, {}
	if type(first) == "table" and tonumber(first.uid) then
		table.insert(out, {no = 1, uid = tonumber(first.uid), name = first.name, user = first.user, t = tonumber(first.t), total = first.total, legacy = true})
		seen[tostring(first.uid)] = true
	end
	if type(daily) == "table" and type(daily.days) == "table" then
		local days = {}
		for k, rec in pairs(daily.days) do
			if type(rec) == "table" and tonumber(rec.uid) and tonumber(k) then table.insert(days, {d = tonumber(k), rec = rec}) end
		end
		table.sort(days, function(a, b) return a.d < b.d end)
		for _, e in ipairs(days) do
			local rec = e.rec
			if not seen[tostring(rec.uid)] then
				seen[tostring(rec.uid)] = true
				table.insert(out, {no = #out + 1, uid = tonumber(rec.uid), name = rec.name, user = rec.user, t = tonumber(rec.t), day = e.d, total = rec.total})
			end
		end
	end
	return out
end
local function readStore()                                             -- true when the list was read (and `current` is fresh)
	if STUDIO then                                                     -- a Studio test of the ledger reading: the folder's TestLedger = JSON {first = rec, daily = the daily_v2 state}
		local okT, tl = pcall(function() return HttpService:JSONDecode(F:GetAttribute("TestLedger") or "") end)
		if okT and type(tl) == "table" then current = compose(tl.first, tl.daily); return true end
		return false
	end
	if not store then return false end
	local ok, first, daily = pcall(function() return store:GetAsync("first", getOptions), store:GetAsync("daily_v2", getOptions) end)
	if not ok then warn("HallOfGuardians: cannot read the Guardian store: " .. tostring(first)); return false end
	current = compose(first, daily)
	return true
end
local function list()
	local out = {}
	for _, e in ipairs(current) do table.insert(out, e) end
	-- a play-test PREVIEW in Studio (no store there): the folder's PreviewJson stands in, so the belvedere can be seen with statues
	if #out == 0 and STUDIO then
		local okP, pv = pcall(function() return HttpService:JSONDecode(F:GetAttribute("PreviewJson") or "[]") end)
		if okP and type(pv) == "table" then for _, e in ipairs(pv) do if type(e) == "table" and e.uid then table.insert(out, e) end end end
	end
	for i, e in ipairs(out) do if not tonumber(e.no) then e.no = i end end
	return out
end
local function entry(no) for _, e in ipairs(list()) do if tonumber(e.no) == no then return e end end return nil end
local function publish()                                               -- the list for every client, in order
	local out = {}
	for _, e in ipairs(list()) do table.insert(out, {no = e.no, uid = e.uid, name = e.name, day = e.day, t = e.t, total = e.total}) end
	local ok, s = pcall(function() return HttpService:JSONEncode(out) end)
	if ok then F:SetAttribute("HallJson", s) end
end

-- ---- the key (the PortoKeeper's own shape) ----
local function part(name, size, color, shape, parent)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = color; p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local KEY_H = 3.6
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
		if p:IsA("BasePart") and p.Transparency < 0.95 then
			local h = p.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
			end end end
		end
	end
	return lo, hi
end
local function makeKey(height, x, bottomY, z, yaw, parent)            -- a key `height` tall standing with its bottom at (x, bottomY, z)
	local s = height / KEY_H
	local k = Instance.new("Model"); k.Name = "Key"
	local pose = keyPose(s)
	for name, d in pairs(pose) do local p = part(name, d[2], d[3], d[4], k); p.CFrame = d[1] end
	local lo = extents(k)
	local base = CFrame.new(x, bottomY - lo.Y, z) * CFrame.Angles(0, yaw, 0)
	for name, d in pairs(pose) do k[name].CFrame = base * d[1] end
	k.WorldPivot = CFrame.new(x, bottomY + height / 2, z)
	k.Parent = parent
	return k
end
local KEY_YAW = math.atan2(LOOK.X, LOOK.Z) + math.pi

-- ---- the statues: made once each, kept in ReplicatedStorage.HallStatues, handed over by name ----
local storeFolder = RS:FindFirstChild("HallStatues")
if not storeFolder then storeFolder = Instance.new("Folder"); storeFolder.Name = "HallStatues"; storeFolder.Parent = RS end
for _, o in ipairs(storeFolder:GetChildren()) do o:Destroy() end
local function feetLow(m)                                              -- the lowest corner of the visible feet (never the invisible root)
	local low = math.huge
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name == "LeftFoot" or d.Name == "RightFoot") and d.Transparency < 0.95 then
			local h = d.Size / 2
			for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
				low = math.min(low, (d.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
			end end end
		end
	end
	if low == math.huge then local cf, s = m:GetBoundingBox(); low = cf.Y - s.Y / 2 end
	return low
end
local cache, used, busy, building = {}, {}, {}, false
local function build(no)
	if cache[no] and cache[no].Parent then used[no] = os.clock(); return cache[no] end
	while busy[no] do task.wait(0.2) end
	if cache[no] and cache[no].Parent then return cache[no] end
	local e = entry(no)
	if not e or not makeStatue then return nil end
	busy[no] = true
	while building do task.wait(0.2) end
	building = true
	local stage = F:FindFirstChild("Staging")
	if not stage then stage = Instance.new("Folder"); stage.Name = "Staging"; stage.Parent = F end
	local low = Vector3.new(SPOT.X, SPOT.Y - DROP, SPOT.Z)
	local ok, fig, acorn = pcall(function()
		return makeStatue:Invoke({uid = e.uid, name = e.name, no = e.no, day = e.day}, {x = low.X, top = low.Y, z = low.Z, parent = stage, name = "Figure", scale = num("Scale", 1.35), look = LOOK})
	end)
	if acorn then acorn:Destroy() end
	local m
	if ok and fig then
		m = Instance.new("Model"); m.Name = "No_" .. tostring(no)
		fig.Parent = m
		-- the harbour key in the raised hand, sized to the figure as the PortoKeeper does it
		local holdSide = (CH:GetAttribute("HoldHand") == "Right") and "Right" or "Left"
		local hand = fig:FindFirstChild(holdSide .. "Hand")
		local lo, hi = extents(fig)
		local h = math.clamp((hi.Y - lo.Y) * num("KeyShare", 0.42), 1.5, 6)
		if hand then makeKey(h, hand.Position.X, hand.Position.Y + hand.Size.Y / 2 - 0.15, hand.Position.Z, KEY_YAW, m)
		else makeKey(h, low.X, hi.Y, low.Z, KEY_YAW, m) end
		m.WorldPivot = (m:GetBoundingBox())
		-- on its feet in the middle of the pedestal, then up out of the ground
		local cf = m:GetBoundingBox()
		m:PivotTo(m:GetPivot() + Vector3.new(low.X - cf.X, low.Y - feetLow(m), low.Z - cf.Z) + Vector3.new(0, DROP, 0))
		m.Parent = storeFolder
		cache[no] = m; used[no] = os.clock()
		local n = 0
		for _ in pairs(cache) do n += 1 end
		if n > 40 then                                                  -- the forty seen most recently are kept
			local oldest, ot
			for k, t in pairs(used) do if cache[k] and (not ot or t < ot) then oldest, ot = k, t end end
			if oldest and oldest ~= no then cache[oldest]:Destroy(); cache[oldest] = nil; used[oldest] = nil end
		end
	else
		warn("HallOfGuardians: no statue for No. " .. tostring(no) .. ": " .. tostring(fig))
		local half = stage:FindFirstChild("Figure"); if half then half:Destroy() end
	end
	building = false
	busy[no] = nil
	return m
end
fn.OnServerInvoke = function(player, no)
	no = tonumber(no)
	if not no then return nil end
	local m = build(math.floor(no))
	return m and m.Name or nil
end

-- ---- the waiting key, the roll, the refresh ----
local function refreshView()
	local l = list()
	local waiting = F:FindFirstChild("WaitingKey")
	if #l == 0 and not waiting then
		local k = makeKey(num("RestKeyHeight", 2.6), SPOT.X, SPOT.Y, SPOT.Z, KEY_YAW, F); k.Name = "WaitingKey"
	elseif #l > 0 and waiting then
		waiting:Destroy()
	end
	local total = (K and tonumber(K:GetAttribute("Need"))) or tonumber(F:GetAttribute("Total")) or 44
	local lect = F:FindFirstChild("Lectern")
	local words = lect and lect:FindFirstChild("Plaque") and lect.Plaque:FindFirstChild("Words")
	if words then
		if #l == 0 then
			words.Roll.Text = "No Guardian yet. Be the first to find all " .. tostring(total) .. " squirrels of Porto Nocciola and your statue will stand here, holding the harbour key."
		else
			local names, from = {}, math.max(1, #l - 5)
			for i = from, #l do table.insert(names, tostring(l[i].no) .. ".\u{A0}" .. tostring(l[i].name or "?")) end   -- (a non-breaking space: the number stays with the name)
			words.Roll.Text = ((from > 1) and (tostring(from - 1) .. " more, then ") or "") .. table.concat(names, "   ")
		end
	end
	if #l > 0 then task.spawn(build, l[#l].no) end                        -- the newest made ahead of anyone asking
end
local lastSig
local function signature()
	local parts = {}
	for _, e in ipairs(list()) do table.insert(parts, tostring(e.no) .. "=" .. tostring(e.uid)) end
	return table.concat(parts, ",")
end
local function refresh()
	readStore()
	local sig = signature()
	if sig ~= lastSig then lastSig = sig; publish(); refreshView() end
end
F:GetAttributeChangedSignal("Rebuild"):Connect(function()             -- a forced redo: the made statues are dropped and the list read again
	for _, m in pairs(cache) do if m then m:Destroy() end end
	cache, used = {}, {}
	lastSig = nil
	task.defer(refresh)
end)
task.spawn(function()
	for attempt = 1, 5 do
		if readStore() or not store then break end
		task.wait(2 * attempt)
	end
	refresh()
	print(string.format("HallOfGuardians: ready - %d Guardians on the roll, one at a time on the belvedere", #list()))
	while true do
		task.wait(num("PollSecs", 60))
		refresh()
	end
end)
task.spawn(function()                                                  -- 3 s after the lighthouse plaque names a new winner: read again
	local plinth = K and K:WaitForChild("Plinth", 30)
	local plaque = plinth and plinth:WaitForChild("Plaque", 30)
	local words = plaque and plaque:WaitForChild("Words", 30)
	local who = words and words:WaitForChild("Who", 30)
	if who then who:GetPropertyChangedSignal("Text"):Connect(function() task.delay(3, refresh) end) end
end)
