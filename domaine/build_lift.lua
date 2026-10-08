-- BasketLift: the way down from the top of the Sandstone Climb for anybody without a hang glider. Shannon (Sep 27 2026):
-- "we need a practical way to get down the mountain if you have not bought the hang glider yet" - and of a basket lift,
-- a door in the rock or a slide: "choice 1, the basket please".
--
-- A wooden hoist on the summit's front edge, between the glider's ramp and the top of trellis B: two posts with a
-- headframe reaching out over the drop, a pulley at its end, a hand winch on the east post and a BASKET LIFT board on
-- top - and a wicker basket hanging from the pulley with its floor level with the terrace. "Ride down": you hop into the
-- basket, it lowers you down the cliff face to the foot (RideSeconds) and you hop out over the garden wall onto the start
-- stone; the empty basket winds itself back up (ReturnSeconds). Free, and down only - the climb still has to be climbed.
-- There is one basket: while it is out, the prompt waits for it.
--
-- HOW IT MOVES (the hang glider's way): the rider's own client moves the rider (a client owns its character's physics, so
-- what it sets every frame is what everyone sees) and the SERVER welds the basket to the rider for the ride, so it goes
-- down smoothly on every screen; at the foot the server unhooks it (anchored), and the trip back up is drawn by every
-- client from the two poses the server gives it (as the gliders left behind are).
-- Nothing here touches the DataStore. Run in edit mode (re-runnable). It also clears the foot props (a big rock) that
-- stood where the basket comes down; build_cliff.lua would put them back, so run this again after rebuilding the climb.
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local C = Color3.fromRGB
	local CL = workspace:FindFirstChild("SandstoneClimb")
	assert(CL, "BasketLift: build the Sandstone Climb first")
	local sumY = CL:GetAttribute("SummitY")
	assert(sumY, "BasketLift: the climb has no SummitY")
	local stone = CL:FindFirstChild("StartStone", true)
	assert(stone, "BasketLift: the climb has no start stone")
	local old = workspace:FindFirstChild("BasketLift"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "BasketLift"

	-- where: the basket's middle, clear of the ramp's rail (x 487.7 at the edge) and trellis B (x 495.5 and up) all the way
	-- down (probe_lift.lua, Sep 27: nothing in the way but a big rock at the foot)
	local X, Z = opts.x or 492, opts.z or -249.9
	local EDGE = opts.edgeZ or -253.1                            -- the posts, on the terrace's front edge
	local OUT = Vector3.new(0, 0, 1)                             -- away from the cliff, over the valley
	local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {workspace.Terrain}
	local function ground(x, z) local h = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -400, 0), rpT); return h and h.Position.Y or 4.5 end
	local foot = ground(X, Z)
	local FLOOR = 0.3                                            -- the basket floor's thickness
	local REST = CFrame.new(X, sumY, Z)                          -- the basket's pivot (its floor's top middle) at the top
	local DROP = sumY - (foot + FLOOR)                           -- how far it goes down

	local WOOD, DARK, STRAW, WEAVE, ROPE = C(118, 84, 52), C(84, 58, 36), C(214, 178, 112), C(176, 134, 74), C(214, 196, 150)
	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.Wood; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent
		return p
	end
	local function soft(p) p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; return p end
	local function beam(name, a, b, thick, colour, material, parent, round)          -- a part from point a to point b
		local len = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		if round then
			return part(name, Vector3.new(len, thick, thick), cf * CFrame.Angles(0, math.rad(90), 0), colour, material, parent, Enum.PartType.Cylinder)
		end
		return part(name, Vector3.new(thick, thick, len), cf, colour, material, parent)
	end

	-- ---------------------------------------------------------------- the foot: room for the basket ----
	local removed = 0
	local KIT = {rock_big = true, rock_cluster = true, bush_big = true, bush_small = true, boxwood = true, oleander = true}
	for _, m in ipairs(CL:GetDescendants()) do
		if m:IsA("Model") and m.Parent and KIT[m.Name] then
			local cf, size = m:GetBoundingBox()
			if cf.Y < foot + 6 and math.abs(cf.X - X) < 2.4 + size.X / 2 and math.abs(cf.Z - Z) < 2.3 + size.Z / 2 then m:Destroy(); removed += 1 end
		end
	end

	-- ---------------------------------------------------------------- the hoist ----
	local hoist = Instance.new("Model"); hoist.Name = "Hoist"; hoist.Parent = F
	local PX, TOPY = 2.2, sumY + 8.9                             -- the posts either side of the basket; the headframe's height
	for _, s in ipairs({-1, 1}) do
		part("Post", Vector3.new(0.7, TOPY - sumY + 0.9, 0.7), CFrame.new(X + s * PX, (sumY - 0.6 + TOPY + 0.3) / 2, EDGE), WOOD, Enum.Material.Wood, hoist)
		beam("Jib", Vector3.new(X + s * PX, TOPY, EDGE - 0.35), Vector3.new(X + s * PX, TOPY, Z + 0.7), 0.55, WOOD, Enum.Material.Wood, hoist)
		-- a knee brace under each jib (no struts back onto the terrace: the ramp and the arch are right behind)
		beam("Brace", Vector3.new(X + s * PX, sumY + 5.6, EDGE + 0.2), Vector3.new(X + s * PX, TOPY - 0.3, EDGE + 2.4), 0.36, DARK, Enum.Material.Wood, hoist)
	end
	part("BackBeam", Vector3.new(PX * 2 + 0.9, 0.5, 0.55), CFrame.new(X, TOPY, EDGE), DARK, Enum.Material.Wood, hoist)
	part("FrontBeam", Vector3.new(PX * 2 + 0.9, 0.45, 0.5), CFrame.new(X, TOPY, Z + 0.45), DARK, Enum.Material.Wood, hoist)
	-- the pulley between the jibs, right over the basket
	local wheelY = TOPY - 0.55
	part("Axle", Vector3.new(PX * 2, 0.2, 0.2), CFrame.new(X, wheelY, Z) * CFrame.Angles(0, 0, 0), C(90, 90, 96), Enum.Material.Metal, hoist, Enum.PartType.Cylinder)
	local wheel = part("Pulley", Vector3.new(0.3, 1.2, 1.2), CFrame.new(X, wheelY, Z), C(96, 70, 46), Enum.Material.Wood, hoist, Enum.PartType.Cylinder)
	for _, s in ipairs({-1, 1}) do part("Cheek", Vector3.new(0.12, 1.5, 0.5), CFrame.new(X + s * 0.28, wheelY + 0.3, Z), C(90, 90, 96), Enum.Material.Metal, hoist) end
	local pulleyDown = Instance.new("Attachment"); pulleyDown.Name = "RopeDown"; pulleyDown.Position = Vector3.new(0, -0.6, 0); pulleyDown.Parent = wheel
	local pulleyBack = Instance.new("Attachment"); pulleyBack.Name = "RopeBack"; pulleyBack.Position = Vector3.new(0, 0, -0.6); pulleyBack.Parent = wheel
	-- the hand winch on the east post (terrace side), its rope running up to the pulley
	local wx, wy, wz = X + PX, sumY + 2.7, EDGE - 0.85
	-- (all soft: climbers step off the top of trellis B just east of it)
	local drum = soft(part("Drum", Vector3.new(1.0, 0.75, 0.75), CFrame.new(wx, wy, wz), ROPE:Lerp(WOOD, 0.35), Enum.Material.Fabric, hoist, Enum.PartType.Cylinder))
	for _, s in ipairs({-1, 1}) do soft(part("Bracket", Vector3.new(0.14, 0.9, 0.9), CFrame.new(wx + s * 0.57, wy, wz + 0.1), DARK, Enum.Material.Wood, hoist)) end
	soft(part("Crank", Vector3.new(0.14, 0.9, 0.14), CFrame.new(wx + 0.72, wy - 0.35, wz), C(90, 90, 96), Enum.Material.Metal, hoist))
	soft(part("Handle", Vector3.new(0.45, 0.14, 0.14), CFrame.new(wx + 0.9, wy - 0.75, wz), DARK, Enum.Material.Wood, hoist, Enum.PartType.Cylinder))
	local drumTop = Instance.new("Attachment"); drumTop.Name = "RopeUp"; drumTop.Position = Vector3.new(0, 0.38, 0); drumTop.Parent = drum
	local function rope(name, a0, a1, parent)
		local b = Instance.new("Beam"); b.Name = name; b.Attachment0 = a0; b.Attachment1 = a1
		b.Width0 = 0.13; b.Width1 = 0.13; b.Color = ColorSequence.new(ROPE); b.FaceCamera = true; b.Segments = 1
		b.LightInfluence = 1; b.Transparency = NumberSequence.new(0); b.Parent = parent
		return b
	end
	rope("WinchRope", drumTop, pulleyBack, hoist)
	-- the board on top of the headframe, facing the terrace
	local boardCF = CFrame.new(X, TOPY + 0.25 + 0.7, EDGE)
	local board = part("Board", Vector3.new(4.2, 1.4, 0.2), boardCF, C(244, 232, 204), Enum.Material.Wood, hoist)
	for _, s in ipairs({-1, 1}) do part("BoardPost", Vector3.new(0.22, 1.4, 0.3), boardCF * CFrame.new(s * 1.9, -0.1, 0.1), DARK, Enum.Material.Wood, hoist) end
	local sg = Instance.new("SurfaceGui"); sg.Name = "Words"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 64; sg.LightInfluence = 0.3; sg.Parent = board
	local function words(t, y, h, colour)
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -16, 0, h); l.Position = UDim2.new(0, 8, 0, y)
		l.Font = Enum.Font.FredokaOne; l.Text = t; l.TextScaled = true; l.TextColor3 = colour; l.Parent = sg
	end
	words("BASKET LIFT", 6, 50, C(62, 40, 26))
	words("down to the start stone", 58, 26, C(150, 100, 50))

	-- ---------------------------------------------------------------- the basket ----
	-- (its own frame: the floor's top middle; the gap in the wall on the terrace side is where you step in)
	local basket = Instance.new("Model"); basket.Name = "Basket"; basket.Parent = F
	local BW, BD, WH, T = 3.8, 3.6, 2.2, 0.22                    -- width (x), depth (z), wall height, wall thickness
	local function bp(name, size, off, colour, material, shape) return part(name, size, REST * off, colour, material, basket, shape) end
	local floor = bp("Floor", Vector3.new(BW, FLOOR, BD), CFrame.new(0, -FLOOR / 2, 0), C(150, 108, 62), Enum.Material.WoodPlanks)
	bp("Wall", Vector3.new(BW, WH, T), CFrame.new(0, WH / 2, BD / 2 - T / 2), STRAW, Enum.Material.Wood)
	for _, s in ipairs({-1, 1}) do
		bp("Wall", Vector3.new(T, WH, BD), CFrame.new(s * (BW / 2 - T / 2), WH / 2, 0), STRAW, Enum.Material.Wood)
		bp("Wall", Vector3.new(0.95, WH, T), CFrame.new(s * (BW / 2 - 0.475), WH / 2, -BD / 2 + T / 2), STRAW, Enum.Material.Wood)
	end
	-- the weave: darker bands round the outside, a rim along the top, posts at the corners (all just for looks)
	for _, y in ipairs({0.55, 1.25}) do
		soft(bp("Band", Vector3.new(BW + 0.06, 0.16, 0.06), CFrame.new(0, y, BD / 2 + 0.02), WEAVE, Enum.Material.Wood))
		for _, s in ipairs({-1, 1}) do soft(bp("Band", Vector3.new(0.06, 0.16, BD + 0.06), CFrame.new(s * (BW / 2 + 0.02), y, 0), WEAVE, Enum.Material.Wood)) end
	end
	bp("Rim", Vector3.new(BW + 0.14, 0.26, 0.3), CFrame.new(0, WH + 0.05, BD / 2 - 0.1), DARK, Enum.Material.Wood)
	for _, s in ipairs({-1, 1}) do
		bp("Rim", Vector3.new(0.3, 0.26, BD + 0.14), CFrame.new(s * (BW / 2 - 0.1), WH + 0.05, 0), DARK, Enum.Material.Wood)
		bp("Rim", Vector3.new(1.0, 0.26, 0.3), CFrame.new(s * (BW / 2 - 0.5), WH + 0.05, -BD / 2 + 0.1), DARK, Enum.Material.Wood)
	end
	for _, sx in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
		bp("Corner", Vector3.new(0.3, WH + 0.3, 0.3), CFrame.new(sx * (BW / 2 - 0.1), (WH + 0.3) / 2 - 0.1, sz * (BD / 2 - 0.1)), DARK, Enum.Material.Wood)
	end end
	-- four ropes from the corners up to an iron ring well over a rider's head, and the ring's rope up to the pulley
	local RING = 7.0
	for _, sx in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
		local a = REST:PointToWorldSpace(Vector3.new(sx * (BW / 2 - 0.12), WH + 0.15, sz * (BD / 2 - 0.12)))
		soft(beam("Hanger", a, REST:PointToWorldSpace(Vector3.new(0, RING - 0.15, 0)), 0.1, ROPE, Enum.Material.Fabric, basket, true))
	end end
	local ring = soft(bp("Ring", Vector3.new(0.22, 0.75, 0.75), CFrame.new(0, RING, 0) * CFrame.Angles(0, 0, math.rad(90)), C(70, 70, 76), Enum.Material.Metal, Enum.PartType.Cylinder))
	local ringUp = Instance.new("Attachment"); ringUp.Name = "RopeUp"; ringUp.Parent = ring
	ringUp.WorldPosition = REST:PointToWorldSpace(Vector3.new(0, RING + 0.3, 0))
	rope("LiftRope", pulleyDown, ringUp, F)
	basket.PrimaryPart = floor
	floor.PivotOffset = CFrame.new(0, FLOOR / 2, 0)             -- (its pivot is the floor's top: where a rider's feet go)
	for _, p in ipairs(basket:GetDescendants()) do if p:IsA("BasePart") then p.CastShadow = true end end

	local pr = Instance.new("ProximityPrompt"); pr.Name = "RideDown"; pr.ActionText = "Ride down"; pr.ObjectText = "Basket lift"
	pr.KeyboardKeyCode = Enum.KeyCode.E; pr.HoldDuration = 0.25; pr.MaxActivationDistance = 10; pr.RequiresLineOfSight = false
	pr.Parent = floor

	-- ---------------------------------------------------------------- the tunables and the event ----
	F:SetAttribute("RideSeconds", opts.rideSeconds or 7)
	F:SetAttribute("ReturnSeconds", opts.returnSeconds or 6)
	F:SetAttribute("Drop", DROP)
	-- where you hop out to: the start stone, clear of its sign (the board's west end reaches x 497.4)
	F:SetAttribute("HopX", opts.hopX or (CL:GetAttribute("StartX") or 498) + 1.5)
	F:SetAttribute("HopY", stone.Position.Y + stone.Size.Y / 2)
	F:SetAttribute("HopZ", opts.hopZ or (CL:GetAttribute("StartZ") or -243.3))
	F:SetAttribute("Busy", false)
	if not RS:FindFirstChild("LiftEvent") then local e = Instance.new("RemoteEvent"); e.Name = "LiftEvent"; e.Parent = RS end
	local dbg = Instance.new("BindableEvent"); dbg.Name = "LiftDebugStart"; dbg.Parent = F   -- Studio tests: start(player) without the prompt

	-- ---------------------------------------------------------------- the server ----
	local SERVER = [==[
-- LiftServer: who rides the basket, and the basket itself - welded to its rider on the way down, wound back up empty
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local L = script.Parent
local ev = RS:WaitForChild("LiftEvent")
local basket = L:WaitForChild("Basket")
local floor = basket:WaitForChild("Floor")
local prompt = floor:WaitForChild("RideDown")
local REST = basket:GetPivot()                         -- hanging at the top, its floor level with the terrace
local SOLID = {}                                       -- what is solid while it waits at the top
for _, p in ipairs(basket:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then SOLID[p] = true end end
local STEP_BACK = REST.Position + Vector3.new(2.5, 3.2, -6.0)   -- (on the terrace, if somebody stands in it as it leaves)

local ride = nil                                       -- {player, hrp, phase = "in" | "down" | "out", ...}
local function setSolid(on) for p in pairs(SOLID) do if p.Parent then p.CanCollide = on end end end
local function say(player, text) ev:FireClient(player, "say", text) end

-- unhooked from the rider and held where the server says (anchored before its welds go, all in one step, so it never
-- falls - and never anchors the rider either)
local function anchorAt(cf)
	for _, d in ipairs(basket:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true
		elseif d:IsA("WeldConstraint") and d.Name == "RiderWeld" then d:Destroy() end
	end
	for _, d in ipairs(basket:GetDescendants()) do if d:IsA("BasePart") then d.Massless = false end end
	if cf then basket:PivotTo(cf) end
end
local function weldTo(hrp)
	for _, d in ipairs(basket:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false; d.Massless = true; d.Anchored = false
			local w = Instance.new("WeldConstraint"); w.Name = "RiderWeld"; w.Part0 = hrp; w.Part1 = d; w.Parent = d
		end
	end
end

local function ready()
	ride = nil
	L:SetAttribute("Busy", false)
	prompt.Enabled = true
end
-- the empty basket winds itself back up: every client draws the move (LiftClient), the server puts it at the top after
local function backUp(from)
	ride = nil
	anchorAt(from)
	setSolid(false)
	local secs = L:GetAttribute("ReturnSeconds") or 6
	local t0 = workspace:GetServerTimeNow()
	basket:SetAttribute("K0", from); basket:SetAttribute("K1", REST); basket:SetAttribute("Secs", secs)
	basket:SetAttribute("T0", t0)
	task.delay(secs, function()
		if basket:GetAttribute("T0") ~= t0 then return end
		basket:PivotTo(REST)
		setSolid(true)
		basket:SetAttribute("T0", nil)
		ready()
	end)
end
local function atFoot(r)
	if ride ~= r or r.phase ~= "down" then return end
	r.phase = "out"
	local foot = REST - Vector3.new(0, L:GetAttribute("Drop"), 0)
	anchorAt(foot)
	ev:FireClient(r.player, "out")                                  -- the rider hops out onto the start stone
	task.delay(1.6, function() if ride == r then backUp(foot) end end)
end
local function riderGone(r)
	if ride ~= r then return end
	if r.phase == "in" then anchorAt(REST); setSolid(true); ready() return end
	backUp(basket:GetPivot())                                       -- (welded to a character going away: unhook it first)
end

local function start(player)
	if ride or L:GetAttribute("Busy") then say(player, "The basket is on its way back up - one moment!") return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 or char:GetAttribute("Gliding") then return end
	if player:GetAttribute("Climbing") then say(player, "Ring the bell first - your climb's clock is still running!") return end
	if player:GetAttribute("Racing") then say(player, "Finish your Forest Race first!") return end
	if (hrp.Position - floor.Position).Magnitude > 14 then return end
	-- anybody else standing in it steps back onto the terrace
	for _, pl in ipairs(Players:GetPlayers()) do
		local c = pl ~= player and pl.Character
		local rr = c and c:FindFirstChild("HumanoidRootPart")
		if rr then
			local lp = REST:PointToObjectSpace(rr.Position)
			if math.abs(lp.X) < 2.4 and math.abs(lp.Z) < 2.3 and lp.Y > -1 and lp.Y < 7 then c:PivotTo(CFrame.new(STEP_BACK) * (rr.CFrame - rr.Position)) end
		end
	end
	hum:UnequipTools()
	local r = {player = player, hrp = hrp, phase = "in"}
	ride = r
	L:SetAttribute("Busy", true)
	prompt.Enabled = false
	r.died = hum.Died:Connect(function() riderGone(r) end)
	ev:FireClient(player, "ride", REST)                            -- the client hops the rider in, then says "in"
	task.delay(5, function() if ride == r and r.phase == "in" then riderGone(r) end end)
end

ev.OnServerEvent:Connect(function(player, what)
	local r = ride
	if not r or r.player ~= player then return end
	if what == "in" and r.phase == "in" then
		if not r.hrp.Parent then riderGone(r) return end
		weldTo(r.hrp)
		r.phase = "down"
		local secs = L:GetAttribute("RideSeconds") or 7
		ev:FireClient(player, "go", secs, L:GetAttribute("Drop"))
		task.delay(secs + 8, function() atFoot(r) end)                -- (if the client never says it got there)
	elseif what == "down" then
		atFoot(r)
	end
end)
PPS.PromptTriggered:Connect(function(p, player)
	if p == prompt then start(player) end
end)
local function watch(player)
	player.CharacterRemoving:Connect(function() if ride and ride.player == player then riderGone(ride) end end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(player) if ride and ride.player == player then riderGone(ride) end end)
local dbg = L:FindFirstChild("LiftDebugStart")
if dbg and RunService:IsStudio() then dbg.Event:Connect(start) end
print("BasketLift: ready")
]==]

	-- ---------------------------------------------------------------- the client ----
	local CLIENT = [==[
-- LiftClient: riding the basket - hop in, down the cliff face, hop out onto the start stone - and drawing its trip back up
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local L = script.Parent
local ev = RS:WaitForChild("LiftEvent")
local basket = L:WaitForChild("Basket")
local C = Color3.fromRGB
local NAVY, CREAM = C(38, 30, 52), C(255, 246, 220)

-- the note at the foot of the screen: the hang glider's, in the same place (measured clear of everything on an iPhone 7)
local gui = Instance.new("ScreenGui"); gui.Name = "LiftGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 16
gui.Parent = player:WaitForChild("PlayerGui")
local note = Instance.new("TextLabel"); note.Name = "Note"; note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -84)
note.Size = UDim2.fromOffset(420, 40); note.BackgroundColor3 = NAVY; note.BackgroundTransparency = 1; note.BorderSizePixel = 0
note.Font = Enum.Font.FredokaOne; note.TextSize = 18; note.TextColor3 = CREAM; note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""
note.Parent = gui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local noteAt, fade = 0, nil
local function say(t, secs)
	if fade then fade:Cancel(); fade = nil end
	note.Text = t; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); noteAt = mine
	task.delay(secs or 3.2, function()
		if noteAt ~= mine then return end
		fade = TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}); fade:Play()
	end)
end

local BIND = "BasketLift"
local OUT = Vector3.new(0, 0, 1)                             -- facing out over the valley
local function smooth(u) u = math.clamp(u, 0, 1); return u * u * (3 - 2 * u) end
local function run(fn) RunService:UnbindFromRenderStep(BIND); RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value - 1, fn) end
local function stopRun() RunService:UnbindFromRenderStep(BIND) end
local function still(hrp) hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end
-- an arc from CFrame a to CFrame b, then done()
local function hop(hrp, a, b, secs, height, done)
	local t0 = os.clock()
	run(function()
		if not hrp.Parent then stopRun() return end
		local u = math.clamp((os.clock() - t0) / secs, 0, 1)
		local turn = a:Lerp(b, smooth(u))
		hrp.CFrame = CFrame.new(a.Position:Lerp(b.Position, u) + Vector3.new(0, height * math.sin(math.pi * u), 0)) * (turn - turn.Position)
		still(hrp)
		if u >= 1 then stopRun(); done() end
	end)
end
local function hold(hrp, cf) run(function() if hrp.Parent then hrp.CFrame = cf; still(hrp) end end) end

local at = nil                                               -- where the rider is held between the steps
ev.OnClientEvent:Connect(function(what, a, b)
	if what == "say" then say(a) return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) then return end
	local legs = hum.HipHeight + hrp.Size.Y / 2
	if what == "ride" then
		-- into the basket, facing out; the camera goes out in front and to one side, looking back at you and the cliff
		-- (behind you it would be in the rock)
		hum.PlatformStand = true
		local p = a.Position + Vector3.new(0, legs, 0)
		local inside = CFrame.lookAt(p, p + OUT)
		local cam = workspace.CurrentCamera
		if cam and cam.CameraType == Enum.CameraType.Custom then
			cam.CFrame = CFrame.lookAt(p + OUT * 11 + Vector3.new(6, 3.5, 0), p + Vector3.new(0, 1, 0))
		end
		hop(hrp, hrp.CFrame, inside, 0.45, 1.6, function()
			at = inside; hold(hrp, at)
			-- (a moment standing still first, so the server sees you where you are when it hooks the basket on)
			task.delay(0.25, function() ev:FireServer("in") end)   -- (then it says "go")
		end)
	elseif what == "go" then
		local secs, drop = a, b
		local top, t0 = at, os.clock()
		say("Enjoy the view on the way down!", 3)
		run(function()
			if not hrp.Parent or hum.Health <= 0 then stopRun() return end
			local u = (os.clock() - t0) / secs
			hrp.CFrame = top - Vector3.new(0, drop * smooth(u), 0)
			still(hrp)
			if u >= 1 then
				at = top - Vector3.new(0, drop, 0)
				hold(hrp, at)
				ev:FireServer("down")                              -- (the server unhooks it, then says "out")
			end
		end)
	elseif what == "out" then
		-- over the garden wall onto the start stone
		local target = Vector3.new(L:GetAttribute("HopX"), L:GetAttribute("HopY") + legs, L:GetAttribute("HopZ"))
		local from = at or hrp.CFrame
		local look = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
		look = look.Magnitude > 0.1 and look.Unit or OUT
		hop(hrp, from, CFrame.lookAt(target, target + look), 0.75, 4.5, function()
			hum.PlatformStand = false
			still(hrp)
			hum:ChangeState(Enum.HumanoidStateType.Landed)
			at = nil
			say("Back at the start stone!", 2.6)
		end)
	end
end)

-- the empty basket's trip back up (LiftServer's backUp): drawn here frame by frame so it is smooth; the server puts it
-- at the top when the time is up
local function watchReturn()
	local t0 = basket:GetAttribute("T0")
	if not t0 then return end
	local K0, K1, secs = basket:GetAttribute("K0"), basket:GetAttribute("K1"), basket:GetAttribute("Secs") or 6
	if typeof(K0) ~= "CFrame" or typeof(K1) ~= "CFrame" then return end
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local u = (workspace:GetServerTimeNow() - t0) / secs
		if basket:GetAttribute("T0") ~= t0 or not basket.Parent then conn:Disconnect() return end
		basket:PivotTo(K0:Lerp(K1, smooth(u)))
		if u >= 1 then conn:Disconnect() end
	end)
end
basket:GetAttributeChangedSignal("T0"):Connect(watchReturn)
watchReturn()
]==]

	local s = Instance.new("Script"); s.Name = "LiftServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "LiftClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace

	local pieces = 0
	for _, p in ipairs(F:GetDescendants()) do if p:IsA("BasePart") then pieces += 1 end end
	print(string.format("BasketLift: basket at %.1f,%.1f from y %.1f down %.1f to the foot (y %.1f), %d pieces, foot props removed %d",
		X, Z, sumY, DROP, foot, pieces, removed))
	return F
end
