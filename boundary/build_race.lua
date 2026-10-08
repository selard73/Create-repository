-- Forest Race: find all 15 forest squirrels against the clock, and race your own best time.
-- Shannon (Sep 25): "for just the forest squirrels, leaderboard of fastest to find all 15 which maybe encourages
-- people to start over and race against their own score". The real collection is never touched: a race is its own
-- game layered on top of it.
--   START: the gate beside the forest spawn has a "Start the race" prompt. 3-2-1-GO on screen, and the forest
--   squirrels turn gray on the racer's screen only (everyone else still sees their own colours).
--   RACE: every forest squirrel the racer clicks turns back to colour for them and the count ticks up (7 / 15). The
--   clock runs on the server, so it cannot be fiddled. A squirrel never found for real counts too, and is found for
--   real by the same click.
--   FINISH: at 15 / 15 the clock stops: the time, the personal best, and "Race again" (back to the gate and straight
--   into a new race). Quitting, or running out of MaxMinutes, puts every squirrel back to the racer's real colours.
--   BOARD: a wooden board by the gate shows the ten fastest ever (an OrderedDataStore, lower is better) and, on each
--   player's own screen, their own best. Times under MinSeconds stay personal bests but never go on the board.
-- A personal best is a ledger item (Item_race_best, hundredths of a second), so it saves with the rest of the
-- progress. Studio cannot reach the DataStore (API access stays off for tests), so there the board shows this
-- server's results only. Player attribute Racing is set while the clock runs (the paid Zoomies pause for it).
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local C = Color3.fromRGB
	local old = workspace:FindFirstChild("ForestRace"); if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "ForestRace"
	local GX, GZ = opts.gateX or 30, opts.gateZ or 0           -- the gate: runners go through it heading +x (east)
	local BX, BZ = opts.boardX or 30, opts.boardZ or -15        -- the board: its face looks -x, turned boardTurn degrees about the vertical
	F:SetAttribute("Map", "forest"); F:SetAttribute("MinSeconds", opts.minSeconds or 45); F:SetAttribute("MaxMinutes", opts.maxMinutes or 20)
	F:SetAttribute("CountdownSeconds", 3); F:SetAttribute("BestAcorns", opts.bestAcorns or 10); F:SetAttribute("BoardRefresh", 60); F:SetAttribute("StoreName", opts.store or "ForestRace_v1")
	local ev = RS:FindFirstChild("RaceEvent")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "RaceEvent"; ev.Parent = RS end

	local function ground(x, z)
		local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F}
		local hit = workspace:Raycast(Vector3.new(x, 8, z), Vector3.new(0, -30, 0), rp)   -- from under the tree tops
		return hit and hit.Position.Y or 0
	end
	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent
		return p
	end
	local WOOD, DARK, GREEN, GOLD, CREAM = C(118, 84, 52), C(78, 54, 34), C(58, 120, 72), C(240, 196, 70), C(255, 246, 220)
	local function text(parent, t, size, colour, y, h, font)
		local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -20, 0, h); l.Position = UDim2.new(0, 10, 0, y)
		l.Font = font or Enum.Font.FredokaOne; l.TextSize = size; l.TextColor3 = colour; l.Text = t; l.TextWrapped = true; l.Parent = parent
		return l
	end

	-- ---------------------------------------------------------------- the start gate ----
	local g = ground(GX, GZ)
	local gate = Instance.new("Model"); gate.Name = "StartGate"; gate.Parent = F
	for _, s in ipairs({-1, 1}) do
		part("Post", Vector3.new(1.4, 11, 1.4), CFrame.new(GX, g + 5.5, GZ + s * 7), WOOD, Enum.Material.Wood, gate)
		part("Knob", Vector3.new(1.9, 1.9, 1.9), CFrame.new(GX, g + 11.5, GZ + s * 7), GOLD, Enum.Material.SmoothPlastic, gate, Enum.PartType.Ball)
	end
	part("Beam", Vector3.new(1.6, 1.2, 16.2), CFrame.new(GX, g + 10.6, GZ), DARK, Enum.Material.Wood, gate)
	local banner = part("Banner", Vector3.new(0.25, 3.2, 12.4), CFrame.new(GX, g + 8.3, GZ), GREEN, Enum.Material.Fabric, gate)
	banner.CanCollide = false
	for _, dy in ipairs({-1.72, 1.72}) do part("Trim", Vector3.new(0.3, 0.25, 12.6), CFrame.new(GX, g + 8.3 + dy, GZ), GOLD, Enum.Material.SmoothPlastic, gate).CanCollide = false end
	for _, face in ipairs({Enum.NormalId.Left, Enum.NormalId.Right}) do
		local sg = Instance.new("SurfaceGui"); sg.Face = face; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; sg.PixelsPerStud = 40; sg.LightInfluence = 0.2; sg.Parent = banner
		local t1 = text(sg, "FOREST RACE", 62, CREAM, 8, 70); local st = Instance.new("UIStroke"); st.Color = C(30, 60, 36); st.Thickness = 3; st.Parent = t1
		text(sg, "race the clock - find all 15 squirrels", 26, C(255, 226, 150), 80, 34)
	end
	for i = 0, 12 do                                          -- the chequered start line
		for j, dx in ipairs({-0.5, 0.5}) do
			local black = (i + j) % 2 == 0
			local t = part("Line", Vector3.new(1, 0.12, 1), CFrame.new(GX + dx, g + 0.06, GZ - 6 + i), black and C(30, 30, 34) or C(245, 245, 240), Enum.Material.SmoothPlastic, gate)
			t.CanCollide = false
		end
	end
	local pad = part("StartPad", Vector3.new(4, 6, 12), CFrame.new(GX - 3, g + 3, GZ), CREAM, nil, gate)
	pad.Transparency = 1; pad.CanCollide = false; pad.CanQuery = false
	local pr = Instance.new("ProximityPrompt"); pr.Name = "StartPrompt"; pr.ActionText = "Start the race"; pr.ObjectText = "Forest Race"
	pr.KeyboardKeyCode = Enum.KeyCode.E; pr.HoldDuration = 0.3; pr.MaxActivationDistance = 12; pr.RequiresLineOfSight = false; pr.Parent = pad
	-- on a phone its button sits just under the FOREST RACE sign on the screen, wherever the sign is (Shannon, Sep 26: "It
	-- should always be under the sign, no matter what direction you're looking at it"); the PromptClient follows the anchor
	pr:SetAttribute("PhoneSpot", "sign")
	pr:SetAttribute("PhoneAnchor", (banner.CFrame * CFrame.new(0, -banner.Size.Y / 2 - 0.3, 0)).Position)
	F:SetAttribute("StartX", GX - 5); F:SetAttribute("StartY", g + 3.4); F:SetAttribute("StartZ", GZ)

	-- ---------------------------------------------------------------- the board ----
	local b = ground(BX, BZ)
	-- beside the gate and turned to look at the spawn (Shannon: behind the gate it hid - "not a good place for it")
	local base = CFrame.new(BX, b, BZ) * CFrame.Angles(0, math.rad(opts.boardTurn or 0), 0)
	local board = Instance.new("Model"); board.Name = "RaceBoard"; board.Parent = F
	for _, s in ipairs({-1, 1}) do part("Post", Vector3.new(0.8, 9.4, 0.8), base * CFrame.new(0, 4.7, s * 5.7), WOOD, Enum.Material.Wood, board) end
	part("Back", Vector3.new(0.4, 7.2, 11.6), base * CFrame.new(0, 5.7, 0), DARK, Enum.Material.Wood, board)
	part("Roof", Vector3.new(1.8, 0.35, 12.4), base * CFrame.new(0, 9.45, 0), WOOD, Enum.Material.Wood, board)
	local face = part("Face", Vector3.new(0.1, 6.4, 10.8), base * CFrame.new(-0.25, 5.7, 0), C(244, 232, 204), Enum.Material.SmoothPlastic, board)
	face.CanCollide = false
	local sg = Instance.new("SurfaceGui"); sg.Name = "Board"; sg.Face = Enum.NormalId.Left; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50; sg.LightInfluence = 0.3; sg.Parent = face
	text(sg, "FASTEST IN THE FOREST", 34, C(84, 48, 18), 6, 40)
	text(sg, "all 15 forest squirrels, against the clock", 17, C(130, 96, 60), 44, 22, Enum.Font.Merriweather)
	for i = 1, 10 do
		local row = Instance.new("Frame"); row.Name = "Row" .. i; row.BackgroundTransparency = (i % 2 == 0) and 1 or 0.9; row.BackgroundColor3 = C(200, 170, 120)
		row.BorderSizePixel = 0; row.Position = UDim2.fromOffset(20, 72 + (i - 1) * 20); row.Size = UDim2.new(1, -40, 0, 20); row.Parent = sg
		local function cell(name, x, w, align)
			local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Position = UDim2.fromOffset(x, 0); l.Size = UDim2.new(0, w, 1, 0)
			l.Font = Enum.Font.FredokaOne; l.TextSize = 16; l.TextColor3 = C(70, 44, 22); l.TextXAlignment = align; l.Text = ""; l.TextTruncate = Enum.TextTruncate.AtEnd; l.Parent = row
		end
		cell("Rank", 4, 34, Enum.TextXAlignment.Right); cell("Who", 46, 290, Enum.TextXAlignment.Left); cell("Time", 340, 94, Enum.TextXAlignment.Right)
	end
	local foot = text(sg, "Your best: -", 18, C(58, 120, 72), 282, 26); foot.Name = "Footer"
	-- THE BOARD LIGHTS UP ITS LEADERS. Shannon: "for the top on the leader board, could you make it glowy or change color
	-- or highlight it in some way? so it stands out? right now its a bit dull to look at". First place is a gold bar with
	-- a glowing rim and a soft shine that runs across it (RaceClient moves the shine and pulses the rim), second and third
	-- are silver and bronze, the rest plain; empty places are hidden (RaceServer's paint), the board is lit from within,
	-- and a thin neon-gold frame glows round it. Re-runnable on a board already built.
	local function styleBoard(sg, face, model)
		local K = Color3.fromRGB
		sg.LightInfluence = 0; sg.Brightness = 1.15
		local STYLE = {
			{y = 70, h = 30, bg = K(255, 214, 92), size = 21, ink = K(92, 52, 8)},      -- first: gold
			{y = 103, h = 22, bg = K(222, 228, 236), size = 17, ink = K(60, 64, 72)},   -- second: silver
			{y = 127, h = 22, bg = K(232, 178, 128), size = 17, ink = K(92, 50, 20)},   -- third: bronze
		}
		for i = 4, 10 do STYLE[i] = {y = 151 + (i - 4) * 18, h = 18, bg = K(200, 170, 120), t = (i % 2 == 0) and 0.8 or 1, size = 15, ink = K(70, 44, 22)} end
		for i, S in ipairs(STYLE) do
			local row = sg:FindFirstChild("Row" .. i)
			if row then
				row.Position = UDim2.fromOffset(20, S.y); row.Size = UDim2.new(1, -40, 0, S.h)
				row.BackgroundColor3 = S.bg; row.BackgroundTransparency = S.t or 0
				for _, cell in ipairs(row:GetChildren()) do if cell:IsA("TextLabel") then cell.TextSize = S.size; cell.TextColor3 = S.ink; cell.ZIndex = 2 end end
				if i <= 3 and not row:FindFirstChildOfClass("UICorner") then local k = Instance.new("UICorner"); k.CornerRadius = UDim.new(0, 8); k.Parent = row end
				if i == 1 then
					row.ClipsDescendants = true
					if not row:FindFirstChild("Glow") then
						local st = Instance.new("UIStroke"); st.Name = "Glow"; st.Color = K(255, 236, 140); st.Thickness = 3
						st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; st.Parent = row
					end
					if not row:FindFirstChild("Shine") then
						local sh = Instance.new("Frame"); sh.Name = "Shine"; sh.BackgroundColor3 = K(255, 255, 255); sh.BorderSizePixel = 0
						sh.Size = UDim2.new(0, 120, 1, 0); sh.Position = UDim2.new(0, -130, 0, 0); sh.ZIndex = 1; sh.Parent = row
						local g = Instance.new("UIGradient")
						g.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.05), NumberSequenceKeypoint.new(1, 1)})   -- bright enough to catch on a phone
						g.Parent = sh
					end
				end
			end
		end
		-- the frame: four thin neon bars just in front of the face's edges (the face shows its -X side)
		for _, old in ipairs(model:GetChildren()) do if old.Name == "GlowTrim" then old:Destroy() end end
		local hy, hz = face.Size.Y / 2, face.Size.Z / 2
		for _, spec in ipairs({
			{CFrame.new(-0.08, hy + 0.08, 0), Vector3.new(0.1, 0.16, face.Size.Z + 0.32)},
			{CFrame.new(-0.08, -hy - 0.08, 0), Vector3.new(0.1, 0.16, face.Size.Z + 0.32)},
			{CFrame.new(-0.08, 0, hz + 0.08), Vector3.new(0.1, face.Size.Y, 0.16)},
			{CFrame.new(-0.08, 0, -hz - 0.08), Vector3.new(0.1, face.Size.Y, 0.16)},
		}) do
			local p = Instance.new("Part"); p.Name = "GlowTrim"; p.Size = spec[2]; p.CFrame = face.CFrame * spec[1]
			p.Color = K(255, 205, 80); p.Material = Enum.Material.Neon; p.Anchored = true; p.CanCollide = false
			p.CanQuery = false; p.CanTouch = false; p.CastShadow = false; p.Parent = model
		end
	end
	styleBoard(sg, face, board)

	-- ---------------------------------------------------------------- server ----
	local SERVER = [==[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local DSS = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local PPS = game:GetService("ProximityPromptService")
local F = script.Parent
local ev = RS:WaitForChild("RaceEvent")
local awardItems = RS:WaitForChild("AwardItems")
local awardAcorns = RS:WaitForChild("AwardAcorns")
local MAP = F:GetAttribute("Map") or "forest"
local Registry = require(workspace:WaitForChild("SquirrelScripts"):WaitForChild("SquirrelRegistry"))
local isRace = {}
for _, e in ipairs(Registry.squirrels) do if e.map == MAP then isRace[e.id] = true end end

local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)                   -- an absolute value, sent as a delta so it merges safely
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function fmt(cs)
	local s = cs / 100
	local m = math.floor(s / 60)
	return string.format("%d:%05.2f", m, s - m * 60)
end

-- ---- which squirrels are in the race, and hearing their clicks ----
local races = {}                                            -- player -> {phase, found, n, total, t0}
local ids, total = {}, 0
local hooked = setmetatable({}, {__mode = "k"})
local finish
local function stop(player, why)
	if not races[player] then return end
	races[player] = nil
	player:SetAttribute("Racing", nil)
	ev:FireClient(player, "stop", why)
end
local function onClick(player, id)
	local r = races[player]
	if not r or r.phase ~= "run" or r.found[id] then return end
	r.found[id] = true; r.n += 1
	ev:FireClient(player, "tick", id, r.n, r.total, os.clock() - r.t0)
	if r.n >= r.total then finish(player) end
end
local function scan()
	local list, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and isRace[id] and not list[id] then
			list[id] = true; n += 1
   for _,part in ipairs(m:GetDescendants()) do
    if part:IsA("BasePart") and not hooked[part] then
     hooked[part]=true;part.CanTouch=true
     part.Touched:Connect(function(hit)
      local char=hit:FindFirstAncestorOfClass("Model");local player=char and Players:GetPlayerFromCharacter(char)
      if player then onClick(player,id) end
     end)
    end
   end
			for _, cd in ipairs(m:GetDescendants()) do
				if cd:IsA("ClickDetector") and not hooked[cd] then
					hooked[cd] = true
					cd.MouseClick:Connect(function(player) onClick(player, id) end)
				end
			end
		end
	end
	ids, total = list, n
	F:SetAttribute("Total", n)
end
task.spawn(function() while true do scan(); task.wait(total == 0 and 1 or 8) end end)

-- ---- the board ----
local store
if not RunService:IsStudio() then
	pcall(function() store = DSS:GetOrderedDataStore(F:GetAttribute("StoreName") or "ForestRace_v1") end)
end
local localBest, names = {}, {}
local boardGui = F:WaitForChild("RaceBoard"):WaitForChild("Face"):WaitForChild("Board")
local MEDAL = {utf8.char(0x1F947), utf8.char(0x1F948), utf8.char(0x1F949)}     -- gold, silver, bronze
local function paint(list)
	for i = 1, 10 do
		local row = boardGui:FindFirstChild("Row" .. i)
		local e = list[i]
		if row then
			row.Visible = e ~= nil                                   -- no empty stripes
			row.Rank.Text = e and (MEDAL[i] or (tostring(i) .. ".")) or ""
			row.Who.Text = e and (names[e.uid] or "...") or ""
			row.Time.Text = e and fmt(e.cs) or ""
		end
	end
end
local refreshing, again = false, false
local function refreshBoard()
	if refreshing then again = true return end
	refreshing = true
	local list, ok = {}, false
	if store then
		ok = pcall(function()
			local page = store:GetSortedAsync(true, 10):GetCurrentPage()
			for _, e in ipairs(page) do list[#list + 1] = {uid = tonumber(e.key), cs = tonumber(e.value)} end
		end)
	end
	if not ok then
		list = {}
		for uid, cs in pairs(localBest) do list[#list + 1] = {uid = uid, cs = cs} end
		table.sort(list, function(a, b2) return a.cs < b2.cs end)
	end
	local need = {}
	for i, e in ipairs(list) do if i <= 10 and e.uid and not names[e.uid] then need[#need + 1] = e.uid end end
	if #need > 0 then
		pcall(function() for _, info in ipairs(UserService:GetUserInfosByUserIdsAsync(need)) do names[info.Id] = info.DisplayName end end)
		for _, uid in ipairs(need) do
			if not names[uid] then
				local ok2, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
				names[uid] = ok2 and n or "a squirrel finder"
			end
		end
	end
 local ranks={};for i,e in ipairs(list) do if i<=10 then ranks[e.uid]=i end end
 for _,p in ipairs(Players:GetPlayers()) do
  local scope=ok and "global" or (RunService:IsStudio() and "server" or "unavailable")
  p:SetAttribute("PassportBoard_race",game:GetService("HttpService"):JSONEncode({rank=scope~="unavailable" and (ranks[p.UserId] or 0) or 0,scope=scope,checked=workspace:GetServerTimeNow()}))
 end
	paint(list)
	refreshing = false
	if again then again = false; task.defer(refreshBoard) end
end
local function submit(player, cs)
	names[player.UserId] = player.DisplayName
	if not localBest[player.UserId] or cs < localBest[player.UserId] then localBest[player.UserId] = cs end
	if store then
		local ok, err = pcall(function()
			store:UpdateAsync(tostring(player.UserId), function(old)
				if old and old <= cs then return nil end         -- the board keeps a player's fastest
				return cs
			end)
		end)
		if not ok then warn("ForestRace: could not save the time: " .. tostring(err)) end
	end
	refreshBoard()
end
task.spawn(function() while true do refreshBoard(); task.wait(F:GetAttribute("BoardRefresh") or 60) end end)

-- ---- a race ----
local function idList() local t = {} for id in pairs(ids) do t[#t + 1] = id end return t end
local function start(player)
	if races[player] or total == 0 or not player:GetAttribute("SaveLoaded") then return end
	local r = {phase = "count", found = {}, n = 0, total = total}
	races[player] = r
	player:SetAttribute("Racing", true)
	local cd = F:GetAttribute("CountdownSeconds") or 3
	ev:FireClient(player, "countdown", cd, r.total, idList(), item(player, "race_best"))
	task.delay(cd, function()
		if races[player] ~= r then return end
		r.phase = "run"; r.t0 = os.clock()
		ev:FireClient(player, "go")
		task.delay((F:GetAttribute("MaxMinutes") or 20) * 60, function() if races[player] == r then stop(player, "time") end end)
	end)
end
finish = function(player)
	local r = races[player]
	if not r then return end
	local secs = os.clock() - r.t0
	local cs = math.max(1, math.floor(secs * 100 + 0.5))
	races[player] = nil
	player:SetAttribute("Racing", nil)
	local best = item(player, "race_best")
	local isBest = best <= 0 or cs < best
	if isBest then setItem(player, "race_best", cs) end
	-- a few acorns for beating your own best (Shannon: "a few acorns if you beat your best time ok"); not for a time too
	-- quick to be real (the same MinSeconds that keeps it off the board)
	local prize = 0
	if isBest and secs >= (F:GetAttribute("MinSeconds") or 45) then
		prize = F:GetAttribute("BestAcorns") or 10
		if prize > 0 then
			awardAcorns:Fire(player, prize)
			player:SetAttribute("Acorns", (player:GetAttribute("Acorns") or 0) + prize)
		end
	end
	local passport = game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity")
	if passport then passport:Fire(player,"race",{cs=cs,previousBest=best,improvement=best>cs and best-cs or 0,prize=prize,boardReady=false}) end
	ev:FireClient(player, "finish", cs, isBest and cs or best, isBest, prize)
	print(string.format("ForestRace: %s ran the forest in %s%s", player.Name, fmt(cs), isBest and " (a personal best)" or ""))
	if secs >= (F:GetAttribute("MinSeconds") or 45) then
		task.spawn(submit, player, isBest and cs or best)
	else
		player:SetAttribute("PassportBoard_race",game:GetService("HttpService"):JSONEncode({rank=0,scope="unavailable",time=workspace:GetServerTimeNow()}))
		warn(string.format("ForestRace: %s's %s is too quick for the board", player.Name, fmt(cs)))
	end
end
PPS.PromptTriggered:Connect(function(prompt, player)
	if prompt.Name == "StartPrompt" and prompt:IsDescendantOf(F) then start(player) end
end)
ev.OnServerEvent:Connect(function(player, what)
	if what == "quit" then
		stop(player, "quit")
	elseif what == "again" and not races[player] then
		local char = player.Character
		local p = Vector3.new(F:GetAttribute("StartX"), F:GetAttribute("StartY"), F:GetAttribute("StartZ"))
		if char then char:PivotTo(CFrame.lookAt(p, p + Vector3.new(1, 0, 0))) end
		task.wait(0.3)
		start(player)
	end
end)
Players.PlayerRemoving:Connect(function(p) races[p] = nil end)
if RunService:IsStudio() then                               -- Studio only: count n more squirrels as found, as if clicked
	local dbg = Instance.new("BindableFunction"); dbg.Name = "RaceDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player, n)
		local r = races[player]
		if not r or r.phase ~= "run" then return "not racing" end
		local k = 0
		for id in pairs(ids) do
			if k >= n then break end
			if not r.found[id] then k += 1; onClick(player, id) end
		end
		return tostring(r.n) .. "/" .. tostring(r.total)
	end
end
print("ForestRace: ready")
]==]

	-- ---------------------------------------------------------------- client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = RS:WaitForChild("RaceEvent")
local C = Color3.fromRGB
local NAVY, GOLD, CREAM, DEEP = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220), C(84, 48, 18)
local FONT = Enum.Font.FredokaOne
local function fmt(cs)
	local s = cs / 100
	local m = math.floor(s / 60)
	return string.format("%d:%05.2f", m, s - m * 60)
end
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p end
local function stroke(p, colour, th) local s = Instance.new("UIStroke"); s.Color = colour; s.Thickness = th; s.LineJoinMode = Enum.LineJoinMode.Round; s.Parent = p; return s end
local function label(parent, t, size, colour, pos, sz, align)
	local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Position = pos; l.Size = sz; l.Font = FONT; l.TextSize = size
	l.TextColor3 = colour; l.Text = t; l.TextXAlignment = align or Enum.TextXAlignment.Center; l.Parent = parent
	return l
end
local function button(parent, t, pos, sz, colour)
	local b = Instance.new("TextButton"); b.Position = pos; b.Size = sz; b.BackgroundColor3 = colour; b.BorderSizePixel = 0; b.AutoButtonColor = false
	b.Font = FONT; b.TextSize = 18; b.TextColor3 = DEEP; b.Text = t; b.Parent = parent
	corner(b, 12)
	return b
end

-- ---- the squirrels' colours: the same texture swap SquirrelAnim makes, so the two agree ----
local function meshOf(model) for _, d in ipairs(model:GetDescendants()) do if d:IsA("MeshPart") and d:GetAttribute("GrayTexture") then return d end end end
local function getTex(mesh) local sa = mesh:FindFirstChildOfClass("SurfaceAppearance"); if sa then return sa.ColorMap end return mesh.TextureID end
local function setTex(mesh, id)
	if not id or id == "" then return end
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then sa.ColorMap = id else mesh.TextureID = id end
end
local race                                                  -- {ids, found, n, total, best, running, t0}
local function paint()
	if not race then return end
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and race.ids[id] then
			local mesh = meshOf(m)
			if mesh then
				local want = race.found[id] and mesh:GetAttribute("ColorTexture") or mesh:GetAttribute("GrayTexture")
				if want and getTex(mesh) ~= want then setTex(mesh, want) end
			end
		end
	end
end
local function restore(idset)
	local list = {}
	local sync = RS:FindFirstChild("SquirrelSync")
	if sync then
		local ok, res = pcall(function() return sync:InvokeServer() end)
		if ok and type(res) == "table" then list = res end
	end
	local found = {}
	for _, id in ipairs(list) do found[id] = true end
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and idset[id] then
			local mesh = meshOf(m)
			if mesh then setTex(mesh, found[id] and mesh:GetAttribute("ColorTexture") or mesh:GetAttribute("GrayTexture")) end
		end
	end
end
-- streamed-in squirrels get their race colour too (SquirrelAnim paints each newcomer with its real colour)
task.spawn(function() while true do if race then paint() end task.wait(0.4) end end)

-- ---- on screen ----
local gui = Instance.new("ScreenGui"); gui.Name = "RaceGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 16; gui.Parent = pg
local bar = Instance.new("Frame"); bar.Name = "Clock"; bar.AnchorPoint = Vector2.new(0.5, 0); bar.Position = UDim2.new(0.5, 0, 0, 62); bar.Size = UDim2.fromOffset(300, 56)
bar.BackgroundColor3 = NAVY; bar.BackgroundTransparency = 0.08; bar.Visible = false; bar.Parent = gui
corner(bar, 14); stroke(bar, GOLD, 2)
local clock = label(bar, "0:00.00", 30, CREAM, UDim2.fromOffset(14, 0), UDim2.new(0, 150, 1, 0), Enum.TextXAlignment.Left)
local count = label(bar, "0 / 15", 20, GOLD, UDim2.fromOffset(164, 0), UDim2.new(0, 76, 1, 0))
local quit = button(bar, "Quit", UDim2.fromOffset(244, 13), UDim2.fromOffset(46, 30), C(214, 202, 176)); quit.TextSize = 14
local big = label(gui, "", 96, GOLD, UDim2.fromScale(0.5, 0.42), UDim2.fromOffset(360, 150))
big.AnchorPoint = Vector2.new(0.5, 0.5); big.Visible = false
stroke(big, DEEP, 4)
local card = Instance.new("Frame"); card.Name = "Result"; card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.45)
card.Size = UDim2.fromOffset(340, 236); card.BackgroundColor3 = NAVY; card.BorderSizePixel = 0; card.Visible = false; card.Parent = gui
corner(card, 16); stroke(card, GOLD, 2)
label(card, "Forest Race", 24, CREAM, UDim2.fromOffset(0, 12), UDim2.new(1, 0, 0, 28))
local rsub = label(card, "All 15 found!", 16, GOLD, UDim2.fromOffset(0, 42), UDim2.new(1, 0, 0, 20))
local rtime = label(card, "0:00.00", 46, GOLD, UDim2.fromOffset(0, 64), UDim2.new(1, 0, 0, 50))
local rbest = label(card, "", 17, CREAM, UDim2.fromOffset(0, 118), UDim2.new(1, 0, 0, 24))
local again = button(card, "Race again", UDim2.fromOffset(28, 170), UDim2.fromOffset(160, 44), GOLD)
local close = button(card, "Close", UDim2.fromOffset(204, 170), UDim2.fromOffset(108, 44), C(214, 202, 176))
local note = label(gui, "", 18, CREAM, UDim2.new(0.5, 0, 1, -110), UDim2.fromOffset(420, 40))
note.AnchorPoint = Vector2.new(0.5, 1); note.BackgroundColor3 = NAVY; note.BackgroundTransparency = 1; note.TextTransparency = 1; note.TextWrapped = true
corner(note, 12)
local noteAt = 0
local function say(t)
	note.Text = t; note.BackgroundTransparency = 0.15; note.TextTransparency = 0
	local mine = os.clock(); noteAt = mine
	task.delay(3.2, function() if noteAt ~= mine then return end; TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency = 1, TextTransparency = 1}):Play() end)
end
local function startPrompt() local p = F:FindFirstChild("StartPrompt", true); return p end
local function setPromptOn(on) local p = startPrompt(); if p then p.Enabled = on end end

-- the board shows your own best on your own screen. The board streams in and out with distance, so it is looked up
-- each time and repainted whenever it arrives, rather than waited on (a wait would hold up everything below it).
local function footerLabel()
	local b = F:FindFirstChild("RaceBoard"); local f = b and b:FindFirstChild("Face"); local g = f and f:FindFirstChild("Board")
	return g and g:FindFirstChild("Footer")
end
local function showBest()
	local footer = footerLabel()
	if not footer then return end
	local best = tonumber(player:GetAttribute("Item_race_best")) or 0
	footer.Text = best > 0 and ("Your best: " .. fmt(best)) or "Your best: - (start at the gate!)"
end
showBest()
F.DescendantAdded:Connect(function(d) if d.Name == "Footer" then task.defer(showBest) end end)
player:GetAttributeChangedSignal("Item_race_best"):Connect(showBest)

local function pop(obj, size)
	obj.TextSize = math.min(100, size * 1.3)                -- TextSize tops out at 100
	TweenService:Create(obj, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = size}):Play()
end
local function flash(model)
	local h = Instance.new("Highlight"); h.FillColor = GOLD; h.FillTransparency = 0.4; h.OutlineColor = C(255, 250, 220); h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
	TweenService:Create(h, TweenInfo.new(0.8), {FillTransparency = 1, OutlineTransparency = 1}):Play()
	game:GetService("Debris"):AddItem(h, 0.9)
end
local function endRace()
	local r = race
	race = nil
	bar.Visible = false; big.Visible = false
	setPromptOn(true)
	if r then task.spawn(restore, r.ids) end
end

RunService.RenderStepped:Connect(function()
	if race and race.running then clock.Text = fmt(math.floor((os.clock() - race.t0) * 100)) end
end)
ev.OnClientEvent:Connect(function(what, a, b, c, d)
	if what == "countdown" then
		local set = {}
		for _, id in ipairs(c or {}) do set[id] = true end
		race = {ids = set, found = {}, n = 0, total = b or 15, best = d or 0, running = false}
		card.Visible = false; setPromptOn(false)
		clock.Text = "0:00.00"; count.Text = "0 / " .. tostring(race.total); bar.Visible = true
		paint()
		task.spawn(function()
			big.Visible = true
			for i = a or 3, 1, -1 do
				if not race then break end
				big.Text = tostring(i); big.TextColor3 = GOLD; pop(big, 96); task.wait(1)
			end
		end)
	elseif what == "go" then
		if not race then return end
		race.running = true; race.t0 = os.clock()
		big.Text = "GO!"; big.TextColor3 = C(150, 230, 120); pop(big, 96)
		task.delay(0.8, function() big.Visible = false end)
		say(string.format("Find all %d forest squirrels!", race.total))
	elseif what == "tick" then
		if not race then return end
		race.found[a] = true; race.n = b
		race.t0 = os.clock() - (d or 0)                         -- keep in step with the server's clock
		count.Text = tostring(b) .. " / " .. tostring(c); pop(count, 20)
		paint()
		-- the find plays just as it did the first time - sound, sparkles, colour, hop, name - from SquirrelAnim (Shannon: "the
		-- squirrels should still make a ding and an appear when you choose them"); the gold flash if that is missing
		local ss = workspace:FindFirstChild("SquirrelScripts")
		local fl = ss and ss:FindFirstChild("RaceFlourish")
		if fl then fl:Fire(a) else for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do if m:GetAttribute("SquirrelId") == a then flash(m) end end end
	elseif what == "finish" then
		if race then race.running = false end
		clock.Text = fmt(a)
		rtime.Text = fmt(a)
		rsub.Text = "All " .. tostring(race and race.total or 15) .. " found!"
		rbest.Text = c and ("New personal best!" .. ((d or 0) > 0 and ("  +" .. d .. " acorns") or "")) or ("Your best: " .. fmt(b))
		rbest.TextColor3 = c and GOLD or CREAM
		endRace()
		card.Visible = true
	elseif what == "stop" then
		endRace()
		if a == "time" then say("Out of time! The gate is waiting when you want another go.") else say("Race stopped. Your squirrels are back to normal.") end
	end
end)
quit.Activated:Connect(function() ev:FireServer("quit") end)
again.Activated:Connect(function() card.Visible = false; ev:FireServer("again") end)
close.Activated:Connect(function() card.Visible = false end)

-- the board's first place shines: a soft light runs across the gold bar every few seconds and its rim pulses. The board
-- streams in and out with distance, so it is looked up each time.
task.spawn(function()
	while true do
		local board = F:FindFirstChild("RaceBoard")
		local face = board and board:FindFirstChild("Face")
		local gui = face and face:FindFirstChild("Board")
		local row = gui and gui:FindFirstChild("Row1")
		local shine, glow = row and row:FindFirstChild("Shine"), row and row:FindFirstChild("Glow")
		if shine and row.Visible then
			shine.Position = UDim2.new(0, -130, 0, 0)
			TweenService:Create(shine, TweenInfo.new(1.4, Enum.EasingStyle.Sine), {Position = UDim2.new(1, 10, 0, 0)}):Play()
		end
		if glow then
			glow.Transparency = 0.65
			TweenService:Create(glow, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), {Transparency = 0}):Play()
		end
		task.wait(3.4)
	end
end)
]==]
	local s = Instance.new("Script"); s.Name = "RaceServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "RaceClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace
	print(string.format("ForestRace: installed - gate at (%.0f,%.1f,%.0f), board at (%.0f,%.0f)", GX, g, GZ, BX, BZ))
	return F
end
