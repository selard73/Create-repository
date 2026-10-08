-- Champion: the Grand Keeper of the Day. Shannon (Sep 25): "the first person to complete [all 44] on any day gets
-- awarded the Grand Keeper of the Great Acorn title and it's numbered by days the game is in existence. For instance,
-- Grand Keeper of the Great Acorn (Day 1); if there is a day where no one gets it, you skip that day. When the first
-- person finds all 44, there should be fireworks seen on all of the maps and an announcement and a statue in the park
-- next to the fountain of that player holding a giant acorn and a squirrel saluting him."
--   THE CLAIM: the moment a player's finds reach every squirrel in the game, the server claims today in a DataStore
--   (DayChampion_v1, key day_<index>; UpdateAsync, so two servers can never both win). The day turns at the daily
--   gift's DayOffsetHours (UTC). Day 1 is LaunchDay (a day index: 20721 = Sep 25 2026); nothing is awarded before it.
--   NUMBERED BY ORDER (Shannon, Sep 26: "I don't want to count it by days because there could be days when no one gets
--   it but count it by order instead 1st, 2nd, 3rd, 4th"): the day claim still makes one winner a day, and each winner
--   also takes the next number in the HALL (same store, key "hall" = {list = {{no, uid, name, user, day, t, total}, ..}};
--   UpdateAsync, so two servers never hand out the same number). The Day winners from before were numbered in the order
--   they won, by the first live server to read the hall (reconcile() also mends a win whose number failed to save).
--   ONCE PER TOTAL (Shannon: winners only - "I think its crazy to give every person a status, then where is the
--   competition?"): whoever has already won with every squirrel there is cannot win again (e.g. after a Reset); when a
--   new map raises the total, everyone races again ("players who progress will get the chance to win it in the next map").
--   THE TITLE: "3rd Grand Keeper of the Great Acorn" - player attribute ChampionTitle, which the honours show on the
--   name tag and the title pill in place of the plain title, set from the hall on join with ChampionNo, ChampionDay,
--   ChampionTotal and ChampionWins (the badge case reads them). Nothing new is written to a player's save.
--   THE PARTY: MessagingService tells every server: fireworks over all three maps, a banner and a chat line for
--   everyone, and the statue is rebuilt.
--   THE STATUE: on the lawn just south of the fountain courtyard, ONE statue on one plinth (Shannon: "the statue
--   should include the character and the squirrel, they should not be 2 separate statues"): the champion's own avatar
--   in marble holding a gilded giant acorn up high in one hand, the other arm hanging relaxed at their side (Shannon:
--   "holding the acorn up in one hand" ... "at her side the way the character's arms naturally fall when standing
--   still"), and beside them on the same plinth the
--   Forest Ranger Squirrel in marble, standing to attention and looking up at them, tail raised high in salute (the
--   squirrel rigs have chest, neck, head and tail bones but no arms, so a paw-to-brow salute cannot be posed). A
--   bronze plaque on the front. The newest Keeper stands there (the last in the hall); before the first one, the
--   squirrel waits beside the acorn.
-- Studio cannot reach the DataStore or MessagingService (API access stays off for tests): there a claim is decided
-- inside the one server, and the day may be before LaunchDay. Studio also gets ChampionDebug (BindableFunction).
-- Also patches workspace.Honours.TitleServer so the honours show ChampionTitle.
-- Run in edit mode (re-runnable).
return function(opts)
	opts = opts or {}
	local RS = game:GetService("ReplicatedStorage")
	local ServerStorage = game:GetService("ServerStorage")
	local C = Color3.fromRGB
	local old = workspace:FindFirstChild("Champion")
	local keepBadge = old and tonumber(old:GetAttribute("Badge_champion")) or 0          -- a badge id entered in Properties survives a reinstall
	if old then old:Destroy() end
	local F = Instance.new("Folder"); F.Name = "Champion"
	local PX, PZ = opts.x or 260, opts.z or -54
	-- one plinth, two figures: the champion a little east of the middle, the squirrel to the west, turned to face them
	local FIG_DX, SQ_DX = opts.figureDX or 2.2, opts.squirrelDX or -3.4
	F:SetAttribute("LaunchDay", opts.launchDay or 20721)
	-- the Roblox (profile) badge for the win: 0 until Shannon creates it on the Creator Hub and pastes its id here.
	-- A Roblox badge cannot carry the day number; the in-game badge case (workspace.BadgeCase) shows that.
	F:SetAttribute("Badge_champion", opts.badgeId or (keepBadge > 0 and keepBadge) or 2765102309602723)   -- "Grand Keeper of the Day" (Shannon, Sep 25)
	F:SetAttribute("Scale", 1.5); F:SetAttribute("SquirrelScale", 1.45); F:SetAttribute("SaluteSquirrel", "ranger_squirrel")
	F:SetAttribute("ChestTilt", -8); F:SetAttribute("HeadTilt", -18); F:SetAttribute("TailTilt", 30)
	F:SetAttribute("HoldHand", "Left")                                      -- the hand that holds the acorn up (the squirrel's side)
	-- where each arm points, in the statue's own frame: (out to that arm's side, up, forward)
	F:SetAttribute("HoldArm", Vector3.new(0.45, 1, 0.15)); F:SetAttribute("FreeArm", Vector3.new(0.22, -1, 0.12)); F:SetAttribute("FreeBend", 15)   -- relaxed: a little out and forward, elbow soft
	F:SetAttribute("FireworkSeconds", 25); F:SetAttribute("FireworkLaunch", opts.launchSound or ""); F:SetAttribute("FireworkPop", opts.popSound or "")
	-- the show's sound, heard the same everywhere: Pro Sound Effects "Fireworks Fast 3 (SFX)" (13 s, looped); swap freely
	F:SetAttribute("FireworkShow", opts.showSound or "rbxassetid://9114447178"); F:SetAttribute("FireworkVolume", 0.6)
	local ev = RS:FindFirstChild("ChampionEvent")
	if not ev then ev = Instance.new("RemoteEvent"); ev.Name = "ChampionEvent"; ev.Parent = RS end

	local function part(name, size, cf, colour, material, parent, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = colour
		p.Material = material or Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = true
		p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		if shape then p.Shape = shape end
		p.Parent = parent
		return p
	end
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.FilterDescendantsInstances = {F}
	local hit = workspace:Raycast(Vector3.new(PX, 30, PZ), Vector3.new(0, -60, 0), rp)
	local g = hit and hit.Position.Y or 0
	local STONE, TRIM, BRONZE = C(214, 208, 196), C(226, 186, 80), C(150, 108, 58)

	-- ---------------------------------------------------------------- the plinth and its plaque ----
	local plinth = Instance.new("Model"); plinth.Name = "Plinth"; plinth.Parent = F
	local PW = opts.plinthWidth or 12                                        -- wide enough for the champion and the squirrel side by side
	part("Base", Vector3.new(PW + 2, 1, 9), CFrame.new(PX, g + 0.5, PZ), STONE, Enum.Material.Marble, plinth)
	part("Body", Vector3.new(PW, 3, 7), CFrame.new(PX, g + 2.5, PZ), STONE, Enum.Material.Marble, plinth)
	part("Band", Vector3.new(PW + 0.12, 0.25, 7.12), CFrame.new(PX, g + 3.7, PZ), TRIM, Enum.Material.SmoothPlastic, plinth)
	part("Cap", Vector3.new(PW + 0.6, 0.4, 7.6), CFrame.new(PX, g + 4.2, PZ), STONE, Enum.Material.Marble, plinth)
	local plaque = part("Plaque", Vector3.new(5.4, 2.2, 0.15), CFrame.new(PX, g + 2.3, PZ - 3.5 - 0.075), BRONZE, Enum.Material.SmoothPlastic, plinth)
	local sg = Instance.new("SurfaceGui"); sg.Name = "Words"; sg.Face = Enum.NormalId.Front; sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 60; sg.LightInfluence = 0.4; sg.Parent = plaque
	local function line(name, y, h, size, font, colour)
		local l = Instance.new("TextLabel"); l.Name = name; l.BackgroundTransparency = 1; l.Position = UDim2.new(0, 10, 0, y); l.Size = UDim2.new(1, -20, 0, h)
		l.Font = font; l.TextScaled = true; l.TextColor3 = colour; l.TextWrapped = true; l.Text = ""; l.Parent = sg
		local cap = Instance.new("UITextSizeConstraint"); cap.MaxTextSize = size; cap.Parent = l   -- long names and titles shrink to fit
		local s = Instance.new("UIStroke"); s.Color = C(70, 44, 18); s.Thickness = 1.5; s.Transparency = 0.2; s.Parent = l
		return l
	end
	line("Title", 8, 30, 26, Enum.Font.Antique, C(255, 226, 150)).Text = "THE GRAND KEEPER"
	line("Day", 38, 24, 20, Enum.Font.Antique, C(255, 236, 190))
	line("Who", 60, 34, 30, Enum.Font.FredokaOne, C(255, 246, 220)).Text = "This could be you"
	line("Note", 94, 36, 15, Enum.Font.Merriweather, C(255, 236, 190)).Text = "Be the first to find all 44 squirrels in a day and your statue will stand here."
	F:SetAttribute("PlinthX", PX); F:SetAttribute("PlinthZ", PZ); F:SetAttribute("TopY", g + 4.4)
	-- where each of them stands on the top of the plinth
	F:SetAttribute("FigureX", PX + FIG_DX)
	F:SetAttribute("SquirrelX", PX + SQ_DX); F:SetAttribute("SquirrelY", g + 4.4); F:SetAttribute("SquirrelZ", PZ)

	-- ---------------------------------------------------------------- the gilded acorn (a template for the server) ----
	local oldAcorn = ServerStorage:FindFirstChild("ChampionAcorn"); if oldAcorn then oldAcorn:Destroy() end
	local tpl = ServerStorage:FindFirstChild("AcornTemplate")
	local acornOk = false
	if tpl then
		local a = tpl:Clone(); a.Name = "ChampionAcorn"
		for _, d in ipairs(a:GetDescendants()) do
			if d:IsA("BaseScript") or d:IsA("Light") or d:IsA("ParticleEmitter") or d:IsA("Sound") or d:IsA("ClickDetector") or d:IsA("TouchTransmitter") then d:Destroy() end
		end
		local hitPart = a:FindFirstChild("Hit"); if hitPart then hitPart:Destroy() end
		for _, p in ipairs(a:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Anchored = true; p.CanCollide = true; p.CastShadow = true
				if p:IsA("MeshPart") then p.TextureID = "" end
				local n = p.Name:lower()
				p.Color = (n == "nut") and C(255, 206, 64) or (n == "cap" and C(214, 160, 44) or C(190, 136, 40))
				p.Material = Enum.Material.SmoothPlastic; p.Reflectance = 0.2
			end
		end
		a.Parent = ServerStorage
		acornOk = true
	end

	-- ---------------------------------------------------------------- server ----
	local SERVER = [==[local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DSS = game:GetService("DataStoreService")
local MS = game:GetService("MessagingService")
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local F = script.Parent
local ev = RS:WaitForChild("ChampionEvent")
local awardItems = RS:WaitForChild("AwardItems")
local TOPIC = "DayChampion_v1"
local STUDIO = RunService:IsStudio()
local store
if not STUDIO then pcall(function() store = DSS:GetDataStore("DayChampion_v1") end) end
local MARBLE = Color3.fromRGB(232, 228, 218)

local function offsetHours() local d = workspace:FindFirstChild("Daily"); return (d and d:GetAttribute("DayOffsetHours")) or 9 end
local function today() return math.floor((os.time() - offsetHours() * 3600) / 86400) end
local function ordinal(n)
	n = math.floor(tonumber(n) or 0)
	local m100, m10, s = n % 100, n % 10, "th"
	if m100 < 11 or m100 > 13 then
		if m10 == 1 then s = "st" elseif m10 == 2 then s = "nd" elseif m10 == 3 then s = "rd" end
	end
	return tostring(n) .. s
end
local function titleFor(no) return ordinal(no) .. " Grand Keeper of the Great Acorn" end
local function item(player, id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function setItem(player, id, value)
	local d = value - item(player, id)
	if d ~= 0 then awardItems:Fire(player, id, d) end
end
local function totalSquirrels()
	local ids, n = {}, 0
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		local id = m:GetAttribute("SquirrelId")
		if id and not ids[id] then ids[id] = true; n += 1 end
	end
	return n
end
local function dateOf(day) return os.date("!%B %d, %Y", day * 86400 + 12 * 3600) end

-- ---- the statue ----
local PX, PZ, TOP = F:GetAttribute("PlinthX"), F:GetAttribute("PlinthZ"), F:GetAttribute("TopY")
local FX = F:GetAttribute("FigureX") or PX                               -- the champion's place on the plinth
local words = F:WaitForChild("Plinth"):WaitForChild("Plaque"):WaitForChild("Words")
local function strip(model)
	for _, t in ipairs(CollectionService:GetTags(model)) do CollectionService:RemoveTag(model, t) end
	for k in pairs(model:GetAttributes()) do if not k:match("^RBX_") then pcall(function() model:SetAttribute(k, nil) end) end end
	for _, d in ipairs(model:GetDescendants()) do
		for _, t in ipairs(CollectionService:GetTags(d)) do CollectionService:RemoveTag(d, t) end
		for k in pairs(d:GetAttributes()) do if not k:match("^RBX_") then pcall(function() d:SetAttribute(k, nil) end) end end
	end
end
local function stoneify(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") or d:IsA("Clothing") or d:IsA("ShirtGraphic") or d:IsA("BodyColors")
			or d:IsA("BaseScript") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") or d:IsA("ParticleEmitter")
			or d:IsA("Light") or d:IsA("Sound") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			if p:IsA("MeshPart") then p.TextureID = "" end
			p.Color = MARBLE; p.Material = Enum.Material.Marble; p.Reflectance = 0
		end
	end
end
local function placeOn(model, x, topY, z)
	local cf, size = model:GetBoundingBox()
	model:PivotTo(model:GetPivot() + Vector3.new(x - cf.Position.X, topY - (cf.Position.Y - size.Y / 2), z - cf.Position.Z))
end
-- A FIGURE STANDS ON ITS FEET. placeOn stands a model on the bottom of its bounding box - but a figure's box also holds
-- the invisible HumanoidRootPart, a fixed-size block at the hips, and on a short avatar (a baby with tiny legs) that block
-- reaches below the feet, so the statue floated over the plinth (Shannon, Sep 26: "a very short baby avatar and the
-- statue formed with him floating"; "some avatars are bigger ... I also want them on their feet and not buried"). The
-- lowest corner of the feet goes on the plinth top, whatever the avatar's size or shape; without visible feet, the
-- lowest visible part of the body (never the root, never anything worn).
local BODY = {LeftFoot = true, RightFoot = true, LeftLowerLeg = true, RightLowerLeg = true, LeftUpperLeg = true, RightUpperLeg = true,
	LowerTorso = true, UpperTorso = true, Head = true, LeftHand = true, RightHand = true, LeftLowerArm = true, RightLowerArm = true,
	LeftUpperArm = true, RightUpperArm = true}
local function lowestPoint(model)
	local low = math.huge
	local function consider(p)
		local h = p.Size / 2
		for _, sx in ipairs({-1, 1}) do for _, sy in ipairs({-1, 1}) do for _, sz in ipairs({-1, 1}) do
			low = math.min(low, (p.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
		end end end
	end
	for _, n in ipairs({"LeftFoot", "RightFoot"}) do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") and p.Transparency < 0.95 then consider(p) end
	end
	if low == math.huge then
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and BODY[p.Name] and p.Transparency < 0.95 then consider(p) end
		end
	end
	return low
end
local function standOn(model, x, topY, z)
	local cf = model:GetBoundingBox()
	local low = lowestPoint(model)
	if low == math.huge then placeOn(model, x, topY, z) return end
	model:PivotTo(model:GetPivot() + Vector3.new(x - cf.Position.X, topY - low, z - cf.Position.Z))
end
local function giantAcorn(height, parent)
	local src = ServerStorage:FindFirstChild("ChampionAcorn")
	if not src then return nil end
	local a = src:Clone(); a.Name = "GiantAcorn"
	local _, size = a:GetBoundingBox()
	if size.Y > 0 then pcall(function() a:ScaleTo(a:GetScale() * height / size.Y) end) end
	a.Parent = parent or F
	return a
end
local function setPlaque(rec)
	local all = tonumber(rec and rec.total) or totalSquirrels()
	if all <= 0 then all = 44 end
	if rec then
		words.Title.Text = rec.no and ("THE " .. ordinal(rec.no):upper() .. " GRAND KEEPER") or "THE GRAND KEEPER"
		words.Day.Text = "OF THE GREAT ACORN"
		words.Who.Text = tostring(rec.name or "?")
		words.Note.Text = "First to find all " .. tostring(all) .. " squirrels on " .. dateOf(rec.day)
	else
		words.Title.Text = "THE GRAND KEEPER"
		words.Day.Text = ""
		words.Who.Text = "This could be you"
		words.Note.Text = "Be the first to find all " .. tostring(all) .. " squirrels in a day and your statue will stand here."
	end
end
local building = false
-- THE FIGURE, made anywhere: o = {x, top, z (its feet go there), parent, name, scale, look (the way it faces)}. Returns the
-- posed marble figure and the gilded acorn in its raised hand. The fountain's statue and every statue in the Hall of
-- Fame at the Chateau (asked for through MakeStatue) come from this one function, so they always match.
local function makeFigure(rec, o)
	local okD, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(rec.uid) end)
	if not okD or not desc then desc = Instance.new("HumanoidDescription") end
	local okM, model = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not okM or not model then
		warn("Champion: could not make the figure: " .. tostring(model))
		return nil
	end
	local FX, TOP, PZ = o.x, o.top, o.z                                     -- (the names the pose code below always used)
	model.Name = o.name or "Figure"
	for _, s in ipairs(model:GetDescendants()) do if s:IsA("BaseScript") then s:Destroy() end end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff end
	local scale = o.scale or F:GetAttribute("Scale") or 1.5
	pcall(function() model:ScaleTo(scale) end)
	local root = model:FindFirstChild("HumanoidRootPart")
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = (p == root); p.CanCollide = false end end
	local up = Vector3.new(FX, TOP + 30, PZ)
	model:PivotTo(CFrame.lookAt(up, up + (o.look or Vector3.new(0, 0, -1))))   -- the fountain's faces north, toward the fountain
	model.Parent = o.parent or F
	for _ = 1, 6 do RunService.Heartbeat:Wait() end                        -- let the body settle, then freeze it
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	-- One hand holds the acorn up high, the other arm hangs relaxed at the side. The pose is carved rather than
	-- animated: with everything anchored, each arm - and anything worn on it - comes off its joints and is AIMED about
	-- its shoulder (the torso's ShoulderRigAttachment), whatever pose it started in. Avatar rigs come two ways - Motor6D
	-- joints, or the newer AnimationConstraint + BallSocketConstraint pairs - and this works on both (Sep 25: editing
	-- Motor6D joints did nothing on a constraint rig, which is why the first statue kept its arms down).
	local torso = model:FindFirstChild("UpperTorso")
	local function linked(d, moving)
		if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
			return (d.Part0 and moving[d.Part0]) or (d.Part1 and moving[d.Part1])
		elseif d:IsA("Constraint") then
			local a0, a1 = d.Attachment0, d.Attachment1
			return (a0 and moving[a0.Parent]) or (a1 and moving[a1.Parent])
		end
		return false
	end
	local function aim(side, dir, bendDeg)
		local att = torso and torso:FindFirstChild(side .. "ShoulderRigAttachment")
		local hand = model:FindFirstChild(side .. "Hand")
		if not (att and hand and typeof(dir) == "Vector3") then return false end
		local pivot = att.WorldPosition
		local cf = torso.CFrame
		local outward = cf.RightVector * ((side == "Right") and 1 or -1)
		local w = (outward * dir.X + cf.UpVector * dir.Y + cf.LookVector * dir.Z).Unit
		-- the arm's parts, and anything worn on each of them (held on by a weld, or hung from one of their attachments)
		local armParts, owner = {}, {}
		for _, n in ipairs({"UpperArm", "LowerArm", "Hand"}) do local pp = model:FindFirstChild(side .. n); if pp then armParts[pp] = n; owner[pp] = n end end
		for _, acc in ipairs(model:GetChildren()) do
			local h = acc:IsA("Accessory") and acc:FindFirstChild("Handle")
			if h then
				for _, d in ipairs(h:GetChildren()) do
					if d:IsA("JointInstance") or d:IsA("WeldConstraint") then
						local other = (d.Part0 == h) and d.Part1 or d.Part0
						if other and armParts[other] then owner[h] = armParts[other] end
					end
				end
				local ha = h:FindFirstChildWhichIsA("Attachment")
				if ha and not owner[h] then
					for pp, n in pairs(armParts) do if pp:FindFirstChild(ha.Name) then owner[h] = n end end
				end
			end
		end
		for _, d in ipairs(model:GetDescendants()) do if linked(d, owner) then d:Destroy() end end
		local v = hand.Position - pivot
		local axis = v:Cross(w)
		if axis.Magnitude > 1e-6 then
			local rot = CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(v.Unit:Dot(w), -1, 1)))
			for pp in pairs(owner) do pp.CFrame = (rot * (pp.CFrame - pivot)) + pivot end
		end
		-- a soft bend at the elbow: the forearm and hand swing forward a little (never back)
		local upper = model:FindFirstChild(side .. "UpperArm")
		local elbow = upper and upper:FindFirstChild(side .. "ElbowRigAttachment")
		if bendDeg and bendDeg ~= 0 and elbow then
			local e = elbow.WorldPosition
			local bendAxis = w:Cross(cf.LookVector)
			if bendAxis.Magnitude > 1e-6 then
				local rot = CFrame.fromAxisAngle(bendAxis.Unit, math.rad(bendDeg))
				local rel = hand.Position - e
				if ((rot * rel) - rel):Dot(cf.LookVector) < 0 then rot = CFrame.fromAxisAngle(bendAxis.Unit, -math.rad(bendDeg)) end
				for pp, n in pairs(owner) do if n ~= "UpperArm" then pp.CFrame = (rot * (pp.CFrame - e)) + e end end
			end
		end
		return true
	end
	local holdSide = (F:GetAttribute("HoldHand") == "Right") and "Right" or "Left"
	local freeSide = (holdSide == "Left") and "Right" or "Left"
	local upR = aim(holdSide, F:GetAttribute("HoldArm") or Vector3.new(0.45, 1, 0.15), 0)                           -- the acorn, held up high
	local upL = aim(freeSide, F:GetAttribute("FreeArm") or Vector3.new(0.22, -1, 0.12), F:GetAttribute("FreeBend") or 15)   -- relaxed at the side
	if hum then hum:Destroy() end
	stoneify(model)
	strip(model)
	standOn(model, FX, TOP, PZ)                                        -- on its feet (not on the bottom of its box)
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") and p ~= root then p.CanCollide = true end end
	local holding = model:FindFirstChild(holdSide .. "Hand")
	-- the acorn is sized to the sitter (Shannon: "for short or tall avatars will the acorn position correctly too?"): the
	-- same share of their height as on an ordinary avatar, so a baby holds a baby-sized giant acorn and a giant a giant's
	local head = model:FindFirstChild("Head")
	local feet = lowestPoint(model)
	local bodyH = (head and feet < math.huge) and (head.Position.Y + head.Size.Y / 2 - feet) or 5.2 * scale
	local a = giantAcorn(math.clamp(bodyH * 0.385, 1.2, 5), o.parent)
	if a then
		if holding then
			placeOn(a, holding.Position.X, holding.Position.Y + holding.Size.Y / 2 - 0.2, holding.Position.Z)   -- resting on the raised hand
		else
			local cf, size = model:GetBoundingBox()
			placeOn(a, cf.Position.X, cf.Position.Y + size.Y / 2, cf.Position.Z)
		end
	end
	return model, a, upR, upL
end
local function buildStatue(rec)
	while building do task.wait(0.2) end
	building = true
	for _, n in ipairs({"Figure", "GiantAcorn"}) do local o = F:FindFirstChild(n); if o then o:Destroy() end end
	setPlaque(rec)
	if not rec then
		local a = giantAcorn(2.6)
		if a then placeOn(a, FX, TOP, PZ) end
		building = false
		return
	end
	local model, _, upR, upL = makeFigure(rec, {x = FX, top = TOP, z = PZ, parent = F, name = "Figure", scale = F:GetAttribute("Scale") or 1.5, look = Vector3.new(0, 0, -1)})
	if not model then local a = giantAcorn(2.6); if a then placeOn(a, FX, TOP, PZ) end end
	building = false
	print(string.format("Champion: the statue of %s (No. %s) stands by the fountain (arms posed %s/%s)", tostring(rec.name), tostring(rec.no), tostring(upR), tostring(upL)))
end

-- the squirrel that stands to attention, looking up at the statue, tail raised in salute. o = {x, y, z (where it stands),
-- tx, tz (the statue it looks up at), parent, name, scale}; the fountain's is built once, the Hall's through MakeSquirrel
local function makeSquirrel(o)
	local want = F:GetAttribute("SaluteSquirrel") or "ranger_squirrel"
	local src
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do if m:GetAttribute("SquirrelId") == want then src = m break end end
	if not src then warn("Champion: no " .. want .. " to stand by the statue") return nil end
	local m = src:Clone(); m.Name = o.name or "Monument"
	strip(m)
	stoneify(m)
	for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = true end end
	pcall(function() m:ScaleTo(m:GetScale() * (o.scale or F:GetAttribute("SquirrelScale") or 1.7)) end)
	m.Parent = o.parent or F
	local bones = {}
	for _, b in ipairs(m:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	local spot = Vector3.new(o.x, o.y, o.z)
	local FX, PZ = o.tx, o.tz
	if bones.Root and bones.Head then
		-- which way it faces: root -> head, flattened (the rule SquirrelAnim uses); turn it to face the statue
		local f = bones.Head.WorldPosition - bones.Root.WorldPosition
		f = Vector3.new(f.X, 0, f.Z)
		local to = Vector3.new(FX - spot.X, 0, PZ - spot.Z)
		if f.Magnitude > 0.01 and to.Magnitude > 0.01 then
			local pivot = m:GetPivot()
			m:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.atan2(to.X, to.Z) - math.atan2(f.X, f.Z), 0) * pivot.Rotation)
		end
		local fw = bones.Head.WorldPosition - bones.Root.WorldPosition
		fw = Vector3.new(fw.X, 0, fw.Z)
		if fw.Magnitude > 0.01 then
			local left = Vector3.yAxis:Cross(fw.Unit)
			local function tilt(b, deg)
				if not b or not deg or deg == 0 then return end
				local axis = b.WorldCFrame:VectorToObjectSpace(left)
				b.CFrame = b.CFrame * CFrame.fromAxisAngle(axis, math.rad(deg))
			end
			tilt(bones.Chest, F:GetAttribute("ChestTilt"))
			tilt(bones.Head, F:GetAttribute("HeadTilt"))
			tilt(bones.Tail1, F:GetAttribute("TailTilt"))
		end
	end
	placeOn(m, spot.X, spot.Y, spot.Z)
	return m
end
local function buildSquirrel()
	if F:FindFirstChild("Monument") then return end
	makeSquirrel({x = F:GetAttribute("SquirrelX"), y = F:GetAttribute("SquirrelY"), z = F:GetAttribute("SquirrelZ"), tx = FX, tz = PZ, parent = F, name = "Monument"})
end

-- ---- claiming the day ----
local localClaims = {}
local function claim(rec)
	if STUDIO or not store then
		if localClaims[rec.day] then return false, localClaims[rec.day] end
		localClaims[rec.day] = rec
		return true
	end
	for attempt = 1, 3 do
		local won, holder = false, nil
		local ok = pcall(function()
			store:UpdateAsync("day_" .. tostring(rec.day), function(oldRec)
				if oldRec ~= nil then won = false; holder = oldRec; return nil end
				won = true; holder = nil
				return rec
			end)
		end)
		if ok then return won, holder end
		task.wait(2 * attempt)
	end
	return false, nil
end
local function saveLatest(rec)
	if STUDIO or not store then return end
	pcall(function()
		store:UpdateAsync("latest", function(oldRec)
			if type(oldRec) == "table" and (oldRec.day or 0) > rec.day then return nil end
			return rec
		end)
	end)
end
-- the Roblox badge: on the win, and on joining for anyone who won before the badge existed (live servers only)
local BadgeService = game:GetService("BadgeService")
local function giveBadge(player)
	local id = tonumber(F:GetAttribute("Badge_champion")) or 0
	if id <= 0 or STUDIO then return end
	task.spawn(function()
		local okH, has = pcall(function() return BadgeService:UserHasBadgeAsync(player.UserId, id) end)
		if okH and not has then
			local ok, err = pcall(function() BadgeService:AwardBadgeAsync(player.UserId, id) end)            -- the current name
			if not ok then ok, err = pcall(function() BadgeService:AwardBadge(player.UserId, id) end) end    -- the older one
			if not ok then warn("Champion: badge award failed: " .. tostring(err)) end
		end
	end)
end

-- ---- the hall: every Grand Keeper in order, 1st, 2nd, 3rd ... (what the Hall of Fame at the Chateau shows) ----
local hall, hallLoaded = {}, false
local function sortHall() table.sort(hall, function(a, b) return (tonumber(a.no) or 0) < (tonumber(b.no) or 0) end) end
local function hallFind(uid)                                         -- the player's latest win
	local best
	for _, e in ipairs(hall) do if e.uid == uid and (not best or e.no > best.no) then best = e end end
	return best
end
local function hallWins(uid) local n = 0; for _, e in ipairs(hall) do if e.uid == uid then n += 1 end end; return n end
local function hallHas(uid, total)                                   -- already won with this many squirrels (or more)?
	for _, e in ipairs(hall) do if e.uid == uid and (tonumber(e.total) or 44) >= total then return true end end
	return false
end
-- every player's screen gets the list (for the Hall of Fame at the Chateau): HallJson on this folder, in order
local HttpService = game:GetService("HttpService")
local function publishHall()
	local out = {}
	for _, e in ipairs(hall) do table.insert(out, {no = e.no, uid = e.uid, name = e.name, day = e.day, total = e.total}) end
	local ok, s = pcall(function() return HttpService:JSONEncode(out) end)
	if ok then F:SetAttribute("HallJson", s) end
end
local function hallMerge(e)                                          -- an entry this server heard about: kept in order, never twice
	if type(e) ~= "table" or not e.no then return end
	for _, x in ipairs(hall) do if x.no == e.no then return end end
	table.insert(hall, {no = e.no, uid = e.uid, name = e.name, user = e.user, day = e.day, t = e.t, total = e.total})
	sortHall()
	publishHall()
end
-- a day's winner takes the next number: atomic across servers, and safe to repeat (one uid + day is never added twice)
local function hallAppend(rec)
	local function entryFor(list)
		for _, x in ipairs(list) do if x.uid == rec.uid and x.day == rec.day then return x, false end end
		local top = 0
		for _, x in ipairs(list) do top = math.max(top, tonumber(x.no) or 0) end
		return {no = top + 1, uid = rec.uid, name = rec.name, user = rec.user, day = rec.day, t = rec.t, total = rec.total or 44}, true
	end
	if STUDIO or not store then
		local e, new = entryFor(hall)
		if new then table.insert(hall, e); sortHall(); publishHall() end
		return e
	end
	for attempt = 1, 4 do
		local mine
		local ok, final = pcall(function()
			return store:UpdateAsync("hall", function(old)
				local list = (type(old) == "table" and type(old.list) == "table") and old.list or {}
				local e, new = entryFor(list)
				mine = e
				if not new then return nil end
				table.insert(list, e)
				return {list = list}
			end)
		end)
		if ok and mine then
			if type(final) == "table" and type(final.list) == "table" then hall = final.list; sortHall() end
			hallMerge(mine)
			publishHall()
			return mine
		end
		task.wait(2 * attempt)
	end
	warn("Champion: could not save the hall number for " .. tostring(rec.name) .. " - the next server start mends it")
	return nil
end
-- on start: read the hall, then make sure every day winner of the last fortnight is in it (the first time, every day from
-- LaunchDay: that is how the Day winners from before the numbering got their numbers, in the order they won)
local function loadHall()
	if STUDIO or not store then publishHall(); hallLoaded = true; return end
	local got = false
	for attempt = 1, 5 do
		local ok, v = pcall(function() return store:GetAsync("hall") end)
		if ok then
			hall = (type(v) == "table" and type(v.list) == "table") and v.list or {}
			sortHall()
			got = true
			break
		end
		task.wait(2 * attempt)
	end
	if got then
		local launch = F:GetAttribute("LaunchDay") or 20721
		local from = (#hall == 0) and launch or math.max(launch, today() - 14)
		local added = 0
		for d = from, today() do
			local ok, rec = pcall(function() return store:GetAsync("day_" .. tostring(d)) end)
			if ok and type(rec) == "table" and rec.uid then
				rec.day = rec.day or d
				local known = false
				for _, x in ipairs(hall) do if x.uid == rec.uid and x.day == rec.day then known = true end end
				if not known and hallAppend(rec) then added += 1 end
			end
		end
		print(string.format("Champion: the hall has %d keepers (%d added from the day records)", #hall, added))
	end
	publishHall()
	hallLoaded = true
end
task.spawn(loadHall)
-- the title and the numbers the badge case shows, all from the hall (nothing new in the save)
local function applyTitle(player)
	local e = hallFind(player.UserId)
	if e then
		player:SetAttribute("ChampionNo", e.no)
		player:SetAttribute("ChampionDay", e.day)
		player:SetAttribute("ChampionTotal", tonumber(e.total) or 44)
		player:SetAttribute("ChampionWins", hallWins(player.UserId))
		player:SetAttribute("ChampionTitle", titleFor(e.no))
		giveBadge(player)
	elseif item(player, "champion_day") > 0 then                        -- a Keeper the hall has not got (the store was down)
		player:SetAttribute("ChampionTitle", "Grand Keeper of the Great Acorn")
		giveBadge(player)
	end
end

local celebrated = {}
local function celebrate(rec)
	if type(rec) ~= "table" or not rec.day or celebrated[rec.day] then return end
	celebrated[rec.day] = true
	hallMerge(rec)
	ev:FireAllClients("crowned", rec)
	task.spawn(buildStatue, rec)
end
local function crown(player)
	local day = today()
	local launch = F:GetAttribute("LaunchDay") or 20721
	if day < launch and not STUDIO then return end
	local t0 = os.clock()
	while not hallLoaded and os.clock() - t0 < 60 do task.wait(0.5) end
	local total = totalSquirrels()
	if hallHas(player.UserId, total) then                              -- a Keeper already, for this many squirrels
		local e = hallFind(player.UserId)
		ev:FireClient(player, "already", e and e.no or 0, total)
		return
	end
	local n = math.max(1, day - launch + 1)
	local rec = {day = day, n = n, uid = player.UserId, name = player.DisplayName, user = player.Name, t = os.time(), total = total}
	local won, holder = claim(rec)
	if not won then
		if holder and holder.name then ev:FireClient(player, "late", holder.name, holder.n, total) end
		return
	end
	local e = hallAppend(rec)
	rec.no = e and e.no or nil
	if item(player, "champion_day") <= 0 then setItem(player, "champion_day", n) end   -- (the first day won, kept as before)
	awardItems:Fire(player, "champion_wins", 1)                          -- the days won
	player:SetAttribute("ChampionNew", true)                            -- the badge case says "new badge" only for this
	applyTitle(player)
	local passport=game:GetService("ReplicatedStorage"):FindFirstChild("PassportActivity");if passport then passport:Fire(player,"keeper",{keeperNo=rec.no or 0}) end
	print(string.format("Champion: %s is the %s Grand Keeper (day %d)", player.Name, rec.no and ordinal(rec.no) or "?", day))
	saveLatest(rec)
	celebrate(rec)
	if not STUDIO then pcall(function() MS:PublishAsync(TOPIC, rec) end) end
end
if not STUDIO then
	pcall(function() MS:SubscribeAsync(TOPIC, function(msg) celebrate(msg.Data) end) end)
end

-- ---- watching every player's finds ----
local function watch(player)
	task.spawn(function()
		local t0 = os.clock()
		while player.Parent and not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 20 do task.wait(0.25) end
		task.wait(2)                                           -- the saved count lands just after SaveLoaded
		while player.Parent and not hallLoaded and os.clock() - t0 < 80 do task.wait(0.5) end
		if not player.Parent then return end
		applyTitle(player)
		local last = tonumber(player:GetAttribute("SquirrelsFound")) or 0
		player:GetAttributeChangedSignal("SquirrelsFound"):Connect(function()
			local now = tonumber(player:GetAttribute("SquirrelsFound")) or 0
			local total = totalSquirrels()
			if total > 0 and now >= total and last < total then task.spawn(crown, player) end
			last = now
		end)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

-- ---- on start: the newest Keeper (or the empty plinth), and the squirrel ----
task.spawn(function()
	local t0 = os.clock()
	while totalSquirrels() == 0 and os.clock() - t0 < 30 do task.wait(0.5) end
	buildSquirrel()
	while not hallLoaded and os.clock() - t0 < 90 do task.wait(0.5) end
	local latest = hall[#hall]
	if not latest and not STUDIO and store then                         -- (the hall could not be read: the last one saved)
		local ok, rec = pcall(function() return store:GetAsync("latest") end)
		if ok and type(rec) == "table" then latest = rec end
	end
	if latest and latest.day then celebrated[latest.day] = true end
	buildStatue(latest)
end)
-- for the Hall of Fame at the Chateau (its HallServer): the same statue and the same saluting squirrel, made where it asks
local mk = Instance.new("BindableFunction"); mk.Name = "MakeStatue"; mk.Parent = F
mk.OnInvoke = function(rec, o) return makeFigure(rec, o) end
local msq = Instance.new("BindableFunction"); msq.Name = "MakeSquirrel"; msq.Parent = F
msq.OnInvoke = function(o) return makeSquirrel(o) end
if STUDIO then
	-- (a hall full of Keepers to look at: HallDebug:Invoke({{uid = ..., name = ...}, ...}) adds them, a day apart)
	local hd = Instance.new("BindableFunction"); hd.Name = "HallDebug"; hd.Parent = F
	hd.OnInvoke = function(list)
		for _, e in ipairs(list) do
			local day = (hall[#hall] and hall[#hall].day or (today() - 20)) + 1
			hallAppend({uid = e.uid, name = e.name, user = e.name, day = day, t = os.time(), total = e.total or 44})
		end
		return #hall
	end
	local dbg = Instance.new("BindableFunction"); dbg.Name = "ChampionDebug"; dbg.Parent = F
	dbg.OnInvoke = function(player) crown(player); return player:GetAttribute("ChampionTitle") end
	-- (a statue of anyone, to check a body shape: StatueDebug:Invoke(userId, name) -> where the feet ended up)
	local sdbg = Instance.new("BindableFunction"); sdbg.Name = "StatueDebug"; sdbg.Parent = F
	sdbg.OnInvoke = function(uid, name)
		buildStatue({uid = uid, name = name or "Test", n = 0, day = 20721})
		local fig = F:FindFirstChild("Figure")
		if not fig then return "no figure" end
		local cf, size = fig:GetBoundingBox()
		return string.format("feet %.2f | plinth top %.2f | box bottom %.2f | height %.1f", lowestPoint(fig), TOP, cf.Position.Y - size.Y / 2, size.Y)
	end
end
print("Champion: ready")
]==]

	-- ---------------------------------------------------------------- client ----
	local CLIENT = [==[
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = RS:WaitForChild("ChampionEvent")
local C = Color3.fromRGB
local NAVY, GOLD, CREAM = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220)
local FONT = Enum.Font.FredokaOne
local function ordinal(n)
	n = math.floor(tonumber(n) or 0)
	local m100, m10, s = n % 100, n % 10, "th"
	if m100 < 11 or m100 > 13 then
		if m10 == 1 then s = "st" elseif m10 == 2 then s = "nd" elseif m10 == 3 then s = "rd" end
	end
	return tostring(n) .. s
end

-- ---- the announcement ----
local gui = Instance.new("ScreenGui"); gui.Name = "ChampionGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 17; gui.Parent = pg
local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0); card.Position = UDim2.new(0.5, 0, 0, -120); card.Size = UDim2.new(0.9, 0, 0, 78)
card.BackgroundColor3 = NAVY; card.BackgroundTransparency = 0.05; card.BorderSizePixel = 0; card.Visible = false; card.Parent = gui
local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(560, 78); lim.Parent = card
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 16); cc.Parent = card
local cs = Instance.new("UIStroke"); cs.Color = GOLD; cs.Thickness = 2.5; cs.Parent = card
local l1 = Instance.new("TextLabel"); l1.BackgroundTransparency = 1; l1.Position = UDim2.fromOffset(12, 8); l1.Size = UDim2.new(1, -24, 0, 32)
l1.Font = FONT; l1.TextScaled = true; l1.TextColor3 = GOLD; l1.Text = ""; l1.Parent = card
local l1c = Instance.new("UITextSizeConstraint"); l1c.MaxTextSize = 26; l1c.Parent = l1
local l2 = Instance.new("TextLabel"); l2.BackgroundTransparency = 1; l2.Position = UDim2.fromOffset(12, 42); l2.Size = UDim2.new(1, -24, 0, 26)
l2.Font = FONT; l2.TextScaled = true; l2.TextColor3 = CREAM; l2.Text = ""; l2.Parent = card
local l2c = Instance.new("UITextSizeConstraint"); l2c.MaxTextSize = 17; l2c.Parent = l2
local shownAt = 0
local function dailyCardUp()                          -- the daily acorns card is showing (nothing goes on top of it: Shannon)
	local dg = pg:FindFirstChild("DailyGui")
	local dc = dg and dg:FindFirstChild("DailyCard")
	return dc ~= nil and dc:IsA("GuiObject") and dc.Visible and dg.Enabled
end
local function titleBannerUp()                        -- the honours' "You are now a ..." banner (finding all 44 brings both at once)
	local hb = pg:FindFirstChild("HonourBar")
	local b = hb and hb:FindFirstChild("Banner")
	return b ~= nil and b:IsA("GuiObject") and b.Visible
end
local function announce(a, b, secs)
	task.spawn(function()
		local t1 = os.clock()
		task.wait(0.3)                                    -- (the honours banner, fired in the same moment, shows first)
		while (dailyCardUp() or titleBannerUp()) and os.clock() - t1 < 90 do task.wait(0.3) end
		l1.Text = a; l2.Text = b
		card.Visible = true
		local mine = os.clock(); shownAt = mine
		TweenService:Create(card, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 128)}):Play()
		task.delay(secs or 10, function()
			if shownAt ~= mine then return end
			local t = TweenService:Create(card, TweenInfo.new(0.5), {Position = UDim2.new(0.5, 0, 0, -120)}); t:Play()
			t.Completed:Connect(function() if shownAt == mine then card.Visible = false end end)
		end)
	end)
end
local function chat(text)
	pcall(function()
		local ch = game:GetService("TextChatService"):WaitForChild("TextChannels", 3):WaitForChild("RBXGeneral", 3)
		ch:DisplaySystemMessage(text)
	end)
end

-- ---- fireworks over all three maps (each screen fires its own; nothing is sent over the network) ----
local SITES = {{0, -60}, {-70, -140}, {70, -170}, {205, -50}, {315, -60}, {260, -170}, {430, -40}, {540, -140}, {650, -60}}
local COLOURS = {C(255, 60, 60), C(255, 150, 40), C(255, 230, 60), C(80, 230, 90), C(60, 220, 255), C(80, 120, 255), C(180, 90, 255), C(255, 90, 200)}
local function sound(id, parent, vol)
	if not id or id == "" then return end
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol; s.RollOffMaxDistance = 700; s.RollOffMinDistance = 40; s.Parent = parent; s:Play()
	Debris:AddItem(s, 6)
end
local function threeColours(first)
	local picks, used = {first}, {[first] = true}
	for _ = 1, 30 do
		if #picks >= 3 then break end
		local c = COLOURS[math.random(1, #COLOURS)]
		if not used[c] then used[c] = true; picks[#picks + 1] = c end
	end
	return picks
end
local function rocket(x, z)
	local colour = COLOURS[math.random(1, #COLOURS)]
	local topY = math.random(80, 120)
	-- a bright spark going up with only a short, faint wisp behind it (Shannon: "less of a tail traveling up")
	local r = Instance.new("Part"); r.Name = "Rocket"; r.Shape = Enum.PartType.Ball; r.Size = Vector3.new(0.45, 0.45, 0.45); r.Anchored = true; r.CanCollide = false; r.CanQuery = false
	r.CastShadow = false; r.Material = Enum.Material.Neon; r.Color = colour; r.CFrame = CFrame.new(x, 4, z); r.Parent = workspace
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.08, 0); a0.Parent = r
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.08, 0); a1.Parent = r
	local tr = Instance.new("Trail"); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 0.035; tr.LightEmission = 1; tr.FaceCamera = true
	tr.Color = ColorSequence.new(colour); tr.Transparency = NumberSequence.new(0.7, 1); tr.WidthScale = NumberSequence.new(1, 0); tr.Parent = r
	sound(F:GetAttribute("FireworkLaunch"), r, 0.5)
	local up = TweenService:Create(r, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(x + math.random(-6, 6), topY, z + math.random(-6, 6))})
	up:Play()
	up.Completed:Connect(function()
		local at = r.CFrame
		r.Transparency = 1
		local b = Instance.new("Part"); b.Anchored = true; b.CanCollide = false; b.CanQuery = false; b.Transparency = 1; b.Size = Vector3.new(1, 1, 1); b.CFrame = at; b.Parent = workspace
		local att = Instance.new("Attachment"); att.Parent = b
		-- three colours in every burst, big bright stars that read against a daytime sky, and a glitter of white
		local picks = threeColours(colour)
		picks[#picks + 1] = C(255, 250, 225)
		for k, col in ipairs(picks) do
			local white = k == #picks
			local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"; pe.LightEmission = 1; pe.LightInfluence = 0
			pe.Brightness = 2; pe.Color = ColorSequence.new(col); pe.Speed = NumberRange.new(white and 20 or 34, white and 30 or 52)
			pe.SpreadAngle = Vector2.new(180, 180); pe.Drag = 2.2; pe.Acceleration = Vector3.new(0, -9, 0); pe.Lifetime = NumberRange.new(1.6, 2.6)
			pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, white and 1.4 or 3.2), NumberSequenceKeypoint.new(0.6, white and 1 or 2.2), NumberSequenceKeypoint.new(1, 0)})
			pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.75, 0.15), NumberSequenceKeypoint.new(1, 1)})
			pe.Rate = 0; pe.Parent = att; pe:Emit(white and 20 or 34)
		end
		-- and a flash of the main colour as it goes
		local ball = Instance.new("Part"); ball.Shape = Enum.PartType.Ball; ball.Material = Enum.Material.Neon; ball.Color = colour; ball.CastShadow = false
		ball.Anchored = true; ball.CanCollide = false; ball.CanQuery = false; ball.CanTouch = false; ball.Size = Vector3.new(2, 2, 2); ball.Transparency = 0.2; ball.CFrame = at; ball.Parent = workspace
		TweenService:Create(ball, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(14, 14, 14), Transparency = 1}):Play()
		Debris:AddItem(ball, 0.6)
		local light = Instance.new("PointLight"); light.Color = colour; light.Brightness = 6; light.Range = 60; light.Parent = b
		TweenService:Create(light, TweenInfo.new(0.5), {Brightness = 0}):Play()
		sound(F:GetAttribute("FireworkPop"), b, 0.8)
		Debris:AddItem(b, 3); Debris:AddItem(r, 0.7)
	end)
end
local showing = false
local function fireworks(secs)
	if showing then return end
	showing = true
	local id = F:GetAttribute("FireworkShow")
	if id and id ~= "" then
		local s = Instance.new("Sound"); s.Name = "FireworkShow"; s.SoundId = id; s.Looped = true; s.Volume = F:GetAttribute("FireworkVolume") or 0.6
		s.Parent = game:GetService("SoundService"); s:Play()
		task.delay(secs + 1, function()
			local t = TweenService:Create(s, TweenInfo.new(2), {Volume = 0}); t:Play()
			t.Completed:Connect(function() s:Destroy() end)
		end)
	end
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < secs do
			-- most of the show goes up over whichever map this screen is looking at; now and then one over a far map
			local cam = workspace.CurrentCamera
			local here = cam and cam.CFrame.Position or Vector3.zero
			local order = {}
			for k, st in ipairs(SITES) do order[k] = {s = st, d = (Vector2.new(st[1], st[2]) - Vector2.new(here.X, here.Z)).Magnitude} end
			table.sort(order, function(a, b) return a.d < b.d end)
			for k, chance in ipairs({1, 0.8, 0.55}) do
				if math.random() < chance then local st = order[k].s; rocket(st[1] + math.random(-18, 18), st[2] + math.random(-18, 18)) end
			end
			if math.random() < 0.25 then local st = order[math.random(4, #order)].s; rocket(st[1] + math.random(-15, 15), st[2] + math.random(-15, 15)) end
			task.wait(0.35 + math.random() * 0.2)
		end
		showing = false
	end)
end

-- the Keepers are numbered in the order they won (Shannon, Sep 26): "the 3rd Grand Keeper", not "Day 3"
ev.OnClientEvent:Connect(function(what, a, b, c)
	if what == "crowned" and type(a) == "table" then
		local all = tonumber(a.total) or 44
		local who = a.no and ("the " .. ordinal(a.no) .. " Grand Keeper") or "today's Grand Keeper"
		if a.uid == player.UserId then
			announce("You are " .. who .. "!", "Of the Great Acorn - your statue stands by the fountain")
		else
			announce(tostring(a.name) .. " is " .. who .. "!", "First to find all " .. all .. " squirrels today")
		end
		chat(string.format("%s found all %d squirrels first today and is %s of the Great Acorn! Their statue now stands by the fountain.", tostring(a.name), all, who))
		fireworks(F:GetAttribute("FireworkSeconds") or 25)
	elseif what == "late" then
		-- SAY IT PLAINLY (Shannon, Sep 26, finishing second: "it said I got all 44 and I am the grand keeper, but no fireworks"):
		-- today's statue is someone else's, and when the next chance comes (the day turns at the daily gift's DayOffsetHours UTC)
		local daily = workspace:FindFirstChild("Daily")
		local off = (daily and daily:GetAttribute("DayOffsetHours")) or 9
		local now = workspace:GetServerTimeNow()
		local nextAt = (math.floor((now - off * 3600) / 86400) + 1) * 86400 + off * 3600
		local left = math.max(0, nextAt - now)
		local h, m = math.floor(left / 3600), math.floor(left % 3600 / 60)
		local untilNext = (h > 0) and string.format("%dh %dm", h, m) or string.format("%d minutes", math.max(1, m))
		announce("Today's statue is already " .. tostring(a) .. "'s", "Next chance in " .. untilNext .. " - be the first to find all " .. (tonumber(c) or 44) .. " after the daily reset!", 14)
		chat(string.format("Today's Grand Keeper statue went to %s. The next one goes to whoever finds all %d squirrels first after the daily reset - in %s.", tostring(a), tonumber(c) or 44, untilNext))
	elseif what == "already" then
		announce("All " .. (tonumber(b) or 44) .. " found again!", "You're already the " .. ordinal(a) .. " Grand Keeper. New squirrels mean a new race!")
	end
end)
]==]
	local s = Instance.new("Script"); s.Name = "ChampionServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
	local c = Instance.new("Script"); c.Name = "ChampionClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
	F.Parent = workspace

	-- ---------------------------------------------------------------- the honours learn about the champion ----
	local patched = "no TitleServer"
	local honours = workspace:FindFirstChild("Honours")
	local ts = honours and honours:FindFirstChild("TitleServer")
	if ts then
		local src = ts.Source
		if src:find("ChampionTitle", 1, true) then
			patched = "already"
		else
			local function rep(a, b2)
				local i, j = src:find(a, 1, true)
				if not i then return false end
				src = src:sub(1, i - 1) .. b2 .. src:sub(j + 1)
				return true
			end
			local r1 = rep('gui.Title.Text = tier > 0 and TIERS[tier].title or ""',
				'local champ = player:GetAttribute("ChampionTitle"); if champ == "" then champ = nil end; gui.Size = UDim2.new(0, champ and 380 or 260, 0, 64); gui.Title.Text = champ or (tier > 0 and TIERS[tier].title or "")')
			local r2 = rep('gui.Title.TextColor3 = tier > 0 and TIERS[tier].colour or C(255, 222, 110)',
				'gui.Title.TextColor3 = champ and C(255, 214, 60) or (tier > 0 and TIERS[tier].colour or C(255, 222, 110))')
			local r3 = rep('player:SetAttribute("HonourTitle", tier > 0 and TIERS[tier].title or "")',
				'local champT = player:GetAttribute("ChampionTitle"); player:SetAttribute("HonourTitle", (champT and champT ~= "") and champT or (tier > 0 and TIERS[tier].title or ""))')
			local r4 = rep('task.delay(1, function() if player.Parent then update(player, false) end end)',
				'player:GetAttributeChangedSignal("ChampionTitle"):Connect(function() update(player, false) end); task.delay(1, function() if player.Parent then update(player, false) end end)')
			if r1 and r2 and r3 and r4 then ts.Source = src; patched = "patched" else patched = string.format("LINES NOT FOUND %s/%s/%s/%s", tostring(r1), tostring(r2), tostring(r3), tostring(r4)) end
		end
	end
	print(string.format("Champion: installed - plinth at (%.0f,%.1f,%.0f), day 1 = %d, acorn template %s, honours %s", PX, g, PZ, F:GetAttribute("LaunchDay"), tostring(acornOk), patched))
	return F
end
