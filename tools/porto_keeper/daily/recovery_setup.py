"""Add a durable completion outbox to the generated and concurrency-guarded setup."""
def recoverable(s):
    def rep(old,new):
        nonlocal s
        assert s.count(old)==1,(old[:100],s.count(old))
        s=s.replace(old,new,1)
    rep('local sessionPlayer, loading, leaving = {}, {}, {}', 'local sessionPlayer, loading, leaving = {}, {}, {}\nlocal italyAdditions, italyConfirmed, italyAcks = {}, {}, {}')
    rep('local function foundList(player)', '''-- Italy durable completion helpers: only confirmed saved intents can be replayed.
local function pendingItaly(player)
    local uid=player.UserId
    if sessionPlayer[uid]~=player or not canSave[uid] then return {} end
    return FindsEpoch.pending(italyConfirmed[uid],uid,findEpoch[uid] or 0,italyAcks[uid])
end
local function emitItaly(player)
    local attempts=pendingItaly(player)
    if #attempts>0 then collectedEv:Fire(player,attempts) end
end
local function acknowledgeItaly(player,claimId)
    local uid=player.UserId
    if sessionPlayer[uid]~=player or type(claimId)~="string" then return end
    for _,rec in ipairs(pendingItaly(player)) do
        if rec.claimId==claimId then
            italyAcks[uid]=italyAcks[uid] or {};italyAcks[uid][claimId]=true;dirty[uid]=true;return
        end
    end
end
local function foundList(player)''')
    rep('    findEpoch[uid], findRevision[uid] = 0, 0\n', '    findEpoch[uid], findRevision[uid] = 0, 0\n    italyAdditions[uid], italyConfirmed[uid], italyAcks[uid] = {}, {}, {}\n')
    rep('if valid then findEpoch[uid] = epoch else canSave[uid]', 'if valid then findEpoch[uid] = epoch; italyConfirmed[uid] = type(data)=="table" and FindsEpoch.copy(data.italyAttempts or {}) or {} else canSave[uid]')
    rep('\tpublishCounts(player)\nend\nlocal function savePlayer', '\tpublishCounts(player)\n    emitItaly(player)\nend\nlocal function savePlayer')
    rep('local epoch, revision, stale = findEpoch[uid] or 0, findRevision[uid] or 0, false\n', 'local epoch, revision, stale = findEpoch[uid] or 0, findRevision[uid] or 0, false\n    local movedItaly, movedAcks = FindsEpoch.copy(italyAdditions[uid] or {}), FindsEpoch.copy(italyAcks[uid] or {})\n')
    rep('\t\tstore:UpdateAsync("u" .. uid, function(old)                -- while it is in flight', '\t\treturn store:UpdateAsync("u" .. uid, function(old)                -- while it is in flight')
    rep('return FindsEpoch.write(old, epoch, {found = out, area = area, acorns = acorns, items = items, passport=', 'return FindsEpoch.write(old, epoch, {found = out, area = area, acorns = acorns, items = items, italyAttempts=FindsEpoch.mergeAttempts(type(old)=="table" and old.italyAttempts, movedItaly, movedAcks), passport=')
    rep('\tif ok then\n\t\tdirty[uid] = nil', '''\tif ok then
        italyConfirmed[uid] = type(err)=="table" and FindsEpoch.copy(err.italyAttempts or {}) or {}
        for key,rec in pairs(movedItaly) do
            if italyAdditions[uid] and italyAdditions[uid][key] and italyAdditions[uid][key].claimId==rec.claimId then italyAdditions[uid][key]=nil end
        end
        for id in pairs(movedAcks) do if italyAcks[uid] then italyAcks[uid][id]=nil end end
\t\tdirty[uid] = nil''')
    rep('or next(owedItems[uid] or {}) then dirty[uid] = true end', 'or next(owedItems[uid] or {}) or next(italyAdditions[uid] or {}) or next(italyAcks[uid] or {}) then dirty[uid] = true end\n        emitItaly(player)')
    rep('\t\tsessionPlayer[uid]=nil; findEpoch[uid]=nil;', '\t\titalyAdditions[uid]=nil;italyConfirmed[uid]=nil;italyAcks[uid]=nil\n\t\tsessionPlayer[uid]=nil; findEpoch[uid]=nil;')
    rep('''            local uid, epoch, at, csv = player.UserId, findEpoch[player.UserId] or 0, os.time(), player:GetAttribute("FoundIds")
            task.spawn(function()''', '''            local uid, epoch, at = player.UserId, findEpoch[player.UserId] or 0, os.time()
            local daily=workspace:FindFirstChild("Daily")
            local offset=daily and daily:GetAttribute("DayOffsetHours") or 9
            italyAdditions[uid]=italyAdditions[uid] or {}
            italyAdditions[uid][tostring(epoch)]=FindsEpoch.newAttempt(uid,player.DisplayName,player.Name,epoch,at,offset,Http:GenerateGUID(false))
            -- No yield occurs between recording the 44th find and staging this intent.
            -- The next save writes BOTH in the same player-key UpdateAsync transaction.
            task.spawn(function()''')
    rep('''                -- Persist the completed finds and confirm their generation before attempting the award.
                if savePlayer(player) and not resetting[uid] and findEpoch[uid] == epoch and sessionPlayer[uid] == player then
                    collectedEv:Fire(player, id, csv, epoch, at)
                else warn("SquirrelSetup: fresh Italy completion could not be saved; no daily claim was made") end''', '''                -- savePlayer emits only the intents returned by the confirmed datastore save.
                -- Lost responses leave the outbox durable for a later save or rejoin to recover.
                if not savePlayer(player) then warn("SquirrelSetup: Italy completion save pending; daily attempt will recover after persistence") end''')
    rep('    found[uid] = {}\n    findEpoch[uid] = FindsEpoch.read(saved)', '    found[uid] = {}\n    italyAdditions[uid] = {}\n    italyConfirmed[uid] = FindsEpoch.copy(saved.italyAttempts or {})\n    findEpoch[uid] = FindsEpoch.read(saved)')
    rep('    resetEv:FireClient(player)\n', '    resetEv:FireClient(player)\n    emitItaly(player)\n')
    s+='''
-- Startup/periodic recovery handshake. These are server-only Bindables, never remotes.
local getItaly=ReplicatedStorage:FindFirstChild("GetItalyAttempts") or Instance.new("BindableFunction")
assert(getItaly:IsA("BindableFunction"));getItaly.Name="GetItalyAttempts";getItaly.OnInvoke=pendingItaly;getItaly.Parent=ReplicatedStorage
local ackItaly=ReplicatedStorage:FindFirstChild("AckItalyAttempt") or Instance.new("BindableEvent")
assert(ackItaly:IsA("BindableEvent"));ackItaly.Name="AckItalyAttempt";ackItaly.Parent=ReplicatedStorage
ackItaly.Event:Connect(acknowledgeItaly)
'''
    return s
