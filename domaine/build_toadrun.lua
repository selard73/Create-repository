-- The Toadstool Run: the vineyard hop line (domaine/build_hopline.lua) as a course. Shannon (Sep 25 2026): "make it a
-- course ... call it the toadstool run; if you fall off midway through, you have to start from the beginning again",
-- then "if you get to the end without falling, award 10 acorns at the end. not one per bounce".
--   START: the top of the line, up by the chapel (VineHop01) - it runs "all the way down the vineyard", as Shannon
--   first put it. FINISH: the bottom, by the Rue (the last VineHop). Start = "bottom" on the folder turns it round.
--   A RUN begins with a bounce on the start cap. Every bounce on any cap of the line keeps it going (bouncing back on
--   one you have passed is not touching the ground, so it is allowed); a bounce on the finish cap ends it: Reward (10)
--   acorns. TOUCH THE GROUND and it is over - back to the start: the player's screen reports it (standing on anything
--   that is not a cap for more than a moment), and the server also ends any run that goes MaxGap seconds without a
--   bounce, which only happens if you landed somewhere. A bounce on the finish cap with no run going gets a hint that
--   the run starts up by the chapel.
--   The bounces come from the trampolines' own RemoteEvent (workspace.Trampolines.Bounced): the RunServer listens to it
--   alongside TrampolineServer and checks the bouncer is really at that cap. The reward goes through the ledger like
--   every other award (RS.AwardAcorns + the Acorns attribute).
--   On screen (RunClient): a pill at the top while you run ("TOADSTOOL RUN 7 / 23"), a line at the foot of the screen for
--   the start, a fall and the finish, and the game's reward sound at the finish.
--   SIGNS at both ends in the toadstools' own red and cream.
-- Attributes on workspace.ToadstoolRun: Reward (10), MaxGap (2.4 s), Start ("top"), Title.
-- Run in edit mode after build_hopline.lua (re-runnable; it rebuilds the folder).
return function(opts)
	opts = opts or {}
	local C = Color3.fromRGB
	local T = workspace:FindFirstChild("Trampolines")
	assert(T and T:FindFirstChild("Bounced"), "workspace.Trampolines (with Bounced) is missing")
	local hops = {}
	for _, m in ipairs(T:GetChildren()) do if m:GetAttribute("Line") == "vineyard" and m.PrimaryPart then hops[m:GetAttribute("Order")] = m end end
	local N = #hops
	assert(N >= 2, "no vineyard hop line - run build_hopline.lua first")
	local old = workspace:FindFirstChild("ToadstoolRun"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "ToadstoolRun"
	F:SetAttribute("Title", "The Toadstool Run"); F:SetAttribute("Reward", opts.reward or 10)
	F:SetAttribute("MaxGap", opts.maxGap or 2.4); F:SetAttribute("Start", opts.start or "top")
	local ev = Instance.new("RemoteEvent"); ev.Name = "RunEvent"; ev.Parent = F
	local report = {}

	-- ---------------------------------------------------------------- the signs ----
	local rpG = RaycastParams.new(); rpG.FilterType = Enum.RaycastFilterType.Include
	local ground = {workspace.Terrain}
	if workspace:FindFirstChild("Baseplate") then table.insert(ground, workspace.Baseplate) end
	rpG.FilterDescendantsInstances = ground
	local function groundAt(x, z)
		local hit = workspace:Raycast(Vector3.new(x, 160, z), Vector3.new(0, -260, 0), rpG)
		return hit and hit.Position.Y or 0
	end
	local WOOD, RED, CREAM, GOLD, SPOT = C(118, 84, 52), C(214, 50, 46), C(255, 246, 220), C(240, 196, 70), C(250, 246, 236)
	local function part(parent, name, size, cf, colour, material, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent
		return p
	end
	local function text(parent, t, size, colour, y, h, strokeColour)
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -28, 0, h); l.Position = UDim2.new(0, 14, 0, y)
		l.Font = Enum.Font.FredokaOne; l.TextScaled = true; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.Parent = parent
		local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = size; c.Parent = l                     -- as big as it fits, never bigger
		if strokeColour then local s = Instance.new("UIStroke"); s.Color = strokeColour; s.Thickness = (size >= 30) and 2.5 or 1.5; s.Parent = l end
		return l
	end
	-- a board between two posts, its face turned toward `look` (a flat direction), a little red toadstool on each post
	local function sign(name, x, z, look, lines)
		local g = groundAt(x, z)
		local base = CFrame.lookAt(Vector3.new(x, g, z), Vector3.new(x + look.X, g, z + look.Z))   -- -Z (Front) faces `look`
		local m = Instance.new("Model"); m.Name = name
		pcall(function() m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic end)
		for _, s in ipairs({-1, 1}) do
			part(m, "Post", Vector3.new(0.6, 7.4, 0.6), base * CFrame.new(s * 4.3, 3.5, 0), WOOD, Enum.Material.Wood)
			local pc = part(m, "PostCap", Vector3.new(1.9, 0.9, 1.9), base * CFrame.new(s * 4.3, 7.2, 0), RED)   -- a flattened dome: a ball part cannot be squashed,
			local sm = Instance.new("SpecialMesh"); sm.MeshType = Enum.MeshType.Sphere; sm.Parent = pc               -- a sphere mesh fills the block it is in
			part(m, "Spot", Vector3.new(0.35, 0.35, 0.35), base * CFrame.new(s * 4.3 + 0.45, 7.55, -0.3), SPOT, nil, Enum.PartType.Ball).CanCollide = false
		end
		local board = part(m, "Board", Vector3.new(8.2, 3.9, 0.3), base * CFrame.new(0, 4.9, 0), RED)   -- the toadstools' own red
		for _, dy in ipairs({-2.02, 2.02}) do part(m, "Trim", Vector3.new(8.4, 0.22, 0.4), base * CFrame.new(0, 4.9 + dy, 0), GOLD).CanCollide = false end
		for _, face in ipairs({Enum.NormalId.Front, Enum.NormalId.Back}) do
			local sg = Instance.new("SurfaceGui"); sg.Face = face; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 50
			sg.LightInfluence = 0.25; sg.Parent = board
			text(sg, "THE TOADSTOOL RUN", 40, CREAM, 8, 46, C(96, 20, 16))
			text(sg, lines[1], 30, GOLD, 56, 34, C(96, 20, 16))
			text(sg, lines[2], 22, CREAM, 92, 54, C(96, 20, 16))
			text(sg, lines[3], 22, GOLD, 146, 30, C(96, 20, 16))
		end
		m.Parent = F
		-- clear of everything? (reported, not fixed: a sign is moved by hand if it ever lands in something)
		local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Exclude; op.FilterDescendantsInstances = {m, workspace.Terrain, workspace:FindFirstChild("Baseplate")}
		local hits = {}
		for _, p in ipairs(workspace:GetPartBoundsInBox(base * CFrame.new(0, 4.4, 0), Vector3.new(9.6, 8, 1.4), op)) do
			if p.Transparency < 0.95 and p.Size.Magnitude < 200 then table.insert(hits, p:GetFullName()) end
		end
		table.insert(report, string.format("%s at %.1f,%.1f %s", name, x, z, (#hits > 0) and ("TOUCHES " .. table.concat(hits, ", ")) or "clear"))
		return m
	end
	local top, bottom = hops[1].PrimaryPart.Position, hops[N].PrimaryPart.Position
	local startAt, finishAt = top, bottom
	if F:GetAttribute("Start") == "bottom" then startAt, finishAt = bottom, top end
	local along = Vector3.new(finishAt.X - startAt.X, 0, finishAt.Z - startAt.Z).Unit   -- the way the run goes
	local north = Vector3.new(0, 0, 1)                                                   -- the vineyard side of the line
	-- back by the wall (Shannon: "move the sign for the toadstool run back closer to the walls"): each sign stands in
	-- the strip between the line and the stone wall, between two of the cypresses, just beyond its end of the line
	-- the finish sign: on the open grass in the corner by the Rue, past the last cap and clear of it (Shannon circled
	-- the spot: "this sign should go where the red circle is showing")
	local s1 = startAt - along * 11 - north * 6.6
	local s2 = finishAt + along * 6.2 - north * 4.6                              -- (364.5,-238: the nearest clear spot to her circle)
	local toFinish = (F:GetAttribute("Start") == "bottom") and "Hop all the way up to the chapel without touching the ground" or "Hop all the way down to the Rue without touching the ground"
	local fromStart = (F:GetAttribute("Start") == "bottom") and "It starts down by the Rue. Touch the ground and you start again!" or "It starts up by the chapel. Touch the ground and you start again!"
	sign("StartSign", s1.X, s1.Z, (north + along * 0.37).Unit, {"START", toFinish, "10 acorns at the end!"})
	sign("FinishSign", s2.X, s2.Z, (north - along * 0.37).Unit, {"FINISH", fromStart, "10 acorns at the end!"})

	-- ---------------------------------------------------------------- the server ----
	local SERVER = [==[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local F = script.Parent
local T = workspace:WaitForChild("Trampolines")
local bounced = T:WaitForChild("Bounced")
local ev = F:WaitForChild("RunEvent")
local awardAcorns = RS:WaitForChild("AwardAcorns")

local runs = {}                                      -- player -> {last = order reached, t = time of the last bounce}
local hinted = {}                                    -- player -> when they were last told where the run starts

local function total() return T:GetAttribute("VineyardHops") or 0 end
local function ends()
	if F:GetAttribute("Start") == "bottom" then return total(), 1 end
	return 1, total()
end
local function stop(player, why)
	if not runs[player] then return end
	runs[player] = nil
	player:SetAttribute("ToadRun", nil)
	if why then ev:FireClient(player, why) end
end

bounced.OnServerEvent:Connect(function(player, model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") or model.Parent ~= T or model:GetAttribute("Line") ~= "vineyard" then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local at = model:GetPivot().Position
	if Vector3.new(hrp.Position.X - at.X, 0, hrp.Position.Z - at.Z).Magnitude > 2.8 * (model:GetAttribute("Scale") or 1.3) + 6 then return end
	local o, now = model:GetAttribute("Order"), os.clock()
	local s, f = ends()
	local dir = (f > s) and 1 or -1
	local r = runs[player]
	if r and now - r.t > (F:GetAttribute("MaxGap") or 2.4) then stop(player, "fell"); r = nil end   -- that long without a bounce: they came down somewhere
	if o == s then
		if r then r.t = now; if r.last ~= s then r.last = s; player:SetAttribute("ToadRun", 1) end return end
		runs[player] = {last = s, t = now}
		player:SetAttribute("ToadRun", 1)
		ev:FireClient(player, "start", total())
		return
	end
	if not r then
		if o == f and (not hinted[player] or now - hinted[player] > 20) then hinted[player] = now; ev:FireClient(player, "startshere") end
		return
	end
	r.t = now
	if (o - r.last) * dir > 0 then r.last = o; player:SetAttribute("ToadRun", math.abs(o - s) + 1) end
	if o == f then
		runs[player] = nil
		player:SetAttribute("ToadRun", nil)
		hinted[player] = now                                               -- you go on bouncing on the finish cap: no "it starts up by the chapel" over the cheering
		local n = F:GetAttribute("Reward") or 10
		awardAcorns:Fire(player, n)                                       -- SquirrelSetup's ledger saves it
		player:SetAttribute("Acorns", (tonumber(player:GetAttribute("Acorns")) or 0) + n)
		local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"toadstool",{prize=n}) end
		ev:FireClient(player, "done", n)
	end
end)
ev.OnServerEvent:Connect(function(player, what)
	if what == "fell" then stop(player, "fell") end
end)
-- a run that has gone quiet ended on the ground, whether or not the player's screen said so
task.spawn(function()
	while true do
		task.wait(0.25)
		local now, gap = os.clock(), F:GetAttribute("MaxGap") or 2.4
		for player, r in pairs(runs) do if now - r.t > gap then stop(player, "fell") end end
	end
end)
Players.PlayerRemoving:Connect(function(p) runs[p] = nil; hinted[p] = nil end)
]==]

	-- ---------------------------------------------------------------- the player's screen ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local F = script.Parent
local T = workspace:WaitForChild("Trampolines")
local ev = F:WaitForChild("RunEvent")
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, RED = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(214, 50, 46)
local FONT = Enum.Font.FredokaOne

local gui = Instance.new("ScreenGui"); gui.Name = "ToadRunGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 16
gui.Parent = player:WaitForChild("PlayerGui")
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p end
local function stroke(p, colour, th) local s = Instance.new("UIStroke"); s.Color = colour; s.Thickness = th; s.Parent = p; return s end
local pill = Instance.new("Frame"); pill.Name = "Progress"; pill.AnchorPoint = Vector2.new(0.5, 0); pill.Position = UDim2.new(0.5, 0, 0, 62)
pill.Size = UDim2.fromOffset(300, 50); pill.BackgroundColor3 = NAVY; pill.BackgroundTransparency = 0.08; pill.Visible = false; pill.Parent = gui
corner(pill, 14); stroke(pill, RED, 2)
local name = Instance.new("TextLabel"); name.BackgroundTransparency = 1; name.Position = UDim2.fromOffset(16, 0); name.Size = UDim2.new(0, 190, 1, 0)
name.Font = FONT; name.TextSize = 20; name.TextColor3 = CREAM; name.TextXAlignment = Enum.TextXAlignment.Left; name.Text = "TOADSTOOL RUN"; name.Parent = pill
local count = Instance.new("TextLabel"); count.BackgroundTransparency = 1; count.Position = UDim2.new(1, -96, 0, 0); count.Size = UDim2.new(0, 84, 1, 0)
count.Font = FONT; count.TextSize = 22; count.TextColor3 = GOLD; count.TextXAlignment = Enum.TextXAlignment.Right; count.Text = ""; count.Parent = pill
local note = Instance.new("TextLabel"); note.AnchorPoint = Vector2.new(0.5, 1); note.Position = UDim2.new(0.5, 0, 1, -110); note.Size = UDim2.fromOffset(460, 44)
note.BackgroundColor3 = NAVY; note.BackgroundTransparency = 1; note.Font = FONT; note.TextSize = 18; note.TextColor3 = CREAM; note.TextTransparency = 1
note.TextWrapped = true; note.Text = ""; note.Parent = gui
corner(note, 12)
local noteStroke = stroke(note, GOLD, 1.5); noteStroke.Transparency = 1
local noteAt = 0
local function say(t, secs)
	note.Text = t; note.BackgroundTransparency = 0.15; note.TextTransparency = 0; noteStroke.Transparency = 0
	local mine = os.clock(); noteAt = mine
	task.delay(secs or 3.4, function()
		if noteAt ~= mine then return end
		local ti = TweenInfo.new(0.5)
		TweenService:Create(note, ti, {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(noteStroke, ti, {Transparency = 1}):Play()
	end)
end
local function sound(id, vol)
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol or 0.6; s.Parent = gui; s:Play(); Debris:AddItem(s, 6)
end
local total = 0
local function show()
	local n = player:GetAttribute("ToadRun")
	pill.Visible = n ~= nil
	if n then
		total = T:GetAttribute("VineyardHops") or total
		count.Text = string.format("%d / %d", n, total)
	end
end
player:GetAttributeChangedSignal("ToadRun"):Connect(show)
show()

local startWhere = (F:GetAttribute("Start") == "bottom") and "down by the Rue" or "up by the chapel"
ev.OnClientEvent:Connect(function(what, n)
	if what == "start" then
		say("The Toadstool Run! Hop all the way to the other end without touching the ground.", 3.6)
		sound("rbxasset://sounds/electronicpingshort.wav", 0.5)
	elseif what == "fell" then
		say("You touched the ground! Back to the start " .. startWhere .. ".", 3.6)
	elseif what == "done" then
		say(string.format("You made it! The whole Toadstool Run without touching the ground: +%d acorns!", n or 10), 5)
		sound("rbxassetid://1845415163", 0.6)
	elseif what == "startshere" then
		say("The Toadstool Run starts " .. startWhere .. ". Hop all the way here without touching the ground for 10 acorns!", 5)
	end
end)

-- touching the ground: standing on anything that is not one of the caps for more than a moment (a bounce touches a cap
-- for a frame or two; a landing on the grass, a vine or a wall lasts longer). Rays from the middle and four sides of
-- the feet, so landing on a brim's very edge still counts as the cap.
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
local grounded, sent = 0, false
local function onCap(hrp, char)
	rp.FilterDescendantsInstances = {char}
	for _, off in ipairs({Vector3.zero, Vector3.new(0.9, 0, 0), Vector3.new(-0.9, 0, 0), Vector3.new(0, 0, 0.9), Vector3.new(0, 0, -0.9)}) do
		local hit = workspace:Raycast(hrp.Position + off, Vector3.new(0, -7, 0), rp)
		if hit and hit.Instance.Name == "Cap" and hit.Instance:IsDescendantOf(T) then return true end
	end
	return false
end
player:GetAttributeChangedSignal("ToadRun"):Connect(function() if player:GetAttribute("ToadRun") == 1 then sent = false end end)
RunService.Heartbeat:Connect(function(dt)
	if not player:GetAttribute("ToadRun") then grounded = 0; sent = false return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) then return end
	if hum.FloorMaterial == Enum.Material.Air or onCap(hrp, char) then grounded = 0 return end
	grounded += dt
	if grounded > 0.15 and not sent then sent = true; ev:FireServer("fell") end
end)
]==]
	local srv = Instance.new("Script"); srv.Name = "RunServer"; srv.RunContext = Enum.RunContext.Server; srv.Source = SERVER; srv.Parent = F
	local cli = Instance.new("Script"); cli.Name = "RunClient"; cli.RunContext = Enum.RunContext.Client; cli.Source = CLIENT; cli.Parent = F
	F.Parent = workspace
	table.insert(report, 1, string.format("%d caps, start %s (cap %d), finish cap %d, reward %d, max gap %.1fs", N, F:GetAttribute("Start"),
		(F:GetAttribute("Start") == "bottom") and N or 1, (F:GetAttribute("Start") == "bottom") and 1 or N, F:GetAttribute("Reward"), F:GetAttribute("MaxGap")))
	return table.concat(report, " | ")
end
