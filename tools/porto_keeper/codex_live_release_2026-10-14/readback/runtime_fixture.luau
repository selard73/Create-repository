-- GENERATED: actual runtime queue, render selection, titles and receipt dispatch.
local Core = require("./DailyKeeperCore")
return function(d)
local persistence, renderer = d.persistence, d.renderer
local STUDIO, OFFSET, TOPIC = d.studio or false, 9, "test"
local Players, F, BadgeService, MessagingService = d.Players, d.F, d.BadgeService, d.MessagingService
local game, Enum, task, os, warn = d.game, d.Enum, d.task, d.os, d.warn
local ev, getAttempts, acknowledge, collected = d.ev, d.getAttempts, d.acknowledge, d.collected
local Celebration=require("./KeeperCelebration")
local workspace={GetServerTimeNow=function()return d.os.time()end}
local freshCelebration={Event={Connect=function(_,fn)d.onFresh=fn end}}
local function title() return "Guardian of the Harbour" end
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

return {process=processAttempts,render=renderCurrent,titles=applyTitles,markFresh=celebrationGate.markFresh,forget=celebrationGate.forget,remote=celebrationGate.remoteRecord,announce=announce}
end
