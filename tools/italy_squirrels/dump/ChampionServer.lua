local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local MS = game:GetService("MessagingService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local F = script.Parent
local ev = RS:WaitForChild("ChampionEvent")
local awardItems = RS:WaitForChild("AwardItems")
local TOPIC = "DayChampion_v1"
local STUDIO = RunService:IsStudio()
local store
if not STUDIO then pcall(function() store = DSS:GetDataStore("DayChampion_v1") end) end
local MARBLE = Color3.fromRGB(232, 228, 218)

local function offsetHours() local d = workspace:FindFirstChild("Daily"); return (d and d:GetAttribute("DayOffsetHours")) or 9 end
local function today() return math.floor((os.time() - offsetHours() * 3600) / 86400) end
local functidescription only knows the player's profile outfit. Preserve the ids of any
-- in-game boutique pieces and Chapelier hat worn at the winning moment so every statue can match.
local function wornLook(player)
	local look = {}
	local dressKit = RS:FindFirstChild("DressKit")
	local dressModule = dressKit and dressKit:FindFirstChild("Catalogue")
	if dressModule then
		local ok, cat = pcall(require, dressModule)
		if ok and type(cat) == "table" and type(cat.order) == "table" then
			local ids = {}
			for _, id in ipairs(cat.order) do
				if item(player, "dress_" .. id) > 0 and item(player, "dresswear_" .. id) > 0 then table.insert(ids, id) end
			end
			if #ids > 0 then look.boutique = table.concat(ids, ",") end
		end
	end
	local hatKit = RS:FindFirstChild("HatKit")
	local hatModule = hatKit and hatKit:FindFirstChild("Catalogue")
	if hatModule then
		local ok, cat = pcall(require, hatModule)
		if ok and type([q.map] then FRENCH_ID[q.id] = true else NOT_FRENCH[q.id] = true end end end
end
local function frenchFound(player)
	local s = player:GetAttribute("FoundIds")
	if type(s) ~= "string" or next(FRENCH_ID) == nil then return tonumber(player:GetAttribute("SquirrelsFound")) or 0 end
	local n = 0
	for id in s:gmatch("[^,]+") do if FRENCH_ID[id] then n += 1 end end
	return n
end
local function totalSquirrels()
	local ids, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId"); if id and NOT_FRENCH[id] then id = nil end
		if id and not ids[id] then ids[id] = true; n += 1 end
	end
	return n
end
local function dateOf(day) return os.date("!%B %d, %Y", day * 86400 + 12 * 3600) end

-- ---- the statue ----
local PX, PZ, TOP = F:GetAttribute("PlinthX"), F:GetAttribute("PlinthZ"), F:GetAttribute("TopY")
local FX = F:GetAttribute("FigureX") or PX              ch("^RBX_") then pcall(function() d:SetAttribute(k, nil) end) end end
	end
end
local function stoneify(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") or d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("BodyColors")
			or d:IsA("BaseScript") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter")
			or d:IsA("Light") or d:IsA("Sound") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			if p:IsA("MeshPart") then p.TextureID = "" end
			p.Color = MARBLE; p.Material = Enum.Material.Marble; p.Reflectance = 0
		end
	end
end
local function placeOn(model, x, topY, z)
	local cf, size = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(x - cf.Position.X, topY - (cf.Position.Y - size.Y / size or shape; without visible feet, the
-- lowest visible part of the body (never the root, never anything worn).
local BODY = {LeftFoot = true, RightFoot = true, LeftLowerLeg = true, RightLowerLeg = true, LeftUpperLeg = true, RightUpperLeg = true,
	LowerTorso = true, UpperTorso = true, Head = true, LeftHand = true, RightHand = true, LeftLowerArm = true, RightLowerArm = true,
	LeftUpperArm = true, RightUpperArm = true}
local function lowestPoint(model)
	local low = math.huge
	local function consider(p)
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
			low = math.min(low, (p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
		end end end
	end
	for _, n in ipairs({"LeftFoot", "RightFoot"}) do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") and p.Transparency < 0.95 then consider(p) end
	end
	if low == math.hug src:Clone(); a.Name = "GiantAcorn"
	local _, size = a:GetBoundingBox()
	if size.Y > 0 then pcall(function() a:ScaleTo(a:GetScale() * height / size.Y) end) end
	a.Parent = parent or F
	return a
end
local function setPlaque(rec)
	local all = tonumber(rec and rec.total) or totalSquirrels()
	if all <= 0 then all = 44 end
	if rec then
		words.Title.Text = rec.no and ("THE " .. ordinal(rec.no):upper() .. " GRAND KEEPER") or "THE GRAND KEEPER"
		words.Day.Text = "OF THE GREAT ACORN"
		words.Who.Text = tostring(rec.name or "?")
		words.Note.Text = "First to find all " .. tostring(all) .. " squirrels on " .. dateOf(rec.day)
	else
		words.Title.Text = "THE GRAND KEEPER"
		words.Day.Text = ""
		words.Who.Text = "This could be you"
		words.Note.Text = "Be the first to find all " .. tostring(all) .. " squirrels in a day and your statue will stand here."
	end
end
local building = false
-- THE FIGURE, made anywhere: HumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not okM or not model then
		warn("Champion: could not make the figure: " .. tostring(model))
		return nil
	end
	local FX, TOP, PZ = o.x, o.top, o.z                                     -- (the names the pose code below always used)
	model.Name = o.name or "Figure"
	for _, s in ipairs(model:GetDescendants()) do if s:IsA("BaseScript") then s:Destroy() end end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end
	local scale = o.scale or F:GetAttribute("Scale") or 1.5
	pcall(function() model:ScaleTo(scale) end)
	local look = type(rec.look) == "table" and rec.look or nil
	if look then
		local dressKit = RS:FindFirstChild("DressKit")
		local dressModule = dressKit and dressKit:FindFirstChild("CattKit")
		local hatModule = hatKit and hatKit:FindFirstChild("Catalogue")
		if hum and hatModule and type(look.hat) == "string" then
			local ok, cat = pcall(require, hatModule)
			local head = model:FindFirstChild("Head")
			local h = ok and cat.byId and cat.byId[look.hat]
			if head and h and type(cat.fit) == "function" and type(cat.pieces) == "function" then
				for _, acc in ipairs(model:GetChildren()) do
					if acc:IsA("Accessory") and acc.AccessoryType == Enum.AccessoryType.Hat then
						local handle = acc:FindFirstChild("Handle"); if handle then handle.Transparency = 1 end
					end
				end
				local fitCF, s = cat.fit(head, h.style.id)
				local pieces = cat.pieces(hatKit, look.hat, head.CFrame * fitCF, s)
				if pieces and pieces[1] then
					local acc = Instance.new("Accessory"); acc.Name = "WornHat"; acc.AccessoryType = Enum.AccessoryType.Hat
					local handle = pieces[1]; handle.Name = "Handrt1 = handle; w.Parent = handle; acc.Parent = model
					end
				end
			end
		end
	end
	local root = model:FindFirstChild("HumanoidRootPart")
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = (p == root); p.CanCollide = false end end
	local up = Vector3.new(FX, TOP + 30, PZ)
	model:PivotTo(CFrame.lookAt(up, up + (o.look or Vector3.new(0, 0, -1))))   -- the fountain's faces north, toward the fountain
	model.Parent = o.parent or F
	for _ = 1, 6 do RunService.Heartbeat:Wait() end                        -- let the body settle, then freeze it
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	-- One hand holds the acorn up high, the other arm hangs relaxed at the side. The pose is carved rather than
	-- animated: with everything anchored, each arm - and anything worn on it - comes off its joints and is AIMED about
	-- its shcal a0, a1 = d.Attachment0, d.Attachment1
			return (a0 and moving[a0.Parent]) or (a1 and moving[a1.Parent])
		end
		return false
	end
	local function aim(side, dir, bendDeg)
		local att = torso and torso:FindFirstChild(side .. "ShoulderRigAttachment")
		local hand = model:FindFirstChild(side .. "Hand")
		if not (att and hand and typeof(dir) == "Vector3") then return false end
		local pivot = att.WorldPosition
		local cf = torso.CFrame
		local outward = cf.RightVector * ((side == "Right") and 1 or -1)
		local w = (outward * dir.X + cf.UpVector * dir.Y + cf.LookVector * dir.Z).Unit
		-- the arm's parts, and anything worn on each of them (held on by a weld, or hung from one of their attachments)
		local armParts, owner = {}, {}
		for _, n in ipairs({"UpperArm", "LowerArm", "Hand"}) do local pp = model:FindFirstChild(side .. n); if pp then armParts[pp] = n; owner[pp] = n end end
		for _, acc in ipairs(modeare welded directly to the arm. Add those parts to the carved
		-- pose so the outfit follows the raised or relaxed arm instead of remaining behind.
		local function boutiquePart(p)
			local a = p and p.Parent
			while a and a ~= model do
				if a:GetAttribute("BoutiqueSlot") or a:GetAttribute("DressId") then return true end
				a = a.Parent
			end
			return false
		end
		for _ = 1, 4 do
			local changed = false
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
					local p0, p1 = d.Part0, d.Part1
					if owner[p0] and p1 and not owner[p1] and boutiquePart(p1) then owner[p1] = owner[p0]; changed = true
					elseif owner[p1] and p0 and not owner[p0] and boutiquePart(p0) then owner[p0] = owner[p1]; changed = true end
				end
			end
			if not changed then break end
		end
		for _, d in ipairs(model:GetDescendants()) do if linked(d, owner) then d:Dion
			local bendAxis = w:Cross(cf.LookVector)
			if bendAxis.Magnitude > 1e-6 then
				local rot = CFrame.fromAxisAngle(bendAxis.Unit, math.rad(bendDeg))
				local rel = hand.Position - e
				if ((rot * rel) - rel):Dot(cf.LookVector) < 0 then rot = CFrame.fromAxisAngle(bendAxis.Unit, -math.rad(bendDeg)) end
				for pp, n in pairs(owner) do if n ~= "UpperArm" then pp.CFrame = (rot * (pp.CFrame - e)) + e end end
			end
		end
		return true
	end
	local holdSide = (F:GetAttribute("HoldHand") == "Right") and "Right" or "Left"
	local freeSide = (holdSide == "Left") and "Right" or "Left"
	local upR = aim(holdSide, F:GetAttribute("HoldArm") or Vector3.new(0.45, 1, 0.15), 0)                           -- the acorn, held up high
	local upL = aim(freeSide, F:GetAttribute("FreeArm") or Vector3.new(0.22, -1, 0.12), F:GetAttribute("FreeBend") or 15)   -- relaxed at the side
	if hum then hum:Destroy() end
	stoneify(modd")
	local feet = lowestPoint(model)
	local bodyH = (head and feet < math.huge) and (head.Position.Y + head.Size.Y / 2 - feet) or 5.2 * scale
	local a = giantAcorn(math.clamp(bodyH * 0.385, 1.2, 5), o.parent)
	if a then
		if holding then
			placeOn(a, holding.Position.X, holding.Position.Y + holding.Size.Y / 2 - 0.2, holding.Position.Z)   -- resting on the raised hand
		else
			local cf, size = model:GetBoundingBox()
			placeOn(a, cf.Position.X, cf.Position.Y + size.Y / 2, cf.Position.Z)
		end
	end
	return model, a, upR, upL
end
local function buildStatue(rec)
	while building do task.wait(0.2) end
	building = true
	for _, n in ipairs({"Figure", "GiantAcorn"}) do local o = F:FindFirstChild(n); if o then o:Destroy() end end
	setPlaque(rec)
	if not rec then
		local a = giantAcorn(2.6)
		if a then placeOn(a, FX, TOP, PZ) end
		building = false
		return
	end
	local model, _, upR, upL = makeFigure(rec, {x = Fe}; the fountain's is built once, the Hall's through MakeSquirrel
local function makeSquirrel(o)
	local want = F:GetAttribute("SaluteSquirrel") or "ranger_squirrel"
	local src
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do if m:GetAttribute("SquirrelId") == want then src = m break end end
	if not src then warn("Champion: no " .. want .. " to stand by the statue") return nil end
	local m = src:Clone(); m.Name = o.name or "Monument"
	strip(m)
	stoneify(m)
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = true end end
	pcall(function() m:ScaleTo(m:GetScale() * (o.scale or F:GetAttribute("SquirrelScale") or 1.7)) end)
	m.Parent = o.parent or F
	local bones = {}
	for _, b in ipairs(m:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	local spot = Vector3.new(o.x, o.y, o.z)
	local FX, PZ = o.tx, o.tz
	if bones.Root and bo		if fw.Magnitude > 0.01 then
			local left = Vector3.yAxis:Cross(fw.Unit)
			local function tilt(b, deg)
				if not b or not deg or deg == 0 then return end
				local axis = b.WorldCFrame:VectorToObjectSpace(left)
				b.CFrame = b.CFrame * CFrame.fromAxisAngle(axis, math.rad(deg))
			end
			tilt(bones.Chest, F:GetAttribute("ChestTilt"))
			tilt(bones.Head, F:GetAttribute("HeadTilt"))
			tilt(bones.Tail1, F:GetAttribute("TailTilt"))
		end
	end
	placeOn(m, spot.X, spot.Y, spot.Z)
	return m
end
local function buildSquirrel()
	if F:FindFirstChild("Monument") then return end
	makeSquirrel({x = F:GetAttribute("SquirrelX"), y = F:GetAttribute("SquirrelY"), z = F:GetAttribute("SquirrelZ"), tx = FX, tz = PZ, parent = F, name = "Monument"})
end

-- ---- claiming the day ----
local localClaims = {}
local function claim(rec)
	if STUDIO or not store then
		if localClaims[rec.day] then return false, localClaims[rec.== "table" and (oldRec.day or 0) > rec.day then return nil end
			return rec
		end)
	end)
end
-- the Roblox badge: on the win, and on joining for anyone who won before the badge existed (live servers only)
local BadgeService = game:GetService("BadgeService")
local function giveBadge(player)
	local id = tonumber(F:GetAttribute("Badge_champion")) or 0
	if id <= 0 or STUDIO then return end
	task.spawn(function()
		local okH, has = pcall(function() return BadgeService:UserHasBadgeAsync(player.UserId, id) end)
		if okH and not has then
			local ok, err = pcall(function() BadgeService:AwardBadgeAsync(player.UserId, id) end)            -- the current name
			if not ok then ok, err = pcall(function() BadgeService:AwardBadge(player.UserId, id) end) end    -- the older one
			if not ok then warn("Champion: badge award failed: " .. tostring(err)) end
		end
	end)
end

-- ---- the hall: every Grand Keeper in order, allHas(uid, total)                                   -- already won with this many squirrels (or more)?
	for _, e in ipairs(hall) do if e.uid == uid and (tonumber(e.total) or 44) >= total then return true end end
	return false
end
-- every player's screen gets the list (for the Hall of Fame at the Chateau): HallJson on this folder, in order
local HttpService = game:GetService("HttpService")
local function publishHall()
	local out = {}
	for _, e in ipairs(hall) do table.insert(out, {no = e.no, uid = e.uid, name = e.name, day = e.day, total = e.total, look = e.look}) end
	local ok, s = pcall(function() return HttpService:JSONEncode(out) end)
	if ok then F:SetAttribute("HallJson", s) end
end
local function hallMerge(e)                                          -- an entry this server heard about: kept in order, never twice
	if type(e) ~= "table" or not e.no then return end
	for _, x in ipairs(hall) do if x.+ 1, uid = rec.uid, name = rec.name, user = rec.user, day = rec.day, t = rec.t, total = rec.total or 44, look = rec.look}, true
	end
	if STUDIO or not store then
		local e, new = entryFor(hall)
		if new then table.insert(hall, e); sortHall(); publishHall() end
		return e
	end
	for attempt = 1, 4 do
		local mine
		local ok, final = pcall(function()
			return store:UpdateAsync("hall", function(old)
				local list = (type(old) == "table" and type(old.list) == "table") and old.list or {}
				local e, new = entryFor(list)
				mine = e
				if not new then return nil end
				table.insert(list, e)
				return {list = list}
			end)
		end)
		if ok and mine then
			if type(final) == "table" and type(final.list) == "table" then hall = final.list; sortHall() end
			hallMerge(mine)
			publishHall()
			return mine
		end
		task.wait(2 * attempt)
	end
	warn("Champion: could not save the hall number for " .. tostring(rec.ist or {}
			sortHall()
			got = true
			break
		end
		task.wait(2 * attempt)
	end
	if got then
		local launch = F:GetAttribute("LaunchDay") or 20721
		local from = (#hall == 0) and launch or math.max(launch, today() - 14)
		local added = 0
		for d = from, today() do
			local ok, rec = pcall(function() return store:GetAsync("day_" .. tostring(d)) end)
			if ok and type(rec) == "table" and rec.uid then
				rec.day = rec.day or d
				local known = false
				for _, x in ipairs(hall) do if x.uid == rec.uid and x.day == rec.day then known = true end end
				if not known and hallAppend(rec) then added += 1 end
			end
		end
		print(string.format("Champion: the hall has %d keepers (%d added from the day records)", #hall, added))
	end
	publishHall()
	hallLoaded = true
end
task.spawn(loadHall)
-- the title and the numbers the badge case shows, all from the hall (nothing new in the save)
local function applyTitle(d = {}
local function celebrate(rec)
	if type(rec) ~= "table" or not rec.day or celebrated[rec.day] then return end
	celebrated[rec.day] = true
	hallMerge(rec)
	ev:FireAllClients("crowned", rec)
	task.spawn(buildStatue, rec)
end
local function crown(player)
	-- the owner never takes a Keeper slot (Shannon, Oct 1 2026: she completes the 44 for testing in the live game); other
	-- user ids can be listed in the Champion folder attribute NoKeeperUserIds ("123, 456"). Everyone else wins as before.
	local listed = tostring(F:GetAttribute("NoKeeperUserIds") or ""):find("%f[%d]" .. tostring(player.UserId) .. "%f[%D]") ~= nil
	if listed or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId) then
		print(string.format("Champion: %s found them all but takes no Keeper slot (owner / NoKeeperUserIds)", player.Name))
		return
	end
	local day = today()
	local launch = F:GetAttribute("LaunchD= wornLook(player)}
	local won, holder = claim(rec)
	if not won then
		if holder and holder.name then ev:FireClient(player, "late", holder.name, holder.n, total) end
		return
	end
	local e = hallAppend(rec)
	rec.no = e and e.no or nil
	if item(player, "champion_day") <= 0 then setItem(player, "champion_day", n) end   -- (the first day won, kept as before)
	awardItems:Fire(player, "champion_wins", 1)                          -- the days won
	player:SetAttribute("ChampionNew", true)                            -- the badge case says "new badge" only for this
	applyTitle(player)
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"keeper",{keeperNo=rec.no or 0}) end
	print(string.format("Champion: %s is the %s Grand Keeper (day %d)", player.Name, rec.no and ordinal(rec.no) or "?", day))
	saveLatest(rec)
	celebrate(rec)
	if not STUDIO ait(0.5) end
		if not player.Parent then return end
		applyTitle(player)
		local last = frenchFound(player)
		player:GetAttributeChangedSignal("SquirrelsFound"):Connect(function()
			task.wait(0.2); local now = frenchFound(player)
			local total = totalSquirrels()
			if total > 0 and now >= total and last < total then task.spawn(crown, player) end
			last = now
		end)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- ---- on start: the newest Keeper (or the empty plinth), and the squirrel ----
task.spawn(function()
	local t0 = os.clock()
	while totalSquirrels() == 0 and os.clock() - t0 < 30 do task.wait(0.5) end
	buildSquirrel()
	while not hallLoaded and os.clock() - t0 < 90 do task.wait(0.5) end
	local latest = hall[#hall]
	if not latest and not STUDIO and store then                         -- (the hall could not be read: the last one saved)
		locke = function(o) return makeSquirrel(o) end
if STUDIO then
	-- (a hall full of Keepers to look at: HallDebug:Invoke({{uid = ..., name = ...}, ...}) adds them, a day apart)
	local hd = Instance.new("BindableFunction"); hd.Name = "HallDebug"; hd.Parent = F
	hd.OnInvoke = function(list)
		for _, e in ipairs(list) do
			local day = (hall[#hall] and hall[#hall].day or (today() - 20)) + 1
			hallAppend({uid = e.uid, name = e.name, user = e.name, day = day, t = os.time(), total = e.total or 44})
		end
		return #hall
	end
	local dbg = Instance.new("BindableFunction"); dbg.Name = "ChampionDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player) crown(player); return player:GetAttribute("ChampionTitle") end
	-- (a statue of anyone, to check a body shape: StatueDebug:Invoke(userId, name) -> where the feet ended up)
	local sdbg = Instance.new("BindableFunction"); sdbg.Name = "StatueDebug"; sdbg.Parent = F
	sdbg.OnIn