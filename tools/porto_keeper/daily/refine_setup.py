"""Concurrency guards applied to the generated SquirrelSetup, with exact anchors."""
def refine(s):
    def rep(old, new):
        nonlocal s
        assert s.count(old) == 1, (old[:100], s.count(old))
        s = s.replace(old, new, 1)
    rep('local findEpoch, findRevision, saving, resetting = {}, {}, {}, {}',
        'local findEpoch, findRevision, saving, resetting = {}, {}, {}, {}\nlocal sessionPlayer, loading, leaving = {}, {}, {}')
    rep('\tlocal uid = player.UserId\n\tfindEpoch[uid], findRevision[uid] = 0, 0\n\tlocal studioFullFindsPreview', '''\tlocal uid = player.UserId
    local deadline = os.clock() + 60
    while (saving[uid] or resetting[uid] or leaving[uid] or loading[uid]) and os.clock() < deadline do task.wait(0.1) end
    if saving[uid] or resetting[uid] or leaving[uid] or loading[uid] or player.Parent ~= Players then
        warn("SquirrelSetup: previous session still busy; rejoin required"); return
    end
    local previousSession = sessionPlayer[uid]
    sessionPlayer[uid], loading[uid] = player, true
    found[uid], loaded[uid], dirty[uid] = {}, false, nil
    if previousSession and previousSession ~= player then
        owed[uid], owedItems[uid], passportPending[uid], passportLoaded[uid] = nil, nil, nil, nil
    end
    findEpoch[uid], findRevision[uid] = 0, 0
\tlocal studioFullFindsPreview''')
    rep('        if ok then\n            local valid, epoch = pcall(FindsEpoch.read, data)', '''        if sessionPlayer[uid] ~= player or player.Parent ~= Players then loading[uid]=nil; return end
        if ok then
            local valid, epoch = pcall(FindsEpoch.read, data)''')
    rep('\tloaded[uid] = true\n', '\tloading[uid] = nil\n\tloaded[uid] = true\n')
    rep('or saving[uid] or resetting[uid] then return end\n    saving[uid] = true', 'or saving[uid] or resetting[uid] or sessionPlayer[uid] ~= player then return false end\n    saving[uid] = true')
    rep('\t\twarn("SquirrelSetup: save failed for " .. player.Name .. ": " .. tostring(err))\n\tend\nend', '\t\twarn("SquirrelSetup: save failed for " .. player.Name .. ": " .. tostring(err))\n\tend\n    return ok and not stale\nend')
    rep('Players.PlayerRemoving:Connect(function(player)\n\tif dirty[player.UserId] then savePlayer(player) end', '''Players.PlayerRemoving:Connect(function(player)
    local uid = player.UserId
    if sessionPlayer[uid] ~= player then return end
    leaving[uid] = true
    local deadline = os.clock() + 60
    while (saving[uid] or resetting[uid] or loading[uid]) and os.clock() < deadline do task.wait(0.1) end
\tif dirty[uid] then savePlayer(player) end
    leaving[uid] = nil''')
    rep('\t\tfindEpoch[uid]=nil; findRevision[uid]=nil; saving[uid]=nil; resetting[uid]=nil', '\t\tif sessionPlayer[uid] ~= player or saving[uid] or resetting[uid] or loading[uid] then return end\n\t\tsessionPlayer[uid]=nil; findEpoch[uid]=nil; findRevision[uid]=nil; saving[uid]=nil; resetting[uid]=nil')
    rep('or resetting[player.UserId] or (hrp.Position-mesh.Position)', 'or resetting[player.UserId] or leaving[player.UserId] or sessionPlayer[player.UserId] ~= player or (hrp.Position-mesh.Position)')
    rep('''        if canSave[player.UserId] and store then
            collectedEv:Fire(player, id, player:GetAttribute("FoundIds"), findEpoch[player.UserId] or 0, os.time())
        end''', '''        local entry = byId[id]
        if canSave[player.UserId] and store and entry and entry.map == "porto" and player:GetAttribute("Found_porto") == 44 then
            local uid, epoch, at, csv = player.UserId, findEpoch[player.UserId] or 0, os.time(), player:GetAttribute("FoundIds")
            task.spawn(function()
                local deadline = os.clock() + 45
                while saving[uid] and os.clock() < deadline do task.wait(0.1) end
                if resetting[uid] or findEpoch[uid] ~= epoch or sessionPlayer[uid] ~= player or not canSave[uid] then return end
                -- Persist the completed finds and confirm their generation before attempting the award.
                if savePlayer(player) and not resetting[uid] and findEpoch[uid] == epoch and sessionPlayer[uid] == player then
                    collectedEv:Fire(player, id, csv, epoch, at)
                else warn("SquirrelSetup: fresh Italy completion could not be saved; no daily claim was made") end
            end)
        end''')
    rep('if not loaded[uid] or resetting[uid] or os.clock() - (resetAt[uid] or -60)', 'if not loaded[uid] or resetting[uid] or leaving[uid] or sessionPlayer[uid] ~= player or os.clock() - (resetAt[uid] or -60)')
    return s
