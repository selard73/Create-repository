-- statue_retry1.lua (Studio EDIT mode; re-runnable). Job 90 (Shannon, Oct 11): Darkknight holds the Guardian of the Harbour
-- record (the Italy plaque shows his name) but no statue stands: PortoKeeperServer asks for Champion.MakeStatue with a plain
-- FindFirstChild the moment a server starts, and when ChampionServer has not made it yet the statue step silently gives
-- nothing (plaque written, key left resting). Two changes to workspace.PortoKeeper.PortoKeeperServer, checked before writing:
--  a. the MakeStatue lookup waits for it (up to 30 s each) instead of FindFirstChild (skipped, with a note, if not found once);
--  b. appended: for the first minute of a server, every 20 s, if a Guardian is recorded and no Figure stands, build it again.
-- Backup ServerStorage.HudBackup.PortoKeeperServer_pre_statue1. Undo: put the backup's Source back. No DataStore, no publish.
local SS = game:GetService("ServerStorage")
local K = workspace:FindFirstChild("PortoKeeper"); local s = K and K:FindFirstChild("PortoKeeperServer")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ STATUE ABORT: workspace.PortoKeeper.PortoKeeperServer not found; nothing changed") return end
local MARK = "Guardian's plaque showed his name but no statue stood"
if s.Source:find(MARK, 1, true) then print("QQ STATUE DONE (already patched): PortoKeeperServer " .. #s.Source) return end
local function count(src, sub) if sub == "" then return 0 end; local n, i = 0, 1; while n < 50 do local a, b = src:find(sub, i, true); if not a then break end; n += 1; i = b + 1 end; return n end
local src, was = s.Source, #s.Source
-- the names the appended part relies on, all top-level in the live script (runner 6's read, Oct 11)
for _, need in ipairs({"local function buildStatue(", "local first", "local F = script.Parent"}) do
	if count(src, need) ~= 1 then print(string.format("QQ STATUE ABORT: '%s' found %d times (need 1); nothing changed", need, count(src, need))) return end
end
if count(src, 'name = "Figure"') < 1 then print("QQ STATUE ABORT: the statue is not built under the name Figure; nothing changed") return end
local A_OLD = 'workspace:FindFirstChild("Champion") and workspace.Champion:FindFirstChild("MakeStatue")'
local A_NEW = '(workspace:WaitForChild("Champion", 30) and workspace.Champion:WaitForChild("MakeStatue", 30))'
local aNote
if count(src, A_OLD) == 1 then
	local a, b = src:find(A_OLD, 1, true); src = src:sub(1, a - 1) .. A_NEW .. src:sub(b + 1); aNote = "the MakeStatue lookup now waits"
else
	aNote = string.format("the MakeStatue lookup found %d times, left as it was (the retry still covers it)", count(src, A_OLD))
end
src = src .. [==[

-- (Oct 11, Shannon: the Guardian's plaque showed his name but no statue stood) the statue maker may not have been ready when
-- the server started; for the first minute, every 20 s, if a Guardian is recorded and no Figure stands, build it again
task.spawn(function()
	for _ = 1, 3 do
		task.wait(20)
		if type(first) == "table" and first.uid and not F:FindFirstChild("Figure") then
			print("PortoKeeper: no statue yet for " .. tostring(first.name) .. "; building it again")
			local ok, err = pcall(buildStatue, first)
			if not ok then warn("PortoKeeper: the statue retry failed: " .. tostring(err)) end
		end
	end
end)
]==]
local f, err = loadstring(src); if not f then print("QQ STATUE ABORT: the patched PortoKeeperServer does not compile: " .. tostring(err) .. "; nothing changed") return end
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
if not hb:FindFirstChild("PortoKeeperServer_pre_statue1") then local bk = s:Clone(); bk.Name = "PortoKeeperServer_pre_statue1"; bk.Enabled = false; bk.Parent = hb end
s.Source = src
print(string.format("QQ STATUE DONE: PortoKeeperServer %d -> %d; %s; a statue retry for the first minute appended (backup HudBackup.PortoKeeperServer_pre_statue1)", was, #s.Source, aNote))
