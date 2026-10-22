-- wall1 (Oct 22 2026): your portrait on your treehouse wall + the Treehouse tab's WALL and ROOMMATE rows. Shannon: "when you
-- sit for a portrait, that portrait gets put on the wall in the treehouse (as well as on the easel by the river). I should also
-- be put in the treehouse menu so you can store it to put something else up if you want or keep it hanging there." + "you
-- don't need the name plaque under it because they know who it is" + "under the treehouse tab, we could also include gordo
-- with a button of 'evict Gordo' in case the player does not want him there, there could be another button to 'Invite Gordo
-- Back'". Previewed in play tests (a real sitting, the wall, Store / Hang, Evict with his parting line once the Passport
-- closes, Invite back with his welcome-back line) and approved: "Install the portrait wall and the Wall and Roommate rows
-- in the Treehouse tab, with backups."
--   PortraitServer: names your newest painting on you (PortraitWallKey / PortraitWallVariant) when it is hung and when you
--     join (from the easels' list, or your paid sitting's saved likeness - a READ of the painter's own store, never a write),
--     and keeps that painting's model while you are in the server.
--   DecorServer: "wall" store / hang (Item_wall_bare) and "gordo" evict / invite (Item_gordo_out), through RS.AwardItems.
--   DecorClient: the WALL and ROOMMATE rows under the rugs; the subtitle mentions the portrait.
--   workspace.Gordo: GordoClient (evicted = his parting line then off; invited back = Lines.welcomeBack), Lines (+2 lines).
--   workspace.Treehouse.WallClient (new, RunContext Client): the painting on the back wall, as the easel paints it.
-- Run in Studio EDIT. Backs each changed script up to ServerStorage.HudBackup (<name>_pre_wall1) first.
local SES = game:GetService("ScriptEditorService")
local backup = game:GetService("ServerStorage"):FindFirstChild("HudBackup")
assert(backup, "no ServerStorage.HudBackup")
assert(not workspace.Treehouse:FindFirstChild("WallClient"), "WallClient already exists - nothing changed")
local function patched(script, edits)
	local src = script.Source
	assert(not src:find("(wall1", 1, true), script.Name .. " already patched")
	for _, e in ipairs(edits) do
		local a, b = src:find(e[1], 1, true)
		assert(a, script.Name .. ": " .. e[3] .. " not found - nothing changed")
		assert(not src:find(e[1], b + 1, true), script.Name .. ": " .. e[3] .. " found twice - nothing changed")
		src = src:sub(1, a - 1) .. e[2] .. src:sub(b + 1)
	end
	return src
end
local ps = workspace.PortraitGallery.PortraitServer
local psSrc = patched(ps, {
	{[==[local wanted={};for _,e in ipairs(list)do wanted[portraitKey(e)]=true end]==],
	 [==[local wanted={};for _,e in ipairs(list)do wanted[portraitKey(e)]=true end
  for _,p in ipairs(Players:GetPlayers())do local k=p:GetAttribute("PortraitWallKey");if k then wanted[k]=true end end   -- (wall1) a treehouse wall's painting stays]==], "the retire list"},
	{[==[show();retireUnusedModels()]==],
	 [==[if player.Parent then player:SetAttribute("PortraitWallKey",model.Name);player:SetAttribute("PortraitWallVariant",tonumber(entry.variant)or 0)end   -- (wall1) the newest painting also hangs in the sitter's treehouse
 show();retireUnusedModels()]==], "the hang"},
	{[==[Players.PlayerAdded:Connect(function(p)task.spawn(owed,p)end)
for _,p in ipairs(Players:GetPlayers())do task.spawn(owed,p)end]==],
	 [==[-- (wall1, Oct 22 2026) the treehouse wall (Shannon: "when you sit for a portrait, that portrait gets put on the wall in the
-- treehouse (as well as on the easel by the river)"): your newest painting - still on the easels, or your paid sitting's
-- saved likeness (the pending receipt, read only, paid when its target is within your purchases) - is prepared and named
-- on you (PortraitWallKey / PortraitWallVariant); WallClient hangs it
local function wallPortrait(player)
 while player.Parent and not(player:GetAttribute("SaveLoaded")and listLoaded)do task.wait(.5)end
 if not player.Parent or item(player,"portrait")<=0 or player:GetAttribute("PortraitWallKey")then return end
 local entry
 for _,e in ipairs(list)do if tonumber(e.id)==player.UserId then entry=e;break end end
 if not entry and store then
  local ok,receipt=pcall(function()return store:GetAsync(pendingKey(player.UserId))end)
  if ok and type(receipt)=="table"and type(receipt.entry)=="table"and tonumber(receipt.target)and receipt.target<=item(player,"portrait")then entry=receipt.entry end
 end
 if not entry then return end
 local ok,model=pcall(prepareModel,entry)
 if ok and player.Parent and not player:GetAttribute("PortraitWallKey")then
  player:SetAttribute("PortraitWallKey",model.Name);player:SetAttribute("PortraitWallVariant",tonumber(entry.variant)or 0)
 end
end
Players.PlayerAdded:Connect(function(p)task.spawn(owed,p);task.spawn(wallPortrait,p)end)
for _,p in ipairs(Players:GetPlayers())do task.spawn(owed,p);task.spawn(wallPortrait,p)end]==], "the join"},
})
local ds = workspace.Treehouse.DecorServer
local dsSrc = patched(ds, {
	{[==[	elseif what == "tip" then]==],
	 [==[	elseif what == "wall" then                                   -- (wall1) your portrait on the treehouse wall: Store / Hang
		local bare = tonumber(p:GetAttribute("Item_wall_bare")) or 0
		if id == "store" then if bare < 1 then award:Fire(p, "wall_bare", 1) end return true end
		if id == "hang" then if bare > 0 then award:Fire(p, "wall_bare", -1) end return true end
		return false, "?"
	elseif what == "gordo" then                                  -- (wall1) Gordo the roommate: Evict / Invite back
		if (tonumber(p:GetAttribute("Item_gordo_home")) or 0) < 1 then return false, "no roommate yet" end
		local out = tonumber(p:GetAttribute("Item_gordo_out")) or 0
		if id == "evict" then if out < 1 then award:Fire(p, "gordo_out", 1) end return true end
		if id == "invite" then if out > 0 then award:Fire(p, "gordo_out", -1) end return true end
		return false, "?"
	elseif what == "tip" then]==], "the tip action"},
})
local dc = workspace.Treehouse.DecorClient
local dcSrc = patched(dc, {
	{[==[label("Place a rug on the floor, or store it for later.", 3, 24, 420, 16, 13, C(110, 70, 30), Enum.Font.BuilderSans)]==],
	 [==[label("Place a rug, hang your portrait, or store them for later.", 3, 24, 420, 16, 13, C(110, 70, 30), Enum.Font.BuilderSans)   -- (wall1)]==], "the subtitle"},
	{[==[label("Decor you find or buy out in the game appears here.", 3, 72 + #RUGS * 60 + 8, 460, 16, 12, MUTED, Enum.Font.BuilderSans)
list.CanvasSize = UDim2.fromOffset(0, 72 + #RUGS * 60 + 8 + 16 + 8)   -- (hud34) the list's full height]==],
	 [==[-- (wall1, Oct 22 2026) two more rows under the rugs, through DecorServer:
--   WALL - your portrait from the river painter hangs on the treehouse's back wall (WallClient); Shannon: "store it to put
--     something else up if you want or keep it hanging there". Store / Hang ("wall"; Item_wall_bare, like rug_bare).
--   ROOMMATE - once Gordo has moved in: "include gordo with a button of 'evict Gordo' in case the player does not want him
--     there, there could be another button to 'Invite Gordo Back'" ("gordo"; Item_gordo_out = 1 while he is out).
local function row(name, y, buttonW)
	local r = Instance.new("Frame"); r.Name = name; r.Position = UDim2.fromOffset(3, y); r.Size = UDim2.new(1, -10, 0, 52)
	r.BackgroundColor3 = C(255, 255, 255); r.BackgroundTransparency = 0.35; r.BorderSizePixel = 0; r.ZIndex = 4; r.Parent = list
	round(r, 12)
	local nm = Instance.new("TextLabel"); nm.Name = "Title"; nm.Position = UDim2.fromOffset(56, 7); nm.Size = UDim2.fromOffset(220, 18)
	nm.BackgroundTransparency = 1; nm.Font = FONT; nm.TextSize = 15; nm.TextColor3 = INK
	nm.TextXAlignment = Enum.TextXAlignment.Left; nm.ZIndex = 5; nm.Parent = r
	local tag = Instance.new("TextLabel"); tag.Name = "Tag"; tag.Position = UDim2.fromOffset(56, 27); tag.Size = UDim2.new(1, -(76 + buttonW), 0, 15)
	tag.BackgroundTransparency = 1; tag.Font = FONT; tag.TextSize = 12; tag.TextColor3 = MUTED; tag.Text = ""; tag.TextTruncate = Enum.TextTruncate.AtEnd
	tag.TextXAlignment = Enum.TextXAlignment.Left; tag.ZIndex = 5; tag.Parent = r
	local b = Instance.new("TextButton"); b.AnchorPoint = Vector2.new(1, 0); b.Position = UDim2.new(1, -10, 0, 10)
	b.Size = UDim2.fromOffset(buttonW, 32); b.BackgroundColor3 = C(245, 170, 60); b.Font = FONT; b.TextSize = 15
	b.TextColor3 = INK; b.Text = ""; b.AutoButtonColor = true; b.ZIndex = 5; b.Parent = r
	round(b, 10)
	local bs = Instance.new("UIStroke"); bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; bs.Color = C(200, 150, 90); bs.Thickness = 1.5; bs.Parent = b
	return r, nm, tag, b
end
local wy = 72 + #RUGS * 60 + 6
label("WALL", 3, wy, 100, 14, 12, MUTED)
local wrow, wnm, wtag, wb = row("WallRow", wy + 20, 86)
wnm.Text = "Your portrait"
local mini = Instance.new("ImageLabel"); mini.Position = UDim2.fromOffset(10, 6); mini.Size = UDim2.fromOffset(34, 40)   -- a little gilt-framed likeness
mini.BackgroundColor3 = C(246, 240, 226); mini.BorderSizePixel = 0; mini.ZIndex = 5; mini.ScaleType = Enum.ScaleType.Crop
mini.Image = "rbxthumb://type=AvatarBust&id=" .. player.UserId .. "&w=150&h=150"; mini.Parent = wrow
local ms = Instance.new("UIStroke"); ms.Color = C(214, 176, 60); ms.Thickness = 2.5; ms.Parent = mini
local gy = wy + 20 + 52 + 8
local ghead = label("ROOMMATE", 3, gy, 120, 14, 12, MUTED)
local grow, gnm, gtag, gb = row("GordoRow", gy + 20, 150)
gnm.Text = "Gordo"
local gface = Instance.new("ViewportFrame"); gface.Position = UDim2.fromOffset(8, 6); gface.Size = UDim2.fromOffset(40, 40)   -- his face, framed like his note's
gface.BackgroundColor3 = C(206, 230, 242); gface.BorderSizePixel = 0; gface.ZIndex = 5; gface.Ambient = C(190, 190, 200)
gface.LightColor = C(255, 250, 240); gface.LightDirection = Vector3.new(-0.4, -1, -0.6); gface.Parent = grow
round(gface, 20)
local gfs = Instance.new("UIStroke"); gfs.Color = C(120, 76, 36); gfs.Thickness = 1.5; gfs.Parent = gface
task.spawn(function()
	local src = RS:WaitForChild("GordoHome", 120)
	if not src then return end
	local copy = src:Clone(); copy.CFrame = CFrame.new(); copy.Parent = gface
	local bones = {}
	for _, bn in ipairs(copy:GetDescendants()) do if bn:IsA("Bone") then bones[bn.Name] = bn end end
	local head = bones.Head and bones.Head.WorldPosition or copy.Position
	local root = bones.Root and bones.Root.WorldPosition or copy.Position
	local f = head - root; f = Vector3.new(f.X, 0, f.Z)
	f = f.Magnitude > 0.05 and f.Unit or Vector3.new(0, 0, -1)
	local reach = copy.Size.Magnitude
	local target = head + Vector3.new(0, reach * 0.07, 0)
	local cam = Instance.new("Camera"); cam.FieldOfView = 30; cam.Parent = gface; gface.CurrentCamera = cam
	cam.CFrame = CFrame.lookAt(target + f * reach * 0.72 + Vector3.new(0, reach * 0.04, 0), target)
end)
local foot = label("Decor you find or buy out in the game appears here.", 3, 0, 460, 16, 12, MUTED, Enum.Font.BuilderSans)
local function item(id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function refreshMore()
	-- the wall
	local has = player:GetAttribute("PortraitWallKey") ~= nil
	local up = item("wall_bare") < 1
	mini.ImageTransparency = has and 0 or 0.6
	wb.Visible = has
	if has then
		wtag.Text = up and "On the wall" or "Stored"
		wtag.TextColor3 = up and C(64, 112, 48) or MUTED
		wb.Text = up and "Store" or "Hang"
		wb.BackgroundColor3 = up and C(236, 226, 206) or C(245, 170, 60)
	else
		wtag.Text = item("portrait") > 0 and "Being framed..." or "Sit for one with the painter by the river"
		wtag.TextColor3 = MUTED
	end
	-- Gordo, once he has moved in (before that the row stays hidden: Italy keeps its surprise)
	local moved = item("gordo_home") >= 1
	local home = item("gordo_out") < 1
	ghead.Visible = moved; grow.Visible = moved
	gface.ImageTransparency = home and 0 or 0.5
	gtag.Text = home and "Watching your house" or "Back in the forest, sulking"
	gtag.TextColor3 = home and C(64, 112, 48) or MUTED
	gb.Text = home and "Evict Gordo" or "Invite Gordo back"
	gb.BackgroundColor3 = home and C(236, 226, 206) or C(245, 170, 60)
	local fy = (moved and gy + 20 + 52 or gy) + 8
	foot.Position = UDim2.fromOffset(3, fy)
	list.CanvasSize = UDim2.fromOffset(0, fy + 16 + 8)   -- (hud34) the list's full height
end
local function press(what, id)
	if busy then return end
	busy = true
	pcall(function() act:InvokeServer(what, id) end)
	task.wait(0.2)
	busy = false
	refreshMore()
end
wb.Activated:Connect(function() press("wall", item("wall_bare") < 1 and "store" or "hang") end)
gb.Activated:Connect(function() press("gordo", item("gordo_out") < 1 and "evict" or "invite") end)
player.AttributeChanged:Connect(function(name)
	if name == "Item_wall_bare" or name == "PortraitWallKey" or name == "Item_portrait" or name == "Item_gordo_home" or name == "Item_gordo_out" then refreshMore() end
end)
refreshMore()]==], "the footer"},
})
local gc = workspace.Gordo.GordoClient
assert(gc.Source:find("gordo1, Oct 22", 1, true) and not gc.Source:find("(wall1", 1, true), "GordoClient is not the gordo1 one - nothing changed")
local gl = workspace.Gordo.Lines
local glSrc = patched(gl, {
	{[==[	-- whenever you come home after that (one of these)]==],
	 [==[	-- (wall1) when you evict him from the Treehouse tab (if he is in sight), and his greeting when you invite him back
	evicted = "Fine! I'm going. I'm taking the snacks. All of them.",
	welcomeBack = "I knew you'd miss me! I brought snacks. I ate them on the way.",
	-- whenever you come home after that (one of these)]==], "the greets heading"},
})
for _, s in ipairs({ps, ds, dc, gc, gl}) do
	local b = s:Clone(); b.Name = s.Name .. "_pre_wall1"
	if b:IsA("Script") then b.Enabled = false end
	b.Parent = backup
end
SES:UpdateSourceAsync(ps, function() return psSrc end)
SES:UpdateSourceAsync(ds, function() return dsSrc end)
SES:UpdateSourceAsync(dc, function() return dcSrc end)
SES:UpdateSourceAsync(gl, function() return glSrc end)
SES:UpdateSourceAsync(gc, function() return [==[
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
]==] end)
local wc = Instance.new("Script"); wc.Name = "WallClient"; wc.RunContext = Enum.RunContext.Client; wc.Parent = workspace.Treehouse
SES:UpdateSourceAsync(wc, function() return [==[
-- WallClient (workspace.Treehouse, RunContext Client; wall1, Oct 22 2026): your portrait on your treehouse wall. Shannon:
-- "when you sit for a portrait, that portrait gets put on the wall in the treehouse (as well as on the easel by the
-- river)" + in the Treehouse menu "so you can store it to put something else up if you want or keep it hanging there"
-- (DecorClient's WALL row; Item_wall_bare = 1 is a stored portrait, like the rugs' rug_bare).
-- PortraitServer keeps your newest painting's model in RS.PortraitGalleryModels and names it on you (PortraitWallKey,
-- PortraitWallVariant); this draws it the way the river easel does - the easel's own Picture (its scene, the 3D sitter,
-- the companion, the wash) on a canvas in a gilt frame, centred on the back wall facing the door, above Gordo's head (no
-- name plaque: "they know who it is"). Drawn on this screen only, like the house (ViewportFrames show on a world surface
-- only from a SurfaceGui in PlayerGui - PortraitClient's own rule).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local TH = script.Parent
local G = workspace:WaitForChild("PortraitGallery", 60)
local portraitModels = RS:WaitForChild("PortraitGalleryModels", 60)
if not (G and portraitModels) then return end
local C = Color3.fromRGB
local VR = UIS.VREnabled                                          -- (PortraitClient: VR draws ViewportFrames unreliably - the bust picture stands in)
local function J(name)
	local ok, t = pcall(function() return HttpService:JSONDecode(TH:GetAttribute(name) or "") end)
	return (ok and type(t) == "table") and t or nil
end
local TREE, PIECES = J("Tree"), J("Pieces") or {}
if not (TREE and tonumber(TREE.x) and tonumber(TREE.y) and tonumber(TREE.z)) then return end
local base = CFrame.new(TREE.x, TREE.y, TREE.z) * CFrame.Angles(0, math.rad(tonumber(TREE.yaw) or 0), 0)   -- TreehouseClient's frame: +z faces the spawn
local function L(x, y, z) return base * CFrame.new(x, y, z) end
local WALLS = math.max(4, math.round(#PIECES * 0.58))            -- (TreehouseClient's STAGES.walls)
local function item(id) return tonumber(player:GetAttribute("Item_" .. id)) or 0 end
local function roomUp()
	local n = 0
	for _, pc in ipairs(PIECES) do if item("tree_" .. tostring(pc.id)) >= 1 then n += 1 end end
	return n >= WALLS
end

-- ---------- the painting, as the river easel paints it (PortraitClient's frameViewport / portraitComplete /
-- renderPreparedLook / configurePicture, the same steps) ----------
local function frameViewport(vp, model)
	if not vp or not model or not model:FindFirstChild("Head") then return false end
	local cam = vp:FindFirstChild("PortraitCamera")
	if not cam then cam = Instance.new("Camera"); cam.Name = "PortraitCamera"; cam.FieldOfView = 28; cam.Parent = vp end
	local points = {}; local low = Vector3.new(math.huge, math.huge, math.huge); local high = -low
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < .99 then
			for _, x in ipairs({-1, 1}) do for _, y in ipairs({-1, 1}) do for _, z in ipairs({-1, 1}) do
				local p = part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2)
				points[#points + 1] = p; low = low:Min(p); high = high:Max(p)
			end end end
		end
	end
	if #points == 0 then return false end
	local focus = (low + high) / 2
	local direction = Vector3.new(.18, .06, -1).Unit
	local orientation = CFrame.lookAt(focus + direction, focus).Rotation
	local aspect = vp.AbsoluteSize.Y > 0 and vp.AbsoluteSize.X / vp.AbsoluteSize.Y or .78
	local tanY = math.tan(math.rad(cam.FieldOfView / 2)); local tanX = tanY * math.max(.1, aspect)
	local dist = 0
	for _, p in ipairs(points) do
		local lp = orientation:VectorToObjectSpace(p - focus)
		dist = math.max(dist, math.abs(lp.X) / tanX + lp.Z, math.abs(lp.Y) / tanY + lp.Z)
	end
	dist *= 1.10
	local torso = model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
	if model:GetAttribute("PortraitCrop") == "waist" and torso then
		local waist = torso.Position.Y - torso.Size.Y / 2
		local height = math.max(model.Head.Size.Y * 1.6, high.Y - waist)
		focus = Vector3.new(torso.Position.X, waist + height / 2, focus.Z)
		dist = height / (2 * tanY) * 1.10
	end
	cam.CFrame = CFrame.lookAt(focus + direction * dist, focus)
	vp.CurrentCamera = cam; vp.Visible = true
	return true
end
local function portraitComplete(model)
	if not model or not model:FindFirstChild("Head") or not model:FindFirstChild("HumanoidRootPart") then return false end
	local expected = model:GetAttribute("PortraitPartCount")
	if type(expected) ~= "number" then return false end
	local count, visualCount = 0, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then count += 1 end
		if d:IsA("BasePart") or d:IsA("DataModelMesh") or d:IsA("Decal") or d:IsA("SurfaceAppearance") then visualCount += 1 end
	end
	return count >= expected and visualCount >= (model:GetAttribute("PortraitVisualCount") or math.huge)
end
local function renderPreparedLook(vp, key)
	if not vp or type(key) ~= "string" then return false end
	local world = vp:FindFirstChild("World"); if not world then return false end
	local model, deadline = nil, os.clock() + 20
	repeat
		model = portraitModels:FindFirstChild(key)
		if portraitComplete(model) then break end
		task.wait(.1)
	until os.clock() > deadline
	if not portraitComplete(model) then return false end
	world:ClearAllChildren()
	local copy = model:Clone(); copy.Name = "PaintedSitter"; copy.Parent = world
	return frameViewport(vp, copy)
end
local function configurePicture(gui, e)
	local img, wash = gui:FindFirstChild("Portrait"), gui:FindFirstChild("Wash")
	local vp = gui:FindFirstChild("Portrait3D")
	local back, over = gui:FindFirstChild("Backdrop"), gui:FindFirstChild("Overlay")
	-- the same turn of scene and companion as the easel (PortraitServer show)
	local id = tonumber(e.id) or 0
	local turn = tonumber(e.variant) or 0
	local scene = ((id + turn) % 5) + 1
	local buddy = ((math.floor(id / 7) + turn) % 5) + 1           -- 5 = alone
	local sf = G:FindFirstChild("Scenes") and G.Scenes:FindFirstChild("Scene" .. scene)
	local sitX, sitS = (sf and sf:GetAttribute("SitX")) or 0.5, (sf and sf:GetAttribute("SitScale")) or 1
	img.Size = UDim2.fromScale(sitS, sitS); img.Position = UDim2.fromScale(sitX - sitS / 2, 1 - sitS)
	if vp then vp.Size = img.Size; vp.Position = img.Position end
	local side = (sitX < 0.45 and -1) or (sitX > 0.55 and 1) or 0
	local DRAWN = {[2] = 1, [3] = -1, [4] = 1}                       -- the side each corner companion was drawn on
	local want = "Buddy" .. buddy .. ((side ~= 0 and DRAWN[buddy] == side) and "M" or "")
	if back then back:ClearAllChildren(); if sf then local sc = sf:Clone(); sc.Visible = true; sc.Parent = back end end
	if over then for _, c in ipairs(over:GetChildren()) do c.Visible = (c.Name == want) end end
	local b1 = img:FindFirstChild("Buddy1"); if b1 then b1.Visible = (buddy == 1) end
	img.Image = ""; img.Visible = true; wash.Visible = true
	if VR then                                                    -- (the bust picture stands in for the 3D sitter)
		if vp then vp.Visible = false end
		img.Image = "rbxthumb://type=AvatarBust&id=" .. tostring(e.id) .. "&w=420&h=420"
		return true
	end
	return renderPreparedLook(vp, e.modelKey)
end

-- ---------- the frame on the wall ----------
-- the canvas 1.5 times the easel's (2.3 x 2), on the back wall's inner face (z -9.3), its middle 5.6 above the floor
-- (y 10.5): over Gordo's head when he is in, clear of the table and the windows; the easel's Picture is laid out for
-- 140 pixels a stud, so at 1.5 times the size it gets 140 / 1.5 and looks exactly the same
local SCALE = 1.5
local CW, CH = 2.3 * SCALE, 2.0 * SCALE
local MIDY, WALLZ = 16.1, -9.3
local GOLD = C(214, 176, 60)                                       -- (the river gallery's gilt)
local pictures = pg:FindFirstChild("TreehouseWall") or Instance.new("Folder")
pictures.Name = "TreehouseWall"; pictures.Parent = pg
local hung, hungKey
local function part(size, colour, cf, parent, material)
	local p = Instance.new("Part"); p.Size = size; p.Color = colour; p.Material = material or Enum.Material.Metal
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.CFrame = cf; p.Parent = parent
	return p
end
local function takeDown()
	if hung then hung:Destroy(); hung = nil end
	pictures:ClearAllChildren()
	hungKey = nil
end
local function hang()
	local key = player:GetAttribute("PortraitWallKey")
	if not (key and roomUp() and item("wall_bare") < 1) then takeDown() return end
	local lf = workspace:FindFirstChild("Treehouse_local")
	if not lf then return end
	if hungKey == key and hung and hung.Parent then return end
	local slot1 = G:FindFirstChild("Slots") and G.Slots:FindFirstChild("Slot1")
	local easel = slot1 and slot1:FindFirstChild("Canvas", true)
	local template = easel and easel:FindFirstChild("Picture")
	if not template then return end
	takeDown()
	local m = Instance.new("Model"); m.Name = "WallPortrait"
	local canvas = part(Vector3.new(CW, CH, 0.08), C(246, 240, 226), L(0, MIDY, WALLZ + 0.05), m, Enum.Material.SmoothPlastic)
	canvas.Name = "Canvas"                                        -- (its Back face, +z, looks into the room: the easel's Picture is on Back too)
	local t, d, z = 0.21, 0.21, WALLZ + 0.1
	for _, sx in ipairs({-1, 1}) do
		part(Vector3.new(t, CH + 2 * t, d), GOLD, L(sx * (CW / 2 + t / 2), MIDY, z), m)
		part(Vector3.new(CW + 2 * t, t, d), GOLD, L(0, MIDY + sx * (CH / 2 + t / 2), z), m)
	end
	m.Parent = lf                                                 -- (no name plaque - Shannon: "they know who it is")
	hung, hungKey = m, key
	local pic = template:Clone(); pic.Name = "WallPicture"; pic.Adornee = canvas; pic.Enabled = true; pic.ResetOnSpawn = false
	pic.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; pic.PixelsPerStud = (template.PixelsPerStud or 140) / SCALE
	pic.Parent = pictures
	task.spawn(function()
		local ok = configurePicture(pic, {id = player.UserId, variant = player:GetAttribute("PortraitWallVariant") or 0, modelKey = key})
		if not ok and pic.Parent then                             -- (the painting's model never came: the bust picture instead)
			local vp = pic:FindFirstChild("Portrait3D"); if vp then vp.Visible = false end
			local img = pic:FindFirstChild("Portrait")
			if img then img.Image = "rbxthumb://type=AvatarBust&id=" .. player.UserId .. "&w=420&h=420"; img.Visible = true end
		end
	end)
end
player.AttributeChanged:Connect(function(n)
	if n == "PortraitWallKey" or n == "PortraitWallVariant" or n == "Item_wall_bare" or n:sub(1, 10) == "Item_tree_" then
		if n == "PortraitWallVariant" then hungKey = nil end
		task.defer(hang)
	end
end)
task.spawn(function()
	workspace:WaitForChild("Treehouse_local", 120)
	while true do hang(); task.wait(5) end                        -- (a reset round can take the room away)
end)
print("WallClient: ready - your portrait on the treehouse's back wall")
]==] end)
local probe = gl:Clone(); probe.Parent = game:GetService("ServerStorage")   -- (a fresh copy: Edit caches the first require of Lines)
local ok, L = pcall(require, probe)
probe:Destroy()
assert(ok and L.evicted and L.welcomeBack, "Gordo's Lines did not load: " .. tostring(L))
print(string.format("wall1: PortraitServer %d, DecorServer %d, DecorClient %d, GordoClient %d, Lines %d, WallClient %d chars", #ps.Source, #ds.Source, #dc.Source, #gc.Source, #gl.Source, #wc.Source))
return "wall1 installed"
