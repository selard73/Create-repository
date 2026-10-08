-- MapMusic: each section of the map gets its own piece of music, and the crossings between them are SILENT.
-- The divides are places, not lines - the bridge over the river, and the vegetable garden between the Rue and the
-- estate. Step onto one and the music goes; step off the far side and the next section's music is already there.
-- The quiet therefore lasts exactly as long as the crossing takes, which is why there is no timer anywhere here:
-- a timed gap drifts out of step with where the player actually is, and that is what it felt like.
-- Everything is an ATTRIBUTE on workspace.MapMusic, so tuning it is editing a number, not shipping code:
--     workspace.MapMusic.forest / village / domaine   - the Roblox audio asset id for that section
--     workspace.MapMusic.Volume                       - how loud the music sits under everything else
--     workspace.MapMusic.Fade                         - seconds to fade out and back in; short, so it feels immediate
--     workspace.MapMusic.BridgeX0 / BridgeX1          - the silent span of the river bridge
--     workspace.MapMusic.GardenX0 / GardenX1          - the silent span of the vegetable garden
-- Run in edit mode: require(workspace.MusicPatch.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local F = workspace:FindFirstChild("MapMusic")
	if not F then F = Instance.new("Folder"); F.Name = "MapMusic"; F.Parent = workspace end

	-- only set a track if one was passed in, so re-running never clobbers Shannon's choices
	for _, id in ipairs({"forest", "village", "domaine", "race"}) do   -- race: the Forest Race's own track, while the clock runs
		if opts[id] then F:SetAttribute(id, tostring(opts[id])) end
		if F:GetAttribute(id) == nil then F:SetAttribute(id, "") end
	end
	if F:GetAttribute("Volume") == nil then F:SetAttribute("Volume", 0.28) end   -- was 0.35; "a little too loud"
	-- Fade is SET rather than defaulted: it was 2.5s to cross-fade over, and a crossing that opens with two and a
	-- half seconds of the old piece still playing cannot feel immediate. Gap is removed - the walk IS the gap.
	F:SetAttribute("Fade", opts.fade or 0.8)
	F:SetAttribute("Gap", nil)
	-- measured off the models themselves: bridge x 141..171, GardenPad x 351..389. The forest has a second bridge
	-- at x -161..-131, which these spans deliberately leave alone.
	F:SetAttribute("BridgeX0", opts.bridgeX0 or 141); F:SetAttribute("BridgeX1", opts.bridgeX1 or 171)
	F:SetAttribute("GardenX0", opts.gardenX0 or 351); F:SetAttribute("GardenX1", opts.gardenX1 or 389)

	local old = F:FindFirstChild("MusicClient"); if old then old:Destroy() end
	local CLIENT = [==[
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
local function areaAt(pos)
	local x = pos.X
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

local function idFor(area)
	local v = folder:GetAttribute(area)
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
	local vol = folder:GetAttribute("Volume") or 0.35
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
	into.SoundId = id
	into.Volume = 0
	into:Play()
	into.TimePosition = (area == "race") and 0 or (mark[id] or 0)   -- a race always starts its music from the top
	fadeTo(into, vol, fade)
	playing, spare = into, out
end

-- standing on the zipline's landing platform: inside its footprint and up at deck height (three treads down
-- the steps and you are out of it)
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
		if root then
			-- no music on the zipline: the ride has its own sound, and the ground it crosses would flip the
			-- track four times in twenty seconds. And none on the landing platform after it, until you have
			-- come down off it - Shannon: "the map music should not start again until you are off the zipline
			-- platform".
			if char:GetAttribute("Riding") or char:GetAttribute("InBookshop") or char:GetAttribute("InChapel") or onZipDeck(root.Position) then switchTo(nil)   -- inside the Librairie and the chapel they play their own music
			elseif player:GetAttribute("Racing") and idFor("race") then switchTo("race")   -- the Forest Race has its own music (Shannon: "a different music sound track than the regular forest soundtrack")
			else switchTo(areaAt(root.Position)) end
		end
		task.wait(0.15)                                -- once a second put the change up to a second behind the foot
	end
end)

-- editing an attribute in Studio takes effect straight away, so tracks can be auditioned in place
for _, key in ipairs({"forest", "village", "domaine", "race"}) do
	folder:GetAttributeChangedSignal(key):Connect(function()
		if current == key then local was = current; current = false; switchTo(was) end
	end)
end
folder:GetAttributeChangedSignal("Volume"):Connect(function()
	if playing.IsPlaying then fadeTo(playing, folder:GetAttribute("Volume") or 0.35, 0.4) end
end)
]==]
	local s = Instance.new("Script"); s.Name = "MusicClient"; s.RunContext = Enum.RunContext.Client; s.Source = CLIENT; s.Parent = F
	print(string.format("MapMusic: ready - forest=%s village=%s domaine=%s (vol %.2f, %.1fs fade; quiet on the bridge x%d..%d and the garden x%d..%d)",
		tostring(F:GetAttribute("forest")), tostring(F:GetAttribute("village")), tostring(F:GetAttribute("domaine")),
		F:GetAttribute("Volume"), F:GetAttribute("Fade"),
		F:GetAttribute("BridgeX0"), F:GetAttribute("BridgeX1"), F:GetAttribute("GardenX0"), F:GetAttribute("GardenX1")))
end
