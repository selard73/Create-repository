-- install_funnel1.lua (Studio EDIT mode; re-runnable). Job 95: the onboarding funnel for the Creator Dashboard (Shannon, Oct 11
-- 2026: "33 % still playing at 5 min, 20 % at 10 min"; she cannot watch new players herself). workspace.Funnel: FunnelEvent,
-- FunnelServer (7232 chars: six steps from the player attributes the game already keeps - Joined, First squirrel, Five squirrels,
-- Second area, All 44 in France, Reached Italy - for first-session players, with Device and Cohort breakdowns; MapOpened as a
-- custom event), FunnelClient (1913 chars: the device kind and the first map open). Events leave only a published place; in
-- Studio the server prints what it would send ("Funnel: step ..."). Undo: delete workspace.Funnel (Item_funnel = 1 stays on the
-- saves of players it marked as new; harmless). No DataStore, no publish. Output lines start with "QQ FUNNEL".
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
if not RS:FindFirstChild("AwardItems") then print("QQ FUNNEL ABORT: ReplicatedStorage.AwardItems not found (the cohort mark needs the game's own ledger)") return end
local SERVER = [===[
-- FunnelServer (workspace.Funnel): the onboarding funnel for the Creator Dashboard (Shannon, Oct 11 2026: "33 % still playing
-- at 5 min, 20 % at 10 min"; she cannot watch new players herself). Six steps, each counted once per player by Roblox itself,
-- taken from what the game already keeps on every player (attributes set by SquirrelSetup, SpawnReturn and TravelServer):
--   1 Joined (the save loaded)             2 First squirrel (SquirrelsFound 1)        3 Five squirrels (SquirrelsFound 5)
--   4 Second area (the Area attribute changes from the first area seen this visit)   5 All 44 in France   6 Reached Italy (Item_porto)
-- Roblox's rules (docs, Oct 2026): events only from the server and only in a published place (nothing leaves Studio); a later
-- step completes the earlier ones by itself; only a player's first time at a step counts; a player with no events for 180 days
-- counts as new again. Two custom fields on every event, for the dashboard's breakdowns: Device (Phone / Tablet / Desktop /
-- Console / VR, reported once by FunnelClient) and Cohort. The funnel is for FIRST-SESSION players: a player who has found no
-- squirrel and not reached Italy when this script first sees them is New, and the save remembers it (Item_funnel = 1 through
-- the game's own AwardItems ledger, as the thank-you gifts do), so their later visits keep counting; everyone else is
-- Returning and gets no funnel steps. "Map opened" is a separate custom event (MapOpened, value = squirrels found at that
-- moment, once per visit, both cohorts), so the funnel stays a line of progress. Every Roblox call is wrapped in pcall.
-- Nothing here writes a DataStore. Attributes on the folder: Enabled (true), ForceNew (Studio only: everyone counts as New,
-- for play tests), LogPrints (true: one Output line per event, "Funnel: ...").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")
local F = script.Parent
local ev = F:WaitForChild("FunnelEvent")
local awardItems = RS:WaitForChild("AwardItems", 60)
local STUDIO = RunService:IsStudio()
local STEPS = {
	{no = 1, name = "Joined"},
	{no = 2, name = "First squirrel"},
	{no = 3, name = "Five squirrels"},
	{no = 4, name = "Second area"},
	{no = 5, name = "All 44 in France"},
	{no = 6, name = "Reached Italy"},
}
local FRENCH = {"forest", "village", "domaine"}
local DEVICES = {Phone = true, Tablet = true, Desktop = true, Console = true, VR = true}
local K1, K2 = Enum.AnalyticsCustomFieldKeys.CustomField01.Name, Enum.AnalyticsCustomFieldKeys.CustomField02.Name
local state = {}                                                       -- player -> {device, cohort, firstArea, logged = {}, map, ready}
local function on() return F:GetAttribute("Enabled") ~= false end
local function num(p, name) return tonumber(p:GetAttribute(name)) or 0 end
local function fields(s) return {[K1] = "Device - " .. (s.device or "Unknown"), [K2] = "Cohort - " .. (s.cohort or "Unknown")} end
local function say(fmt, ...) if F:GetAttribute("LogPrints") ~= false then print("Funnel: " .. string.format(fmt, ...)) end end

local function logStep(p, s, step)
	if s.logged[step.no] then return end
	s.logged[step.no] = true
	local ok, err = pcall(function() AnalyticsService:LogOnboardingFunnelStepEvent(p, step.no, step.name, fields(s)) end)
	say("step %d %s for %s (%s, %s)%s", step.no, step.name, p.Name, s.device or "Unknown", s.cohort or "Unknown", ok and "" or (" - not sent: " .. tostring(err)))
end
local function check(p)
	local s = state[p]
	if not (s and s.ready and s.cohort == "New" and on()) then return end
	local found = num(p, "SquirrelsFound")
	local french = 0
	for _, m in ipairs(FRENCH) do french += num(p, "Found_" .. m) end
	local area = p:GetAttribute("Area")
	if s.firstArea == nil and type(area) == "string" and area ~= "" then s.firstArea = area end
	-- only the highest step reached is sent (Roblox completes the earlier ones itself; fewer calls)
	local top = 1
	if found >= 1 then top = 2 end
	if found >= 5 then top = 3 end
	if s.firstArea and type(area) == "string" and area ~= "" and area ~= s.firstArea then top = math.max(top, 4) end
	if french >= 44 then top = 5 end
	if num(p, "Item_porto") >= 1 then top = 6 end
	if top > (s.top or 0) then
		s.top = top
		logStep(p, s, STEPS[top])
	end
end
local function cohortOf(p)
	if STUDIO and F:GetAttribute("ForceNew") == true then return "New" end
	if num(p, "Item_funnel") >= 1 then return "New" end                 -- seen as new on an earlier visit: still counting
	if num(p, "SquirrelsFound") == 0 and num(p, "Item_porto") == 0 then
		if awardItems then pcall(function() awardItems:Fire(p, "funnel", 1) end) end   -- the save remembers (never a DataStore write from here)
		return "New"
	end
	return "Returning"
end
local function onEvent(p, kind, value)
	local s = state[p]
	if not s then return end
	if kind == "device" and type(value) == "string" and DEVICES[value] and not s.device then
		s.device = value
	elseif kind == "map" and not s.map and not s.ready then
		s.mapPending = true                                             -- opened in the first seconds: logged once the player is ready
	elseif kind == "map" and not s.map and s.ready and on() then
		s.map = true
		local found = num(p, "SquirrelsFound")
		local ok, err = pcall(function() AnalyticsService:LogCustomEvent(p, "MapOpened", found, fields(s)) end)
		say("MapOpened for %s with %d squirrels (%s, %s)%s", p.Name, found, s.device or "Unknown", s.cohort or "Unknown", ok and "" or (" - not sent: " .. tostring(err)))
	end
end
local function watch(p)
	local s = {logged = {}, map = false, ready = false}
	state[p] = s
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent and not p:GetAttribute("SaveLoaded") and os.clock() - t0 < 120 do task.wait(0.5) end
		if not (p.Parent and p:GetAttribute("SaveLoaded")) then return end
		s.cohort = cohortOf(p)                                          -- decided the moment the save is in (the counts land in the same breath)
		local area = p:GetAttribute("Area")
		if type(area) == "string" and area ~= "" then s.firstArea = area end
		local t1 = os.clock()
		while p.Parent and not s.device and os.clock() - t1 < 30 do task.wait(0.25) end   -- the client's device report (slow phones take a while)
		if not p.Parent then return end
		s.ready = true
		if s.cohort == "New" and on() then logStep(p, s, STEPS[1]) end
		check(p)
		if s.mapPending then s.mapPending = nil; onEvent(p, "map") end
		for _, name in ipairs({"SquirrelsFound", "Area", "Item_porto", "Found_forest", "Found_village", "Found_domaine"}) do
			p:GetAttributeChangedSignal(name):Connect(function() task.defer(check, p) end)
		end
	end)
end
ev.OnServerEvent:Connect(onEvent)
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p)
	local s = state[p]
	if s and s.cohort == "New" and not s.ready and on() then s.ready = true; logStep(p, s, STEPS[1]) end   -- left before the device report: a quick leaver, counted
	state[p] = nil
end)
print("Funnel: ready (6 steps; events leave only a published place)")
]===]
local CLIENT = [===[
-- FunnelClient (workspace.Funnel, RunContext Client): two things the server cannot see, sent once each per visit through
-- FunnelEvent: which kind of device this is (Phone / Tablet / Desktop / Console / VR - the Device breakdown of the onboarding
-- funnel) and the first time the map opens (PlayerGui attribute OpenPanel = "map", the HUD's own convention). Nothing drawn.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VRService = game:GetService("VRService")
local player = Players.LocalPlayer
local F = script.Parent
local ev = F:WaitForChild("FunnelEvent")
local pg = player:WaitForChild("PlayerGui")
local function touch()
	local ok, pi = pcall(function() return UIS.PreferredInput end)
	if ok and pi ~= nil then return pi == Enum.PreferredInput.Touch end
	return UIS.TouchEnabled and not UIS.MouseEnabled
end
local function device()
	if VRService.VREnabled then return "VR" end
	if GuiService:IsTenFootInterface() then return "Console" end
	if touch() then
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize or Vector2.new(0, 0)
		return (math.min(v.X, v.Y) >= 600) and "Tablet" or "Phone"     -- (a phone sideways is about 667 x 375; tablets run 768 and up)
	end
	return "Desktop"
end
task.spawn(function()
	local t0 = os.clock()                                               -- the viewport is tiny before the first frame: wait for a real size (5 s at most)
	while os.clock() - t0 < 5 do
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize
		if v and math.min(v.X, v.Y) > 1 then break end
		task.wait(0.1)
	end
	ev:FireServer("device", device())
end)
local sent = false
local function look()
	if not sent and pg:GetAttribute("OpenPanel") == "map" then sent = true; ev:FireServer("map") end
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(look)
look()
]===]
do   -- the compile check, where loadstring can run: the sources are compiled with the luau CLI before every push
	for _, pair in ipairs({{"server", SERVER}, {"client", CLIENT}}) do
		local ok, f, err = pcall(function() return loadstring(pair[2]) end)
		if ok and not f then print("QQ FUNNEL ABORT: the " .. pair[1] .. " does not compile: " .. tostring(err)) return end
	end
end
local old = workspace:FindFirstChild("Funnel")
local F = Instance.new("Folder"); F.Name = "Funnel"
F:SetAttribute("Enabled", true); F:SetAttribute("ForceNew", false); F:SetAttribute("LogPrints", true)
if old then
	for k, v in pairs(old:GetAttributes()) do F:SetAttribute(k, v) end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Funnel_pre_" .. n) do n += 1 end
	old.Name = "Funnel_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local ev = Instance.new("RemoteEvent"); ev.Name = "FunnelEvent"; ev.Parent = F
local s = Instance.new("Script"); s.Name = "FunnelServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "FunnelClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ FUNNEL DONE: workspace.Funnel (FunnelServer %d, FunnelClient %d chars; Enabled %s, ForceNew %s, LogPrints %s)%s", #s.Source, #c.Source, tostring(F:GetAttribute("Enabled")), tostring(F:GetAttribute("ForceNew")), tostring(F:GetAttribute("LogPrints")), old and ("; the old folder is HudBackup." .. old.Name) or ""))
