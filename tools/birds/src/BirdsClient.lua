-- BirdsClient (workspace.Birds, RunContext Client): ambient birds (Shannon, Oct 15 2026: "and some birds?"). Gulls circle the
-- harbour and the lighthouse, swallows dart over the French village in figure-eights; no gameplay, nothing to touch. Every bird is
-- three parts (a body and two wings) made and moved on THIS client only - the server never sees them and nothing replicates - so
-- a flock costs a few CFrame writes a frame. A site is skipped while the camera is farther than its Range (the birds park out of
-- sight), so phones only move the flock they can see. The sites come from the folder's attribute Sites (JSON; the installer
-- writes them): [{name, kind = "gull" | "swallow", x, y, z, r, n, band, range}] - x/z the centre, y the flight height (world),
-- r the circle's radius, n the number of birds, band the vertical spread, range the camera distance that wakes the site.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local F = script.Parent
local C = Color3.fromRGB
local KIND = {
	gull = {body = Vector3.new(0.5, 0.36, 1.3), wing = Vector3.new(1.6, 0.06, 0.55), bodyColor = C(245, 245, 240), wingColor = C(205, 208, 212), speed = 0.22, flap = 1.5, glide = true, bank = 14},
	swallow = {body = Vector3.new(0.3, 0.22, 0.8), wing = Vector3.new(0.95, 0.04, 0.32), bodyColor = C(34, 38, 56), wingColor = C(28, 30, 46), speed = 0.85, flap = 6.0, glide = false, bank = 32},
}
local function part(size, color, parent)
	local p = Instance.new("Part"); p.Size = size; p.Color = color; p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent
	return p
end
local folder = workspace:FindFirstChild("Birds_local") or Instance.new("Folder")
folder.Name = "Birds_local"; folder:ClearAllChildren(); folder.Parent = workspace
local function sites()
	local ok, t = pcall(function() return HttpService:JSONDecode(F:GetAttribute("Sites") or "[]") end)
	return (ok and type(t) == "table") and t or {}
end
local flocks = {}
local function makeFlock(site)
	local k = KIND[site.kind] or KIND.gull
	local m = Instance.new("Model"); m.Name = site.name or site.kind; m.Parent = folder
	local birds = {}
	for i = 1, tonumber(site.n) or 5 do
		local body = part(k.body, k.bodyColor, m)
		local lw, rw = part(k.wing, k.wingColor, m), part(k.wing, k.wingColor, m)
		table.insert(birds, {body = body, lw = lw, rw = rw,
			phase = math.random() * 2 * math.pi, flapPhase = math.random() * 2 * math.pi, glidePhase = math.random() * 2 * math.pi,
			r = (tonumber(site.r) or 30) * (0.75 + math.random() * 0.5), dy = (math.random() - 0.5) * (tonumber(site.band) or 10),
			speed = k.speed * (0.85 + math.random() * 0.3), dir = (i % 2 == 0) and 1 or -1})
	end
	table.insert(flocks, {site = site, kind = k, model = m, birds = birds, awake = true, t = math.random() * 100})
end
for _, s in ipairs(sites()) do makeFlock(s) end
local PARK = CFrame.new(0, -1000, 0)
local function place(b, k, cf, flap)
	b.body.CFrame = cf
	local hw = k.wing.X / 2
	b.lw.CFrame = cf * CFrame.new(-k.body.X / 2, 0, 0) * CFrame.Angles(0, 0, flap) * CFrame.new(-hw, 0, 0)
	b.rw.CFrame = cf * CFrame.new(k.body.X / 2, 0, 0) * CFrame.Angles(0, 0, -flap) * CFrame.new(hw, 0, 0)
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
			if fl.awake then fl.awake = false; for _, b in ipairs(fl.birds) do b.body.CFrame = PARK; b.lw.CFrame = PARK; b.rw.CFrame = PARK end end
			continue
		end
		fl.awake = true
		fl.t += dt
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
			-- the wings: gulls glide between bouts of flapping, swallows beat all the time
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
F:GetAttributeChangedSignal("Sites"):Connect(function()                -- a new site list: rebuilt on the spot
	for _, fl in ipairs(flocks) do fl.model:Destroy() end
	flocks = {}
	for _, s in ipairs(sites()) do makeFlock(s) end
end)
print(string.format("Birds: %d flocks on this screen", #flocks))
