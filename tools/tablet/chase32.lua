-- chase32 (Oct 21 2026): Shannon: "that note about waiting for someone else to join posted at the top in gold and brown
-- and also at the bottom, we don't need that note in 2 places I think the one at the top is enough". On joining the
-- chase, ChaseClient showed the waiting line twice: the top banner ("Waiting for another player to join the chase...")
-- AND a bottom toast ("You're in the baguette chase! Waiting for someone else to join..."). The bottom toast now only
-- appears when the chase is actually on ("Go get it!"); while waiting, the top banner alone says so. ALL devices.
-- Run in Studio EDIT. Backs ChaseClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local chase = workspace.Baguette.ChaseClient
local old = [[		say("You're in the baguette chase! " .. ((A("Playing") or 0) < (A("MinPlayers") or 2) and "Waiting for someone else to join..." or "Go get it!"))]]
local new = [[		-- (Oct 21 2026, Shannon: the top banner already says the chase is waiting - one place is enough)
		if (A("Playing") or 0) >= (A("MinPlayers") or 2) then say("You're in the baguette chase! Go get it!") end]]
local src = chase.Source
local a, b = src:find(old, 1, true)
assert(a, "ChaseClient: joined toast not found - nothing changed")
assert(not src:find(old, b + 1, true), "ChaseClient: joined toast found twice - nothing changed")
local newSrc = src:sub(1, a - 1) .. new .. src:sub(b + 1)
local bk = chase:Clone(); bk.Name = "ChaseClient_pre_chase32"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(chase, function() return newSrc end)
print(string.format("chase32: ChaseClient %d -> %d chars", #src, #chase.Source))
return "chase32 installed"
