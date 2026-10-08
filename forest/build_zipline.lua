-- Zipline: the wire from the forest tower out to a landing at the far end of the farm, the platform that
-- catches you, and THE RIDE - a trolley over the wire with a bar you hold on either side, bought once in the
-- Acorn Store (Item_ziphandle) and yours to keep.
--
-- The route was chosen by measurement, not by eye. The line runs DIAGONALLY over the town - Shannon: "crosswise
-- over the map, not just down one side" - to a landing at 675,-120, which puts the wire five studs off the
-- village's centre line. A straight wire has to pass over everything between: the boundary walls do not count
-- (invisible, and off for anyone who has unlocked the farm), the village rooftops at 33-37 do, and the tightest
-- point is a roof trim near x 612 in the farm, where the wire is lowest. THE RIDER HANGS 8.7 STUDS BELOW THE
-- WIRE (5.7 to the root, three more to the feet), so "the wire clears it" is not enough - the landing deck is
-- 18 high so the feet clear that trim by about four studs. A landing straight through the centre at deck 12
-- measured minus one.
--
-- HOW THE RIDE WORKS. The rider's own client moves the character: a client owns its character's physics, so a
-- CFrame it sets every frame is what everyone else sees, smoothly, with no server round trip in the loop. The
-- SERVER decides whether the ride may start - do you own a handle, is the farm open to you, are you actually up
-- at the top - builds the handle welded to the character so everybody sees it (sparkles and sound included),
-- raises the arms and bends the knees, and takes it all back at the far end. Nothing here touches the DataStore.
--
-- LETTING GO: jump during the ride and you drop off the wire where you are (the client ends the ride, gives a hop and
-- some of the ride's speed, and tells the server "done" so the handle and the pose go back).
-- Tunable in Properties on workspace.Zipline: Speed (studs/s along the wire), RideSoundId, RideVolume.
-- Re-runnable: it rebuilds the landing, the wire, the station and both scripts from scratch each time.
-- Needs the tower built first (it ties to ForestTower.ZipAnchor and reads its DeckY).
-- Run in edit mode: require(workspace.Zipline.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local NAME = opts.name or "Zipline"                -- the return line is "ZiplineBack"
	local REMOTE = opts.remote or "ZipRide"
	local T = workspace:FindFirstChild(opts.fromTower or "ForestTower")
	assert(T, "Zipline: build the tower first")
	local SIDE_OF = T:GetAttribute("AnchorSide") or 1
	local cx, cz = T:GetAttribute("Centre"):match("([^,]+),([^,]+)")
	cx, cz = tonumber(cx), tonumber(cz)
	local deckY0 = T:GetAttribute("DeckY")
	assert(deckY0, "Zipline: this tower predates the hand-height anchor; rebuild it first")
	-- THE WIRE STARTS AT THE ANCHOR, wherever the anchor actually is. This was a hardcoded 6.9 studs out,
	-- measured when the tower was fifteen wide; slimming it to nine and a half moved the anchor inwards and
	-- left the wire beginning in mid-air a stud short of the block it is supposed to be tied to.
	local block = T:FindFirstChild("ZipAnchor")
	assert(block, "Zipline: the tower has no ZipAnchor to tie to")
	local launch = Vector3.new(block.Position.X + SIDE_OF * (block.Size.X / 2 - 0.15), block.Position.Y, block.Position.Z)

	local LAND_X = opts.landX or 675
	local LAND_Z = opts.landZ or -120
	local DECK = opts.deck or 18                          -- how high the landing platform stands (see the header)

	local rng = Random.new(opts.seed or 5150)
	local WOOD  = {Color3.fromRGB(104, 72, 44), Color3.fromRGB(118, 84, 52), Color3.fromRGB(92, 62, 38)}
	local PLANK = {Color3.fromRGB(146, 108, 66), Color3.fromRGB(132, 96, 58), Color3.fromRGB(158, 119, 74)}
	local CREAM = Color3.fromRGB(255, 246, 220)

	-- the true floor: the lowest surface in the column, never the first thing a ray from the sky meets
	local function groundAt(x, z)
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
		local skip, y, probe = {}, nil, Vector3.new(x, 300, z)
		for pass = 1, 14 do
			rp.FilterDescendantsInstances = skip
			local h = workspace:Raycast(probe, Vector3.new(0, -500, 0), rp)
			if not h then break end
			y = h.Position.Y
			table.insert(skip, h.Instance)
			probe = Vector3.new(x, h.Position.Y - 0.1, z)
		end
		return y or 0
	end

	local old = workspace:FindFirstChild(NAME); if old then old:Destroy() end
	local Z = Instance.new("Model"); Z.Name = NAME

	local function wood(name, size, cf, palette, parent)
		local p = Instance.new("Part")
		p.Name = name; p.Size = size; p.CFrame = cf
		if typeof(palette) == "Color3" then palette = {palette} end
		p.Color = palette[rng:NextInteger(1, #palette)]
		p.Material = Enum.Material.Wood
		p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = parent or Z
		return p
	end

	-- ---------------------------------------------------------------- the landing ----
	local land, deckY, stop, span, dir
	local landTower = opts.landOnTower and workspace:FindFirstChild(opts.landOnTower)
	if landTower then
		-- LAND ON A TOWER'S TOP DECK (the return line comes home to the forest lookout). Its decks are open, rail-free, on
		-- the anchor side; the line arrives there 1.6 studs north of the ridge line, where the roof's underside is 10.5
		-- above the boards and the trolley on a wire tied 9.2 up clears it. The stop sits well over the deck.
		local tcx, tcz = landTower:GetAttribute("Centre"):match("([^,]+),([^,]+)")
		tcx, tcz = tonumber(tcx), tonumber(tcz)
		deckY = landTower:GetAttribute("DeckY")
		local tside = landTower:GetAttribute("AnchorSide") or 1
		local ANCHOR_UP = 9.2
		local mastX, mastZ = tcx + tside * 0.6, tcz - 1.6              -- the stop lands 2.8 back along the wire: two studs inside the deck's edge
		wood("Mast", Vector3.new(0.7, ANCHOR_UP + 1.0, 0.7), CFrame.new(mastX, deckY + (ANCHOR_UP + 1.0) / 2 - 0.2, mastZ), WOOD)
		land = Vector3.new(mastX + tside * 0.45, deckY + ANCHOR_UP, mastZ)
		LAND_X, LAND_Z = tcx, tcz
	else
	local gy = groundAt(LAND_X, LAND_Z)
	deckY = gy + DECK
	local SIDE = 13

	-- THE LANDING FACES THE WIRE. The line comes in on a diagonal, so the platform is built in a frame whose +X
	-- runs along the direction of travel: the open side is the side you arrive from, the mast stands ahead of
	-- the stopping point, and the ramp leaves to the right. Nothing here knows which way is east.
	local fwd = Vector3.new(LAND_X - launch.X, 0, LAND_Z - launch.Z).Unit
	local L = CFrame.fromMatrix(Vector3.new(LAND_X, deckY, LAND_Z), fwd, Vector3.yAxis, fwd:Cross(Vector3.yAxis))
	local function at(dx, dy, dz) return L * CFrame.new(dx, dy, dz) end

	-- four legs, each on its own ground
	for _, c in ipairs({{-1, -1}, {1, -1}, {1, 1}, {-1, 1}}) do
		local foot = at(c[1] * (SIDE / 2 - 0.7), 0, c[2] * (SIDE / 2 - 0.7)).Position
		local g = groundAt(foot.X, foot.Z)
		local len = deckY - g + 1
		wood("Leg", Vector3.new(0.85, len, 0.85), CFrame.new(foot.X, g - 0.5 + len / 2, foot.Z) * L.Rotation, WOOD)
		wood("Footing", Vector3.new(1.75, 0.9, 1.75), CFrame.new(foot.X, g + 0.2, foot.Z) * L.Rotation,
			{Color3.fromRGB(128, 124, 118)})
	end
	wood("Deck", Vector3.new(SIDE, 0.55, SIDE), L, PLANK)

	-- RAILS: full along the far side and the left; on the steps side and the arrival side they run in from
	-- each corner to a post and stop, leaving the middle open, because the middle is where those edges are
	-- used - the flight meets the deck there, and the wire brings you in over the other with your feet half a
	-- stud above the boards, so a rail straight across it would be a rail you pass through. The first version
	-- had this backwards: it fenced off the stairs and left the landing edge bare.
	local function rails(side, gap)
		local segs = gap and {{-SIDE / 2, -gap}, {gap, SIDE / 2}} or {{-SIDE / 2, SIDE / 2}}
		for _, seg in ipairs(segs) do
			local a, b = seg[1], seg[2]
			local mid, len = (a + b) / 2, b - a
			local function spot(u, y) return side[1] == 0 and at(u, y, side[2] * SIDE / 2) or at(side[1] * SIDE / 2, y, u) end
			for _, ry in ipairs({1.0, 2.0}) do
				local size = side[1] == 0 and Vector3.new(len + 0.22, 0.18, 0.22) or Vector3.new(0.22, 0.18, len + 0.22)
				wood("Rail", size, spot(mid, ry), WOOD)
			end
			for _, u in ipairs({a, mid, b}) do
				wood("Baluster", Vector3.new(0.22, 2.3, 0.22), spot(u, 1.15), WOOD)
			end
		end
	end
	rails({0, -1}, nil)               -- the left-hand side, full
	rails({1, 0}, nil)                -- the far side, beyond the mast, full
	rails({0, 1}, 2.6)                -- the steps side: open where the flight meets the deck
	rails({-1, 0}, 2.6)               -- the arrival side: open where the wire brings you in

	-- STEPS down to the ground, not a ramp: a 35-degree plank was a slide, and the deck should be reachable
	-- from below as well, for anyone who walks over to see what it is. A straight flight off the right-hand
	-- side, the tower's tread and rise, with a stringer under each edge. The top tread's face is one rise
	-- below the deck top and the bottom tread's is one rise above the ground, so both ends are a step.
	local STEPS = math.ceil(DECK / 0.65)
	local rise = DECK / STEPS
	local run = 0.78
	local WIDTH = 4.4
	for i = 1, STEPS do
		wood("Step", Vector3.new(WIDTH, 0.35, run + 0.12),
			at(0, 0.275 - rise * i - 0.175, SIDE / 2 + run * (i - 0.5)), PLANK)
	end
	local flightLen = math.sqrt(DECK ^ 2 + (run * STEPS) ^ 2)
	local flightTilt = math.atan2(DECK, run * STEPS)
	for _, sx in ipairs({-1, 1}) do
		wood("Stringer", Vector3.new(0.3, 0.55, flightLen),
			at(sx * (WIDTH / 2 + 0.15), 0.275 - DECK / 2 - 0.45, SIDE / 2 + run * STEPS / 2) * CFrame.Angles(flightTilt, 0, 0), WOOD)
	end

	-- THE MAST IS TALL AND WELL ONTO THE DECK. The rider arrives hanging about 5.7 studs below the wire and the
	-- ride stops a few studs short of the post, so the wire has to be a full handle-plus-arm above the boards
	-- there, and the stopping point has to be over the deck rather than over its edge. The old mast was 6.5
	-- high and a stud in from the edge: a rider set down from that would have been standing in the boards, or
	-- beside them, in mid-air.
	local ANCHOR_UP = 9.2
	local mastH = ANCHOR_UP + 1.3
	wood("Mast", Vector3.new(0.9, mastH, 0.9), at(-SIDE / 2 + 5.0, -0.5 + mastH / 2, 0), WOOD)
	land = at(-SIDE / 2 + 5.0 - 0.45, ANCHOR_UP, 0).Position
	end

	-- ---------------------------------------------------------------- the wire ----
	-- One long thin cylinder from anchor to anchor. A cylinder's length runs along its X axis, so it is built
	-- pointing down the line and then turned a quarter turn to lie along it.
	span = (land - launch).Magnitude
	dir = (land - launch).Unit
	local wire = Instance.new("Part")
	wire.Name = "Wire"
	wire.Shape = Enum.PartType.Cylinder
	wire.Size = Vector3.new(span, 0.28, 0.28)
	wire.Color = Color3.fromRGB(58, 56, 60)
	wire.Material = Enum.Material.Metal
	wire.Anchored = true; wire.CanCollide = false; wire.CanTouch = false; wire.CanQuery = false
	wire.CFrame = CFrame.lookAt((launch + land) / 2, land) * CFrame.Angles(0, math.rad(90), 0)
	wire.Parent = Z

	-- the block the trolley runs up against; the ride ends here, over the deck, and the rider is set down
	stop = land - dir * 2.8
	local stopper = Instance.new("Part")
	stopper.Name = "Stopper"; stopper.Size = Vector3.new(0.6, 0.7, 0.55)
	stopper.Color = Color3.fromRGB(38, 36, 40); stopper.Material = Enum.Material.SmoothPlastic
	stopper.Anchored = true; stopper.CanCollide = false; stopper.CanTouch = false; stopper.CanQuery = false
	stopper.CFrame = CFrame.lookAt(stop, land)
	stopper.Parent = Z

	-- ---------------------------------------------------------------- the station ----
	-- Where the ride starts: a post on the top deck beside the anchor, with the prompt on it. The prompt lives
	-- on a post at chest height rather than on the anchor nearly nine studs up, so its label floats just over
	-- your head instead of somewhere under the roof, and it never sits across the view you climbed up for.
	local postX, postZ = cx + SIDE_OF * 3.9, cz - 2.4
	local post = wood("StationPost", Vector3.new(0.5, 4.2, 0.5), CFrame.new(postX, deckY0 + 2.375, postZ), WOOD)
	local sign = wood("StationSign", Vector3.new(0.14, 0.8, 2.0), CFrame.new(postX - SIDE_OF * 0.32, deckY0 + 3.9, postZ), PLANK)
	local sg = Instance.new("SurfaceGui"); sg.Face = SIDE_OF == 1 and Enum.NormalId.Left or Enum.NormalId.Right
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 50; sg.Parent = sign
	local tl = Instance.new("TextLabel"); tl.Size = UDim2.fromScale(1, 1); tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.FredokaOne; tl.TextScaled = true; tl.TextColor3 = CREAM; tl.Text = opts.signText or "ZIPLINE"; tl.Parent = sg
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RidePrompt"; prompt.ActionText = opts.action or "Ride the zipline"; prompt.ObjectText = opts.objectText or "Zipline"
	prompt.HoldDuration = 0.35                          -- a short hold, so a stray tap does not launch you
	prompt.MaxActivationDistance = 8; prompt.RequiresLineOfSight = false
	prompt.Parent = post

	-- ---------------------------------------------------------------- the plumbing ----
	-- Made here, in edit mode, so they exist in the saved place before either script goes looking for them.
	local ride = RS:FindFirstChild(REMOTE)
	if not ride then ride = Instance.new("RemoteEvent"); ride.Name = REMOTE; ride.Parent = RS end
	local dbg = Instance.new("BindableEvent"); dbg.Name = "ZipDebugStart"; dbg.Parent = Z   -- server-only test hook

	Z:SetAttribute("LaunchX", launch.X); Z:SetAttribute("LaunchY", launch.Y); Z:SetAttribute("LaunchZ", launch.Z)
	Z:SetAttribute("LandX", land.X); Z:SetAttribute("LandY", land.Y); Z:SetAttribute("LandZ", land.Z)
	Z:SetAttribute("StopX", stop.X); Z:SetAttribute("StopY", stop.Y); Z:SetAttribute("StopZ", stop.Z)
	Z:SetAttribute("Span", span)
	Z:SetAttribute("DeckY", deckY0)                     -- the top of the tower, where the ride begins
	Z:SetAttribute("LandDeckY", deckY)
	Z:SetAttribute("DeckX", LAND_X); Z:SetAttribute("DeckZ", LAND_Z)   -- the music client keeps quiet up here
	-- the ride's feel, in Properties rather than in code: fast enough not to be dull, slow enough to look at
	-- the map going by. RideSoundId 0 means no sound.
	Z:SetAttribute("Speed", opts.speed or 48)
	Z:SetAttribute("RideSoundId", opts.sound or 137868028905774)   -- the whirr Shannon chose
	Z:SetAttribute("RideVolume", opts.volume or 0.7)

	-- ---------------------------------------------------------------- the ride: server ----
	local SERVER = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local Z = script.Parent
local ride = RS:WaitForChild("ZipRide")

local function at(name)
	return Vector3.new(Z:GetAttribute(name .. "X"), Z:GetAttribute(name .. "Y"), Z:GetAttribute(name .. "Z"))
end
local function need()
	local B
	for _, b in ipairs(workspace:GetChildren()) do
		if b.Name == "Boundary" and b:FindFirstChild("Walls") then B = b end
	end
	return (B and B:GetAttribute("Need")) or 10
end

local riding = {}                                     -- player -> {char, handle, c0}

-- THE POSE IN NUMBERS: arms straight up and a touch forward, a little apart; thighs swung forward and knees
-- bent, the way legs hang from a zipline handle. The handle builder uses the arm turn to find the hands.
local ARM_UP, ARM_OUT, HIP, KNEE = math.rad(175), math.rad(6), math.rad(24), math.rad(-42)
local function armTurn(out, up, spread) return CFrame.Angles(0, 0, (spread or ARM_OUT) * out) * CFrame.Angles(up or ARM_UP, 0, 0) end

-- Everything the ride changed goes back: the handle (sound and sparkles with it), the arms, the humanoid.
local function finish(player)
	local r = riding[player]; if not r then return end
	riding[player] = nil
	if r.handle and r.handle.Parent then r.handle:Destroy() end
	local char = r.char
	if char and char.Parent then
		for joint, c0 in pairs(r.c0) do if joint.Parent then joint.C0 = c0 end end
		for att, cf in pairs(r.att) do if att.Parent then att.CFrame = cf end end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		char:SetAttribute("Riding", nil)
	end
end

-- THE HANDLE IS BUILT TO FIT THIS CHARACTER: the grips go exactly where this rig's hands end up with the arms
-- raised, so a tall or a small avatar still holds the bar and hangs the right distance below the wire. Every
-- piece is welded to the root part and massless, so it rides along without touching the character's physics.
-- Returns the model, how far the wire sits above the root, and how far behind the wire the root hangs.
local function buildHandle(char, hrp)
	-- WHERE THE HANDS END UP, worked out from the rig itself rather than guessed from arm lengths. Each R15
	-- joint is a pair of RigAttachments, one on each part, that the joint holds together; so with the shoulder
	-- turned the way pose() turns it, the arm's rest-pose CFrames follow by multiplication - shoulder, elbow,
	-- wrist - down to the GripAttachment in the hand, which is exactly where a tool would sit. The first
	-- version estimated the reach from part sizes and put the bar at head height, a stud below the hands.
	local function att(part, name) local a = part and part:FindFirstChild(name); return a and a.CFrame end
	local lower, upper = char:FindFirstChild("LowerTorso"), char:FindFirstChild("UpperTorso")
	local rootA, rootB = att(hrp, "RootRigAttachment"), att(lower, "RootRigAttachment")
	local waistA, waistB = att(lower, "WaistRigAttachment"), att(upper, "WaistRigAttachment")
	local upperCF = (rootA and rootB and waistA and waistB) and (rootA * rootB:Inverse() * waistA * waistB:Inverse())
		or CFrame.new(0, 1.0, 0)
	local function gripOf(side, up, spread)
		local out = (side == "Left") and 1 or -1
		local turn = armTurn(out, up, spread)          -- the same turn pose() makes
		local ua, la, ha = char:FindFirstChild(side .. "UpperArm"), char:FindFirstChild(side .. "LowerArm"), char:FindFirstChild(side .. "Hand")
		local sA, sB = att(upper, side .. "ShoulderRigAttachment"), att(ua, side .. "ShoulderRigAttachment")
		local eA, eB = att(ua, side .. "ElbowRigAttachment"), att(la, side .. "ElbowRigAttachment")
		local wA, wB = att(la, side .. "WristRigAttachment"), att(ha, side .. "WristRigAttachment")
		if not (sA and sB and eA and eB and wA and wB) then return nil end
		local haCF = upperCF * (sA * turn) * sB:Inverse() * eA * eB:Inverse() * wA * wB:Inverse()
		return (haCF * (att(ha, side .. "GripAttachment") or CFrame.new())).Position     -- root-local
	end
	-- THE BAR GOES OVER THE HEAD. Shannon: "the handle is actually going through the top of the player's head" - a
	-- big-headed avatar's hands, arms straight up, only reach the top of its head. (Tipping the arms forward put the
	-- bar in front of the forehead, which from the usual camera behind still looked like it went through.) So the
	-- handle is a trapeze: a grip in each hand, a strap from each grip up to a crossbar that clears the head and
	-- whatever is worn on it, and the stem from there to the trolley. The arms spread wider when they must, so the
	-- straps pass beside the head. The wire point stays put, so the rider hangs as far below it as before - unless a
	-- tall hat needs the room.
	local head = char:FindFirstChild("Head")
	local headTop, headHalfW = nil, 0
	if head then
		local function top(p)                           -- the top of a part in the root's frame, turned or not
			local c = hrp.CFrame:ToObjectSpace(p.CFrame)
			local ext = math.abs(c.RightVector.Y) * p.Size.X / 2 + math.abs(c.UpVector.Y) * p.Size.Y / 2 + math.abs(c.LookVector.Y) * p.Size.Z / 2
			headTop = math.max(headTop or -math.huge, c.Y + ext)
			return c
		end
		local hc = top(head)
		headHalfW = math.abs(hc.X) + head.Size.X / 2
		-- HAIR AND HATS COUNT FOR THE HEIGHT. An accessory is worn on the head when its attachment has a twin on the
		-- head (HairAttachment, HatAttachment, FaceFrontAttachment...). The first version looked for a weld to the head,
		-- but this game's avatars hold their accessories another way, so it saw no hair at all and the bar went
		-- through Shannon's ponytail.
		for _, acc in ipairs(char:GetChildren()) do
			local h = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
			local a = h and h:FindFirstChildWhichIsA("Attachment")
			if a and head:FindFirstChild(a.Name) then top(h) end
		end
	end
	local up, spread, gL, gR = ARM_UP, ARM_OUT, nil, nil
	for deg = 6, 34, 4 do
		spread = math.rad(deg)
		gL, gR = gripOf("Left", up, spread), gripOf("Right", up, spread)
		if not (gL and gR and headTop) then break end
		if (math.abs(gL.X) + math.abs(gR.X)) / 2 - 0.3 >= headHalfW then break end    -- the hands, and the straps, beside the head
	end
	if not (gL and gR) then                           -- an unfamiliar rig: fall back to a plain estimate
		gL, gR = Vector3.new(-1, 3.9, -0.2), Vector3.new(1, 3.9, -0.2)
	end
	local barY = (gL.Y + gR.Y) / 2
	local barZ = (gL.Z + gR.Z) / 2
	local gripX = (math.abs(gL.X) + math.abs(gR.X)) / 2
	local BAR_DROP = 1.7                              -- wire point down to the grips, as it always was
	local crossY = math.max(barY + 0.3, (headTop or barY) + 0.45)         -- the crossbar, well over the head and the hair
	-- a hat too tall for the room under the trolley lifts the wire point (the rider hangs lower), by 0.6 at most so
	-- the rider still arrives over the landing deck and not in it
	local wireY = barY + BAR_DROP + math.clamp(crossY + 0.45 - (barY + BAR_DROP), 0, 0.6)
	crossY = math.min(crossY, wireY - 0.45)           -- and always under the trolley
	local drop, strap = wireY - crossY, crossY - barY  -- wire point down to the crossbar; crossbar down to the grips

	local M = Instance.new("Model"); M.Name = "ZipHandle"
	local function part(name, size, cf, color, material, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size
		p.CFrame = hrp.CFrame * cf
		p.Color = color; p.Material = material or Enum.Material.Metal
		if shape then p.Shape = shape end
		p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = M
		local w = Instance.new("WeldConstraint"); w.Part0 = hrp; w.Part1 = p; w.Parent = p
		return p
	end
	local STEEL, RUBBER, ORANGE = Color3.fromRGB(150, 150, 156), Color3.fromRGB(38, 36, 40), Color3.fromRGB(226, 120, 40)
	local W = CFrame.new(0, wireY, barZ)              -- the wire point, in the root part's frame
	-- the trolley: two cheeks either side of the wire, a cap over the top, two wheels riding on it
	part("Cheek", Vector3.new(0.14, 0.95, 1.7), W * CFrame.new(-0.32, 0.3, 0), STEEL)
	part("Cheek", Vector3.new(0.14, 0.95, 1.7), W * CFrame.new(0.32, 0.3, 0), STEEL)
	local cap = part("Cap", Vector3.new(0.78, 0.14, 1.7), W * CFrame.new(0, 0.86, 0), ORANGE, Enum.Material.SmoothPlastic)
	for _, dz in ipairs({-0.5, 0.5}) do
		part("Wheel", Vector3.new(0.5, 0.62, 0.62), W * CFrame.new(0, 0.45, dz), RUBBER, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	end
	-- the stem down to the crossbar, the crossbar over the head, a strap down each side, and a grip in each hand
	local stem = part("Stem", Vector3.new(0.16, drop - 0.15, 0.16), W * CFrame.new(0, -(drop + 0.15) / 2, 0), STEEL)
	part("Bar", Vector3.new(gripX * 2 + 0.3, 0.16, 0.16), W * CFrame.new(0, -drop, 0), STEEL)
	for _, sx in ipairs({-1, 1}) do
		part("Strap", Vector3.new(0.12, strap + 0.08, 0.12), W * CFrame.new(sx * gripX, -drop - strap / 2, 0), STEEL)
		part("Grip", Vector3.new(0.7, 0.3, 0.3), W * CFrame.new(sx * gripX, -BAR_DROP, 0), RUBBER, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	end

	-- SPARKLES where the wheels meet the wire - the same gold sparkle the acorns wear, so it reads as the
	-- game's own kind of magic and not as something on fire. They are left behind in the air as the trolley
	-- moves, which is what draws the trail.
	local spark = Instance.new("Attachment"); spark.Name = "Spark"
	spark.Position = Vector3.new(0, (drop - 0.15) / 2, 0)          -- the top of the stem: the wire point
	spark.Parent = stem
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 190), Color3.fromRGB(255, 200, 90))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.4, 0.36), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
	pe.Lifetime = NumberRange.new(0.5, 1.1); pe.Rate = 65; pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(70, 70); pe.Acceleration = Vector3.new(0, -5, 0); pe.Drag = 1.5
	pe.LightEmission = 0.9; pe.LightInfluence = 0; pe.Rotation = NumberRange.new(0, 360); pe.RotSpeed = NumberRange.new(-90, 90)
	pe.Parent = spark

	-- the sound of the wheels on the wire, from the trolley itself so everyone hears it go past
	local id = tonumber(Z:GetAttribute("RideSoundId")) or 0
	if id > 0 then
		local snd = Instance.new("Sound"); snd.Name = "Whirr"
		snd.SoundId = "rbxassetid://" .. id
		snd.Looped = true; snd.Volume = Z:GetAttribute("RideVolume") or 0.7
		snd.RollOffMode = Enum.RollOffMode.InverseTapered; snd.RollOffMinDistance = 10; snd.RollOffMaxDistance = 160
		snd.Parent = cap
		snd:Play()
	end

	M.Parent = char
	return M, wireY, -barZ, up, spread
end

-- THE POSE, done on the SERVER so everyone sees it: joint offsets changed on a client stay on that client.
-- The client's Animate script stops its animations the moment the humanoid platform-stands, so nothing
-- fights this.
-- TWO KINDS OF JOINT. Older rigs hang a limb on a Motor6D, which is posed by writing C0. Newer characters
-- (this game's included) hang it on an AnimationConstraint, whose C0 is READ-ONLY - the first version checked
-- for a Motor6D, found none, and quietly raised nothing, so riders hung by their hair. An AnimationConstraint
-- follows its two attachments, so the same turn goes onto the parent-side attachment and the limb follows it.
local function poseList(up, spread) return {
	{part = "LeftUpperArm",  joint = "LeftShoulder",  turn = armTurn(1, up, spread)},
	{part = "RightUpperArm", joint = "RightShoulder", turn = armTurn(-1, up, spread)},
	{part = "LeftUpperLeg",  joint = "LeftHip",       turn = CFrame.Angles(HIP, 0, 0)},
	{part = "RightUpperLeg", joint = "RightHip",      turn = CFrame.Angles(HIP, 0, 0)},
	{part = "LeftLowerLeg",  joint = "LeftKnee",      turn = CFrame.Angles(KNEE, 0, 0)},
	{part = "RightLowerLeg", joint = "RightKnee",     turn = CFrame.Angles(KNEE, 0, 0)},
} end
local function pose(char, r, up, spread)
	for _, p in ipairs(poseList(up, spread)) do
		local part = char:FindFirstChild(p.part)
		local joint = part and part:FindFirstChild(p.joint)
		if joint then
			if joint:IsA("Motor6D") then
				r.c0[joint] = joint.C0
				joint.C0 = joint.C0 * p.turn
			elseif joint:IsA("AnimationConstraint") and joint.Attachment0 then
				local att = joint.Attachment0
				r.att[att] = r.att[att] or att.CFrame
				att.CFrame = att.CFrame * p.turn
			else
				warn("ZipServer: " .. p.joint .. " is a " .. joint.ClassName .. "; cannot pose it")
			end
		end
	end
end

local function start(player)
	if riding[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 then return end
	if (player:GetAttribute("Item_ziphandle") or 0) <= 0 then
		ride:FireClient(player, "no", "You need a zipline handle. The Acorn Store has them.")
		return
	end
	if (player:GetAttribute("Found_village") or 0) < need() then
		ride:FireClient(player, "no", string.format("The farm is not open to you yet. Find %d in the Rue first.", need()))
		return
	end
	-- actually up there, not shouting from the deck below through the stairwell
	local launch = at("Launch")
	local flat = (hrp.Position - launch) * Vector3.new(1, 0, 1)
	if flat.Magnitude > 12 or math.abs(hrp.Position.Y - (Z:GetAttribute("DeckY") + 3)) > 4.5 then
		ride:FireClient(player, "no", "Climb to the top of the tower first.")
		return
	end
	local r = {char = char, c0 = {}, att = {}}
	riding[player] = r
	local handle, hang, back, up, spread = buildHandle(char, hrp)
	r.handle = handle
	pose(char, r, up, spread)
	hum.PlatformStand = true
	char:SetAttribute("Riding", true)                 -- the music client reads this and goes quiet
	ride:FireClient(player, "go", hang, back)
	-- if the client never reports in - crashed, lagged out, tampered - take it all back anyway
	local speed = Z:GetAttribute("Speed") or 44
	task.delay((Z:GetAttribute("Span") or 700) / speed + 14, function()
		if riding[player] == r then finish(player) end
	end)
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "RidePrompt" and prompt:IsDescendantOf(Z) then start(player) end
end)
ride.OnServerEvent:Connect(function(player, what)
	if what == "done" then finish(player) end
end)
Players.PlayerRemoving:Connect(finish)
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function() finish(player) end)
end)
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterRemoving:Connect(function() finish(player) end)
end
local dbg = Z:FindFirstChild("ZipDebugStart")
if dbg then dbg.Event:Connect(start) end
print("ZipServer: ready")
]==]

	-- ---------------------------------------------------------------- the ride: client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Z = script.Parent
local ride = RS:WaitForChild("ZipRide")
local C = Color3.fromRGB

local function at(name)
	return Vector3.new(Z:GetAttribute(name .. "X"), Z:GetAttribute(name .. "Y"), Z:GetAttribute(name .. "Z"))
end

-- a line at the foot of the screen, in the game's own colours, for "you need a handle"
local gui = Instance.new("ScreenGui"); gui.Name = "ZipNote"; gui.ResetOnSpawn = false; gui.DisplayOrder = 6
gui.Parent = player:WaitForChild("PlayerGui")
local note = Instance.new("TextLabel")
note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -72); note.Size = UDim2.fromOffset(460, 40)
note.BackgroundColor3 = C(38, 30, 52); note.BackgroundTransparency = 1; note.BorderSizePixel = 0
note.Font = Enum.Font.FredokaOne; note.TextSize = 18; note.TextColor3 = C(255, 246, 220); note.TextTransparency = 1
note.TextWrapped = true; note.Text = ""; note.Parent = gui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local ns = Instance.new("UIStroke"); ns.Color = C(240, 200, 90); ns.Thickness = 1.5; ns.Transparency = 1; ns.Parent = note
local shownAt = 0
local function say(text)
	note.Text = text
	note.BackgroundTransparency = 0.15; note.TextTransparency = 0; ns.Transparency = 0
	local mine = os.clock(); shownAt = mine
	task.delay(2.8, function()
		if shownAt ~= mine then return end
		local ti = TweenInfo.new(0.5)
		TweenService:Create(note, ti, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(ns, ti, {Transparency = 1}):Play()
	end)
end

local BIND = "ZipRide"
local bound = false
local function unbind()
	if bound then RunService:UnbindFromRenderStep(BIND); bound = false end
end

-- The ride. Moved just before the camera updates each frame, so the camera never sees the character a frame
-- behind where it is. Speed is integrated rather than looked up: pull away from the platform, run at Speed,
-- and brake against the stopper so you arrive at a walk rather than a crash.
local function go(hang, back)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end
	hum.PlatformStand = true
	local launch, stop = at("Launch"), at("Stop")
	local L = (stop - launch).Magnitude
	local dir = (stop - launch).Unit
	local flat = Vector3.new(dir.X, 0, dir.Z).Unit
	local V = Z:GetAttribute("Speed") or 44           -- studs/s along the wire
	local A, BRAKE, VEND = 16, 30, 6                  -- studs/s^2, and the speed you arrive at
	local s, vel = 0, 0
	local startCF = hrp.CFrame
	local GRAB = math.clamp(((hrp.Position - launch) * Vector3.new(1, 0, 1)).Magnitude / 12, 0.25, 0.9)
	local t0 = os.clock()
	local done = false
	-- LET GO: jump and you drop off the wire where you are, carrying on a little the way you were going. Shannon: "can
	-- you make the zip line so that the player can jump off mid trip if they want to?" JumpRequest is the jump key or
	-- the phone's jump button; the humanoid's Jump is watched too, in case one comes without the other. Not in the first
	-- half second, so the jump that got you up the last step does not throw you straight off.
	local letGo = false
	local function wantOff() if os.clock() - t0 > 0.5 then letGo = true end end
	local c1 = UIS.JumpRequest:Connect(wantOff)
	local c2 = hum:GetPropertyChangedSignal("Jump"):Connect(function() if hum.Jump then wantOff() end end)
	local function drop() c1:Disconnect(); c2:Disconnect() end
	unbind()
	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value - 1, function(dt)
		if done or not hrp.Parent or hum.Health <= 0 then unbind(); drop() return end
		if letGo then                                -- off the wire: a hop, and on the way you were going
			done = true
			unbind(); drop()
			hum.PlatformStand = false
			hrp.AssemblyLinearVelocity = flat * (vel * 0.6) + Vector3.new(0, 14, 0)
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
			ride:FireServer("done")                     -- the server takes the handle and the pose back
			return
		end
		local t = os.clock() - t0
		if t >= GRAB then
			local brakeV = math.sqrt(VEND * VEND + 2 * BRAKE * math.max(L - s, 0))
			vel = math.min(vel + A * dt, V, brakeV)
			s = math.min(s + vel * dt, L)
		end
		local P = launch + dir * s
		local target = CFrame.lookAt(P, P + flat) * CFrame.new(0, -hang, back)
		if t < GRAB then
			hrp.CFrame = startCF:Lerp(target, t / GRAB)
		else
			hrp.CFrame = target
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		if s >= L - 0.01 then
			done = true
			unbind(); drop()
			hum.PlatformStand = false
			ride:FireServer("done")
		end
	end)
	bound = true
	say("Jump any time to let go!")
end

ride.OnClientEvent:Connect(function(what, a, b)
	if what == "go" then go(a, b)
	elseif what == "no" then say(a) end
end)
]==]

	local s = Instance.new("Script"); s.Name = "ZipServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER:gsub('RS:WaitForChild%("ZipRide"%)', 'RS:WaitForChild("' .. REMOTE .. '")'); s.Parent = Z
	local c = Instance.new("Script"); c.Name = "ZipClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT:gsub('RS:WaitForChild%("ZipRide"%)', 'RS:WaitForChild("' .. REMOTE .. '")'):gsub('local BIND = "ZipRide"', 'local BIND = "' .. REMOTE .. '"'); c.Parent = Z
	Z.Parent = workspace

	local parts = 0
	for _, p in ipairs(Z:GetDescendants()) do if p:IsA("BasePart") then parts += 1 end end
	print(string.format("Zipline: %d parts | wire %.0f studs from %.1f,%.1f,%.1f down to %.1f,%.1f,%.1f (a drop of %.1f) | stops at %.1f,%.1f,%.1f, %.1f above the landing deck (deck %.0f high) | station post at %.1f,%.1f | %.0f studs/s",
		parts, span, launch.X, launch.Y, launch.Z, land.X, land.Y, land.Z, launch.Y - land.Y,
		stop.X, stop.Y, stop.Z, stop.Y - deckY, DECK, postX, postZ, Z:GetAttribute("Speed")))
	return Z
end
