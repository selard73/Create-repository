-- install_treehouse3.lua (Studio EDIT; re-runnable; its body also runs as a play-test PREVIEW - discarded on stop).
-- Job 112: the HOMEBASE TREEHOUSE MOVES to Shannon's spot (-107, 4), a bigger room, no trunk inside. The old hollow is put back
-- (folder to HudBackup, pines back, the wall re-joined, the dirt re-grassed; the dell's terrain stays). At the new site the forest props
-- within 26 studs go to HudBackup.TreehouseCleared_n; a disk of Ground round the oak; the oak BEHIND the house; ten stones;
-- TreehouseServer (4806) + TreehouseClient3 (34887); twelve pieces unchanged. Log HudBackup.Treehouse3_log. No DataStore, no publish. Output "QQ TREE".
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local T = workspace.Terrain
local SERVER = [===[
-- TreehouseServer (workspace.Treehouse, RunContext Server). Job 103 (Shannon, Oct 15 2026: "finding parts and building a treehouse
-- in the forest ... strew the pieces throughout the french map, and have a count somewhere to show how many more they need, and they
-- can piece it together as they collect the pieces"). The pieces and the half-built house are PER PLAYER (each builds their own, drawn
-- by TreehouseClient on their own screen); this script is the only authority: it hands out a piece once, checks the player really
-- stands by it, keeps it on the save as Item_tree_<id> through the game's AwardItems ledger (no new store), and pays the builder's
-- 100 acorns once (Item_tree_done) through AwardAcorns + the Acorns attribute, the way the thank-you gifts do. Never touches a
-- DataStore. Attributes it sets on the player: TreePieces (how many so far; the dashboards can read it).
-- Pieces: the folder's attribute Pieces (JSON: [{id, x, y, z, kind}], written by the installer).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local F = script.Parent
local REACH = 14                                    -- studs from the piece a pick-up is honoured within (the prompt shows at 10; the root sits ~3 up)
local PRIZE = 100
local ev = RS:WaitForChild("TreehousePick", 60)
local awardItems = RS:WaitForChild("AwardItems", 60)
local awardAcorns = RS:WaitForChild("AwardAcorns", 60)
if not (ev and awardItems and awardAcorns) then warn("Treehouse: ReplicatedStorage is missing TreehousePick / AwardItems / AwardAcorns; the treehouse is off") return end
local pieces, byId = {}, {}
do
	local ok, t = pcall(function() return HttpService:JSONDecode(F:GetAttribute("Pieces") or "[]") end)
	if ok and type(t) == "table" then pieces = t end
	for _, p in ipairs(pieces) do if type(p) == "table" and p.id then byId[p.id] = p end end
end
local TOTAL = #pieces
if TOTAL == 0 then warn("Treehouse: no pieces in the Pieces attribute; the treehouse is off") return end
local got = {}                                      -- got[player][id] = true, this session (the attribute follows at once, this is belt and braces)
local last = {}                                     -- last[player] = os.clock() of the last honoured pick
local function has(p, id) return (got[p] and got[p][id]) or (tonumber(p:GetAttribute("Item_tree_" .. id)) or 0) >= 1 end
local function count(p)
	local n = 0
	for _, pc in ipairs(pieces) do if has(p, pc.id) then n += 1 end end
	return n
end
local function refresh(p)
	local n = count(p)
	if p:GetAttribute("TreePieces") ~= n then p:SetAttribute("TreePieces", n) end
	return n
end
local function pay(p)
	if (tonumber(p:GetAttribute("Item_tree_done")) or 0) >= 1 or (got[p] and got[p].done) then return false end
	got[p] = got[p] or {}; got[p].done = true
	awardItems:Fire(p, "tree_done", 1)
	awardAcorns:Fire(p, PRIZE)
	p:SetAttribute("Acorns", (tonumber(p:GetAttribute("Acorns")) or 0) + PRIZE)
	return true
end
ev.OnServerEvent:Connect(function(p, what, id)
	if what ~= "pick" or type(id) ~= "string" then return end
	local pc = byId[id]
	if not pc then return end
	if p:GetAttribute("SaveLoaded") ~= true then ev:FireClient(p, "wait") return end
	if has(p, id) then ev:FireClient(p, "got", id, refresh(p)) return end        -- (already theirs: the client just tidies up)
	local now = os.clock()
	if last[p] and now - last[p] < 1.5 then return end                           -- (the nearest two pieces are 23 studs apart: no honest player picks two within 1.5 s)
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local d = (root.Position - Vector3.new(tonumber(pc.x) or 0, tonumber(pc.y) or 0, tonumber(pc.z) or 0)).Magnitude
	if d > REACH then return end                                                -- (not there: a stale prompt or a hacked client; nothing happens)
	last[p] = now
	got[p] = got[p] or {}; got[p][id] = true
	awardItems:Fire(p, "tree_" .. id, 1)
	local n = refresh(p)
	ev:FireClient(p, "got", id, n)
	if n >= TOTAL and pay(p) then ev:FireClient(p, "done", PRIZE, n) end
end)
local function join(p)
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent and p:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end
		if not p.Parent then return end
		local n = refresh(p)
		if n >= TOTAL and pay(p) then ev:FireClient(p, "done", PRIZE, n) end        -- (all twelve on the save but never paid: paid now)
	end)
end
Players.PlayerAdded:Connect(join)
for _, p in ipairs(Players:GetPlayers()) do join(p) end
Players.PlayerRemoving:Connect(function(p) got[p] = nil; last[p] = nil end)
print(string.format("Treehouse: %d pieces, %d acorns for the builder", TOTAL, PRIZE))
]===]
local CLIENT = [===[
-- TreehouseClient v2 (workspace.Treehouse, RunContext Client). Jobs 103 + 111: the HOMEBASE TREEHOUSE in its hollow by the zip line tower. Everything here is drawn on THIS screen
-- only: the pieces this player has not found yet (a bundle with a "Treehouse piece / Pick up" prompt, Style Custom so the game's own
-- PromptClient draws it), the house growing on the oak with every piece (ladder, deck, railing, walls, roof, window, lantern, flag),
-- the sign at the foot with the count, a toast at every pick-up, a pill under the purse on desktop ("Treehouse: 3 of 12 pieces";
-- phones have no room in the HUD column, the sign and the toasts carry the count there) and the "Treehouse built!" card. The server
-- (TreehouseServer) decides what is theirs: a pick-up is a request; the piece goes when the server says "got" and Item_tree_<id>
-- arrives on the player. The oak itself (trunk, branches, canopy) is shared and built by the installer; the ladder and the deck are
-- local parts, so a player stands on their own deck (other players see them up in the tree without it - as the belvedere does).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local F = script.Parent
local ev = RS:WaitForChild("TreehousePick", 60)
if not ev then return end
local C = Color3.fromRGB
local NAVY, GOLD, CREAM = C(38, 30, 52), C(240, 200, 90), C(255, 246, 220)
local WOOD, WOOD_DARK, ROPE, ROOF = C(150, 108, 62), C(104, 70, 40), C(214, 186, 128), C(92, 58, 40)
local FONT = Enum.Font.FredokaOne
local function J(name, default)
	local ok, t = pcall(function() return HttpService:JSONDecode(F:GetAttribute(name) or "") end)
	return (ok and type(t) == "table") and t or default
end
local TREE = J("Tree", nil)
if not (TREE and tonumber(TREE.x) and tonumber(TREE.y) and tonumber(TREE.z)) then return end   -- (no oak written: nothing to draw)
local PIECES = J("Pieces", {})
local TOTAL = #PIECES
if TOTAL == 0 then return end
local FAR = 0
for _, p in ipairs(PIECES) do if p.far then FAR += 1 end end
-- pieces needed for each stage, scaled to the pieces that were actually placed (12: 1/3/5/7/9/10/11/12; 11: 1/3/5/6/8/9/10/11) so a
-- skipped spot can never hide the flag
local STAGES = {ladder = 1, deck = math.max(2, math.round(TOTAL * 0.25)), railing = math.max(3, math.round(TOTAL * 0.42)), walls = math.max(4, math.round(TOTAL * 0.58)),
	roof = math.max(5, math.round(TOTAL * 0.75)), window = math.max(6, TOTAL - 2), lantern = math.max(7, TOTAL - 1), flag = math.max(8, TOTAL)}
local NAME = "Homebase Treehouse"
local REVEAL_LINE = "A squirrel was going to live here, but you got the first piece, so it's yours now. The squirrel won't mind."
local isPhone = UIS.TouchEnabled and not UIS.KeyboardEnabled
local base = CFrame.new(TREE.x, TREE.y, TREE.z) * CFrame.Angles(0, math.rad(tonumber(TREE.yaw) or 0), 0)   -- +z faces the spawn
local folder = workspace:FindFirstChild("Treehouse_local") or Instance.new("Folder")
folder.Name = "Treehouse_local"; folder:ClearAllChildren(); folder.Parent = workspace
local piecesF = Instance.new("Folder"); piecesF.Name = "Pieces"; piecesF.Parent = folder
local houseF = Instance.new("Folder"); houseF.Name = "House"; houseF.Parent = folder
local function part(size, color, cf, parent, material, collide)
	local p = Instance.new("Part"); p.Size = size; p.Color = color; p.Material = material or Enum.Material.Wood
	p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = cf; p.Parent = parent
	return p
end
local gotLocal = {}
local function has(id) return gotLocal[id] or (tonumber(player:GetAttribute("Item_tree_" .. id)) or 0) >= 1 end
local function count()
	local n = 0
	for _, p in ipairs(PIECES) do if has(p.id) then n += 1 end end
	return n
end
local function inFrance() local a = player:GetAttribute("Area"); return a == "forest" or a == "village" or a == "domaine" end

-- ---------- the pieces ----------
local pieceModels = {}
local pending = {}
local function bundle(kind, cf, parent)
	-- a little heap a player can spot: planks tied with rope, or a coil of rope, a stack of shingles, a lantern in its crate
	local main
	if kind == "rope" then
		main = part(Vector3.new(0.5, 1.8, 1.8), ROPE, cf * CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.rad(90)), parent, Enum.Material.Fabric); main.Shape = Enum.PartType.Cylinder   -- (a Cylinder's axis is X; turned upright its 0.5 is the height)
		local top = part(Vector3.new(0.4, 1.3, 1.3), C(190, 160, 104), cf * CFrame.new(0.1, 0.7, 0.1) * CFrame.Angles(0, 0, math.rad(90)), parent, Enum.Material.Fabric); top.Shape = Enum.PartType.Cylinder
	elseif kind == "shingles" then
		main = part(Vector3.new(2.0, 0.22, 1.4), ROOF, cf * CFrame.new(0, 0.11, 0), parent)
		for i = 1, 3 do part(Vector3.new(2.0, 0.22, 1.4), (i % 2 == 0) and WOOD_DARK or ROOF, cf * CFrame.new((i % 2 == 0) and 0.15 or -0.1, 0.11 + i * 0.22, (i == 3) and 0.1 or 0) * CFrame.Angles(0, math.rad(i * 7), 0), parent) end
	elseif kind == "lantern" then
		main = part(Vector3.new(1.4, 1.1, 1.4), WOOD_DARK, cf * CFrame.new(0, 0.55, 0), parent, Enum.Material.WoodPlanks)
		local lamp = part(Vector3.new(0.6, 0.7, 0.6), C(255, 196, 110), cf * CFrame.new(0, 1.35, 0), parent, Enum.Material.Neon)
		local cap = part(Vector3.new(0.8, 0.15, 0.8), WOOD_DARK, cf * CFrame.new(0, 1.78, 0), parent)
		local l = Instance.new("PointLight"); l.Color = C(255, 200, 120); l.Range = 7; l.Brightness = 0.6; l.Parent = lamp
	else   -- planks
		main = part(Vector3.new(0.5, 0.26, 3.0), WOOD, cf * CFrame.new(0, 0.13, 0), parent)
		part(Vector3.new(0.5, 0.26, 3.0), C(162, 118, 70), cf * CFrame.new(0.55, 0.13, -0.1) * CFrame.Angles(0, math.rad(4), 0), parent)
		part(Vector3.new(0.5, 0.26, 2.9), WOOD_DARK, cf * CFrame.new(0.25, 0.39, 0.1) * CFrame.Angles(0, math.rad(-5), 0), parent)
		local tie = part(Vector3.new(1.3, 0.62, 0.3), ROPE, cf * CFrame.new(0.25, 0.32, 0.6), parent, Enum.Material.Fabric)
	end
	return main
end
local function makePiece(pc)
	local m = Instance.new("Model"); m.Name = "Piece_" .. pc.id
	local cf = CFrame.new(pc.x, pc.y, pc.z) * CFrame.Angles(0, (tonumber(pc.yaw) or 0) * math.pi / 180, 0)
	local main = bundle(pc.kind, cf, m)
	m.PrimaryPart = main
	local bb = Instance.new("BillboardGui"); bb.Name = "Tag"; bb.Size = UDim2.fromOffset(120, 22); bb.StudsOffset = Vector3.new(0, 2.4, 0); bb.MaxDistance = 42; bb.AlwaysOnTop = false; bb.Parent = main
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundColor3 = NAVY; t.BackgroundTransparency = 0.25; t.Font = FONT; t.TextSize = 13; t.TextColor3 = GOLD; t.Text = "Treehouse piece"; t.Parent = bb
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = t
	-- the gold glow the interact pills use (PromptClient's outline colour), on every piece within sight so it stands out from the grass
	-- (Shannon, Oct 15: "a yellow glowy outline around the treehouse pieces, the way you do to show things are interactable")
	local hl = Instance.new("Highlight"); hl.Name = "Glow"; hl.Adornee = m; hl.FillColor = C(255, 214, 90); hl.FillTransparency = 0.8
	hl.OutlineColor = C(255, 214, 90); hl.OutlineTransparency = 0; hl.DepthMode = Enum.HighlightDepthMode.Occluded; hl.Parent = m
	local pr = Instance.new("ProximityPrompt"); pr.Name = "PickUp"; pr.Style = Enum.ProximityPromptStyle.Custom
	pr.ObjectText = "Treehouse piece"; pr.ActionText = "Pick up"; pr.MaxActivationDistance = 10; pr.HoldDuration = 0; pr.RequiresLineOfSight = false
	pr.Parent = main
	pr.Triggered:Connect(function()
		if has(pc.id) then return end
		if pending[pc.id] and os.clock() - pending[pc.id] < 2 then return end
		pending[pc.id] = os.clock()
		ev:FireServer("pick", pc.id)
	end)
	m.Parent = piecesF
	pieceModels[pc.id] = m
end
game:GetService("RunService").Heartbeat:Connect(function()
	local f = 0.72 + 0.16 * math.sin(os.clock() * 2.2)
	for _, m in pairs(pieceModels) do local g = m:FindFirstChild("Glow"); if g then g.FillTransparency = f end end
end)
local function placePieces()
	for _, pc in ipairs(PIECES) do
		local m = pieceModels[pc.id]
		if has(pc.id) then
			if m and not (pending[pc.id] and os.clock() - pending[pc.id] < 2) then m:Destroy(); pieceModels[pc.id] = nil end   -- (a pick in flight: the "got" reply takes it down with its "Got it!")
		elseif not m then makePiece(pc) end
	end
end

-- ---------- the house on the oak (local coordinates: y 0 = the oak's foot, +z towards the spawn) ----------
local HOUSE_DZ = 0                                                       -- (job 112: the house is centred on its own stilts; the oak's trunk stands OUTSIDE the back wall at z -13.5 and the room is clear)
local function L(x, y, z, rx, ry, rz) return base * CFrame.new(x, y, z + HOUSE_DZ) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0)) end
local function wedge(size, color, cf, parent)
	local w = Instance.new("WedgePart"); w.Size = size; w.Color = color; w.Material = Enum.Material.WoodPlanks; w.Anchored = true; w.CanCollide = true; w.CanQuery = false; w.CanTouch = false
	w.TopSurface = Enum.SurfaceType.Smooth; w.BottomSurface = Enum.SurfaceType.Smooth; w.CFrame = cf; w.Parent = parent
	return w
end
-- (r3) sitting: the house is drawn on this screen only, so its seats are too - a "Sit" prompt; Seat:Sit when Roblox lets the client
-- do it, else the character is welded on (the character is this client's own, so the weld holds); a jump stands up
local sitting
local function standUp()
	if not sitting then return end
	local s = sitting; sitting = nil
	if s.weld then s.weld:Destroy() end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.Sit = false end
end
local function seatAt(p)
	local pr = Instance.new("ProximityPrompt"); pr.ActionText = "Sit"; pr.ObjectText = ""; pr.HoldDuration = 0; pr.MaxActivationDistance = 7
	pr.RequiresLineOfSight = false; pr.Parent = p
	p.CanQuery = true
	pr.Triggered:Connect(function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not (hum and root and hum.Health > 0) then return end
		standUp()
		root.CFrame = p.CFrame * CFrame.new(0, p.Size.Y / 2 + hum.HipHeight * 0.5 + 0.9, 0)
		hum.Sit = true
		local w = Instance.new("WeldConstraint"); w.Part0 = p; w.Part1 = root; w.Parent = p
		sitting = {weld = w, seat = p}
		local c; c = hum:GetPropertyChangedSignal("Jump"):Connect(function() if hum.Jump then c:Disconnect(); standUp() end end)
		task.spawn(function()                                                -- (the house redraws: the seat goes, so does the weld)
			while sitting and sitting.seat == p and p.Parent do task.wait(0.5) end
			if sitting and sitting.seat == p then standUp() end
			if c.Connected then c:Disconnect() end
		end)
	end)
	return p
end
local signLabel
-- the house (job 112): a 22 x 22 deck on stilts with a 22 x 8 balcony toward the spawn, a 19 x 19 room (18.6 inside), the door onto the
-- balcony, a window in each side wall, the floor the deck's top at y 10.5; the trunk is behind the back wall, nothing stands in the room
local function buildHouse(n)
	houseF:ClearAllChildren()
	-- the sign at the foot, always, left of the ladder
	part(Vector3.new(0.4, 3.0, 0.4), WOOD_DARK, L(-12, 1.5, 21.6), houseF, nil, true)   -- behind the board, never across its text
	local board = part(Vector3.new(5.6, 2.8, 0.3), WOOD, L(-12, 3.7, 22, 0, 180, 0), houseF, Enum.Material.WoodPlanks, true)   -- its Front faces +z (the spawn)
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.CanvasSize = Vector2.new(480, 240); sg.LightInfluence = 0.6; sg.Parent = board
	signLabel = Instance.new("TextLabel"); signLabel.Size = UDim2.new(1, -24, 1, -16); signLabel.Position = UDim2.fromOffset(12, 8); signLabel.BackgroundTransparency = 1
	signLabel.Font = FONT; signLabel.TextScaled = true; signLabel.TextColor3 = CREAM; signLabel.TextWrapped = true; signLabel.Parent = sg
	local ss = Instance.new("UIStroke"); ss.Color = C(40, 24, 12); ss.Thickness = 1.5; ss.Parent = signLabel
	if n >= STAGES.ladder then                                              -- the ladder lands on the balcony's front, in its railing gap
		local t = Instance.new("TrussPart"); t.Size = Vector3.new(2, 10, 2); t.Style = Enum.Style.AlternatingSupports; t.Color = WOOD_DARK; t.Material = Enum.Material.Wood
		t.Anchored = true; t.CanCollide = true; t.CanQuery = true; t.CanTouch = false; t.CFrame = L(0, 5, 20); t.Name = "Ladder"; t.Parent = houseF
	end
	if n >= STAGES.deck then                                                -- the deck, the balcony, joists, six stilts to the ground
		local d = part(Vector3.new(22, 0.5, 22), WOOD, L(0, 10.25, 0), houseF, Enum.Material.WoodPlanks, true); d.Name = "Deck"; d.CanQuery = true
		local b2 = part(Vector3.new(22, 0.5, 8), WOOD, L(0, 10.25, 15), houseF, Enum.Material.WoodPlanks, true); b2.Name = "Balcony"; b2.CanQuery = true
		for _, z in ipairs({-9, -3, 3, 9, 15}) do part(Vector3.new(22.4, 0.5, 0.8), WOOD_DARK, L(0, 9.75, z), houseF) end
		for _, x in ipairs({-9, -3, 3, 9}) do part(Vector3.new(0.8, 0.5, 30.4), WOOD_DARK, L(x, 9.75, 4), houseF) end
		for _, s in ipairs({{-10, 18}, {10, 18}, {-10, 0}, {10, 0}, {-10, -10}, {10, -10}}) do part(Vector3.new(0.9, 10, 0.9), WOOD_DARK, L(s[1], 5, s[2]), houseF, nil, true) end
	end
	if n >= STAGES.railing then                                             -- the balcony's railing (always), the deck's until the walls come
		local function post(x, z) part(Vector3.new(0.4, 1.3, 0.4), WOOD_DARK, L(x, 11.15, z), houseF, nil, true) end
		local function rail(x, z, sx, sz) part(Vector3.new(sx, 0.25, sz), WOOD, L(x, 11.7, z), houseF, nil, true) end
		for _, x in ipairs({-10.8, -1.6, 1.6, 10.8}) do post(x, 18.8) end
		rail(-6.2, 18.8, 9.2, 0.25); rail(6.2, 18.8, 9.2, 0.25)                -- the gap is the top of the ladder
		for _, x in ipairs({-10.8, 10.8}) do post(x, 11.3); rail(x, 15.05, 0.25, 7.5) end
		if n < STAGES.walls then
			for _, x in ipairs({-10.8, 10.8}) do post(x, -10.8); rail(x, 0.25, 0.25, 22.1) end
			rail(0, -10.8, 22, 0.25)
		end
	end
	-- (r3, Shannon: "the door entry and ceiling are too low ... for a tall character it will be hard to fit"): the walls 9 tall
	-- (floor 10.5 .. 19.5), the door 5 wide and 8 high; everything above the old wall top moved up 2.5 with it
	if n >= STAGES.walls then                                               -- a 19 x 19 room, the door onto the balcony
		part(Vector3.new(19, 9, 0.4), WOOD, L(0, 15, -9.5), houseF, Enum.Material.WoodPlanks, true)
		for _, x in ipairs({-9.5, 9.5}) do
			if n >= STAGES.window then                                       -- each side wall is four parts round a 2.8 x 2.8 hole (y 12.7..15.5) once the windows come
				part(Vector3.new(0.4, 2.2, 19), WOOD, L(x, 11.6, 0), houseF, Enum.Material.WoodPlanks, true)
				part(Vector3.new(0.4, 4.0, 19), WOOD, L(x, 17.5, 0), houseF, Enum.Material.WoodPlanks, true)
				for _, z in ipairs({-5.45, 5.45}) do part(Vector3.new(0.4, 2.8, 8.1), WOOD, L(x, 14.1, z), houseF, Enum.Material.WoodPlanks, true) end
			else
				part(Vector3.new(0.4, 9, 19), WOOD, L(x, 15, 0), houseF, Enum.Material.WoodPlanks, true)
			end
		end
		for _, x in ipairs({-6.0, 6.0}) do part(Vector3.new(7.0, 9, 0.4), WOOD, L(x, 15, 9.5), houseF, Enum.Material.WoodPlanks, true) end   -- the door is the 5-stud gap
		part(Vector3.new(5.0, 1.0, 0.4), WOOD, L(0, 19.0, 9.5), houseF, Enum.Material.WoodPlanks, true)          -- the wall over the door (the opening is 8 high)
		part(Vector3.new(5.4, 0.5, 0.5), WOOD_DARK, L(0, 18.35, 9.55), houseF, Enum.Material.WoodPlanks)        -- the lintel trim, looks only
		for _, x in ipairs({-2.6, 2.6}) do part(Vector3.new(0.3, 8, 0.5), WOOD_DARK, L(x, 14.5, 9.55), houseF, Enum.Material.WoodPlanks) end   -- the door frame's sides
		-- a table and two stools in the right back corner at avatar scale (the top 2.6 above the floor, the seats 1.6), a mug; the middle stays open
		part(Vector3.new(3.4, 0.2, 2.4), WOOD, L(6.4, 13.1, -6.4), houseF, Enum.Material.WoodPlanks)
		for _, d in ipairs({{-1.45, -0.95}, {1.45, -0.95}, {-1.45, 0.95}, {1.45, 0.95}}) do part(Vector3.new(0.3, 2.5, 0.3), WOOD_DARK, L(6.4 + d[1], 11.75, -6.4 + d[2]), houseF) end
		for _, x in ipairs({5.0, 7.8}) do
			seatAt(part(Vector3.new(1.2, 0.2, 1.2), WOOD, L(x, 12.1, -4.0), houseF, Enum.Material.WoodPlanks, true))   -- (r3: you can sit on them; facing the table)
			part(Vector3.new(0.3, 1.5, 0.3), WOOD_DARK, L(x, 11.25, -4.0), houseF)
		end
		local mug = part(Vector3.new(0.9, 0.7, 0.7), CREAM, L(6.9, 13.65, -6.2, 0, 0, 90), houseF, Enum.Material.SmoothPlastic); mug.Shape = Enum.PartType.Cylinder
		part(Vector3.new(0.14, 0.5, 0.14), CREAM, L(6.9, 13.65, -5.72), houseF, Enum.Material.SmoothPlastic)
		part(Vector3.new(0.14, 0.14, 0.4), CREAM, L(6.9, 13.9, -5.6), houseF, Enum.Material.SmoothPlastic); part(Vector3.new(0.14, 0.14, 0.4), CREAM, L(6.9, 13.4, -5.6), houseF, Enum.Material.SmoothPlastic)
	end
	if n >= STAGES.roof then
		wedge(Vector3.new(20.4, 4.5, 10.2), ROOF, L(0, 21.75, -5.1), houseF)
		wedge(Vector3.new(20.4, 4.5, 10.2), ROOF, L(0, 21.75, 5.1, 0, 180, 0), houseF)
		part(Vector3.new(20.8, 0.35, 0.35), WOOD_DARK, L(0, 24.15, 0), houseF)
		part(Vector3.new(22, 0.3, 4), ROOF, L(0, 19.8, 12), houseF, Enum.Material.WoodPlanks)   -- a little awning over the door onto the balcony
	end
	if n >= STAGES.window then                                              -- a window in each side wall, in its hole, the frame 0.5 thick so it shows inside and out
		for _, x in ipairs({-9.5, 9.5}) do
			part(Vector3.new(0.5, 0.3, 3.2), WOOD_DARK, L(x, 15.6, 0), houseF); part(Vector3.new(0.5, 0.3, 3.2), WOOD_DARK, L(x, 12.6, 0), houseF)
			for _, z in ipairs({-1.5, 1.5}) do part(Vector3.new(0.5, 3.3, 0.3), WOOD_DARK, L(x, 14.1, z), houseF) end
			local pane = part(Vector3.new(0.08, 2.8, 2.8), C(170, 210, 235), L(x, 14.1, 0), houseF, Enum.Material.Glass); pane.Transparency = 0.35; pane.Reflectance = 0.15
			part(Vector3.new(0.08, 2.8, 0.12), WOOD_DARK, L(x, 14.1, 0), houseF); part(Vector3.new(0.08, 0.12, 2.8), WOOD_DARK, L(x, 14.1, 0), houseF)
		end
		-- a shelf under the left window on the inside (its top at the sill), a potted plant on it (the wall's inner face is at x -9.3)
		part(Vector3.new(1.0, 0.14, 3.4), WOOD, L(-8.8, 12.5, 0), houseF, Enum.Material.WoodPlanks)
		part(Vector3.new(0.7, 0.6, 0.7), C(178, 96, 62), L(-8.8, 12.87, 0.9), houseF, Enum.Material.SmoothPlastic)
		part(Vector3.new(1.0, 0.9, 1.0), C(92, 150, 70), L(-8.8, 13.6, 0.9), houseF, Enum.Material.Grass)
	end
	if n >= STAGES.lantern then                                             -- beside the door, under the awning
		part(Vector3.new(0.08, 1.2, 0.08), C(60, 56, 52), L(3.6, 18.9, 10.4), houseF, Enum.Material.Metal)
		part(Vector3.new(0.9, 0.18, 0.9), C(60, 56, 52), L(3.6, 18.2, 10.4), houseF, Enum.Material.Metal)
		local lamp = part(Vector3.new(0.7, 0.9, 0.7), C(255, 196, 110), L(3.6, 17.7, 10.4), houseF, Enum.Material.Neon)
		local l = Instance.new("PointLight"); l.Color = C(255, 200, 120); l.Range = 16; l.Brightness = 0.9; l.Shadows = false; l.Parent = lamp
	end
	if n >= STAGES.flag then
		part(Vector3.new(0.2, 4.4, 0.2), C(70, 60, 50), L(10.8, 12.9, 18.8), houseF, Enum.Material.Metal)        -- on the balcony's front corner post
		part(Vector3.new(0.06, 1.3, 2.3), C(196, 56, 48), L(10.8, 14.4, 17.55), houseF, Enum.Material.Fabric)
		part(Vector3.new(0.08, 0.42, 2.3), CREAM, L(10.8, 14.4, 17.55), houseF, Enum.Material.Fabric)
		-- a round rug in the middle of the room and, by the left window, a red armchair you can sit in (r3: it was a gold cushion, read as "a yellow square")
		local rug = part(Vector3.new(0.1, 7.0, 7.0), C(188, 74, 64), L(0, 10.55, 0.5, 0, 0, 90), houseF, Enum.Material.Fabric); rug.Shape = Enum.PartType.Cylinder   -- (a cylinder's length is its X; stood on end it is a disc)
		local RED, RED_D = C(176, 58, 52), C(132, 40, 36)
		local ac = L(-7.2, 0, 3.6, 0, -90, 0)                                -- facing the middle of the room (+x)
		local function arm(x, y, z, sx, sy, sz, col) return part(Vector3.new(sx, sy, sz), col, ac * CFrame.new(x, y, z), houseF, Enum.Material.Fabric, true) end
		arm(0, 11.0, 0, 2.6, 1.0, 2.4, RED_D)                                -- the base
		seatAt(arm(0, 11.75, -0.1, 2.2, 0.5, 2.0, RED))                      -- the seat cushion
		arm(0, 12.9, 1.05, 2.6, 2.8, 0.5, RED)                               -- the back
		for _, x in ipairs({-1.2, 1.2}) do arm(x, 12.2, 0, 0.45, 1.4, 2.4, RED_D) end   -- the arms
	end
end
local function signText(n)
	if n >= TOTAL then return NAME .. "\nest. today.\nWelcome home." end
	if n < STAGES.deck then return string.format("Future home of\n%s.\nPlease excuse the dirt.\n%d of %d pieces found.", NAME, n, TOTAL) end
	return string.format("%s\n%d of %d pieces found.\n%d to go.", NAME, n, TOTAL, TOTAL - n)
end
-- ---------- the pill, the toast, the card ----------
for _, n in ipairs({"TreehouseGui", "TreehouseDone"}) do local g = pg:FindFirstChild(n); if g then g:Destroy() end end   -- (an earlier TreehouseClient's, after a re-install)
local gui = Instance.new("ScreenGui"); gui.Name = "TreehouseGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 15; gui.Parent = pg
local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p; return c end
local pill = Instance.new("TextLabel"); pill.Name = "TreePill"; pill.AnchorPoint = Vector2.new(1, 0); pill.Position = UDim2.new(1, -12, 0, 100)
pill.AutomaticSize = Enum.AutomaticSize.X; pill.Size = UDim2.fromOffset(0, 24); pill.BackgroundColor3 = NAVY; pill.BackgroundTransparency = 0.15
pill.Font = FONT; pill.TextSize = 13; pill.TextColor3 = GOLD; pill.Text = ""; pill.Visible = false; pill.Parent = gui
corner(pill, 12)
local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10); pad.Parent = pill
local lastN = -1
local function updatePill()
	local n = count()
	pill.Text = string.format("Homebase: %d of %d pieces", n, TOTAL)
	pill.Visible = (not isPhone) and inFrance() and pg:GetAttribute("OpenPanel") == nil and n < TOTAL and F:GetAttribute("Enabled") ~= false
end
local toast = Instance.new("TextLabel"); toast.Name = "TreeToast"; toast.AnchorPoint = Vector2.new(0.5, 1); toast.Position = UDim2.new(0.5, 0, 1, -118); toast.Size = UDim2.fromOffset(400, 40)
toast.BackgroundColor3 = NAVY; toast.BackgroundTransparency = 0.1; toast.Font = FONT; toast.TextSize = 17; toast.TextColor3 = GOLD; toast.TextWrapped = true; toast.Visible = false; toast.Parent = gui
corner(toast, 12)
local toastAt = 0
local function say(t, secs)
	toast.Text = t; toast.Size = UDim2.fromOffset(400, #t > 60 and 66 or 40); toast.Visible = true
	local mine = os.clock(); toastAt = mine
	task.delay(secs or 3.5, function() if toastAt == mine then toast.Visible = false end end)
end
local function sound(id, vol)
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol or 0.5; s.Parent = gui
	s.Ended:Connect(function() s:Destroy() end); s:Play()
	task.delay(6, function() if s.Parent then s:Destroy() end end)
end
local function pieceSound()                                                -- (r2, Shannon: "the toast when you find a piece should be a different sound than ... a squirrel")
	local s = Instance.new("Sound"); s.SoundId = tostring(F:GetAttribute("PieceSound") or "rbxassetid://16480570986")
	s.Volume = tonumber(F:GetAttribute("PieceSoundVolume")) or 0.55; s.PlaybackSpeed = tonumber(F:GetAttribute("PieceSoundSpeed")) or 1.5; s.Parent = gui
	s.Ended:Connect(function() s:Destroy() end); s:Play()
	task.delay(6, function() if s.Parent then s:Destroy() end end)
end
local function doneCard(prize)
	local cg = Instance.new("ScreenGui"); cg.Name = "TreehouseDone"; cg.ResetOnSpawn = false; cg.IgnoreGuiInset = true; cg.DisplayOrder = 100; cg.Parent = pg
	local card = Instance.new("Frame"); card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.45); card.Size = UDim2.fromOffset(340, 168)
	card.BackgroundColor3 = NAVY; card.Parent = cg; corner(card, 16); card.Size = UDim2.fromOffset(360, 186)
	local st = Instance.new("UIStroke"); st.Color = GOLD; st.Thickness = 2; st.Parent = card
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -24, 0, 36); title.Position = UDim2.fromOffset(12, 14); title.BackgroundTransparency = 1
	title.Font = FONT; title.TextSize = 24; title.TextColor3 = GOLD; title.Text = "Homebase Treehouse: built!"; title.Parent = card
	local body = Instance.new("TextLabel"); body.Size = UDim2.new(1, -30, 0, 76); body.Position = UDim2.fromOffset(15, 52); body.BackgroundTransparency = 1
	body.Font = FONT; body.TextSize = 16; body.TextColor3 = CREAM; body.TextWrapped = true
	body.Text = string.format("%d acorns for the builder. Climb up, step onto the balcony, and look out over your forest. Add-ons for your Homebase wait in Rue de Noisette.", prize or 100); body.Parent = card
	local btn = Instance.new("TextButton"); btn.AnchorPoint = Vector2.new(0.5, 1); btn.Position = UDim2.new(0.5, 0, 1, -14); btn.Size = UDim2.fromOffset(120, 34)
	btn.BackgroundColor3 = GOLD; btn.Font = FONT; btn.TextSize = 17; btn.TextColor3 = NAVY; btn.Text = "Hooray!"; btn.Parent = card; corner(btn, 10)
	btn.Activated:Connect(function() cg:Destroy() end)
	task.delay(15, function() if cg.Parent then cg:Destroy() end end)
end

-- ---------- the first piece: a look at the hollow where the Homebase will stand (~6 s), then back ----------
local revealed = false
local function reveal()
	if revealed then return end
	revealed = true
	local cam = workspace.CurrentCamera
	if not cam then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local site = base.Position
	local toward = (Vector3.new(TREE.x, 0, TREE.z) - Vector3.new(3, 0, 1)).Unit            -- from the spawn toward the site
	local eye = site - toward * 46 + Vector3.new(0, 22, 0)                                   -- (job 112: farther back for the bigger house and its tree)
	local look = CFrame.lookAt(eye, site + Vector3.new(0, 6, 0))
	local from = cam.CFrame
	cam.CameraType = Enum.CameraType.Scriptable
	local t1 = TweenService:Create(cam, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = look})
	t1:Play()
	say(REVEAL_LINE, 6.2)
	task.delay(1.2 + 4.5, function()                                          -- (r2, Shannon: "make it 4.5 seconds": the 1.2 s fly-in, then a 4.5 s hold)
		local back = (player.Character and player.Character:FindFirstChild("Head")) and CFrame.lookAt(player.Character.Head.Position + Vector3.new(0, 4, 10), player.Character.Head.Position) or from
		local t2 = TweenService:Create(cam, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = back})
		t2:Play()
		t2.Completed:Connect(function()
			cam.CameraType = Enum.CameraType.Custom
			local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if h then cam.CameraSubject = h end
		end)
	end)
end
-- ---------- the last piece: a look at the finished house, fireworks, "Welcome home" (r2, Shannon, Oct 15) ----------
local function fireworks(centre, secs)
	local COLS = {C(255, 120, 120), C(255, 206, 90), C(120, 210, 140), C(120, 170, 255), C(230, 140, 230), C(255, 255, 255)}
	local t0 = os.clock()
	task.spawn(function()
		local k = 0
		while os.clock() - t0 < secs do
			k += 1
			local col = COLS[(k % #COLS) + 1]
			local side = (k % 2 == 0) and 1 or -1                               -- (r2b: either side of the house and below the banner - runner 7's preview)
			local at = L(side * math.random(11, 19), math.random(15, 25), math.random(-6, 6)).Position
			local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.Transparency = 1
			p.Size = Vector3.new(1, 1, 1); p.CFrame = CFrame.new(at); p.Parent = folder
			local e = Instance.new("ParticleEmitter"); e.Rate = 0; e.Speed = NumberRange.new(14, 24); e.SpreadAngle = Vector2.new(180, 180)
			e.Lifetime = NumberRange.new(0.9, 1.6); e.Acceleration = Vector3.new(0, -14, 0); e.Drag = 2.2; e.LightEmission = 1; e.LightInfluence = 0
			e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.8), NumberSequenceKeypoint.new(0.6, 1.2), NumberSequenceKeypoint.new(1, 0)})   -- (r2b: bigger - they read as a faint trail in daylight)
			pcall(function() e.Brightness = 5 end)
			e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1)})
			e.Color = ColorSequence.new(col, COLS[((k + 2) % #COLS) + 1]); e.Parent = p
			local l = Instance.new("PointLight"); l.Color = col; l.Range = 28; l.Brightness = 4; l.Shadows = false; l.Parent = p
			e:Emit(130)
			TweenService:Create(l, TweenInfo.new(1.1), {Brightness = 0}):Play()
			Debris:AddItem(p, 2.5)
			task.wait(0.45 + math.random() * 0.25)
		end
	end)
	-- confetti falling over the deck
	local cp = Instance.new("Part"); cp.Anchored = true; cp.CanCollide = false; cp.CanQuery = false; cp.CanTouch = false; cp.Transparency = 1
	cp.Size = Vector3.new(26, 1, 26); cp.CFrame = CFrame.new(centre + Vector3.new(0, 26, 0)); cp.Parent = folder
	local ce = Instance.new("ParticleEmitter"); ce.Shape = Enum.ParticleEmitterShape.Box; ce.EmissionDirection = Enum.NormalId.Bottom; ce.Rate = 90
	ce.Speed = NumberRange.new(2, 5); ce.Lifetime = NumberRange.new(3, 4.5); ce.Acceleration = Vector3.new(0, -4, 0); ce.Drag = 0.6
	ce.RotSpeed = NumberRange.new(-260, 260); ce.Rotation = NumberRange.new(0, 360); ce.Size = NumberSequence.new(0.35); ce.Shape = Enum.ParticleEmitterShape.Box
	ce.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, COLS[1]), ColorSequenceKeypoint.new(0.33, COLS[2]), ColorSequenceKeypoint.new(0.66, COLS[4]), ColorSequenceKeypoint.new(1, COLS[3])})
	ce.Parent = cp
	task.delay(secs, function() ce.Enabled = false end)
	Debris:AddItem(cp, secs + 5)
end
local function welcomeBanner(text, secs)
	local bg = Instance.new("ScreenGui"); bg.Name = "TreehouseWelcome"; bg.ResetOnSpawn = false; bg.IgnoreGuiInset = true; bg.DisplayOrder = 99; bg.Parent = pg
	local t = Instance.new("TextLabel"); t.AnchorPoint = Vector2.new(0.5, 0); t.Position = UDim2.fromScale(0.5, 0.14); t.Size = UDim2.new(0.9, 0, 0, 72)
	t.BackgroundTransparency = 1; t.Font = FONT; t.TextScaled = true; t.TextColor3 = GOLD; t.Text = text; t.TextTransparency = 1; t.Parent = bg
	local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = 60; tc.Parent = t
	local st = Instance.new("UIStroke"); st.Color = C(60, 30, 14); st.Thickness = 3; st.Transparency = 1; st.Parent = t
	TweenService:Create(t, TweenInfo.new(0.5), {TextTransparency = 0}):Play(); TweenService:Create(st, TweenInfo.new(0.5), {Transparency = 0}):Play()
	task.delay(secs, function()
		TweenService:Create(t, TweenInfo.new(0.5), {TextTransparency = 1}):Play(); TweenService:Create(st, TweenInfo.new(0.5), {Transparency = 1}):Play()
		Debris:AddItem(bg, 0.7)
	end)
end
local function finale(prize)
	local cam = workspace.CurrentCamera
	if not cam then doneCard(prize) return end
	local from = cam.CFrame
	local centre = L(0, 13, 0).Position
	local look = CFrame.lookAt(L(14, 24, 52).Position, L(0, 14, 0).Position)   -- in front of the balcony, a little to the right and above
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = look}):Play()
	task.delay(1.0, function()
		fireworks(centre, 4.5)
		sound("rbxassetid://1845415163", 0.7)
		welcomeBanner("Welcome home, " .. player.DisplayName .. "!", 4.3)
	end)
	task.delay(1.2 + 4.5, function()                                          -- the same 4.5 s hold as the first look
		local head = player.Character and player.Character:FindFirstChild("Head")
		local back = head and CFrame.lookAt(head.Position + Vector3.new(0, 4, 10), head.Position) or from
		local t2 = TweenService:Create(cam, TweenInfo.new(1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = back}); t2:Play()
		t2.Completed:Connect(function()
			cam.CameraType = Enum.CameraType.Custom
			local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if h then cam.CameraSubject = h end
			doneCard(prize)
		end)
	end)
end
-- ---------- keeping it all current ----------
local function refresh()
	if F:GetAttribute("Enabled") == false then piecesF:ClearAllChildren(); houseF:ClearAllChildren(); pieceModels = {}; lastN = -1; signLabel = nil; pill.Visible = false return end
	local n = count()
	placePieces()
	if n ~= lastN then lastN = n; buildHouse(n) end
	if signLabel then signLabel.Text = signText(n) end
	updatePill()
end
local queued = false
local function later() if queued then return end; queued = true; task.defer(function() queued = false; refresh() end) end
ev.OnClientEvent:Connect(function(what, a, b)
	if what == "got" then
		gotLocal[a] = true; pending[a] = nil
		local m = pieceModels[a]
		if m then
			local tag = m.PrimaryPart and m.PrimaryPart:FindFirstChild("Tag")
			local tl = tag and tag:FindFirstChildOfClass("TextLabel")
			if tl then tl.Text = "Got it!" end
			local pr = m.PrimaryPart and m.PrimaryPart:FindFirstChild("PickUp"); if pr then pr.Enabled = false end
			task.delay(0.7, function() if m.Parent then m:Destroy() end end)
			pieceModels[a] = nil
		end
		local n = tonumber(b) or count()
		pieceSound()
		later()
		if n == 1 and not revealed then task.delay(0.6, reveal)
		elseif n >= TOTAL then say("That was the last piece!", 3)
		else say(string.format("Homebase piece %d of %d! %d more to find", n, TOTAL, TOTAL - n), 3.5) end
	elseif what == "done" then
		task.delay(0.8, function() later(); finale(tonumber(a) or 100) end)    -- (r2: the finished house first, then the card)
	elseif what == "wait" then
		say("Your save is still loading - try again in a moment", 3)
	end
end)
player.AttributeChanged:Connect(function(name)
	if name:sub(1, 10) == "Item_tree_" or name == "Area" or name == "SaveLoaded" then later() end
end)
pg:GetAttributeChangedSignal("OpenPanel"):Connect(updatePill)
F:GetAttributeChangedSignal("Enabled"):Connect(later)
task.spawn(function()
	local t0 = os.clock()
	while player:GetAttribute("SaveLoaded") ~= true and os.clock() - t0 < 120 do task.wait(0.5) end   -- the Item_tree_* attributes come with the save
	refresh()
	print(string.format("Treehouse: %d of %d pieces on this screen", count(), TOTAL))
end)
]===]
do
	for _, s in ipairs({{"TreehouseServer", SERVER}, {"TreehouseClient3", CLIENT}}) do
		local ok, f, err = pcall(function() return loadstring(s[2]) end)
		if ok and not f then print("QQ TREE ABORT: " .. s[1] .. " does not compile: " .. tostring(err)) return end
	end
end
local SITE = HttpService:JSONDecode([==[{"x":-107,"z":4,"floor":0.06,"yaw":91.6}]==])
local PIECES = HttpService:JSONDecode([==[[{"id":"p1","x":14,"z":-8,"kind":"planks","yaw":30},{"id":"p2","x":-10,"z":-42,"kind":"rope","yaw":0},{"id":"p3","x":22,"z":-46,"kind":"planks","yaw":70},{"id":"p4","x":55,"z":-14,"kind":"shingles","yaw":15},{"id":"p5","x":-12,"z":-88,"kind":"planks","yaw":100},{"id":"p6","x":86,"z":-36,"kind":"rope","yaw":40},{"id":"p7","x":58,"z":-108,"kind":"shingles","yaw":0},{"id":"p8","x":76,"z":-118,"kind":"planks","yaw":55},{"id":"p9","x":36,"z":-131,"kind":"lantern","yaw":20},{"id":"p10","x":2,"z":-144,"kind":"planks","yaw":80},{"id":"p11","x":-37,"z":-138,"kind":"shingles","yaw":10},{"id":"p12","x":72,"z":-148,"kind":"lantern","yaw":60}]]==])
local CLEAR_PARENTS = HttpService:JSONDecode([==[["Forest","Foliage","Rocks","Trees","Nature","Props","Mushrooms","Bushes"]]==])
local CLEAR_NAMES = HttpService:JSONDecode([==[["tree","pine","oak","birch","rock","stone","boulder","mushroom","bush","stump","log","fern","shrub","flower","grass","foliage","canopy","trunk"]]==])
local KEEP_NAMES = HttpService:JSONDecode([==[["squirrel","tower","spawn","zip","station","glider","ramp","treehouse","piece","sign","shop","bench","path","road","bridge","gate","wall","fence"]]==])
local CLEAR_R = 26
local SX, SZ, FLOOR = SITE.x, SITE.z, SITE.floor
local log = {}
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Treehouse3") end)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
-- ---------- 1: the old hollow put back ----------
local old = workspace:FindFirstChild("Treehouse")
local oldSite
if old then
	pcall(function() oldSite = HttpService:JSONDecode(old:GetAttribute("Tree")) end)
	local n = 1; while hb:FindFirstChild("Treehouse_pre_" .. n) do n += 1 end
	old.Name = "Treehouse_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
	log.old = old.Name
end
do	-- the pines back from the LAST TreehouseCleared_n that still holds models, to the first Dressing folder
	local dressing
	for _, f in ipairs(workspace:GetDescendants()) do if f:IsA("Folder") and f.Name == "Dressing" then dressing = f break end end
	local back, from = 0, nil
	for n = 9, 1, -1 do
		local cf = hb:FindFirstChild("TreehouseCleared_" .. n)
		if cf and #cf:GetChildren() > 0 and dressing then
			for _, m in ipairs(cf:GetChildren()) do m.Parent = dressing; back += 1 end
			from = cf.Name; break
		end
	end
	print(string.format("QQ TREE old hollow: %d dressing models back%s", back, from and (" from HudBackup." .. from) or " (nothing to put back)"))
	log.pinesBack = back
end
do	-- the wall: the U goes, the two "Wall" parts at z 25 re-join into one
	local removed = 0
	local walls, wf = {}, nil
	for _, p in ipairs(workspace:GetDescendants()) do
		if p:IsA("BasePart") then
			if p.Name == "HollowWallBack" or p.Name == "HollowWallLeft" or p.Name == "HollowWallRight" then p:Destroy(); removed += 1
			elseif p.Name == "Wall" and p.Size.X > 20 and math.abs(p.Position.Z - 25) < 1.5 and p.Size.Y > 40 then table.insert(walls, p); wf = p.Parent end
		end
	end
	if #walls >= 2 then
		local x1, x2 = math.huge, -math.huge
		for _, w in ipairs(walls) do x1 = math.min(x1, w.Position.X - w.Size.X / 2); x2 = math.max(x2, w.Position.X + w.Size.X / 2) end
		local keep = walls[1]
		keep.Size = Vector3.new(x2 - x1, keep.Size.Y, keep.Size.Z); keep.CFrame = CFrame.new((x1 + x2) / 2, keep.Position.Y, keep.Position.Z)
		for i = 2, #walls do walls[i]:Destroy() end
		print(string.format("QQ TREE old hollow: the U of wall removed (%d parts); the north edge re-joined x %d..%d", removed, x1, x2))
	else
		print(string.format("QQ TREE old hollow: the U of wall removed (%d parts); the north edge is already one part (%d found)", removed, #walls))
	end
	log.wall = {removed = removed, joined = #walls}
end
if oldSite then	-- the old dirt disk back to grass (ReplaceMaterial keeps the shape)
	local r = Region3.new(Vector3.new(oldSite.x - 18, oldSite.y - 6, oldSite.z - 18), Vector3.new(oldSite.x + 18, oldSite.y + 2, oldSite.z + 18)):ExpandToGrid(4)
	T:ReplaceMaterial(r, 4, Enum.Material.Ground, Enum.Material.Grass)
	print(string.format("QQ TREE old hollow: the dirt re-grassed round (%d, %d)", oldSite.x, oldSite.z))
end
-- ---------- 2: the new site's clearing ----------
local function lower(s) return string.lower(s or "") end
local function matches(name, list) local n = lower(name); for _, k in ipairs(list) do if n:find(k, 1, true) then return true end end; return false end
local function parentOk(inst)
	local a = inst.Parent
	while a and a ~= workspace do
		for _, k in ipairs(CLEAR_PARENTS) do if a.Name == k then return true end end
		a = a.Parent
	end
	return false
end
local function hasScript(inst) for _, d in ipairs(inst:GetDescendants()) do if d:IsA("BaseScript") then return true end end; return false end
local cleared, kept, clearedF = 0, {}, nil
local seen = {}
for _, inst in ipairs(workspace:GetDescendants()) do
	if (inst:IsA("Model") or inst:IsA("BasePart")) and inst.Parent and not seen[inst] and inst ~= T then
		local top = inst
		while top.Parent and top.Parent ~= workspace and not (top.Parent:IsA("Folder")) do top = top.Parent end   -- the model under its folder
		if not seen[top] then
			seen[top] = true
			-- by BOUNDING BOX, not pivot (some Forest models' pivots sit far from their geometry): the box centre within CLEAR_R, or
			-- the box's nearest point within 18 of the site (the house's footprint reaches 15.6 to the deck corners, 22 to the balcony)
			local ok, cf, size = pcall(function() if top:IsA("Model") then return top:GetBoundingBox() end; return top.CFrame, top.Size end)
			local near = false
			if ok and cf and size then
				local dxc, dzc = math.abs(cf.X - SX) - size.X / 2, math.abs(cf.Z - SZ) - size.Z / 2
				local edge = math.sqrt(math.max(dxc, 0) ^ 2 + math.max(dzc, 0) ^ 2)
				near = math.sqrt((cf.X - SX) ^ 2 + (cf.Z - SZ) ^ 2) <= CLEAR_R or edge <= 18
			end
			if near then
				local keepIt = matches(top.Name, KEEP_NAMES) or top:FindFirstChildOfClass("Humanoid") or hasScript(top) or game:GetService("Players"):GetPlayerFromCharacter(top)
				if not keepIt and parentOk(top) and matches(top.Name, CLEAR_NAMES) then
					if not clearedF then local n = 1; while hb:FindFirstChild("TreehouseCleared_" .. n) do n += 1 end; clearedF = Instance.new("Folder"); clearedF.Name = "TreehouseCleared_" .. n; clearedF.Parent = hb end
					top:SetAttribute("ClearedFrom", top.Parent:GetFullName()); top.Parent = clearedF; cleared += 1
				elseif not keepIt then
					table.insert(kept, top:GetFullName() .. string.format(" (%.0f, %.0f)", cf.X, cf.Z))
				end
			end
		end
	end
end
print(string.format("QQ TREE cleared from the site: %d%s", cleared, clearedF and (" (HudBackup." .. clearedF.Name .. ", each with a ClearedFrom attribute)") or ""))
if #kept > 0 then print("QQ TREE left standing within " .. CLEAR_R .. " (not on the lists): " .. table.concat(kept, " | ")) end
log.cleared = clearedF and clearedF.Name or nil; log.kept = kept
-- the dirt round the oak (and under the house): Grass -> Ground in a 22-stud disk, the shape untouched
do
	local r = Region3.new(Vector3.new(SX - 24, FLOOR - 6, SZ - 24), Vector3.new(SX + 24, FLOOR + 2, SZ + 24)):ExpandToGrid(4)
	T:ReplaceMaterial(r, 4, Enum.Material.Grass, Enum.Material.Ground)
end
-- ---------- 3: the pieces' ground ----------
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {T}
local rpA = RaycastParams.new(); rpA.FilterType = Enum.RaycastFilterType.Exclude
local skip = {}
for _, n in ipairs({"Treehouse", "Treehouse_local"}) do local f = workspace:FindFirstChild(n); if f then table.insert(skip, f) end end
for _, pl in ipairs(game:GetService("Players"):GetPlayers()) do if pl.Character then table.insert(skip, pl.Character) end end
rpA.FilterDescendantsInstances = skip
local function ground(x, z)
	local h = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpA)
	local t = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rpT)
	local ty = t and t.Position.Y or nil
	if not h then return nil, "nothing", ty end
	local what = (h.Instance == T) and ("terrain " .. h.Material.Name) or h.Instance.Name
	return h.Position.Y, what, ty, h.Instance, h
end
local function open(x, z)
	local y, what, ty, inst, h = ground(x, z)
	if not y then return nil, what end
	if inst == T then if h and h.Material == Enum.Material.Water then return nil, what end; return y, what end
	local n = inst.Name:lower()
	if n:find("trunk") or n:find("foliage") or n:find("leaf") or n:find("roof") or n:find("canopy") then return nil, what .. " at y " .. string.format("%.1f", y) end
	if ty and y > ty + 2.5 then return nil, what .. string.format(" at y %.1f (terrain %.1f)", y, ty) end
	return y, what
end
local placed, skipped = {}, {}
for _, pc in ipairs(PIECES) do
	local y, what = open(pc.x, pc.z)
	local dx, dz = 0, 0
	if not y then
		for _, r in ipairs({6, 12, 18, 24}) do
			for i = 0, 7 do
				local a = i * math.pi / 4
				local tx, tz = pc.x + r * math.sin(a), pc.z + r * math.cos(a)
				local y2, w2 = open(tx, tz)
				if y2 then y, what, dx, dz = y2, w2, tx - pc.x, tz - pc.z break end
			end
			if y then break end
		end
	end
	if y then
		pc.x, pc.z, pc.y = pc.x + dx, pc.z + dz, y + 0.05
		table.insert(placed, pc)
		print(string.format("QQ TREE piece %s (%s) at (%.0f, %.1f, %.0f) on %s%s", pc.id, pc.kind, pc.x, pc.y, pc.z, what, (dx ~= 0 or dz ~= 0) and string.format(" (nudged %.0f, %.0f)", dx, dz) or ""))
	else
		table.insert(skipped, pc.id .. " (" .. tostring(what) .. ")")
		print(string.format("QQ TREE piece %s SKIPPED - no open ground within 24 studs of (%.0f, %.0f): %s", pc.id, pc.x, pc.z, tostring(what)))
	end
end
-- ---------- 4: the folder, the oak behind the house, the stones, the scripts ----------
local RS = game:GetService("ReplicatedStorage")
local F = Instance.new("Folder"); F.Name = "Treehouse"
F:SetAttribute("Enabled", true)
F:SetAttribute("Tree", HttpService:JSONEncode({x = SX, y = FLOOR, z = SZ, yaw = SITE.yaw}))
F:SetAttribute("Pieces", HttpService:JSONEncode(placed))
if not RS:FindFirstChild("TreehousePick") then local e = Instance.new("RemoteEvent"); e.Name = "TreehousePick"; e.Parent = RS end
local Oak = Instance.new("Model"); Oak.Name = "Oak"; Oak.Parent = F
local base = CFrame.new(SX, FLOOR, SZ) * CFrame.Angles(0, math.rad(SITE.yaw), 0)
local TZ = -13.5                                                           -- the trunk's local z: outside the room's back wall (z -9.5) and the deck (z -11)
local BARK, BARK2 = Color3.fromRGB(96, 66, 40), Color3.fromRGB(84, 56, 34)
local LEAF, LEAF2 = Color3.fromRGB(74, 124, 54), Color3.fromRGB(98, 148, 62)
local function mk(shape, size, color, cf, material, collide, parent)
	local p = Instance.new("Part"); p.Shape = shape; p.Size = size; p.Color = color; p.Material = material
	p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = collide == true; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.CFrame = cf; p.Parent = parent or Oak
	return p
end
local V, B = Enum.PartType.Cylinder, Enum.PartType.Ball
local tb = base * CFrame.new(0, 0, TZ)                                     -- the trunk's foot
mk(V, Vector3.new(9, 7.2, 7.2), BARK, tb * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkLow"     -- y -1..8, 3 into the ground
mk(V, Vector3.new(18, 4.8, 4.8), BARK, tb * CFrame.new(0, 16, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkHigh"   -- y 7..25, behind the back wall, past the ridge (21.5)
mk(B, Vector3.new(5, 5, 5), BARK2, tb * CFrame.new(0, 25, 0), Enum.Material.Wood, false).Name = "Crown"
for i = 1, 5 do
	local a = math.rad(i * 72 + 20)
	mk(V, Vector3.new(5.2, 1.8, 1.8), BARK2, tb * CFrame.Angles(0, a, 0) * CFrame.new(4.2, 0.55, 0) * CFrame.Angles(0, 0, math.rad(-16)), Enum.Material.Wood, true).Name = "Root"
end
for _, x in ipairs({-5, 5}) do                                              -- two limbs from the trunk reaching under the deck (y 8 -> 9.4), as if they carried it
	mk(V, Vector3.new(15, 1.6, 1.6), BARK2, base * CFrame.new(x, 8.7, TZ + 7) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(-5)) * CFrame.Angles(0, 0, 0), Enum.Material.Wood, false).Name = "Limb"
end
for i = 1, 4 do
	local a = math.rad(i * 90 + 45)
	mk(V, Vector3.new(11, 1.6, 1.6), BARK2, tb * CFrame.Angles(0, a, 0) * CFrame.new(4.8, 27, 0) * CFrame.Angles(0, 0, math.rad(34)), Enum.Material.Wood, false).Name = "Branch"
end
for i = 1, 6 do
	local a = math.rad(i * 60)
	mk(B, Vector3.new(13, 13, 13), (i % 2 == 0) and LEAF or LEAF2, tb * CFrame.new(8 * math.sin(a), 30.5, 8 * math.cos(a)), Enum.Material.Grass, false).Name = "Leaves"   -- bottoms y 24, above the ridge
end
mk(B, Vector3.new(12, 12, 12), LEAF, tb * CFrame.new(0, 35, 0), Enum.Material.Grass, false).Name = "Leaves"
mk(B, Vector3.new(9, 9, 9), LEAF2, tb * CFrame.new(12.5 * math.sin(math.rad(30)), 28.5, 12.5 * math.cos(math.rad(30))), Enum.Material.Grass, false).Name = "Leaves"
mk(B, Vector3.new(9, 9, 9), LEAF, tb * CFrame.new(12.5 * math.sin(math.rad(210)), 28, 12.5 * math.cos(math.rad(210))), Enum.Material.Grass, false).Name = "Leaves"
-- the ring of stones at the dirt's edge, a gap at the mouth for the path in
local Stones = Instance.new("Model"); Stones.Name = "Stones"; Stones.Parent = F
local STONE = Color3.fromRGB(150, 146, 138)
for i = 0, 9 do
	local a = math.rad(i * 36 + 18)
	local dgap = (i * 36 + 18 + 180) % 360 - 180
	if math.abs(dgap) > 30 then
		local s = mk(B, Vector3.new(2.4 + (i % 3) * 0.5, 1.6 + (i % 2) * 0.4, 2.2 + (i % 3) * 0.4), STONE, base * CFrame.new(21 * math.sin(a), 0.4, -3 + 21 * math.cos(a)) * CFrame.Angles(0, a, math.rad(10)), Enum.Material.Slate, true, Stones)
		s.Name = "Stone"
	end
end
local s = Instance.new("Script"); s.Name = "TreehouseServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "TreehouseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
local lv = hb:FindFirstChild("Treehouse3_log") or Instance.new("StringValue"); lv.Name = "Treehouse3_log"; lv.Parent = hb
log.site = {x = SX, y = FLOOR, z = SZ, yaw = SITE.yaw, clearR = CLEAR_R}
lv.Value = HttpService:JSONEncode(log)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Treehouse3") end)
print(string.format("QQ TREE DONE: Homebase Treehouse at (%d, %.1f, %d) yaw %.1f, the trunk behind the house; %d pieces placed%s; TreehouseServer %d, TreehouseClient %d chars%s",
	SX, FLOOR, SZ, SITE.yaw, #placed, #skipped > 0 and (", skipped " .. table.concat(skipped, ", ")) or "", #s.Source, #c.Source, log.old and ("; the old folder is HudBackup." .. log.old) or ""))
