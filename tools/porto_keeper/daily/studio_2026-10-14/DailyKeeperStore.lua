-- Persistence adapter with injected clock/sleep for isolated tests.
local Store = {}
function Store.new(core, dataStore, options)
    local now, wait = options.now, options.wait
    local legacy, state, ready = nil, nil, false
    local api = {}
    local function adopt(observed)
        if not state or observed.revision >= state.revision then state = observed end
    end
    function api.refresh()
        if not dataStore and options.openStore then
            local ok, opened = pcall(options.openStore)
            if ok then dataStore = opened end
        end
        if not dataStore then return false, "daily award persistence unavailable" end
        local ok, value = pcall(function()
            local first = dataStore:GetAsync("first", options.getOptions)
            local daily = dataStore:GetAsync(core.KEY, options.getOptions)
            local merged = core.state(daily, first)
            return {legacy=first, state=merged}
        end)
        if not ok then return false, tostring(value) end
        legacy, ready = value.legacy, true
        adopt(value.state)
        return true, state
    end
    function api.snapshot() return state end
    function api.claim(rec)
        if not ready then
            local ok, err = api.refresh()
            if not ok then return "unavailable", nil, err end
        end
        local lastError
        for attempt = 1, 3 do
            local outcome, holder, observed
            local ok, err = pcall(function()
                dataStore:UpdateAsync(core.KEY, function(old)
                    local nextState
                    nextState, outcome, holder, observed = core.claim(old, legacy, rec, now(), options.offsetHours)
                    return nextState
                end)
            end)
            if ok and outcome then
                adopt(observed)
                return outcome, holder
            end
            lastError = tostring(err)
            if attempt < 3 then wait(attempt * 2) end
        end
        return "unavailable", nil, lastError
    end
    return api
end
return Store
