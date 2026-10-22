-- GordoClient (workspace.Gordo, RunContext Client; gordo1, Oct 22 2026): Gordo, your house-sitter (GordoServer moves him in
-- after a minute in Italy). Shannon: "after about 1 minute of Italy game play, a funny message pops up about it. when they
-- return home to the treehouse, Gordo is in there to meet them and periodically says funny things using the speech bubble."
--   the note: a little paper card with his face (the letters' look) and Lines.italy; OK or 14 s closes it.
--   at home (drawn on this screen only, like the house itself): Gordo is at one of four SPOTS - inside at the back of the
--   room, on the porch, down by the ladder, in the armchair - and moves on to the next only after you have left sight of
--   the house; he breathes, sways his tail and turns his head to you. When you reach him he greets you (Lines.firstGreet the
--   first time, then one of Lines.greets) and every 25-40 s while you are with him says one of Lines.chatter, through
--   ReplicatedStorage.SquirrelBubble - never while a window (the Passport, a letter...) is open.
--   (wall1) the Treehouse tab's ROOMMATE row can evict him (Item_gordo_out: his parting line, then off to the forest) and
--   invite him back (Lines.welcomeBack).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local LINES = require(F:WaitForChild("Lines"))
local Bubble = require(RS:WaitForChild("SquirrelBubble"))
local ev = RS:WaitForChild("GordoMovedIn", 60)
local TH = workspace:WaitForChild("Treehouse", 60)
if not (ev and TH) then return end
local C = Color3.fromRGB
local PAPER, INK, GOLD, NAVY, BROWN = C(255, 251, 238), C(70, 44, 22), C(240, 200, 90), C(38, 30, 52), C(120, 76, 36)
local HAND, FONT = Enum.Font.PatrickHand, Enum.Font.FredokaOne
local rng = Random.new()
local function J(name)
	local ok, t = pcall(function() return HttpService:JSONDecode(TH:GetAttribute(name) or "") end)
	return (ok and type(t) == "table") and t or nil
end
local TREE, PIECES = J("Tree"), J("Pieces") or {}
if not (TREE and tonumber(TREE.x) and tonumber(TREE.y) and tonumber(TREE.z)) then return end
local base = CFrame.new(TREE.x, TREE.y, TREE.z) * CFrame.Angles(0, math.rad(tonumber(TREE.yaw) or 0), 0)   -- TreehouseClient's frame: +z faces the spawn
local function L(x, y, z) return (base * CFrame.new(x, y, z)).Position end
local WALLS = math.max(4, math.round(#PIECES * 0.58))            -- (TreehouseClient's STAGES.walls)
-- his four spots, in turn (Shannon: "each time you return to the treehouse, Gordo is in a different location? First inside
-- where he is now, once on the porch, one down by the ladder, once sitting in the chair"): where he stands in the house's
-- frame (y = his feet; ground = found by a ray), what he faces, and where you have to be to be "with" him (to be greeted)
local SPOTS = {
	{name = "inside", at = Vector3.new(0, 10.5, -6.3), face = Vector3.new(0, 10.5, 9.5)},       -- the back of the room, facing the door
	{name = "porch", at = Vector3.new(-5.5, 10.5, 15), face = Vector3.new(0, 10.5, 19)},        -- on the balcony, watching the top of the ladder
	{name = "ladder", at = Vector3.new(-3.4, 0, 22.6), face = Vector3.new(-3.4, 0, 40), ground = true},   -- left of the ladder's foot, facing the path
	{name = "chair", at = Vector3.new(-7.0, 12.0, 3.6), face = Vector3.new(0, 12.0, 3.6)},      -- on the armchair's cushion (its top y 12), facing the room
}
local function item(id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function roomUp()
	local n = 0
	for _, pc in ipairs(PIECES) do if item("tree_" .. tostring(pc.id)) >= 1 then n += 1 end end
	return n >= WALLS
end
local function named(s) return (s:gsub("{name}", player.DisplayName)) end
local function tw(o, t, goal, style, dir)
	local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	x:Play(); return x
end
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = o; return c end
local function stroke(o, col, th) local s = Instance.new("UIStroke"); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Color = col; s.Thickness = th; s.Parent = o; return s end

-- ---------- the note in Italy ----------
local function face(parent, size)                                -- his photo: the house copy, framed head-on like the letters' stamps
	local holder = Instance.new("Frame"); holder.Name = "Face"; holder.Size = UDim2.fromOffset(size, size); holder.BackgroundColor3 = C(206, 230, 242)
	holder.Rotation = -4; holder.Parent = parent
	corner(holder, UDim.new(0, 12)); stroke(holder, BROWN, 3)
	local src = RS:FindFirstChild("GordoHome") or RS:WaitForChild("GordoHome", 3)
	if not src then
		local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.TextScaled = true
		t.Text = utf8.char(0x1F43F); t.Parent = holder
		return holder
	end
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.new(1, -8, 1, -8); vp.Position = UDim2.fromOffset(4, 4); vp.BackgroundTransparency = 1
	vp.Ambient = C(190, 190, 200); vp.LightColor = C(255, 250, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.6); vp.Parent = holder
	local copy = src:Clone(); copy.CFrame = CFrame.new(); copy.Parent = vp
	local bones = {}
	for _, b in ipairs(copy:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	local head = bones.Head and bones.Head.WorldPosition or copy.Position
	local root = bones.Root and bones.Root.WorldPosition or copy.Position
	local f = head - root; f = Vector3.new(f.X, 0, f.Z)
	f = f.Magnitude > 0.05 and f.Unit or Vector3.new(0, 0, -1)
	local reach = copy.Size.Magnitude
	local target = head + Vector3.new(0, reach * 0.07, 0)
	local cam = Instance.new("Camera"); cam.FieldOfView = 30; cam.Parent = vp; vp.CurrentCamera = cam
	cam.CFrame = CFrame.lookAt(target + f * reach * 0.72 + Vector3.new(0, reach * 0.04, 0), target)
	return holder
end
local function italyNote()
	local old = pg:FindFirstChild("GordoNote"); if old then old:Destroy() end
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local small = vp.Y < 500
	local gui = Instance.new("ScreenGui"); gui.Name = "GordoNote"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 30; gui.Parent = pg
	local W = math.min(small and 430 or 520, vp.X - 32)
	local FS, PAD = small and 74 or 96, small and 12 or 18
	local card = Instance.new("Frame"); card.Name = "Card"; card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromOffset(vp.X / 2, vp.Y * 0.45)
	card.Size = UDim2.fromOffset(W, FS + PAD * 2); card.BackgroundColor3 = PAPER; card.Parent = gui
	corner(card, UDim.new(0, 16)); stroke(card, GOLD, 3)
	local sc = Instance.new("UIScale"); sc.Scale = 0.5; sc.Parent = card
	local photo = face(card, FS); photo.Position = UDim2.fromOffset(PAD, PAD)
	local body = Instance.new("Frame"); body.Name = "Body"; body.BackgroundTransparency = 1; body.Position = UDim2.fromOffset(PAD * 2 + FS, PAD)
	body.Size = UDim2.new(1, -(PAD * 3 + FS), 0, 0); body.AutomaticSize = Enum.AutomaticSize.Y; body.Parent = card
	local list = Instance.new("UIListLayout"); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Padding = UDim.new(0, small and 4 or 8); list.Parent = body
	local function line(txt, font, size, colour, order, align)
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 0); l.AutomaticSize = Enum.AutomaticSize.Y; l.BackgroundTransparency = 1
		l.Font = font; l.TextSize = size; l.TextColor3 = colour; l.TextWrapped = true; l.Text = txt; l.LayoutOrder = order
		l.TextXAlignment = align or Enum.TextXAlignment.Left; l.Parent = body
		return l
	end
	line(named(LINES.italy or ""), HAND, small and 18 or 22, INK, 1)
	line("Gordo  " .. utf8.char(0x1F43F), FONT, small and 15 or 18, BROWN, 2, Enum.TextXAlignment.Right)
	local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.LayoutOrder = 3; row.Size = UDim2.new(1, 0, 0, small and 30 or 36); row.Parent = body
	local ok = Instance.new("TextButton"); ok.Name = "OK"; ok.AnchorPoint = Vector2.new(1, 0); ok.Position = UDim2.fromScale(1, 0)
	ok.Size = UDim2.fromOffset(small and 90 or 110, small and 30 or 36); ok.BackgroundColor3 = GOLD; ok.Font = FONT; ok.TextSize = small and 16 or 18
	ok.TextColor3 = NAVY; ok.Text = "OK!"; ok.Parent = row
	corner(ok, UDim.new(0, 12))
	local function fit() if card.Parent then card.Size = UDim2.fromOffset(W, math.max(FS, list.AbsoluteContentSize.Y) + PAD * 2) end end
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)   -- (the handwriting font can load a moment later)
	task.defer(fit)
	tw(sc, 0.35, {Scale = 1}, Enum.EasingStyle.Back)
	local closed = false
	local function close()
		if closed then return end
		closed = true
		tw(sc, 0.2, {Scale = 0}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.22, function() gui:Destroy() end)
	end
	ok.Activated:Connect(close)
	task.delay(14, close)
end
ev.OnClientEvent:Connect(function(what) if what == "moved" then italyNote() end end)

-- ---------- Gordo at home ----------
local ORDER = {"Root", "Chest", "Neck", "Head", "Tail1", "Tail2"}
local g                                                          -- the drawn Gordo: model, mesh, bones, his axes, pose state, his spot
local spot                                                       -- the spot he is at (SPOTS index); chosen when he is first drawn
local function heading(v) return math.atan2(-v.X, -v.Z) end
local function today() return math.floor((os.time() - 9 * 3600) / 86400) end   -- (the daily card's day)
local function chairSeat()                                       -- the armchair's cushion (TreehouseClient: 2.2 x 0.5 x 2.0, red)
	local house = workspace:FindFirstChild("Treehouse_local") and workspace.Treehouse_local:FindFirstChild("House")
	for _, p in ipairs(house and house:GetChildren() or {}) do
		if p:IsA("Part") and (p.Size - Vector3.new(2.2, 0.5, 2.0)).Magnitude < 0.01 and math.round(p.Color.R * 255) == 176 and math.round(p.Color.G * 255) == 58 then return p end
	end
end
local leavingUntil = 0                                           -- (wall1) an evicted Gordo says his piece before he goes
local function place()
	if g and not g.model.Parent then g = nil end
	if os.clock() < leavingUntil then return end
	-- (wall1) the Treehouse tab's "Evict Gordo" (Item_gordo_out = 1) sends him back to the forest; "Invite Gordo back" clears it
	if not (item("gordo_home") >= 1 and item("gordo_out") < 1 and roomUp()) then
		if g then g.model:Destroy(); g = nil end
		return
	end
	-- the first time he is home he is inside where he moved in; on a later visit he starts at the day's spot and goes round
	spot = spot or (item("gordo_home") == 1 and 1 or today() % #SPOTS + 1)
	if g and g.spot == spot then return end
	local lf = workspace:FindFirstChild("Treehouse_local")
	local src = RS:FindFirstChild("GordoHome")
	if not (lf and src) then return end
	if g then g.model:Destroy(); g = nil end
	local S = SPOTS[spot]
	local at = L(S.at.X, S.at.Y, S.at.Z)
	if S.ground then                                              -- (the ground's height under him, not the oak's foot)
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = {player.Character, lf:FindFirstChild("GordoRoommate")}
		local hit = workspace:Raycast(at + Vector3.new(0, 8, 0), Vector3.new(0, -30, 0), rp)
		if hit then at = hit.Position end
	end
	local m = Instance.new("Model"); m.Name = "GordoRoommate"
	local mesh = src:Clone(); mesh.Parent = m
	local bones = {}
	for _, b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	local f = (bones.Head and bones.Root) and (bones.Head.WorldPosition - bones.Root.WorldPosition) or mesh.CFrame.LookVector
	f = Vector3.new(f.X, 0, f.Z); if f.Magnitude < 0.05 then f = Vector3.new(0, 0, -1) end
	local look = L(S.face.X, S.face.Y, S.face.Z) - at; look = Vector3.new(look.X, 0, look.Z).Unit
	local rot = CFrame.Angles(0, heading(look) - heading(f), 0) * mesh.CFrame.Rotation
	local s = mesh.Size
	local halfY = (math.abs(rot.XVector.Y) * s.X + math.abs(rot.YVector.Y) * s.Y + math.abs(rot.ZVector.Y) * s.Z) / 2
	mesh.CFrame = CFrame.new(at + Vector3.new(0, halfY, 0)) * rot -- (feet on the floor: the mesh's box bottom)
	m.PrimaryPart = mesh
	m.Parent = lf
	local upL = mesh.CFrame:VectorToObjectSpace(Vector3.yAxis)
	local fwdL = mesh.CFrame:VectorToObjectSpace(look)
	g = {model = m, mesh = mesh, bones = bones, fwdL = fwdL, upL = upL, leftL = upL:Cross(fwdL), want = {}, spot = spot,
		t = 0, look = 0, lookTarget = 0, lookT = 2, flick = 0, flickT = 5}
end
player.AttributeChanged:Connect(function(n)
	if n == "Item_gordo_home" or n:sub(1, 10) == "Item_tree_" then task.defer(place) end
end)
task.spawn(function()
	workspace:WaitForChild("Treehouse_local", 120)
	RS:WaitForChild("GordoHome", 120)
	while true do place(); task.wait(5) end                       -- (a reset round can take the room away; a redraw can clear him)
end)

-- breathing, his head and tail: SquirrelAnim's idle, his head turning to you when you are near
local function pose(name, pitch, yaw, roll, offF, offU, offL)
	local w = g.want[name]
	if not w then w = {0, 0, 0, 0, 0, 0}; g.want[name] = w end
	w[1] += pitch or 0; w[2] += yaw or 0; w[3] += roll or 0; w[4] += offF or 0; w[5] += offU or 0; w[6] += offL or 0
end
RunService.Heartbeat:Connect(function(dt)
	if not (g and g.mesh.Parent) then return end
	local cam = workspace.CurrentCamera
	local mesh = g.mesh
	if cam and (cam.CFrame.Position - mesh.Position).Magnitude > 150 then return end
	g.t += dt
	local t = g.t
	local scale = mesh.Size.Y / 2.4                               -- (SquirrelAnim's BLENDER_HEIGHT)
	local fwdW, upW, leftW = mesh.CFrame:VectorToWorldSpace(g.fwdL), mesh.CFrame:VectorToWorldSpace(g.upL), mesh.CFrame:VectorToWorldSpace(g.leftL)
	table.clear(g.want)
	local breathe = math.sin(t * 1.6) * 0.5 + 0.5
	pose("Chest", -1.5 * breathe, 0, 0, 0, 0.012 * breathe, 0)
	pose("Root", 0, 0, 0, 0, 0.008 * math.sin(t * 1.6), 0)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local target
	if root and (root.Position - mesh.Position).Magnitude < 30 then
		local d = root.Position - mesh.Position; d = Vector3.new(d.X, 0, d.Z)
		target = d.Magnitude > 0.5 and math.clamp(math.deg(math.atan2(fwdW:Cross(d.Unit).Y, fwdW:Dot(d.Unit))), -40, 40) or 0
	else
		g.lookT -= dt
		if g.lookT <= 0 then g.lookTarget = rng:NextNumber(-22, 22); g.lookT = rng:NextNumber(2, 5) end
		target = g.lookTarget
	end
	g.look += (target - g.look) * math.min(1, dt * 4)
	pose("Neck", 0, g.look * 0.35, 0)
	pose("Head", math.sin(t * 0.9) * 1.5, g.look * 0.65, 0)
	g.flickT -= dt
	if g.flickT <= 0 then g.flick = 1; g.flickT = rng:NextNumber(4, 11) end
	g.flick = math.max(0, g.flick - dt * 2.2)
	local sway1, sway2 = math.sin(t * 1.4) * 5, math.sin(t * 1.4 - 0.9) * 8
	local fl = math.sin(g.flick * math.pi) * 18
	pose("Tail1", sway1 * 0.4 + fl * 0.6, sway1, 0)
	pose("Tail2", sway2 * 0.5 + fl, sway2, 0)
	for _, name in ipairs(ORDER) do
		local b = g.bones[name]
		if b then
			local w = g.want[name]
			if not w then b.Transform = CFrame.identity
			else
				local parent = b.Parent
				local pw = (parent:IsA("Bone") and parent.TransformedWorldCFrame) or mesh.CFrame
				local R = (pw * b.CFrame).Rotation
				local lLeft, lUp, lFwd = R:VectorToObjectSpace(leftW), R:VectorToObjectSpace(upW), R:VectorToObjectSpace(fwdW)
				local off = R:VectorToObjectSpace((fwdW * w[4] + upW * w[5] + leftW * w[6]) * scale)
				b.Transform = CFrame.new(off) * CFrame.fromAxisAngle(lUp, math.rad(w[2])) * CFrame.fromAxisAngle(lLeft, math.rad(w[1])) * CFrame.fromAxisAngle(lFwd, math.rad(w[3]))
			end
		end
	end
end)

-- leaving and coming back (Shannon: "he should only change location if the player leaves sight of the treehouse then
-- returns"): you have left once you are more than 140 studs off (past the forest spawn, 110) with no part of the house on
-- your screen, or more than 320 off, or out of the forest (Italy, the village...: the camera can still point its way from
-- Italy, the preview showed) - right then he moves on to his next spot, so he is already there when you come back, and he
-- will greet you again. Walking down to the mailbox and back up, or looking away, moves nothing.
local GONE, FAR_GONE = 140, 320
local CORNERS = {L(0, 12, 6)}                                    -- the house's box (balcony, ladder and roof) and its middle
for _, x in ipairs({-11, 11}) do for _, y in ipairs({0, 25}) do for _, z in ipairs({-11, 25}) do table.insert(CORNERS, L(x, y, z)) end end end
local function houseOnScreen()
	local cam = workspace.CurrentCamera
	if not cam then return true end
	for _, c in ipairs(CORNERS) do
		local _, on = cam:WorldToViewportPoint(c)
		if on then return true end
	end
	return false
end
-- where you have to be to be "with" him at each spot (where you can see him - on the balcony, his bubble from inside the
-- room floated over the wall)
local function local3(pos) return base:PointToObjectSpace(pos) end
local function inRoom(p) return math.abs(p.X) < 9.3 and p.Z > -9.3 and p.Z < 10 and p.Y > 9.5 and p.Y < 20 end   -- the 19 x 19 room, floor y 10.5
local WITH = {
	inside = inRoom,
	chair = inRoom,
	porch = function(p) return math.abs(p.X) < 11.2 and p.Z > 9.4 and p.Z < 19.6 and p.Y > 9.5 and p.Y < 20 end,   -- the balcony
	ladder = function(p) return p.Y < 8 and Vector2.new(p.X - SPOTS[3].at.X, p.Z - SPOTS[3].at.Z).Magnitude < 16 end, -- on the ground near him
}
local gone, greeted, nextTalk, bag, lastLine = false, false, math.huge, {}, nil
local invitedBack = false                                        -- (wall1) his next greeting is Lines.welcomeBack
local function chatterLine()
	if #bag == 0 then
		for _, l in ipairs(LINES.chatter or {}) do table.insert(bag, l) end
		for i = #bag, 2, -1 do local j = rng:NextInteger(1, i); bag[i], bag[j] = bag[j], bag[i] end
		if #bag > 1 and bag[#bag] == lastLine then bag[1], bag[#bag] = bag[#bag], bag[1] end
	end
	lastLine = table.remove(bag)
	return lastLine
end
local function busy()
	return pg:GetAttribute("OpenPanel") ~= nil or pg:FindFirstChild("MailLetter") ~= nil or pg:FindFirstChild("GordoNote") ~= nil
end
local function say(text)
	if not (g and g.model.Parent and type(text) == "string" and text ~= "") then return end
	Bubble.say(g.model, named(text), {secs = math.clamp(2 + #text / 16, 3.5, 7)})
end
task.spawn(function()
	while true do
		task.wait(0.5)
		local seat = chairSeat()                                   -- nobody sits on Gordo: the armchair takes no one while he is in it
		if seat then seat.CanTouch = not (g and SPOTS[g.spot].name == "chair") end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local p = local3(root.Position)
			local d = Vector2.new(p.X, p.Z - 6).Magnitude
			if d > GONE then
				if not gone and (d > FAR_GONE or player:GetAttribute("Area") ~= "forest" or not houseOnScreen()) then   -- out of sight of the house: on to his next spot
					gone = true
					greeted = false
					if spot and item("gordo_home") >= 2 then spot = spot % #SPOTS + 1; place() end
				end
			else
				gone = false
			end
			if g and g.mesh.Parent and not greeted and WITH[SPOTS[g.spot].name](p) and not busy() then
				greeted = true                                       -- a greeting when you reach him, once each time you come back
				if item("gordo_home") == 1 then
					say(LINES.firstGreet); ev:FireServer("met")
				elseif invitedBack and LINES.welcomeBack then
					say(LINES.welcomeBack)
				else
					local gs = LINES.greets or {}
					if #gs > 0 then say(gs[rng:NextInteger(1, #gs)]) end
				end
				invitedBack = false
				nextTalk = os.clock() + rng:NextNumber(18, 28)
			elseif g and g.mesh.Parent and greeted and WITH[SPOTS[g.spot].name](p) and not busy() and os.clock() >= nextTalk then
				say(chatterLine())                                   -- now and then while you are with him
				nextTalk = os.clock() + rng:NextNumber(25, 40)
			end
		end
	end
end)
-- (wall1) evicted from the Treehouse tab: if he is near you he has his say first (Lines.evicted) - once the Passport is
-- closed, so you see it - then off to the forest; invited back: he is at his spot again and greets you with
-- Lines.welcomeBack when you reach him
local wasOut = item("gordo_out") >= 1
player:GetAttributeChangedSignal("Item_gordo_out"):Connect(function()
	local out = item("gordo_out") >= 1
	if out == wasOut then return end
	wasOut = out
	if out then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if g and g.mesh.Parent and root and (root.Position - g.mesh.Position).Magnitude < 40 and LINES.evicted then
			leavingUntil = math.huge                             -- (he waits for the window to close)
			task.spawn(function()
				local t0 = os.clock()
				while busy() and os.clock() - t0 < 60 do task.wait(0.2) end
				if item("gordo_out") < 1 then leavingUntil = 0 return end   -- (invited straight back)
				task.wait(0.4)
				say(LINES.evicted)
				leavingUntil = os.clock() + 3.5
				task.delay(3.6, place)
			end)
		else
			place()
		end
	else
		leavingUntil = 0; invitedBack = true; greeted = false
		place()
	end
end)
print("GordoClient: ready")
