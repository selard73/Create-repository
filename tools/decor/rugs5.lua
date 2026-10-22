-- rugs5 (Oct 21 2026, late): the live "crickets" bug, found for real. The rugs4 chain's watcher checked the
-- once-ever flag ONCE at session start: on Shannon's live account the flag was still 1 from the previous round for
-- the first seconds after her save loaded, so the watcher ended itself for the whole session - and the treehouse
-- reset wiped the flag two seconds AFTER that. Her rebuild then happened in a session where nothing was watching.
-- Studio tests never caught it because a Studio account starts blank. The watcher now NEVER quits: it idles while
-- the flag is on the save, arms whenever the tutorial becomes owed (flag off + house done + player in the room),
-- and so also survives a reset that happens mid-session - exactly her join order.
-- Run in Studio EDIT. Backs TreehouseClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local tc = workspace.Treehouse.TreehouseClient
local src = tc.Source
assert(not src:find("rugs5", 1, true), "TreehouseClient already patched")
-- the whole arming skeleton is replaced; the step bodies stay as installed by rugs4
local old = [=[	while not flag() do
		while not flag() and not (built() and inRoom()) do task.wait(0.5) end
		if flag() then break end]=]
local new = [=[	while true do
		-- (rugs5) arm whenever the tutorial is owed: flag off the save, the house done, the player in the room.
		-- The flag being ON here is no reason to quit - a reset may wipe it at any moment, even mid-session.
		while flag() or not (built() and inRoom()) do task.wait(0.5) end]=]
local a, b = src:find(old, 1, true)
assert(a, "TreehouseClient: rugs4 arm loop not found - nothing changed")
assert(not src:find(old, b + 1, true), "TreehouseClient: arm loop found twice - nothing changed")
src = src:sub(1, a - 1) .. new .. src:sub(b + 1)
-- the finale's break leaves the loop forever; now it just returns to the idle wait
local old2 = [=[			say("Looks lovely in here! Swap or store your rugs any time.", 7)
			break
		end]=]
local new2 = [=[			say("Looks lovely in here! Swap or store your rugs any time.", 7)
		end]=]
local c, d = src:find(old2, 1, true)
assert(c, "TreehouseClient: finale break not found - nothing changed")
assert(not src:find(old2, d + 1, true), "TreehouseClient: finale break found twice - nothing changed")
src = src:sub(1, c - 1) .. new2 .. src:sub(d + 1)
local bk = tc:Clone(); bk.Name = "TreehouseClient_pre_rugs5"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(tc, function() return src end)
print(string.format("rugs5: TreehouseClient -> %d chars", #tc.Source))
return "rugs5 installed"
