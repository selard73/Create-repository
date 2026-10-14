-- Guardian of the Harbour: first fresh Italy completion per 09:00 UTC day.
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
