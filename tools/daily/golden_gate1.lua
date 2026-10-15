-- daily/golden_gate1 (job 101): EDIT mode. The golden squirrel announcements show only on the French map (Shannon, Oct 15 2026).
-- Four exact-string patches of workspace.Daily.DailyClient + one appended watcher: the pill under the purse and the card's golden
-- line need the player's Area to be forest / village / domaine; the pill follows every Area change. The daily acorns card still
-- shows everywhere. Every anchor counted before anything changes; compiled where loadstring runs; original ->
-- ServerStorage.HudBackup.DailyClient_pre_golden1. Also reports whether workspace.DailyQuestion.QuestionClient carries its own
-- French gate (FRENCH_QUESTION_REMINDERS). Output lines "QQ GOLD".
if game:GetService("RunService"):IsRunning() then print("QQ GOLD ABORT - Play mode") return end
local Q = workspace:FindFirstChild("DailyQuestion"); local qc = Q and Q:FindFirstChild("QuestionClient")
print("QQ GOLD QuestionClient " .. (qc and (#qc.Source .. " chars, French gate " .. (qc.Source:find("FRENCH_QUESTION_REMINDERS", 1, true) and "present" or "ABSENT")) or "not found"))
local D = workspace:FindFirstChild("Daily")
local s = D and D:FindFirstChild("DailyClient")
if not (s and s:IsA("LuaSourceContainer")) then print("QQ GOLD ABORT - missing workspace.Daily.DailyClient") return end
local o = s.Source
print("QQ GOLD DailyClient is " .. #o .. " chars")
local MARK = [===[
local function inFrance()]===]
if o:find(MARK, 1, true) then print("QQ GOLD DONE (already patched): DailyClient " .. #o) return end
local P = {{[===[
local pillPhase = phone and "gone" or "on"
]===], [===[
local pillPhase = phone and "gone" or "on"
-- (Oct 15 2026, Shannon: the golden squirrel is a French affair - "those things should only show if you are on the french map")
local function inFrance() local a = player:GetAttribute("Area"); return a == "forest" or a == "village" or a == "domaine" end
]===]}, {[===[
	goldLine.Text = (state.goldName ~= "" and state.goldName ~= nil) and string.format("Golden Squirrel today: %s is hiding in %s", state.goldName, state.goldArea) or ""
]===], [===[
	goldLine.Text = (inFrance() and state.goldName ~= "" and state.goldName ~= nil) and string.format("Golden Squirrel today: %s is hiding in %s", state.goldName, state.goldArea) or ""
]===]}, {[===[
	pill.Visible = pillPhase == "on"
]===], [===[
	pill.Visible = pillPhase == "on" and inFrance()
]===]}, {[===[
ev.OnClientEvent:Connect(function(what, a, b)
	if what == "state" and type(a) == "table" then
		setPill(a)
]===], [===[
local lastState
ev.OnClientEvent:Connect(function(what, a, b)
	if what == "state" and type(a) == "table" then
		lastState = a
		setPill(a)
]===]}}
for i, p in ipairs(P) do
	local a, b = o:find(p[1], 1, true)
	if not a then print("QQ GOLD ABORT - anchor " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then print("QQ GOLD ABORT - anchor " .. i .. " matches more than once; nothing changed") return end
end
local n = o
for _, p in ipairs(P) do local a, b = n:find(p[1], 1, true); n = n:sub(1, a - 1) .. p[2] .. n:sub(b + 1) end
n = n .. [===[

-- the pill follows the player from map to map (shown in France, hidden in Porto Nocciola)
player:GetAttributeChangedSignal("Area"):Connect(function() if lastState then setPill(lastState) end end)
]===]
do
	local ok, f, err = pcall(function() return loadstring(n) end)
	if ok and not f then print("QQ GOLD ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
if not backup:FindFirstChild("DailyClient_pre_golden1") then local c = s:Clone(); c.Name = "DailyClient_pre_golden1"; c.Enabled = false; c.Parent = backup end
s.Source = n
print(string.format("QQ GOLD DONE: DailyClient %d -> %d chars; backup ServerStorage.HudBackup.DailyClient_pre_golden1", #o, #n))
