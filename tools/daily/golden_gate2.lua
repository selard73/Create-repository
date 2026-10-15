-- daily/golden_gate2 (job 101 round 2): EDIT mode. The Wise Squirrel draw announcement (banner + chat line) shows only on the
-- French map (Shannon, Oct 15 2026). ONE exact-string patch of workspace.DailyQuestion.QuestionClient: the "drawn" block runs only
-- when frenchQuestionReminderAllowed() (the gate the reminders already use). The personal prize banner stays everywhere. The anchor
-- is counted before anything changes; the result is compiled where loadstring runs; original ->
-- ServerStorage.HudBackup.QuestionClient_pre_golden2. Output lines "QQ GOLD".
if game:GetService("RunService"):IsRunning() then print("QQ GOLD ABORT - Play mode") return end
local Q = workspace:FindFirstChild("DailyQuestion")
local s = Q and Q:FindFirstChild("QuestionClient")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ GOLD ABORT - missing workspace.DailyQuestion.QuestionClient") return end
local o = s.Source
print("QQ GOLD QuestionClient is " .. #o .. " chars")
local MARK = [===[
FRENCH_DRAWN_ANNOUNCE_20261015_V1]===]
if o:find(MARK, 1, true) then print("QQ GOLD DONE (already patched): QuestionClient " .. #o) return end
if not o:find([===[
local function frenchQuestionReminderAllowed()]===], 1, true) then print("QQ GOLD ABORT - QuestionClient has no frenchQuestionReminderAllowed(); nothing changed") return end
local F1, R1 = [===[
		if info.name then
			announce("Today's Wise Squirrel: " .. tostring(info.name) .. "!", "The answers were: " .. tostring(a.forest or "") .. "  and  " .. tostring(a.poste or ""), 8)
			chat(string.format("%s is today's Wise Squirrel! (%d right answers were in the draw)", tostring(info.name), info.count or 0))
		else
			chat("Nobody got a Question of the Day right today. New ones are up!")
		end
]===], [===[
		if not frenchQuestionReminderAllowed() then
			-- FRENCH_DRAWN_ANNOUNCE_20261015_V1 (Shannon, Oct 15 2026: the draw is a French affair - "those things should only show if you are on the french map")
		elseif info.name then
			announce("Today's Wise Squirrel: " .. tostring(info.name) .. "!", "The answers were: " .. tostring(a.forest or "") .. "  and  " .. tostring(a.poste or ""), 8)
			chat(string.format("%s is today's Wise Squirrel! (%d right answers were in the draw)", tostring(info.name), info.count or 0))
		else
			chat("Nobody got a Question of the Day right today. New ones are up!")
		end
]===]
local a, b = o:find(F1, 1, true)
if not a then print("QQ GOLD ABORT - the drawn block was not found; nothing changed") return end
if o:find(F1, b + 1, true) then print("QQ GOLD ABORT - the drawn block matches more than once; nothing changed") return end
local n = o:sub(1, a - 1) .. R1 .. o:sub(b + 1)
do
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ GOLD ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
if not backup:FindFirstChild("QuestionClient_pre_golden2") then local c = s:Clone(); c.Name = "QuestionClient_pre_golden2"; c.Enabled = false; c.Parent = backup end
s.Source = n
print(string.format("QQ GOLD DONE: QuestionClient %d -> %d chars; backup ServerStorage.HudBackup.QuestionClient_pre_golden2", #o, #n))
-- ---- the daily card's golden line follows the gate as the card shows ----
local D = workspace:FindFirstChild("Daily")
local ds = D and D:FindFirstChild("DailyClient")
if not (ds and ds:IsA("LuaSourceContainer")) then print("QQ GOLD DailyClient not found; the card patch skipped") return end
local od = ds.Source
if od:find([===[
FRENCH_GOLDLINE_20261015_V1]===], 1, true) then print("QQ GOLD DailyClient already patched (" .. #od .. ")") return end
if not od:find("local function frenchMapHudAllowed()", 1, true) then print("QQ GOLD DailyClient has no frenchMapHudAllowed(); the card patch skipped") return end
local D1, DR = [===[
	goldLine.Text = (state.goldName ~= "" and state.goldName ~= nil) and string.format("Golden Squirrel today: %s is hiding in %s", state.goldName, state.goldArea) or ""
]===], [===[
	goldLine.Text = (state.goldName ~= "" and state.goldName ~= nil) and string.format("Golden Squirrel today: %s is hiding in %s", state.goldName, state.goldArea) or ""
	goldLine.Visible = frenchMapHudAllowed()   -- FRENCH_GOLDLINE_20261015_V1 (Shannon: the line showed on a card in Italy once; the gate now runs as the card shows, not only on an Area change)
]===]
local da, db = od:find(D1, 1, true)
if not da then print("QQ GOLD DailyClient anchor not found; the card patch skipped") return end
if od:find(D1, db + 1, true) then print("QQ GOLD DailyClient anchor matches more than once; the card patch skipped") return end
local nd = od:sub(1, da - 1) .. DR .. od:sub(db + 1)
do
	local ok, f, err = pcall(function() return loadstring(nd) end)
	if ok and not f then print("QQ GOLD DailyClient patched source does not compile: " .. tostring(err) .. "; the card patch skipped") return end
end
if not backup:FindFirstChild("DailyClient_pre_golden2") then local c = ds:Clone(); c.Name = "DailyClient_pre_golden2"; c.Enabled = false; c.Parent = backup end
ds.Source = nd
print(string.format("QQ GOLD DONE: DailyClient %d -> %d chars; backup ServerStorage.HudBackup.DailyClient_pre_golden2", #od, #nd))
