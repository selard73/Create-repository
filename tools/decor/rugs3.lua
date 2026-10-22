-- rugs3 (Oct 21 2026): Shannon, after rebuilding on her iPad: "I did not get any tutorial or note after the treehouse
-- was complete". Cause: the rugs1 tip latched a SESSION boolean (shown = true) when it mis-fired at her Japan spawn
-- (the race before the round-4 reset clawed her flags), so the real completion later in the SAME session was blocked.
-- Two fixes in TreehouseClient's tip block:
--   1. the only lasting latch is the ledger flag (Item_tree_decortip) - a session guard now only covers the 6 s wait,
--      and the state is re-checked after that wait (so a claw-back during it cancels the tip: no more Japan mis-fire);
--   2. the toast only shows when the server actually GRANTS the flag (rugs1 showed it whenever the call didn't error).
-- Run in Studio EDIT. Backs TreehouseClient up to ServerStorage.HudBackup first. Never touches a DataStore.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local tc = workspace.Treehouse.TreehouseClient
local old = [=[	local shown = false
	local function maybeTip()
		if shown then return end
		if (tonumber(player:GetAttribute("Item_tree_decortip")) or 0) >= 1 then return end
		if (tonumber(player:GetAttribute("Item_tree_done")) or 0) < 1 then return end
		shown = true
		task.wait(6)
		local ok = pcall(function() return act:InvokeServer("tip") end)
		if not ok then return end]=]
local new = [=[	local inFlight = false
	local function maybeTip()
		if inFlight then return end
		if (tonumber(player:GetAttribute("Item_tree_decortip")) or 0) >= 1 then return end
		if (tonumber(player:GetAttribute("Item_tree_done")) or 0) < 1 then return end
		inFlight = true
		task.wait(6)
		-- (rugs3) the moment may have passed while we waited: a listed player's reset claws the flags right after the
		-- join, and then the tip belongs to the NEXT completion, not this one. The ledger flag is the only lasting
		-- latch, so a claw-back re-arms the tip - her rebuild in the same session now gets it.
		if (tonumber(player:GetAttribute("Item_tree_decortip")) or 0) >= 1 or (tonumber(player:GetAttribute("Item_tree_done")) or 0) < 1 then inFlight = false return end
		local ok, granted = pcall(function() return act:InvokeServer("tip") end)
		inFlight = false
		if not ok or not granted then return end]=]
local src = tc.Source
local a, b = src:find(old, 1, true)
assert(a, "TreehouseClient: tip latch block not found - nothing changed")
assert(not src:find(old, b + 1, true), "TreehouseClient: tip latch block found twice - nothing changed")
local out = src:sub(1, a - 1) .. new .. src:sub(b + 1)
local bk = tc:Clone(); bk.Name = "TreehouseClient_pre_rugs3"; bk.Enabled = false; bk.Parent = backup
SES:UpdateSourceAsync(tc, function() return out end)
print(string.format("rugs3: TreehouseClient %d -> %d chars", #src, #tc.Source))
return "rugs3 installed"
