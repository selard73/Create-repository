"""Build reviewed Studio source from exact baseline snapshots; no Roblox connection."""
from pathlib import Path
from refine_setup import refine
from recovery_setup import recoverable
ROOT = Path(__file__).resolve().parent
def replace_once(s, old, new):
    assert s.count(old) == 1, (old[:100], s.count(old))
    return s.replace(old, new, 1)

def build():
    old = (ROOT/'PortoKeeperServer.baseline.lua').read_text(encoding='utf-8')
    visual = old[old.index('-- ---- the key ----'):old.index('-- ---- the record ----')]
    visual = replace_once(visual, 'dateOf(rec.t or os.time())', 'dateOf(rec)')
    visual = replace_once(visual, '"OF PORTO NOCCIOLA"', '"OF PORTO NOCCIOLA / DAILY GUARDIAN"')
    visual = replace_once(visual, '"This could be you"', '"Awaiting today\'s Guardian"')
    visual = replace_once(visual, '" squirrels of Porto Nocciola and your statue will stand here, holding the harbour key."', '" squirrels of Porto Nocciola today. Returning with all 44 does not count; reset your finds to try again."')
    visual = replace_once(visual, 'local building = false\n', '')
    visual = replace_once(visual, '\twhile building do task.wait(0.2) end\n\tbuilding = true\n', '')
    visual = replace_once(visual, '\t\tbuilding = false\n\t\treturn\n', '\t\treturn true\n')
    visual = replace_once(visual, '\tbuilding = false\nend', '\treturn model ~= nil\nend')
    (ROOT/'PortoKeeperServer.lua').write_text((ROOT/'server_header.lua').read_text()+ '\n'+visual+'\n'+(ROOT/'server_runtime.lua').read_text(),encoding='utf-8')

    s=(ROOT/'SquirrelSetup.baseline.lua').read_text(encoding='utf-8')
    s=replace_once(s, 'local dirty = {}', '''local FindsEpoch = require(script.Parent:WaitForChild("FindsEpoch"))
local findEpoch, findRevision, saving, resetting = {}, {}, {}, {}
local collectedEv = ReplicatedStorage:FindFirstChild("SquirrelCollectedServer") or Instance.new("BindableEvent")
assert(collectedEv:IsA("BindableEvent"), "SquirrelCollectedServer must be server-only")
collectedEv.Name = "SquirrelCollectedServer"; collectedEv.Parent = ReplicatedStorage
local dirty = {}''')
    s=replace_once(s, '\tlocal uid = player.UserId\n\tlocal studioFullFindsPreview', '\tlocal uid = player.UserId\n\tfindEpoch[uid], findRevision[uid] = 0, 0\n\tlocal studioFullFindsPreview')
    s=replace_once(s, '\t\tif ok then\n\t\t\tpassportLoaded', '''        if ok then
            local valid, epoch = pcall(FindsEpoch.read, data)
            if valid then findEpoch[uid] = epoch else canSave[uid] = false; warn("SquirrelSetup: invalid reset generation; saving and daily awards disabled") end
\t\t\tpassportLoaded''')
    s=replace_once(s, '\tif not store or not canSave[uid] or not loaded[uid] then return end\n', '''\tif not store or not canSave[uid] or not loaded[uid] or saving[uid] or resetting[uid] then return end
    saving[uid] = true
    local epoch, revision, stale = findEpoch[uid] or 0, findRevision[uid] or 0, false
''')
    s=replace_once(s, '\t\tstore:UpdateAsync("u" .. uid, function(old)                -- while it is in flight\n', '''\t\tstore:UpdateAsync("u" .. uid, function(old)                -- while it is in flight
            stale = FindsEpoch.read(old) ~= epoch
            if stale then return nil end
''')
    oldReturn='\t\t\treturn {found = out, area = area, acorns = acorns, items = items, passport=Journal.merge(type(old)=="table" and old.passport or {},movedPassport), updated = os.time()}'
    s=replace_once(s,oldReturn,'\t\t\treturn FindsEpoch.write(old, epoch, {found = out, area = area, acorns = acorns, items = items, passport=Journal.merge(type(old)=="table" and old.passport or {},movedPassport), updated = os.time()})')
    s=replace_once(s, '\tif ok then\n\t\tdirty[uid] = nil', '''    saving[uid] = nil
    if stale then
        canSave[uid] = false
        warn("SquirrelSetup: newer reset detected; stale session cannot save or compete; rejoin required")
        return
    end
\tif ok then
\t\tdirty[uid] = nil''')
    s=replace_once(s, '\telse\n\t\twarn("SquirrelSetup: save failed for "', '''        if (findRevision[uid] or 0) ~= revision or (owed[uid] or 0) ~= 0 or next(owedItems[uid] or {}) then dirty[uid] = true end
\telse
\t\twarn("SquirrelSetup: save failed for "''')
    s=replace_once(s, '\t\tfound[uid] = nil; loaded[uid] = nil;', '\t\tfindEpoch[uid]=nil; findRevision[uid]=nil; saving[uid]=nil; resetting[uid]=nil\n\t\tfound[uid] = nil; loaded[uid] = nil;')
    s=replace_once(s, 'if not hrp or not hum or hum.Health<=0 or not loaded[player.UserId] or ', 'if not hrp or not hum or hum.Health<=0 or not loaded[player.UserId] or resetting[player.UserId] or ')
    s=replace_once(s, '\t\tt[id] = true\n\t\tdirty[player.UserId] = true', '\t\tt[id] = true\n        findRevision[player.UserId] = (findRevision[player.UserId] or 0) + 1\n\t\tdirty[player.UserId] = true')
    s=replace_once(s, '\t\tpublishCounts(player)\n\t\tev:FireClient(player, id)', '''\t\tpublishCounts(player)
        if canSave[player.UserId] and store then
            collectedEv:Fire(player, id, player:GetAttribute("FoundIds"), findEpoch[player.UserId] or 0, os.time())
        end
\t\tev:FireClient(player, id)''')
    start=s.index('resetEv.OnServerEvent:Connect(function(player)')
    end=s.index('\nend)',start)+len('\nend)')
    reset='''resetEv.OnServerEvent:Connect(function(player)
    local uid = player.UserId
    if not loaded[uid] or resetting[uid] or os.clock() - (resetAt[uid] or -60) < 5 then return end
    if not store or not canSave[uid] then warn("SquirrelSetup: reset refused because this save is unavailable"); return end
    resetAt[uid], resetting[uid] = os.clock(), true
    local deadline = os.clock() + 45
    while saving[uid] and os.clock() < deadline do task.wait(0.1) end
    if saving[uid] then resetting[uid]=nil; warn("SquirrelSetup: reset timed out waiting for save"); return end
    local expected, token = findEpoch[uid] or 0, Http:GenerateGUID(false)
    local saved, lastError
    for attempt = 1, 3 do
        local stale = false
        local ok, result = pcall(function()
            return store:UpdateAsync("u" .. uid, function(old)
                local out = FindsEpoch.reset(old, expected, os.time(), token)
                stale = out == nil
                if not out then return nil end
                out.passport = Journal.merge(out.passport or {}, passportPending[uid] or {})
                return out
            end)
        end)
        if ok and result and result.findsResetToken == token then saved=result; break end
        if stale then canSave[uid]=false; lastError="a newer reset exists; rejoin required"; break end
        lastError=tostring(result)
        if attempt < 3 then task.wait(attempt) end
    end
    if not saved then
        -- A lost response could mean the reset committed. Freeze saving/awards until rejoin;
        -- never put the old finds back or pretend an unconfirmed reset succeeded.
        canSave[uid]=false; resetting[uid]=nil
        warn("SquirrelSetup: reset not confirmed; rejoin before saving or competing: " .. tostring(lastError))
        return
    end
    found[uid] = {}
    findEpoch[uid] = FindsEpoch.read(saved)
    findRevision[uid] = (findRevision[uid] or 0) + 1
    dirty[uid] = true -- keep any acorns/items earned while the reset request was in flight
    player:SetAttribute("SquirrelsFound", 0)
    publishCounts(player)
    resetting[uid] = nil
    resetEv:FireClient(player)
    print("SquirrelSetup: " .. player.Name .. " reset finds; generation " .. findEpoch[uid])
end)'''
    s=s[:start]+reset+s[end:]
    (ROOT/'SquirrelSetup.lua').write_text(recoverable(refine(s)),encoding='utf-8')

    client=(ROOT/'PortoKeeperClient.baseline.lua').read_text(encoding='utf-8')
    client=client.replace('or 45','or 44').replace('First to find all ', 'First today to find all ')
    client=client.replace('squirrels of Porto Nocciola first and is the', 'squirrels of Porto Nocciola first today and is the')
    client=client.replace('%s got there first and holds the harbour key.', '%s got there first today. To compete on another day, reset your finds and collect all 44 again.')
    client=replace_once(client, '\telseif what == "already" then', '''    elseif what == "reset_needed" then
        chat("To compete on another day, reset your finds and collect all 44 Italy squirrels again.")
    elseif what == "unavailable" then
        chat("Your Guardian result is pending. We will retry automatically and when you rejoin, for the day you completed Italy.")
\telseif what == "already" then''')
    client=replace_once(client, 'ev.OnClientEvent:Connect(function(what, a)', 'local receipts = {}\nev.OnClientEvent:Connect(function(what, a)')
    client=replace_once(client, '\telseif what == "late" then\n\t\tchat(string.format("You found every squirrel in Porto Nocciola! %s got there first today. To compete on another day, reset your finds and collect all 44 again.", tostring(a)))', '''    elseif what == "recovered" and type(a) == "table" then
        if receipts[a.claimId] then return end
        receipts[a.claimId] = true
        chat("Your Guardian award for " .. os.date("!%B %d, %Y", a.day * 86400 + 43200) .. " is confirmed. You keep your title; the lighthouse displays today's winner.")
    elseif what == "late" then
        local record = type(a) == "table" and a or {name=tostring(a)}
        if record.claimId and receipts[record.claimId] then return end
        if record.claimId then receipts[record.claimId] = true end
        local date = record.day and (" for " .. os.date("!%B %d, %Y", record.day * 86400 + 43200)) or " today"
        chat("You found every squirrel in Porto Nocciola! " .. tostring(record.name) .. " holds the award" .. date .. ". To compete on another day, reset your finds and collect all 44 again.")''')
    (ROOT/'PortoKeeperClient.lua').write_text(client,encoding='utf-8')
    print('Built daily server/client and guarded finds persistence from verified baselines.')

if __name__=='__main__': build()
