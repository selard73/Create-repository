-- HallServer (workspace.HallOfGuardians): the Belvedere dei Guardiani on the Prato dei Fiori - every Guardian of the Harbour
-- of Porto Nocciola in marble, holding the harbour key, standing in a crescent above the sea (Shannon, Oct 14 2026: "make this
-- hall of fame look distinctively different from the one in France"; the French hall shows one Keeper at a time in a frame -
-- here they all stand together in the open). The architecture (terrace, parapet, column, lanterns, the lectern) is built by
-- the installer; THIS script builds what changes: a pedestal and a statue for each Guardian from the Guardian list, at server
-- start and again whenever the list changes. The first Guardian keeps the centre; the next ones take the slots right and left
-- of it in turn; the next empty slot gets an inviting pedestal with the resting key. Statues come from Champion.MakeStatue
-- (the same marble figure as every other statue in the game); the acorn it hands over is swapped for the harbour key (the
-- PortoKeeper's own key shape). The list is READ from the Guardian's own store (PortoKeeper_v1: the historical "first" record
-- and Codex's daily ledger "daily_v2", Oct 13-14 2026); nothing here ever writes a DataStore, and Codex's PortoKeeperServer is
-- left exactly as it is: this script polls the store once a minute and again whenever the lighthouse plaque names a new winner.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DSS = game:GetService("DataStoreService")
local F = script.Parent
local STUDIO = RunService:IsStudio()
local CH = workspace:WaitForChild("Champion", 60)
local makeStatue = CH and CH:WaitForChild("MakeStatue", 60)
local K = workspace:WaitForChild("PortoKeeper", 60)
local BASE = F:GetAttribute("Base")                                    -- the belvedere's own frame: origin at the terrace's
if typeof(BASE) ~= "CFrame" then BASE = CFrame.new() end                -- centre on the floor, -z toward the land (the visitors)
local function at(x, y, z) return BASE * CFrame.new(x, y, z) end
local function num(name, default) local v = tonumber(F:GetAttribute(name)); return v or default end
local SLOTS = math.max(1, math.floor(num("Slots", 7)))
local FLOOR = num("FloorTop", 0.6)                                  -- the terrace floor's top, above the frame's origin
local C = Color3.fromRGB
local MARBLE, GOLD, GOLD_D, GOLD_DD, TERRA, CREAM = C(236, 232, 224), C(255, 206, 64), C(214, 160, 44), C(190, 136, 40), C(178, 92, 62), C(250, 244, 228)

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
local function signature()
	local parts = {}
	for _, e in ipairs(list()) do table.insert(parts, tostring(e.no) .. "=" .. tostring(e.uid)) end
	return table.concat(parts, ",")
end
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

-- ---- the slots: where each pedestal stands on the crescent ----
-- slot 1 is the centre (straight back, the sea behind it); 2 is right of it, 3 left, 4 right again ... so the row stays
-- balanced however many there are. The pedestals stand on a circle of Radius round the terrace's centre, ArcDeg wide.
local function slotAngle(k)
	local step = (SLOTS > 1) and math.rad(num("ArcDeg", 150)) / (SLOTS - 1) or 0
	local half = math.floor(k / 2)
	local side = (k % 2 == 0) and 1 or -1
	return side * half * step
end
local function slotSpot(k)
	local r, th = num("Radius", 13), slotAngle(k)
	return r * math.sin(th), r * math.cos(th)                           -- local x, z
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
-- a key `height` tall standing with its bottom at (x, bottomY, z), its face turned by yaw
local function makeKey(height, x, bottomY, z, yaw, parent)
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

-- ---- a pedestal with its tile ----
local PED_W, PED_H = 3.2, 2.6
local function label(parent, name, y, h, size, font, colour)
	local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 8, 0, y); l.Size = UDim2.new(1, -16, 0, h)
	l.Font = font; l.TextScaled = true; l.TextColor3 = colour; l.TextWrapped = true; l.Text = ""; l.Parent = parent
	local cap = Instance.new("UITextSizeConstraint"); cap.MaxTextSize = size; cap.Parent = l
	return l
end
local function pedestal(k, facing)
	local m = Instance.new("Model"); m.Name = "Slot_" .. k
	local lx, lz = slotSpot(k)
	local cf = at(lx, FLOOR, lz) * CFrame.Angles(0, slotAngle(k), 0)    -- on the floor's top; the tile faces the terrace's centre
	local p = Instance.new("Part"); p.Name = "Pedestal"; p.Size = Vector3.new(PED_W, PED_H, PED_W); p.CFrame = cf * CFrame.new(0, PED_H / 2, 0)
	p.Color = MARBLE; p.Material = Enum.Material.Marble; p.Anchored = true; p.CanCollide = true; p.TopSurface = Enum.SurfaceType.Smooth; p.Parent = m
	local b = Instance.new("Part"); b.Name = "Band"; b.Size = Vector3.new(PED_W + 0.16, 0.18, PED_W + 0.16); b.CFrame = cf * CFrame.new(0, PED_H - 0.3, 0)
	b.Color = GOLD; b.Material = Enum.Material.SmoothPlastic; b.Reflectance = 0.15; b.Anchored = true; b.CanCollide = false; b.Parent = m
	local f = Instance.new("Part"); f.Name = "Foot"; f.Size = Vector3.new(PED_W + 0.5, 0.3, PED_W + 0.5); f.CFrame = cf * CFrame.new(0, 0.15, 0)
	f.Color = MARBLE; f.Material = Enum.Material.Marble; f.Anchored = true; f.CanCollide = true; f.Parent = m
	-- the tile on the front: terracotta, cream letters (Shannon's pick, Oct 14)
	local t = Instance.new("Part"); t.Name = "Tile"; t.Size = Vector3.new(2.6, 1.6, 0.12); t.CFrame = cf * CFrame.new(0, 1.35, -(PED_W / 2 + 0.05))
	t.Color = TERRA; t.Material = Enum.Material.SmoothPlastic; t.Anchored = true; t.CanCollide = false; t.Parent = m
	local sg = Instance.new("SurfaceGui"); sg.Name = "Words"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 80; sg.LightInfluence = 0.3; sg.Parent = t
	-- (2.6 x 1.6 studs = 208 x 128 px)
	label(sg, "Title", 6, 26, 22, Enum.Font.Antique, CREAM)
	label(sg, "Who", 32, 44, 40, Enum.Font.FredokaOne, CREAM)
	label(sg, "When", 78, 44, 15, Enum.Font.Merriweather, CREAM)
	m.WorldPivot = cf
	m:SetAttribute("Slot", k)
	m.Parent = F
	return m, cf
end
local function tileWords(m, title, who, when)
	local w = m:FindFirstChild("Tile") and m.Tile:FindFirstChild("Words")
	if not w then return end
	w.Title.Text = title; w.Who.Text = who; w.When.Text = when
end
local function lookFrom(cf)                                            -- from a pedestal toward the terrace's front
	local to = at(0, 0, -6).Position - cf.Position
	to = Vector3.new(to.X, 0, to.Z)
	return (to.Magnitude > 0.01) and to.Unit or -BASE.LookVector
end
local function keyYaw(look) return math.atan2(look.X, look.Z) + math.pi end

-- ---- the statues ----
local shown = {}                                                       -- slot k -> the uid standing there (or "invite")
local function clearSlot(k)
	local m = F:FindFirstChild("Slot_" .. k)
	if m then m:Destroy() end
	shown[k] = nil
end
local function statueFor(m, cf, e)
	if not makeStatue then return false end
	local look = lookFrom(cf)
	local ok, fig, acorn = pcall(function()
		return makeStatue:Invoke({uid = e.uid, name = e.name, no = e.no, day = e.day}, {x = cf.Position.X, top = cf.Position.Y + PED_H, z = cf.Position.Z, parent = m, name = "Figure", scale = num("Scale", 1.35), look = look})
	end)
	if acorn then acorn:Destroy() end
	if not (ok and fig) then
		warn("HallOfGuardians: no statue for " .. tostring(e.name) .. ": " .. tostring(fig))
		local half = m:FindFirstChild("Figure"); if half then half:Destroy() end
		return false
	end
	-- the harbour key in the raised hand, sized to the figure as the PortoKeeper does it
	local holdSide = (CH:GetAttribute("HoldHand") == "Right") and "Right" or "Left"
	local hand = fig:FindFirstChild(holdSide .. "Hand")
	local lo, hi = extents(fig)
	local h = math.clamp((hi.Y - lo.Y) * num("KeyShare", 0.42), 1.5, 6)
	if hand then
		makeKey(h, hand.Position.X, hand.Position.Y + hand.Size.Y / 2 - 0.15, hand.Position.Z, keyYaw(look), m)
	else
		makeKey(h, cf.Position.X, hi.Y, cf.Position.Z, keyYaw(look), m)
	end
	return true
end
local building, dirty, wipe = false, false, false
local pending = {}                                                     -- slot k -> the entry still without a statue
local function buildOnce()
	if wipe then wipe = false; for k = 1, SLOTS do clearSlot(k) end end
	local l = list()
	local total = (K and tonumber(K:GetAttribute("Need"))) or tonumber(F:GetAttribute("Total")) or 44
	for k = 1, SLOTS do
		local e = l[k]
		if e then
			if shown[k] ~= e.uid or not F:FindFirstChild("Slot_" .. k) then
				clearSlot(k)
				local m, cf = pedestal(k)
				tileWords(m, ordinal(e.no):upper() .. " GUARDIAN", tostring(e.name or "?"), "All " .. tostring(e.total or total) .. " squirrels, " .. dateOf(e))
				shown[k] = e.uid
				if statueFor(m, cf, e) then pending[k] = nil else pending[k] = e end
				task.wait(1.5)                                        -- (the statue maker fetches each avatar from the web)
			end
		elseif k == #l + 1 then
			if shown[k] ~= "invite" or not F:FindFirstChild("Slot_" .. k) then
				clearSlot(k)
				local m, cf = pedestal(k)
				tileWords(m, "THIS COULD BE YOU", "Guardian No. " .. tostring(k), "Find all " .. tostring(total) .. " squirrels of Porto Nocciola")
				makeKey(num("RestKeyHeight", 2.6), cf.Position.X, cf.Position.Y + PED_H, cf.Position.Z, keyYaw(lookFrom(cf)), m)
				shown[k] = "invite"
			end
		else
			if shown[k] then clearSlot(k) end
		end
	end
	-- the roll on the lectern: every Guardian by name, in order (the ones beyond the crescent's slots too)
	local lect = F:FindFirstChild("Lectern")
	local words = lect and lect:FindFirstChild("Plaque") and lect.Plaque:FindFirstChild("Words")
	if words then
		if #l == 0 then
			words.Roll.Text = "No Guardian yet. Be the first to find all " .. tostring(total) .. " squirrels of Porto Nocciola and your statue will stand here, holding the harbour key."
		else
			local names, from = {}, math.max(1, #l - 5)
			for i = from, #l do table.insert(names, tostring(l[i].no) .. ". " .. tostring(l[i].name or "?")) end
			words.Roll.Text = ((from > 1) and (tostring(from - 1) .. " more, then ") or "") .. table.concat(names, "   ")
		end
	end
end
local function build()                                                 -- a change during a build runs it once more after
	if building then dirty = true return end
	building = true
	repeat
		dirty = false
		local ok, err = pcall(buildOnce)
		if not ok then warn("HallOfGuardians: build failed: " .. tostring(err)) end
	until not dirty
	building = false
end
-- a statue the maker could not give (the start-up burst, a web hiccup): asked for again every 20 s, for the server's life
task.spawn(function()
	while true do
		task.wait(20)
		local keys = {}
		for k in pairs(pending) do table.insert(keys, k) end
		for _, k in ipairs(keys) do
			local e, m = pending[k], F:FindFirstChild("Slot_" .. k)
			if e and m and shown[k] == e.uid then
				print("HallOfGuardians: no statue yet for " .. tostring(e.name) .. "; asking again")
				if statueFor(m, m.WorldPivot, e) then pending[k] = nil end
				task.wait(1.5)
			else
				pending[k] = nil
			end
		end
	end
end)
F:GetAttributeChangedSignal("Rebuild"):Connect(function() wipe = true; task.defer(build) end)
-- the store: read at start (a few tries), then once a minute, and 3 s after the lighthouse plaque names a new Guardian
local lastSig
local function refresh()
	readStore()
	local sig = signature()
	if sig ~= lastSig then lastSig = sig; build() end
end
task.spawn(function()
	for attempt = 1, 5 do
		if readStore() or not store then break end
		task.wait(2 * attempt)
	end
	refresh()
	print(string.format("HallOfGuardians: ready - %d Guardians on the belvedere (%d slots)", #list(), SLOTS))
	while true do
		task.wait(num("PollSecs", 60))
		refresh()
	end
end)
task.spawn(function()
	local plinth = K and K:WaitForChild("Plinth", 30)
	local plaque = plinth and plinth:WaitForChild("Plaque", 30)
	local words = plaque and plaque:WaitForChild("Words", 30)
	local who = words and words:WaitForChild("Who", 30)
	if who then who:GetPropertyChangedSignal("Text"):Connect(function() task.delay(3, refresh) end) end
end)
