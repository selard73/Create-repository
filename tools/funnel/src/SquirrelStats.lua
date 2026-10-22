-- SquirrelStats (workspace.Funnel, Script; funnel2, Oct 22 2026): why players stop after reaching the Rue. Shannon: "we need
-- to specifically figure out why there is a sharp drop after they get to the 2nd section" + "is there a way to see if there
-- is a particular squirrel they are having difficulty finding and maybe that is why they drop off?" Four custom events for
-- the Creator Dashboard (Custom Events page), each with Device in custom field 1:
--   SquirrelFound  every find after the save loaded; value = how many squirrels of that map the player has now (its place
--                  in their order); field 2 Cohort, field 3 "Rue: Marcel the Mime Squirrel". The squirrels of an area found
--                  far less often than their neighbours are the hard ones.
--   StillMissing   when a player leaves France unfinished with 5 or fewer squirrels to go in the area they are in: one event
--                  per squirrel still missing there; field 2 Cohort, field 3 as above. The names that keep turning up are
--                  the squirrels people give up on.
--   QuitInFrance   NEW players only (the funnel's cohort), once, when they leave France unfinished: value = seconds in the
--                  area they left from (this visit); field 2 how long ("under 1 min" / "1-3 min" / "3-10 min" / "over 10
--                  min"), field 3 where and how far ("Rue: 3 of 14"). Quick quits point at a crash or a jarring moment,
--                  long stays with few finds at squirrels too hard to find.
--   AreaFPS / AreaMemory   from StatsClient, once per area per visit after 20 s there: the frame rate averaged over 10 s
--                  and the memory in MB; field 2 Cohort, field 3 the area. Lag or a crash on the busy Rue shows up here.
-- Device and Cohort come from the funnel (player attributes FunnelDevice / FunnelCohort, set by FunnelServer). Nothing in the
-- game is patched: it reads the player attributes SquirrelSetup already keeps (FoundIds, Found_<map>) and SpawnReturn's Area.
-- Events leave only a published place; in Studio it prints what it would send ("Stats: ..."). No DataStore. Every Roblox
-- call is wrapped in pcall. Attributes on workspace.Funnel: Enabled, LogPrints (as FunnelServer).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")
local F = script.Parent
local STUDIO = RunService:IsStudio()
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local K1, K2, K3 = Enum.AnalyticsCustomFieldKeys.CustomField01.Name, Enum.AnalyticsCustomFieldKeys.CustomField02.Name, Enum.AnalyticsCustomFieldKeys.CustomField03.Name
local AREA = {forest = "Forest", village = "Rue", domaine = "Château", porto = "Italy"}
local FRANCE = {forest = true, village = true, domaine = true}
local MISSING_MAX = 5                                                   -- StillMissing only near the end of an area
local function on() return F:GetAttribute("Enabled") ~= false end
local function say(fmt, ...) if F:GetAttribute("LogPrints") ~= false then print("Stats: " .. string.format(fmt, ...)) end end
-- (the dashboard gets plain letters: Gérard -> Gerard, Château -> Chateau)
local FOLD = {["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e", ["à"] = "a", ["â"] = "a", ["ç"] = "c", ["ô"] = "o", ["î"] = "i", ["ï"] = "i", ["û"] = "u", ["ù"] = "u"}
local function plain(s)
	for k, v in pairs(FOLD) do s = s:gsub(k, v) end
	return #s > 48 and s:sub(1, 48) or s
end
local byId, ofMap = {}, {}
for _, e in ipairs(Registry.squirrels) do
	byId[e.id] = e
	ofMap[e.map] = ofMap[e.map] or {}
	table.insert(ofMap[e.map], e)
end
local function label(e) return plain((AREA[e.map] or e.map) .. ": " .. tostring(e.name or e.id)) end
local function device(p) return "Device - " .. tostring(p:GetAttribute("FunnelDevice") or "Unknown") end
local function cohort(p) return "Cohort - " .. tostring(p:GetAttribute("FunnelCohort") or "Unknown") end
local function send(p, name, value, f2, f3)
	if not on() then return end
	local ok, err = pcall(function() AnalyticsService:LogCustomEvent(p, name, value, {[K1] = device(p), [K2] = f2, [K3] = f3}) end)
	say("%s %s = %s (%s, %s) for %s%s", name, f3, tostring(value), device(p), f2, p.Name,
		(not ok) and (" - not sent: " .. tostring(err)) or (STUDIO and " (Studio, not sent)" or ""))
end
local function idSet(p)
	local t = {}
	for id in tostring(p:GetAttribute("FoundIds") or ""):gmatch("[^,]+") do t[id] = true end
	return t
end
local function countIn(set, map)
	local n = 0
	for _, e in ipairs(ofMap[map] or {}) do if set[e.id] then n += 1 end end
	return n
end

local state = {}                                                        -- [player] = {known = set, area, since, perf = {}}
local function watch(p)
	local s = {perf = {}}
	state[p] = s
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent and not p:GetAttribute("SaveLoaded") and os.clock() - t0 < 120 do task.wait(0.5) end
		if not (p.Parent and p:GetAttribute("SaveLoaded")) then return end
		task.wait(2)                                                    -- (the load itself is not a find)
		if not p.Parent then return end
		s.known = idSet(p)
		s.area, s.since = p:GetAttribute("Area"), os.clock()
		p:GetAttributeChangedSignal("FoundIds"):Connect(function()
			local now = idSet(p)
			local fresh = {}
			for id in pairs(now) do if not s.known[id] then table.insert(fresh, id) end end
			s.known = now                                               -- (a reset shrinks the list: it simply starts again)
			for _, id in ipairs(fresh) do
				local e = byId[id]
				if e then send(p, "SquirrelFound", countIn(now, e.map), cohort(p), label(e)) end
			end
		end)
		p:GetAttributeChangedSignal("Area"):Connect(function()
			local a = p:GetAttribute("Area")
			if a ~= s.area then s.area, s.since = a, os.clock() end
		end)
	end)
end
local function leaving(p)
	local s = state[p]
	state[p] = nil
	if not (s and s.known and on()) then return end
	local area = s.area
	if not FRANCE[area] then return end
	local french = 0
	for m in pairs(FRANCE) do french += countIn(s.known, m) end
	if french >= 44 then return end
	local list = ofMap[area] or {}
	local missing = {}
	for _, e in ipairs(list) do if not s.known[e.id] then table.insert(missing, e) end end
	if #missing >= 1 and #missing <= MISSING_MAX then
		for _, e in ipairs(missing) do send(p, "StillMissing", 1, cohort(p), label(e)) end
	end
	if p:GetAttribute("FunnelCohort") == "New" then
		local secs = math.floor(os.clock() - (s.since or os.clock()))
		local how = secs < 60 and "under 1 min" or secs < 180 and "1-3 min" or secs < 600 and "3-10 min" or "over 10 min"
		send(p, "QuitInFrance", secs, "Stayed " .. how, plain(AREA[area] .. ": " .. (#list - #missing) .. " of " .. #list))
	end
end
-- the client's frame rate and memory, once per area per visit (StatsClient)
local ev = F:FindFirstChild("StatsEvent") or Instance.new("RemoteEvent")
ev.Name = "StatsEvent"; ev.Parent = F
ev.OnServerEvent:Connect(function(p, kind, area, fps, mem)
	local s = state[p]
	if not (s and kind == "perf" and type(area) == "string" and AREA[area] and not s.perf[area]) then return end
	if type(fps) ~= "number" or fps ~= fps or fps < 1 or fps > 400 then return end
	s.perf[area] = true
	send(p, "AreaFPS", math.floor(fps + 0.5), cohort(p), plain(AREA[area]))
	if type(mem) == "number" and mem == mem and mem > 0 and mem < 100000 then send(p, "AreaMemory", math.floor(mem + 0.5), cohort(p), plain(AREA[area])) end
end)
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(leaving)
print("Stats: ready (SquirrelFound, StillMissing, QuitInFrance, AreaFPS/AreaMemory; events leave only a published place)")
