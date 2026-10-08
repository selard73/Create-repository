-- AcornModel: the collectible itself. Built from parts rather than a mesh so it matches the low-poly world and
-- costs almost nothing: a tan nut, a ridged brown cap, a little stem, and one oversized invisible hitbox.
--
-- It LIES ON ITS SIDE, the way an acorn that has fallen actually rests, and each one is turned a different way so a
-- row of them does not read as a row of skittles. The first version stood upright and was well over twice this
-- size, which made it look planted rather than dropped.
--
-- Two placement traps, both of which put acorns in the wrong place once already:
--   * The tilt is applied when the acorn is PLACED, not baked into the parts. PivotTo moves a model rigidly so
--     that its pivot lands on the CFrame you give it, so a tilt baked into the parts is simply cancelled out by
--     the next PivotTo and the acorn stands up again.
--   * The pivot is the NUT, not the hitbox. The hitbox reaches high above the acorn to catch someone walking over
--     it, so pivoting on that would bury the acorn a couple of studs underground.
--
-- It is NOT animated from the server. Twenty acorns turning on the server is twenty parts of network traffic every
-- frame for something purely decorative; the client spins its own copies instead and the server's stay still. That
-- is also why the hitbox is far bigger than the acorn: you walk INTO an acorn, you do not thread a needle.
-- Run in edit mode: require(workspace.AcornModel.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local NUT = Color3.fromRGB(206, 146, 82)               -- the same tan and brown as the acorn in the HUD, so the
	local CAP = Color3.fromRGB(110, 70, 40)                -- counter in the corner and the thing on the ground
	local STEM = Color3.fromRGB(86, 56, 34)                -- are recognisably the same object

	local S = opts.scale or 0.40
	local REST = 0.75 * S                                  -- tipped over, the nut's belly is one radius down

	local function part(name, shape, size, colour, localCF, parent)
		local p = Instance.new("Part")
		p.Name = name; p.Shape = shape; p.Size = size * S; p.Color = colour
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = localCF
		p.Parent = parent
		return p
	end

	local old = game:GetService("ServerStorage"):FindFirstChild("AcornTemplate")
	if old then old:Destroy() end
	local m = Instance.new("Model"); m.Name = "AcornTemplate"

	-- modelled upright about the nut's centre. Cylinders run along X, hence the quarter turn that stands each on end.
	local UP = CFrame.Angles(0, 0, math.rad(90))
	local nut = part("Nut", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5), NUT, CFrame.new(), m)
	part("Cap", Enum.PartType.Cylinder, Vector3.new(0.55, 1.7, 1.7), CAP, CFrame.new(0, 0.62 * S, 0) * UP, m)
	part("Lip", Enum.PartType.Cylinder, Vector3.new(0.22, 1.42, 1.42), CAP, CFrame.new(0, 0.94 * S, 0) * UP, m)
	part("Stem", Enum.PartType.Cylinder, Vector3.new(0.42, 0.28, 0.28), STEM, CFrame.new(0, 1.18 * S, 0) * UP, m)

	-- the hitbox reaches well above the acorn, because a box the size of the acorn sits below the soles of your
	-- feet and you walk straight over the top of it without ever touching it
	local box = Instance.new("Part")
	box.Name = "Hit"; box.Size = Vector3.new(4.5, 8, 4.5); box.CFrame = CFrame.new(0, 2.6, 0)
	box.Transparency = 1; box.Anchored = true; box.CanCollide = false; box.CanTouch = true; box.CanQuery = false
	box.Parent = m
	m.PrimaryPart = nut                                    -- the NUT, so PivotTo puts the acorn where it is asked

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 214, 140); light.Brightness = 1.2; light.Range = 7; light.Shadows = false
	light.Parent = nut

	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 236, 170))
	sparkle.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0)})
	sparkle.Transparency = NumberSequence.new(0.4)
	sparkle.Lifetime = NumberRange.new(0.4, 0.8); sparkle.Rate = 4; sparkle.Speed = NumberRange.new(0.3, 0.7)
	sparkle.SpreadAngle = Vector2.new(180, 180); sparkle.LightEmission = 0.8
	sparkle.Parent = nut
	m:SetAttribute("Rest", REST)
	m.Parent = game:GetService("ServerStorage")

	-- the one way to place an acorn, used by the preview here and by the server at run time, so the two can never
	-- drift apart: on its side, turned a different way each time, belly resting on the surface
	local function lieAt(model, surface, yaw)
		model:PivotTo(CFrame.new(surface + Vector3.new(0, REST, 0))
			* CFrame.Angles(0, yaw, 0)
			* CFrame.Angles(math.rad(90), 0, 0))
	end

	-- ---------------------------------------------------------------- a preview to look at ----
	local prev = workspace:FindFirstChild("AcornPreview"); if prev then prev:Destroy() end
	local shown = 0
	if opts.preview then
		local spots = workspace:FindFirstChild("AcornSpots")
		assert(spots, "AcornModel: run build_acorn_spots first")
		local rng = Random.new(opts.seed or 771)
		local F = Instance.new("Folder"); F.Name = "AcornPreview"; F.Parent = workspace
		for _, at in ipairs(spots:GetChildren()) do
			local c = m:Clone()
			c.Name = "Acorn_" .. at.Name
			lieAt(c, at.Position, rng:NextNumber(0, math.pi * 2))
			c.Parent = F
			shown += 1
		end
	end

	print(string.format("AcornModel: scale %.2f, lying over, nut resting %.2f above the surface%s",
		S, REST, shown > 0 and string.format("; %d placed for preview", shown) or ""))
	return m, lieAt
end
