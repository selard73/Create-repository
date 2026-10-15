-- install_treehouse2.lua (Studio EDIT; re-runnable; its body also runs as a play-test PREVIEW - terrain included, discarded on stop).
-- Job 111: the HOMEBASE TREEHOUSE in a hollow cut into the bank behind the zip line tower's left (Shannon, Oct 15 2026: "put it in a
-- corner to the left of the zip line tower ... clear a space ... an open area clearly designated for the treehouse"; "Move the edge out").
-- Terrain: a back rim, a floor, a stepped bowl, a dirt disk; the invisible north edge split round the hollow with a U of wall; the
-- dressing pines on the site to HudBackup; the oak, ten stones, the sign; TreehouseServer (4806) + TreehouseClient2 (22722);
-- twelve pieces all in the forest (p1 in sight of the spawn, the rest beside squirrels). Everything logged for undo in
-- HudBackup.Treehouse2_log. No DataStore, no publish. Output "QQ TREE".
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
local function L(x, y, z, rx, ry, rz) return base * CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0)) end
local function wedge(size, color, cf, parent)
	local w = Instance.new("WedgePart"); w.Size = size; w.Color = color; w.Material = Enum.Material.WoodPlanks; w.Anchored = true; w.CanCollide = true; w.CanQuery = false; w.CanTouch = false
	w.TopSurface = Enum.SurfaceType.Smooth; w.BottomSurface = Enum.SurfaceType.Smooth; w.CFrame = cf; w.Parent = parent
	return w
end
local signLabel
local function buildHouse(n)
	houseF:ClearAllChildren()
	-- the sign at the foot, always
	part(Vector3.new(0.4, 3.0, 0.4), WOOD_DARK, L(-9, 1.5, 18), houseF, nil, true)
	local board = part(Vector3.new(5.6, 2.8, 0.3), WOOD, L(-9, 3.7, 18, 0, 180, 0), houseF, Enum.Material.WoodPlanks, true)   -- at the hollow's mouth, its Front faces +z (the spawn)
	local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.CanvasSize = Vector2.new(480, 240); sg.LightInfluence = 0.6; sg.Parent = board
	signLabel = Instance.new("TextLabel"); signLabel.Size = UDim2.new(1, -24, 1, -16); signLabel.Position = UDim2.fromOffset(12, 8); signLabel.BackgroundTransparency = 1
	signLabel.Font = FONT; signLabel.TextScaled = true; signLabel.TextColor3 = CREAM; signLabel.TextWrapped = true; signLabel.Parent = sg
	local ss = Instance.new("UIStroke"); ss.Color = C(40, 24, 12); ss.Thickness = 1.5; ss.Parent = signLabel
	if n >= STAGES.ladder then                                              -- the ladder lands on the balcony
		local t = Instance.new("TrussPart"); t.Size = Vector3.new(2, 10, 2); t.Style = Enum.Style.AlternatingSupports; t.Color = WOOD_DARK; t.Material = Enum.Material.Wood
		t.Anchored = true; t.CanCollide = true; t.CanQuery = true; t.CanTouch = false; t.CFrame = L(0, 5, 17); t.Name = "Ladder"; t.Parent = houseF
	end
	if n >= STAGES.deck then                                                -- a 16 x 16 deck round the trunk and an 16 x 8 balcony toward the spawn
		local d = part(Vector3.new(16, 0.5, 16), WOOD, L(0, 10.25, 0), houseF, Enum.Material.WoodPlanks, true); d.Name = "Deck"; d.CanQuery = true
		local b2 = part(Vector3.new(16, 0.5, 8), WOOD, L(0, 10.25, 12), houseF, Enum.Material.WoodPlanks, true); b2.Name = "Balcony"; b2.CanQuery = true
		for _, z in ipairs({-6, 0, 6, 12}) do part(Vector3.new(16.4, 0.5, 0.8), WOOD_DARK, L(0, 9.75, z), houseF) end
		for _, x in ipairs({-6, 6}) do part(Vector3.new(0.8, 0.5, 24.4), WOOD_DARK, L(x, 9.75, 4), houseF) end
		for _, x in ipairs({-7, 7}) do part(Vector3.new(0.8, 10, 0.8), WOOD_DARK, L(x, 5, 15), houseF, nil, true) end   -- two stilts under the balcony's front, feet on the ground
	end
	if n >= STAGES.railing then                                             -- the balcony's railing (always), the deck's until the walls come
		local function post(x, z) part(Vector3.new(0.4, 1.3, 0.4), WOOD_DARK, L(x, 11.15, z), houseF, nil, true) end
		local function rail(x, z, sx, sz) part(Vector3.new(sx, 0.25, sz), WOOD, L(x, 11.7, z), houseF, nil, true) end
		for _, x in ipairs({-7.8, -1.6, 1.6, 7.8}) do post(x, 15.8) end
		rail(-4.7, 15.8, 6.2, 0.25); rail(4.7, 15.8, 6.2, 0.25)                -- the gap is the top of the ladder
		for _, x in ipairs({-7.8, 7.8}) do post(x, 8.5); rail(x, 12.1, 0.25, 7.6) end
		if n < STAGES.walls then
			for _, x in ipairs({-7.8, 7.8}) do post(x, -7.8); rail(x, 0.2, 0.25, 16.2) end
			rail(0, -7.8, 16, 0.25)
		end
	end
	if n >= STAGES.walls then                                               -- a 13 x 13 room, the door onto the balcony
		part(Vector3.new(13, 6.5, 0.4), WOOD, L(0, 13.75, -6.5), houseF, Enum.Material.WoodPlanks, true)
		for _, x in ipairs({-6.5, 6.5}) do part(Vector3.new(0.4, 6.5, 13), WOOD, L(x, 13.75, 0), houseF, Enum.Material.WoodPlanks, true) end
		for _, x in ipairs({-4.3, 4.3}) do part(Vector3.new(4.4, 6.5, 0.4), WOOD, L(x, 13.75, 6.5), houseF, Enum.Material.WoodPlanks, true) end   -- the door is the 4.2-stud gap
		part(Vector3.new(4.4, 1.2, 0.4), WOOD_DARK, L(0, 16.4, 6.5), houseF, Enum.Material.WoodPlanks)   -- the lintel, looks only
	end
	if n >= STAGES.roof then
		wedge(Vector3.new(14.4, 3.6, 7.2), ROOF, L(0, 18.8, -3.6), houseF)
		wedge(Vector3.new(14.4, 3.6, 7.2), ROOF, L(0, 18.8, 3.6, 0, 180, 0), houseF)
		part(Vector3.new(14.8, 0.35, 0.35), WOOD_DARK, L(0, 20.75, 0), houseF)
		part(Vector3.new(16, 0.3, 4), ROOF, L(0, 17.1, 9), houseF, Enum.Material.WoodPlanks)   -- a little awning over the door onto the balcony
	end
	if n >= STAGES.window then
		local x = -6.72
		part(Vector3.new(0.25, 0.3, 3.2), WOOD_DARK, L(x, 15.6, 0), houseF); part(Vector3.new(0.25, 0.3, 3.2), WOOD_DARK, L(x, 12.6, 0), houseF)
		for _, z in ipairs({-1.5, 1.5}) do part(Vector3.new(0.25, 3.3, 0.3), WOOD_DARK, L(x, 14.1, z), houseF) end
		local pane = part(Vector3.new(0.08, 2.8, 2.8), C(170, 210, 235), L(x, 14.1, 0), houseF, Enum.Material.Glass); pane.Transparency = 0.35; pane.Reflectance = 0.15
		part(Vector3.new(0.08, 2.8, 0.12), WOOD_DARK, L(x - 0.02, 14.1, 0), houseF); part(Vector3.new(0.08, 0.12, 2.8), WOOD_DARK, L(x - 0.02, 14.1, 0), houseF)
	end
	if n >= STAGES.lantern then                                             -- beside the door, under the awning
		part(Vector3.new(0.08, 1.2, 0.08), C(60, 56, 52), L(3.4, 16.4, 7.4), houseF, Enum.Material.Metal)
		part(Vector3.new(0.9, 0.18, 0.9), C(60, 56, 52), L(3.4, 15.7, 7.4), houseF, Enum.Material.Metal)
		local lamp = part(Vector3.new(0.7, 0.9, 0.7), C(255, 196, 110), L(3.4, 15.2, 7.4), houseF, Enum.Material.Neon)
		local l = Instance.new("PointLight"); l.Color = C(255, 200, 120); l.Range = 14; l.Brightness = 0.9; l.Shadows = false; l.Parent = lamp
	end
	if n >= STAGES.flag then
		part(Vector3.new(0.2, 4.4, 0.2), C(70, 60, 50), L(7.8, 12.9, 15.8), houseF, Enum.Material.Metal)        -- on the balcony's front corner post, clear of the leaves
		part(Vector3.new(0.06, 1.3, 2.3), C(196, 56, 48), L(7.8, 14.4, 14.55), houseF, Enum.Material.Fabric)
		part(Vector3.new(0.08, 0.42, 2.3), CREAM, L(7.8, 14.4, 14.55), houseF, Enum.Material.Fabric)
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
	local eye = site - toward * 34 + Vector3.new(0, 17, 0)
	local look = CFrame.lookAt(eye, site + Vector3.new(0, 4, 0))
	local from = cam.CFrame
	cam.CameraType = Enum.CameraType.Scriptable
	local t1 = TweenService:Create(cam, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = look})
	t1:Play()
	say(REVEAL_LINE, 7.5)
	task.delay(6.5, function()
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
		sound("rbxassetid://1845415163", 0.45)
		later()
		if n == 1 and not revealed then task.delay(0.6, reveal)
		elseif n >= TOTAL then say("That was the last piece!", 3)
		else say(string.format("Homebase piece %d of %d! %d more to find", n, TOTAL, TOTAL - n), 3.5) end
	elseif what == "done" then
		task.delay(0.8, function() sound("rbxassetid://1845415163", 0.7); doneCard(tonumber(a) or 100) end)
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
	for _, s in ipairs({{"TreehouseServer", SERVER}, {"TreehouseClient2", CLIENT}}) do
		local ok, f, err = pcall(function() return loadstring(s[2]) end)
		if ok and not f then print("QQ TREE ABORT: " .. s[1] .. " does not compile: " .. tostring(err)) return end
	end
end
local SITE = HttpService:JSONDecode([==[{"x":-18,"z":47,"yaw":155.5}]==])
local PIECES = HttpService:JSONDecode([==[[{"id":"p1","x":14,"z":-8,"kind":"planks","yaw":30},{"id":"p2","x":-10,"z":-42,"kind":"rope","yaw":0},{"id":"p3","x":22,"z":-46,"kind":"planks","yaw":70},{"id":"p4","x":55,"z":-14,"kind":"shingles","yaw":15},{"id":"p5","x":-12,"z":-88,"kind":"planks","yaw":100},{"id":"p6","x":86,"z":-36,"kind":"rope","yaw":40},{"id":"p7","x":58,"z":-108,"kind":"shingles","yaw":0},{"id":"p8","x":76,"z":-118,"kind":"planks","yaw":55},{"id":"p9","x":36,"z":-131,"kind":"lantern","yaw":20},{"id":"p10","x":2,"z":-144,"kind":"planks","yaw":80},{"id":"p11","x":-37,"z":-138,"kind":"shingles","yaw":10},{"id":"p12","x":72,"z":-148,"kind":"lantern","yaw":60}]]==])
local FLOOR = 0.1
local log = {}
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before Treehouse2") end)
local SX, SZ = SITE.x, SITE.z
-- ---------- 1-4: the terrain ----------
-- the back rim (the ridge fell to nothing past z ~75): grass up to y 9 from z 62 to 84, so the hollow has a bank behind it
T:FillBlock(CFrame.new((SX - 34 + SX + 34) / 2, (9 - 14) / 2, 73), Vector3.new(68, 23, 22), Enum.Material.Grass)
for _, ex in ipairs({SX - 34, SX + 34}) do T:FillBall(Vector3.new(ex, -2.5, 73), 11, Enum.Material.Grass) end   -- rounded ends, seen from the tower top
-- the floor: grass up to the forest's level under the whole hollow (the ridge's foot dips below it near the edge)
T:FillCylinder(CFrame.new(SX, (FLOOR - 8) / 2, SZ), 8 + FLOOR, 29, Enum.Material.Grass)
-- the bowl: air above the floor, WIDENING with height like an amphitheatre (the crest is y 10-14; 17 clears it)
for _, step in ipairs({{0, 4, 22.5}, {4, 8, 24}, {8, 12, 25.5}, {12, 17, 27}}) do
	local y1, y2, r = FLOOR + step[1], FLOOR + step[2], step[3]
	T:FillCylinder(CFrame.new(SX, (y1 + y2) / 2, SZ), y2 - y1, r, Enum.Material.Air)
end
-- the dirt round the oak
T:FillCylinder(CFrame.new(SX, FLOOR - 1, SZ), 2.2, 15, Enum.Material.Ground)
print(string.format("QQ TREE terrain: rim to y 9 behind z 62..84, floor at %.1f, a bowl of radius 27 cut to y 17, dirt radius 15, centred (%d, %d)", FLOOR, SX, SZ))
-- ---------- 5: the edge ----------
local edges = {}
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("BasePart") and p.Name == "Wall" and p.Size.X > 60 and math.abs(p.Position.Z - 25) < 1.5 and p.Size.Y > 40 then table.insert(edges, p) end
end
local MOUTH_L, MOUTH_R, BACK = SX - 30, SX + 30, SZ + 26                 -- the mouth's x range along the old edge, the U's back z (a stud inside the floor's face)
local edge
for _, e in ipairs(edges) do if e.Position.X - e.Size.X / 2 < MOUTH_L and e.Position.X + e.Size.X / 2 > MOUTH_R then edge = e end end   -- the one spanning the mouth
if #edges == 0 then print("QQ TREE edge: the north wall (Wall, ~233 x 1 at z 25) was NOT found - the hollow is open to the bank; tell the cloud thread")
elseif #edges > 1 and edge then print("QQ TREE edge: " .. #edges .. " wall parts at z 25; the one spanning the mouth is split") end
if edge and not edge.Parent:FindFirstChild("HollowWallBack") then
	local wf = edge.Parent
	local y, h = edge.Position.Y, edge.Size.Y
	local x1, x2 = edge.Position.X - edge.Size.X / 2, edge.Position.X + edge.Size.X / 2
	local function wall(name, cx, cz, sx, sz)
		local w = edge:Clone(); w.Name = name; w.Size = Vector3.new(sx, h, sz); w.CFrame = CFrame.new(cx, y, cz); w.Parent = wf
		return w
	end
	log.edge = {name = edge.Name, size = tostring(edge.Size), cframe = tostring(edge.CFrame)}
	wall("HollowWallBack", (MOUTH_L + MOUTH_R) / 2, BACK, MOUTH_R - MOUTH_L + 2 * edge.Size.Z, edge.Size.Z)
	wall("HollowWallLeft", MOUTH_L, (edge.Position.Z + BACK) / 2, edge.Size.Z, BACK - edge.Position.Z)
	wall("HollowWallRight", MOUTH_R, (edge.Position.Z + BACK) / 2, edge.Size.Z, BACK - edge.Position.Z)
	wall("Wall", (x1 + MOUTH_L) / 2, edge.Position.Z, MOUTH_L - x1, edge.Size.Z)          -- the old wall's west part
	edge.Size = Vector3.new(x2 - MOUTH_R, h, edge.Size.Z); edge.CFrame = CFrame.new((MOUTH_R + x2) / 2, y, edge.Position.Z)   -- the old part keeps the east
	print(string.format("QQ TREE edge: the north wall opens between x %d and %d; a U of wall round the hollow to z %d", MOUTH_L, MOUTH_R, BACK))
elseif edge then print("QQ TREE edge: already opened (HollowWallBack exists)")
elseif #edges > 0 then print("QQ TREE edge: already opened (no wall spans the mouth)") end
-- ---------- 6: the dressing on the site ----------
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local cleared = 0
local clearedF
for _, m in ipairs(workspace:GetDescendants()) do
	if m:IsA("Model") and m.Parent and m.Parent.Name == "Dressing" then
		local cf = m:GetPivot()
		if math.sqrt((cf.X - SX) ^ 2 + (cf.Z - SZ) ^ 2) <= 31 and cf.Z > 18 then
			if not clearedF then local n = 1; while hb:FindFirstChild("TreehouseCleared_" .. n) do n += 1 end; clearedF = Instance.new("Folder"); clearedF.Name = "TreehouseCleared_" .. n; clearedF.Parent = hb end
			m.Parent = clearedF; cleared += 1
		end
	end
end
print(string.format("QQ TREE dressing cleared from the site: %d%s", cleared, clearedF and (" (HudBackup." .. clearedF.Name .. ")") or ""))
-- ---------- 8: the pieces' ground (the forest - unchanged terrain, rays are fine) ----------
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
-- ---------- 7: the folder, the oak, the stones, the scripts ----------
local RS = game:GetService("ReplicatedStorage")
local old = workspace:FindFirstChild("Treehouse")
if old then
	local n = 1; while hb:FindFirstChild("Treehouse_pre_" .. n) do n += 1 end
	old.Name = "Treehouse_pre_" .. n; old.Parent = hb
	for _, s in ipairs(old:GetDescendants()) do if s:IsA("BaseScript") then s.Enabled = false end end
end
local F = Instance.new("Folder"); F.Name = "Treehouse"
F:SetAttribute("Enabled", true)
F:SetAttribute("Tree", HttpService:JSONEncode({x = SX, y = FLOOR, z = SZ, yaw = SITE.yaw}))
F:SetAttribute("Pieces", HttpService:JSONEncode(placed))
if not RS:FindFirstChild("TreehousePick") then local e = Instance.new("RemoteEvent"); e.Name = "TreehousePick"; e.Parent = RS end
local Oak = Instance.new("Model"); Oak.Name = "Oak"; Oak.Parent = F
local base = CFrame.new(SX, FLOOR, SZ) * CFrame.Angles(0, math.rad(SITE.yaw), 0)
local BARK, BARK2 = Color3.fromRGB(96, 66, 40), Color3.fromRGB(84, 56, 34)
local LEAF, LEAF2 = Color3.fromRGB(74, 124, 54), Color3.fromRGB(98, 148, 62)
local function mk(shape, size, color, cf, material, collide, parent)
	local p = Instance.new("Part"); p.Shape = shape; p.Size = size; p.Color = color; p.Material = material
	p.Anchored = true; p.CanCollide = collide == true; p.CanQuery = collide == true; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.CFrame = cf; p.Parent = parent or Oak
	return p
end
local V, B = Enum.PartType.Cylinder, Enum.PartType.Ball
mk(V, Vector3.new(7.2, 6.6, 6.6), BARK, base * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkLow"
mk(V, Vector3.new(15.4, 4.8, 4.8), BARK, base * CFrame.new(0, 14.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood, true).Name = "TrunkHigh"   -- rises through the roof (ridge y 20.75)
mk(B, Vector3.new(5, 5, 5), BARK2, base * CFrame.new(0, 22.2, 0), Enum.Material.Wood, false).Name = "Crown"
for i = 1, 5 do
	local a = math.rad(i * 72 + 20)
	mk(V, Vector3.new(4.8, 1.8, 1.8), BARK2, base * CFrame.Angles(0, a, 0) * CFrame.new(3.8, 0.55, 0) * CFrame.Angles(0, 0, math.rad(-16)), Enum.Material.Wood, true).Name = "Root"
end
for i = 1, 4 do
	local a = math.rad(i * 90 + 45)
	mk(V, Vector3.new(10, 1.6, 1.6), BARK2, base * CFrame.Angles(0, a, 0) * CFrame.new(4.4, 24.2, 0) * CFrame.Angles(0, 0, math.rad(34)), Enum.Material.Wood, false).Name = "Branch"
end
for i = 1, 6 do
	local a = math.rad(i * 60)
	mk(B, Vector3.new(12, 12, 12), (i % 2 == 0) and LEAF or LEAF2, base * CFrame.new(7.2 * math.sin(a), 28.2, 7.2 * math.cos(a)), Enum.Material.Grass, false).Name = "Leaves"
end
mk(B, Vector3.new(11, 11, 11), LEAF, base * CFrame.new(0, 32.4, 0), Enum.Material.Grass, false).Name = "Leaves"
mk(B, Vector3.new(8.5, 8.5, 8.5), LEAF2, base * CFrame.new(11.5 * math.sin(math.rad(30)), 25.6, 11.5 * math.cos(math.rad(30))), Enum.Material.Grass, false).Name = "Leaves"
mk(B, Vector3.new(8.5, 8.5, 8.5), LEAF, base * CFrame.new(11.5 * math.sin(math.rad(210)), 25.2, 11.5 * math.cos(math.rad(210))), Enum.Material.Grass, false).Name = "Leaves"
-- the ring of stones at the dirt's edge, a gap at the mouth for the path in
local Stones = Instance.new("Model"); Stones.Name = "Stones"; Stones.Parent = F
local STONE = Color3.fromRGB(150, 146, 138)
for i = 0, 9 do
	local a = math.rad(i * 36 + 18)
	local dgap = (i * 36 + 18 + 180) % 360 - 180
	if math.abs(dgap) > 30 then                                           -- the gap at the mouth (local +z), for the path in
		local s = mk(B, Vector3.new(2.4 + (i % 3) * 0.5, 1.6 + (i % 2) * 0.4, 2.2 + (i % 3) * 0.4), STONE, base * CFrame.new(15.2 * math.sin(a), 0.4, 15.2 * math.cos(a)) * CFrame.Angles(0, a, math.rad(10)), Enum.Material.Slate, true, Stones)
		s.Name = "Stone"
	end
end
local s = Instance.new("Script"); s.Name = "TreehouseServer"; s.RunContext = Enum.RunContext.Server; s.Source = SERVER; s.Parent = F
local c = Instance.new("Script"); c.Name = "TreehouseClient"; c.RunContext = Enum.RunContext.Client; c.Source = CLIENT; c.Parent = F
F.Parent = workspace
local lv = hb:FindFirstChild("Treehouse2_log") or Instance.new("StringValue"); lv.Name = "Treehouse2_log"; lv.Parent = hb
log.site = {x = SX, z = SZ, floor = FLOOR, bowl = 27, rim = "z 62..84 to y 9", mouth = {MOUTH_L, MOUTH_R}, back = BACK}; log.cleared = clearedF and clearedF.Name or nil
lv.Value = HttpService:JSONEncode(log)
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after Treehouse2") end)
print(string.format("QQ TREE DONE: Homebase Treehouse at (%d, %.1f, %d) yaw %.1f in its hollow; %d pieces placed%s; TreehouseServer %d, TreehouseClient %d chars%s",
	SX, FLOOR, SZ, SITE.yaw, #placed, #skipped > 0 and (", skipped " .. table.concat(skipped, ", ")) or "", #s.Source, #c.Source, old and ("; the old folder is HudBackup." .. old.Name) or ""))
