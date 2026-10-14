-- install_hall1.lua (Studio EDIT mode; re-runnable; its body also runs as a play-test PREVIEW on the test server). Job 94,
-- round 6: the Belvedere dei Guardiani - the Italian Hall of Fame on the Prato dei Fiori (site E): the French display concept
-- in the Italian style (Shannon, Oct 14 2026: "the same display concept, just a different model or style"). ONE pedestal in the
-- centre of the crescent shows one Guardian of the Harbour at a time, the newest first, with Older / Newer buttons and a plaque
-- (name, date, count); everyone on the lectern roll. workspace.HallOfGuardians: Belvedere (a round mosaic terrace, a low parapet
-- with a majolica band, the centre column with the gold key, two dim lanterns, cypresses and lemon trees cloned from Porto's own),
-- Pedestal (terracotta tile, GothamBold cream), Older / Newer, the Lectern with the roll, HallStatue (RemoteFunction), HallServer
-- (15329 chars: the statues, made once each from the Guardian list), HallClient (4703 chars: each player's own view).
-- Undo: delete workspace.HallOfGuardians (an older one is HudBackup.HallOfGuardians_pre_n). No DataStore, no publish. "QQ BELV".
local SS = game:GetService("ServerStorage")
local CS = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CX, CZ, YAW = 530, -1064, math.rad(90)              -- the terrace's centre; yaw 0 = the front faces north (-z)
local SERVER = [===[
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
local everRead = false                                                 -- live: nothing is shown or published until the store was read once
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
	everRead = true
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
	if cache[no] and cache[no].Parent then used[no] = os.clock(); return cache[no] end
	local e = entry(no)
	if not e or not makeStatue then return nil end
	busy[no] = true
	while building do task.wait(0.2) end
	building = true
	local m
	local okAll, errAll = pcall(function()                              -- (whatever throws, the locks are released below)
		local stage = F:FindFirstChild("Staging")
		if not stage then stage = Instance.new("Folder"); stage.Name = "Staging"; stage.Parent = F end
		local low = Vector3.new(SPOT.X, SPOT.Y - DROP, SPOT.Z)
		local ok, fig, acorn = pcall(function()
			return makeStatue:Invoke({uid = e.uid, name = e.name, no = e.no, day = e.day}, {x = low.X, top = low.Y, z = low.Z, parent = stage, name = "Figure", scale = num("Scale", 1.35), look = LOOK})
		end)
		if acorn then acorn:Destroy() end
		for _, n in ipairs({"GiantAcorn"}) do local stray = stage:FindFirstChild(n); if stray then stray:Destroy() end end
		if not (ok and fig) then
			warn("HallOfGuardians: no statue for No. " .. tostring(no) .. ": " .. tostring(fig))
			local half = stage:FindFirstChild("Figure"); if half then half:Destroy() end
			return
		end
		local built = Instance.new("Model"); built.Name = "No_" .. tostring(no)
		fig.Parent = built
		-- the harbour key in the raised hand, sized to the figure as the PortoKeeper does it
		local holdSide = (CH:GetAttribute("HoldHand") == "Right") and "Right" or "Left"
		local hand = fig:FindFirstChild(holdSide .. "Hand")
		local lo, hi = extents(fig)
		local h = math.clamp((hi.Y - lo.Y) * num("KeyShare", 0.42), 1.5, 6)
		if hand then makeKey(h, hand.Position.X, hand.Position.Y + hand.Size.Y / 2 - 0.15, hand.Position.Z, KEY_YAW, built)
		else makeKey(h, low.X, hi.Y, low.Z, KEY_YAW, built) end
		built.WorldPivot = (built:GetBoundingBox())
		-- on its feet in the middle of the pedestal (centred by its own body, not the raised key), then up out of the ground
		local mid = (lo + hi) / 2
		built:PivotTo(built:GetPivot() + Vector3.new(low.X - mid.X, low.Y - feetLow(built), low.Z - mid.Z) + Vector3.new(0, DROP, 0))
		built.Parent = storeFolder
		cache[no] = built; used[no] = os.clock()
		local n = 0
		for _ in pairs(cache) do n += 1 end
		if n > 40 then                                                  -- the forty seen most recently are kept
			local oldest, ot
			for k, t in pairs(used) do if cache[k] and (not ot or t < ot) then oldest, ot = k, t end end
			if oldest and oldest ~= no then cache[oldest]:Destroy(); cache[oldest] = nil; used[oldest] = nil end
		end
		m = built
	end)
	if not okAll then warn("HallOfGuardians: the statue build failed: " .. tostring(errAll)) end
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
	if not STUDIO and not everRead then return end                     -- (an outage at start: keep trying, show nothing wrong)
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
]===]
local CLIENT = [===[
-- HallClient (workspace.HallOfGuardians, RunContext Client): this player's own view of the Belvedere dei Guardiani - the newest
-- Guardian of the Harbour first, Older and Newer with the two buttons, the pedestal's plaque with name, date and count (the
-- French hall's mechanism in the Italian style). The statue shown is a copy, on this screen only, of the one HallServer made.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local _player = Players.LocalPlayer
local F = script.Parent
local fn = F:WaitForChild("HallStatue")
local store = RS:WaitForChild("HallStatues")
local function ordinal(n)
	n = math.floor(tonumber(n) or 0)
	local m100, m10, s = n % 100, n % 10, "th"
	if m100 < 11 or m100 > 13 then
		if m10 == 1 then s = "st" elseif m10 == 2 then s = "nd" elseif m10 == 3 then s = "rd" end
	end
	return tostring(n) .. s
end
local function dateOf(e)                                               -- the lighthouse plaque's own rule: the day's noon, else the moment
	local t = tonumber(e.day) and (tonumber(e.day) * 86400 + 43200) or tonumber(e.t)
	return t and os.date("!%b %d, %Y", t) or ""
end
local function list()
	local ok, t = pcall(function() return HttpService:JSONDecode(F:GetAttribute("HallJson") or "[]") end)
	return (ok and type(t) == "table") and t or {}
end
local function total() local K = workspace:FindFirstChild("PortoKeeper"); return (K and tonumber(K:GetAttribute("Need"))) or tonumber(F:GetAttribute("Total")) or 44 end
local view = Instance.new("Folder"); view.Name = "HallView_local"; view.Parent = workspace
local keepers, idx, shownNo = {}, 0, nil
local want = 0                                                         -- the newest request (older ones are dropped)
local function words()
	local ped = F:FindFirstChild("Pedestal")
	local tile = ped and ped:FindFirstChild("Tile")
	return tile and tile:FindFirstChild("Words")
end
local function setPlaque()
	local w = words()
	if not w then return end
	local e = keepers[idx]
	if e then
		w.Title.Text = ordinal(e.no):upper() .. " GUARDIAN"
		w.Who.Text = tostring(e.name or "?")
		w.When.Text = "All " .. tostring(e.total or total()) .. " squirrels, " .. dateOf(e) .. "  \u{B7}  " .. tostring(idx) .. " of " .. tostring(#keepers)
	else
		w.Title.Text = "THIS COULD BE YOU"
		w.Who.Text = "Guardian No. 1"
		w.When.Text = "Find all " .. tostring(total()) .. " squirrels of Porto Nocciola"
	end
end
local function setButtons()
	for _, b in ipairs({{name = "Older", on = idx > 1}, {name = "Newer", on = idx < #keepers}}) do
		local m = F:FindFirstChild(b.name)
		local disc = m and m:FindFirstChild("Button")
		if disc then disc.Transparency = b.on and 0 or 0.55 end
	end
end
local function show()
	setPlaque(); setButtons()
	local e = keepers[idx]
	if not e then
		view:ClearAllChildren(); shownNo = nil
		return
	end
	if shownNo == e.no and #view:GetChildren() > 0 then return end
	want += 1
	local mine = want
	task.spawn(function()
		local ok, name = pcall(function() return fn:InvokeServer(e.no) end)
		if mine ~= want then return end                                  -- (scrolled on while it was being made)
		local src = ok and name and store:WaitForChild(name, 20)
		if mine ~= want then return end
		view:ClearAllChildren()
		if src then
			local c = src:Clone()
			c.Parent = view
			shownNo = e.no
		end
	end)
end
local function step(d)
	local n = math.clamp(idx + d, math.min(1, #keepers), #keepers)
	if n ~= idx then idx = n; show() end
end
local function hookButtons()
	for _, b in ipairs({{name = "Older", d = -1}, {name = "Newer", d = 1}}) do
		local m = F:WaitForChild(b.name)
		local function hook(p)
			local cd = p:IsA("BasePart") and p:FindFirstChildOfClass("ClickDetector")
			if cd and not cd:GetAttribute("Hooked") then
				cd:SetAttribute("Hooked", true)
				cd.MouseClick:Connect(function() step(b.d) end)
			end
		end
		for _, p in ipairs(m:GetChildren()) do hook(p) end
		m.ChildAdded:Connect(function(p) task.defer(hook, p) end)          -- (streamed in later)
	end
end
local function reload()
	local atNewest = (idx == #keepers)
	keepers = list()
	if atNewest or idx > #keepers or idx == 0 then idx = #keepers end   -- a new Guardian: the belvedere moves on to them
	show()
end
task.spawn(hookButtons)
F:GetAttributeChangedSignal("HallJson"):Connect(reload)
F:GetAttributeChangedSignal("Rebuild"):Connect(function() shownNo = nil; view:ClearAllChildren(); task.delay(1, show) end)   -- (a rebuild on the server: fetch the statue again)
F.DescendantAdded:Connect(function(d) if d.Name == "Words" then task.defer(setPlaque) elseif d.Name == "Button" then task.defer(setButtons) end end)
reload()
]===]
do   -- the compile check, where loadstring can run (a Script has none and the call itself throws): the sources are compiled with the luau CLI before every push
	for _, pair in ipairs({{"HallServer", SERVER}, {"HallClient", CLIENT}}) do
		local ok, f, err = pcall(function() return loadstring(pair[2]) end)
		if ok and not f then print("QQ BELV ABORT: " .. pair[1] .. " does not compile: " .. tostring(err)) return end
	end
end
local CH = workspace:FindFirstChild("Champion")
if not (CH and CH:FindFirstChild("ChampionServer")) then print("QQ BELV ABORT: workspace.Champion.ChampionServer not found (it makes the statues)") return end
if not workspace:FindFirstChild("PortoKeeper") then print("QQ BELV ABORT: workspace.PortoKeeper not found (it keeps the Guardian list)") return end
local C = Color3.fromRGB
local STONE, TRIM, MAJOLICA, TERRA, GOLD, GOLD_D, GOLD_DD, CREAM, IRON = C(232, 226, 210), C(240, 236, 226), C(52, 110, 150), C(178, 92, 62), C(255, 206, 64), C(214, 160, 44), C(190, 136, 40), C(250, 244, 228), C(52, 50, 48)
local MOSAIC, SEA = C(222, 212, 190), C(78, 150, 186)
local RT = 17                                                          -- the terrace's radius

-- ---------------------------------------------------------------- the ground ----
local F = Instance.new("Folder"); F.Name = "HallOfGuardians"
local old = workspace:FindFirstChild("HallOfGuardians")
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Exclude; rpT.FilterDescendantsInstances = {F, old}
local function groundAt(x, z)                                        -- the first visible thing under the sky (invisible volumes skipped), never water
	local from = Vector3.new(x, 300, z)
	for _ = 1, 6 do
		local h = workspace:Raycast(from, Vector3.new(0, -600, 0), rpT)
		if not h then return nil end
		if h.Instance == workspace.Terrain then
			if h.Material == Enum.Material.Water then return nil end
			return h.Position.Y, h.Instance
		end
		if h.Instance.Transparency < 1 then return h.Position.Y, h.Instance end
		from = h.Position - Vector3.new(0, 0.05, 0)
	end
	return nil
end
local rpTerr = RaycastParams.new(); rpTerr.FilterType = Enum.RaycastFilterType.Include; rpTerr.FilterDescendantsInstances = {workspace.Terrain}
local samples, lowest, highest = {}, math.huge, -math.huge
local centreY = groundAt(CX, CZ)
for i = 0, 11 do
	local a = i * math.pi / 6
	local y = groundAt(CX + 17.5 * math.sin(a), CZ + 17.5 * math.cos(a))
	if y then table.insert(samples, y); lowest = math.min(lowest, y); highest = math.max(highest, y) end
end
if not centreY or #samples < 10 then print("QQ BELV ABORT: no ground under the terrace's rim (water or nothing at the centre or round it); nothing built") return end
if highest - lowest > 3 then print(string.format("QQ BELV ABORT: the ground rises %.1f studs across the terrace (edges %.1f..%.1f); too steep for one floor; nothing built", highest - lowest, lowest, highest)) return end
-- what stands round the terrace (r 19 and 21): anything more than a stud above the terrain there is reported
local standing = {}
for _, r in ipairs({19, 21}) do
	for i = 0, 23 do
		local a = i * math.pi / 12
		local x, z = CX + r * math.sin(a), CZ + r * math.cos(a)
		local y, inst = groundAt(x, z)
		local t = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpTerr)
		if y and inst and inst ~= workspace.Terrain and t and y > t.Position.Y + 1 then
			local top = inst; while top.Parent and top.Parent ~= workspace do top = top.Parent end
			standing[top.Name] = (standing[top.Name] or 0) + 1
		end
	end
end
local g = math.max(centreY, highest - 0.5) - 0.1                      -- the floor's base: its top never below the highest edge; the skirt covers the downhill side
local BASE = CFrame.new(CX, g, CZ) * CFrame.Angles(0, YAW, 0)
local function at(x, y, z) return BASE * CFrame.new(x, y, z) end
-- what stands INSIDE the footprint (r up to RT + 3.5, the step and the entrance trees included): a BIG thing (a tree, a wall,
-- a path slab, a bench: a box over 4 studs across or 3 tall) means this is the wrong spot - abort with its name; small props
-- (flowers, grass) under the terrace or the step are set aside into ServerStorage.HudBackup.HallOfGuardians_props_n with
-- their places kept (undo: move them back). Distances are measured to each part's OWN box (its rotation respected), so a long
-- handrail forty studs away does not count.
local function distXZ(d)
	local lp = d.CFrame:PointToObjectSpace(Vector3.new(CX, d.Position.Y, CZ))
	local h = d.Size / 2
	local cp = d.CFrame:PointToWorldSpace(Vector3.new(math.clamp(lp.X, -h.X, h.X), math.clamp(lp.Y, -h.Y, h.Y), math.clamp(lp.Z, -h.Z, h.Z)))
	local dx, dz = cp.X - CX, cp.Z - CZ
	return math.sqrt(dx * dx + dz * dz)
end
local countCache = {}
local function partCount(m)
	local n = countCache[m]
	if n == nil then
		n = 0
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then n += 1; if n > 150 then break end end end
		countCache[m] = n
	end
	return n
end
local function thingOf(p)
	local m = p.Parent
	while m and m ~= workspace do
		if m:IsA("Model") and partCount(m) <= 150 then return m end
		m = m.Parent
	end
	return p
end
local function boxOf(parts)
	local lo, hi = Vector3.new(1e9, 1e9, 1e9), Vector3.new(-1e9, -1e9, -1e9)
	for _, p in ipairs(parts) do
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
			local c = p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz); lo = lo:Min(c); hi = hi:Max(c)
		end end end
	end
	return lo, hi
end
local inside = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d ~= workspace.Terrain and d.Transparency < 1 and not d:IsDescendantOf(F) and not (old and d:IsDescendantOf(old)) then
		local p = d.Position
		if distXZ(d) <= RT + 3.5 then
			local t = workspace:Raycast(Vector3.new(p.X, 300, p.Z), Vector3.new(0, -600, 0), rpTerr)
			if p.Y + d.Size.Y / 2 > (t and t.Position.Y or -1e9) + 0.5 then
				local th = thingOf(d)
				inside[th] = inside[th] or {}
				table.insert(inside[th], d)
			end
		end
	end
end
local bigs, props = {}, {}
for th, parts in pairs(inside) do
	local lo, hi = boxOf(parts)
	if hi.X - lo.X > 4 or hi.Z - lo.Z > 4 or hi.Y - lo.Y > 3 then
		local nearest = math.huge
		for _, d in ipairs(parts) do nearest = math.min(nearest, distXZ(d)) end
		table.insert(bigs, th.Name .. string.format(" (x %.0f..%.0f z %.0f..%.0f, %.1f studs from the centre)", lo.X, hi.X, lo.Z, hi.Z, nearest))
	else
		-- parked only when it stands under the terrace itself or under the step
		local under = false
		for _, d in ipairs(parts) do
			local l = BASE:PointToObjectSpace(d.Position)
			if distXZ(d) <= RT + 0.6 or (math.abs(l.X) <= 6.3 and l.Z <= -(RT + 0.5) and l.Z >= -(RT + 3.6)) then under = true break end
		end
		if under then table.insert(props, th) end
	end
end
if #bigs > 0 then table.sort(bigs); print("QQ BELV ABORT: standing inside the terrace's footprint at (" .. CX .. ", " .. CZ .. "): " .. table.concat(bigs, "; ") .. "; pick another centre; nothing built") return end
local function part(name, size, cf, colour, material, parent, shape, collide)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = (collide ~= false)
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local function disc(name, radius, thick, y, colour, material, parent, collide)        -- a flat round slab, its axis upright
	return part(name, Vector3.new(thick, radius * 2, radius * 2), at(0, y, 0) * CFrame.Angles(0, 0, math.pi / 2), colour, material, parent, Enum.PartType.Cylinder, collide)
end
local belv = Instance.new("Model"); belv.Name = "Belvedere"; belv.Parent = F

-- ---------------------------------------------------------------- the terrace ----
-- (RT, the terrace's radius, is set at the top)
disc("Skirt", RT + 0.2, 3.0, -1.5, STONE, Enum.Material.Limestone, belv)
disc("Rim", RT + 0.5, 0.3, 0.15, TERRA, Enum.Material.Slate, belv)
disc("Floor", RT, 0.6, 0.3, MOSAIC, Enum.Material.Marble, belv)
disc("MosaicRing", 6.2, 0.06, 0.63, GOLD, Enum.Material.SmoothPlastic, belv, false).Reflectance = 0.1
disc("MosaicSea", 5.5, 0.08, 0.66, SEA, Enum.Material.Slate, belv, false)
disc("MosaicHeart", 1.6, 0.06, 0.72, GOLD, Enum.Material.SmoothPlastic, belv, false).Reflectance = 0.1
part("Step", Vector3.new(12, 0.32, 2.4), at(0, 0.16, -(RT + 0.9)), STONE, Enum.Material.Limestone, belv)
local Y0 = 0.6                                                         -- the floor's top

-- ---------------------------------------------------------------- the parapet, the sea side ----
local RW, NSEG, ARC = 15.6, 16, math.rad(170)                          -- the wall's radius, its segments, how far round it goes
local segL = 2 * RW * math.sin(ARC / NSEG / 2) + 0.2
for i = 1, NSEG do
	local th = -ARC / 2 + (i - 0.5) * ARC / NSEG
	local x, z = RW * math.sin(th), RW * math.cos(th)
	local turn = CFrame.Angles(0, th, 0)
	part("Wall", Vector3.new(segL, 2.2, 0.7), at(x, Y0 + 1.1, z) * turn, STONE, Enum.Material.Limestone, belv)
	part("Band", Vector3.new(segL, 0.45, 0.8), at(x, Y0 + 1.3, z) * turn, MAJOLICA, Enum.Material.SmoothPlastic, belv, nil, false)
	part("Cap", Vector3.new(segL + 0.1, 0.3, 1.0), at(x, Y0 + 2.35, z) * turn, TRIM, Enum.Material.Marble, belv)
end

-- ---------------------------------------------------------------- the column with the harbour key ----
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
local function makeKey(height, cfBottom, parent)                      -- a key standing on cfBottom, its face along cfBottom's -z
	local s = height / KEY_H
	local k = Instance.new("Model"); k.Name = "Key"
	local pose = keyPose(s)
	local lo = math.huge
	for name, d in pairs(pose) do
		local p = part(name, d[2], d[1], d[3], Enum.Material.SmoothPlastic, k, d[4], false); p.CanQuery = false; p.Reflectance = 0.08
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do lo = math.min(lo, (p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y) end end end
	end
	local base = cfBottom * CFrame.new(0, -lo, 0) * CFrame.Angles(0, math.pi, 0)
	for name, d in pairs(pose) do k[name].CFrame = base * d[1] end
	k.WorldPivot = cfBottom * CFrame.new(0, height / 2, 0)
	k.Parent = parent
	return k
end
do
	local col = Instance.new("Model"); col.Name = "Column"; col.Parent = belv
	part("Base", Vector3.new(2.4, 0.5, 2.4), at(0, Y0 + 2.5 + 0.25, RW), TRIM, Enum.Material.Marble, col)
	part("Shaft", Vector3.new(8.6, 1.5, 1.5), at(0, Y0 + 3.0 + 4.3, RW) * CFrame.Angles(0, 0, math.pi / 2), STONE, Enum.Material.Limestone, col, Enum.PartType.Cylinder)
	part("Capital", Vector3.new(2.2, 0.4, 2.2), at(0, Y0 + 11.6 + 0.2, RW), TRIM, Enum.Material.Marble, col)
	part("Plinth", Vector3.new(1.4, 0.3, 1.4), at(0, Y0 + 12.0 + 0.15, RW), GOLD_D, Enum.Material.SmoothPlastic, col)
	makeKey(3.4, at(0, Y0 + 12.3, RW), col)
end

-- ---------------------------------------------------------------- the lanterns at the horns ----
for _, s in ipairs({-1, 1}) do
	local th = s * (ARC / 2 - math.rad(2))
	local x, z = RW * math.sin(th), RW * math.cos(th)
	local m = Instance.new("Model"); m.Name = "Lantern"; m.Parent = belv
	part("Foot", Vector3.new(0.9, 0.3, 0.9), at(x, Y0 + 2.5 + 0.15, z), IRON, Enum.Material.Metal, m)
	part("Post", Vector3.new(0.4, 3.8, 0.4), at(x, Y0 + 2.8 + 1.9, z), IRON, Enum.Material.Metal, m, nil, false)
	local lamp = part("Lamp", Vector3.new(0.9, 0.9, 0.9), at(x, Y0 + 6.6 + 0.45, z), C(255, 196, 120), Enum.Material.Glass, m, Enum.PartType.Ball, false)
	lamp.Transparency = 0.15                                              -- (Shannon, Oct 14, live: "the lamps on the end are too bright" - her pick of the runner's mock E)
	local lt = Instance.new("PointLight"); lt.Range = 12; lt.Brightness = 0.35; lt.Color = C(255, 214, 150); lt.Shadows = false; lt.Parent = lamp
	part("Hood", Vector3.new(1.2, 0.2, 1.2), at(x, Y0 + 7.5 + 0.1, z), IRON, Enum.Material.Metal, m, nil, false)
end

-- ---------------------------------------------------------------- the lectern with the roll of the Guardians ----
do
	local lect = Instance.new("Model"); lect.Name = "Lectern"; lect.Parent = F
	local LZ = -(RT - 3.6)
	part("Post", Vector3.new(1.6, 2.4, 1.1), at(0, Y0 + 1.2, LZ), STONE, Enum.Material.Limestone, lect)
	part("Frame", Vector3.new(7.6, 3.2, 0.14), at(0, Y0 + 2.9, LZ + 0.02) * CFrame.Angles(math.rad(52), 0, 0), TRIM, Enum.Material.Marble, lect, nil, false)
	local plaque = part("Plaque", Vector3.new(7.2, 2.8, 0.2), at(0, Y0 + 2.9, LZ) * CFrame.Angles(math.rad(52), 0, 0), TERRA, Enum.Material.SmoothPlastic, lect, nil, false)   -- (terracotta with cream letters: Shannon's pick, Oct 14)
	local psg = Instance.new("SurfaceGui"); psg.Name = "Words"; psg.Face = Enum.NormalId.Front; psg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	psg.PixelsPerStud = 70; psg.LightInfluence = 0.3; psg.Parent = plaque
	local function line(name, y, h, size, font, colour, text)
		local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 12, 0, y); l.Size = UDim2.new(1, -24, 0, h)
		l.Font = font; l.TextScaled = true; l.TextColor3 = colour; l.TextWrapped = true; l.Text = text; l.Parent = psg
		local cap = Instance.new("UITextSizeConstraint"); cap.MaxTextSize = size; cap.Parent = l
		return l
	end
	-- (7.2 x 2.8 studs = 504 x 196 px at 70 per stud)
	-- (GothamBold in cream on the terracotta, no gold, no gradient: Shannon's pick from a 14-font sampler, Oct 14)
	line("Title", 6, 42, 36, Enum.Font.GothamBold, CREAM, "BELVEDERE DEI GUARDIANI")
	line("Sub", 48, 24, 18, Enum.Font.GothamBold, CREAM, "THE GUARDIANS OF THE HARBOUR OF PORTO NOCCIOLA")
	line("Roll", 76, 76, 26, Enum.Font.GothamBold, CREAM, "")
	line("Foot", 156, 30, 16, Enum.Font.GothamBold, CREAM, "Each of them found every squirrel of Porto Nocciola.")
end

-- ---------------------------------------------------------------- the pedestal, in the centre of the crescent ----
local PR, PED_W, PED_H = 12.6, 3.2, 2.6                                -- where the crescent's centre pedestal stood; its size
do
	local ped = Instance.new("Model"); ped.Name = "Pedestal"; ped.Parent = F
	local cf = at(0, Y0, PR)                                            -- the tile faces the front (-z)
	part("Foot", Vector3.new(PED_W + 0.5, 0.3, PED_W + 0.5), cf * CFrame.new(0, 0.15, 0), STONE, Enum.Material.Marble, ped)
	part("Block", Vector3.new(PED_W, PED_H, PED_W), cf * CFrame.new(0, PED_H / 2, 0), STONE, Enum.Material.Marble, ped)
	part("Band", Vector3.new(PED_W + 0.16, 0.18, PED_W + 0.16), cf * CFrame.new(0, PED_H - 0.3, 0), GOLD, Enum.Material.SmoothPlastic, ped, nil, false).Reflectance = 0.15
	local tile = part("Tile", Vector3.new(2.6, 1.6, 0.12), cf * CFrame.new(0, 1.35, -(PED_W / 2 + 0.05)), TERRA, Enum.Material.SmoothPlastic, ped, nil, false)
	local sg = Instance.new("SurfaceGui"); sg.Name = "Words"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 80; sg.LightInfluence = 0.3; sg.Parent = tile
	local function label(name, y, h, size)                             -- (2.6 x 1.6 studs = 208 x 128 px; GothamBold in cream: her pick)
		local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 8, 0, y); l.Size = UDim2.new(1, -16, 0, h)
		l.Font = Enum.Font.GothamBold; l.TextScaled = true; l.TextColor3 = CREAM; l.TextWrapped = true; l.Text = ""; l.Parent = sg
		local cap = Instance.new("UITextSizeConstraint"); cap.MaxTextSize = size; cap.Parent = l
	end
	label("Title", 6, 26, 20); label("Who", 32, 44, 36); label("When", 78, 44, 15)
	ped.WorldPivot = cf
	F:SetAttribute("Spot", cf.Position + Vector3.new(0, PED_H, 0))        -- the pedestal's top centre: where the statue's feet go
	F:SetAttribute("Look", BASE.LookVector)                              -- the way the statue faces: out to the front
end
-- the buttons, Older and Newer (France's: a post, a cap, a disc you click or tap; facing the pedestal, local +x is on your LEFT)
for _, b in ipairs({{name = "Older", s = 1, glyph = "<"}, {name = "Newer", s = -1, glyph = ">"}}) do
	local m = Instance.new("Model"); m.Name = b.name; m.Parent = F
	local x, z = b.s * 5.2, PR - 4.6
	part("Post", Vector3.new(1.2, 3.0, 1.2), at(x, Y0 + 1.5, z), STONE, Enum.Material.Limestone, m)
	part("Cap", Vector3.new(1.5, 0.3, 1.5), at(x, Y0 + 3.15, z), TERRA, Enum.Material.Slate, m)
	local disc = part("Button", Vector3.new(0.35, 2.0, 2.0), at(x, Y0 + 4.3, z) * CFrame.Angles(0, math.pi / 2, 0), TRIM, Enum.Material.Marble, m, Enum.PartType.Cylinder)
	local dsg = Instance.new("SurfaceGui"); dsg.Face = Enum.NormalId.Right; dsg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; dsg.PixelsPerStud = 60
	dsg.LightInfluence = 0.3; dsg.Parent = disc
	local gl = Instance.new("TextLabel"); gl.BackgroundTransparency = 1; gl.Size = UDim2.fromScale(1, 1); gl.Font = Enum.Font.GothamBold
	gl.Text = b.glyph; gl.TextScaled = true; gl.TextColor3 = TERRA; gl.Parent = dsg
	for _, p in ipairs({disc, m:FindFirstChild("Post"), m:FindFirstChild("Cap")}) do
		local cd = Instance.new("ClickDetector"); cd.MaxActivationDistance = 40; cd.Parent = p
	end
end

-- ---------------------------------------------------------------- Porto's own trees ----
-- (copies of the town's models, their tags and scripts removed so a copy joins nothing the original is part of)
local found, sources = {}, {}
do
	local want = {["Italian cypress"] = true, ["Lemon tree"] = true}                                    -- (no benches: Shannon, Oct 14, "I don't think we need benches there")
	for _, d in ipairs(workspace:GetDescendants()) do
		if want[d.Name] and d:IsA("Model") and not sources[d.Name] and not d:IsDescendantOf(F) and not (old and d:IsDescendantOf(old)) then sources[d.Name] = d end
	end
end
local function copyOf(name, scale, lx, lz, faceZ)
	local src = sources[name]
	if not src then found[name] = (found[name] or 0); return end
	local c = src:Clone(); c.Name = "Belv_" .. name:gsub("%s+", "_")
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BaseScript") then d:Destroy() else for _, t in ipairs(CS:GetTags(d)) do CS:RemoveTag(d, t) end end
	end
	for _, t in ipairs(CS:GetTags(c)) do CS:RemoveTag(c, t) end
	for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = true end end
	pcall(function() c:ScaleTo(c:GetScale() * scale) end)
	local want = at(lx, 0, lz).Position
	local gy
	if lx * lx + lz * lz < RT * RT then gy = at(0, Y0, 0).Position.Y + 0.1 else gy = groundAt(want.X, want.Z) end   -- inside: on the floor's top
	if not gy then c:Destroy(); found[name] = (found[name] or 0); return end
	local cf, size = c:GetBoundingBox()
	local pivot = c:GetPivot()
	if faceZ then                                                       -- turned so its front (-z) looks along the belvedere's +z (out to sea)
		c:PivotTo(CFrame.new(pivot.Position) * BASE.Rotation * CFrame.Angles(0, math.pi, 0))
		cf, size = c:GetBoundingBox()
	end
	c:PivotTo(c:GetPivot() + Vector3.new(want.X - cf.Position.X, gy - (cf.Position.Y - size.Y / 2) - 0.1, want.Z - cf.Position.Z))
	c.Parent = belv
	found[name] = (found[name] or 0) + 1
end
for _, s in ipairs({-1, 1}) do
	copyOf("Italian cypress", 1.0, s * 18 * math.sin(math.rad(52)), 18 * math.cos(math.rad(52)))       -- behind the parapet's shoulders
	copyOf("Lemon tree", 0.9, s * 8.5, -(RT + 2.6))                                                    -- either side of the step
end

-- ---------------------------------------------------------------- the folder, its settings, the script ----
F:SetAttribute("Base", BASE)
F:SetAttribute("FloorTop", Y0)
F:SetAttribute("Scale", 1.35); F:SetAttribute("KeyShare", 0.42); F:SetAttribute("RestKeyHeight", 2.6); F:SetAttribute("Total", 44)
F:SetAttribute("Rebuild", 0)
-- a play-test preview (no Guardian list on the test server): three sample Guardians so the crescent can be seen with statues
if RunService:IsRunning() then
	F:SetAttribute("PreviewJson", HttpService:JSONEncode({
		{no = 1, uid = 9611145467, name = "SelBell", user = "SelBell", t = 1791676800, total = 44},
		{no = 2, uid = 4161205246, name = "dakota", user = "mentallyunstable_xo", t = 1791763200, total = 44},
		{no = 3, uid = 7902108387, name = "blizzy_1718", user = "blizzy_1718", t = 1791849600, total = 44},
	}))
else
	F:SetAttribute("PreviewJson", "")
end
if old then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("HallOfGuardians_pre_" .. n) do n += 1 end
	old.Name = "HallOfGuardians_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
-- the small props under the terrace, set aside with their places kept
local parked = 0
if #props > 0 then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("HallOfGuardians_props_" .. n) do n += 1 end
	local pf = Instance.new("Folder"); pf.Name = "HallOfGuardians_props_" .. n; pf.Parent = hb
	for _, th in ipairs(props) do th:SetAttribute("ParkedFrom", th.Parent and th.Parent:GetFullName() or ""); th.Parent = pf; parked += 1 end   -- (the undo: back to ParkedFrom)
end
local rf = Instance.new("RemoteFunction"); rf.Name = "HallStatue"; rf.Parent = F
local s = Instance.new("Script"); s.Name = "HallServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "HallClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
local names, near = {}, {}
for _, n in ipairs({"Italian cypress", "Lemon tree"}) do table.insert(names, n .. " " .. tostring(found[n] or 0)) end
for n, k in pairs(standing) do table.insert(near, n .. " x" .. k) end
print(string.format("QQ BELV DONE: workspace.HallOfGuardians at (%.0f, %.1f, %.0f) yaw %.0f (ground centre %.1f, edges %.1f..%.1f); terrace R %d, parapet %d segments, one pedestal + Older/Newer; copies: %s; %d small props set aside (HudBackup.HallOfGuardians_props_*); HallServer %d, HallClient %d chars%s", CX, g, CZ, math.deg(YAW), centreY, lowest, highest, RT, NSEG, table.concat(names, ", "), parked, #s.Source, #c.Source, old and ("; the old folder is HudBackup." .. old.Name) or ""))
if #near > 0 then print("QQ BELV NOTE: standing within 19-21 studs of the centre (more than a stud above the terrain): " .. table.concat(near, ", ")) end
