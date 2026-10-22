-- funnel2 (Oct 22 2026): where and why new players stop in France. Shannon: "I need to find out specifically where they are
-- dropping off sharply between reaching the 2nd map and finding all 44 squirrels. Are they stopping at the 2nd map? are they
-- getting the the 3rd map and dropping off there. Also, is there a way to see if there is a particular squirrel they are
-- having difficulty finding" + "we need to specifically figure out why there is a sharp drop after they get to the 2nd
-- section".
--   FunnelServer: the onboarding funnel in 11 steps instead of 6 - Joined / First squirrel / Five squirrels / Ten squirrels
--     (Rue open) / Reached the Rue / Twenty squirrels / Reached the Chateau / Thirty squirrels / Forty squirrels / All 44 in
--     France / Reached Italy. (Steps 4-6 change meaning: read the dashboard from the publish date on.)
--   SquirrelStats (new, Script) + StatsClient (new, Client): custom events SquirrelFound, StillMissing, QuitInFrance,
--     AreaFPS / AreaMemory (see SquirrelStats' header).
-- Run in Studio EDIT. Backs FunnelServer up to ServerStorage.HudBackup.FunnelServer_pre_funnel2 first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
local F = workspace:FindFirstChild("Funnel")
assert(F and F:FindFirstChild("FunnelServer"), "no workspace.Funnel.FunnelServer - nothing changed")
assert(not F:FindFirstChild("SquirrelStats") and not F:FindFirstChild("StatsClient"), "SquirrelStats / StatsClient already there - nothing changed")
local fs = F.FunnelServer
local function patched(script, edits)
	local src = script.Source
	assert(not src:find("(funnel2", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	return src
end
local fsSrc = patched(fs, {
	{[==[--   4 Second area (the Area attribute changes from the first area seen this visit)   5 All 44 in France   6 Reached Italy (Item_porto)]==],
	 [==[--   4 Second area (the Area attribute changes from the first area seen this visit)   5 All 44 in France   6 Reached Italy (Item_porto)
-- (funnel2, Oct 22 2026) now 11 steps, the French part finer - Shannon: "I need to find out specifically where they are
-- dropping off sharply between reaching the 2nd map and finding all 44 squirrels":
--   1 Joined  2 First squirrel  3 Five squirrels  4 Ten squirrels (Rue open)  5 Reached the Rue  6 Twenty squirrels
--   7 Reached the Chateau  8 Thirty squirrels  9 Forty squirrels  10 All 44 in France  11 Reached Italy
-- (France's areas open in turn - the Rue after 10 forest squirrels, the chateau after 10 on the Rue - so each step implies
-- the ones before it; the counts are French squirrels only.) Which squirrels, how long, and lag: SquirrelStats.]==], "the step list in the header"},
	{[==[local STEPS = {
	{no = 1, name = "Joined"},
	{no = 2, name = "First squirrel"},
	{no = 3, name = "Five squirrels"},
	{no = 4, name = "Second area"},
	{no = 5, name = "All 44 in France"},
	{no = 6, name = "Reached Italy"},
}]==],
	 [==[local STEPS = {                                                       -- (funnel2: 11 steps; 4-6 were Second area / All 44 / Italy)
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
}]==], "the STEPS table"},
	{[==[	local top = 1
	if found >= 1 then top = 2 end
	if found >= 5 then top = 3 end
	if s.firstArea and type(area) == "string" and area ~= "" and area ~= s.firstArea then top = math.max(top, 4) end
	if french >= 44 then top = 5 end
	if num(p, "Item_porto") >= 1 then top = 6 end]==],
	 [==[	if area == "village" or area == "domaine" then s.rue = true end    -- (funnel2) once in the Rue this visit, or past it
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
	if num(p, "Item_porto") >= 1 then top = 11 end]==], "the step choice in check"},
	{[==[print("Funnel: ready (6 steps; events leave only a published place)")]==],
	 [==[print("Funnel: ready (11 steps; events leave only a published place)")]==], "the ready line"},
})
local b = fs:Clone(); b.Name = "FunnelServer_pre_funnel2"; b.Enabled = false; b.Parent = backup
SES:UpdateSourceAsync(fs, function() return fsSrc end)
local ss = Instance.new("Script"); ss.Name = "SquirrelStats"; ss.Parent = F
SES:UpdateSourceAsync(ss, function() return [==[
@@STATS@@]==] end)
local sc = Instance.new("Script"); sc.Name = "StatsClient"; sc.RunContext = Enum.RunContext.Client; sc.Parent = F
SES:UpdateSourceAsync(sc, function() return [==[
@@CLIENT@@]==] end)
print(string.format("funnel2: FunnelServer %d chars, SquirrelStats %d chars, StatsClient %d chars", #fs.Source, #ss.Source, #sc.Source))
return "funnel2 installed"
