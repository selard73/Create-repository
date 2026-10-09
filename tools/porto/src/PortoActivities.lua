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
