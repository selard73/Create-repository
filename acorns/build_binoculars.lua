-- Binoculars: the Acorn Store's Robux item (Item_binoculars, owned for good through a GAME PASS). Hold the button
-- (tap to toggle on a phone) and the camera drops into first person and narrows from the usual 70 degrees to
-- about 18, behind a binocular mask, with mouse sensitivity scaled down so the zoomed view is steerable - and
-- while you look through them, EVERY SQUIRREL YOU HAVE NOT FOUND within RevealRange glows red, through trees and
-- walls (a Highlight drawn on top of everything, the same glow the hint uses). Let go and it all comes back.
-- Shannon: "special binoculars that show hiding squirrels more easily, like makes them glow red and show through
-- objects in front of them; this item should only be available with robux purchase".
--
-- HOW THEY ARE HELD. Equipped, the binoculars rest against the chest in both hands, pointing a little down; when
-- you zoom they rise to the eyes and the hands come up with them, over ZoomTime, and drop back when you let go.
-- Shannon: "the way player is holding them looks weird, is there a way to have player holding them to their
-- face like looking through them?" then "rest at chest until zoom is better". The default tool grip (one arm
-- straight out, binoculars pointed at the sky) came from Roblox's tool-hold animation, which only plays for a
-- tool with a part named Handle; so the left barrel is the Body instead, RequiresHandle is off, and a server
-- script (BinocularsHold) welds the Body to the UpperTorso on equip and tweens the weld between the chest frame
-- and the eye frame - both expressed in the torso's frame, so it is one weld that slides, never a re-weld. The
-- zoom is the client's, so the tool's client tells the server through the Raise RemoteEvent, which accepts it
-- only from whoever is holding this tool. The arms are posed on EVERY client by BinocularsPose: a two-bone IK
-- per arm in the torso's frame, aimed at the barrels wherever they are, written to the joints' Transform each
-- Stepped - the moment after the animator has written its own - so walking moves the legs and torso but the
-- hands stay on the barrels; the two solutions are blended over ZoomTime to match the sliding weld, and while
-- the binoculars are at the eyes the neck is held at rest so the idle's look-around does not carry the head off
-- the hands. Your own binoculars are hidden from you while zoomed (the mask stands in for them) or whenever the
-- camera is at your face, so they never fill the screen.
--
-- EVERYTHING VISIBLE HAPPENS ON THE OWNER'S SCREEN: the camera, the mask, the sensitivity and the glows are the
-- client's own (a Highlight made on a client exists only there), and the "not found yet" test reads the FoundIds
-- attribute the server already publishes for the hint shop. The server does two things: it grants Item_binoculars
-- to anyone who owns the Game Pass (checked on join, and the moment a purchase completes), and hands out the tool
-- to whoever has the item, on every spawn. Nothing here touches the DataStore or sells anything for acorns.
--
-- THE GAME PASS is Shannon's ("Spotter's Binoculars", id 1991720687, created Sep 23 2026); its id lives in the
-- BinocularsPassId attribute on workspace.Binoculars (0 = not configured: the shop row says "coming soon").
-- Tunable in Properties on workspace.Binoculars: ZoomFov (18), ZoomTime (0.25, also the raise), ZoomSensitivity
-- (0.3), RevealRange (studs, 110), ZoomSoundId (0 = none), ZoomVolume, BinocularsPassId; the hold: ChestForward
-- / ChestUp / ChestTilt (the rest, past the chest, in degrees of droop), EyeForward / EyeUp (the raise, past the
-- face), GripX/GripY/GripZ (where each hand lands on the barrels, in the binoculars' frame, X mirrored for the
-- left hand), PoleX/PoleY/PoleZ (which way the elbows point).
-- Re-runnable: rebuilds the tool template, the Raise event and all four scripts.
-- Run in edit mode: require(workspace.Binoculars.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local SS = game:GetService("ServerStorage")
	local C = Color3.fromRGB
	local BLACK, STEEL, LENS = C(38, 36, 40), C(120, 122, 128), C(70, 110, 150)

	local F = workspace:FindFirstChild("Binoculars")
	if not F then F = Instance.new("Folder"); F.Name = "Binoculars"; F.Parent = workspace end
	F:SetAttribute("ZoomFov", opts.zoomFov or 18)
	F:SetAttribute("ZoomTime", opts.zoomTime or 0.25)
	F:SetAttribute("ZoomSensitivity", opts.zoomSensitivity or 0.3)
	F:SetAttribute("RevealRange", opts.revealRange or 110)
	F:SetAttribute("ZoomSoundId", opts.zoomSound or 0)
	F:SetAttribute("ZoomVolume", opts.zoomVolume or 0.6)
	-- the pass "Spotter's Binoculars" (99 Robux), created Sep 23 2026; an id already on the folder is kept
	if F:GetAttribute("BinocularsPassId") == nil then F:SetAttribute("BinocularsPassId", opts.passId or 1991720687) end
	-- the hold (see BinocularsHold and BinocularsPose)
	F:SetAttribute("ChestForward", opts.chestForward or 0.75); F:SetAttribute("ChestUp", opts.chestUp or 0.15); F:SetAttribute("ChestTilt", opts.chestTilt or -25)
	F:SetAttribute("EyeForward", opts.eyeForward or 0.80); F:SetAttribute("EyeUp", opts.eyeUp or 0.05)
	F:SetAttribute("GripX", opts.gripX or 0.95); F:SetAttribute("GripY", opts.gripY or -0.12); F:SetAttribute("GripZ", opts.gripZ or 0.30)
	F:SetAttribute("PoleX", opts.poleX or 0.7); F:SetAttribute("PoleY", opts.poleY or -0.6); F:SetAttribute("PoleZ", opts.poleZ or -0.35)
	local raise = F:FindFirstChild("Raise")
	if not raise then raise = Instance.new("RemoteEvent"); raise.Name = "Raise"; raise.Parent = F end

	-- ---------------------------------------------------------------- the tool ----
	-- Two barrels and a bridge, welded to the left barrel, which is the Body (NOT a Handle: see the header).
	-- Cylinders run along X, so each barrel is turned a quarter turn to point forward (-Z). The binoculars' own
	-- frame has its origin between the barrels; the Body sits at (-0.4, 0, 0) in it, turned by FWD.
	local oldT = SS:FindFirstChild("BinocularsTool"); if oldT then oldT:Destroy() end
	local tool = Instance.new("Tool"); tool.Name = "BinocularsTool"; tool.ToolTip = "Hold to look closer - hidden squirrels glow"
	tool.CanBeDropped = false; tool.RequiresHandle = false
	tool.TextureId = "rbxassetid://" .. (opts.icon or 130972021255978)   -- the hotbar icon (marketing/icon_binoculars.png, decal 81014897590131)
	local function tpart(name, size, cf, color, material, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf
		p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
		if shape then p.Shape = shape end
		p.Anchored = false; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = tool
		return p
	end
	local FWD = CFrame.Angles(0, math.rad(90), 0)                 -- a cylinder's X axis turned to -Z
	local body = tpart("Body", Vector3.new(1.5, 0.62, 0.62), CFrame.new(-0.4, 0, 0) * FWD, BLACK, nil, Enum.PartType.Cylinder)
	local function weld(p) local w = Instance.new("WeldConstraint"); w.Part0 = body; w.Part1 = p; w.Parent = p end
	weld(tpart("Barrel", Vector3.new(1.5, 0.62, 0.62), CFrame.new(0.4, 0, 0) * FWD, BLACK, nil, Enum.PartType.Cylinder))
	weld(tpart("Bridge", Vector3.new(0.5, 0.22, 0.5), CFrame.new(0, 0.12, 0.1), STEEL, Enum.Material.Metal))
	for _, x in ipairs({-0.4, 0.4}) do
		weld(tpart("Lens", Vector3.new(0.06, 0.5, 0.5), CFrame.new(x, 0, -0.76) * FWD, C(200, 60, 60), Enum.Material.Glass, Enum.PartType.Cylinder))
		weld(tpart("Eyecup", Vector3.new(0.12, 0.46, 0.46), CFrame.new(x, 0, 0.78) * FWD, C(20, 20, 22), Enum.Material.Rubber, Enum.PartType.Cylinder))
	end
	tool.Parent = SS

	-- ---------------------------------------------------------------- the hold (server, in the tool) ----
	-- One weld, Body to UpperTorso. Equip puts it at the chest frame; Raise slides it to the eye frame (the head
	-- through the neck at rest, pushed past the face) and back, over ZoomTime. The character carries
	-- BinocularsUp = "chest" | "eyes" for the pose script on every client. Unequip undoes it all.
	local HOLD = [==[
local TweenService = game:GetService("TweenService")
local tool = script.Parent
local body = tool:WaitForChild("Body")
local F = workspace:WaitForChild("Binoculars")
local raise = F:WaitForChild("Raise")
local FWD = CFrame.Angles(0, math.rad(90), 0)
local BODY = CFrame.new(-0.4, 0, 0) * FWD                      -- the Body's place in the binoculars' own frame
local function cfg(name, default) local v = F:GetAttribute(name); return v ~= nil and v or default end
local function frames(j)                                       -- parent-side and child-side frames of a joint
	if j:IsA("Motor6D") then return j.C0, j.C1 end
	if j:IsA("AnimationConstraint") then return j.Attachment0 and j.Attachment0.CFrame or CFrame.new(), j.Attachment1 and j.Attachment1.CFrame or CFrame.new() end
	return nil
end
local function chestFrame(torso)
	return CFrame.new(0, cfg("ChestUp", 0.15), -(torso.Size.Z / 2 + cfg("ChestForward", 0.75))) * CFrame.Angles(math.rad(cfg("ChestTilt", -25)), 0, 0)
end
local function eyeFrame(torso, head)
	local neck = head:FindFirstChild("Neck")
	local n0, n1
	if neck then n0, n1 = frames(neck) end                    -- ("neck and frames(neck)" would keep only n0)
	local headF = (n0 and n1) and (n0 * n1:Inverse()) or CFrame.new(0, torso.Size.Y / 2 + head.Size.Y / 2, 0)
	return headF * CFrame.new(0, cfg("EyeUp", 0.05), -(head.Size.Z / 2 + cfg("EyeForward", 0.8)))
end
local weld, holder, tween
local function down()
	if tween then tween:Cancel(); tween = nil end
	if weld then weld:Destroy(); weld = nil end
	if holder then holder:SetAttribute("BinocularsUp", nil); holder = nil end
end
local function up(char)
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if not torso then return end
	down()
	weld = Instance.new("Weld"); weld.Name = "HoldWeld"; weld.Part0 = torso; weld.Part1 = body
	weld.C0 = chestFrame(torso) * BODY; weld.C1 = CFrame.new(); weld.Parent = body
	holder = char
	char:SetAttribute("BinocularsUp", "chest")
end
local function setRaised(on)
	if not (weld and holder) then return end
	local torso, head = weld.Part0, holder:FindFirstChild("Head")
	if not (torso and head) then return end
	if tween then tween:Cancel() end
	tween = TweenService:Create(weld, TweenInfo.new(cfg("ZoomTime", 0.25), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{C0 = (on and eyeFrame(torso, head) or chestFrame(torso)) * BODY})
	tween:Play()
	holder:SetAttribute("BinocularsUp", on and "eyes" or "chest")
end
tool.Equipped:Connect(function()
	local char = tool.Parent
	if char and char:FindFirstChildOfClass("Humanoid") then up(char) end
end)
tool.Unequipped:Connect(down)
tool.AncestryChanged:Connect(function() if not tool:IsDescendantOf(game) then down() end end)
raise.OnServerEvent:Connect(function(pl, on)
	if holder and pl.Character == holder then setRaised(on == true) end
end)
]==]
	local hs = Instance.new("Script"); hs.Name = "BinocularsHold"; hs.Source = HOLD; hs.Parent = tool

	-- ---------------------------------------------------------------- the client half ----
	local CLIENT = [==[
local tool = script.Parent
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local C = Color3.fromRGB
local touch = UIS.TouchEnabled and not UIS.MouseEnabled       -- a phone toggles; a mouse holds
local raise = workspace:WaitForChild("Binoculars"):WaitForChild("Raise")
local function cfg(name, default)
	local F = workspace:FindFirstChild("Binoculars")
	local v = F and F:GetAttribute(name)
	return v ~= nil and v or default
end

-- the mask: one wide oval of clear glass in a black field (the film-binocular shape), a seam and a fine ring
local gui = Instance.new("ScreenGui"); gui.Name = "BinocularMask"; gui.ResetOnSpawn = false; gui.DisplayOrder = 9
gui.IgnoreGuiInset = true; gui.Enabled = false; gui.Parent = player:WaitForChild("PlayerGui")
local eye = Instance.new("Frame"); eye.AnchorPoint = Vector2.new(0.5, 0.5); eye.Position = UDim2.fromScale(0.5, 0.5)
eye.BackgroundTransparency = 1; eye.Parent = gui
local ring = Instance.new("UIStroke"); ring.Color = C(0, 0, 0); ring.Thickness = 900; ring.Parent = eye
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = eye
local seam = Instance.new("Frame"); seam.AnchorPoint = Vector2.new(0.5, 0.5); seam.Position = UDim2.fromScale(0.5, 0.5)
seam.Size = UDim2.new(0, 3, 1, 0); seam.BackgroundColor3 = C(0, 0, 0); seam.BackgroundTransparency = 0.55; seam.BorderSizePixel = 0; seam.Parent = gui
local cross = Instance.new("Frame"); cross.AnchorPoint = Vector2.new(0.5, 0.5); cross.Position = UDim2.fromScale(0.5, 0.5)
cross.Size = UDim2.fromOffset(18, 18); cross.BackgroundTransparency = 1; cross.Parent = gui
local cs = Instance.new("UIStroke"); cs.Color = C(255, 120, 120); cs.Thickness = 1.5; cs.Transparency = 0.3; cs.Parent = cross
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1, 0); cc.Parent = cross
local function fit()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local d = math.min(vp.X * 0.62, vp.Y * 0.92)
	eye.Size = UDim2.fromOffset(d * 1.45, d)
end
fit()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end

-- THE REVEAL. Every squirrel this player has not found, within RevealRange, gets a red Highlight drawn on top of
-- everything - so it shows through the tree it is hiding behind. Highlights made here exist on this client only.
-- "Not found" is the FoundIds attribute the server publishes for the hint shop; the colour model is the one
-- players see, the gray twin is skipped.
local glows = {}                                              -- model -> Highlight
local squirrels, scannedAt = {}, 0
local function idOf(m) return m:GetAttribute("SquirrelId") or (m.Name:lower():gsub("_color$", "")) end
local function scan()
	squirrels = {}
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and (m:GetAttribute("SquirrelId") or m.Name:lower():match("_color$")) and not m.Name:lower():find("gray") then
			table.insert(squirrels, m)
		end
	end
	scannedAt = os.clock()
end
local function foundSet()
	local s = {}
	for id in string.gmatch(player:GetAttribute("FoundIds") or "", "[^,]+") do s[id] = true end
	return s
end
local function clearGlows()
	for m, hl in pairs(glows) do if hl then hl:Destroy() end end
	glows = {}
end
local function reveal()
	if os.clock() - scannedAt > 15 or #squirrels == 0 then scan() end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local found = foundSet()
	local range = cfg("RevealRange", 110)
	local keep = {}
	for _, m in ipairs(squirrels) do
		if m.Parent and not found[idOf(m)] then
			local d = (m:GetPivot().Position - root.Position).Magnitude
			if d <= range then
				keep[m] = true
				if not glows[m] then
					local hl = Instance.new("Highlight"); hl.Name = "BinoGlow"; hl.Adornee = m
					hl.FillColor = C(255, 60, 60); hl.FillTransparency = 0.3
					hl.OutlineColor = C(255, 150, 150); hl.OutlineTransparency = 0
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Parent = m
					glows[m] = hl
				end
			end
		end
	end
	for m, hl in pairs(glows) do
		if not keep[m] then hl:Destroy(); glows[m] = nil end
	end
end

local zoomed = false
local savedFov, savedMode, savedSens, savedDist
local revealConn
local function setZoom(on)
	if on == zoomed then return end
	zoomed = on
	raise:FireServer(on)                                      -- the binoculars and the hands rise, for everyone
	local cam = workspace.CurrentCamera
	if not cam then return end
	local t = cfg("ZoomTime", 0.25)
	if on then
		savedFov, savedMode, savedSens = cam.FieldOfView, player.CameraMode, UIS.MouseDeltaSensitivity
		local head = player.Character and player.Character:FindFirstChild("Head")
		savedDist = head and (cam.CFrame.Position - head.Position).Magnitude or nil
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		UIS.MouseDeltaSensitivity = cfg("ZoomSensitivity", 0.3)
		gui.Enabled = true; fit()
		TweenService:Create(cam, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = cfg("ZoomFov", 18)}):Play()
		local id = tonumber(cfg("ZoomSoundId", 0)) or 0
		if id > 0 then
			local s = Instance.new("Sound"); s.SoundId = "rbxassetid://" .. id; s.Volume = cfg("ZoomVolume", 0.6)
			s.Parent = game:GetService("SoundService"); s:Play(); Debris:AddItem(s, 6)
		end
		reveal()
		revealConn = task.spawn(function()
			while zoomed do task.wait(0.4); if zoomed then reveal() end end
		end)
	else
		gui.Enabled = false
		TweenService:Create(cam, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = savedFov or 70}):Play()
		player.CameraMode = savedMode or Enum.CameraMode.Classic
		UIS.MouseDeltaSensitivity = savedSens or 1
		clearGlows()
		-- leaving first person does not bring the camera back out by itself (measured: it stayed 0.6 from the
		-- head), so the minimum zoom is raised to where the camera was for a moment, which pushes it back there
		if savedDist and savedDist > 1.5 then
			local minWas = player.CameraMinZoomDistance
			local pushed = math.min(savedDist, player.CameraMaxZoomDistance)
			player.CameraMinZoomDistance = pushed
			task.delay(0.15, function() if player.CameraMinZoomDistance == pushed then player.CameraMinZoomDistance = minWas end end)
		end
	end
end

-- YOUR OWN BINOCULARS ARE INVISIBLE TO YOU while you look through them (the mask stands in for them) and whenever
-- the camera is right at your face, or they would fill the screen. Everyone else sees them.
local parts = {}
for _, p in ipairs(tool:GetDescendants()) do if p:IsA("BasePart") then table.insert(parts, p) end end
local function setHidden(h) for _, p in ipairs(parts) do p.LocalTransparencyModifier = h and 1 or 0 end end
local hideConn
tool.Equipped:Connect(function()
	if hideConn then hideConn:Disconnect() end
	hideConn = RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local head = player.Character and player.Character:FindFirstChild("Head")
		setHidden(zoomed or (cam ~= nil and head ~= nil and (cam.CFrame.Position - head.Position).Magnitude < 1.8))
	end)
end)
tool.Unequipped:Connect(function()
	if hideConn then hideConn:Disconnect(); hideConn = nil end
	setHidden(false)
end)

tool.Activated:Connect(function()
	if touch then setZoom(not zoomed) else setZoom(true) end
end)
tool.Deactivated:Connect(function()
	if not touch then setZoom(false) end
end)
tool.Unequipped:Connect(function() setZoom(false) end)
tool.AncestryChanged:Connect(function() if not tool:IsDescendantOf(game) then setZoom(false) end end)
-- a squirrel found while looking loses its glow at once
player:GetAttributeChangedSignal("FoundIds"):Connect(function() if zoomed then reveal() end end)
]==]
	local ls = Instance.new("LocalScript"); ls.Name = "BinocularsClient"; ls.Source = CLIENT; ls.Parent = tool

	-- ---------------------------------------------------------------- the pose (every client) ----
	-- Whoever carries BinocularsUp gets both arms posed on THIS client, so everyone sees the same spotter. Joints
	-- are Motor6Ds on older rigs and AnimationConstraints on newer ones; both carry Transform, the animator's
	-- per-frame offset, and a Transform written in Stepped replaces what the animator just wrote.
	local POSE = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local F = script.Parent
local function cfg(name, default) local v = F:GetAttribute(name); return v ~= nil and v or default end
local function frames(j)                                       -- parent-side and child-side frames of a joint
	if j:IsA("Motor6D") then return j.C0, j.C1 end
	if j:IsA("AnimationConstraint") then return j.Attachment0 and j.Attachment0.CFrame or CFrame.new(), j.Attachment1 and j.Attachment1.CFrame or CFrame.new() end
	return nil
end
local function jointOf(char, part, name) local p = char:FindFirstChild(part); return p and p:FindFirstChild(name) end

-- WHERE THE BINOCULARS ARE, in the UpperTorso's frame - the same two frames BinocularsHold welds them to
local function binoFrame(char, st)
	local torso, head = char:FindFirstChild("UpperTorso"), char:FindFirstChild("Head")
	if not (torso and head) then return nil end
	if st == "eyes" then
		local neck = head:FindFirstChild("Neck")
		local n0, n1
		if neck then n0, n1 = frames(neck) end
		local headF = (n0 and n1) and (n0 * n1:Inverse()) or CFrame.new(0, torso.Size.Y / 2 + head.Size.Y / 2, 0)
		return headF * CFrame.new(0, cfg("EyeUp", 0.05), -(head.Size.Z / 2 + cfg("EyeForward", 0.8)))
	end
	return CFrame.new(0, cfg("ChestUp", 0.15), -(torso.Size.Z / 2 + cfg("ChestForward", 0.75))) * CFrame.Angles(math.rad(cfg("ChestTilt", -25)), 0, 0)
end

-- TWO-BONE IK, in the UpperTorso's frame, on the rig's REAL bones. Roblox composes a joint as Part1 = Part0 *
-- C0 * Transform * C1^-1 (checked to 0.00 studs), so with unrotated rig attachments the elbow sits at S + R1*u
-- and the hand's centre at S + R1*(u + R2*w), where u and w are the bone vectors read off the attachments - and
-- on this game's avatars they are NOT straight down: the upper arm bone runs (0.40, -0.56, 0.07), out as much
-- as down, which is why a straight-down assumption sent the arms over the head. The elbow bends about its X by
-- phi until the bent arm's length is |T - S| (a cos + b sin = c), then the whole arm is turned so its end lands
-- on T, with the bend plane set by a pole vector so the elbows point out, down and a little forward. With the
-- binoculars at the eyes the neck is held at rest, so the head - and the binoculars on it - stay with the hands.
local function solve(char, st)
	local bino = binoFrame(char, st)
	if not bino then return nil end
	local pose = {}
	local arms = 0
	for _, side in ipairs({"Right", "Left"}) do
		local sgn = side == "Right" and 1 or -1
		local sh = jointOf(char, side .. "UpperArm", side .. "Shoulder")
		local el = jointOf(char, side .. "LowerArm", side .. "Elbow")
		local wr = jointOf(char, side .. "Hand", side .. "Wrist")
		if sh and el and wr and frames(sh) and frames(el) and frames(wr) then
			local s0, s1 = frames(sh); local e0, e1 = frames(el); local w0, w1 = frames(wr)
			local S = s0.Position                                        -- the shoulder joint, torso frame
			local u = e0.Position - s1.Position                          -- shoulder to elbow, in the upper arm's frame
			local w = (w0.Position - e1.Position) - w1.Position          -- elbow to the hand's centre, in the lower arm's
			local T = (bino * CFrame.new(sgn * cfg("GripX", 0.95), cfg("GripY", -0.12), cfg("GripZ", 0.3))).Position
			local d = T - S
			local D = d.Magnitude
			-- the elbow bends about the lower arm's X by phi until |u + R2 w| = D: u.(R2 w) = K + A cos + B sin
			local K = u.X * w.X
			local A = u.Y * w.Y + u.Z * w.Z
			local B = u.Z * w.Y - u.Y * w.Z
			local M = (D * D - u.Magnitude ^ 2 - w.Magnitude ^ 2) / 2
			local delta = math.atan2(B, A)
			local alpha = math.acos(math.clamp((M - K) / math.max(math.sqrt(A * A + B * B), 1e-6), -1, 1))
			local function norm(x) return math.atan2(math.sin(x), math.cos(x)) end
			local phi, phi2 = norm(delta + alpha), norm(delta - alpha)
			-- of the two bends take the forward one (0..180); if both are, the one nearer a natural 110 degrees
			local ok1, ok2 = phi > 0 and phi < math.pi, phi2 > 0 and phi2 < math.pi
			if ok2 and (not ok1 or math.abs(phi2 - math.rad(110)) < math.abs(phi - math.rad(110))) then phi = phi2 end
			local R2 = CFrame.Angles(phi, 0, 0)
			local e = u + R2 * w                                         -- the hand, arm bent, before the turn
			local ne = u:Cross(e)
			if ne.Magnitude < 1e-4 then ne = Vector3.new(1, 0, 0) end
			local pole = Vector3.new(sgn * cfg("PoleX", 0.7), cfg("PoleY", -0.6), cfg("PoleZ", -0.35))
			local nd = pole:Cross(d)
			if nd.Magnitude < 1e-4 then nd = Vector3.new(sgn, 0, 0) end
			pose[sh] = CFrame.fromMatrix(Vector3.zero, nd.Unit, d.Unit) * CFrame.fromMatrix(Vector3.zero, ne.Unit, e.Unit):Inverse()
			pose[el] = R2
			pose[wr] = CFrame.new()                                      -- the hand stays in line with the forearm
			arms += 1
		end
	end
	if st == "eyes" then
		local neck = jointOf(char, "Head", "Neck")
		if neck then pose[neck] = CFrame.new() end
	end
	return arms == 2 and pose or nil
end

-- Each character's record: its state, when it changed, the pose it is blending from and the two solutions.
local recs = setmetatable({}, {__mode = "k"})
local complained = false
local function apply(j, cf) j.Transform = cf end
RunService.Stepped:Connect(function()
	local now = os.clock()
	local T = cfg("ZoomTime", 0.25)
	for _, pl in ipairs(Players:GetPlayers()) do
		local char = pl.Character
		local st = char and char:GetAttribute("BinocularsUp")
		if char and st and not char:GetAttribute("Riding") then
			local rec = recs[char]
			if not rec then rec = {solved = {}}; recs[char] = rec end
			if rec.st ~= st then rec.from = rec.cur; rec.st = st; rec.t0 = now end
			local pose = rec.solved[st]
			if not pose then pose = solve(char, st); rec.solved[st] = pose end
			if pose then
				local alpha = rec.from and math.clamp((now - rec.t0) / math.max(T, 0.05), 0, 1) or 1
				local cur = {}
				for j, cf in pairs(pose) do
					local f = rec.from and rec.from[j]
					cur[j] = (f and alpha < 1) and f:Lerp(cf, alpha) or cf
				end
				rec.cur = cur
				for j, cf in pairs(cur) do
					if j.Parent then
						local ok, err = pcall(apply, j, cf)
						if not ok and not complained then complained = true; warn("BinocularsPose: cannot pose " .. j.ClassName .. ": " .. tostring(err)) end
					end
				end
			end
		elseif char and recs[char] then
			recs[char] = nil
		end
	end
end)
]==]
	local oldP = F:FindFirstChild("BinocularsPose"); if oldP then oldP:Destroy() end
	local ps = Instance.new("Script"); ps.Name = "BinocularsPose"; ps.RunContext = Enum.RunContext.Client; ps.Source = POSE; ps.Parent = F

	-- ---------------------------------------------------------------- the server half ----
	local old = F:FindFirstChild("BinocularsServer"); if old then old:Destroy() end
	local SERVER = [==[
local Players = game:GetService("Players")
local SS = game:GetService("ServerStorage")
local MPS = game:GetService("MarketplaceService")
local F = script.Parent
local template = SS:WaitForChild("BinocularsTool")

-- ---- ownership comes from the Game Pass: checked when you arrive, granted the moment a purchase completes
local function passId() return tonumber(F:GetAttribute("BinocularsPassId")) or 0 end
local function grant(player)
	if (player:GetAttribute("Item_binoculars") or 0) > 0 then return end
	player:SetAttribute("Item_binoculars", 1)
end
local function checkPass(player)
	local id = passId()
	if id <= 0 then return end
	local ok, owns = pcall(function() return MPS:UserOwnsGamePassAsync(player.UserId, id) end)
	if ok and owns then grant(player) end
end
MPS.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
	if purchased and id == passId() then grant(player) end
end)

-- ---- the tool follows ownership: whoever has Item_binoculars carries one, on every spawn
local function give(player)
	if (player:GetAttribute("Item_binoculars") or 0) <= 0 then return end
	local char = player.Character
	if not char then return end
	local pack = player:FindFirstChildOfClass("Backpack")
	if (pack and pack:FindFirstChild("Binoculars")) or char:FindFirstChild("Binoculars") then return end
	local t = template:Clone()
	t.Name = "Binoculars"
	t.Parent = pack or player
end
local function watch(player)
	player.CharacterAdded:Connect(function() task.wait(0.6); give(player) end)
	player:GetAttributeChangedSignal("Item_binoculars"):Connect(function() give(player) end)
	task.spawn(checkPass, player)
	if player.Character then task.defer(give, player) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
print("BinocularsServer: ready" .. (passId() > 0 and (" (game pass " .. passId() .. ")") or " (no game pass id yet - nobody can buy them)"))
]==]
	local s = Instance.new("Script"); s.Name = "BinocularsServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F

	local parts = 0
	for _, p in ipairs(tool:GetDescendants()) do if p:IsA("BasePart") then parts += 1 end end
	print(string.format("Binoculars: tool of %d parts in ServerStorage (Body, no Handle; rests at the chest, rises to the eyes) | zoom to %d degrees over %.2fs, sensitivity %.2f | unfound squirrels glow red within %d studs | game pass id %s",
		parts, F:GetAttribute("ZoomFov"), F:GetAttribute("ZoomTime"), F:GetAttribute("ZoomSensitivity"), F:GetAttribute("RevealRange"), tostring(F:GetAttribute("BinocularsPassId"))))
	return F
end
