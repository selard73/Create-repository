-- Pure reset/save guards. An old session may not merge finds across a successful reset.
local Epoch = {}
local function copy(t)
    if type(t) ~= "table" then return t end
    local out={};for k,v in pairs(t) do out[k]=copy(v) end;return out
end
Epoch.copy = copy

function Epoch.newAttempt(uid, name, user, epoch, at, offset, claimId)
    return {version=1, durable=true, uid=uid, name=name, user=user, epoch=epoch,
        t=at, offset=offset, day=math.floor((at-offset*3600)/86400), total=44, claimId=claimId}
end

function Epoch.validAttempt(rec, uid, maxEpoch)
    return type(rec)=="table" and rec.version==1 and rec.durable==true and rec.uid==uid
        and type(rec.claimId)=="string" and #rec.claimId>0 and #rec.claimId<=128
        and type(rec.epoch)=="number" and rec.epoch>=0 and rec.epoch%1==0 and rec.epoch<=maxEpoch
        and type(rec.t)=="number" and rec.t>0 and type(rec.offset)=="number"
        and rec.day==math.floor((rec.t-rec.offset*3600)/86400) and rec.total==44
        and type(rec.name)=="string" and type(rec.user)=="string"
end

function Epoch.pending(records, uid, maxEpoch, acks)
    local out={}
    if type(records)=="table" then
        for key,rec in pairs(records) do
            if Epoch.validAttempt(rec,uid,maxEpoch) and key==tostring(rec.epoch) and not (acks and acks[rec.claimId]) then
                table.insert(out,copy(rec))
            end
        end
    end
    table.sort(out,function(a,b)return a.epoch<b.epoch end)
    return out
end

function Epoch.mergeAttempts(old, additions, acks)
    local out=type(old)=="table" and copy(old) or {}
    for key,rec in pairs(additions or {}) do
        -- The first persisted intent for a generation is canonical across sessions.
        if out[key]==nil then out[key]=copy(rec) end
    end
    for key,rec in pairs(out) do
        if type(rec)=="table" and acks and acks[rec.claimId] then out[key]=nil end
    end
    return out
end

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
