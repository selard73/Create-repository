-- welcome1 (Oct 22 2026): keep new players past their first minute, help stuck ones, and tidy the boards. Shannon: "out of
-- everyone who enters the game, less than half stay to get a first squirrel ... why are more than 50% leaving before
-- playing?" -> "please make all of the changes you suggested" + "did we want to move the 2nd question of the day board, maybe
-- to the chateau area someplace? It does feel a bit classroom" + "the chickens need little dots for eyes".
--   WelcomeClient (new, workspace.Welcome): a newcomer's nearest forest squirrel glows, sparkles and calls them over.
--   HintServer / HintClient: a FREE hint when stuck (75 s without a first squirrel, 180 s since the last find), one per
--     area per visit; the Hint button glows and says "Free hint!".
--   DailyClient: a newcomer's daily card waits for their first squirrel and says "Your first daily acorns!", never
--     "Welcome back" to someone new. QuestionClient: the question reminder waits for a first squirrel too.
--   Question board #2 moves from La Poste to the chateau's arrival lawn (opens with the chateau: 10 Rue squirrels);
--     QuestionClient's reminder and the Passport's row follow ("Chateau question").
--   The five hens get little black dot eyes.
-- Run in Studio EDIT. Backs every patched script up to ServerStorage.HudBackup (<name>_pre_welcome1) first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
assert(not workspace:FindFirstChild("Welcome"), "workspace.Welcome already exists - nothing changed")
--@@EDITS_BEGIN
local EDITS = {
	HintServer = {workspace.HintShop.HintServer, {
		{[==[req.OnServerEvent:Connect(function(player)
	local productId = H:GetAttribute("HintProductId") or 0
	if (player:GetAttribute("HintUntil") or 0) > os.time() then status:FireClient(player, "A hint is already running. Follow the sparkles!"); return end]==],
		 [==[-- (welcome1, Oct 22 2026) a FREE hint for a stuck player - only paid hints existed, so a player who could not find the
-- next squirrel could only leave. After FirstStuck seconds (75) without a first squirrel, or Stuck seconds (180) since the
-- last find, the next hint is free: player attribute FreeHintReady = the area (HintClient makes the button glow). One free
-- hint per area per visit; after that the paid hint as before. Nothing saved.
local lastFind, freeUsed = {}, {}
local function watchStuck(player)
	freeUsed[player] = {}
	task.spawn(function()
		local t0 = os.clock()
		while player.Parent and not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 120 do task.wait(0.5) end
		lastFind[player] = os.clock()
		player:GetAttributeChangedSignal("FoundIds"):Connect(function()
			lastFind[player] = os.clock()
			if player:GetAttribute("FreeHintReady") then player:SetAttribute("FreeHintReady", nil) end
		end)
	end)
end
Players.PlayerAdded:Connect(watchStuck)
for _, p in ipairs(Players:GetPlayers()) do watchStuck(p) end
Players.PlayerRemoving:Connect(function(p) lastFind[p] = nil; freeUsed[p] = nil end)
task.spawn(function()
	while true do
		task.wait(5)
		for _, p in ipairs(Players:GetPlayers()) do
			local since = lastFind[p]
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if since and root and freeUsed[p] and not p:GetAttribute("FreeHintReady") and (p:GetAttribute("HintUntil") or 0) <= os.time() then
				local zone = zoneOf(root.Position)
				local waitFor = ((tonumber(p:GetAttribute("SquirrelsFound")) or 0) == 0) and (H:GetAttribute("FirstStuck") or 75) or (H:GetAttribute("Stuck") or 180)
				if not freeUsed[p][zone] and os.clock() - since >= waitFor and pick(p) then p:SetAttribute("FreeHintReady", zone) end
			end
		end
	end
end)
req.OnServerEvent:Connect(function(player)
	local productId = H:GetAttribute("HintProductId") or 0
	if (player:GetAttribute("HintUntil") or 0) > os.time() then status:FireClient(player, "A hint is already running. Follow the sparkles!"); return end
	local free = player:GetAttribute("FreeHintReady")
	if free then                                                  -- (welcome1) the stuck player's free hint
		if grant(player) then freeUsed[player] = freeUsed[player] or {}; freeUsed[player][free] = true; lastFind[player] = os.clock() end
		player:SetAttribute("FreeHintReady", nil)
		return
	end]==], "the hint request"},
	}},
	HintClient = {workspace.HintShop.HintClient, {
		{[==[local bs = Instance.new("UIStroke"); bs.Color = C(240, 200, 90); bs.Thickness = 2; bs.Parent = btn]==],
		 [==[local bs = Instance.new("UIStroke"); bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; bs.Color = C(240, 200, 90); bs.Thickness = 2; bs.Parent = btn   -- (welcome1: Border - the Contextual default blurred the letters)]==], "the button's stroke"},
		{[==[local function baseLabel() return "Hint" end]==],
		 [==[local function baseLabel() return player:GetAttribute("FreeHintReady") and "Free hint!" or "Hint" end   -- (welcome1)]==], "the button label"},
		{[==[	fetchPrice()
	if id > 0 then]==],
		 [==[	fetchPrice()
	if player:GetAttribute("FreeHintReady") then                  -- (welcome1) the stuck player's free hint
		priceRow.Text = "Free!"; buy.Text = "Get free hint"; buy.BackgroundColor3 = C(70, 150, 90)
		shade.Visible = true
		return
	end
	if id > 0 then]==], "the modal's price"},
		{[==[btn.Activated:Connect(function()]==],
		 [==[-- (welcome1, Oct 22 2026) a free hint is waiting (HintServer's FreeHintReady): the button turns gold and says so (no
-- pulsing glow - Shannon: "that glow on FREE HINT is not good"), with one note
local function freeLook()
	local ready = player:GetAttribute("FreeHintReady") ~= nil
	btn.Text = baseLabel()
	btn.BackgroundColor3 = ready and C(240, 200, 90) or C(38, 30, 52)
	btn.TextColor3 = ready and C(84, 48, 18) or C(255, 246, 220)
	if ready then say("Stuck? Your next hint is free!", 5) end
end
player:GetAttributeChangedSignal("FreeHintReady"):Connect(freeLook)
freeLook()
btn.Activated:Connect(function()]==], "the button press"},
	}},
	DailyClient = {workspace.Daily.DailyClient, {
		{[==[local function showCard(state)
	sub.Text = state.streak > 1 and string.format("Day %d in a row", state.streak) or "Welcome back"]==],
		 [==[-- (welcome1, Oct 22 2026) a first-time player's card waits for their first squirrel, and never says "Welcome back" to
-- someone who has never been here (Shannon: "I did not know everyone gets a welcome back note upon their first visit")
local newcomer
task.spawn(function()
	local t0 = os.clock()
	while not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 60 do task.wait(0.25) end
	newcomer = (tonumber(player:GetAttribute("SquirrelsFound")) or 0) == 0
end)
local function afterFirstFind(fn)                                   -- fn now, or a few seconds after a newcomer's first squirrel
	task.spawn(function()
		local t0 = os.clock()
		while newcomer == nil and os.clock() - t0 < 60 do task.wait(0.25) end
		if newcomer and (tonumber(player:GetAttribute("SquirrelsFound")) or 0) == 0 then
			while (tonumber(player:GetAttribute("SquirrelsFound")) or 0) == 0 do player:GetAttributeChangedSignal("SquirrelsFound"):Wait() end
			task.wait(6)
			local t1 = os.clock()
			while pg:GetAttribute("OpenPanel") and os.clock() - t1 < 60 do task.wait(0.5) end   -- (after the gifts card, if it is up)
		end
		fn()
	end)
end
local function showCard(state)
	sub.Text = state.streak > 1 and string.format("Day %d in a row", state.streak) or (newcomer and "Your first daily acorns!" or "Welcome back")   -- (welcome1)]==], "the card's greeting"},
		{[==[		if a.claimable and not shown then showCard(a) end]==],
		 [==[		if a.claimable and not shown then afterFirstFind(function() if not shown then showCard(a) end end) end   -- (welcome1)]==], "the card's timing"},
	}},
	QuestionClient = {workspace.DailyQuestion.QuestionClient, {
		{[==[if os.clock()-joinedAt<8 or not player:GetAttribute("SaveLoaded")then return true end]==],
		 [==[if os.clock()-joinedAt<8 or not player:GetAttribute("SaveLoaded")then return true end
 if (tonumber(player:GetAttribute("SquirrelsFound"))or 0)<1 then return true end -- (welcome1) not before a first squirrel]==], "the reminder's wait"},
		{[==[(player:GetAttribute("Found_forest")or 0)>=need and latestStatus.poste=="open"]==],
		 [==[(player:GetAttribute("Found_village")or 0)>=need and latestStatus.poste=="open"]==], "board #2's unlock (welcome1: the chateau)"},
		{[==["A second question awaits at La Poste! Open Passport → Clues or visit the board."]==],
		 [==["A second question awaits at the château! Open Passport → Clues or visit the board."]==], "board #2's reminder"},
	}},
	PassportClient = {workspace.Passport.PassportClient, {
		{[==[if (p:GetAttribute("Found_forest")or 0)>=need then questionRow("poste","La Poste question")end]==],
		 [==[if (p:GetAttribute("Found_village")or 0)>=need then questionRow("poste","Château question")end -- (welcome1) board #2 at the chateau]==], "board #2's row"},
	}},
}
local function patched(script, edits)
	local src = script.Source
	assert(not src:find("(welcome1", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	return src
end
-- board #2 to the chateau's arrival lawn, its front to the arrival pad
local function moveBoard()
	local board = workspace.DailyQuestion.Board_poste
	if board:GetAttribute("WasPivot") == nil then board:SetAttribute("WasPivot", board:GetPivot()) end
	local pad = workspace.Spawn_domaine.Position
	local spot = Vector3.new(429.5, 0, -12.5)                           -- (Shannon's circle: "here by the monument thingy")
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {board}
	local g = workspace:Raycast(spot + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0), params)
	local piv = board:GetPivot()
	-- the way its writing faces (the Face part's SurfaceGui side), turned about the vertical to face the pad; its lean kept
	local face = board:FindFirstChild("Face", true)
	local sg = face and face:FindFirstChildWhichIsA("SurfaceGui", true)
	local n = face.CFrame:VectorToWorldSpace(Vector3.FromNormalId(sg and sg.Face or Enum.NormalId.Front)) * Vector3.new(1, 0, 1)
	local d = (Vector3.new(pad.X, 0, pad.Z) - Vector3.new(spot.X, 0, spot.Z))
	local turn = math.atan2(d.X, d.Z) - math.atan2(n.X, n.Z)
	local cf, size = board:GetBoundingBox()
	local lift = piv.Position.Y - (cf.Position.Y - size.Y / 2)
	board:PivotTo(CFrame.new(spot.X, (g and g.Position.Y or 2) + lift, spot.Z) * CFrame.Angles(0, turn, 0) * piv.Rotation)
	return board:GetPivot().Position
end
-- little black dot eyes for the hens: just behind the beak's base, either side of the head, in WORLD axes (the beak's own
-- axes are tilted - the first try put them 2 studs above the head); inside each hen model, so they move with it
local function eyes()
	local n = 0
	for _, h in ipairs(workspace.Domaine.Props:GetChildren()) do
		local body, beak = h:IsA("Model") and h.Name == "hen" and h:FindFirstChild("Hen"), h:IsA("Model") and h:FindFirstChild("Beak")
		if body and beak and not h:FindFirstChild("EyeL") then
			local fwd = (beak.Position - body.Position) * Vector3.new(1, 0, 1)
			fwd = fwd.Magnitude > 0.01 and fwd.Unit or body.CFrame.LookVector
			local right = fwd:Cross(Vector3.yAxis).Unit
			local base = beak.Position - fwd * 0.22 + Vector3.new(0, 0.1, 0)
			for _, side in ipairs({{"EyeL", -1}, {"EyeR", 1}}) do
				local e = Instance.new("Part"); e.Name = side[1]; e.Shape = Enum.PartType.Ball; e.Size = Vector3.new(0.11, 0.11, 0.11)
				e.Color = Color3.fromRGB(25, 20, 18); e.Material = Enum.Material.SmoothPlastic; e.Anchored = true
				e.CanCollide = false; e.CanQuery = false; e.CanTouch = false; e.CastShadow = false
				e.CFrame = CFrame.new(base + right * (side[2] * 0.17))
				e.Parent = h
			end
			n += 1
		end
	end
	return n
end
--@@EDITS_END
local sources = {}
for name, pair in pairs(EDITS) do sources[name] = patched(pair[1], pair[2]) end
for name, pair in pairs(EDITS) do
	local b = pair[1]:Clone(); b.Name = pair[1].Name .. "_pre_welcome1"; b.Enabled = false; b.Parent = backup
end
for name, pair in pairs(EDITS) do SES:UpdateSourceAsync(pair[1], function() return sources[name] end) end
local folder = Instance.new("Folder"); folder.Name = "Welcome"; folder.Parent = workspace
local wc = Instance.new("Script"); wc.Name = "WelcomeClient"; wc.RunContext = Enum.RunContext.Client; wc.Parent = folder
SES:UpdateSourceAsync(wc, function() return [==[
-- WelcomeClient (workspace.Welcome, RunContext Client; welcome1, Oct 22 2026): a brand-new player's first minute. Shannon:
-- "out of everyone who enters the game, less than half stay to get a first squirrel ... why are more than 50% leaving before
-- playing?" Nothing told a newcomer what to do, and the nearest squirrel was a small grey shape ~50 studs away among grey
-- rocks. Now, for a player who has found NO squirrel yet: the nearest unfound forest squirrel gets a gold outline (seen
-- through the trees) and sparkles, and calls out through SquirrelBubble ("Psst! Over here! ... Click on me!") until found; then
-- the squirrel that was found says how many are left. Anyone with a find already never sees any of it. Nothing is saved.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer
local Bubble = require(RS:WaitForChild("SquirrelBubble"))
local GOLD = Color3.fromRGB(255, 214, 90)
local CALLS = {
	"Psst! Over here! We're hiding all over France. Can you find all 44 of us? Click on me!",   -- (Shannon: "click on me. not tap me")
	"Over here! Click on me!",
	"Still here! Come and find me!",
	"Psst! Over here!",
}
local GIVE_UP = 180                                                      -- (then the free hint takes over)
local function finds() return tonumber(player:GetAttribute("SquirrelsFound")) or 0 end
local t0 = os.clock()
while not player:GetAttribute("SaveLoaded") and os.clock() - t0 < 60 do task.wait(0.25) end
if not player:GetAttribute("SaveLoaded") or finds() > 0 then return end
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart", 20)
task.wait(2)                                                            -- (the spawn settles, the forest streams in)
if not root or finds() > 0 or player:GetAttribute("Area") ~= "forest" then return end
local function idOf(m) return m:GetAttribute("SquirrelId") or (m.Name:lower():gsub("_color$", "")) end
local function inForest(pos) return pos.X < 150 and pos.Z > -300 end    -- (SpawnReturn's area lines)
local function nearest()
	local best, bd
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		if m:IsA("Model") and m:IsDescendantOf(workspace) and not m.Name:lower():find("gray") then
			local ok, cf = pcall(function() return m:GetBoundingBox() end)
			if ok and inForest(cf.Position) then
				local d = (cf.Position - root.Position).Magnitude
				if not bd or d < bd then best, bd = m, d end
			end
		end
	end
	return best
end
local target = nearest()
if not target then return end
local hl = Instance.new("Highlight"); hl.Name = "WelcomeGlow"; hl.FillTransparency = 1; hl.OutlineColor = GOLD
hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = target; hl.Parent = target
local body = target:FindFirstChildWhichIsA("BasePart", true)
local att, fx
if body then
	att = Instance.new("Attachment"); att.Name = "WelcomeSparkles"; att.Position = Vector3.new(0, 1.2, 0); att.Parent = body
	fx = Instance.new("ParticleEmitter"); fx.Color = ColorSequence.new(GOLD); fx.LightEmission = 1; fx.Rate = 8
	fx.Lifetime = NumberRange.new(0.9, 1.5); fx.Speed = NumberRange.new(1.5, 3); fx.SpreadAngle = Vector2.new(180, 180)
	fx.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0)})
	fx.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1)}); fx.Parent = att
end
local done = false
local function stop()
	done = true
	if hl then hl:Destroy(); hl = nil end
	if att then att:Destroy(); att = nil end
	for _, d in ipairs(target:GetDescendants()) do                    -- (nothing of ours left behind, whatever happened)
		if d.Name == "WelcomeGlow" or d.Name == "WelcomeSparkles" then d:Destroy() end
	end
end
task.spawn(function()
	local i, start = 1, os.clock()
	while not done and finds() == 0 and os.clock() - start < GIVE_UP and target.Parent do
		Bubble.say(target, CALLS[i], {secs = (i == 1) and 7 or 4})
		i = (i % #CALLS) + 1
		if i == 1 then i = 2 end                                        -- (the long line only the first time)
		task.wait(12)
	end
	if not done and finds() == 0 then stop() end
end)
-- the first find: the squirrel that was found says how many are left
local con
con = player:GetAttributeChangedSignal("SquirrelsFound"):Connect(function()
	if finds() < 1 then return end
	con:Disconnect()
	stop()
	local ids = {}
	for id in tostring(player:GetAttribute("FoundIds") or ""):gmatch("[^,]+") do ids[id] = true end
	local speaker = target
	for _, m in ipairs(CollectionService:GetTagged("Squirrel")) do
		if m:IsA("Model") and not m.Name:lower():find("gray") and ids[idOf(m)] then speaker = m break end
	end
	local forestLeft = 15 - (tonumber(player:GetAttribute("Found_forest")) or 1)
	task.wait(3.5)                                                      -- (after the find's own reveal)
	if speaker and speaker.Parent then
		Bubble.say(speaker, string.format("You found me! %d more of us are hiding in France - %d right here in the forest.", 44 - finds(), forestLeft), {secs = 6})
	end
end)
]==] end)
local at = moveBoard()
local n = eyes()
print(string.format("welcome1: 5 scripts patched, WelcomeClient %d chars, board #2 at %.0f,%.0f,%.0f, %d hens got eyes", #wc.Source, at.X, at.Y, at.Z, n))
return "welcome1 installed"
