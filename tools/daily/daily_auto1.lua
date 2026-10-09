-- daily/daily_auto1 (job 35): EDIT mode. The Daily Acorns card collects itself after AutoCollect seconds (15) if nobody
-- pressed Collect. Four exact finds in workspace.Daily.DailyClient; compiled before writing; original ->
-- ServerStorage.HudBackup.DailyClient_pre_auto1. Output lines start with "QQ AUTO".
if game:GetService("RunService"):IsRunning() then warn("QQ AUTO ABORT - Play mode") return end
local D = workspace:FindFirstChild("Daily")
local s = D and D:FindFirstChild("DailyClient")
if not (s and s:IsA("LuaSourceContainer")) then warn("QQ AUTO ABORT - missing workspace.Daily.DailyClient") return end
print("QQ AUTO DailyClient is " .. #s.Source .. " chars")
local o = s.Source
for i, p in ipairs({{[===[
local function showCard(state)
]===], [===[
local collect, autoToken   -- Collect's action (set below); the auto-collect timer (Shannon, Oct 9 2026, VR) shares it
local function showCard(state)
]===]}, {[===[
	card.Visible = true; shown = true
]===], [===[
	card.Visible = true; shown = true
	local mine = {}; autoToken = mine
	task.delay(tonumber(script.Parent:GetAttribute("AutoCollect")) or 15, function()
		if autoToken == mine and shown and btn.Text == "Collect" and collect then collect() end   -- nobody pressed it: collect and go
	end)
]===]}, {[===[
btn.Activated:Connect(function()
	if busy then return end
	busy = true
	local ok, res = action:InvokeServer("claim")
]===], [===[
collect = function()
	if busy then return end
	busy = true
	local ok, res = action:InvokeServer("claim")
]===]}, {[===[
	busy = false
end)
]===], [===[
	busy = false
end
btn.Activated:Connect(function() collect() end)
]===]}}) do
	local a, b = o:find(p[1], 1, true)
	if not a then warn("QQ AUTO ABORT - find " .. i .. " not found; nothing changed") return end
	if o:find(p[1], b + 1, true) then warn("QQ AUTO ABORT - find " .. i .. " matches more than once; nothing changed") return end
	o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
end
local f, err = loadstring(o)
if not f then warn("QQ AUTO ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local backup = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); backup.Name = "HudBackup"; backup.Parent = SS
local c = s:Clone(); c.Name = "DailyClient_pre_auto1"; c.Enabled = false; c.Parent = backup
s.Source = o
if D:GetAttribute("AutoCollect") == nil then D:SetAttribute("AutoCollect", 15) end
print(string.format("QQ AUTO DONE: DailyClient %d chars; AutoCollect %s s; backup ServerStorage.HudBackup.DailyClient_pre_auto1", #s.Source, tostring(D:GetAttribute("AutoCollect"))))
