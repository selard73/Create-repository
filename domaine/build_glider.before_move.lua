-- HangGlider: a hang glider bought once in the Acorn Store for 1000 acorns (Item_glider), taken off from a wooden ramp
-- on the Sandstone Climb's summit to fly down into the Rue. Shannon (Sep 27 2026): "I want to make a hand glider that
-- you'll be able to buy for a thousand acorns. And it's something you can use from the top of that mountain to fly down
-- into the city" - and to the plan (take off only from the summit, the joystick steers, jump lets go, it lands by itself,
-- a flying-squirrel sail): "all of that sounds excellent lets do it".
--
-- THE SAIL: a classic delta hang glider in bright colours (Shannon, after her first flights: "I don't like the look of it;
-- I want it to be colorful" - the flying-squirrel sail it started with is kept in domaine/glider/flying_squirrel/). One
-- mesh and texture made by domaine/gen_glider_mesh.py <scheme>, imported and kept hidden as
-- ServerStorage.GliderKit.GliderSail (scratchpad kit_glider.lua). A smaller copy sits on the launch arch as the sign.
-- AFTER THE FLIGHT the glider stays where it came down for LingerSeconds, then fades (GliderServer's settle).
--
-- HOW THE FLIGHT WORKS (the zipline's way): the SERVER decides whether you may take off - is the glider yours, are you on
-- the ramp, is the climb's clock not still running - builds the glider welded to the character so everybody sees it (the
-- wind in it and a streak off each wing tip included), raises the arms to the bar, and takes it all back when you land.
-- The pilot's own client flies the character (a client owns its character's physics, so a CFrame it sets every frame is
-- what everyone else sees): a run down the ramp, then the glide - Speed studs/s ahead, sinking Sink studs/s - turning
-- toward wherever the joystick points (TurnRate degrees/s at most, leaning into the turn), and diving (DiveSpeed,
-- DiveSink) while you push the way you are already going. It lands by itself on whatever is under it - grass, the
-- street, a roof. Bumping into something, or reaching the edge of the map (Zones), lets go; so does jumping, any time.
-- WHY IT POINTS AT THE RUE'S GARDEN GATE: a straight line from the summit to the square crosses the Rue's east-end roofs
-- (townhouse_d, 36 high) where only a 5.3 glide ratio clears them; the line to the gate (352, -120) passes over roofs of
-- 22 (probe_glide.lua). So the ramp faces the gate and the glider cruises at 5.5 (32 over 5.8) - over the gate at about
-- 42 - and a dive (40 over 14) brings you down into the street or the square. The invisible walls along x 352 open for
-- anyone who has unlocked the Chateau (OpenAcross), which a pilot on the summit always has.
-- Tunable in Properties on workspace.HangGlider. Nothing here touches the DataStore.
-- Run in edit mode (re-runnable; also removes the summit boxwood that stood where the ramp goes).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local SS = game:GetService("ServerStorage")
	local C = Color3.fromRGB
	local CL = workspace:FindFirstChild("SandstoneClimb")
	assert(CL, "HangGlider: build the Sandstone Climb first")
	local top = CL:FindFirstChild("Summit") and CL.Summit:FindFirstChild("Top")
	assert(top, "HangGlider: the climb has no summit")
	local kit = SS:FindFirstChild("GliderKit")
	assert(kit and kit:FindFirstChild("GliderSail"), "HangGlider: import the sail first (kit_glider.lua)")
	local SAIL_C = Vector3.new(0, 0.2564, -1.4)                  -- the sail mesh's bounding-box centre in the glider's frame (gen_glider_mesh.py)
	local sumY = top.Position.Y + top.Size.Y / 2
	local rng = Random.new(opts.seed or 2709)

	local old = workspace:FindFirstChild("HangGlider"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "HangGlider"

	-- the boxwood on the terrace's south-west corner stood where the ramp goes (build_cliff.lua no longer plants it)
	local removed = 0
	for _, m in ipairs(CL:GetDescendants()) do
		if m:IsA("Model") and m.Name == "boxwood" and m.Parent then
			local cf = m:GetBoundingBox()
			if (Vector3.new(cf.X, 0, cf.Z) - Vector3.new(485.5, 0, -254.5)).Magnitude < 2 and cf.Y > sumY - 1 then m:Destroy(); removed += 1 end
		end
	end

	-- ---------------------------------------------------------------- the ramp ----
	-- from the terrace's south-west corner out over the cliff's edge, pointing at the Rue's garden gate
	local B = Vector3.new(opts.rampX or 489.5, sumY, opts.rampZ or -257.5)          -- its back end, on the terrace
	local aim = Vector3.new(opts.aimX or 352, sumY, opts.aimZ or -120)
	local dir = ((aim - B) * Vector3.new(1, 0, 1)).Unit
	local RC = CFrame.lookAt(B, B + dir)                                              -- -Z runs down the ramp, +X is its right
	local LEN, WIDE, DROP = opts.rampLength or 12, 4.6, 1.0                           -- the deck falls DROP from back to lip
	local SLOPE = math.atan(DROP / LEN)
	local function deckY(s) return sumY + 0.42 - DROP * s / LEN end                   -- the planks' top, s studs down the ramp
	local WOOD, PLANK, DARK, ROPE = C(118, 84, 52), C(158, 119, 74), C(92, 62, 38), C(214, 196, 150)

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
	local function onRamp(x, s, up) return (RC * CFrame.new(x, deckY(s) - sumY + (up or 0), -s)).Position end

	local ramp = Instance.new("Model"); ramp.Name = "Ramp"; ramp.Parent = F
	local planks = 0
	for s = 0.49, LEN - 0.3, 0.98 do
		local c = PLANK:Lerp(DARK, rng:NextNumber(0, 0.22))
		part("Plank", Vector3.new(WIDE, 0.24, 0.9), RC * CFrame.new(0, deckY(s) - sumY - 0.12, -s) * CFrame.Angles(-SLOPE, 0, 0), c, Enum.Material.WoodPlanks, ramp)
		planks += 1
	end
	for _, sx in ipairs({-1, 1}) do                                                    -- the stringers under the planks
		beam("Stringer", onRamp(sx * (WIDE / 2 - 0.45), 0.1, -0.5), onRamp(sx * (WIDE / 2 - 0.45), LEN - 0.1, -0.5), 0.5, DARK, Enum.Material.Wood, ramp)
	end
	-- a rail along each side for the first two thirds; the lip end stays open
	for _, sx in ipairs({-1, 1}) do
		local x = sx * (WIDE / 2 - 0.08)
		local last
		for s = 0.3, 8.4, 2.7 do
			part("RailPost", Vector3.new(0.3, 1.2, 0.3), CFrame.new(onRamp(x, s, 0.6)), WOOD, Enum.Material.Wood, ramp)
			last = s
		end
		beam("Rail", onRamp(x, 0.3, 1.2), onRamp(x, last, 1.2), 0.24, WOOD, Enum.Material.Wood, ramp)
		beam("Rail", onRamp(x, 0.3, 0.62), onRamp(x, last, 0.62), 0.16, WOOD, Enum.Material.Wood, ramp)
	end
	-- the overhang is held up by two struts down to the rock (found by a ray from under the lip)
	local rockP = RaycastParams.new(); rockP.FilterType = Enum.RaycastFilterType.Include; rockP.FilterDescendantsInstances = {CL, workspace.Terrain}
	local struts = 0
	for _, sx in ipairs({-1, 1}) do
		local a = onRamp(sx * (WIDE / 2 - 0.45), LEN - 0.8, -0.7)
		local d = (-dir * 0.8 + Vector3.new(0, -1, 0)).Unit
		local hit = workspace:Raycast(a, d * 16, rockP)
		local b = hit and hit.Position or (a + d * 7)
		beam("Strut", a, b, 0.42, DARK, Enum.Material.Wood, ramp)
		struts += 1
	end

	-- ---------------------------------------------------------------- the launch arch, its sign and the display glider ----
	local arch = Instance.new("Model"); arch.Name = "Arch"; arch.Parent = F
	local AS = 0.35                                                                    -- how far down the ramp the arch stands
	local archTop = deckY(AS) + 7.4                                                   -- (the crossbar clears a tall avatar's head)
	for _, sx in ipairs({-1, 1}) do
		local p = onRamp(sx * (WIDE / 2 + 0.32), AS)
		part("Post", Vector3.new(0.6, archTop - deckY(AS) + 0.3, 0.6), CFrame.new(p.X, (deckY(AS) + archTop) / 2 - 0.1, p.Z) * (RC - RC.Position), PLANK, Enum.Material.Wood, arch)
	end
	local barCF = CFrame.new(onRamp(0, AS, archTop - deckY(AS))) * (RC - RC.Position)
	part("Crossbar", Vector3.new(WIDE + 1.9, 0.5, 0.62), barCF, DARK, Enum.Material.Wood, arch)
	-- the sign stands ON the crossbar like a gateway's name board (hanging under it on cords read like a gallows),
	-- facing the terrace where people come from
	local signCF = barCF * CFrame.new(0, 0.25 + 0.72, 0) * CFrame.Angles(0, math.pi, 0)
	local sign = soft(part("Sign", Vector3.new(3.9, 1.44, 0.22), signCF, C(244, 232, 204), Enum.Material.Wood, arch))
	for _, sx in ipairs({-1, 1}) do soft(part("Brace", Vector3.new(0.22, 1.2, 0.3), barCF * CFrame.new(sx * 2.05, 0.8, 0.05), DARK, Enum.Material.Wood, arch)) end
	local signTop = 0.25 + 1.44                                                        -- (above the crossbar's middle)
	local sg = Instance.new("SurfaceGui"); sg.Name = "Words"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 64; sg.LightInfluence = 0.3; sg.Parent = sign
	local function words(t, y, h, colour)
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -16, 0, h); l.Position = UDim2.new(0, 8, 0, y)
		l.Font = Enum.Font.FredokaOne; l.Text = t; l.TextScaled = true; l.TextColor3 = colour; l.Parent = sg
	end
	words("HANG GLIDER", 6, 50, C(62, 40, 26))
	words("fly down into the Rue", 58, 26, C(150, 100, 50))

	-- the display: the same glider at a little over half size, its bar resting on the sign, nose up toward the Rue so the
	-- people on the terrace see its colours
	local DS = opts.displayScale or 0.56
	local disp = Instance.new("Model"); disp.Name = "Display"; disp.Parent = F
	local O = barCF * CFrame.new(0, signTop, 0) * CFrame.Angles(math.rad(26), 0, 0) * CFrame.new(0, 2.3 * DS, 1.0 * DS)   -- the glider's own frame
	local sailD = kit.GliderSail:Clone(); sailD.Size = sailD.Size * DS; sailD.CFrame = O * CFrame.new(SAIL_C * DS)
	sailD.Anchored = true; sailD.CanCollide = false; sailD.CanQuery = false; sailD.CanTouch = false; sailD.Parent = disp
	local STEEL = C(196, 198, 206)
	local function dtube(name, a, b, d) return soft(beam(name, O:PointToWorldSpace(a * DS), O:PointToWorldSpace(b * DS), d * DS, STEEL, Enum.Material.Metal, disp, true)) end
	dtube("Keel", Vector3.new(0, -0.1, -4.9), Vector3.new(0, -0.1, 2.15), 0.24)
	for _, sx in ipairs({-1, 1}) do dtube("LeadingEdge", Vector3.new(0, -0.05, -4.95), Vector3.new(sx * 6.4, 0.3, 1.4), 0.22) end
	local hangPt = Vector3.new(0, -0.12, -1.0)
	for _, sx in ipairs({-1, 1}) do dtube("DownTube", hangPt, Vector3.new(sx * 1.35, -2.3, -1.0), 0.18) end
	dtube("BaseBar", Vector3.new(-1.6, -2.3, -1.0), Vector3.new(1.6, -2.3, -1.0), 0.2)

	-- the windsock, on the terrace beside the ramp, blowing back up the ramp (you take off into the wind)
	local ws = Instance.new("Model"); ws.Name = "Windsock"; ws.Parent = F
	local wp = B + dir * 3.6 + RC.RightVector * 3.2                                   -- (0.7 in from the terrace's west edge)
	soft(part("Pole", Vector3.new(0.28, 6.6, 0.28), CFrame.new(wp.X, sumY + 3.3, wp.Z), C(206, 206, 212), Enum.Material.Metal, ws, nil))
	part("Foot", Vector3.new(1.1, 0.3, 1.1), CFrame.new(wp.X, sumY + 0.15, wp.Z), C(170, 170, 176), Enum.Material.Metal, ws)
	local sockDir = (-dir + Vector3.new(0, -0.3, 0)).Unit
	local p0 = Vector3.new(wp.X, sumY + 6.35, wp.Z)
	for i = 0, 4 do
		local r = 0.5 - i * 0.065
		local c = p0 + sockDir * (0.36 + i * 0.6)
		soft(part("Sock", Vector3.new(0.6, r * 2, r * 2), CFrame.lookAt(c, c + sockDir) * CFrame.Angles(0, math.rad(90), 0),
			(i % 2 == 0) and C(226, 90, 60) or C(250, 244, 232), Enum.Material.Fabric, ws, Enum.PartType.Cylinder))
	end
	soft(part("Ring", Vector3.new(0.12, 1.1, 1.1), CFrame.lookAt(p0, p0 + sockDir) * CFrame.Angles(0, math.rad(90), 0), C(206, 206, 212), Enum.Material.Metal, ws, Enum.PartType.Cylinder))

	-- ---------------------------------------------------------------- the prompt, the tunables, the event ----
	local pr = Instance.new("ProximityPrompt"); pr.Name = "TakeOff"; pr.ActionText = "Take off"; pr.ObjectText = "Hang glider"
	pr.KeyboardKeyCode = Enum.KeyCode.E; pr.HoldDuration = 0.25; pr.MaxActivationDistance = 11; pr.RequiresLineOfSight = false
	pr.Parent = sign
	-- (first test, Sep 27: at 32 over 5.8 a hands-off flight crossed the whole Rue and met its far wall at y 14; at 32 over
	-- 7 it comes down on the lawns in the Rue's south half and still clears the east-end roofs on the gate line by ~5)
	F:SetAttribute("Speed", opts.speed or 32); F:SetAttribute("Sink", opts.sink or 7)
	F:SetAttribute("DiveSpeed", opts.diveSpeed or 40); F:SetAttribute("DiveSink", opts.diveSink or 14)
	F:SetAttribute("TurnRate", opts.turnRate or 80); F:SetAttribute("MaxSeconds", opts.maxSeconds or 45)
	F:SetAttribute("RampX", B.X); F:SetAttribute("RampY", sumY); F:SetAttribute("RampZ", B.Z)
	F:SetAttribute("RampDirX", dir.X); F:SetAttribute("RampDirZ", dir.Z); F:SetAttribute("RampLength", LEN); F:SetAttribute("RampDrop", DROP)
	F:SetAttribute("WindSound", opts.windSound or "rbxasset://sounds/action_falling.mp3"); F:SetAttribute("WindVolume", opts.windVolume or 0.3)
	-- where a glider may be (the forest, the Rue, the estate and the cliff inside its fence); past these it lets go.
	-- x0,x1,z0,z1 per zone - the invisible walls themselves can't be relied on (the cliff's fence can't be hit by a ray)
	F:SetAttribute("Zones", opts.zones or "-130,150,-215,25;150,352,-205,5;352,700,-250,30;468,566,-273,-249.4")
	if not RS:FindFirstChild("GliderEvent") then local e = Instance.new("RemoteEvent"); e.Name = "GliderEvent"; e.Parent = RS end
	local dbg = Instance.new("BindableEvent"); dbg.Name = "GliderDebugStart"; dbg.Parent = F   -- Studio tests: start(player) without the prompt
	-- after a flight the glider stays where it came down this long, then fades; the ones left behind wait in Landed
	F:SetAttribute("LingerSeconds", opts.lingerSeconds or 20)
	local landedF = Instance.new("Folder"); landedF.Name = "Landed"; landedF.Parent = F

	-- ---------------------------------------------------------------- the server ----
	local SERVER = [==[
-- GliderServer: may this player take off? If so, the glider on their back (for everyone to see) and their arms on the bar
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PPS = game:GetService("ProximityPromptService")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local G = script.Parent
local ev = RS:WaitForChild("GliderEvent")
local kit = SS:WaitForChild("GliderKit")
local SAIL_C = Vector3.new(0, 0.2564, -1.4)           -- the sail mesh's bounding-box centre in the glider's own frame

local function need()
	local B
	for _, b in ipairs(workspace:GetChildren()) do
		if b.Name == "Boundary" and b:FindFirstChild("Walls") then B = b end
	end
	return (B and B:GetAttribute("Need")) or 10
end

local flying = {}                                      -- player -> {char, model, c0, att}

-- THE POSE: arms up to the bar (the zipline's numbers), legs hanging nearly straight
local ARM_UP, ARM_OUT, HIP, KNEE = math.rad(172), math.rad(8), math.rad(8), math.rad(-18)
local function armTurn(out, up, spread) return CFrame.Angles(0, 0, (spread or ARM_OUT) * out) * CFrame.Angles(up or ARM_UP, 0, 0) end

-- AFTER THE FLIGHT THE GLIDER STAYS WHERE IT CAME DOWN (Shannon, Sep 27: "the hang glider just disappears when it lands;
-- that is not convincing; it should linger and still be there when you land"). Unhooked from the pilot it comes to rest
-- on whatever solid thing is under it, stays LingerSeconds and fades: after a landing it settles just behind you, parked
-- the way a hang glider is - nose and bar on the ground, wings swept up behind; let go of in the air, it flies on a
-- moment by itself and drops; after a bump it falls from where it hit (into the tree, sometimes). The server works out
-- the poses (K0 where it was, K1 the end of a pilotless glide, K2 at rest) and puts it at rest when the move is over;
-- every client draws the move in between (GliderClient), so it is smooth on every screen. One per pilot.
local landed = G:WaitForChild("Landed")
local NOSE = Vector3.new(0, 0.05, -5.0)                -- the sail's nose in the glider's frame (gen_glider_mesh.py)
local function flatUnit(v)
	v = Vector3.new(v.X, 0, v.Z)
	return v.Magnitude > 1e-3 and v.Unit or Vector3.new(0, 0, -1)
end
local function solidBelow(pos, skip)
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true
	rp.FilterDescendantsInstances = skip
	return workspace:Raycast(pos + Vector3.new(0, 1.5, 0), Vector3.new(0, -300, 0), rp)
end
-- resting: the bar's middle on the surface that was hit, lying along it (a sloping roof too), pointing `yaw`, the nose
-- tipped down until it touches as well, rolled a little if it crashed - then lifted until none of it is under whatever
-- is below it (first try, Sep 27: parked level on townhouse_e's pitched roof, half of it went into the roof)
local SAMPLES = {NOSE, Vector3.new(0, -0.1, 2.15), Vector3.new(6.6, 0.42, 1.55), Vector3.new(-6.6, 0.42, 1.55),
	Vector3.new(3.3, 0.2, -1.7), Vector3.new(-3.3, 0.2, -1.7), Vector3.new(3.3, 0.24, 1.0), Vector3.new(-3.3, 0.24, 1.0)}
local function restPose(bar, hit, yaw, roll, skip)
	local up = hit.Normal.Y > 0.7 and hit.Normal or Vector3.yAxis                -- (a wall or a steep roof: level)
	local fwd = yaw - up * yaw:Dot(up)
	fwd = fwd.Magnitude > 1e-3 and fwd.Unit or Vector3.new(0, 0, -1)
	local tilt = math.atan2(NOSE.Y - bar.Y, bar.Z - NOSE.Z)
	local rot = CFrame.fromMatrix(Vector3.zero, fwd:Cross(up), up, -fwd) * CFrame.Angles(0, 0, roll or 0) * CFrame.Angles(-tilt, 0, 0)
	local cf = CFrame.new(hit.Position + up * 0.09 - rot:VectorToWorldSpace(bar)) * rot
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true
	rp.FilterDescendantsInstances = skip
	local lift = 0
	local pts = table.clone(SAMPLES)
	table.insert(pts, bar + Vector3.new(1.7, 0, 0)); table.insert(pts, bar - Vector3.new(1.7, 0, 0))
	for _, s in ipairs(pts) do
		local w = cf:PointToWorldSpace(s)
		local h = workspace:Raycast(w + Vector3.new(0, 3, 0), Vector3.new(0, -3.3, 0), rp)
		if h then lift = math.max(lift, h.Position.Y + 0.1 - w.Y) end
	end
	return cf + Vector3.new(0, math.min(lift, 6), 0)
end
local function settle(player, r, how, heading, speed, hrpCF)
	local M = r.model
	local sail = M:FindFirstChild("GliderSail")
	local kind = type(how) == "string" and string.match(how, "^(%a+)") or nil
	if not sail or not kind or kind == "gone" then M:Destroy() return end          -- (left, reset, never reported back)
	for _, d in ipairs(M:GetDescendants()) do                                     -- unhooked: nobody's, bumps nothing
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
		elseif d:IsA("WeldConstraint") then d:Destroy()
		elseif d:IsA("Trail") then d.Enabled = false
		elseif d:IsA("Sound") then
			task.spawn(function() for _ = 1, 10 do d.Volume *= 0.6; task.wait(0.05) end; d:Stop() end)
		end
	end
	local O = sail.CFrame * CFrame.new(-SAIL_C)                                   -- the glider's own frame, right now
	-- ...as the PILOT'S screen had it: the server's copy of a moving character runs a little behind, and a glider that
	-- starts to settle from back there jumps away from the pilot first (Shannon, Sep 27: "it disappeared for a minute
	-- when I landed and then appeared again")
	if typeof(hrpCF) == "CFrame" and r.oRel and r.hrp and r.hrp.Parent and (hrpCF.Position - r.hrp.Position).Magnitude < 20 then O = hrpCF * r.oRel end
	local yaw = flatUnit((typeof(heading) == "Vector3" and heading.Magnitude > 0.5 and heading.Magnitude < 1.5) and heading or O.LookVector)
	local v = (type(speed) == "number" and speed == speed) and math.clamp(speed, 0, 60) or 20
	local bar = r.bar or Vector3.new(0, -2.2, -1.0)
	local skip = {M, landed}
	for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
	local K1, K2, T1, T2, drop = nil, nil, 0, 0, false
	if kind == "land" then
		-- settles a step behind where you touched down (you run on out from under it)
		local hit = solidBelow(O:PointToWorldSpace(bar) - yaw * 3, skip)
		if hit then K2 = restPose(bar, hit, yaw, 0, skip); T2 = 0.9 end
	else
		local from = O
		if kind == "letgo" or kind == "time" then
			-- flies on a moment by itself, slowing and sinking, its nose coming up as it stalls
			local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true
			rp.FilterDescendantsInstances = skip
			local go = yaw * math.clamp(v * 0.55, 4, 22) + Vector3.new(0, -4, 0)
			local hit = workspace:Spherecast(O.Position, 2, go, rp)
			if hit then go = go.Unit * math.max(0, hit.Distance - 0.5) end
			local p = O.Position + go
			K1 = CFrame.lookAt(p, p + yaw) * CFrame.Angles(math.rad(14), 0, 0); T1 = 1.0
			from = K1
		end
		-- then drops onto whatever is under it, skewed a little and one wing low
		local s = (player.UserId % 2 == 0) and 1 or -1
		local p = from:PointToWorldSpace(bar)
		local hit = solidBelow(p, skip)
		if hit then
			K2 = restPose(bar, hit, CFrame.Angles(0, math.rad(22) * s, 0):VectorToWorldSpace(yaw), math.rad(14) * s, skip)
			T2 = math.clamp(math.sqrt(2 * math.max(0, p.Y - hit.Position.Y) / 70), 0.35, 2.2); drop = true
		end
	end
	if not K2 then M:Destroy() return end                                         -- (nothing under it: off the map)
	local oldOne = landed:FindFirstChild(tostring(player.UserId)); if oldOne then oldOne:Destroy() end
	M.Name = tostring(player.UserId)
	M.WorldPivot = O
	-- (sent to every screen whole and kept there, wherever they are: a model moved out of a character into the streamed
	-- world can otherwise drop out on a screen until streaming sends it again)
	pcall(function() M.ModelStreamingMode = Enum.ModelStreamingMode.Persistent end)
	M:SetAttribute("K0", O); if K1 then M:SetAttribute("K1", K1) end; M:SetAttribute("K2", K2)
	M:SetAttribute("T1", T1); M:SetAttribute("T2", T2); M:SetAttribute("Drop", drop)
	M:SetAttribute("T0", workspace:GetServerTimeNow())
	M.Parent = landed
	task.delay(T1 + T2, function() if M.Parent then M:PivotTo(K2) end end)
	task.delay(T1 + T2 + (G:GetAttribute("LingerSeconds") or 20), function()
		if not M.Parent then return end
		M:SetAttribute("FadeAt", workspace:GetServerTimeNow())                    -- (each client fades it)
		task.wait(1.7)
		if M.Parent then M:Destroy() end
	end)
end

local function finish(player, how, heading, speed, hrpCF)
	local r = flying[player]; if not r then return end
	flying[player] = nil
	if r.model and r.model.Parent then
		local ok, err = pcall(settle, player, r, how, heading, speed, hrpCF)
		if not ok then
			warn("HangGlider: the glider could not settle - " .. tostring(err))
			if r.model.Parent then r.model:Destroy() end
		end
	end
	local char = r.char
	if char and char.Parent then
		for joint, c0 in pairs(r.c0) do if joint.Parent then joint.C0 = c0 end end
		for att, cf in pairs(r.att) do if att.Parent then att.CFrame = cf end end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.PlatformStand = false end
		char:SetAttribute("Gliding", nil)
	end
end

-- WHERE THE HANDS END UP with the arms raised, worked out from the rig's own attachments (the zipline's reckoning: shoulder,
-- elbow, wrist, grip), and the top of the head with hair and hats counted - so the bar sits in the hands and the sail
-- clears whatever the avatar wears, tall or small
local function reach(char, hrp)
	local function att(part, name) local a = part and part:FindFirstChild(name); return a and a.CFrame end
	local lower, upper = char:FindFirstChild("LowerTorso"), char:FindFirstChild("UpperTorso")
	local rootA, rootB = att(hrp, "RootRigAttachment"), att(lower, "RootRigAttachment")
	local waistA, waistB = att(lower, "WaistRigAttachment"), att(upper, "WaistRigAttachment")
	local upperCF = (rootA and rootB and waistA and waistB) and (rootA * rootB:Inverse() * waistA * waistB:Inverse()) or CFrame.new(0, 1.0, 0)
	local function gripOf(side, up, spread)
		local out = (side == "Left") and 1 or -1
		local turn = armTurn(out, up, spread)
		local ua, la, ha = char:FindFirstChild(side .. "UpperArm"), char:FindFirstChild(side .. "LowerArm"), char:FindFirstChild(side .. "Hand")
		local sA, sB = att(upper, side .. "ShoulderRigAttachment"), att(ua, side .. "ShoulderRigAttachment")
		local eA, eB = att(ua, side .. "ElbowRigAttachment"), att(la, side .. "ElbowRigAttachment")
		local wA, wB = att(la, side .. "WristRigAttachment"), att(ha, side .. "WristRigAttachment")
		if not (sA and sB and eA and eB and wA and wB) then return nil end
		local haCF = upperCF * (sA * turn) * sB:Inverse() * eA * eB:Inverse() * wA * wB:Inverse()
		return (haCF * (att(ha, side .. "GripAttachment") or CFrame.new())).Position
	end
	local head = char:FindFirstChild("Head")
	local headTop, headHalfW = nil, 0
	if head then
		local function top(p)
			local c = hrp.CFrame:ToObjectSpace(p.CFrame)
			local ext = math.abs(c.RightVector.Y) * p.Size.X / 2 + math.abs(c.UpVector.Y) * p.Size.Y / 2 + math.abs(c.LookVector.Y) * p.Size.Z / 2
			headTop = math.max(headTop or -math.huge, c.Y + ext)
			return c
		end
		local hc = top(head)
		headHalfW = math.abs(hc.X) + head.Size.X / 2
		for _, acc in ipairs(char:GetChildren()) do
			local h = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
			local a = h and h:FindFirstChildWhichIsA("Attachment")
			if a and head:FindFirstChild(a.Name) then top(h) end
		end
	end
	local up, spread, gL, gR = ARM_UP, ARM_OUT, nil, nil
	for deg = 8, 34, 4 do
		spread = math.rad(deg)
		gL, gR = gripOf("Left", up, spread), gripOf("Right", up, spread)
		if not (gL and gR and headTop) then break end
		if (math.abs(gL.X) + math.abs(gR.X)) / 2 - 0.3 >= headHalfW then break end
	end
	if not (gL and gR) then gL, gR = Vector3.new(-1, 3.9, -0.2), Vector3.new(1, 3.9, -0.2) end
	return gL, gR, headTop, up, spread
end

-- THE GLIDER, built to fit this pilot and welded to the root: the flying-squirrel sail over the hands, its keel and
-- leading-edge tubes, the A-frame down to a bar in both hands, the wind in it, and a streak off each wing tip.
-- Returns the model, the hang point's height and depth in the root's frame (the client banks about it), and the pose.
local function buildGlider(char, hrp)
	local gL, gR, headTop, up, spread = reach(char, hrp)
	local barY, barZ = (gL.Y + gR.Y) / 2, (gL.Z + gR.Z) / 2
	local gripX = (math.abs(gL.X) + math.abs(gR.X)) / 2
	local keelY = math.max(barY + 1.5, (headTop or barY) + 0.95)
	local M = Instance.new("Model"); M.Name = "HangGlider"
	local function weld(p)
		p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		local w = Instance.new("WeldConstraint"); w.Part0 = hrp; w.Part1 = p; w.Parent = p
		p.Parent = M
		return p
	end
	local O = hrp.CFrame * CFrame.new(0, keelY, barZ + 1.0) * CFrame.Angles(math.rad(5), 0, 0)   -- the glider's frame: keel over the hands, nose a touch up
	local sail = kit.GliderSail:Clone(); sail.CFrame = O * CFrame.new(SAIL_C); weld(sail)
	local STEEL = Color3.fromRGB(196, 198, 206)
	local function tube(name, a, b, d)                  -- a, b in the glider's frame
		local pa, pb = O:PointToWorldSpace(a), O:PointToWorldSpace(b)
		local p = Instance.new("Part"); p.Name = name; p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new((pb - pa).Magnitude, d, d)
		p.CFrame = CFrame.lookAt((pa + pb) / 2, pb) * CFrame.Angles(0, math.rad(90), 0)
		p.Color = STEEL; p.Material = Enum.Material.Metal
		return weld(p)
	end
	tube("Keel", Vector3.new(0, -0.1, -4.9), Vector3.new(0, -0.1, 2.15), 0.22)
	for _, sx in ipairs({-1, 1}) do tube("LeadingEdge", Vector3.new(0, -0.05, -4.95), Vector3.new(sx * 6.4, 0.3, 1.4), 0.2) end
	local hangPt = Vector3.new(0, -0.12, -1.0)
	local barL = O:PointToObjectSpace(hrp.CFrame:PointToWorldSpace(Vector3.new(-gripX - 0.3, barY, barZ)))
	local barR = O:PointToObjectSpace(hrp.CFrame:PointToWorldSpace(Vector3.new(gripX + 0.3, barY, barZ)))
	tube("DownTube", hangPt, barL, 0.16); tube("DownTube", hangPt, barR, 0.16)
	tube("BaseBar", barL, barR, 0.18)
	local snd = Instance.new("Sound"); snd.Name = "Wind"; snd.SoundId = G:GetAttribute("WindSound") or ""; snd.Looped = true
	snd.Volume = G:GetAttribute("WindVolume") or 0.3; snd.PlaybackSpeed = 0.85
	snd.RollOffMode = Enum.RollOffMode.InverseTapered; snd.RollOffMinDistance = 8; snd.RollOffMaxDistance = 90; snd.Parent = sail
	snd:Play()
	for _, sx in ipairs({-1, 1}) do
		local tip = Vector3.new(sx * 6.5, 0.42, 1.45) - SAIL_C
		local a0 = Instance.new("Attachment"); a0.Name = "TipA"; a0.Position = tip; a0.Parent = sail
		local a1 = Instance.new("Attachment"); a1.Name = "TipB"; a1.Position = tip + Vector3.new(0, 0.16, 0); a1.Parent = sail
		local tr = Instance.new("Trail"); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.7; tr.MinLength = 0.1
		tr.Color = ColorSequence.new(Color3.fromRGB(255, 250, 236)); tr.Transparency = NumberSequence.new(0.3, 1)
		tr.LightEmission = 0.4; tr.FaceCamera = true; tr.WidthScale = NumberSequence.new(1, 0.25); tr.Parent = sail
	end
	M.Parent = char
	local h = hrp.CFrame:PointToObjectSpace(O:PointToWorldSpace(hangPt))
	return M, h.Y, h.Z, up, spread, (barL + barR) / 2, hrp.CFrame:ToObjectSpace(O)
end

-- THE POSE, done here so everyone sees it (a joint changed on a client stays on that client). Older rigs pose a Motor6D
-- by its C0; this game's avatars hang limbs on AnimationConstraints, whose C0 is read-only, so the turn goes onto the
-- parent-side attachment instead (the zipline learned that one: riders once hung by their hair).
local function pose(char, r, up, spread)
	local list = {
		{part = "LeftUpperArm",  joint = "LeftShoulder",  turn = armTurn(1, up, spread)},
		{part = "RightUpperArm", joint = "RightShoulder", turn = armTurn(-1, up, spread)},
		{part = "LeftUpperLeg",  joint = "LeftHip",       turn = CFrame.Angles(HIP, 0, 0)},
		{part = "RightUpperLeg", joint = "RightHip",      turn = CFrame.Angles(HIP, 0, 0)},
		{part = "LeftLowerLeg",  joint = "LeftKnee",      turn = CFrame.Angles(KNEE, 0, 0)},
		{part = "RightLowerLeg", joint = "RightKnee",     turn = CFrame.Angles(KNEE, 0, 0)},
	}
	for _, p in ipairs(list) do
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
			end
		end
	end
end

local function start(player)
	if flying[player] then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or hum.Health <= 0 then return end
	if (player:GetAttribute("Item_glider") or 0) <= 0 then ev:FireClient(player, "shop") return end
	if (player:GetAttribute("Found_village") or 0) < need() then
		ev:FireClient(player, "no", string.format("The Chateau is not open to you yet. Find %d in the Rue first.", need()))
		return
	end
	if player:GetAttribute("Climbing") then ev:FireClient(player, "no", "Ring the bell first - your climb's clock is still running!") return end
	if player:GetAttribute("Racing") then ev:FireClient(player, "no", "Finish your Forest Race first!") return end
	local back = Vector3.new(G:GetAttribute("RampX"), G:GetAttribute("RampY"), G:GetAttribute("RampZ"))
	local flat = (hrp.Position - back) * Vector3.new(1, 0, 1)
	if flat.Magnitude > 13 or math.abs(hrp.Position.Y - back.Y) > 7 then
		ev:FireClient(player, "no", "Take off from the ramp at the top of the Sandstone Climb.")
		return
	end
	hum:UnequipTools()
	local r = {char = char, c0 = {}, att = {}}
	flying[player] = r
	local model, hangY, hangZ, up, spread, bar, oRel = buildGlider(char, hrp)
	r.model = model; r.bar = bar                        -- (the bar's middle in the glider's frame: what it rests on after)
	r.oRel, r.hrp = oRel, hrp                           -- (where the glider sits on the pilot)
	pose(char, r, up, spread)
	hum.PlatformStand = true
	char:SetAttribute("Gliding", true)
	ev:FireClient(player, "go", hangY, hangZ)
	-- if the client never reports back (crashed, lagged out, tampered), take it all back anyway
	task.delay((G:GetAttribute("MaxSeconds") or 45) + 15, function() if flying[player] == r then finish(player) end end)
end

PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "TakeOff" and prompt:IsDescendantOf(G) then start(player) end
end)
ev.OnServerEvent:Connect(function(player, what, how, heading, speed, hrpCF)
	if what == "done" then
		finish(player, how, heading, speed, hrpCF)
		if how then print(string.format("HangGlider: %s - %s", player.Name, tostring(how))) end
	end
end)
Players.PlayerRemoving:Connect(finish)
local function watch(player) player.CharacterRemoving:Connect(function() finish(player) end) end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
local dbg = G:FindFirstChild("GliderDebugStart")
if dbg and RunService:IsStudio() then dbg.Event:Connect(start) end
print("HangGlider: ready")
]==]

	-- ---------------------------------------------------------------- the client: the flight ----
	local CLIENT = [==[
-- GliderClient: the take-off run, the glide (steering, diving, leaning), landing, letting go - and the prompt's words
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local G = script.Parent
local ev = RS:WaitForChild("GliderEvent")
local C = Color3.fromRGB
local NAVY, CREAM = C(38, 30, 52), C(255, 246, 220)

-- the note at the foot of the screen, in the climb's and the Forest Race's colours - but 26 px lower than theirs: on an
-- iPhone 7 at -110 it came down 8 px over the title banner ("A section complete!", y 112..232 there); at -84 it sits
-- between the banner and the hotbar (y 250..290 there; the hotbar starts at 298), clear of the joystick and jump button
-- at the sides (measured in the Device Simulator, Sep 27)
local gui = Instance.new("ScreenGui"); gui.Name = "GliderGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 16
gui.Parent = player:WaitForChild("PlayerGui")
local note = Instance.new("TextLabel"); note.Name = "Note"; note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -84)
note.Size = UDim2.fromOffset(420, 40); note.BackgroundColor3 = NAVY; note.BackgroundTransparency = 1; note.BorderSizePixel = 0
note.Font = Enum.Font.FredokaOne; note.TextSize = 18; note.TextColor3 = CREAM; note.TextTransparency = 1; note.TextWrapped = true; note.Text = ""
note.Parent = gui
local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 12); nc.Parent = note
local noteAt, fade = 0, nil
local function say(t, secs)
	if fade then fade:Cancel(); fade = nil end              -- (a fade still running from the last note hid the next one)
	note.Text = t; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); noteAt = mine
	task.delay(secs or 3.2, function()
		if noteAt ~= mine then return end
		fade = TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}); fade:Play()
	end)
end

-- the prompt says what it will do for you: take off if the glider is yours, otherwise where one is sold
local flying = false
local function prompt() return G:FindFirstChild("TakeOff", true) end
local function refreshPrompt()
	local p = prompt(); if not p then return end
	local shop = workspace:FindFirstChild("Shop")
	local price = shop and shop:GetAttribute("Price_glider")
	local was = p.ActionText
	if (player:GetAttribute("Item_glider") or 0) > 0 then
		p.ActionText = "Take off"; p.ObjectText = "Hang glider"
	else
		p.ActionText = "See it in the Acorn Store"; p.ObjectText = price and ("Hang glider - " .. tostring(price) .. " acorns") or "Hang glider"
	end
	-- the prompt pills draw their words when they appear, so one already showing (you bought the glider standing at the
	-- ramp) is hidden and shown again to say the new thing
	if was ~= p.ActionText and p.Enabled and not flying then
		p.Enabled = false
		task.delay(0.15, function() if not flying then p.Enabled = true end end)
	end
end
refreshPrompt()
player:GetAttributeChangedSignal("Item_glider"):Connect(refreshPrompt)
task.delay(3, refreshPrompt)

-- where a glider may be: x0,x1,z0,z1 per zone
local function zones()
	local out = {}
	for chunk in string.gmatch(G:GetAttribute("Zones") or "", "[^;]+") do
		local a, b, c, d = chunk:match("([^,]+),([^,]+),([^,]+),([^,]+)")
		if a then table.insert(out, {tonumber(a), tonumber(b), tonumber(c), tonumber(d)}) end
	end
	return out
end
local function inside(zs, p)
	if #zs == 0 then return true end
	for _, z in ipairs(zs) do
		if p.X >= z[1] and p.X <= z[2] and p.Z >= z[3] and p.Z <= z[4] then return true end
	end
	return false
end

local BIND = "HangGlider"
local bound = false
local function unbind() if bound then RunService:UnbindFromRenderStep(BIND); bound = false end end

local function fly(hangY, hangZ)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum) or flying then ev:FireServer("done") return end
	flying = true
	hum.PlatformStand = true
	local tp = prompt(); if tp then tp.Enabled = false end
	local back = Vector3.new(G:GetAttribute("RampX"), G:GetAttribute("RampY"), G:GetAttribute("RampZ"))
	local dir = Vector3.new(G:GetAttribute("RampDirX"), 0, G:GetAttribute("RampDirZ")).Unit
	local LEN, DROP = G:GetAttribute("RampLength") or 12, G:GetAttribute("RampDrop") or 1
	local legs = hum.HipHeight + hrp.Size.Y / 2
	local V, S = G:GetAttribute("Speed") or 32, G:GetAttribute("Sink") or 5.8
	local DV, DS = G:GetAttribute("DiveSpeed") or 40, G:GetAttribute("DiveSink") or 14
	local TURN = math.rad(G:GetAttribute("TurnRate") or 80)
	local MAXT = G:GetAttribute("MaxSeconds") or 45
	local zs = zones()
	local hang = Vector3.new(0, hangY or 4.5, hangZ or 0)                       -- the hang point, in the root's frame
	local function deck(s) return back.Y + 0.42 - DROP * math.clamp(s, 0, LEN) / LEN end
	local startCF = hrp.CFrame
	local S0, RUN_V = -0.8, 24                                                   -- the run starts just behind the arch; off the lip at 24
	local runT = 2 * (LEN - S0) / RUN_V
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true; rp.IgnoreWater = false
	local function refreshFilter()
		local skip = {}
		for _, pl in ipairs(Players:GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
		rp.FilterDescendantsInstances = skip
	end
	refreshFilter()
	local heading, v, w = dir, RUN_V, 0
	local hp, bank, pitch = nil, 0, 0
	local t0, lastFilter = os.clock(), os.clock()
	local letGo, ended = false, false
	-- LET GO: jump, any time after the lip (the jump key or the phone's jump button; the humanoid's Jump is watched too)
	local function wantOff() if os.clock() - t0 > runT + 0.3 then letGo = true end end
	local c1 = UIS.JumpRequest:Connect(wantOff)
	local c2 = hum:GetPropertyChangedSignal("Jump"):Connect(function() if hum.Jump then wantOff() end end)
	local function stop(how, vel)
		if ended then return end
		ended = true
		unbind(); c1:Disconnect(); c2:Disconnect()
		flying = false
		if tp then tp.Enabled = true end
		if hrp.Parent then
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + heading)          -- upright again
			hum.PlatformStand = false
			hrp.AssemblyLinearVelocity = vel or Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			hum:ChangeState(how == "land" and Enum.HumanoidStateType.Landed or Enum.HumanoidStateType.Freefall)
		end
		ev:FireServer("done", how, heading, v, hrp.CFrame)                          -- (the glider settles from there)
	end
	-- the camera, once: from behind and above, looking the way the ramp points and down a little, so the squirrel on top
	-- of the sail shows (level with the pilot, the sail is only a thin line)
	local cam = workspace.CurrentCamera
	if cam and cam.CameraType == Enum.CameraType.Custom then
		local look = (dir * math.cos(math.rad(24)) - Vector3.new(0, math.sin(math.rad(24)), 0)).Unit
		local focus = back + Vector3.new(0, legs + 3, 0)
		cam.CFrame = CFrame.lookAt(focus - look * 14, focus)
	end
	unbind()
	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Camera.Value - 1, function(dt)
		if ended then return end
		if not hrp.Parent or hum.Health <= 0 then stop("gone") return end
		dt = math.min(dt, 0.1)
		local now = os.clock()
		local t = now - t0
		if now - lastFilter > 1 then refreshFilter(); lastFilter = now end
		if t < runT then
			-- THE RUN: onto the ramp just behind the arch, then down it with the glider overhead, faster and faster
			local s = S0 + 0.5 * (RUN_V / runT) * t * t
			local pos = back + dir * s
			local at = Vector3.new(pos.X, deck(s) + legs, pos.Z)
			local target = CFrame.lookAt(at, at + dir)
			local k = math.clamp(t / 0.3, 0, 1)
			hrp.CFrame = (k < 1) and startCF:Lerp(target, k) or target
			hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero
			return
		end
		if not hp then hp = hrp.CFrame:PointToWorldSpace(hang) end
		if letGo then stop("letgo", heading * v * 0.5 + Vector3.new(0, 6, 0)); say("You let go!", 2.2) return end
		if t > MAXT then stop("time", heading * v * 0.4) return end
		-- STEERING: the glider turns toward wherever the joystick (or the keys) point; pushing the way it is already
		-- going makes it dive
		local md = hum.MoveDirection
		local flat = Vector3.new(md.X, 0, md.Z)
		local mag = math.min(flat.Magnitude, 1)
		local turn, dive = 0, 0
		if mag > 0.15 then
			local want = flat.Unit
			local ang = math.atan2(heading:Cross(want).Y, heading:Dot(want))
			turn = math.clamp(ang, -TURN * dt, TURN * dt)
			heading = CFrame.Angles(0, turn, 0):VectorToWorldSpace(heading)
			heading = Vector3.new(heading.X, 0, heading.Z).Unit
			dive = mag * math.clamp((heading:Dot(want) - 0.75) / 0.25, 0, 1)
		end
		local airT = t - runT
		local vT = V + (DV - V) * dive
		local sT = (S + (DS - S) * dive) * math.clamp(airT / 1.0, 0, 1)            -- floats off the lip, then settles into its sink
		v = v + math.clamp(vT - v, -18 * dt, 12 * dt)
		w = w + math.clamp(sT - w, -14 * dt, 14 * dt)
		local nhp = hp + heading * (v * dt) - Vector3.new(0, w * dt, 0)
		-- lean into the turn, nose down in a dive; the pilot swings under the hang point
		bank = bank + (math.clamp((turn / dt) / TURN, -1, 1) * math.rad(28) - bank) * math.min(1, dt * 4)
		pitch = pitch + (-math.rad(12) * dive - pitch) * math.min(1, dt * 3)
		local cf = CFrame.lookAt(nhp, nhp + heading) * CFrame.Angles(pitch, 0, bank) * CFrame.new(-hang)
		local from, to = hrp.Position, cf.Position
		-- bumping into something lets go where you are
		local step = to - from
		if step.Magnitude > 0.001 then
			local hit = workspace:Spherecast(from, 1.1, step + step.Unit * 0.4, rp)
			if hit then
				local B = hit.Instance.Parent and hit.Instance.Parent.Name == "Walls" and hit.Instance.Parent.Parent
				if B and B.Name == "Boundary" then                                      -- the invisible wall round the map
					stop("edge:" .. hit.Instance:GetFullName(), Vector3.zero); say("That's the edge of the map - you let go.", 2.8)
				else
					stop("bump:" .. hit.Instance:GetFullName(), -heading * 4); say("Bump! You let go of the glider.", 2.6)
				end
				return
			end
		end
		-- so does the edge of the map
		if not inside(zs, to) then stop("edge", Vector3.zero); say("That's the edge of the map - you let go.", 2.8) return end
		-- touching down: whatever is under you - grass, the street, a roof
		if airT > 0.35 then
			local down = workspace:Raycast(to, Vector3.new(0, -(legs + 0.6), 0), rp)
			if down then
				local land = Vector3.new(to.X, down.Position.Y + legs, to.Z)
				hrp.CFrame = CFrame.lookAt(land, land + heading)
				stop("land:" .. down.Instance:GetFullName(), heading * math.min(v, 20) * 0.45)
				say(land.X < 352 and "Welcome to the Rue!" or "Touchdown!", 2.4)
				return
			end
		end
		hp = nhp
		hrp.CFrame = cf
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)
	bound = true
	local phone = UIS.TouchEnabled and not UIS.KeyboardEnabled
	say(phone and "Steer with the joystick. Jump to let go!" or "Steer with the keys. Jump to let go!", 3.4)
	task.delay(4, function() if not ended then say("Push the way you're going to dive faster.", 3.2) end end)
end

ev.OnClientEvent:Connect(function(what, a, b)
	if what == "go" then
		fly(a, b)
	elseif what == "shop" then
		local shop = workspace:FindFirstChild("Shop")
		local openAt = shop and shop:FindFirstChild("OpenAt")
		if openAt then openAt:Fire("glider") else say("The hang glider is in the Acorn Store.") end
	elseif what == "no" then
		say(a)
	end
end)

-- ---- the gliders people leave behind (GliderServer's settle) ----
-- The server only puts each one where it ends up; the move from where it was let go of to where it comes to rest is
-- drawn here, frame by frame, so it is smooth; when its time is up it fades out here too.
local landed = G:WaitForChild("Landed")
local function easeOut(u) return 1 - (1 - u) * (1 - u) end
local function easeIn(u) return u * u end
local function watchLanded(m)
	if not m:IsA("Model") then return end
	if m:GetAttribute("T0") == nil then m:GetAttributeChangedSignal("T0"):Wait() end
	local K0, K1, K2 = m:GetAttribute("K0"), m:GetAttribute("K1"), m:GetAttribute("K2")
	local T0, T1, T2 = m:GetAttribute("T0"), m:GetAttribute("T1") or 0, m:GetAttribute("T2") or 0
	if typeof(K0) ~= "CFrame" or typeof(K2) ~= "CFrame" then return end
	local mid = typeof(K1) == "CFrame" and K1 or K0
	local drop = m:GetAttribute("Drop")
	-- (seen through, it stays seen through: whatever hid it while it was part of the character - the camera close to
	-- you, say - does not follow it out)
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 end end
	local move
	move = RunService.RenderStepped:Connect(function()
		if not m.Parent then move:Disconnect() return end
		local t = workspace:GetServerTimeNow() - T0
		local cf
		if t < T1 then
			cf = K0:Lerp(mid, easeOut(math.clamp(t / T1, 0, 1)))
		elseif t < T1 + T2 then
			local u = math.clamp((t - T1) / T2, 0, 1)
			cf = mid:Lerp(K2, drop and easeIn(u) or easeOut(u))
		else
			cf = K2; move:Disconnect()
		end
		m:PivotTo(cf)
	end)
	local function fade()
		local parts = {}
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then table.insert(parts, d) end end
		local t0 = os.clock()
		local fc
		fc = RunService.RenderStepped:Connect(function()
			local k = math.clamp((os.clock() - t0) / 1.5, 0, 1)
			for _, p in ipairs(parts) do if p.Parent then p.LocalTransparencyModifier = k end end
			if k >= 1 or not m.Parent then fc:Disconnect() end
		end)
	end
	if m:GetAttribute("FadeAt") then fade() else m:GetAttributeChangedSignal("FadeAt"):Connect(fade) end
end
landed.ChildAdded:Connect(function(m) task.spawn(watchLanded, m) end)
for _, m in ipairs(landed:GetChildren()) do task.spawn(watchLanded, m) end
]==]

	local s = Instance.new("Script"); s.Name = "GliderServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "GliderClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace

	local pieces = 0
	for _, p in ipairs(F:GetDescendants()) do if p:IsA("BasePart") then pieces += 1 end end
	print(string.format("HangGlider: ramp from %.1f,%.1f heading %.2f,%.2f (%d planks, %d struts), %d pieces, boxwood removed %d, lip at %.1f,%.1f,%.1f",
		B.X, B.Z, dir.X, dir.Z, planks, struts, pieces, removed, onRamp(0, LEN).X, deckY(LEN), onRamp(0, LEN).Z))
	return F
end
