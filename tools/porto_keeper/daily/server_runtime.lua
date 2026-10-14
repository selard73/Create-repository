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
