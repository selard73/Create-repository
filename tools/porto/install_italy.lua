-- porto/install_italy: EDIT mode. Installs the Italy page of the Passport and Bella's beach game (Oct 9 2026, Shannon:
-- "please can you check how we did that system with the French map and duplicate it for the Italy map" + the sea glass /
-- shell game with Bella on the beach). Everything is exact-string patching with guards, or new instances. Nothing runs
-- unless every find hits exactly once and every patched Source compiles; originals -> ServerStorage.HudBackup.*_pre_italy.
-- Output lines start with "QQ ITA". Re-running is refused by the guards (already patched) except for the new instances,
-- which are left alone if present.
if game:GetService("RunService"):IsRunning() then warn("QQ ITA ABORT - Play mode") return end
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local P = workspace:FindFirstChild("Passport")
local Grotta = workspace:FindFirstChild("Grotta")
local Cat, Jr, Vis, Cl = P and P:FindFirstChild("Catalogue"), P and P:FindFirstChild("Journal"), P and P:FindFirstChild("PassportVisuals"), P and P:FindFirstChild("PassportClient")
local Polpo = Grotta and Grotta:FindFirstChild("PolpoServer")
for _, pair in ipairs({{Cat, "Catalogue"}, {Jr, "Journal"}, {Vis, "PassportVisuals"}, {Cl, "PassportClient"}, {Polpo, "Grotta.PolpoServer"}}) do
	if not (pair[1] and pair[1]:IsA("LuaSourceContainer")) then warn("QQ ITA ABORT - missing " .. pair[2]) return end
end
local LEN = {[Cat] = 7793, [Jr] = 12486, [Vis] = 3783, [Cl] = 27056}
for s, n in pairs(LEN) do
	if #s.Source ~= n then warn(string.format("QQ ITA ABORT - %s.Source is %d chars, expected %d (already patched, or changed since Oct 9)", s.Name, #s.Source, n)) return end
end

local PATCHES = {
	{Cat, "Catalogue", {{[===[
 {id="keeper",name="Keeper of the Great Acorn"]===], [===[
 {id="porto_harbour",name="Friends of the harbour",area="porto",icon="rescue",hint="Meet every squirrel at the harbour.",detail="Fifteen squirrels live and work round the harbour of Porto Nocciola: on the quay, the piers, the fish market and the beach beside it. Click each one or run into it. Your Passport counts them as you go."},
 {id="porto_borgo",name="Friends of the Via della Piazza",area="porto",icon="rescue",hint="Meet every squirrel in the town.",detail="Fifteen squirrels are up the hill in the town: the piazza with its fountain, the pizzeria and the bakery, the clock tower and the lanes. Click each one or run into it."},
 {id="porto_groves",name="Friends of the Groves",area="porto",icon="rescue",hint="Meet every squirrel in the Groves.",detail="Fourteen squirrels are out in the Groves and along the coast: the lemon and olive terraces, the lighthouse, the cliffs, the sand spit and the beach. Click each one or run into it."},
 {id="porto_bell",name="A ringing buongiorno",area="porto",icon="bell",hint="Ring the brass bell at the harbour office.",detail="The Capitaneria del Porto by the quay keeps a brass harbour bell. Walk up to it and give it a ring to tell Porto Nocciola you have arrived."},
 {id="cappuccino",name="Cappuccino zoomies",area="porto",icon="coffee",hint="Drink a cappuccino at the piazza.",detail="Sit at a table at the pizzeria, the bakery or the gelateria and drink a cappuccino for 5 acorns. It gives you extra speed for five minutes. Try it on the Scalinata dei Fiori!"},
 {id="porto_lemon",name="When life gives you lemons",area="porto",icon="acorn",hint="Buy a lemon from the Lemon Seller.",detail="The Lemon Seller Squirrel in the Groves sells lemons for 8 acorns. Buy one and it goes in your purse. They say the parfumerie in France will want them one day."},
 {id="porto_crabs",name="Beppe's bucket",area="porto",icon="boat",hint="Catch crabs and sell them to Beppe at the fish market.",detail="Buy a crab trap in the Acorn Store, cast it from the tide pools or the little cove, wait, and pull it in. Take your catch to Beppe at the fish market: 3 acorns a crab, and a golden crab is worth 100!"},
 {id="porto_funicular",name="Up the hill",area="porto",icon="flag",hint="Ride the funicular up from the harbour.",detail="The funicular runs from the bottom stop by the harbour up to the town. Step into a car at either end and ride it all the way. Mind the view out of the left side on the way up."},
 {id="porto_opera",name="Bravo!",area="porto",icon="book",hint="Listen to the opera duet in the piazza.",detail="The Fat Lady Squirrel and Nino the accordion player perform in the piazza. Walk up to her and choose Listen to hear her sing. Bravo, bravissima!"},
 {id="porto_polpo",name="Grotta rescue",area="porto",icon="rescue",hint="Free the young squirrels from Polpo Brontolone.",detail="Polpo Brontolone, the grumpy octopus, keeps three young squirrels in cages at the back of the Grotta Azzurra. Climb over him while he dozes and open every cage. If he wakes, the slingshot helps."},
 {id="porto_beach",name="Bella's beach finds",area="porto",icon="glace",hint="Collect sea glass and shells on the beach and make something with Bella.",detail="The sand round the Sea Glass Collector Squirrel (call her Bella) is scattered with sea glass and shells. Pick them up and show them to her: she makes a suncatcher, a shell necklace or a vase with you and pays you acorns. Find the purple piece and she makes you a parfum bottle to keep for France."},
 {id="keeper",name="Keeper of the Great Acorn"]===]}}},
	{Jr, "Journal", {{[===[
 elseif id=="keeper" then return "First to complete all 44 squirrels that day!]===], [===[
 elseif id=="porto_harbour" or id=="porto_borgo" or id=="porto_groves" then return "Met every squirrel in "..(d.area or "that part of Porto Nocciola").."! "..tostring(d.found or "All").." new friends."
 elseif id=="porto_bell" then return "Rang the brass bell at the Capitaneria del Porto. Buongiorno, Porto Nocciola!"
 elseif id=="cappuccino" then return string.format("Drank a cappuccino in the piazza and zoomed round Porto Nocciola at +%d%% for %s minutes.",d.boost or 35,tostring((d.seconds or 300)/60))
 elseif id=="porto_lemon" then return "Bought a lemon from the Lemon Seller in the Groves. Keep it for the parfumerie!"
 elseif id=="porto_crabs" then return "Sold your catch to Beppe at the fish market"..((d.gold or 0)>0 and ", and one of them was golden!" or ".")
 elseif id=="porto_funicular" then return "Rode the funicular up the hill above Porto Nocciola. What a view!"
 elseif id=="porto_opera" then return "Stood in the piazza and heard The Fat Lady Squirrel sing, with Nino on the accordion. Bravo!"
 elseif id=="porto_polpo" then return "Freed the young squirrels from Polpo Brontolone's cages in the Grotta Azzurra."
 elseif id=="porto_beach" then return "Combed the beach for sea glass and shells and made a "..(d.made and d.made:lower() or "treasure").." with Bella."..((d.prize or 0)>0 and (" She paid "..d.prize.." acorns.") or (d.kept and " It is yours to keep." or ""))
 elseif id=="keeper" then return "First to complete all 44 squirrels that day!]===]}}},
	{Vis, "PassportVisuals", {{[===[
photos="camera"}]===], [===[
photos="camera",porto_harbour="fishing_squirrel",porto_borgo="waiter_squirrel",porto_groves="birdwatch_squirrel",porto_bell="church",cappuccino="coffee",porto_lemon="sunflower_squirrel",porto_crabs="squirrel_buccaneer",porto_funicular="ski_squirrel",porto_opera="glam_squirrel",porto_polpo="super_squirrel",porto_beach="surfing_squirrel"}]===]}}},
	{Cl, "PassportClient", {{[===[
 return #have.." of 4 photos ("..table.concat(have,", ").."). Still to find: "..table.concat(need,", ").."."
end
]===], [===[
 return #have.." of 4 photos ("..table.concat(have,", ").."). Still to find: "..table.concat(need,", ").."."
end
-- Porto outings (Oct 9 2026): the three "meet every squirrel" lines count from FoundIds; the beach counts kinds found
local PortoAreas;pcall(function()PortoAreas=require(game:GetService("ReplicatedStorage"):WaitForChild("PortoAreas",5))end)
local function hintFor(e)
 if e.id=="photos" then return photoHint() end
 if PortoAreas then
  for area,ids in pairs(PortoAreas.lists)do
   if PortoAreas.outing[area]==e.id then
    local have={};for id in string.gmatch(p:GetAttribute("FoundIds") or "","[^,]+")do have[id]=true end
    local n=0;for _,id in ipairs(ids)do if have[id] then n+=1 end end
    return string.format("%d of %d squirrels found in %s.",n,#ids,PortoAreas.names[area])
   end
  end
  if e.id=="porto_beach" then
   local n=0;for _,k in ipairs(PortoAreas.beachKinds)do if item(k)>0 then n+=1 end end
   if n>0 then return string.format("%d of %d kinds of beach finds so far. Show them to Bella on the Spiaggia.",n,#PortoAreas.beachKinds) end
  end
 end
 return e.hint
end
]===]}, {[===[
addRow(e.id,e.name,e.id=="photos" and photoHint() or e.hint,nil,function()openDetail(id)end)]===], [===[
addRow(e.id,e.name,hintFor(e),nil,function()openDetail(id)end)]===]}, {[===[
or name=="Item_porto" or name:find("^Item_photo")~=nil) and not pending then]===], [===[
or name=="Item_porto" or name=="FoundIds" or name:find("^Item_photo")~=nil or name:find("^Item_seaglass")~=nil or name:find("^Item_shell")~=nil) and not pending then]===]}}},
	{Polpo, "PolpoServer", {{[===[
passport:Fire(player, "rescue", {})]===], [===[
passport:Fire(player, "porto_polpo", {})]===]}}},
}
local out = {}
for _, pt in ipairs(PATCHES) do
	local s, name, pairs_ = pt[1], pt[2], pt[3]
	local src = s.Source
	for i, p in ipairs(pairs_) do
		local a, b = src:find(p[1], 1, true)
		if not a then warn("QQ ITA ABORT - " .. name .. " find " .. i .. " not found; nothing changed") return end
		if src:find(p[1], b + 1, true) then warn("QQ ITA ABORT - " .. name .. " find " .. i .. " matches more than once; nothing changed") return end
	end
	local o = src
	for _, p in ipairs(pairs_) do
		local a, b = o:find(p[1], 1, true)
		o = o:sub(1, a - 1) .. p[2] .. o:sub(b + 1)
	end
	local f, err = loadstring(o)
	if not f then warn("QQ ITA ABORT - patched " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
	out[s] = o
end

local NEW = {
	PortoAreas = [====[
-- PortoAreas (ReplicatedStorage): the Porto Nocciola passport outings' shared tables (Oct 9 2026). The three "find all"
-- outings use the registry ids of each area (SquirrelRegistry map porto: harbour, borgo = Via della Piazza, groves).
-- Keep this in step with the registry when squirrels are added.
return {
	lists = {
		harbour = {"customs_squirrel", "fishmonger_squirrel", "deckhand_squirrel", "netmender_squirrel", "gelato_squirrel", "boatpainter_squirrel",
			"realtor_squirrel", "italytourist_squirrel", "tightrope_squirrel", "seacaptain_squirrel", "sunbather_squirrel", "crabcatcher_squirrel",
			"conductor_squirrel", "lifeguard_squirrel", "octopus_squirrel"},
		borgo = {"sassyshopper_squirrel", "pogo_squirrel", "pizzadelivery_squirrel", "baker_squirrel", "giulia_market_squirrel",
			"officer_acorn_police_squirrel", "goldenyears_squirrel", "goodneighbor_squirrel", "operasinger_squirrel", "broomseller_squirrel",
			"accordion_squirrel", "pizzamaker_squirrel", "church_mouse_cousin", "clockmaker_squirrel", "postcard_squirrel"},
		groves = {"lemonseller_squirrel", "olivepicker_squirrel", "snorkel_squirrel", "hiker_squirrel", "cliffdiver_squirrel", "stargazer_squirrel",
			"treasurehunter_squirrel", "lighthousekeeper_squirrel", "keeperswife_squirrel", "photographer_squirrel", "droneflyer_squirrel",
			"seaglass_squirrel", "guitarist_squirrel", "butterfly_squirrel"},
	},
	outing = {harbour = "porto_harbour", borgo = "porto_borgo", groves = "porto_groves"},
	names = {harbour = "the harbour", borgo = "the Via della Piazza", groves = "the Groves"},
	-- Bella's beach finds: the item ids (Item_<id> on the player), in the order the panel shows them
	beachKinds = {"seaglass_green", "seaglass_brown", "seaglass_white", "seaglass_blue", "seaglass_purple", "shell_scallop", "shell_spiral", "shell_cowrie"},
}
]====],
	PortoActivities = [====[
-- PortoActivities (workspace.PortoPassport, server): the Porto Nocciola passport outings that nothing fired before
-- (Oct 9 2026, Shannon: "I don't think we have added the activities to the passport ... duplicate the French system for the
-- Italy map"). Every outing is one RS.PassportActivity:Fire(player, id, data), exactly as the French scripts do.
--   porto_harbour / porto_borgo / porto_groves  all the squirrels of that area found (from the FoundIds attribute)
--   cappuccino      a Porto coffee: SpeedServer fires "coffee"; this echoes it as the Italian outing when you are in Porto
--   porto_lemon     a lemon bought from the Lemon Seller (AwardItems "lemon")
--   porto_crabs     crabs sold to Beppe (AwardItems "crabs" / "goldcrabs" going down = a sale)
--   porto_bell      the brass harbour bell at the Capitaneria del Porto (its own prompt; this listens)
--   porto_funicular a ride in a funicular car (seen in a car at one height, still in it 20 studs higher or lower)
--   porto_opera     "Listen" at the opera duet: plays the aria (sound 9042832054, attr OperaSoundId) and stamps
--   porto_polpo     fired by PolpoServer itself (patched from the French "rescue")
--   porto_beach     fired by SeaGlassServer when something is made with Bella
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local passport = RS:WaitForChild("PassportActivity")
local awardItems = RS:WaitForChild("AwardItems")
local Areas = require(RS:WaitForChild("PortoAreas"))
local F = script.Parent
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local function str(name, d) local v = F:GetAttribute(name) return type(v) == "string" and v or d end
local function fire(p, id, data) if p and p.Parent == Players then passport:Fire(p, id, data or {}) end end
local function inPorto(p)
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	local pos = root and root.Position
	return pos ~= nil and pos.X > 150 and pos.Z < -480
end

-- ---------- the three "find all" outings ----------
local stamped = {}   -- [player][area] this session (mark itself only stamps once a day; this just avoids chatter)
local function checkFinds(p)
	local have = {}
	for id in string.gmatch(p:GetAttribute("FoundIds") or "", "[^,]+") do have[id] = true end
	stamped[p] = stamped[p] or {}
	for area, ids in pairs(Areas.lists) do
		local n = 0
		for _, id in ipairs(ids) do if have[id] then n += 1 end end
		if n >= #ids and n > 0 and not stamped[p][area] then
			stamped[p][area] = true
			fire(p, Areas.outing[area], {found = n, area = Areas.names[area]})
		end
	end
end

-- ---------- echoes of things other scripts already fire or award ----------
passport.Event:Connect(function(p, id, data)
	if typeof(p) ~= "Instance" or not p:IsA("Player") then return end
	if id == "coffee" and inPorto(p) then fire(p, "cappuccino", type(data) == "table" and table.clone(data) or {}) end
end)
awardItems.Event:Connect(function(p, id, n)
	if typeof(p) ~= "Instance" or not p:IsA("Player") or type(id) ~= "string" then return end
	n = tonumber(n) or 0
	if id == "lemon" and n > 0 then fire(p, "porto_lemon", {})
	elseif (id == "crabs" or id == "goldcrabs") and n < 0 then fire(p, "porto_crabs", {crabs = -n, gold = id == "goldcrabs" and -n or 0}) end
end)

-- ---------- the harbour bell ----------
task.spawn(function()
	local porto = workspace:WaitForChild("PortoNocciola", 30)
	if not porto then return end
	local hooked = 0
	for _, d in ipairs(porto:GetDescendants()) do
		if d.Name == "Brass harbour bell" then
			local prompt = d:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then prompt.Triggered:Connect(function(p) fire(p, "porto_bell", {}) end); hooked += 1 end
		end
	end
	if hooked == 0 then warn("PortoActivities: no prompt on a 'Brass harbour bell' - the bell outing cannot be earned") end
end)

-- ---------- the opera duet: a Listen prompt and the aria ----------
task.spawn(function()
	local singer = workspace:WaitForChild("operasinger_squirrel_color", 30)
	local part = singer and (singer.PrimaryPart or singer:FindFirstChildWhichIsA("BasePart", true))
	if not part then warn("PortoActivities: no opera singer model - the opera outing cannot be earned") return end
	local sound = part:FindFirstChild("OperaSong")
	if not sound then
		sound = Instance.new("Sound"); sound.Name = "OperaSong"; sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 10; sound.RollOffMaxDistance = 80; sound.Volume = num("OperaVolume", 0.8); sound.Parent = part
	end
	sound.SoundId = "rbxassetid://" .. str("OperaSoundId", "9042832054")
	local prompt = part:FindFirstChild("OperaPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt"); prompt.Name = "OperaPrompt"; prompt.ObjectText = "The opera duet"; prompt.ActionText = "Listen"
		prompt.MaxActivationDistance = 12; prompt.HoldDuration = 0; prompt.RequiresLineOfSight = false; prompt.UIOffset = Vector2.new(0, -40)
		prompt.Parent = part
	end
	local listeners = {}
	prompt.Triggered:Connect(function(p)
		listeners[p] = true
		if not sound.IsPlaying then
			sound:Play()
			prompt.ActionText = "Listening..."
		end
		fire(p, "porto_opera", {})
	end)
	sound.Ended:Connect(function() prompt.ActionText = "Listen"; listeners = {} end)
end)

-- ---------- the funicular: in a car at one height, still in it 20 studs higher or lower ----------
task.spawn(function()
	local porto = workspace:WaitForChild("PortoNocciola", 30)
	local fun = porto and porto:FindFirstChild("15 Funicolare")
	if not fun then warn("PortoActivities: no '15 Funicolare' - the funicular outing cannot be earned") return end
	local cars = {}
	for _, d in ipairs(fun:GetDescendants()) do if d:IsA("Model") and d.Name:sub(1, 4) == "Car_" then table.insert(cars, d) end end
	if #cars == 0 then warn("PortoActivities: no Car_* models under the funicular") return end
	local riding = {}   -- [player] = {car, y0}
	local function inside(car, pos)
		local cf, size = car:GetBoundingBox()
		local l = cf:PointToObjectSpace(pos)
		return math.abs(l.X) <= size.X / 2 + 1.5 and math.abs(l.Y) <= size.Y / 2 + 2.5 and math.abs(l.Z) <= size.Z / 2 + 1.5
	end
	while true do
		task.wait(1)
		for _, p in ipairs(Players:GetPlayers()) do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local r = riding[p]
				if r then
					if inside(r.car, root.Position) then
						if math.abs(r.car:GetPivot().Position.Y - r.y0) >= num("RideHeight", 20) then fire(p, "porto_funicular", {}); riding[p] = nil end
					else riding[p] = nil end
				else
					for _, car in ipairs(cars) do
						if inside(car, root.Position) then riding[p] = {car = car, y0 = car:GetPivot().Position.Y} break end
					end
				end
			end
		end
	end
end)

-- ---------- players ----------
local function watch(p)
	p:GetAttributeChangedSignal("FoundIds"):Connect(function() checkFinds(p) end)
	task.delay(5, function() if p.Parent then checkFinds(p) end end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(p) stamped[p] = nil end)
print("PortoActivities: ready")
]====],
	Recipes = [====[
-- SeaGlassRecipes (workspace.SeaGlass, shared by server and client): what Bella's beach holds and what she makes with you.
-- Item ids are Item_<id> on the player (saved like everything else through AwardItems).
local R = {}
R.kinds = {
	{id = "seaglass_green",  name = "Green sea glass",   short = "green",   colour = Color3.fromRGB(96, 190, 120),  glass = true, weight = 30},
	{id = "seaglass_brown",  name = "Brown sea glass",   short = "brown",   colour = Color3.fromRGB(150, 100, 60),  glass = true, weight = 25},
	{id = "seaglass_white",  name = "Frosted sea glass", short = "white",   colour = Color3.fromRGB(236, 241, 241), glass = true, weight = 20},
	{id = "seaglass_blue",   name = "Blue sea glass",    short = "blue",    colour = Color3.fromRGB(80, 140, 210),  glass = true, weight = 17},
	{id = "seaglass_purple", name = "Purple sea glass",  short = "purple",  colour = Color3.fromRGB(160, 100, 200), glass = true, weight = 8, rare = true},
	{id = "shell_scallop",   name = "Scallop shell",     short = "scallop", colour = Color3.fromRGB(240, 205, 180), shell = "scallop", weight = 22},
	{id = "shell_spiral",    name = "Spiral shell",      short = "spiral",  colour = Color3.fromRGB(225, 190, 150), shell = "spiral",  weight = 16},
	{id = "shell_cowrie",    name = "Cowrie shell",      short = "cowrie",  colour = Color3.fromRGB(215, 170, 130), shell = "cowrie",  weight = 16},
}
R.byId = {}
for _, k in ipairs(R.kinds) do R.byId[k.id] = k end
-- needs: item id -> count. pay: acorns Bella gives you for it. keep: it is yours instead (Item_<keep> = 1, once).
R.recipes = {
	{id = "suncatcher", name = "Sea glass suncatcher", needs = {seaglass_green = 2, seaglass_blue = 1, seaglass_white = 1}, pay = 60,
		line = "Hang it in a window and the whole room goes green and blue!"},
	{id = "necklace", name = "Shell necklace", needs = {shell_cowrie = 2, shell_spiral = 1, seaglass_white = 1}, pay = 70,
		line = "Cowries, a spiral and a frosted bead. Bellissima!"},
	{id = "vase", name = "Sea glass vase", needs = {seaglass_green = 3, seaglass_brown = 2, shell_scallop = 1}, pay = 80,
		line = "Mosaic all the way round, with a scallop for the front. My best seller!"},
	{id = "parfum", name = "Parfum bottle", needs = {seaglass_purple = 1, seaglass_white = 2, seaglass_blue = 1}, keep = "parfum_bottle",
		line = "The purple one! A bottle like this deserves a scent of its own. Keep it safe for France."},
}
R.byRecipe = {}
for _, r in ipairs(R.recipes) do R.byRecipe[r.id] = r end
function R.needsText(r)
	local parts = {}
	for _, k in ipairs(R.kinds) do
		local n = r.needs[k.id]
		if n then table.insert(parts, n .. " " .. k.short) end
	end
	return table.concat(parts, ", ")
end
return R
]====],
	SeaGlassServer = [====[
-- SeaGlassServer (workspace.SeaGlass): Bella's beach finds (Oct 9 2026, Shannon: "find sea glass and shells ... build the
-- things with them ... sell them for acorns; one item, the parfum bottle, you can keep"; today's small version: "the
-- interaction can just be with the squirrel on the beach", and the squirrel finding the glass IS Bella).
-- Sea glass and shells lie on the sand round the Sea Glass Collector Squirrel (Bella) on the Spiaggia. Walk up, "Pick up":
-- Item_<kind> +1 (AwardItems, so it is saved). COUNT pieces are out at a time; a taken piece grows back somewhere else after
-- RESPAWN_MIN..RESPAWN_MAX s. Bella's prompt opens the client's panel; "make" is checked HERE: the finds come off
-- (AwardItems negative), Bella pays acorns (AwardAcorns + the Acorns attribute, as CrabServer does) or, for the parfum
-- bottle, Item_parfum_bottle = 1 to keep. The first thing made stamps the passport outing porto_beach.
-- Attributes on workspace.SeaGlass: Count 8, RespawnMin 45, RespawnMax 90, BoxMin/BoxMax (the sand to scatter on).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local G = script.Parent
local R = require(G:WaitForChild("Recipes"))
local ev = G:WaitForChild("SeaGlassEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local passport = RS:FindFirstChild("PassportActivity")
local pieces = G:WaitForChild("Pieces")
local function num(name, d) local v = G:GetAttribute(name) return type(v) == "number" and v or d end
local function item(p, id) return tonumber(p:GetAttribute("Item_" .. id)) or 0 end

local bella = workspace:WaitForChild("seaglass_squirrel_color", 60)
local bellaPos = bella and bella:GetPivot().Position or Vector3.new(399.6, -48.8, -1054.8)

-- ---------- where a piece may lie: sand, away from Bella and from each other, nothing built on it ----------
local tparams = RaycastParams.new(); tparams.FilterType = Enum.RaycastFilterType.Exclude; tparams.IgnoreWater = true
local oparams = OverlapParams.new(); oparams.FilterType = Enum.RaycastFilterType.Exclude; oparams.FilterDescendantsInstances = {workspace.Terrain, pieces}
local spots = {}
local function findSpots()
	local a = G:GetAttribute("BoxMin"); local b = G:GetAttribute("BoxMax")
	if typeof(a) ~= "Vector3" then a = Vector3.new(388, -60, -1095) end
	if typeof(b) ~= "Vector3" then b = Vector3.new(445, -40, -1046) end
	local rng = Random.new(7)
	local tries = 0
	while #spots < 40 and tries < 400 do
		tries += 1
		local x, z = rng:NextNumber(a.X, b.X), rng:NextNumber(a.Z, b.Z)
		local hit = workspace:Raycast(Vector3.new(x, b.Y + 20, z), Vector3.new(0, -(b.Y - a.Y + 40), 0), tparams)
		if hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Sand and hit.Normal.Y > 0.8 then
			local pos = hit.Position
			local ok = (pos - bellaPos).Magnitude >= 3.5
			if ok then for _, s in ipairs(spots) do if (s - pos).Magnitude < 2.6 then ok = false break end end end
			if ok and #workspace:GetPartBoundsInRadius(pos, 1.3, oparams) > 0 then ok = false end
			if ok then table.insert(spots, pos) end
		end
	end
	print(string.format("SeaGlassServer: %d spots on the sand (%d tries)", #spots, tries))
end
findSpots()
if #spots < 8 then warn("SeaGlassServer: not enough sand spots; set BoxMin/BoxMax on workspace.SeaGlass") end

-- ---------- the pieces ----------
local function pickKind(rng)
	local total = 0
	for _, k in ipairs(R.kinds) do total += k.weight end
	local r = rng:NextNumber(0, total)
	for _, k in ipairs(R.kinds) do r -= k.weight; if r <= 0 then return k end end
	return R.kinds[1]
end
local function build(kind, pos, rng)
	local m = Instance.new("Model"); m.Name = "Find"; m:SetAttribute("Kind", kind.id)
	local body = Instance.new("Part"); body.Name = "Body"; body.Anchored = true; body.CanCollide = false; body.CanTouch = false; body.CastShadow = false
	body.Color = kind.colour
	local yaw = rng:NextNumber(0, math.pi * 2)
	if kind.glass then
		body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.55, 0.28, 0.45)
		body.Material = Enum.Material.Glass; body.Transparency = 0.2; body.Reflectance = 0.15
		body.CFrame = CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, yaw, 0)
		local l = Instance.new("PointLight"); l.Color = kind.colour; l.Brightness = 0.7; l.Range = 3.5; l.Shadows = false; l.Parent = body
	elseif kind.shell == "scallop" then
		body.Shape = Enum.PartType.Cylinder; body.Size = Vector3.new(0.14, 0.62, 0.62); body.Material = Enum.Material.Sandstone
		body.CFrame = CFrame.new(pos + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, yaw, math.rad(90))
	elseif kind.shell == "spiral" then
		body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.3, 0.3, 0.58); body.Material = Enum.Material.Sandstone
		body.CFrame = CFrame.new(pos + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, yaw, 0)
	else
		body.Shape = Enum.PartType.Ball; body.Size = Vector3.new(0.42, 0.26, 0.3); body.Material = Enum.Material.SmoothPlastic; body.Reflectance = 0.1
		body.CFrame = CFrame.new(pos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, yaw, 0)
	end
	body.Parent = m; m.PrimaryPart = body
	local pr = Instance.new("ProximityPrompt"); pr.Name = "PickPrompt"; pr.ObjectText = kind.name; pr.ActionText = "Pick up"
	pr.MaxActivationDistance = 8; pr.HoldDuration = 0; pr.RequiresLineOfSight = false; pr.UIOffset = Vector2.new(0, -10); pr.Parent = body
	m.Parent = pieces
	return m, pr
end

local used = {}      -- [spotIndex] = piece model
local rng = Random.new()
local function freeSpot()
	local free = {}
	for i in ipairs(spots) do if not used[i] then table.insert(free, i) end end
	if #free == 0 then return nil end
	return free[rng:NextInteger(1, #free)]
end
local taking = {}
local function spawnOne()
	local i = freeSpot()
	if not i then return end
	local kind = pickKind(rng)
	local m, pr = build(kind, spots[i], rng)
	used[i] = m
	pr.Triggered:Connect(function(p)
		if taking[m] or not m.Parent then return end
		taking[m] = true
		awardItems:Fire(p, kind.id, 1)
		ev:FireClient(p, "found", kind.id, kind.name, item(p, kind.id) + 1, kind.rare == true)
		used[i] = nil
		m:Destroy()
		task.delay(rng:NextNumber(num("RespawnMin", 45), num("RespawnMax", 90)), spawnOne)
	end)
end
for _ = 1, num("Count", 8) do spawnOne() end

-- ---------- Bella ----------
if bella then
	local part = bella.PrimaryPart or bella:FindFirstChildWhichIsA("BasePart", true)
	if part and not part:FindFirstChild("BellaPrompt") then
		local pr = Instance.new("ProximityPrompt"); pr.Name = "BellaPrompt"; pr.ObjectText = "Bella"; pr.ActionText = "Show your beach finds"
		pr.MaxActivationDistance = 10; pr.HoldDuration = 0; pr.RequiresLineOfSight = false; pr.UIOffset = Vector2.new(0, -60); pr.Parent = part
		pr.Triggered:Connect(function(p) ev:FireClient(p, "open") end)
	end
else
	warn("SeaGlassServer: no seaglass_squirrel_color in the world - Bella's prompt is missing")
end

-- ---------- making things ----------
local busy = {}
ev.OnServerEvent:Connect(function(p, what, recipeId)
	if what ~= "make" or busy[p] then return end
	local r = type(recipeId) == "string" and R.byRecipe[recipeId]
	if not r then return end
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - bellaPos).Magnitude > 16 then ev:FireClient(p, "nope", "Come closer to Bella first.") return end
	if r.keep and item(p, r.keep) > 0 then ev:FireClient(p, "nope", "You already have your " .. r.name:lower() .. ". Keep it safe!") return end
	for id, n in pairs(r.needs) do
		if item(p, id) < n then ev:FireClient(p, "nope", "Not enough " .. (R.byId[id] and R.byId[id].short or id) .. " yet. Keep looking!") return end
	end
	busy[p] = true
	for id, n in pairs(r.needs) do awardItems:Fire(p, id, -n) end
	local pay = 0
	if r.keep then
		awardItems:Fire(p, r.keep, 1)
	else
		pay = r.pay or 0
		awardAcorns:Fire(p, pay)
		p:SetAttribute("Acorns", (p:GetAttribute("Acorns") or 0) + pay)
	end
	if passport then passport:Fire(p, "porto_beach", {made = r.name, prize = pay, kept = r.keep ~= nil}) end
	busy[p] = nil
	ev:FireClient(p, "made", r.id, r.name, pay, r.line)
end)
Players.PlayerRemoving:Connect(function(p) busy[p] = nil end)
print("SeaGlassServer: ready")
]====],
	SeaGlassClient = [====[
-- SeaGlassClient (workspace.SeaGlass, RunContext Client): Bella's beach finds on your screen (Oct 9 2026). A little toast when
-- you pick something up; Bella's panel (her prompt opens it): your finds in a row, the four things she makes, Make buttons
-- that light up when you have the pieces. One panel in the middle of the screen, sized for a phone (it sets the PlayerGui
-- attribute OpenPanel like the other panels, so the camera and the rest step aside). Bella speaks through SquirrelBubble.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local G = script.Parent
local R = require(G:WaitForChild("Recipes"))
local ev = G:WaitForChild("SeaGlassEvent")
local Bubble
pcall(function() Bubble = require(RS:WaitForChild("SquirrelBubble", 10)) end)
local C = Color3.fromRGB
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local CREAM, INK, GOLD, BROWN, GREEN, GREY = C(255, 246, 220), C(58, 36, 16), C(255, 202, 62), C(58, 36, 16), C(112, 160, 84), C(214, 202, 176)
local function item(id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = o end
local function stroke(o, col, th) local s = Instance.new("UIStroke") s.Color = col s.Thickness = th s.Parent = o return s end
local function bella() return workspace:FindFirstChild("seaglass_squirrel_color") end
local function say(line, secs)
	local m = bella()
	if Bubble and m then pcall(function() Bubble.say(m, line, {secs = secs or 4.5}) end) end
end

local gui = Instance.new("ScreenGui"); gui.Name = "SeaGlassGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 7; gui.Parent = pg

-- ---------- the toast ----------
local toast = Instance.new("TextLabel"); toast.Name = "Toast"; toast.AnchorPoint = Vector2.new(0.5, 1); toast.Size = UDim2.fromOffset(300, 34)
toast.BackgroundColor3 = BROWN; toast.BackgroundTransparency = 0.12; toast.BorderSizePixel = 0; toast.FontFace = FONT; toast.TextSize = 16
toast.TextColor3 = CREAM; toast.TextScaled = true; toast.Visible = false; toast.ZIndex = 8; toast.Parent = gui
corner(toast, 10); stroke(toast, GOLD, 2)
local toastAt = 0
local function showToast(text, secs)
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	toast.Size = UDim2.fromOffset(math.min(320, v.X - 40), 34)
	toast.Position = UDim2.fromOffset(v.X / 2, v.Y - 120)
	toast.Text = text; toast.Visible = true
	toastAt = os.clock(); local t = toastAt
	task.delay(secs or 2.5, function() if toastAt == t then toast.Visible = false end end)
end

-- ---------- the panel ----------
local panel = Instance.new("Frame"); panel.Name = "Panel"; panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = BROWN; panel.BackgroundTransparency = 0.06; panel.BorderSizePixel = 0; panel.Visible = false; panel.ZIndex = 8; panel.Parent = gui
corner(panel, 14); stroke(panel, GOLD, 2)
local title = Instance.new("TextLabel"); title.Position = UDim2.fromOffset(14, 8); title.Size = UDim2.new(1, -70, 0, 28); title.BackgroundTransparency = 1
title.FontFace = FONT; title.TextSize = 20; title.TextColor3 = GOLD; title.TextXAlignment = Enum.TextXAlignment.Left; title.Text = "Bella's beach finds"; title.ZIndex = 9; title.Parent = panel
local closeBtn = Instance.new("TextButton"); closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -8, 0, 6); closeBtn.Size = UDim2.fromOffset(36, 32)
closeBtn.BackgroundColor3 = C(170, 70, 50); closeBtn.BorderSizePixel = 0; closeBtn.FontFace = FONT; closeBtn.TextSize = 18; closeBtn.TextColor3 = CREAM; closeBtn.Text = "X"; closeBtn.ZIndex = 9; closeBtn.Parent = panel
corner(closeBtn, 8)
local findsRow = Instance.new("Frame"); findsRow.Position = UDim2.fromOffset(10, 42); findsRow.Size = UDim2.new(1, -20, 0, 58); findsRow.BackgroundTransparency = 1; findsRow.ZIndex = 9; findsRow.Parent = panel
local dots = {}
for i, k in ipairs(R.kinds) do
	local cell = Instance.new("Frame"); cell.Size = UDim2.new(1 / #R.kinds, 0, 1, 0); cell.Position = UDim2.new((i - 1) / #R.kinds, 0, 0, 0); cell.BackgroundTransparency = 1; cell.ZIndex = 9; cell.Parent = findsRow
	local d = Instance.new("Frame"); d.AnchorPoint = Vector2.new(0.5, 0); d.Position = UDim2.new(0.5, 0, 0, 2); d.Size = UDim2.fromOffset(22, k.glass and 22 or 18); d.BackgroundColor3 = k.colour; d.BorderSizePixel = 0; d.ZIndex = 10; d.Parent = cell
	corner(d, k.glass and 11 or 6); stroke(d, k.rare and GOLD or C(90, 64, 40), 1.5)
	local n = Instance.new("TextLabel"); n.AnchorPoint = Vector2.new(0.5, 0); n.Position = UDim2.new(0.5, 0, 0, 27); n.Size = UDim2.fromOffset(40, 16); n.BackgroundTransparency = 1
	n.FontFace = FONT; n.TextSize = 14; n.TextColor3 = CREAM; n.Text = "0"; n.ZIndex = 10; n.Parent = cell
	local s = Instance.new("TextLabel"); s.AnchorPoint = Vector2.new(0.5, 0); s.Position = UDim2.new(0.5, 0, 0, 42); s.Size = UDim2.fromOffset(46, 14); s.BackgroundTransparency = 1
	s.FontFace = FONT; s.TextSize = 11; s.TextColor3 = C(220, 205, 180); s.Text = k.short; s.ZIndex = 10; s.Parent = cell
	dots[k.id] = n
end
local rows = {}
local ROW_Y, ROW_H = 106, 46
for i, r in ipairs(R.recipes) do
	local row = Instance.new("Frame"); row.Position = UDim2.fromOffset(10, ROW_Y + (i - 1) * ROW_H); row.Size = UDim2.new(1, -20, 0, ROW_H - 6)
	row.BackgroundColor3 = C(78, 52, 28); row.BorderSizePixel = 0; row.ZIndex = 9; row.Parent = panel
	corner(row, 10)
	local nm = Instance.new("TextLabel"); nm.Position = UDim2.fromOffset(10, 3); nm.Size = UDim2.new(1, -130, 0, 18); nm.BackgroundTransparency = 1
	nm.FontFace = FONT; nm.TextSize = 15; nm.TextColor3 = CREAM; nm.TextXAlignment = Enum.TextXAlignment.Left; nm.TextTruncate = Enum.TextTruncate.AtEnd; nm.Text = r.name; nm.ZIndex = 10; nm.Parent = row
	local nd = Instance.new("TextLabel"); nd.Position = UDim2.fromOffset(10, 21); nd.Size = UDim2.new(1, -130, 0, 16); nd.BackgroundTransparency = 1
	nd.FontFace = FONT; nd.TextSize = 12; nd.TextColor3 = C(220, 205, 180); nd.TextXAlignment = Enum.TextXAlignment.Left; nd.TextTruncate = Enum.TextTruncate.AtEnd; nd.Text = R.needsText(r); nd.ZIndex = 10; nd.Parent = row
	local b = Instance.new("TextButton"); b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, -8, 0.5, 0); b.Size = UDim2.fromOffset(112, 30)
	b.BackgroundColor3 = GOLD; b.BorderSizePixel = 0; b.FontFace = FONT; b.TextSize = 14; b.TextColor3 = C(84, 48, 18); b.AutoButtonColor = false; b.ZIndex = 10; b.Parent = row
	corner(b, 8)
	b.MouseButton1Click:Connect(function() ev:FireServer("make", r.id) end)
	rows[r.id] = {btn = b, name = nm}
end
local note = Instance.new("TextLabel"); note.Position = UDim2.fromOffset(12, ROW_Y + #R.recipes * ROW_H - 2); note.Size = UDim2.new(1, -24, 0, 22); note.BackgroundTransparency = 1
note.FontFace = FONT; note.TextSize = 13; note.TextColor3 = C(220, 205, 180); note.TextScaled = true; note.Text = ""; note.ZIndex = 9; note.Parent = panel
local function canMake(r)
	if r.keep and item(r.keep) > 0 then return false, "made" end
	for id, n in pairs(r.needs) do if item(id) < n then return false end end
	return true
end
local function refresh()
	for _, k in ipairs(R.kinds) do dots[k.id].Text = tostring(item(k.id)) end
	for _, r in ipairs(R.recipes) do
		local ok, why = canMake(r)
		local b = rows[r.id].btn
		if why == "made" then b.Text = "Yours"; b.BackgroundColor3 = GREEN; b.TextColor3 = CREAM
		else
			b.Text = r.keep and "Make & keep" or ("Make  " .. r.pay .. " acorns")
			b.BackgroundColor3 = ok and GOLD or GREY; b.TextColor3 = ok and C(84, 48, 18) or C(120, 100, 80)
		end
	end
end
local function layout()
	local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local h = ROW_Y + #R.recipes * ROW_H + 24
	panel.Size = UDim2.fromOffset(math.min(380, v.X - 24), math.min(h, v.Y - 16))
end
local open = false
local function closePanel()
	if not open then return end
	open = false; panel.Visible = false
	if pg:GetAttribute("OpenPanel") == "seaglass" then pg:SetAttribute("OpenPanel", nil) end
end
local function openPanel()
	if pg:GetAttribute("OpenPanel") ~= nil and pg:GetAttribute("OpenPanel") ~= "seaglass" then return end
	layout(); refresh(); note.Text = ""
	open = true; panel.Visible = true; pg:SetAttribute("OpenPanel", "seaglass")
	local any = false
	for _, k in ipairs(R.kinds) do if item(k.id) > 0 then any = true break end end
	say(any and "Ciao! Let me see what the sea gave you today." or "Ciao, I'm Bella! Bring me pretty things from the sand and we'll make something.", 4.5)
end
closeBtn.MouseButton1Click:Connect(closePanel)
UIS.InputBegan:Connect(function(input, gp)
	if open and not gp and input.KeyCode == Enum.KeyCode.Escape then closePanel() end
end)
-- walked away from Bella: the panel goes
task.spawn(function()
	while true do
		task.wait(0.5)
		if open then
			local m, root = bella(), player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not m or not root or (m:GetPivot().Position - root.Position).Magnitude > 16 then closePanel() end
		end
	end
end)
for _, k in ipairs(R.kinds) do player:GetAttributeChangedSignal("Item_" .. k.id):Connect(function() if open then refresh() end end) end
player:GetAttributeChangedSignal("Item_parfum_bottle"):Connect(function() if open then refresh() end end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if open then layout() end end) end

ev.OnClientEvent:Connect(function(what, a, b, c, d)
	if what == "open" then openPanel()
	elseif what == "found" then
		local name, count, rare = b, c, d
		showToast(string.format("%s! You have %d.", name, count), rare and 4 or 2.5)
		if rare then say("Is that... the purple one?! Bring it to me!", 5) end
	elseif what == "made" then
		local name, pay, line = b, c, d
		note.Text = pay > 0 and string.format("Bella pays %d acorns for the %s.", pay, name:lower()) or ("The " .. name:lower() .. " is yours to keep.")
		say(line or "Bellissima!", 5)
		refresh()
	elseif what == "nope" then
		note.Text = tostring(a)
	end
end)
print("SeaGlassClient: ready")
]====],
}
for name, src in pairs(NEW) do
	local f, err = loadstring(src)
	if not f then warn("QQ ITA ABORT - new script " .. name .. " does not compile: " .. tostring(err) .. "; nothing changed") return end
end

-- backups, then the patches
local hb = SS:FindFirstChild("HudBackup")
if not hb then hb = Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS end
for _, pt in ipairs(PATCHES) do
	local s = pt[1]
	local bname = pt[2]:gsub("%.", "_") .. "_pre_italy"
	if not hb:FindFirstChild(bname) then
		local bk = s:Clone(); bk.Name = bname
		pcall(function() bk.Enabled = false end)
		bk.Parent = hb
	end
end
for s, o in pairs(out) do s.Source = o end

-- the new pieces
local function module(parent, name, src)
	local m = parent:FindFirstChild(name)
	if m and m:IsA("ModuleScript") then m.Source = src return m end
	m = Instance.new("ModuleScript"); m.Name = name; m.Source = src; m.Parent = parent
	return m
end
module(RS, "PortoAreas", NEW.PortoAreas)

local PP = workspace:FindFirstChild("PortoPassport")
if not PP then PP = Instance.new("Folder"); PP.Name = "PortoPassport"; PP.Parent = workspace end
if PP:GetAttribute("OperaSoundId") == nil then PP:SetAttribute("OperaSoundId", "9042832054") end
if PP:GetAttribute("OperaVolume") == nil then PP:SetAttribute("OperaVolume", 0.8) end
if PP:GetAttribute("RideHeight") == nil then PP:SetAttribute("RideHeight", 20) end
local act = PP:FindFirstChild("PortoActivities")
if not act then act = Instance.new("Script"); act.Name = "PortoActivities"; act.Parent = PP end
act.RunContext = Enum.RunContext.Server
act.Source = NEW.PortoActivities

local SG = workspace:FindFirstChild("SeaGlass")
if not SG then SG = Instance.new("Folder"); SG.Name = "SeaGlass"; SG.Parent = workspace end
if SG:GetAttribute("Count") == nil then SG:SetAttribute("Count", 8) end
if SG:GetAttribute("RespawnMin") == nil then SG:SetAttribute("RespawnMin", 45) end
if SG:GetAttribute("RespawnMax") == nil then SG:SetAttribute("RespawnMax", 90) end
if SG:GetAttribute("BoxMin") == nil then SG:SetAttribute("BoxMin", Vector3.new(388, -60, -1095)) end
if SG:GetAttribute("BoxMax") == nil then SG:SetAttribute("BoxMax", Vector3.new(445, -40, -1046)) end
if not SG:FindFirstChild("Pieces") then local f = Instance.new("Folder"); f.Name = "Pieces"; f.Parent = SG end
if not SG:FindFirstChild("SeaGlassEvent") then local e = Instance.new("RemoteEvent"); e.Name = "SeaGlassEvent"; e.Parent = SG end
module(SG, "Recipes", NEW.Recipes)
local sv = SG:FindFirstChild("SeaGlassServer")
if not sv then sv = Instance.new("Script"); sv.Name = "SeaGlassServer"; sv.Parent = SG end
sv.RunContext = Enum.RunContext.Server; sv.Source = NEW.SeaGlassServer
local cl = SG:FindFirstChild("SeaGlassClient")
if not cl then cl = Instance.new("Script"); cl.Name = "SeaGlassClient"; cl.Parent = SG end
cl.RunContext = Enum.RunContext.Client; cl.Source = NEW.SeaGlassClient

print(string.format("QQ ITA DONE: Catalogue %d, Journal %d, PassportVisuals %d, PassportClient %d chars; PolpoServer stamps porto_polpo; RS.PortoAreas, workspace.PortoPassport.PortoActivities, workspace.SeaGlass {SeaGlassServer, SeaGlassClient, Recipes, SeaGlassEvent, Pieces}; backups ServerStorage.HudBackup.*_pre_italy",
	#out[Cat], #out[Jr], #out[Vis], #out[Cl]))
