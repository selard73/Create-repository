-- Cosmetic event guards only. No services, award decisions, or saved-data changes.
local Celebration = {}
Celebration.VERSION = 1
Celebration.MAX_DELAY = 120

function Celebration.new(clock, day)
    local startedAt = clock()
    local seen, fresh = {}, {}
    local api = {}
    function api.markFresh(player, rec)
        if type(rec) ~= "table" or rec.uid ~= player.UserId or type(rec.claimId) ~= "string" then return end
        fresh[player] = fresh[player] or {}
        fresh[player][rec.claimId] = true
    end
    function api.forget(player) fresh[player] = nil end
    function api.allows(rec)
        if type(rec) ~= "table" or type(rec.claimId) ~= "string" or seen[rec.claimId]
            or rec.celebrationVersion ~= Celebration.VERSION or type(rec.celebrationAt) ~= "number" then return false end
        local now, at = clock(), rec.celebrationAt
        return at == at and at >= startedAt and at <= now + 5 and now - at <= Celebration.MAX_DELAY
            and rec.day == day(now)
    end
    function api.mark(rec) seen[rec.claimId] = true end
    function api.accept(rec)
        if not api.allows(rec) then return false end
        api.mark(rec)
        return true
    end
    function api.localRecord(player, rec)
        if type(rec) ~= "table" or rec.uid ~= player.UserId or not fresh[player] or not fresh[player][rec.claimId] then return nil end
        local result = {}
        for k, v in pairs(rec) do result[k] = v end
        result.celebrationVersion = Celebration.VERSION
        result.celebrationAt = clock()
        return api.allows(result) and result or nil
    end
    function api.remoteRecord(rec, message)
        if type(rec) ~= "table" or type(message) ~= "table" or rec.claimId ~= message.claimId then return nil end
        local result = {}
        for k, v in pairs(rec) do result[k] = v end
        result.celebrationVersion = message.celebrationVersion
        result.celebrationAt = message.celebrationAt
        return api.allows(result) and result or nil
    end
    return api
end
return Celebration
