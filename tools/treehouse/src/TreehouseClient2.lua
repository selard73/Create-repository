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
local HOUSE_DZ = 4                                                       -- (round 2: the house sits 4 studs forward of the trunk, so the trunk stands at the back of the room, not in the doorway)
local function L(x, y, z, rx, ry, rz) return base * CFrame.new(x, y, z + HOUSE_DZ) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0)) end
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
