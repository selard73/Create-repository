-- install_birds1.lua (Studio EDIT mode; re-runnable; its body also runs as a play-test PREVIEW). Job 100: ambient birds (Shannon,
-- Oct 15 2026: "and some birds?"): gulls circling the harbour and the lighthouse, swallows darting over the French village in
-- figure-eights; purely visual, client-side (nothing replicates, nothing to touch), flocks asleep while the camera is far.
-- workspace.Birds: BirdsClient (18905 chars) + attributes Enabled, Sites (JSON: name, kind, x, y, z, r, n, band, range - edit
-- the attribute in Studio to move a flock, no code). Undo: delete workspace.Birds. No DataStore, no publish. "QQ BIRDS".
local SS = game:GetService("ServerStorage")
local CLIENT = [===[
-- BirdsClient (workspace.Birds, RunContext Client): ambient birds (Shannon, Oct 15 2026: "and some birds?"; then "on the italy
-- map we should have some mesh seaguls and maybe a pelican"). Gulls circle the harbour and the lighthouse, gliding between bouts
-- of flapping; one pelican glides low and slow over the harbour water; swallows dart over the French village in figure-eights.
-- No gameplay, nothing to touch. Every bird is made and moved on THIS client only - the server never sees them and nothing
-- replicates - so a flock costs a few CFrame writes a frame. A site sleeps while the camera is farther than its Range (the birds
-- park out of sight), so phones only move the flock they can see.
-- THE LOOK (v3, Oct 15: Shannon's Meshy pelican and gull, rigged by runner 7 - see tools/birds/RIG_NOTES_2026-10-15.md): two kinds of
-- site. FLYING flocks (circles, figure-eights) use a part-built bird - a body, two wings with dark tips (gull), a long bill (pelican),
-- a forked dart (swallow) - unless a wings-spread mesh named Templates.<Kind>Flying exists (facing -Z; parts named LeftWing /
-- RightWing flap). PERCHED birds (site.perch = true: a pelican on the quay, gulls on a railing) use the mesh template
-- Templates.<Kind> (Gull, Pelican: a standing bird with folded wings, facing -Z; its BONES are driven here: Wing.L/.R and
-- WingTip.L/.R flap to 55 degrees about the model's +Z, Head turns about +Y and nods about +X, Jaw opens about +X (pelican's
-- gulp), Thigh.L/.R swing about +X and Body rolls about +Z for the waddle - the ranges runner 7 tested) or, without a template, a
-- part-built bird standing with folded wings. Perched birds idle: look about, preen-flap, waddle on the spot, gulp.
-- Sites come from the folder's attribute Sites (JSON; the installer writes them): [{name, kind = "gull" | "pelican" | "swallow",
-- x, y, z, r, n, band, range}] for a flock (x/z the centre, y the flight height, r the radius, n the birds, band the vertical
-- spread, range the camera distance that wakes the site) and [{name, kind, perch = true, x, y, z, yaw, n, gap, height, range}]
-- for perched birds (x/y/z the first bird's feet, yaw its facing in degrees, n birds spaced gap studs to its right, height the
-- bird's standing height in studs). Edit the attribute in Studio to move a bird; no code.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local F = script.Parent
local C = Color3.fromRGB
local KIND = {
	gull = {stand = 1.9, span = 3.0, body = Vector3.new(0.6, 0.42, 1.6), bodyColor = C(246, 246, 242), wingColor = C(214, 216, 220), tipColor = C(70, 72, 78), speed = 0.2, flap = 1.4, glide = true, bank = 14},
	pelican = {stand = 4.2, span = 5.0, body = Vector3.new(0.9, 0.7, 2.6), bodyColor = C(238, 232, 220), wingColor = C(200, 196, 188), tipColor = C(60, 58, 56), speed = 0.1, flap = 0.9, glide = true, bank = 8, bill = true},
	swallow = {stand = 0.9, span = 1.9, body = Vector3.new(0.3, 0.22, 0.8), bodyColor = C(34, 38, 56), wingColor = C(28, 30, 46), tipColor = nil, speed = 0.38, flap = 3.2, glide = true, bank = 18},   -- (v6, Shannon: "too many and too quickly ... The Birds" - a lazy glide now, with bouts of flapping)
}
local function part(size, color, parent, shape)
	local p = Instance.new("Part"); p.Size = size; p.Color = color; p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = parent
	return p
end
local folder = workspace:FindFirstChild("Birds_local") or Instance.new("Folder")
folder.Name = "Birds_local"; folder:ClearAllChildren(); folder.Parent = workspace
local function sites()
	local ok, t = pcall(function() return HttpService:JSONDecode(F:GetAttribute("Sites") or "[]") end)
	return (ok and type(t) == "table") and t or {}
end
local function templateFor(kind, suffix)
	local T = F:FindFirstChild("Templates")
	local t = T and T:FindFirstChild(kind:sub(1, 1):upper() .. kind:sub(2) .. (suffix or ""))
	if t and (t:IsA("Model") or t:IsA("BasePart")) then return t end
	return nil
end
-- a bird: {root = the part the body follows, wings = {{part, side, hinge offset}}, offset = root's pose relative to the flight CFrame}
local function makePartBird(k, parent)
	local root = part(k.body, k.bodyColor, parent)
	local wings = {}
	local half = k.span / 2
	local wingW = half - k.body.X / 2
	for _, side in ipairs({-1, 1}) do
		local w = part(Vector3.new(wingW, 0.06, k.body.Z * 0.42), k.wingColor, parent)
		w:SetAttribute("Side", side)
		table.insert(wings, {part = w, side = side, len = wingW, z = 0})
		if k.tipColor then
			local tip = part(Vector3.new(wingW * 0.3, 0.07, k.body.Z * 0.3), k.tipColor, parent)
			table.insert(wings, {part = tip, side = side, len = wingW, z = 0, tip = true})
		end
	end
	local extra = {}
	if k.bill then
		table.insert(extra, {part = part(Vector3.new(0.22, 0.2, 1.1), C(236, 190, 110), parent), cf = CFrame.new(0, -0.05, -(k.body.Z / 2 + 0.5))})
		table.insert(extra, {part = part(Vector3.new(0.26, 0.26, 0.5), C(60, 58, 56), parent), cf = CFrame.new(0, 0.05, -(k.body.Z / 2 + 0.1))})   -- the dark head
	end
	return {root = root, wings = wings, extra = extra, template = false}
end
local function makeTemplateBird(k, tpl, parent)
	local c = tpl:Clone(); c.Name = "Bird"; c.Parent = parent
	local parts, wings = {}, {}
	for _, d in ipairs(c:IsA("BasePart") and {c} or c:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; table.insert(parts, d) end
	end
	if c:IsA("Model") then
		local _, size = c:GetBoundingBox()
		if size.X > 0.01 then pcall(function() c:ScaleTo(c:GetScale() * k.span / size.X) end) end
	end
	local root = c:IsA("BasePart") and c or (c.PrimaryPart or parts[1])
	if not root then c:Destroy(); return makePartBird(k, parent) end
	local base = root.CFrame
	local rel = {}
	for _, d in ipairs(parts) do
		if d ~= root then
			local hinge = (d.Name == "LeftWing" or d.Name == "RightWing") and ((d.Name == "LeftWing") and -1 or 1) or nil
			table.insert(rel, {part = d, cf = base:ToObjectSpace(d.CFrame), side = hinge})
		end
	end
	return {root = root, rel = rel, template = true, model = c}
end
local flocks = {}
-- ---------- perched birds ----------
local BONES = {"Wing.L", "Wing.R", "WingTip.L", "WingTip.R", "Head", "Neck", "Neck1", "Jaw", "Thigh.L", "Thigh.R", "Body"}
local function makePerchBird(k, tpl, site, cf, parent)
	-- cf: the bird's feet on the perch, facing -Z. Returns {model, bones = {name -> {bone, axes = {X, Y, Z}}}, boned}
	local b = {bones = {}, boned = false}
	local height = tonumber(site.height) or k.stand
	if tpl then
		local c = tpl:Clone(); c.Name = "Bird"
		for _, d in ipairs(c:IsA("BasePart") and {c} or c:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false end
		end
		c.Parent = parent
		if c:IsA("Model") then
			local _, size = c:GetBoundingBox()
			if size.Y > 0.01 then pcall(function() c:ScaleTo(c:GetScale() * height / size.Y) end) end
			c:PivotTo(cf)                                                   -- feet first, then lift the box onto the perch
			local box, bsize = c:GetBoundingBox()
			c:PivotTo(cf * CFrame.new(0, cf.Position.Y - (box.Position.Y - bsize.Y / 2), 0))
			b.model = c
			local pv = c:GetPivot()
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("Bone") and table.find(BONES, d.Name) then
					d.Transform = CFrame.identity
					b.bones[d.Name] = {bone = d, axes = {
						X = d.WorldCFrame:VectorToObjectSpace(pv:VectorToWorldSpace(Vector3.xAxis)),
						Y = d.WorldCFrame:VectorToObjectSpace(pv:VectorToWorldSpace(Vector3.yAxis)),
						Z = d.WorldCFrame:VectorToObjectSpace(pv:VectorToWorldSpace(Vector3.zAxis))}}
					b.boned = true
				end
			end
		else
			c.CFrame = cf * CFrame.new(0, c.Size.Y / 2, 0); b.model = c
		end
		return b
	end
	-- no template: a part-built bird standing with folded wings
	local body = part(k.body, k.bodyColor, parent); body.CFrame = cf * CFrame.new(0, k.body.Y / 2 + 0.3, 0) * CFrame.Angles(math.rad(-8), 0, 0)
	local legL = part(Vector3.new(0.08, 0.5, 0.08), C(230, 170, 90), parent); legL.CFrame = cf * CFrame.new(-0.12, 0.25, 0.1)
	local legR = part(Vector3.new(0.08, 0.5, 0.08), C(230, 170, 90), parent); legR.CFrame = cf * CFrame.new(0.12, 0.25, 0.1)
	b.wings = {}
	for _, side in ipairs({-1, 1}) do
		local w = part(Vector3.new(0.06, k.body.Y * 0.8, k.body.Z * 0.75), k.wingColor, parent)
		table.insert(b.wings, {part = w, side = side})
	end
	if k.bill then
		local bill = part(Vector3.new(0.22, 0.2, 1.1), C(236, 190, 110), parent); bill.CFrame = body.CFrame * CFrame.new(0, 0.1, -(k.body.Z / 2 + 0.5))
		local head = part(Vector3.new(0.26, 0.26, 0.5), C(60, 58, 56), parent); head.CFrame = body.CFrame * CFrame.new(0, 0.2, -(k.body.Z / 2 + 0.1))
	end
	b.body = body
	return b
end
local function setBone(b, name, axis, deg)
	local e = b.bones[name]
	if e then e.bone.Transform = CFrame.fromAxisAngle(e.axes[axis], math.rad(deg)) end
end
local function makePerch(site, k, m)
	local tpl = templateFor(site.kind or "gull")
	local yaw = math.rad(tonumber(site.yaw) or 0)
	local n = tonumber(site.n) or 1
	local gap = tonumber(site.gap) or 3
	local birds = {}
	local offsets = type(site.offsets) == "table" and site.offsets or nil     -- v7: per-bird {dx along the site's facing-right, dy up, dz across, yaw} instead of a row
	if offsets then n = #offsets end
	for i = 1, n do
		local holder = Instance.new("Model"); holder.Name = "Bird" .. i; holder.Parent = m
		local o = offsets and offsets[i] or {(i - 1) * gap, 0, 0, (i - 1) * 23 - (n - 1) * 11}
		local spot = CFrame.new(tonumber(site.x) or 0, tonumber(site.y) or 0, tonumber(site.z) or 0) * CFrame.Angles(0, yaw, 0) * CFrame.new(tonumber(o[1]) or 0, tonumber(o[2]) or 0, tonumber(o[3]) or 0) * CFrame.Angles(0, math.rad(tonumber(o[4]) or 0), 0)
		local b = makePerchBird(k, tpl, site, spot, holder)
		b.spot = spot; b.act = "idle"; b.until_ = math.random() * 3; b.t = 0; b.dir = 1
		table.insert(birds, b)
	end
	table.insert(flocks, {site = site, kind = k, model = m, birds = birds, awake = true, t = 0, perch = true, mesh = tpl ~= nil})
end
local ACTS = {{"look", 2.2, 3}, {"flap", 1.3, 2}, {"waddle", 1.6, 2}, {"gulp", 0.8, 1}, {"idle", 2.5, 4}}
local function pickAct(b, k)
	local total = 0
	for _, a in ipairs(ACTS) do if a[1] ~= "gulp" or k.bill then total += a[3] end end
	local r = math.random() * total
	for _, a in ipairs(ACTS) do
		if a[1] ~= "gulp" or k.bill then
			r -= a[3]
			if r <= 0 then b.act = a[1]; b.until_ = a[2] * (0.8 + math.random() * 0.5); b.t = 0; b.dir = (math.random() < 0.5) and -1 or 1 return end
		end
	end
	b.act = "idle"; b.until_ = 2; b.t = 0
end
local function stepPerch(fl, dt)
	local k = fl.kind
	for _, b in ipairs(fl.birds) do
		b.t += dt
		if b.t >= b.until_ then pickAct(b, k) end
		local t, a = b.t, b.act
		local ease = math.min(1, t / 0.4)                                 -- a soft start to every move
		local wing, tip, headY, headX, jaw, thighL, thighR, roll = 0, 0, 0, 0, 0, 0, 0, 0
		if a == "look" then headY = 35 * b.dir * ease * (t < b.until_ - 0.4 and 1 or math.max(0, (b.until_ - t) / 0.4))
		elseif a == "flap" then local f = math.sin(t * 2 * math.pi * 3.2); wing = (30 + 25 * f) * ease; tip = 12 * f * ease; headX = -6 * ease
		elseif a == "waddle" then local f = math.sin(t * 2 * math.pi * 2); roll = 7 * f * ease; thighL = 25 * f * ease; thighR = -25 * f * ease
		elseif a == "gulp" then local u = math.sin(math.min(1, t / b.until_) * math.pi); jaw = -20 * u; headX = 8 * u
		else roll = 1.2 * math.sin(fl.t * 1.1 + b.t); headX = -2 + 2 * math.sin(fl.t * 0.7) end
		if b.boned then
			setBone(b, "Wing.L", "Z", -wing); setBone(b, "Wing.R", "Z", wing)
			setBone(b, "WingTip.L", "Z", -tip); setBone(b, "WingTip.R", "Z", tip)
			local e = b.bones.Head
			if e then e.bone.Transform = CFrame.fromAxisAngle(e.axes.Y, math.rad(headY)) * CFrame.fromAxisAngle(e.axes.X, math.rad(headX)) end
			setBone(b, "Jaw", "X", jaw); setBone(b, "Thigh.L", "X", thighL); setBone(b, "Thigh.R", "X", thighR); setBone(b, "Body", "Z", roll)
		elseif b.wings then
			for _, w in ipairs(b.wings) do
				w.part.CFrame = b.body.CFrame * CFrame.new(w.side * (k.body.X / 2 + 0.03), 0.05, 0.05) * CFrame.Angles(0, 0, -w.side * math.rad(wing * 0.6))
			end
			b.body.CFrame = b.spot * CFrame.new(0, k.body.Y / 2 + 0.3, 0) * CFrame.Angles(math.rad(-8 + headX * 0.3), math.rad(headY * 0.5), math.rad(roll))
		elseif b.model and b.model:IsA("Model") and (roll ~= 0 or headY ~= 0) then
			b.model:PivotTo(b.spot * CFrame.Angles(0, math.rad(headY * 0.3), math.rad(roll)))   -- (a mesh without bones: it turns and sways a little)
		end
	end
end
local function makeFlock(site)
	local k = KIND[site.kind] or KIND.gull
	local m = Instance.new("Model"); m.Name = site.name or site.kind; m.Parent = folder
	if site.perch then return makePerch(site, k, m) end
	local tpl = templateFor(site.kind or "gull", "Flying")
	local birds = {}
	for i = 1, tonumber(site.n) or 5 do
		local holder = Instance.new("Model"); holder.Name = "Bird" .. i; holder.Parent = m
		local b = tpl and makeTemplateBird(k, tpl, holder) or makePartBird(k, holder)
		b.phase = math.random() * 2 * math.pi; b.flapPhase = math.random() * 2 * math.pi; b.glidePhase = math.random() * 2 * math.pi
		b.r = (tonumber(site.r) or 30) * (0.75 + math.random() * 0.5); b.dy = (math.random() - 0.5) * (tonumber(site.band) or 10)
		b.speed = k.speed * (0.85 + math.random() * 0.3); b.dir = (i % 2 == 0) and 1 or -1
		table.insert(birds, b)
	end
	table.insert(flocks, {site = site, kind = k, model = m, birds = birds, awake = true, t = math.random() * 100, mesh = tpl ~= nil})
end
-- v5: the templates are Persistent models but their MeshParts still arrive a moment after the client starts; a perch built before
-- its mesh is there would stay part-built. So: wait (bounded) for every perch kind's template to have a part, then build.
local function templateReady(kind)
	local t = templateFor(kind)
	return t == nil or t:IsA("BasePart") or t:FindFirstChildWhichIsA("BasePart", true) ~= nil
end
local function meshPending()
	for _, s in ipairs(sites()) do if s.perch and not templateReady(s.kind or "gull") then return true end end
	return false
end
task.spawn(function()
	local t0 = os.clock()
	while meshPending() and os.clock() - t0 < 25 do task.wait(0.25) end
	for _, s in ipairs(sites()) do makeFlock(s) end
end)
local PARK = CFrame.new(0, -1000, 0)
local function park(b)
	b.root.CFrame = PARK
	if b.template then for _, r in ipairs(b.rel) do r.part.CFrame = PARK end
	else for _, w in ipairs(b.wings) do w.part.CFrame = PARK end; for _, e in ipairs(b.extra) do e.part.CFrame = PARK end end
end
local function place(b, k, cf, flap)
	b.root.CFrame = cf
	if b.template then
		for _, r in ipairs(b.rel) do
			if r.side then r.part.CFrame = cf * CFrame.Angles(0, 0, -r.side * flap) * r.cf   -- (a named wing flaps about the body's side)
			else r.part.CFrame = cf * r.cf end
		end
		return
	end
	for _, w in ipairs(b.wings) do
		local hinge = cf * CFrame.new(w.side * k.body.X / 2, 0, 0) * CFrame.Angles(0, 0, -w.side * flap)
		if w.tip then w.part.CFrame = hinge * CFrame.new(w.side * (w.len - w.len * 0.15), 0.005, 0)
		else w.part.CFrame = hinge * CFrame.new(w.side * w.len / 2, 0, 0) end
	end
	for _, e in ipairs(b.extra) do e.part.CFrame = cf * e.cf end
end
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam or F:GetAttribute("Enabled") == false then return end
	local camPos = cam.CFrame.Position
	for _, fl in ipairs(flocks) do
		local s, k = fl.site, fl.kind
		local centre = Vector3.new(tonumber(s.x) or 0, tonumber(s.y) or 50, tonumber(s.z) or 0)
		local near = (camPos - centre).Magnitude <= (tonumber(s.range) or 450)
		if not near then
			if fl.awake then fl.awake = false; if not fl.perch then for _, b in ipairs(fl.birds) do park(b) end end end   -- (perched birds stay on their perch, still)
			continue
		end
		fl.awake = true
		fl.t += dt
		if fl.perch then stepPerch(fl, dt) continue end
		for _, b in ipairs(fl.birds) do
			b.phase += b.speed * b.dir * dt
			local th = b.phase
			local pos, vel
			if s.kind == "swallow" then                                  -- a figure-eight, darting
				local sx, cx = math.sin(th), math.cos(th)
				pos = centre + Vector3.new(b.r * sx, b.dy + 3 * math.sin(2 * th + b.flapPhase), b.r * sx * cx)
				vel = Vector3.new(b.r * cx, 6 * math.cos(2 * th + b.flapPhase), b.r * (cx * cx - sx * sx)) * (b.speed * b.dir)
			else                                                        -- a slow circle, rising and falling
				pos = centre + Vector3.new(b.r * math.sin(th), b.dy + 2.5 * math.sin(0.5 * th + b.glidePhase), b.r * math.cos(th))
				vel = Vector3.new(b.r * math.cos(th), 1.25 * math.cos(0.5 * th + b.glidePhase), -b.r * math.sin(th)) * (b.speed * b.dir)
			end
			if vel.Magnitude < 0.01 then vel = Vector3.new(0, 0, 1) end
			local look = CFrame.lookAt(pos, pos + vel)
			local bank = math.rad(k.bank) * b.dir * (s.kind == "swallow" and math.cos(2 * th) or 1)
			local cf = look * CFrame.Angles(0, 0, -bank)
			-- the wings: gulls and the pelican glide between bouts of flapping, swallows beat all the time
			local amp = math.rad(38)
			if k.glide then
				local bout = math.sin(0.35 * fl.t + b.glidePhase)
				amp = amp * math.clamp(bout * 1.6, 0.08, 1)
			end
			local flap = amp * math.sin((fl.t + b.flapPhase) * k.flap * 2 * math.pi)
			place(b, k, cf, flap)
		end
	end
end)
local function rebuild()
	for _, fl in ipairs(flocks) do fl.model:Destroy() end
	flocks = {}
	for _, s in ipairs(sites()) do makeFlock(s) end
end
F:GetAttributeChangedSignal("Sites"):Connect(rebuild)                  -- a new site list: rebuilt on the spot
local rebuildQueued = false
local function rebuildSoon()                                            -- a template (or its mesh) arriving later: rebuilt once it is whole
	if rebuildQueued then return end
	rebuildQueued = true
	task.delay(1.5, function() rebuildQueued = false; if not meshPending() then rebuild() else rebuildSoon() end end)
end
do local T = F:FindFirstChild("Templates"); if T then T.DescendantAdded:Connect(rebuildSoon) end end
F.ChildAdded:Connect(function(c) if c.Name == "Templates" then c.DescendantAdded:Connect(rebuildSoon); rebuildSoon() end end)   -- a Templates folder dropped in later
task.delay(26, function()
	local meshKinds, perches = {}, 0
	for _, fl in ipairs(flocks) do if fl.mesh then table.insert(meshKinds, fl.site.kind) end; if fl.perch then perches += 1 end end
	print(string.format("Birds: %d sites on this screen (%d perched)%s", #flocks, perches, #meshKinds > 0 and (" (mesh: " .. table.concat(meshKinds, ", ") .. ")") or " (part-built)"))
end)
]===]
do   -- the compile check, where loadstring can run: the source is compiled with the luau CLI before every push
	local ok, f, err = pcall(function() return loadstring(CLIENT) end)
	if ok and not f then print("QQ BIRDS ABORT: BirdsClient does not compile: " .. tostring(err)) return end
end
local old = workspace:FindFirstChild("Birds")
local F = Instance.new("Folder"); F.Name = "Birds"
F:SetAttribute("Enabled", true)
F:SetAttribute("Sites", [==[[{"name":"Harbour gulls","kind":"gull","x":225,"y":22,"z":-670,"r":34,"n":3,"band":8,"range":500},{"name":"Lighthouse gulls","kind":"gull","x":520,"y":92,"z":-1178,"r":28,"n":3,"band":10,"range":500},{"name":"Village swallows","kind":"swallow","x":262,"y":30,"z":-58,"r":30,"n":3,"band":6,"range":400},{"name":"Pelican on the quay","kind":"pelican","perch":true,"x":232.5,"y":-46.56,"z":-667.6,"yaw":280,"n":1,"height":2.6,"range":220},{"name":"Gulls on the harbour rail","kind":"gull","perch":true,"x":231.6,"y":-46.56,"z":-673.4,"yaw":102,"n":3,"height":1.9,"range":220,"offsets":[[0,0,0,0],[7.5,0,0.6,50],[-5.5,0,0.9,-70]]},{"name":"Gulls at the lighthouse","kind":"gull","perch":true,"x":526,"y":3.5,"z":-1170,"yaw":300,"n":2,"gap":2.4,"height":1.9,"range":260}]]==])
local T = Instance.new("Folder"); T.Name = "Templates"; T.Parent = F   -- (Templates.Gull / Pelican = the rigged standing meshes for the perches; Templates.GullFlying / PelicanFlying = wings-spread meshes for the flocks)
if old then local ot = old:FindFirstChild("Templates"); if ot then for _, m in ipairs(ot:GetChildren()) do m:Clone().Parent = T end end end
for _, m in ipairs(T:GetChildren()) do if m:IsA("Model") then m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent end end   -- (v4: a template must reach every client whole - her imports sit far away, and a streamed-out template is an empty Model)
if old then
	local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
	local n = 1; while hb:FindFirstChild("Birds_pre_" .. n) do n += 1 end
	old.Name = "Birds_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local c = Instance.new("Script"); c.Name = "BirdsClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
print(string.format("QQ BIRDS DONE: workspace.Birds (BirdsClient %d chars; 6 sites: 3 flocks + 3 perches; mesh templates: Templates.Gull / Templates.Pelican for the perches, Templates.GullFlying / PelicanFlying for the flocks)%s", #c.Source, old and ("; the old folder is HudBackup." .. old.Name) or ""))
