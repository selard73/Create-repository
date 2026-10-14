-- Pure reset/save guards. An old session may not merge finds across a successful reset.
local Epoch = {}
function Epoch.read(data)
    if data == nil then return 0 end
    assert(type(data) == "table", "Invalid player save")
    local value = data.findsEpoch or 0
    assert(type(value) == "number" and value >= 0 and value % 1 == 0, "Invalid finds reset generation")
    return value
end

function Epoch.write(old, expected, fields)
    if Epoch.read(old) ~= expected then return nil end
    local out = table.clone(old or {})
    for k, v in pairs(fields) do out[k] = v end
    out.findsEpoch = expected
    return out
end

function Epoch.reset(old, expected, at, token)
    -- Repeating a reset after a lost response must not increment its generation twice.
    if type(old) == "table" and old.findsResetToken == token then return table.clone(old) end
    if Epoch.read(old) ~= expected then return nil end
    local out = table.clone(old or {})
    out.found = {}
    out.findsEpoch = expected + 1
    out.findsResetToken = token
    out.updated = at
    return out
end
return Epoch
