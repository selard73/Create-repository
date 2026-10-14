-- PortoKeeperServer: the Guardian of the Harbour. The first player ever to find all of Porto Nocciola's squirrels (attribute
-- Need on this folder, 45 = three sections of 15) wins once, for good: a marble statue of them on the plinth by the
-- lighthouse, holding the harbour key; the plaque names them; the title shows over their head; a badge when Badge_key is set.
-- The statue is made by Champion.MakeStatue (the same figure as the French Keeper), so every statue in the game matches.
-- Record: DataStore "PortoKeeper_v1", key "first" (Shannon, Oct 7 2026: a new store, separate from all player saves).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local BadgeService = game:GetService("BadgeService")
local F = script.Parent
local ev = RS:WaitForChild("PortoKeeperEvent")
local STUDIO = RunService:IsStudio()
local store
if not STUDIO then pcall(function() store = DSS:GetDataStore("PortoKeeper_v1") end) end
local GOLD, GOLD_D, GOLD_DD = Color3.new(1, 0.807843, 0.25098), Color3.new(0.839216, 0.627451, 0.172549), Color3.new(0.745098, 0.533333, 0.156863)
local function need() return tonumber(F:GetAttribute("Need")) or 45 end
local function title() return F:GetAttribute("Title") or "Guardian of the Harbour" end
local function dateOf(t) return os.date("!%B %d, %Y", t) end
-- Porto's finds counted from FoundIds (Oct 9 2026; Found_porto may lag or be missing), as the French Keeper counts
local PORTO_ID = {}
do
	local FRENCH = {forest = true, village = true, domaine = true}
	local ok, R = pcall(require, workspace.SquirrelScripts.SquirrelRegistry)
	if ok then for _, q in ipairs(R.squirrels) do if not FRENCH[q.map] then PORTO_ID[q.id] = true end end end
end
local function portoFound(player)
	local s = player:GetAttribute("FoundIds")
	if type(s) ~= "string" or next(PORTO_ID) == nil then return tonumber(player:GetAttribute("Found_porto")) or 0 end
	local n = 0
	for id in s:gmatch("[^,]+") do if PORTO_ID[id] then n += 1 end end
	return n
end

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
	words.Day.Text = "OF PORTO NOCCIOLA"
	if rec then
		words.Who.Text = tostring(rec.name or "?")
		words.Note.Text = "First to find all " .. tostring(rec.total or need()) .. " squirrels of Porto Nocciola, on " .. dateOf(rec.t or os.time())
	else
		words.Who.Text = "This could be you"
		words.Note.Text = "Be the first to find all " .. tostring(need()) .. " squirrels of Porto Nocciola and your statue will stand here, holding the harbour key."
	end
end

-- ---- the statue ----
local building = false
local function buildStatue(rec)
	while building do task.wait(0.2) end
	building = true
	for _, n in ipairs({"Figure", "Key", "GiantAcorn"}) do local o = F:FindFirstChild(n); if o then o:Destroy() end end
	setPlaque(rec)
	local PX, PZ, TOP = F:GetAttribute("PlinthX"), F:GetAttribute("PlinthZ"), F:GetAttribute("TopY")
	local FX = F:GetAttribute("FigureX") or PX
	if not rec then
		makeKey(F:GetAttribute("RestKeyHeight") or 3.4, PX, TOP, PZ, facingYaw(), F)
		building = false
		return
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
	building = false
end

-- ---- the record ----
local first = nil        -- the winner's record, once known
local loaded = false
local function giveBadge(player)
	local id = tonumber(F:GetAttribute("Badge_key")) or 0
	if id <= 0 or STUDIO then return end
	task.spawn(function()
		local okH, has = pcall(function() return BadgeService:UserHasBadgeAsync(player.UserId, id) end)
		if okH and not has then
			local ok, e = pcall(function() BadgeService:AwardBadgeAsync(player.UserId, id) end)
			if not ok then warn("PortoKeeper: badge award failed: " .. tostring(e)) end
		end
	end)
end
local function applyTitle(player)
	if first and first.uid == player.UserId then
		player:SetAttribute("PortoKeeperTitle", title())
		giveBadge(player)
	end
end
local function claim(rec)
	if STUDIO or not store then
		if first then return false, first end
		first = rec
		return true
	end
	for attempt = 1, 3 do
		local won, holder = false, nil
		local ok = pcall(function()
			store:UpdateAsync("first", function(old)
				if old ~= nil then won = false; holder = old; return nil end
				won = true; return rec
			end)
		end)
		if ok then return won, holder end
		task.wait(2 * attempt)
	end
	return false, nil
end
local function load()
	if STUDIO or not store then loaded = true; return end
	for attempt = 1, 5 do
		local ok, v = pcall(function() return store:GetAsync("first") end)
		if ok then if type(v) == "table" and v.uid then first = v end loaded = true; return end
		task.wait(2 * attempt)
	end
	loaded = true
end
local function celebrate(rec)
	ev:FireAllClients("crowned", rec)
	task.spawn(buildStatue, rec)
end
local function crown(player, force)
	local listed = tostring(F:GetAttribute("NoKeeperUserIds") or ""):find("%f[%d]" .. tostring(player.UserId) .. "%f[%D]") ~= nil
	local owner = (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId)
	if (listed or owner) and not force then
		print(string.format("PortoKeeper: %s found them all but takes no Guardian slot (owner / NoKeeperUserIds)", player.Name))
		return
	end
	local t0 = os.clock()
	while not loaded and os.clock() - t0 < 60 do task.wait(0.5) end
	if first then
		ev:FireClient(player, first.uid == player.UserId and "already" or "late", first.name)
		return
	end
	local rec = {uid = player.UserId, name = player.DisplayName, user = player.Name, t = os.time(), total = need()}
	local won, holder = claim(rec)
	if not won then
		if holder then first = holder; ev:FireClient(player, "late", holder.name) end
		return
	end
	first = rec
	applyTitle(player)
	print(string.format("PortoKeeper: %s is the %s (all %d Porto squirrels)", player.Name, title(), rec.total))
	celebrate(rec)
end

-- ---- watching every player's Porto finds (Found_porto is kept by SquirrelSetup) ----
local function watch(player)
	task.spawn(function()
		local t0 = os.clock()
		while player.Parent and not loaded and os.clock() - t0 < 60 do task.wait(0.5) end
		if not player.Parent then return end
		applyTitle(player)
		local last = portoFound(player)
		if last >= need() and not first then task.spawn(crown, player) end   -- found them all before the Guardian stood here (Oct 9 2026)
		local function check()
			task.wait(0.2); local now = portoFound(player)
			if now >= need() and last < need() then task.spawn(crown, player) end
			last = now
		end
		player:GetAttributeChangedSignal("Found_porto"):Connect(check)
		player:GetAttributeChangedSignal("FoundIds"):Connect(check)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

task.spawn(function()
	load()
	buildStatue(first)
	for _, p in ipairs(Players:GetPlayers()) do applyTitle(p) end
end)
if STUDIO then
	-- Studio only: KeeperDebug:Invoke(player) crowns that player (owner too); KeeperDebug:Invoke(nil) clears back to the placeholder
	local dbg = Instance.new("BindableFunction"); dbg.Name = "KeeperDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player)
		if not player then
			if first then local p = Players:GetPlayerByUserId(first.uid) if p then p:SetAttribute("PortoKeeperTitle", nil) end end
			first = nil; buildStatue(nil); return "cleared"
		end
		first = nil; crown(player, true); return player:GetAttribute("PortoKeeperTitle")
	end
end
print("PortoKeeper: ready (" .. title() .. " at " .. need() .. " squirrels)")

-- (Oct 11, Shannon: the Guardian's plaque showed his name but no statue stood) the statue maker may not have been ready when
-- the server started; for the first minute, every 20 s, if a Guardian is recorded and no Figure stands, build it again
task.spawn(function()
	for _ = 1, 3 do
		task.wait(20)
		if type(first) == "table" and first.uid and not F:FindFirstChild("Figure") then
			print("PortoKeeper: no statue yet for " .. tostring(first.name) .. "; building it again")
			local ok, err = pcall(buildStatue, first)
			if not ok then warn("PortoKeeper: the statue retry failed: " .. tostring(err)) end
		end
	end
end)

