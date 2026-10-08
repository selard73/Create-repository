-- MimeHat: the hat on the ground in front of the mime, and what happens when you drop something in it.
--
-- He is a mime, so he does not say thank you. He tips his hat and produces an entirely empty speech bubble,
-- which is the joke. The acorn falls in, the hat bobs, and that is the whole transaction.
--
-- All of it happens on the BUYER'S screen only, per the rule that changes to the world are yours alone. Two
-- people tipping him at once each see their own acorn land.
--
-- The hat is placed by MEASUREMENT, not by guesswork: there is a tree directly in front of him, so the obvious
-- spot two studs ahead is inside a trunk. The builder sweeps an arc across his front and takes the first clear
-- patch of ground it finds.
-- Run in edit mode: require(workspace.MimeHat.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local mime
	for _, o in ipairs(workspace:GetDescendants()) do
		if o:IsA("Model") and o.Name == "mime_squirrel_color" then mime = o break end
	end
	assert(mime, "MimeHat: the mime is not in the workspace")

	local mn, mx
	for _, p in ipairs(mime:GetDescendants()) do
		if p:IsA("BasePart") then
			for sx = -1, 1, 2 do for sy = -1, 1, 2 do for sz = -1, 1, 2 do
				local v = (p.CFrame * CFrame.new(p.Size.X / 2 * sx, p.Size.Y / 2 * sy, p.Size.Z / 2 * sz)).Position
				mn = mn and Vector3.new(math.min(mn.X, v.X), math.min(mn.Y, v.Y), math.min(mn.Z, v.Z)) or v
				mx = mx and Vector3.new(math.max(mx.X, v.X), math.max(mx.Y, v.Y), math.max(mx.Z, v.Z)) or v
			end end end
		end
	end
	local centre = Vector3.new((mn.X + mx.X) / 2, mn.Y, (mn.Z + mx.Z) / 2)

	-- which way is he looking? the squirrels are built facing local -Z
	local mesh = mime:FindFirstChildWhichIsA("MeshPart", true)
	local face = mesh and (mesh.CFrame.LookVector * Vector3.new(1, 0, 1)) or Vector3.new(0, 0, -1)
	if face.Magnitude < 0.1 then face = Vector3.new(0, 0, -1) end
	face = face.Unit

	-- Where a busker's hat goes: on the pavement, close, ideally in front. He is hemmed in - a tree directly
	-- ahead, a scarecrow behind, a bistro table to one side - so sweep the whole circle and take whichever
	-- workable spot lies nearest his front rather than insisting on straight ahead.
	--
	-- Two tests, and only two. The ground must be LEVEL WITH HIS FEET, which is what stops the hat ending up
	-- on top of a tree root two studs in the air; and nothing solid may occupy the hat's own small volume.
	-- An earlier version demanded a metre and a half of clear space in every direction, which is right for a
	-- table and absurd for a hat, and it found nowhere at all.
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	local best, bestScore, found
	for deg = 0, 350, 10 do
		for _, r in ipairs({1.9, 2.3, 2.8, 3.3}) do
			local dir = CFrame.Angles(0, math.rad(deg), 0):VectorToWorldSpace(face)
			local at = centre + dir * r
			-- Step DOWN through whatever is overhead. He stands under a plane tree, so a ray dropped from above
			-- stops in the canopy and never reaches the pavement - which is why the whole arc in front of him
			-- looked unusable. Keep going until a surface turns up at his own feet level.
			local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
			local skip, hit = {}, nil
			for pass = 1, 10 do
				rp.FilterDescendantsInstances = skip
				local h = workspace:Raycast(at + Vector3.new(0, 9, 0), Vector3.new(0, -18, 0), rp)
				if not h then break end
				if h.Normal.Y > 0.9 and math.abs(h.Position.Y - mn.Y) < 0.5 then hit = h break end
				table.insert(skip, h.Instance)
			end
			if hit then
				op.FilterDescendantsInstances = {mime, hit.Instance}
				-- PAVING IS NOT AN OBSTACLE. The plaza here is several overlapping flat slabs - Square, PlotN -
				-- and excluding only the one the ray happened to land on left the others looking like walls, so
				-- every direction round him reported "blocked" and the hat could go nowhere at all. Anything
				-- whose top is level with the floor is floor; only what stands proud of it is in the way.
				local blocked = false
				for _, t in ipairs(workspace:GetPartBoundsInRadius(hit.Position + Vector3.new(0, 0.6, 0), 0.95, op)) do
					if t.Position.Y + t.Size.Y / 2 > hit.Position.Y + 0.35 then blocked = true break end
				end
				if not blocked then
					-- nearest his front wins, and nearer to him beats further away
					local turn = math.min(deg, 360 - deg)
					local score = turn + r * 6
					if not best or score < bestScore then
						best, bestScore = hit.Position, score
						found = string.format("%d degrees off his front, %.1f studs out", turn, r)
					end
				end
			end
		end
	end
	local spot = best
	assert(spot, "MimeHat: nowhere clear in front of him to put a hat")

	local oldHat = workspace:FindFirstChild("MimeHat"); if oldHat then oldHat:Destroy() end
	local hat = Instance.new("Model"); hat.Name = "MimeHat"

	-- THE SHAPE. Stacking cylinders produced something that read as a tin, and most store models cannot be
	-- fetched by script at all ("User is not authorized to access Asset" - LoadAsset only reaches assets you
	-- own). This one can, and it is better than a beret for the job: an upside-down top hat, which is already
	-- the right way up to catch what falls in it.
	-- Order of preference: a hat mesh already sitting in the workspace, then the asset, then a built shape.
	local ASSET = opts.hat or 14112038337
	local source, how

	for _, o in ipairs(workspace:GetDescendants()) do
		local n = o.Name:lower()
		if o:IsA("MeshPart") and o.MeshId ~= "" and (n:find("beret") or n:find("hat")) and not o:IsDescendantOf(workspace:FindFirstChild("MimeHat") or workspace) then
			source, how = o, "a hat mesh found in the workspace"
			break
		end
	end

	local loaded
	if not source then
		pcall(function() loaded = game:GetService("InsertService"):LoadAsset(ASSET) end)
		if loaded then
			for _, q in ipairs(loaded:GetDescendants()) do
				if q:IsA("MeshPart") and q.MeshId ~= "" then source, how = q, "asset " .. ASSET break end
			end
		end
	end

	local brim
	local FELT, SHADOW, BAND = Color3.fromRGB(30, 28, 34), Color3.fromRGB(18, 17, 22), Color3.fromRGB(96, 62, 38)
	if source then
		brim = source:Clone()
		for _, c in ipairs(brim:GetChildren()) do c:Destroy() end
		brim.Name = "Brim"; brim.Color = FELT; brim.Material = Enum.Material.SmoothPlastic
		brim.Anchored = true; brim.CanCollide = false; brim.CanTouch = false; brim.CanQuery = false
		local widest = math.max(brim.Size.X, brim.Size.Z)
		if widest > 0.05 then brim.Size = brim.Size * (3.4 / widest) end
		-- NOT turned over: the asset is an upside-down top hat already, and flipping it would stand it back up
		brim.CFrame = CFrame.new(spot + Vector3.new(0, brim.Size.Y / 2, 0))
		brim.Parent = hat
	else
		local function dome(name, sx, sy, sz, y, colour)
			local p = Instance.new("Part")
			p.Name = name; p.Size = Vector3.new(1, 1, 1); p.Color = colour
			p.Material = Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = false
			p.CanTouch = false; p.CanQuery = false
			p.CFrame = CFrame.new(spot + Vector3.new(0, y, 0))
			local m = Instance.new("SpecialMesh")
			m.MeshType = Enum.MeshType.Sphere; m.Scale = Vector3.new(sx, sy, sz); m.Parent = p
			p.Parent = hat
			return p
		end
		brim = dome("Brim", 3.2, 1.15, 3.2, 0.30, FELT)        -- the crown, pressed flat, sitting upside down
		dome("Lip", 3.55, 0.34, 3.55, 0.56, FELT)              -- the soft edge, overhanging all the way round
		dome("Band", 2.5, 0.26, 2.5, 0.62, BAND)               -- the leather band, now facing the sky
		dome("Inside", 2.25, 0.5, 2.25, 0.48, SHADOW)          -- the hollow it catches things in
	end
	if loaded then loaded:Destroy() end
	for _, o in ipairs(workspace:GetChildren()) do
		if o.Name == "HatSource" then o:Destroy() end        -- leftovers from testing the insert
	end
	local rest = source and brim.Size.Y or 0.66

	-- a couple already in it, so what it is for needs no explaining
	local rng = Random.new(4821)
	for i = 1, 2 do
		local ac = Instance.new("Part")
		ac.Name = "Caught" .. i
		ac.Shape = Enum.PartType.Ball; ac.Size = Vector3.new(0.44, 0.44, 0.44)
		ac.Color = Color3.fromRGB(206, 146, 82); ac.Material = Enum.Material.SmoothPlastic
		ac.Anchored = true; ac.CanCollide = false; ac.CanTouch = false; ac.CanQuery = false
		local ang = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(0.15, 0.55)
		ac.CFrame = CFrame.new(spot + Vector3.new(math.cos(ang) * r, rest + 0.12, math.sin(ang) * r))
		ac.Parent = hat
	end

	hat.PrimaryPart = brim
	hat.Parent = workspace

	-- You tip him AT the hat, not from a menu three maps away. Buying it from the forest meant he raised his
	-- hat to an empty street and the buyer saw nothing at all, which is the whole point of the thing.
	-- PromptUI restyles every ProximityPrompt in the workspace, so this picks up the game's own look and its
	-- touch handling without asking.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TipPrompt"
	prompt.ActionText = "Tip the mime"
	prompt.ObjectText = "3 acorns"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false          -- it lies on the ground among the cafe furniture
	-- the label floats above whatever it is attached to, and the beret is at his feet, so without this
	-- it hangs squarely over the mime and hides the person you are trying to tip
	prompt.UIOffset = Vector2.new(0, 78)
	prompt:SetAttribute("ShopItem", "tip")      -- what ShopServer should charge for when it fires
	prompt.Parent = brim
	hat:SetAttribute("Facing", face.X .. "," .. face.Z)

	-- ---------------------------------------------------------------- the reaction ----
	local F = workspace:FindFirstChild("Shop")
	assert(F, "MimeHat: run build_shop first")
	local oldC = F:FindFirstChild("MimeClient"); if oldC then oldC:Destroy() end
	local CLIENT = [==[
-- What the mime does when you tip him. Entirely on the tipper's own screen.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer

local hat = workspace:WaitForChild("MimeHat", 30)
if not hat then return end
local brim = hat:FindFirstChild("Brim")
if not brim then return end

local base = {}
for _, p in ipairs(hat:GetChildren()) do
	if p:IsA("BasePart") then base[p] = p.CFrame end
end
local centre = brim.Position

local function bob()
	-- The beret is swept up, turned and replaced. It was a small tilt before and nobody noticed it at all, so
	-- now it leaves the ground properly. Each part moves from its OWN resting CFrame, so repeated tips cannot
	-- walk the hat across the pavement.
	for p, home in pairs(base) do
		local lifted = CFrame.new(centre + Vector3.new(0, 2.2, 0))
			* CFrame.Angles(0, math.rad(210), math.rad(26))
			* CFrame.new(-centre)
			* home
		TweenService:Create(p, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{CFrame = lifted}):Play()
		task.delay(0.52, function()
			TweenService:Create(p, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{CFrame = home}):Play()
		end)
	end
	-- and a burst, because a small movement at your feet is easy to miss while you are looking at the mime
	local fx = Instance.new("Part")
	fx.Size = Vector3.new(0.2, 0.2, 0.2); fx.Transparency = 1; fx.Anchored = true
	fx.CanCollide = false; fx.CanQuery = false; fx.CanTouch = false
	fx.CFrame = CFrame.new(centre + Vector3.new(0, 0.8, 0)); fx.Parent = workspace
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 226, 150))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0)})
	pe.Lifetime = NumberRange.new(0.5, 1); pe.Speed = NumberRange.new(4, 9)
	pe.SpreadAngle = Vector2.new(180, 180); pe.Rate = 0; pe.LightEmission = 0.9
	pe.Parent = fx
	pe:Emit(26)
	Debris:AddItem(fx, 2.5)
end

local function acornIn()
	-- one acorn, falling into the hat
	local a = Instance.new("Part")
	a.Shape = Enum.PartType.Ball; a.Size = Vector3.new(0.5, 0.5, 0.5)
	a.Color = Color3.fromRGB(206, 146, 82); a.Material = Enum.Material.SmoothPlastic
	a.Anchored = true; a.CanCollide = false; a.CanTouch = false; a.CanQuery = false
	a.CFrame = CFrame.new(centre + Vector3.new(0, 5.5, 0))
	a.Parent = workspace
	TweenService:Create(a, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{CFrame = CFrame.new(centre + Vector3.new(0, 0.55, 0))}):Play()   -- down into the bowl
	Debris:AddItem(a, 1.2)
end

local function bubble()
	-- A mime does not say thank you. He produces a speech bubble with nothing whatsoever in it.
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.2, 0.2, 0.2); part.Transparency = 1; part.Anchored = true
	part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
	part.CFrame = CFrame.new(centre + Vector3.new(0, 5.2, 0))
	part.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(132, 96); bb.AlwaysOnTop = true; bb.Parent = part
	local box = Instance.new("Frame")
	box.Size = UDim2.fromScale(1, 0.78); box.BackgroundColor3 = Color3.fromRGB(252, 250, 244)
	box.BorderSizePixel = 0; box.Parent = bb
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = box
	local st = Instance.new("UIStroke"); st.Color = Color3.fromRGB(60, 52, 44); st.Thickness = 2; st.Parent = box
	local tail = Instance.new("Frame")
	tail.AnchorPoint = Vector2.new(0.5, 0); tail.Position = UDim2.fromScale(0.34, 0.74)
	tail.Size = UDim2.fromOffset(13, 13); tail.Rotation = 45
	tail.BackgroundColor3 = Color3.fromRGB(252, 250, 244); tail.BorderSizePixel = 0; tail.Parent = bb
	local ts = Instance.new("UIStroke"); ts.Color = Color3.fromRGB(60, 52, 44); ts.Thickness = 2; ts.Parent = tail
	for _, o in ipairs({box, tail}) do
		TweenService:Create(o, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 2.4),
			{BackgroundTransparency = 1}):Play()
	end
	TweenService:Create(st, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 2.4),
		{Transparency = 1}):Play()
	TweenService:Create(ts, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 2.4),
		{Transparency = 1}):Play()
	Debris:AddItem(part, 5)
end

local function thanks()
	warn("QQ MIME - tip registered on this client; playing the thank you")
	acornIn()
	task.delay(0.42, bob)
	task.delay(0.6, bubble)
end

-- Only when the count goes UP. The attribute is also written when the save loads, and a player rejoining with
-- forty tips behind them should not be met by a hat having a fit.
warn("QQ MIME - watching for tips; you have given " .. tostring(player:GetAttribute("Item_tip") or 0) .. " so far")
local last = player:GetAttribute("Item_tip") or 0
player:GetAttributeChangedSignal("Item_tip"):Connect(function()
	local now = player:GetAttribute("Item_tip") or 0
	if now > last then thanks() end
	last = now
end)
]==]
	local c = Instance.new("Script"); c.Name = "MimeClient"; c.RunContext = Enum.RunContext.Client
	c.Source = CLIENT; c.Parent = F

	print(string.format("MimeHat: %s, at %.1f,%.1f,%.1f (%s from the mime at %.0f,%.0f)",
		how or "built from spheres", spot.X, spot.Y, spot.Z, found, centre.X, centre.Z))
end
