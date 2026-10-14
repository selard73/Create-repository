-- install_interact1.lua (Studio EDIT mode; re-runnable). Job 98: what players interact with, counted for the Creator Dashboard
-- (Shannon, Oct 14 2026: "a tool that will count and give info on how far each player gets and what they interact with"; "how far"
-- is the funnel, job 95). workspace.Interact: InteractServer (8554 chars) listens to what the game already fires - every prompt
-- triggered, click, seat, tool equipped or used, area entered, item gained - and sends AnalyticsService custom events
-- Interact_<kind> with Device / Cohort (from the funnel) / Name fields, once per player per thing per minute, at most Budget per
-- server per minute. Nothing else is patched. Events leave only a published place; in Studio the server prints what it would send.
-- Undo: delete workspace.Interact. No DataStore, no publish. Output lines start with "QQ INTERACT".
local SS = game:GetService("ServerStorage")
local SERVER = [===[
-- InteractServer (workspace.Interact): what players interact with, counted for the Creator Dashboard (Shannon, Oct 14 2026: "we
-- need a tool that will count and give info on how far each player gets and what they interact with"; "how far" is the funnel,
-- job 95). Nothing in the game is patched: this script listens to what the game already fires -
--   Prompt   every ProximityPrompt a player triggers (ProximityPromptService.PromptTriggered): the prompt's ObjectText or its parent
--   Click    every ClickDetector a player clicks (the hall's Older/Newer, the race gate, ...): the nearest Model's name
--   Seat     every Seat or VehicleSeat a player sits in (the boat, the balloon, the funicolare, the benches)
--   Tool     every tool equipped (the camera, the slingshot, the binoculars, ...) and ToolUse when it is activated
--   Area     every area the player enters (the Area attribute: forest, village, domaine, porto)
--   Item     every item or keepsake gained after the save loaded (Item_<id> rising: a shop buy, the backpack, the chute ...)
-- Each goes to AnalyticsService:LogCustomEvent(player, "Interact_<kind>", 1, {Device, Cohort, Name}) once per player per thing
-- per minute (Repeat 60 s), at most Budget events per server per minute (the rest counted and reported, never sent). Device and
-- Cohort come from the funnel (player attributes FunnelDevice / FunnelCohort, set by FunnelServer). The dashboard's Custom Events
-- page then shows, per kind, how many players use each thing, split by device or cohort. Events leave only a published place;
-- in Studio the server prints what it would send when LogPrints is true. No DataStore. Attributes on the folder: Enabled, Repeat
-- (60), Budget (90), LogPrints (true in Studio).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local STUDIO = RunService:IsStudio()
local K1, K2, K3 = Enum.AnalyticsCustomFieldKeys.CustomField01.Name, Enum.AnalyticsCustomFieldKeys.CustomField02.Name, Enum.AnalyticsCustomFieldKeys.CustomField03.Name
local function on() return F:GetAttribute("Enabled") ~= false end
local function num(name, default) local v = tonumber(F:GetAttribute(name)); return v or default end
local function prints() local v = F:GetAttribute("LogPrints"); if v == nil then return STUDIO end; return v == true end
local function clean(s, max)
	s = tostring(s or ""):gsub("[%c|]", " "):gsub("^%s+", ""):gsub("%s+$", ""):gsub("_%d+$", "")   -- (Boat_<uid> -> Boat: one name per thing, never per rider)
	if s == "" then s = "unnamed" end
	max = max or 40
	if #s > max then
		s = s:sub(1, max)
		while #s > 0 and not utf8.len(s) do s = s:sub(1, -2) end          -- (never a split character)
	end
	return s
end
local function modelName(o)                                            -- the nearest Model above o (never a player's character), else o's own name
	local m = o
	while m and m ~= workspace do
		if m:IsA("Model") then
			if Players:GetPlayerFromCharacter(m) then return "a player" end
			return m.Name
		end
		m = m.Parent
	end
	return o.Name
end

-- ---- the send, with its throttles ----
local last = {}                                                        -- [player] = {[kind:name] = clock}
local sentThisBucket, dropped, bucketStart = 0, 0, os.clock()           -- ten-second buckets: Budget / 6 each
local function fieldsFor(p, name)
	return {[K1] = "Device - " .. tostring(p:GetAttribute("FunnelDevice") or "Unknown"), [K2] = "Cohort - " .. tostring(p:GetAttribute("FunnelCohort") or "Unknown"), [K3] = name}
end
local function log(p, kind, rawName)
	if not (on() and p and p.Parent == Players) then return end
	local name = clean(rawName, 40)
	local key = kind .. ":" .. name
	local t = os.clock()
	local mine = last[p]; if not mine then mine = {}; last[p] = mine end
	if mine[key] and t - mine[key] < num("Repeat", 60) then return end
	if t - bucketStart >= 10 then
		if dropped > 0 then                                             -- the truncation itself is reported, once per bucket
			local d = dropped
			pcall(function() AnalyticsService:LogCustomEvent(p, "Interact_Dropped", d) end)
			if prints() then print(string.format("Interact: %d events over the budget were not sent in the last ten seconds", d)) end
		end
		sentThisBucket, dropped, bucketStart = 0, 0, t
	end
	if sentThisBucket >= math.max(1, math.floor(num("Budget", 90) / 6)) then dropped += 1; return end
	mine[key] = t
	sentThisBucket += 1
	local ok, err = pcall(function() AnalyticsService:LogCustomEvent(p, "Interact_" .. kind, 1, fieldsFor(p, name)) end)
	if prints() then print(string.format("Interact: %s \"%s\" by %s%s", kind, name, p.Name, (not ok) and (" - not sent: " .. tostring(err)) or (STUDIO and " (Studio, not sent)" or ""))) end
end

-- ---- prompts ----
PPS.PromptTriggered:Connect(function(prompt, p)
	local name = (prompt.ObjectText ~= "" and prompt.ObjectText) or (prompt.Parent and modelName(prompt.Parent)) or prompt.Name
	log(p, "Prompt", name)
end)

-- ---- clicks ----
local hooked = setmetatable({}, {__mode = "k"})
local function hookClick(cd)
	if not cd:IsA("ClickDetector") or hooked[cd] then return end
	hooked[cd] = true
	cd.MouseClick:Connect(function(p) log(p, "Click", cd.Parent and modelName(cd.Parent) or cd.Name) end)
end
-- ---- seats ----
local function hookSeat(seat)
	if not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) or hooked[seat] then return end
	hooked[seat] = true
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local hum = seat.Occupant
		local char = hum and hum.Parent
		local p = char and Players:GetPlayerFromCharacter(char)
		if p then log(p, "Seat", modelName(seat)) end
	end)
end
for _, d in ipairs(workspace:GetDescendants()) do hookClick(d); hookSeat(d) end
workspace.DescendantAdded:Connect(function(d) hookClick(d); hookSeat(d) end)

-- ---- tools, areas, items ----
local function hookTool(p, tool)
	if not tool:IsA("Tool") or hooked[tool] then return end
	hooked[tool] = true
	tool.Equipped:Connect(function() log(p, "Tool", tool.Name) end)
	tool.Activated:Connect(function() log(p, "ToolUse", tool.Name) end)
end
local function watch(p)
	local function char(c)
		for _, t in ipairs(c:GetChildren()) do hookTool(p, t) end
		c.ChildAdded:Connect(function(t) hookTool(p, t) end)
	end
	if p.Character then char(p.Character) end
	p.CharacterAdded:Connect(char)
	local bp = p:FindFirstChildOfClass("Backpack")
	if bp then for _, t in ipairs(bp:GetChildren()) do hookTool(p, t) end; bp.ChildAdded:Connect(function(t) hookTool(p, t) end) end
	p.ChildAdded:Connect(function(c) if c:IsA("Backpack") then for _, t in ipairs(c:GetChildren()) do hookTool(p, t) end; c.ChildAdded:Connect(function(t) hookTool(p, t) end) end end)
	-- areas: every change after the first area seen
	local lastArea = p:GetAttribute("Area")
	p:GetAttributeChangedSignal("Area"):Connect(function()
		local a = p:GetAttribute("Area")
		if not (type(a) == "string" and a ~= "") or a == lastArea then return end
		local first = (lastArea == nil)                                 -- the spawn area is where they arrived, not a move
		lastArea = a
		if not first then log(p, "Area", a) end
	end)
	-- items: a rise in any Item_<id> once the save is in (the load itself is not a purchase)
	local baseline = {}
	local function snapshot() for k, v in pairs(p:GetAttributes()) do if type(k) == "string" and k:sub(1, 5) == "Item_" then baseline[k] = tonumber(v) or 0 end end end
	local SKIP = {funnel = true, porto = true}                            -- the game's own marks (the funnel's, the Italy arrival) and gifts are not purchases
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent and not p:GetAttribute("SaveLoaded") and os.clock() - t0 < 120 do task.wait(0.5) end
		if not (p.Parent and p:GetAttribute("SaveLoaded")) then return end
		task.wait(2)
		snapshot()
		p.AttributeChanged:Connect(function(k)
			if type(k) ~= "string" or k:sub(1, 5) ~= "Item_" then return end
			local id = k:sub(6)
			if SKIP[id] or id:sub(1, 7) == "thanks_" then return end
			local v = tonumber(p:GetAttribute(k)) or 0
			if v > (baseline[k] or 0) then baseline[k] = v; log(p, "Item", id) end
		end)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) last[p] = nil end)
print("Interact: ready (prompts, clicks, seats, tools, areas, items; events leave only a published place)")
]===]
do   -- the compile check, where loadstring can run: the sources are compiled with the luau CLI before every push
	local ok, f, err = pcall(function() return loadstring(SERVER) end)
	if ok and not f then print("QQ INTERACT ABORT: the server does not compile: " .. tostring(err)) return end
end
local old = workspace:FindFirstChild("Interact")
local F = Instance.new("Folder"); F.Name = "Interact"
F:SetAttribute("Enabled", true); F:SetAttribute("Repeat", 60); F:SetAttribute("Budget", 90)
if old then
	for k, v in pairs(old:GetAttributes()) do F:SetAttribute(k, v) end
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Interact_pre_" .. n) do n += 1 end
	old.Name = "Interact_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local s = Instance.new("Script"); s.Name = "InteractServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
F.Parent = workspace
print(string.format("QQ INTERACT DONE: workspace.Interact (InteractServer %d chars; Enabled %s, Repeat %s, Budget %s)%s", #s.Source, tostring(F:GetAttribute("Enabled")), tostring(F:GetAttribute("Repeat")), tostring(F:GetAttribute("Budget")), old and ("; the old folder is HudBackup." .. old.Name) or ""))
