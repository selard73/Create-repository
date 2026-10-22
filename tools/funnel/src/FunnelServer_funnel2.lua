-- FunnelServer (workspace.Funnel): the onboarding funnel for the Creator Dashboard (Shannon, Oct 11 2026: "33 % still playing
-- at 5 min, 20 % at 10 min"; she cannot watch new players herself). Six steps, each counted once per player by Roblox itself,
-- taken from what the game already keeps on every player (attributes set by SquirrelSetup, SpawnReturn and TravelServer):
--   1 Joined (the save loaded)             2 First squirrel (SquirrelsFound 1)        3 Five squirrels (SquirrelsFound 5)
--   4 Second area (the Area attribute changes from the first area seen this visit)   5 All 44 in France   6 Reached Italy (Item_porto)
-- (funnel2, Oct 22 2026) now 11 steps, the French part finer - Shannon: "I need to find out specifically where they are
-- dropping off sharply between reaching the 2nd map and finding all 44 squirrels":
--   1 Joined  2 First squirrel  3 Five squirrels  4 Ten squirrels (Rue open)  5 Reached the Rue  6 Twenty squirrels
--   7 Reached the Chateau  8 Thirty squirrels  9 Forty squirrels  10 All 44 in France  11 Reached Italy
-- (France's areas open in turn - the Rue after 10 forest squirrels, the chateau after 10 on the Rue - so each step implies
-- the ones before it; the counts are French squirrels only.) Which squirrels, how long, and lag: SquirrelStats.
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
local STEPS = {                                                       -- (funnel2: 11 steps; 4-6 were Second area / All 44 / Italy)
	{no = 1, name = "Joined"},
	{no = 2, name = "First squirrel"},
	{no = 3, name = "Five squirrels"},
	{no = 4, name = "Ten squirrels (Rue open)"},
	{no = 5, name = "Reached the Rue"},
	{no = 6, name = "Twenty squirrels"},
	{no = 7, name = "Reached the Chateau"},
	{no = 8, name = "Thirty squirrels"},
	{no = 9, name = "Forty squirrels"},
	{no = 10, name = "All 44 in France"},
	{no = 11, name = "Reached Italy"},
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
	if area == "village" or area == "domaine" then s.rue = true end    -- (funnel2) once in the Rue this visit, or past it
	if area == "domaine" then s.chateau = true end
	local top = 1
	if found >= 1 then top = 2 end
	if found >= 5 then top = 3 end
	if french >= 10 then top = 4 end
	if s.rue then top = math.max(top, 5) end
	if french >= 20 then top = math.max(top, 6) end
	if s.chateau then top = math.max(top, 7) end
	if french >= 30 then top = 8 end
	if french >= 40 then top = 9 end
	if french >= 44 then top = 10 end
	if num(p, "Item_porto") >= 1 then top = 11 end
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
		p:SetAttribute("FunnelDevice", value)
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
		p:SetAttribute("FunnelCohort", s.cohort)                        -- (for other scripts: the interaction counter, job 98)
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
print("Funnel: ready (11 steps; events leave only a published place)")
