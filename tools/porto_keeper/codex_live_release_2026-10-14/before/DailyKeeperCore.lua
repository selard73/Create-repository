-- Pure rules. No Roblox services, player mutations, or datastore access.
local Core = {}
Core.KEY = "daily_v2"
Core.VERSION = 2
Core.NEED = 44

local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = copy(v) end
    return out
end
Core.copy = copy

function Core.day(at, offsetHours)
    return math.floor((at - (offsetHours or 9) * 3600) / 86400)
end

function Core.registry(entries)
    local all, italy = {}, {}
    for _, entry in ipairs(entries) do
        all[entry.id] = true
        if entry.map == "porto" then italy[entry.id] = true end
    end
    return all, italy
end

function Core.normalize(id, all)
    local sid = tostring(id):gsub("_color$", "")
    if not all[sid] then
        local base = sid:match("^(.-)_%d+$")
        if base and all[base] then sid = base end
    end
    return sid
end

function Core.count(csv, all, italy)
    if type(csv) ~= "string" then return 0 end
    local seen, count = {}, 0
    for id in csv:gmatch("[^,]+") do
        local sid = Core.normalize(id, all)
        if italy[sid] and not seen[sid] then seen[sid] = true; count += 1 end
    end
    return count
end

-- Called only by the server-side collection event, never from loaded attributes.
function Core.freshCompletion(id, csv, epoch, all, italy)
    return type(epoch) == "number" and epoch >= 0 and epoch % 1 == 0
        and italy[Core.normalize(id, all)] == true
        and Core.count(csv, all, italy) == Core.NEED
end

function Core.excluded(uid, creatorId, userOwned, noKeeperIds)
    local listed = tostring(noKeeperIds or ""):find("%f[%d]" .. tostring(uid) .. "%f[%D]") ~= nil
    return listed or (userOwned and uid == creatorId)
end

local function validRecord(rec)
    return type(rec) == "table" and type(rec.uid) == "number" and rec.uid > 0
end

function Core.state(old, legacy)
    if old ~= nil then
        assert(type(old) == "table" and old.version == Core.VERSION, "Unsupported Italy daily ledger")
        assert(type(old.days) == "table" and type(old.winners) == "table" and type(old.attempts) == "table", "Invalid Italy daily ledger")
    end
    local state = old and copy(old) or {version=Core.VERSION, revision=0, days={}, winners={}, attempts={}}
    state.revision = state.revision or 0
    if legacy ~= nil then
        assert(validRecord(legacy), "Invalid legacy Italy award; refusing migration")
        -- Historical 'first' stays untouched. Do not invent a daily award for its date.
        state.legacy = state.legacy or copy(legacy)
        state.winners[tostring(legacy.uid)] = state.winners[tostring(legacy.uid)] or copy(legacy)
    end
    return state
end

function Core.current(state, at, offsetHours)
    return state and state.days[tostring(Core.day(at, offsetHours))] or nil
end

-- The callback uses this one record for daily vacancy, lifetime winners, and reset attempts.
-- Returning nil means cancel the write. All effects/notifications happen after persistence.
function Core.claim(old, legacy, rec, now, offsetHours)
    local state = Core.state(old, legacy)
    assert(validRecord(rec) and type(rec.claimId) == "string", "Invalid Italy candidate")
    assert(type(rec.epoch) == "number" and rec.epoch >= 0 and rec.epoch % 1 == 0, "Invalid reset generation")
    assert(rec.total == Core.NEED and rec.day == Core.day(rec.t, offsetHours), "Invalid Italy completion")
    local uid, day = tostring(rec.uid), tostring(rec.day)
    local prior = state.winners[uid]
    -- A lost response after a successful write must recover the same win, not create another.
    if prior then
        if prior.claimId == rec.claimId then return nil, "won", copy(prior), state end
        return nil, "already", copy(prior), state
    end
    local attempt = state.attempts[uid]
    if attempt and rec.epoch <= attempt.epoch then
        if attempt.claimId == rec.claimId then
            return nil, "late", copy(state.days[tostring(attempt.day)]), state
        end
        return nil, "attempted", copy(state.days[tostring(attempt.day)]), state
    end
    if rec.t > now + 5 then return nil, "unavailable", nil, state end
    if rec.durable ~= true and now - rec.t > 300 then return nil, "expired", nil, state end
    -- Durable intents were saved atomically with the 44th find. Recovery can only
    -- claim that original day, even after an extended outage; never today's slot.
    -- Keep the completion's day even if a retry crosses 09:00 UTC. It cannot occupy the new day.
    state.attempts[uid] = {epoch=rec.epoch, day=rec.day, t=rec.t, claimId=rec.claimId}
    state.revision += 1
    local holder = state.days[day]
    if holder then return state, "late", copy(holder), state end
    state.days[day] = copy(rec)
    state.winners[uid] = copy(rec)
    return state, "won", copy(rec), state
end

-- A serialized render queue: a slow old avatar cannot overwrite a newer requested winner.
-- Failed builds remain retryable; the lock is released even when build throws.
function Core.renderer(build, spawn, onError)
    local desired, rendered, busy
    local renderer = {}
    function renderer.request(key, rec, force)
        desired = {key=key, rec=rec}
        if force then rendered = nil end
        if busy or rendered == key then return end
        busy = true
        spawn(function()
            while desired do
                local target = desired
                local ok, complete = pcall(build, target.rec)
                if ok and complete then rendered = target.key else
                    rendered = nil
                    if onError then onError(ok and "avatar not ready" or tostring(complete)) end
                end
                if desired.key == target.key then break end
            end
            busy = false
        end)
    end
    function renderer.status() return rendered, busy end
    return renderer
end

return Core
