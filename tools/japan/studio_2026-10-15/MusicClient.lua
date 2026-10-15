-- MapMusic (client): plays the track belonging to whichever section the player is standing in.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local folder = script.Parent

-- Which section you are standing in, or nil for one of the two crossings. The spans are read live so they can be
-- nudged from the Properties panel without a rebuild. They are bands in x rather than the footprints of the bridge
-- and the garden themselves, so that once the boundary opens clear across, crossing anywhere along a divide is
-- still a quiet moment rather than a hard cut.
-- Porto's three areas (Oct 8 2026), on the same lines as the Porto gates (workspace.PortoGates HarbourLine / GrovesPolygon)
local function parsePoly(s)
	local t = {}
	for x, z in string.gmatch(s or "", "([%-%d%.]+),([%-%d%.]+)") do table.insert(t, Vector2.new(tonumber(x), tonumber(z))) end
	return t
end
local function inside(poly, p)
	local c, j = false, #poly
	for i = 1, #poly do
		local a, b = poly[i], poly[j]
		if ((a.Y > p.Y) ~= (b.Y > p.Y)) and (p.X < (b.X - a.X) * (p.Y - a.Y) / (b.Y - a.Y) + a.X) then c = not c end
		j = i
	end
	return c
end
local harbourPoly, grovesPoly, grottaPoly, grottaQuietPoly
local function portoArea(pos)
	local pg = workspace:FindFirstChild("PortoGates")
	if not pg then return "porto" end
	if not harbourPoly then
		harbourPoly = parsePoly(pg:GetAttribute("HarbourLine"))
		table.insert(harbourPoly, Vector2.new(-300, -500)) table.insert(harbourPoly, Vector2.new(-300, -1330))
		grovesPoly = parsePoly(pg:GetAttribute("GrovesPolygon"))
		grottaPoly = parsePoly(folder:GetAttribute("GrottaPolygon"))             -- (Oct 8) the Grotta Azzurra: its own echoing track
		grottaQuietPoly = parsePoly(folder:GetAttribute("GrottaQuietPolygon"))   -- the path down to it from the steps: quiet
	end
	-- a quiet band at each crossing (Shannon: "a small area such as the first half of the flight of steps ... where no music
	-- is playing"): within PortoQuietRadius of a gate, the music fades out and the next area's starts as you step on
	local qr = folder:GetAttribute("PortoQuietRadius") or 9
	local gates = pg:FindFirstChild("Gates")
	if gates then
		for _, g in ipairs(gates:GetChildren()) do
			local blk = g:FindFirstChild("Block")
			if blk and (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(blk.Position.X, 0, blk.Position.Z)).Magnitude < qr and math.abs(pos.Y - blk.Position.Y) < 20 then return nil end
		end
	end
	local q = Vector2.new(pos.X, pos.Z)
	if pos.Y < -20 then                                                       -- down at the waterline only (the town is above the cave)
		if #grottaPoly > 2 and inside(grottaPoly, q) then return player:GetAttribute("PolpoFight") and "porto_grotta_fight" or "porto_grotta" end   -- the adventure track while he is roused (PolpoClient sets the flag)
		if #grottaQuietPoly > 2 and inside(grottaQuietPoly, q) then return nil end
	end
	if #harbourPoly > 3 and inside(harbourPoly, q) then return "porto" end
	if #grovesPoly > 3 and inside(grovesPoly, q) then return "porto_groves" end
	return "porto_borgo"
end
local function areaAt(pos)
	-- Interior override: evaluated before the surrounding Japan districts.
	local teaFrame = folder:GetAttribute("JapanTeaHouseFrame")
	local teaHalfSize = folder:GetAttribute("JapanTeaHouseHalfSize")
	if player.UserId == 9611145467 and typeof(teaFrame) == "CFrame" and typeof(teaHalfSize) == "Vector3" then
		local p = teaFrame:PointToObjectSpace(pos)
		if math.abs(p.X) <= teaHalfSize.X and math.abs(p.Y) <= teaHalfSize.Y and math.abs(p.Z) <= teaHalfSize.Z then
			return "japan_teahouse"
		end
	end
	-- Unfinished Japan music follows the same account restriction as the private preview.
	local min = folder:GetAttribute("JapanPalaceMin") or Vector3.new(6215, -8, -196)
	local max = folder:GetAttribute("JapanPalaceMax") or Vector3.new(6550, 90, 119)
	if player.UserId == 9611145467
		and pos.X >= min.X and pos.X <= max.X
		and pos.Y >= min.Y and pos.Y <= max.Y
		and pos.Z >= min.Z and pos.Z <= max.Z then
		return "japan_palace"
	end
	local shopsMin = folder:GetAttribute("JapanShopsMin") or Vector3.new(5840, -8, -240)
	local shopsMax = folder:GetAttribute("JapanShopsMax") or Vector3.new(6215, 60, 130)
	if player.UserId == 9611145467
		and pos.X >= shopsMin.X and pos.X <= shopsMax.X
		and pos.Y >= shopsMin.Y and pos.Y <= shopsMax.Y
		and pos.Z >= shopsMin.Z and pos.Z <= shopsMax.Z then
		return "japan_shops"
	end
	local countryMin = folder:GetAttribute("JapanCountrysideMin") or Vector3.new(5200, -20, -800)
	local countryMax = folder:GetAttribute("JapanCountrysideMax") or Vector3.new(5840, 360, 170)
	local mountainsMin = folder:GetAttribute("JapanMountainsMin") or Vector3.new(5200, -20, -1290)
	local mountainsMax = folder:GetAttribute("JapanMountainsMax") or Vector3.new(6640, 360, -240)
	if player.UserId == 9611145467 then
		local inFields = pos.X >= countryMin.X and pos.X <= countryMax.X
			and pos.Y >= countryMin.Y and pos.Y <= countryMax.Y
			and pos.Z >= countryMin.Z and pos.Z <= countryMax.Z
		local inMountains = pos.X >= mountainsMin.X and pos.X <= mountainsMax.X
			and pos.Y >= mountainsMin.Y and pos.Y <= mountainsMax.Y
			and pos.Z >= mountainsMin.Z and pos.Z <= mountainsMax.Z
		if inFields or inMountains then return "japan_countryside" end
	end
	local x = pos.X
	if pos.Z < -540 then                               -- Porto Nocciola (Oct 4 2026): its own track from the dock on;
		if pos.Z < (folder:GetAttribute("PortoZ") or -594) then return portoArea(pos) end
		return nil                                      -- the arrival grass above the quay is a quiet band
	end
	local b0 = folder:GetAttribute("BridgeX0") or 141
	local b1 = folder:GetAttribute("BridgeX1") or 171
	local g0 = folder:GetAttribute("GardenX0") or 351
	local g1 = folder:GetAttribute("GardenX1") or 389
	if x < b0 then return "forest" end
	if x < b1 then return nil end                      -- on the bridge
	if x < g0 then return "village" end
	if x < g1 then return nil end                      -- in the vegetable garden
	return "domaine"
end

-- two players so a change can cross-fade; one is always "current" and the other is free
local function newSound(name)
	local s = Instance.new("Sound")
	s.Name = name; s.Looped = true; s.Volume = 0; s.SoundGroup = nil; s.Parent = SoundService
	return s
end
local a, b = newSound("MusicA"), newSound("MusicB")
local playing, spare = a, b
local current = false                                  -- the section playing; nil is a real value now (a crossing)
local mark = {}                                        -- where each section's track had got to when you left it

-- a section may list several tracks, "id1,id2" (Oct 8 2026): they play back to back and go round again
local lists, listAt = {}, {}
local function idFor(area)
	local v = folder:GetAttribute(area)
	if v and tostring(v):find(",", 1, true) then
		local t = {}
		for d in tostring(v):gmatch("%d+") do table.insert(t, d) end
		lists[area] = t
		local at = listAt[area] or 1
		if at > #t then at = 1 end
		listAt[area] = at
		return "rbxassetid://" .. t[at]
	end
	lists[area] = nil
	if (not v or v == "") and type(area) == "string" and area:sub(1, 6) == "porto_" then v = folder:GetAttribute("porto") end   -- no track of its own yet: the harbour's
	if not v or v == "" then return nil end
	v = tostring(v):match("%d+")
	return v and ("rbxassetid://" .. v) or nil
end

local fading = {}
local function fadeTo(sound, target, secs)
	if fading[sound] then fading[sound]:Cancel() end
	local tw = TweenService:Create(sound, TweenInfo.new(secs, Enum.EasingStyle.Sine), {Volume = target})
	fading[sound] = tw
	tw:Play()
	return tw
end

-- A crossing is silent, so stepping onto one fades the music out and stepping off starts the next straight away.
-- The generation number is what keeps a turn-back honest: walk onto the bridge and turn round, and the delayed
-- Stop belonging to that first step must not cut the piece we have just lifted back up.
local gen = 0
local function switchTo(area)
	if area == current then return end
	current = area
	gen += 1
	local mine = gen
	local vol = (area and (folder:GetAttribute("Volume_" .. area) or (area:sub(1, 6) == "porto_" and folder:GetAttribute("Volume_porto") or nil))) or folder:GetAttribute("Volume") or 0.35   -- per-area level (Porto is ambient)
	local fade = folder:GetAttribute("Fade") or 0.8
	local id = area and idFor(area)

	if id and playing.SoundId == id and playing.IsPlaying then
		fadeTo(playing, vol, fade)                     -- stepped back off a crossing the way you came
		return
	end

	local out = playing
	if out.IsPlaying then
		-- remember where this section had got to, so coming back resumes the piece instead of restarting it
		if out.SoundId ~= "" then mark[out.SoundId] = out.TimePosition end
		fadeTo(out, 0, fade)
		task.delay(fade + 0.05, function()
			if gen == mine and out.Volume <= 0.001 then out:Stop() end
		end)
	end
	if not id then return end                          -- a crossing, or a section with no track set: stay quiet

	local into = (out == a) and b or a
	into.Looped = not (lists[area] and #lists[area] > 1)       -- a list moves on when a track ends
	into.SoundId = id
	into.Volume = 0
	into:Play()
	into.TimePosition = (area == "race") and 0 or (mark[id] or 0)   -- a race always starts its music from the top
	fadeTo(into, vol, fade)
	playing, spare = into, out
end

-- the next track of a list when the current one ends
for _, snd in ipairs({a, b}) do
	snd.Ended:Connect(function()
		if snd ~= playing or not current then return end
		local list = lists[current]
		if not list or #list < 2 then return end
		listAt[current] = (listAt[current] or 1) % #list + 1
		local nid = idFor(current)
		mark[nid] = 0
		snd.SoundId = nid
		snd.TimePosition = 0
		snd:Play()
	end)
end
local function onZipDeck(pos)
	local Z = workspace:FindFirstChild("Zipline")
	if not Z then return false end
	local dx, dz = pos.X - (Z:GetAttribute("DeckX") or 1e9), pos.Z - (Z:GetAttribute("DeckZ") or 1e9)
	return dx * dx + dz * dz < 10.5 * 10.5 and pos.Y > (Z:GetAttribute("LandDeckY") or 1e9) - 2.5
end
-- follow the player from section to section
task.spawn(function()
	while true do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then if char:GetAttribute("Riding") or char:GetAttribute("NoMusic") or char:GetAttribute("InBookshop") or char:GetAttribute("InChapel") or onZipDeck(root.Position) then switchTo(nil) elseif player:GetAttribute("Climbing") and idFor("climb") then switchTo("climb")   -- the Sandstone Climb has its own music while its clock runs (Shannon picked APM's Sunny Skies)
			elseif player:GetAttribute("Racing") and idFor("race") then switchTo("race") else switchTo(areaAt(root.Position)) end end   -- no music on the zipline or on its landing platform; the Forest Race has its own track
		task.wait(0.15)                                -- once a second put the change up to a second behind the foot
	end
end)

-- editing an attribute in Studio takes effect straight away, so tracks can be auditioned in place
for _, key in ipairs({"forest", "village", "domaine", "race", "climb", "porto", "japan_palace", "japan_shops", "japan_countryside", "japan_teahouse"}) do
	folder:GetAttributeChangedSignal(key):Connect(function()
		if current == key then local was = current; current = false; switchTo(was) end
	end)
end
folder:GetAttributeChangedSignal("Volume"):Connect(function()
	if playing.IsPlaying then fadeTo(playing, folder:GetAttribute("Volume") or 0.35, 0.4) end
end)

-- a per-area level (Volume_<area>) can be nudged live too
folder.AttributeChanged:Connect(function(n)
	if current and n == "Volume_" .. tostring(current) and playing.IsPlaying then fadeTo(playing, folder:GetAttribute(n) or folder:GetAttribute("Volume") or 0.35, 0.4) end
end)
