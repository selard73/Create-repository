-- CameraClient v3 (workspace.PhotoGame, RunContext Client), Oct 8 2026. Shannon: "make the camera function a lot like the
-- binoculars: when you click it, it pulls up to her face, you look through the lens, a button to zoom in and out and one
-- to take the photo; the photo you take should show on the screen". Holding the Camera: a "Postcards wanted" list and a
-- camera sign over each sight still wanted. Click / tap = raise it: first person through a lens window; mouse wheel or
-- the + / - buttons zoom; click or the round shutter button takes the photo; X or right-click lowers it. Every photo comes
-- back as a polaroid of what was in the lens (the parts in view copied into a little scene); if it is one of the four
-- sights CameraServer checks it and puts it in your bag. VR: aim with the camera in your hand (gold ring); the photo
-- floats in front of you. The Postcard Squirrel's sell prompt shows only while you have photos.
-- v3 (Oct 8 late, Shannon: "where your album saves your photos, I want it to actually show the photos ... maybe they could
-- save in a carousel view"): the album in the panel shows the photos themselves, one at a time (< > to flip, X to delete,
-- tap the photo = see it big in the middle of the screen; on a phone the panel is too short, so a "See your photos" button
-- opens that big view). Each photo is the very scene you shot, kept while you play; CameraServer keeps where it was taken
-- (spot, zoom, where the whale / pizza were) in its own small store, so after a rejoin the album takes it again from there.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local G = script.Parent
local kit = RS:WaitForChild("PhotoGame")
local ev = kit:WaitForChild("PhotoEvent")
local Subjects = require(kit:WaitForChild("Subjects"))
local Bubble = require(RS:WaitForChild("SquirrelBubble"))
local TOOL, ICON = "Camera", "rbxassetid://88496268802875"
local C = Color3.fromRGB
local FONT = Font.new("rbxasset://fonts/families/FredokaOne.json")
local CREAM, INK, GOLD, BROWN = C(255, 246, 220), C(58, 36, 16), C(255, 202, 62), C(58, 36, 16)
local RED = C(170, 70, 50)
local function num(name, d) local v = G:GetAttribute(name) return type(v) == "number" and v or d end
local function vr() return VRService.VREnabled end
local function viewport() local c = workspace.CurrentCamera return c and c.ViewportSize or Vector2.new(1280, 720) end
local gui   -- the CameraGui, made below; screen() is its size (in VR the screen layer is a panel, not the headset's picture)
local function screen() local s = gui and gui.AbsoluteSize; if s and s.X > 10 then return s end return viewport() end
local touch = UIS.TouchEnabled and not UIS.KeyboardEnabled
local holding, raised = false, false
local function corner(o, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = o end
local function stroke(o, col, th) local st = Instance.new("UIStroke") st.Color = col st.Thickness = th st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border st.Parent = o return st end
local function heldHandle()
	local char = player.Character
	local t = char and char:FindFirstChild(TOOL)
	return t and t:FindFirstChild("Handle")
end
-- while the camera is up to your eye you look THROUGH it, so the one in your hand is hidden (this screen only)
local function hideHeld(on)
	local char = player.Character
	local pack = player:FindFirstChildOfClass("Backpack")
	local t = (char and char:FindFirstChild(TOOL)) or (pack and pack:FindFirstChild(TOOL))   -- on unequip it is already back in the bag
	if not t then return end
	for _, d in ipairs(t:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = on and 1 or 0 end end
end

gui = Instance.new("ScreenGui")
gui.Name = "CameraGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 6; gui.Parent = pg

-- ---------- the lens: darkened round a clear window in the middle, a frame, corner marks, the zoom ----------
local lens = Instance.new("Frame"); lens.Name = "Lens"; lens.Size = UDim2.fromScale(1, 1); lens.BackgroundTransparency = 1; lens.Visible = false; lens.Parent = gui
local shade = {}
for i = 1, 4 do local f = Instance.new("Frame"); f.BackgroundColor3 = C(8, 6, 10); f.BackgroundTransparency = 0.32; f.BorderSizePixel = 0; f.Parent = lens; shade[i] = f end
local win = Instance.new("Frame"); win.Name = "Window"; win.BackgroundTransparency = 1; win.Parent = lens; stroke(win, CREAM, 2)
local marks = {}
for i = 1, 8 do local b = Instance.new("Frame"); b.BackgroundColor3 = CREAM; b.BorderSizePixel = 0; b.Parent = win; marks[i] = b end
local dot = Instance.new("Frame"); dot.AnchorPoint = Vector2.new(0.5, 0.5); dot.Position = UDim2.fromScale(0.5, 0.5); dot.Size = UDim2.fromOffset(6, 6)
dot.BackgroundColor3 = CREAM; dot.BorderSizePixel = 0; dot.Parent = win; corner(dot, 3)
local zoomLabel = Instance.new("TextLabel"); zoomLabel.Position = UDim2.new(0, 10, 1, -30); zoomLabel.Size = UDim2.fromOffset(90, 22); zoomLabel.BackgroundTransparency = 1
zoomLabel.FontFace = FONT; zoomLabel.TextSize = 18; zoomLabel.TextColor3 = CREAM; zoomLabel.TextXAlignment = Enum.TextXAlignment.Left; zoomLabel.TextStrokeTransparency = 0.4; zoomLabel.Parent = win
local function button(text, size)
	local b = Instance.new("TextButton"); b.AnchorPoint = Vector2.new(0.5, 0.5); b.Size = UDim2.fromOffset(size, size); b.BackgroundColor3 = GOLD
	b.FontFace = FONT; b.TextSize = math.floor(size * 0.5); b.TextColor3 = C(84, 48, 18); b.Text = text; b.AutoButtonColor = true; b.Parent = lens
	corner(b, math.floor(size / 2)); stroke(b, C(150, 98, 36), 2)
	return b
end
local shutterBtn = button("", 78)
local shutterIn = Instance.new("Frame"); shutterIn.AnchorPoint = Vector2.new(0.5, 0.5); shutterIn.Position = UDim2.fromScale(0.5, 0.5); shutterIn.Size = UDim2.fromOffset(54, 54)
shutterIn.BackgroundColor3 = C(255, 255, 255); shutterIn.Parent = shutterBtn; corner(shutterIn, 27); stroke(shutterIn, C(150, 98, 36), 2)
local zoomInBtn, zoomOutBtn, lowerBtn = button("+", 46), button("-", 46), button("X", 42)
-- the window sits in the middle, clear of the HUD bar (74 px), the hotbar / jump button (76 px) and the buttons on the right
local function windowRect()
	local v = viewport()
	local half = math.max(40, math.min(v.Y * 0.32, v.Y / 2 - 76))
	local x1 = math.min(v.X * 0.78, v.X - 170)
	local x0 = v.X - x1
	return math.floor(x0), math.floor(v.Y / 2 - half), math.floor(x1), math.floor(v.Y / 2 + half)
end
local function layoutLens()
	local v = viewport()
	local x0, y0, x1, y1 = windowRect()
	shade[1].Position = UDim2.fromOffset(0, 0); shade[1].Size = UDim2.fromOffset(v.X, y0)
	shade[2].Position = UDim2.fromOffset(0, y1); shade[2].Size = UDim2.fromOffset(v.X, v.Y - y1)
	shade[3].Position = UDim2.fromOffset(0, y0); shade[3].Size = UDim2.fromOffset(x0, y1 - y0)
	shade[4].Position = UDim2.fromOffset(x1, y0); shade[4].Size = UDim2.fromOffset(v.X - x1, y1 - y0)
	win.Position = UDim2.fromOffset(x0, y0); win.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
	local w, h = x1 - x0, y1 - y0
	local L, T = math.clamp(math.floor(math.min(w, h) * 0.12), 12, 30), 4
	for i, c in ipairs({{0, 0, 1, 1}, {w, 0, -1, 1}, {0, h, 1, -1}, {w, h, -1, -1}}) do
		marks[i * 2 - 1].Position = UDim2.fromOffset(c[3] > 0 and c[1] + 6 or c[1] - 6 - L, c[4] > 0 and c[2] + 6 or c[2] - 6 - T); marks[i * 2 - 1].Size = UDim2.fromOffset(L, T)
		marks[i * 2].Position = UDim2.fromOffset(c[3] > 0 and c[1] + 6 or c[1] - 6 - T, c[4] > 0 and c[2] + 6 or c[2] - 6 - L); marks[i * 2].Size = UDim2.fromOffset(T, L)
	end
	local cy = v.Y / 2
	shutterBtn.Position = UDim2.fromOffset(v.X - 58, cy)
	zoomInBtn.Position = UDim2.fromOffset(v.X - 128, cy - 28); zoomOutBtn.Position = UDim2.fromOffset(v.X - 128, cy + 28)
	lowerBtn.Position = UDim2.fromOffset(v.X - 58, math.max(98, cy - 82))
end

-- the message slot (as the store's toasts, above the hotbar); in VR it also floats over the camera in your hand
local toastLabel = Instance.new("TextLabel")
toastLabel.Name = "CameraToast"; toastLabel.AnchorPoint = Vector2.new(0.5, 1); toastLabel.Position = UDim2.new(0.5, 0, 1, -118)
toastLabel.BackgroundColor3 = BROWN; toastLabel.BackgroundTransparency = 0.1; toastLabel.BorderSizePixel = 0; toastLabel.ZIndex = 5
toastLabel.FontFace = FONT; toastLabel.TextColor3 = CREAM; toastLabel.TextScaled = true; toastLabel.TextWrapped = true; toastLabel.Visible = false; toastLabel.Parent = gui
corner(toastLabel, 14); stroke(toastLabel, GOLD, 2)
local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = 19; tc.MinTextSize = 11; tc.Parent = toastLabel
local tp = Instance.new("UIPadding"); tp.PaddingLeft = UDim.new(0, 12); tp.PaddingRight = UDim.new(0, 12); tp.PaddingTop = UDim.new(0, 5); tp.PaddingBottom = UDim.new(0, 5); tp.Parent = toastLabel
local vrSign
local toastAt = 0
local function toast(text, secs)
	local v = viewport()
	local av = gui:FindFirstChild("AlbumViewer")
	if av and av.Visible then return end                    -- the big photo view says what happened on its own card
	local w = math.min(460, v.X - 40)
	if raised then local x0, _, x1 = windowRect(); w = math.min(w, x1 - x0 - 20) end
	local wp = gui:FindFirstChild("Wanted")                 -- and it stays clear of the panel on the left (phones)
	if wp and (wp.Visible or holding) then w = math.min(w, math.max(160, 2 * (v.X / 2 - (wp.AbsolutePosition.X + wp.AbsoluteSize.X + 8)))) end
	toastLabel.Size = UDim2.fromOffset(w, 52); toastLabel.Text = text; toastLabel.Visible = true
	local t = os.clock(); toastAt = t
	task.delay(secs or 3, function() if toastAt == t then toastLabel.Visible = false end end)
	if vr() then
		local h = heldHandle()
		if h then
			if not vrSign then
				vrSign = Instance.new("BillboardGui"); vrSign.Name = "CameraVRSign"; vrSign.Size = UDim2.fromOffset(300, 70); vrSign.StudsOffset = Vector3.new(0, 1.3, 0)
				vrSign.AlwaysOnTop = true; vrSign.LightInfluence = 0; vrSign.Parent = pg
				local l = Instance.new("TextLabel"); l.Name = "Text"; l.Size = UDim2.fromScale(1, 1); l.BackgroundColor3 = BROWN; l.BackgroundTransparency = 0.1
				l.FontFace = FONT; l.TextColor3 = CREAM; l.TextScaled = true; l.TextWrapped = true; l.Parent = vrSign; corner(l, 12)
			end
			vrSign.Adornee = h; vrSign.Text.Text = text; vrSign.Enabled = true
			task.delay(secs or 3, function() if toastAt == t and vrSign then vrSign.Enabled = false end end)
		end
	end
end
local flash = Instance.new("Frame"); flash.Size = UDim2.fromScale(1, 1); flash.BackgroundColor3 = C(255, 255, 255); flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0; flash.ZIndex = 20; flash.Parent = gui
local shutterSound = Instance.new("Sound"); shutterSound.SoundId = "rbxassetid://9113678227"; shutterSound.Volume = 0.8; shutterSound.Parent = gui

-- ---------- what is in the picture (squirrels far away may not be loaded yet: then they simply are not in it) ----------
local models = {}
local function model(name)
	if not name then return nil end
	local m = models[name]
	if not (m and m.Parent) then m = workspace:FindFirstChild(name); models[name] = m end
	return m
end
local function centre(m)
	if not (m and m:FindFirstChildWhichIsA("BasePart", true)) then return nil end
	return m:GetBoundingBox().Position
end
local pizzaModel
local function pizza()
	if pizzaModel and pizzaModel.Parent then return pizzaModel end
	local P = workspace:FindFirstChild("PortoNocciola")
	pizzaModel = P and P:FindFirstChild("Chef Nutmeg's pizza dough", true)
	return pizzaModel
end
local function whaleMesh() local w = workspace:FindFirstChild("PortoWhale") return w, w and w:FindFirstChildWhichIsA("MeshPart", true) end
local function anchors(s)
	if s.id == "whale" then
		local w, mesh = whaleMesh()
		if not mesh then return {}, {} end
		local bh = mesh:FindFirstChild("Blowhole")
		return {(bh and bh.WorldPosition or mesh.Position) + Vector3.new(0, 2.5, 0)}, {w}
	end
	local pts, ignore = {}, {}
	for _, name in ipairs({s.model, s.model2}) do
		local m = model(name)
		local c = centre(m)
		if not c then return {}, {} end
		table.insert(pts, c); table.insert(ignore, m)
	end
	if s.id == "pizza" then local pz = pizza(); if pz and pz:FindFirstChildWhichIsA("BasePart", true) then table.insert(pts, pz:GetPivot().Position); table.insert(ignore, pz) end end
	return pts, ignore
end
local function moment(s)
	if s.id == "whale" then
		local _, mesh = whaleMesh()
		local bh = mesh and mesh:FindFirstChild("Blowhole")
		local sp = bh and bh:FindFirstChild("Spout")
		return sp ~= nil and sp.Enabled == true
	elseif s.id == "pizza" then
		local f = (os.clock() % 1.5) / 1.5
		return 3.1 * 4 * f * (1 - f) > 0.8
	end
	return true
end
local function shotCF()
	local cam = workspace.CurrentCamera
	if vr() then
		local h = heldHandle()
		if h then return CFrame.lookAt(h.Position, h.Position + h.CFrame.LookVector) end
		return cam:GetRenderCFrame()
	end
	return cam.CFrame
end
local function inFrame(cf, pt)
	if vr() then
		local d = pt - cf.Position
		if d.Magnitude < 0.1 then return false, 9 end
		local ang = math.deg(math.acos(math.clamp(cf.LookVector:Dot(d.Unit), -1, 1)))
		return ang < 22, ang / 22
	end
	local v, on = workspace.CurrentCamera:WorldToViewportPoint(pt)
	if not on or v.Z <= 0 then return false, 9 end
	local x0, y0, x1, y1 = windowRect()
	local off = math.max(math.abs(v.X - (x0 + x1) / 2) / ((x1 - x0) / 2), math.abs(v.Y - (y0 + y1) / 2) / ((y1 - y0) / 2))
	return off <= 1, off
end
local function lineClear(from, to, ignore)
	local ex = {player.Character}
	local twins = workspace:FindFirstChild("SquirrelTwins"); if twins then table.insert(ex, twins) end
	for _, x in ipairs(ignore) do table.insert(ex, x) end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	local origin = from
	for _ = 1, 10 do
		params.FilterDescendantsInstances = ex
		local dir = to - origin
		if dir.Magnitude < 0.2 then return true end
		local hit = workspace:Raycast(origin, dir, params)
		if not hit then return true end
		local inst = hit.Instance
		if inst == workspace.Terrain then
			if hit.Material ~= Enum.Material.Water then return false end
			origin = hit.Position + dir.Unit * 0.1
		elseif inst.Transparency >= 0.5 or (not inst.CanCollide and inst.Transparency > 0) then table.insert(ex, inst)
		else return false end
	end
	return true
end
local function wantedList()
	local list = {}
	for _, s in ipairs(Subjects) do if (player:GetAttribute("Item_photo_" .. s.id) or 0) < 1 then table.insert(list, s.short) end end
	return list
end
local function evaluate(cf)
	local results = {}
	for _, s in ipairs(Subjects) do
		local ok, pts, ignore = pcall(anchors, s)
		if ok and #pts > 0 then
			local maxD = s.id == "whale" and num("WhaleMaxDist", 300) or num("MaxDist", 45)
			local r = {s = s, n = 0, near = true, clear = true, off = 0}
			for _, pt in ipairs(pts) do
				local inside, off = inFrame(cf, pt)
				if inside then r.n += 1 end
				r.off = math.max(r.off, off)
				if (pt - cf.Position).Magnitude > maxD then r.near = false end
			end
			r.all, r.some = r.n == #pts, r.n > 0
			if r.all and r.near then for _, pt in ipairs(pts) do if not lineClear(cf.Position, pt, ignore) then r.clear = false break end end end
			r.moment = moment(s)
			r.ok = r.all and r.near and r.clear and r.moment
			table.insert(results, r)
		end
	end
	table.sort(results, function(a, b) return a.off < b.off end)
	for _, r in ipairs(results) do if r.ok then return r.s end end
	for _, r in ipairs(results) do
		if r.some then
			if not r.near then return nil, "Get closer to " .. r.s.name .. "!" end
			if not r.all then return nil, r.s.id == "opera" and "Get the singer AND the accordion player in the picture!" or ("Put " .. r.s.name .. " in the middle!") end
			if not r.clear then return nil, "Something's in the way of " .. r.s.name .. "!" end
			if not r.moment then return nil, r.s.id == "whale" and "Wait for the whale to blow its spout!" or "Catch the pizza in the air!" end
		end
	end
	local w = wantedList()
	if #w == 0 then return nil, "Your four postcards are ready - sell them to the Postcard Squirrel." end
	return nil, "Not a postcard. Wanted: " .. table.concat(w, ", ") .. " (follow the camera signs)."
end

-- ---------- the photo: the parts that were in the lens, copied into a little scene (a WorldModel) ----------
local SKIP = {Script = true, LocalScript = true, ModuleScript = true, Sound = true, ParticleEmitter = true, Beam = true, Trail = true, ProximityPrompt = true,
	BillboardGui = true, SurfaceGui = true, ClickDetector = true, PointLight = true, SpotLight = true, SurfaceLight = true, Fire = true, Smoke = true, Sparkles = true}
local function stripCopy(inst)
	local ok, c = pcall(function() return inst:Clone() end)
	if not (ok and c) then return nil end
	for _, d in ipairs(c:GetDescendants()) do
		if SKIP[d.ClassName] then d:Destroy() elseif d:IsA("BasePart") then d.Anchored = true end
	end
	if c:IsA("BasePart") then c.Anchored = true end
	return c
end
local function buildWorld(cf, fov, extra, ignore)
	local world = Instance.new("WorldModel"); world.Name = "Scene"
	local look = cf.LookVector
	local params = OverlapParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = {workspace.CurrentCamera}
	if player.Character then table.insert(ex, player.Character) end
	for _, x in ipairs(ignore or {}) do table.insert(ex, x) end
	params.FilterDescendantsInstances = ex
	local cosLim = math.cos(math.rad(math.min(80, fov * 0.9)))
	local list = {}
	for _, ring in ipairs({{30, 32}, {95, 70}, {200, 110}}) do
		for _, p in ipairs(workspace:GetPartBoundsInRadius(cf.Position + look * ring[1], ring[2], params)) do
			if not list[p] and p.Transparency < 0.95 then
				local d = p.Position - cf.Position
				local dist = d.Magnitude
				if dist < 320 and (dist < p.Size.Magnitude * 0.6 or look:Dot(d.Unit) > cosLim) then list[p] = dist end
			end
		end
	end
	local arr = {}
	for p, d in pairs(list) do table.insert(arr, {p, d}) end
	table.sort(arr, function(a, b) return a[2] < b[2] end)
	for i = 1, math.min(600, #arr) do local c = stripCopy(arr[i][1]); if c then c.Parent = world end end
	if extra then pcall(extra, world) end
	return world, #arr
end
local function mount(vpf, world, cf, fov)
	local cam = vpf:FindFirstChild("PhotoCam") or Instance.new("Camera")
	cam.Name = "PhotoCam"; cam.CFrame = cf; cam.FieldOfView = fov; cam.Parent = vpf; vpf.CurrentCamera = cam
	if world then world.Parent = vpf end
end
-- the photo paper: a sky-to-grass gradient (terrain can't be copied) with the scene in front of it
local function photoFrame(parent, pos, size, z)
	local sky = Instance.new("Frame"); sky.Name = "Photo"; sky.Position = pos; sky.Size = size; sky.BorderSizePixel = 0
	sky.BackgroundColor3 = C(255, 255, 255); sky.ZIndex = z; sky.ClipsDescendants = true; sky.Parent = parent
	local grad = Instance.new("UIGradient"); grad.Rotation = 90
	grad.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, C(150, 198, 236)), ColorSequenceKeypoint.new(0.6, C(214, 234, 246)), ColorSequenceKeypoint.new(0.61, C(120, 170, 140)), ColorSequenceKeypoint.new(1, C(92, 140, 112))})
	grad.Parent = sky
	local vpf = Instance.new("ViewportFrame"); vpf.Name = "View"; vpf.Size = UDim2.fromScale(1, 1); vpf.BackgroundTransparency = 1; vpf.ZIndex = z + 1; vpf.Parent = sky
	vpf.Ambient = C(178, 174, 182); vpf.LightColor = C(255, 246, 226); vpf.LightDirection = Vector3.new(-0.4, -1, -0.5)
	return sky, vpf
end
-- the whale's spout is mist, which a copied scene can't show: it is drawn
local function whaleSpoutBase(mesh)
	if not mesh then return nil end
	local bh = mesh:FindFirstChild("Blowhole")
	return (bh and bh:IsA("Attachment") and bh.WorldPosition) or (mesh.Position + Vector3.new(0, mesh.Size.Y / 2, 0))
end
local function spoutBalls(world, base)
	if not base then return end
	for i = 1, 8 do
		local b = Instance.new("Part"); b.Shape = Enum.PartType.Ball; b.Anchored = true; b.Material = Enum.Material.SmoothPlastic
		b.Color = C(244, 250, 255); b.Transparency = 0.1 + i * 0.06
		local r = 0.9 + i * 0.45; b.Size = Vector3.new(r, r, r)
		b.Position = base + Vector3.new(math.sin(i * 1.7) * 0.35 * i, i * 1.25, math.cos(i * 1.3) * 0.3 * i); b.Parent = world
	end
end

-- ---------- the album's bookkeeping (CameraServer keeps the counts and where each photo was taken) ----------
local metaList = {}     -- key -> a kept photo as CameraServer has it: {k, id, t, p = spot, l = look, f = zoom, x = {w = whale, sp = spouting, z = pizza}}
local pending = {}      -- key -> a photo just taken, until CameraServer has it (ok = it said yes)
local worlds = {}       -- key -> its scene (a WorldModel, kept out of sight while not shown), or false when it can't be shown
local shots = {}        -- key -> {cf, fov} the scene is looked at with
local busyDev, retryAt, tries, rejected = {}, {}, {}, {}
local function r2(v) return math.floor(v * 100 + 0.5) / 100 end
local function r3(v) return math.floor(v * 1000 + 0.5) / 1000 end
local function packCF(cf) local t = {cf:GetComponents()} for i, v in ipairs(t) do t[i] = r3(v) end return t end
local function metaCF(m)
	local p = Vector3.new(m.p[1], m.p[2], m.p[3])
	local l = Vector3.new(m.l[1], m.l[2], m.l[3])
	if l.Magnitude < 0.1 then l = Vector3.new(0, 0, -1) end
	return CFrame.lookAt(p, p + l.Unit)
end
local function newKey() return (HttpService:GenerateGUID(false):gsub("%-", "")):sub(1, 12) end
local function shotMeta(cf, camFov, spouting)
	local l = cf.LookVector
	local m = {k = newKey(), t = os.time(), p = {r2(cf.X), r2(cf.Y), r2(cf.Z)}, l = {r3(l.X), r3(l.Y), r3(l.Z)}, f = r2(camFov)}
	local x = {}
	local _, mesh = whaleMesh()
	if mesh and (mesh.Position - cf.Position).Magnitude < 330 then x.w = packCF(mesh.CFrame); if spouting then x.sp = true end end
	local pz = pizza()
	if pz and pz:FindFirstChildWhichIsA("BasePart", true) and (pz:GetPivot().Position - cf.Position).Magnitude < 90 then x.z = packCF(pz:GetPivot()) end
	if next(x) then m.x = x end
	return m
end
-- to take a kept photo again: the whale and the pizza go back to where they were when it was taken
local function sceneFor(m)
	local ignore, adds = {}, {}
	local x = m.x or {}
	local w, mesh = whaleMesh()
	if x.w and mesh then
		table.insert(ignore, w)
		local at = CFrame.new(table.unpack(x.w))
		table.insert(adds, function(world)
			local c = stripCopy(mesh); if not c then return end
			c.CFrame = at; c.Parent = world
			if x.sp then spoutBalls(world, whaleSpoutBase(c)) end
		end)
	end
	local pz = pizza()
	if x.z and pz then
		table.insert(ignore, pz)
		local at = CFrame.new(table.unpack(x.z))
		table.insert(adds, function(world)
			local c = stripCopy(pz); if not c then return end
			if c:IsA("Model") then c:PivotTo(at) else c.CFrame = at end
			c.Parent = world
		end)
	end
	return function(world) for _, f in ipairs(adds) do pcall(f, world) end end, ignore
end
-- a postcard taken before the album kept pictures: taken again from in front of its sight (when that is loaded)
local function oldPostcardShot(id)
	local s = Subjects.byId and Subjects.byId[id]
	if not s then return nil end
	if id == "whale" then
		local _, mesh = whaleMesh()
		if not mesh then return nil end
		local target = mesh.Position
		for k = 0, 7 do
			local a = k * math.pi / 4
			local eye = target + Vector3.new(math.cos(a) * 45, 12, math.sin(a) * 45)
			if lineClear(eye, target, {mesh.Parent}) then
				return CFrame.lookAt(eye, target), 40, function(world) spoutBalls(world, whaleSpoutBase(mesh)) end
			end
		end
		return nil
	end
	local pts, ign = {}, {}
	for _, name in ipairs({s.model, s.model2}) do
		local mdl = model(name)
		local c = centre(mdl)
		if not c then return nil end
		table.insert(pts, c); table.insert(ign, mdl)
	end
	local mid = Vector3.zero
	for _, p in ipairs(pts) do mid += p end
	mid /= #pts
	for k = 0, 15 do
		local a = k * math.pi / 8
		local eye = mid + Vector3.new(math.cos(a) * 12, 2.5, math.sin(a) * 12)
		local clear = true
		for _, p in ipairs(pts) do if not lineClear(eye, p, ign) then clear = false break end end
		if clear then return CFrame.lookAt(eye, mid), 50 end
	end
	return CFrame.lookAt(mid + Vector3.new(12, 2.5, 0), mid), 50
end
local refreshAlbumUI   -- set further down
local function develop(m)
	if worlds[m.k] ~= nil or busyDev[m.k] or os.clock() < (retryAt[m.k] or 0) then return end
	if m.old and m.id == "view" then worlds[m.k] = false return end      -- an old view: nothing says where it was taken
	busyDev[m.k] = true
	task.spawn(function()
		local ok, world, cf, fov = pcall(function()
			local cf, fov, extra, ignore
			if m.p then
				cf, fov = metaCF(m), m.f or 45
				extra, ignore = sceneFor(m)
				pcall(function() player:RequestStreamAroundAsync(cf.Position + cf.LookVector * 30, 4) end)
			else
				cf, fov, extra = oldPostcardShot(m.id)
				if not cf then return nil end
			end
			local w, n = buildWorld(cf, fov, extra, ignore)
			if n < 5 then w:Destroy() return nil end
			return w, cf, fov
		end)
		busyDev[m.k] = nil
		if ok and world then
			worlds[m.k] = world; shots[m.k] = {cf = cf, fov = fov}
		else
			tries[m.k] = (tries[m.k] or 0) + 1
			if tries[m.k] >= 4 and not m.old then worlds[m.k] = false else retryAt[m.k] = os.clock() + 4 end   -- an older postcard waits for its sight to load
		end
		if refreshAlbumUI then pcall(refreshAlbumUI) end
	end)
end
-- the photos in the album now: the bag's counts say how many; the newest kept picture of each kind fills each place
local function albumList()
	local counts = {view = player:GetAttribute("Item_photo_view") or 0}
	for _, s in ipairs(Subjects) do counts[s.id] = player:GetAttribute("Item_photo_" .. s.id) or 0 end
	local byId = {}
	local function add(m) if counts[m.id] then byId[m.id] = byId[m.id] or {}; table.insert(byId[m.id], m) end end
	for _, m in pairs(metaList) do add(m) end
	for k, m in pairs(pending) do if m.ok and not metaList[k] then add(m) end end
	local list = {}
	for id, n in pairs(counts) do
		local arr = byId[id] or {}
		table.sort(arr, function(a, b) return (a.t or 0) > (b.t or 0) end)
		for i = 1, n do table.insert(list, arr[i] or {k = "old_" .. id .. "_" .. i, id = id, t = 0, old = true}) end
	end
	table.sort(list, function(a, b) if (a.t or 0) ~= (b.t or 0) then return (a.t or 0) < (b.t or 0) end return a.k < b.k end)
	return list
end
local function captionOf(m, long)
	if m.id == "view" then return m.old and "An older view" or "A view" end
	local s = Subjects.byId and Subjects.byId[m.id]
	if long then return s and s.title or "A postcard" end
	return "Postcard: " .. (s and s.short or m.id)
end
-- put photo m into a viewport (or a note while it develops / when it can't be shown)
local function showIn(vpf, note, m)
	if not m then return end
	if worlds[m.k] == nil then develop(m) end
	local w, s = worlds[m.k], shots[m.k]
	if w and s then
		if w.Parent ~= vpf then
			for _, c in ipairs(vpf:GetChildren()) do if c:IsA("WorldModel") and c ~= w then c.Parent = nil end end
			mount(vpf, w, s.cf, s.fov)
		end
		note.Visible = false
	else
		for _, c in ipairs(vpf:GetChildren()) do if c:IsA("WorldModel") then c.Parent = nil end end
		note.Visible = true
		note.Text = (w == false) and (m.old and "An older photo" or "This one didn't come out") or "Developing..."
	end
end

-- ---------- the polaroid you see right after a shot (its scene then goes into the album) ----------
local cardShowing = false
local function showCard(cf, fov, title, sub, extra, key)
	local v = viewport()
	local card = Instance.new("Frame"); card.Name = "Polaroid"; card.AnchorPoint = Vector2.new(0.5, 0.5); card.Size = UDim2.fromOffset(240, 300)
	card.BackgroundColor3 = C(252, 250, 244); card.BorderSizePixel = 0; card.Rotation = -2; card.ZIndex = 10; card.Parent = gui
	corner(card, 6); stroke(card, C(70, 52, 34), 2)
	local x0, y0, x1, y1 = windowRect()
	local top, bottom = 64, v.Y - 176
	card.Position = UDim2.fromOffset((x0 + x1) / 2, (top + bottom) / 2)
	local sc = Instance.new("UIScale"); sc.Scale = 0.5; sc.Parent = card
	local fit = math.min(1, (bottom - top - 8) / 300, (v.X - 40) / 240)
	local _, vpf = photoFrame(card, UDim2.fromOffset(12, 12), UDim2.fromOffset(216, 216), 11)
	local world
	pcall(function() world = buildWorld(cf, fov, extra) end)
	if world then mount(vpf, world, cf, fov) end
	if key then busyDev[key] = true end
	local t1 = Instance.new("TextLabel"); t1.Name = "Title"; t1.Position = UDim2.fromOffset(12, 232); t1.Size = UDim2.fromOffset(216, 30); t1.BackgroundTransparency = 1
	t1.FontFace = FONT; t1.TextScaled = true; t1.TextColor3 = INK; t1.Text = title; t1.ZIndex = 11; t1.Parent = card
	local c1 = Instance.new("UITextSizeConstraint"); c1.MaxTextSize = 21; c1.Parent = t1
	local t2 = Instance.new("TextLabel"); t2.Name = "Sub"; t2.Position = UDim2.fromOffset(12, 262); t2.Size = UDim2.fromOffset(216, 32); t2.BackgroundTransparency = 1
	t2.FontFace = FONT; t2.TextScaled = true; t2.TextWrapped = true; t2.TextColor3 = C(120, 96, 70); t2.Text = sub or ""; t2.ZIndex = 11; t2.Parent = card
	local c2 = Instance.new("UITextSizeConstraint"); c2.MaxTextSize = 14; c2.Parent = t2
	if vr() then
		local head = workspace.CurrentCamera:GetRenderCFrame()
		local holder = Instance.new("Part"); holder.Name = "PolaroidVR"; holder.Anchored = true; holder.CanCollide = false; holder.CanQuery = false
		holder.CanTouch = false; holder.Transparency = 1; holder.Size = Vector3.new(2.4, 3, 0.05)
		local at = head.Position + head.LookVector * 3.2
		holder.CFrame = CFrame.lookAt(at, head.Position); holder.Parent = workspace.CurrentCamera
		local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.CanvasSize = Vector2.new(240, 300); sg.AlwaysOnTop = true; sg.LightInfluence = 0
		sg.Adornee = holder; sg.Parent = pg
		card.Parent = sg; card.Position = UDim2.fromScale(0.5, 0.5); fit = 1
		card.Destroying:Connect(function() sg:Destroy(); holder:Destroy() end)
	end
	cardShowing = true
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = fit}):Play()
	task.delay(3.2, function()
		local tw = TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0})
		tw:Play(); tw.Completed:Wait()
		if key then                                                   -- the album keeps this very scene
			busyDev[key] = nil
			if world and not rejected[key] then world.Parent = nil; worlds[key] = world; shots[key] = {cf = cf, fov = fov} end
		end
		card:Destroy()
		if not gui:FindFirstChild("Polaroid") then cardShowing = false end
	end)
	return card
end

-- a big panel open (shop, passport, map...), or the Daily Acorns card waiting to be collected (nothing goes over it: Shannon).
-- Oct 8 fix: the Daily card used to lower the camera the instant it was raised, with no word why - now it says so.
local function panelOpen() return pg:GetAttribute("OpenPanel") ~= nil end
local function dailyUp()
	local d = pg:FindFirstChild("DailyGui")
	local card = d and d.Enabled and d:FindFirstChild("DailyCard")
	return card ~= nil and card:IsA("GuiObject") and card.Visible
end

-- ---------- raising and lowering the camera (like the binoculars), and zooming ----------
local fov = 45
local saved = {}
local function setFov(f)
	fov = math.clamp(f, 12, 70)
	local cam = workspace.CurrentCamera
	if raised and cam then
		TweenService:Create(cam, TweenInfo.new(0.15), {FieldOfView = fov}):Play()
		UIS.MouseDeltaSensitivity = (saved.sens or 1) * math.max(0.25, fov / 70)
	end
	zoomLabel.Text = string.format("%.1fx", 70 / fov)
end
local function raise()
	if raised or vr() then return end
	if dailyUp() then toast("Collect your Daily Acorns first (the card at the top), then raise the camera.", 3.5) return end
	if panelOpen() then return end
	raised = true
	local cam = workspace.CurrentCamera
	saved = {fov = cam.FieldOfView, mode = player.CameraMode, sens = UIS.MouseDeltaSensitivity,
		dist = (cam.CFrame.Position - cam.Focus.Position).Magnitude}
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	layoutLens(); lens.Visible = true
	setFov(fov)
	toast(touch and "Tap the round button to take a photo. + and - zoom." or "Click to take a photo. Mouse wheel or + / - to zoom. X or right-click to lower.", 3.5)
end
local function lower()
	if not raised then return end
	raised = false
	lens.Visible = false
	hideHeld(false)
	local cam = workspace.CurrentCamera
	if cam then TweenService:Create(cam, TweenInfo.new(0.2), {FieldOfView = saved.fov or 70}):Play() end
	UIS.MouseDeltaSensitivity = saved.sens or 1
	player.CameraMode = saved.mode or Enum.CameraMode.Classic
	if saved.dist and saved.dist > 1 then                       -- step back out of her head, to where the camera was
		local minWas = player.CameraMinZoomDistance
		local push = math.min(saved.dist, player.CameraMaxZoomDistance)
		player.CameraMinZoomDistance = push
		task.delay(0.15, function() if player.CameraMinZoomDistance == push then player.CameraMinZoomDistance = minWas end end)
	end
end
zoomInBtn.MouseButton1Click:Connect(function() setFov(fov - 8) end)
zoomOutBtn.MouseButton1Click:Connect(function() setFov(fov + 8) end)
lowerBtn.MouseButton1Click:Connect(lower)
UIS.InputChanged:Connect(function(input)
	if raised and input.UserInputType == Enum.UserInputType.MouseWheel then setFov(fov - input.Position.Z * 4) end
end)
UIS.InputBegan:Connect(function(input, gp)
	if raised and (input.UserInputType == Enum.UserInputType.MouseButton2 or (input.KeyCode == Enum.KeyCode.X and not gp)) then lower() end
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if raised then layoutLens() end end) end

-- ---------- taking the photo ----------
local last, cards = 0, {}
local function shoot()
	if os.clock() - last < num("Cooldown", 0.8) then return end
	local used = player:GetAttribute("Item_photo_view") or 0
	for _, x in ipairs(Subjects) do used += player:GetAttribute("Item_photo_" .. x.id) or 0 end
	if used >= num("Slots", 4) then toast("Your album is full (4 photos). Sell your postcards or delete a photo first.", 3.5) return end
	last = os.clock()
	shutterSound:Play()
	if not vr() then flash.BackgroundTransparency = 0.25; TweenService:Create(flash, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play() end
	local cf = shotCF()
	local camFov = vr() and 50 or workspace.CurrentCamera.FieldOfView
	local ok, s, why = pcall(evaluate, cf)
	if not ok then s, why = nil, "Hmm, that one came out blurry. Try again!" end
	local whaleS = Subjects.byId and Subjects.byId.whale
	local spouting = whaleS ~= nil and moment(whaleS)
	local _, wm = whaleMesh()
	local extra
	if spouting and wm and (wm.Position - cf.Position).Magnitude < 330 then
		extra = function(world) local _, mesh = whaleMesh(); spoutBalls(world, whaleSpoutBase(mesh)) end
	end
	if not s then
		local m = shotMeta(cf, camFov, spouting); m.id = "view"; pending[m.k] = m
		cards.view = showCard(cf, camFov, "A nice photo", why, extra, m.k)
		toast(why, 3.5); ev:FireServer("shot", "view", m)
		return
	end
	if (player:GetAttribute("Item_photo_" .. s.id) or 0) >= 1 then
		showCard(cf, camFov, s.title, "Already in your bag - sell it to the Postcard Squirrel first!", extra)
		return
	end
	local m = shotMeta(cf, camFov, spouting); m.id = s.id; pending[m.k] = m
	cards[s.id] = showCard(cf, camFov, s.title, "Developing...", extra, m.k)
	ev:FireServer("shot", s.id, m)
end
local hooked = {}
local function hook(t)
	if hooked[t] or not t:IsA("Tool") or t.Name ~= TOOL then return end
	hooked[t] = true
	t.Activated:Connect(function()
		if vr() or raised then shoot() else raise() end
	end)
	t.Equipped:Connect(function()
		holding = true
		toast(vr() and "Pull the trigger to take a photo" or touch and "Tap to raise the camera" or "Click to raise the camera", 2.5)
	end)
	t.Unequipped:Connect(function() holding = false; lower() end)
end
shutterBtn.MouseButton1Click:Connect(function() if raised then shoot() end end)
local function watchContainer(c) if not c then return end for _, t in ipairs(c:GetChildren()) do hook(t) end c.ChildAdded:Connect(hook) end
watchContainer(player:WaitForChild("Backpack"))
player.CharacterAdded:Connect(function(char) holding = false; lower(); watchContainer(char); watchContainer(player:WaitForChild("Backpack")) end)
if player.Character then watchContainer(player.Character) end

-- ---------- what to photograph: a list while you hold the camera, and a camera sign over each sight still wanted ----------
local LABEL = {whale = "The whale's spout", pizza = "Chef Nutmeg's flying pizza", opera = "The opera duet", captain = "The sea captain"}
local wanted = Instance.new("Frame"); wanted.Name = "Wanted"; wanted.Position = UDim2.fromOffset(12, 84); wanted.Size = UDim2.fromOffset(206, 116)
wanted.BackgroundColor3 = BROWN; wanted.BackgroundTransparency = 0.12; wanted.BorderSizePixel = 0; wanted.ZIndex = 6; wanted.Visible = false; wanted.Parent = gui
corner(wanted, 12); stroke(wanted, GOLD, 2)
local wHead = Instance.new("TextLabel"); wHead.Position = UDim2.fromOffset(10, 5); wHead.Size = UDim2.new(1, -20, 0, 20); wHead.BackgroundTransparency = 1; wHead.ZIndex = 7
wHead.FontFace = FONT; wHead.TextSize = 16; wHead.TextColor3 = GOLD; wHead.TextXAlignment = Enum.TextXAlignment.Left; wHead.Text = "Postcards wanted"; wHead.Parent = wanted
local rowsW = {}
for i, s in ipairs(Subjects) do
	local d = Instance.new("Frame"); d.Position = UDim2.fromOffset(10, 32 + (i - 1) * 21); d.Size = UDim2.fromOffset(11, 11); d.BorderSizePixel = 0; d.ZIndex = 7; d.Parent = wanted
	corner(d, 6); stroke(d, GOLD, 1.5)
	local l = Instance.new("TextLabel"); l.Position = UDim2.fromOffset(28, 27 + (i - 1) * 21); l.Size = UDim2.new(1, -34, 0, 20); l.BackgroundTransparency = 1; l.ZIndex = 7
	l.FontFace = FONT; l.TextSize = 14; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = wanted
	rowsW[s.id] = {dot = d, label = l}
end

-- ---------- THE ALBUM: the photos themselves, one at a time (Shannon: "a carousel view") ----------
local albumHead = Instance.new("TextLabel"); albumHead.Position = UDim2.fromOffset(10, 118); albumHead.Size = UDim2.new(1, -20, 0, 20); albumHead.BackgroundTransparency = 1
albumHead.ZIndex = 7; albumHead.FontFace = FONT; albumHead.TextSize = 16; albumHead.TextColor3 = GOLD; albumHead.TextXAlignment = Enum.TextXAlignment.Left; albumHead.Parent = wanted
local function smallButton(parent, text, colour, z)
	local b = Instance.new("TextButton"); b.BackgroundColor3 = colour; b.BorderSizePixel = 0; b.AutoButtonColor = true; b.FontFace = FONT
	b.TextColor3 = colour == GOLD and C(84, 48, 18) or CREAM; b.Text = text; b.ZIndex = z; b.Parent = parent
	corner(b, 8)
	return b
end
local function noteLabel(parent, z)
	local n = Instance.new("TextLabel"); n.Name = "Note"; n.Size = UDim2.fromScale(1, 1); n.BackgroundTransparency = 1; n.ZIndex = z; n.FontFace = FONT
	n.TextColor3 = INK; n.TextScaled = true; n.TextWrapped = true; n.Text = "Developing..."; n.Visible = false; n.Parent = parent
	local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 16; c.Parent = n
	local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0, 6); p.PaddingRight = UDim.new(0, 6); p.Parent = n
	return n
end
-- in the panel: [<] the photo (X in its corner, tap = big) [>], its name and "2/3" under it
local strip = Instance.new("Frame"); strip.Name = "Album"; strip.BackgroundTransparency = 1; strip.Position = UDim2.fromOffset(0, 140); strip.ZIndex = 7; strip.Visible = false; strip.Parent = wanted
local thumb = Instance.new("Frame"); thumb.Name = "Thumb"; thumb.BackgroundColor3 = C(252, 250, 244); thumb.BorderSizePixel = 0; thumb.ZIndex = 7; thumb.Parent = strip
corner(thumb, 4)
local thumbSky, thumbVpf = photoFrame(thumb, UDim2.fromOffset(4, 4), UDim2.new(1, -8, 1, -8), 8)
local thumbNote = noteLabel(thumbSky, 10)
local thumbOpen = Instance.new("TextButton"); thumbOpen.Name = "Open"; thumbOpen.Size = UDim2.fromScale(1, 1); thumbOpen.BackgroundTransparency = 1; thumbOpen.Text = ""; thumbOpen.ZIndex = 11; thumbOpen.Parent = thumb
local thumbDel = smallButton(thumb, "X", RED, 12); thumbDel.Name = "Delete"; thumbDel.AnchorPoint = Vector2.new(1, 0); thumbDel.Position = UDim2.new(1, -3, 0, 3); thumbDel.Size = UDim2.fromOffset(22, 22); thumbDel.TextSize = 14
local prevBtn = smallButton(strip, "<", GOLD, 8); prevBtn.Name = "Prev"; prevBtn.Size = UDim2.fromOffset(22, 34); prevBtn.TextSize = 18
local nextBtn = smallButton(strip, ">", GOLD, 8); nextBtn.Name = "Next"; nextBtn.Size = UDim2.fromOffset(22, 34); nextBtn.TextSize = 18
local caption = Instance.new("TextLabel"); caption.Name = "Caption"; caption.BackgroundTransparency = 1; caption.ZIndex = 7; caption.FontFace = FONT; caption.TextSize = 14
caption.TextColor3 = CREAM; caption.TextXAlignment = Enum.TextXAlignment.Left; caption.TextTruncate = Enum.TextTruncate.AtEnd; caption.Parent = strip
local countL = Instance.new("TextLabel"); countL.Name = "Count"; countL.BackgroundTransparency = 1; countL.ZIndex = 7; countL.FontFace = FONT; countL.TextSize = 14
countL.TextColor3 = GOLD; countL.TextXAlignment = Enum.TextXAlignment.Right; countL.Parent = strip
-- on a phone the panel is too short for a photo: a button opens the big view instead
local seeBtn = smallButton(wanted, "View", GOLD, 8); seeBtn.Name = "SeePhotos"; seeBtn.Position = UDim2.fromOffset(10, 116); seeBtn.TextSize = 15; seeBtn.Visible = false

-- the big view, in the middle of the screen
local viewer = Instance.new("TextButton"); viewer.Name = "AlbumViewer"; viewer.Size = UDim2.fromScale(1, 1); viewer.BackgroundColor3 = C(8, 6, 10)
viewer.BackgroundTransparency = 0.2; viewer.BorderSizePixel = 0; viewer.AutoButtonColor = false; viewer.Text = ""; viewer.ZIndex = 30; viewer.Visible = false; viewer.Parent = gui
local vcard = Instance.new("TextButton"); vcard.Name = "Card"; vcard.AnchorPoint = Vector2.new(0.5, 0.5); vcard.Size = UDim2.fromOffset(240, 330); vcard.AutoButtonColor = false; vcard.Text = ""
vcard.BackgroundColor3 = C(252, 250, 244); vcard.BorderSizePixel = 0; vcard.ZIndex = 31; vcard.Parent = viewer
corner(vcard, 6); stroke(vcard, C(70, 52, 34), 2)
local vscale = Instance.new("UIScale"); vscale.Parent = vcard
local vSky, vVpf = photoFrame(vcard, UDim2.fromOffset(12, 12), UDim2.fromOffset(216, 216), 32)
local vNote = noteLabel(vSky, 34)
local vTitle = Instance.new("TextLabel"); vTitle.Name = "Title"; vTitle.Position = UDim2.fromOffset(12, 232); vTitle.Size = UDim2.fromOffset(216, 28); vTitle.BackgroundTransparency = 1
vTitle.FontFace = FONT; vTitle.TextScaled = true; vTitle.TextColor3 = INK; vTitle.ZIndex = 32; vTitle.Parent = vcard
local vt1 = Instance.new("UITextSizeConstraint"); vt1.MaxTextSize = 21; vt1.Parent = vTitle
local vSub = Instance.new("TextLabel"); vSub.Name = "Sub"; vSub.Position = UDim2.fromOffset(12, 260); vSub.Size = UDim2.fromOffset(216, 20); vSub.BackgroundTransparency = 1
vSub.FontFace = FONT; vSub.TextScaled = true; vSub.TextColor3 = C(120, 96, 70); vSub.ZIndex = 32; vSub.Parent = vcard
local vt2 = Instance.new("UITextSizeConstraint"); vt2.MaxTextSize = 14; vt2.Parent = vSub
local vDel = smallButton(vcard, "Delete", RED, 33); vDel.Name = "Delete"; vDel.Position = UDim2.fromOffset(12, 286); vDel.Size = UDim2.fromOffset(102, 32); vDel.TextSize = 16
local vClose = smallButton(vcard, "Close", GOLD, 33); vClose.Name = "Close"; vClose.Position = UDim2.fromOffset(126, 286); vClose.Size = UDim2.fromOffset(102, 32); vClose.TextSize = 16
local function bigArrow(text)
	local b = smallButton(viewer, text, GOLD, 33); b.AnchorPoint = Vector2.new(0.5, 0.5); b.Size = UDim2.fromOffset(46, 46); b.TextSize = 24
	corner(b, 23); stroke(b, C(150, 98, 36), 2)
	return b
end
local vPrev, vNext = bigArrow("<"), bigArrow(">"); vPrev.Name = "Prev"; vNext.Name = "Next"

local cur = {list = {}, index = 1, newest = nil}
local viewerOpen = false
local armed = {key = nil, at = 0}           -- delete asks once: "tap again"
local function armedFor(m) return m ~= nil and armed.key == m.k and os.clock() - armed.at < 5 end
local function layoutViewer()
	local v = screen()
	local top, bottom = 64, v.Y - (UIS.TouchEnabled and 84 or 30)          -- any touch screen keeps clear of the thumbstick / jump / hotbar
	local fit = math.max(0.4, math.min(1.4, (bottom - top - 10) / 330, (v.X - 150) / 240))
	local cx, cy = v.X / 2, (top + bottom) / 2
	vcard.Position = UDim2.fromOffset(cx, cy); vscale.Scale = fit
	local dx = 120 * fit + 36
	vPrev.Position = UDim2.fromOffset(cx - dx, cy - 45 * fit); vNext.Position = UDim2.fromOffset(cx + dx, cy - 45 * fit)
end
local function refreshViewer()
	local list = cur.list
	local m = list[cur.index]
	if not m then return end
	vTitle.Text = captionOf(m, true)
	if armedFor(m) then vSub.Text = "Tap Delete again to throw it away"; vSub.TextColor3 = RED
	else vSub.Text = string.format("%d of %d", cur.index, #list); vSub.TextColor3 = C(120, 96, 70) end
	vPrev.Visible = #list > 1; vNext.Visible = #list > 1
	showIn(vVpf, vNote, m)
end
local function closeViewer()
	if not viewerOpen then return end
	viewerOpen = false; viewer.Visible = false
	if pg:GetAttribute("OpenPanel") == "album" then pg:SetAttribute("OpenPanel", nil) end
end
local function openViewer()
	if #cur.list == 0 then return end
	viewerOpen = true
	pg:SetAttribute("OpenPanel", "album")
	if raised then lower() end
	layoutViewer(); viewer.Visible = true
	refreshViewer()
end
pg:GetAttributeChangedSignal("OpenPanel"):Connect(function() if viewerOpen and pg:GetAttribute("OpenPanel") ~= "album" then closeViewer() end end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if viewerOpen then layoutViewer() end end) end
local function step(d)
	local n = #cur.list
	if n == 0 then return end
	cur.index = ((cur.index - 1 + d) % n) + 1
	armed.key = nil
	if refreshAlbumUI then refreshAlbumUI() end
end
local function deleteCurrent()
	local m = cur.list[cur.index]
	if not m then return end
	if armedFor(m) then
		armed.key = nil
		ev:FireServer("delete", m.id, m.k)
	else
		armed.key, armed.at = m.k, os.clock()
		task.delay(5.1, function() if refreshAlbumUI then pcall(refreshAlbumUI) end end)
	end
	if refreshAlbumUI then refreshAlbumUI() end
end
prevBtn.MouseButton1Click:Connect(function() step(-1) end)
nextBtn.MouseButton1Click:Connect(function() step(1) end)
vPrev.MouseButton1Click:Connect(function() step(-1) end)
vNext.MouseButton1Click:Connect(function() step(1) end)
thumbDel.MouseButton1Click:Connect(deleteCurrent)
vDel.MouseButton1Click:Connect(deleteCurrent)
thumbOpen.MouseButton1Click:Connect(openViewer)
seeBtn.MouseButton1Click:Connect(openViewer)
vClose.MouseButton1Click:Connect(closeViewer)
viewer.MouseButton1Click:Connect(closeViewer)                  -- a tap beside the photo closes it (the card itself doesn't)

-- lay the panel out: as tall as the photo the screen has room for (the thumbstick / Reset link stay clear below it)
local function panelWidth()
	local width = math.clamp(math.floor(viewport().X * 0.25) - 22, 110, 206)
	if raised then local x0 = windowRect(); width = math.clamp(x0 - 22, 110, 206) end
	return width
end
-- the panel starts under the Hint button wherever that sits (a phone puts it lower: Oct 8 phone check, nothing may overlap)
local function panelTop()
	local hg = pg:FindFirstChild("HintGui")
	local b = hg and hg.Enabled and hg:FindFirstChild("HintButton")
	if b and b:IsA("GuiObject") and b.Visible then
		local inset = game:GetService("GuiService"):GetGuiInset()
		return math.max(84, math.floor(b.AbsolutePosition.Y + inset.Y + b.AbsoluteSize.Y + 8))
	end
	return 84
end
refreshAlbumUI = function()
	local list = albumList()
	cur.list = list
	local newest = #list > 0 and list[#list].k or nil
	if newest ~= cur.newest then cur.newest = newest; cur.index = #list end      -- a new photo: show it
	cur.index = math.clamp(cur.index, 1, math.max(1, #list))
	local width = panelWidth()
	local v = screen()
	local top = panelTop()
	wanted.Position = UDim2.fromOffset(12, top)
	local S = math.floor(math.min(width - 64, v.Y - (UIS.TouchEnabled and 100 or 50) - top - 140 - 30, 150))
	local mode = #list == 0 and "none" or ((S >= 64 and not vr()) and "strip" or "button")   -- VR: the button, the photos open big
	local h = 146
	-- phone / VR: "Album 2/4 [View]" on one line, so the panel stays as short as it was
	albumHead.Size = UDim2.new(1, mode == "button" and -84 or -20, 0, 20)
	albumHead.Text = string.format((mode == "button" and width < 190) and "Album %d/%d" or "Your album %d/%d", #list, num("Slots", 4))
	if mode == "strip" then
		strip.Size = UDim2.fromOffset(width, S + 26)
		thumb.Position = UDim2.fromOffset(math.floor((width - S) / 2), 0); thumb.Size = UDim2.fromOffset(S, S)
		prevBtn.Position = UDim2.fromOffset(6, math.floor(S / 2) - 17); nextBtn.Position = UDim2.fromOffset(width - 28, math.floor(S / 2) - 17)
		prevBtn.Visible = #list > 1; nextBtn.Visible = #list > 1
		caption.Position = UDim2.fromOffset(10, S + 5); caption.Size = UDim2.fromOffset(width - 56, 18)
		countL.Position = UDim2.fromOffset(width - 46, S + 5); countL.Size = UDim2.fromOffset(36, 18)
		local m = list[cur.index]
		if armedFor(m) then caption.Text = "Tap X again to delete"; caption.TextColor3 = C(255, 150, 120)
		else caption.Text = m and captionOf(m, false) or ""; caption.TextColor3 = CREAM end
		countL.Text = string.format("%d/%d", cur.index, #list)
		h = 140 + S + 30
		if not viewerOpen then showIn(thumbVpf, thumbNote, m) end
	elseif mode == "button" then
		seeBtn.Position = UDim2.fromOffset(width - 70, 116); seeBtn.Size = UDim2.fromOffset(60, 24)
	end
	strip.Visible = mode == "strip"; seeBtn.Visible = mode == "button"
	wanted.Size = UDim2.fromOffset(width, h)
	if viewerOpen then
		if #list == 0 or not holding then closeViewer() else refreshViewer() end
	end
	-- scenes of photos that have left the album (sold, deleted) are thrown away
	local keep = {}
	for _, m in ipairs(list) do keep[m.k] = true end
	for k, w in pairs(worlds) do
		if not keep[k] and not pending[k] and not metaList[k] then
			if w then w:Destroy() end
			worlds[k] = nil; shots[k] = nil
		end
	end
end

local markers = {}
local function markerFor(s)
	local m = markers[s.id]
	if m then return m end
	m = Instance.new("BillboardGui"); m.Name = "PostcardMarker_" .. s.id; m.Size = UDim2.fromOffset(60, 70); m.AlwaysOnTop = true; m.LightInfluence = 0
	m.MaxDistance = 3000; m.Enabled = false; m.Parent = pg
	local img = Instance.new("ImageLabel"); img.Size = UDim2.fromOffset(46, 46); img.Position = UDim2.fromOffset(7, 0); img.BackgroundTransparency = 1; img.Image = ICON; img.Parent = m
	local t = Instance.new("TextLabel"); t.Position = UDim2.fromOffset(-20, 46); t.Size = UDim2.fromOffset(100, 20); t.BackgroundTransparency = 1
	t.FontFace = FONT; t.TextSize = 14; t.TextColor3 = CREAM; t.TextStrokeTransparency = 0.25; t.Text = s.short; t.Parent = m
	markers[s.id] = m
	return m
end
local function adorneeFor(s)
	if s.id == "whale" then local _, mesh = whaleMesh(); return mesh, Vector3.new(0, 9, 0) end
	local m = model(s.model)
	return m and (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)), Vector3.new(0, 3.4, 0)
end
local function refreshWanted()
	wanted.Visible = holding and not panelOpen()                       -- in VR too now (Oct 8: the album has to be reachable there)
	local width = panelWidth()
	local short = width < 190
	for _, s in ipairs(Subjects) do
		local got = (player:GetAttribute("Item_photo_" .. s.id) or 0) > 0
		local r = rowsW[s.id]
		r.dot.BackgroundColor3 = got and C(120, 200, 110) or BROWN
		r.label.TextColor3 = got and C(190, 230, 170) or CREAM
		r.label.Text = (short and (s.short:sub(1, 1):upper() .. s.short:sub(2)) or (LABEL[s.id] or s.title)) .. (got and (short and " - got!" or " - got it!") or "")
		local m = markerFor(s)
		local a, off = adorneeFor(s)
		m.Adornee = a; if off then m.StudsOffset = off end
		m.Enabled = holding and not got and a ~= nil
	end
	refreshAlbumUI()
	if raised and (panelOpen() or dailyUp()) then lower() end
end
task.spawn(function() while gui.Parent do task.wait(0.25); pcall(refreshWanted) end end)
-- in VR: a gold ring where the camera in your hand is pointing
local aimAtt = Instance.new("Attachment"); aimAtt.Name = "CameraAimPoint"; aimAtt.Parent = workspace.Terrain
local aim = Instance.new("BillboardGui"); aim.Name = "CameraAim"; aim.Size = UDim2.fromOffset(36, 36); aim.AlwaysOnTop = true; aim.LightInfluence = 0
aim.Adornee = aimAtt; aim.Enabled = false; aim.Parent = pg
local ring = Instance.new("Frame"); ring.Size = UDim2.fromScale(1, 1); ring.BackgroundTransparency = 1; ring.Parent = aim; corner(ring, 18); stroke(ring, GOLD, 3)
RunService.RenderStepped:Connect(function()
	if raised then hideHeld(true) end
	local on = holding and vr()
	aim.Enabled = on
	if on then
		local cf = shotCF()
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {player.Character}
		local hit = workspace:Raycast(cf.Position, cf.LookVector * 80, params)
		aimAtt.WorldPosition = hit and hit.Position or (cf.Position + cf.LookVector * 40)
	end
end)

-- ---------- the Postcard Squirrel ----------
-- Oct 8 2026 fix: never WaitForChild the SellSpot - it is a part, and with streaming it is not loaded while you are far away
-- (you start in France), which stalled the rest of this script (the postcard messages) in the live game.
local function refreshPrompt()
	local spot = G:FindFirstChild("SellSpot")
	local prompt = spot and spot:FindFirstChild("SellPrompt")
	if not prompt then return end
	local any = false
	for _, s in ipairs(Subjects) do if (player:GetAttribute("Item_photo_" .. s.id) or 0) > 0 then any = true end end
	prompt.Enabled = any
end
for _, s in ipairs(Subjects) do player:GetAttributeChangedSignal("Item_photo_" .. s.id):Connect(refreshPrompt) end
G.ChildAdded:Connect(function(c) if c.Name == "SellSpot" then c:WaitForChild("SellPrompt", 10); refreshPrompt() end end)
refreshPrompt()
local function setSub(id, text) local c = cards[id]; if c and c.Parent then local t = c:FindFirstChild("Sub"); if t then t.Text = text end end end
local function drop(key)                                            -- CameraServer said no: that photo isn't kept
	if type(key) ~= "string" then return end
	pending[key] = nil; rejected[key] = true
	local w = worlds[key]
	if w then w:Destroy() end
	worlds[key] = nil; shots[key] = nil
end
local function confirm(key) if type(key) == "string" and pending[key] then pending[key].ok = true end end
ev.OnClientEvent:Connect(function(what, a, b, c)
	if what == "album" then
		metaList = {}
		for _, m in ipairs(type(a) == "table" and a or {}) do
			if type(m) == "table" and type(m.k) == "string" and type(m.id) == "string" then metaList[m.k] = m; pending[m.k] = nil end
		end
		pcall(refreshAlbumUI)
	elseif what == "got" then confirm(b); setSub(a, "Postcard saved! Sell it to the Postcard Squirrel.")
		toast("Postcard saved! The Postcard Squirrel on the lighthouse path will buy it.", 3.2)
	elseif what == "have" then drop(b); setSub(a, "Already in your bag - sell it first!")
	elseif what == "kept" then confirm(c); setSub("view", "Saved to your album (" .. tostring(b) .. "/" .. num("Slots", 4) .. "). Don't want it? Delete it from the album.")
	elseif what == "full" then drop(b); setSub(a, "Album full!"); toast("Your album is full (4 photos). Sell your postcards or delete a photo first.", 3.5)
	elseif what == "deleted" then toast("Photo deleted.", 2)
	elseif what == "nope" then drop(b); setSub(a, "Blurry - try again!"); toast("Hmm, that one came out blurry. Try again!", 3)
	elseif what == "sold" then
		local sold, pay, stamp = a or {}, b or 0, c
		local speaker = model("postcard_squirrel_color")
		local line
		if #sold == 0 then line = "No photos? Bring me pictures of Porto and I'll buy them!"
		elseif #sold >= #Subjects then line = "Magnifico! The whale, the pizza, the duet AND the captain! " .. pay .. " acorns for you!"
		elseif table.find(sold, "whale") then line = "A whale spout?! The tourists will love it! " .. pay .. " acorns for you."
		else line = "Bellissimo! I'll print these right away. " .. pay .. " acorns for you." end
		if speaker then Bubble.say(speaker, line, {secs = 4.5}) end
		if pay > 0 then toast("+" .. pay .. " acorns!", 2.5) end
		if stamp then task.delay(2.6, function() toast("Passport stamp: Postcards from Porto!", 3) end) end
	end
end)
ev:FireServer("album?")
print("CameraClient v3: ready - the album shows the photos")
