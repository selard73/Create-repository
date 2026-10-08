"""Builds Squirrels.rbxmx: Folder "SquirrelScripts" with
  SquirrelSetup (server): finds every rigged squirrel (bones Root+Tail2), pairs each colour model with its gray twin
      (name contains "gray"), keeps the colour model, stores both texture ids as attributes, starts it gray,
      tags it "Squirrel", and handles finds (click by default; FindBy attribute) per player (attribute PerPlayer on the folder) or shared.
  SquirrelAnim (client): idle bones every frame (breathe, look-around, tail sway + flick),
      and the reveal (texture swap + sparkle + hop + sound) when the server says this player found one.
Run: python make_squirrel_scripts.py   then in Studio: right-click Workspace > Insert from file > Squirrels.rbxmx
"""
from pathlib import Path
import xml.dom.minidom as m
OUT = Path(__file__).parent / "Squirrels.rbxmx"

COMMON = r'''
local function isSquirrelMesh(p)
	return p:IsA("MeshPart") and p:FindFirstChild("Tail2", true) ~= nil and p:FindFirstChild("Root", true) ~= nil
end
local function getTex(mesh)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then return sa.ColorMap end
	return mesh.TextureID
end
local function setTex(mesh, id)
	local sa = mesh:FindFirstChildOfClass("SurfaceAppearance")
	if sa then sa.ColorMap = id else mesh.TextureID = id end
end
'''

SETUP = r'''
-- SquirrelSetup (server)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local folder = script.Parent
''' + COMMON + r'''
if folder:GetAttribute("FoundSound") == nil then folder:SetAttribute("FoundSound", "rbxassetid://1845415163") end
if folder:GetAttribute("NameTagSeconds") == nil then folder:SetAttribute("NameTagSeconds", 3.2) end
if folder:GetAttribute("MaskImage") == nil then folder:SetAttribute("MaskImage", "rbxassetid://77268792392056") end   -- white square, transparent circle
local PER_PLAYER = folder:GetAttribute("PerPlayer")
if PER_PLAYER == nil then PER_PLAYER = true; folder:SetAttribute("PerPlayer", true) end
local TARGET_HEIGHT = folder:GetAttribute("TargetHeight") or 2.9      -- studs tall; the meshes come in at 2.4
folder:SetAttribute("TargetHeight", TARGET_HEIGHT)

local ev = ReplicatedStorage:FindFirstChild("SquirrelFound") or Instance.new("RemoteEvent")
ev.Name = "SquirrelFound"; ev.Parent = ReplicatedStorage
local sync = ReplicatedStorage:FindFirstChild("SquirrelSync") or Instance.new("RemoteFunction")
sync.Name = "SquirrelSync"; sync.Parent = ReplicatedStorage

-- 1. collect every squirrel mesh in the Workspace
local meshes = {}
for _, p in ipairs(workspace:GetDescendants()) do if isSquirrelMesh(p) then table.insert(meshes, p) end end
local function modelOf(mesh) return mesh:FindFirstAncestorOfClass("Model") or mesh end
local function baseName(inst)
	local n = string.lower(modelOf(inst).Name .. " " .. inst.Name)
	n = n:gsub("_gray", ""):gsub("gray", ""):gsub("_color", ""):gsub("color", ""):gsub("%s+", " ")
	return n
end
local function isGray(inst) return string.find(string.lower(modelOf(inst).Name .. " " .. inst.Name), "gray") ~= nil end

-- 2. pair colour + gray by base name (fallback: identical mesh size)
local grays, colours = {}, {}
for _, mesh in ipairs(meshes) do
	if mesh:GetAttribute("GrayTexture") then table.insert(colours, mesh)          -- already set up (saved place)
	elseif isGray(mesh) then table.insert(grays, mesh) else table.insert(colours, mesh) end
end
for _, c in ipairs(colours) do
	if not c:GetAttribute("GrayTexture") then
		local twin
		for i, g in ipairs(grays) do
			if baseName(g) == baseName(c) then twin = g; table.remove(grays, i); break end
		end
		if not twin then
			for i, g in ipairs(grays) do
				if (g.Size - c.Size).Magnitude < 0.01 * c.Size.Magnitude then twin = g; table.remove(grays, i); break end
			end
		end
		if twin then
			c:SetAttribute("GrayTexture", getTex(twin)); c:SetAttribute("ColorTexture", getTex(c))
			modelOf(twin).Parent = nil
			print("SquirrelSetup: paired", modelOf(c):GetFullName(), "with its gray twin")
		else
			c:SetAttribute("ColorTexture", getTex(c))
			warn("SquirrelSetup: no gray twin found for " .. modelOf(c):GetFullName() .. " (import the _gray FBX too, name must contain 'gray'); it will start in colour")
		end
	end
end
for _, g in ipairs(grays) do warn("SquirrelSetup: unpaired gray squirrel " .. modelOf(g):GetFullName()) end

-- display names (shown on the floating tag when found); matched against the model name, first hit wins.
-- Set a DisplayName attribute on a squirrel model to override.
-- the registry: names, bios, maps, framing. Edit SquirrelRegistry, not this script.
local Registry = require(folder:WaitForChild("SquirrelRegistry"))
local byId = {}
for _, e in ipairs(Registry.squirrels) do byId[e.id] = e end
local THIS_MAP = folder:GetAttribute("MapId") or "forest"
folder:SetAttribute("MapId", THIS_MAP)
local function baseId(model)
	local n = model.Name:lower():gsub("_color$", ""):gsub("_gray$", "")
	return n
end
-- 3. set each one up
local squirrels = {}     -- id -> mesh
local function setup(mesh)
	local model = modelOf(mesh)
	local entry = byId[baseId(model)]
	if entry then
		model:SetAttribute("SquirrelId", entry.id)
		if not model:GetAttribute("DisplayName") then model:SetAttribute("DisplayName", entry.name) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", entry.bio or "") end
	else
		warn("SquirrelSetup: " .. model.Name .. " is not in SquirrelRegistry; add it there (id = '" .. baseId(model) .. "')")
		if not model:GetAttribute("SquirrelId") then model:SetAttribute("SquirrelId", baseId(model)) end
		if not model:GetAttribute("Bio") then model:SetAttribute("Bio", "A squirrel of mystery. Nobody knows where they came from, least of all them.") end
	end
	if model == mesh then     -- bare MeshPart: wrap it so ScaleTo / PivotTo work
		local wrap = Instance.new("Model"); wrap.Name = mesh.Name; wrap.Parent = mesh.Parent; mesh.Parent = wrap; model = wrap
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = true; p.CanCollide = false; p.CanTouch = true end
	end
	model.PrimaryPart = model.PrimaryPart or mesh
	-- scale to TargetHeight, keeping the feet where they are
	if math.abs(mesh.Size.Y - TARGET_HEIGHT) > 0.02 then
		local cf0, sz0 = model:GetBoundingBox()
		local bottom = cf0.Position.Y - sz0.Y / 2
		model:ScaleTo(model:GetScale() * TARGET_HEIGHT / mesh.Size.Y)
		local cf1, sz1 = model:GetBoundingBox()
		model:PivotTo(model:GetPivot() + Vector3.new(cf0.Position.X - cf1.Position.X, bottom - (cf1.Position.Y - sz1.Y / 2), cf0.Position.Z - cf1.Position.Z))
	end
	local id = model:GetAttribute("SquirrelId")
	if not id or squirrels[id] then
		id = baseId(model); local k = 1
		while squirrels[id] do k += 1; id = baseId(model) .. "_" .. k end
		model:SetAttribute("SquirrelId", id)
	end
	squirrels[id] = mesh
	CollectionService:AddTag(model, "Squirrel")
	if not PER_PLAYER then
		local gray = mesh:GetAttribute("GrayTexture")
		if gray and not model:GetAttribute("Found") then setTex(mesh, gray) end
		if model:GetAttribute("Found") == nil then model:SetAttribute("Found", false) end
	end
	return model, id
end
local total = 0
for _, mesh in ipairs(colours) do setup(mesh); total += 1 end
folder:SetAttribute("Total", total)
local mapTotal = 0
for _, e in ipairs(Registry.squirrels) do if e.map == THIS_MAP then mapTotal += 1 end end
folder:SetAttribute("MapTotal", mapTotal); folder:SetAttribute("AllTotal", #Registry.squirrels)
print(string.format("SquirrelSetup: %d squirrels ready (%s)", total, PER_PLAYER and "per-player finds" or "shared finds"))

-- 4. finds, saved per player in a DataStore so they survive leaving and rejoining
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local USE_STORE = folder:GetAttribute("UseDataStore")
if USE_STORE == nil then USE_STORE = true; folder:SetAttribute("UseDataStore", true) end
local STORE_KEY = folder:GetAttribute("SaveKey") or "SquirrelFinds_v1"
folder:SetAttribute("SaveKey", STORE_KEY)
local store
if USE_STORE and PER_PLAYER then
	local ok, err = pcall(function() store = DataStoreService:GetDataStore(STORE_KEY) end)
	if not ok then warn("SquirrelSetup: DataStore unavailable, finds will not be saved: " .. tostring(err)); store = nil end
end
local found = {}          -- userId -> { [id] = true }
local loaded = {}         -- userId -> true once the DataStore load finished (or was skipped)
local canSave = {}        -- userId -> false when the load failed (never overwrite good data with an empty list)
local dirty = {}          -- userId -> true when there is something new to save
local function foundList(player)
	local t = found[player.UserId]
	if not t then t = {}; found[player.UserId] = t end
	return t
end
local function count(t) local n = 0 for _ in pairs(t) do n += 1 end return n end
local function loadPlayer(player)
	local uid = player.UserId
	canSave[uid] = true
	if store then
		local ok, data
		for attempt = 1, 3 do
			ok, data = pcall(function() return store:GetAsync("u" .. uid) end)
			if ok then break end
			task.wait(1.5)
		end
		if ok then
			local t = foundList(player)
			if type(data) == "table" and type(data.found) == "table" then
				for _, id in ipairs(data.found) do t[(tostring(id):gsub("_color$", ""))] = true end
			end
			print(string.format("SquirrelSetup: loaded %d saved finds for %s", count(t), player.Name))
		else
			canSave[uid] = false
			warn("SquirrelSetup: could not load finds for " .. player.Name .. " (" .. tostring(data) .. "); this session will not be saved")
		end
	end
	loaded[uid] = true
	player:SetAttribute("SquirrelsFound", count(foundList(player)))
end
local function savePlayer(player)
	local uid = player.UserId
	if not store or not canSave[uid] or not loaded[uid] then return end
	local list = {}
	for id in pairs(foundList(player)) do table.insert(list, id) end
	local ok, err = pcall(function()
		store:UpdateAsync("u" .. uid, function(old)
			-- merge with whatever is already saved, so two servers never erase each other's finds
			local merged = {}
			if type(old) == "table" and type(old.found) == "table" then for _, id in ipairs(old.found) do merged[id] = true end end
			for _, id in ipairs(list) do merged[id] = true end
			local out = {}
			for id in pairs(merged) do table.insert(out, id) end
			return {found = out, updated = os.time()}
		end)
	end)
	if ok then dirty[uid] = nil else warn("SquirrelSetup: save failed for " .. player.Name .. ": " .. tostring(err)) end
end
Players.PlayerAdded:Connect(loadPlayer)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(loadPlayer, player) end
Players.PlayerRemoving:Connect(function(player)
	if dirty[player.UserId] then savePlayer(player) end
	task.delay(5, function() found[player.UserId] = nil; loaded[player.UserId] = nil; canSave[player.UserId] = nil; dirty[player.UserId] = nil end)
end)
-- save anything new every few seconds rather than on every single click
task.spawn(function()
	while true do
		task.wait(8)
		for _, player in ipairs(Players:GetPlayers()) do if dirty[player.UserId] then savePlayer(player) end end
	end
end)
game:BindToClose(function()
	if not store then return end
	for _, player in ipairs(Players:GetPlayers()) do if dirty[player.UserId] then savePlayer(player) end end
end)
sync.OnServerInvoke = function(player)
	local list = {}
	if PER_PLAYER then
		local waited = 0
		while not loaded[player.UserId] and waited < 15 do task.wait(0.25); waited += 0.25 end
		for id in pairs(foundList(player)) do table.insert(list, id) end
	else
		for id, mesh in pairs(squirrels) do if modelOf(mesh):GetAttribute("Found") then table.insert(list, id) end end
	end
	return list
end
local function onFound(player, model, id, mesh)
	if PER_PLAYER then
		local t = foundList(player)
		if t[id] then return end
		t[id] = true
		dirty[player.UserId] = true
		player:SetAttribute("SquirrelsFound", count(t))
		ev:FireClient(player, id)                      -- only this player sees it turn to colour
	else
		if model:GetAttribute("Found") then return end
		model:SetAttribute("Found", true)
		setTex(mesh, mesh:GetAttribute("ColorTexture"))
		local n = 0
		for _, m2 in pairs(squirrels) do if modelOf(m2):GetAttribute("Found") then n += 1 end end
		folder:SetAttribute("FoundCount", n)
		ev:FireAllClients(id, player)                  -- everyone sees the reveal
	end
	print(string.format("SquirrelSetup: %s found %s", player.Name, id))
end
-- FindBy attribute on the folder: "click" (default), "touch", or "both"
local FIND_BY = folder:GetAttribute("FindBy")
if FIND_BY == nil then FIND_BY = "click"; folder:SetAttribute("FindBy", "click") end
local CLICK_DIST = folder:GetAttribute("ClickDistance") or 32
folder:SetAttribute("ClickDistance", CLICK_DIST)
for id, mesh in pairs(squirrels) do
	local model = modelOf(mesh)
	if FIND_BY == "click" or FIND_BY == "both" then
		for _, old in ipairs(mesh:GetChildren()) do if old:IsA("ClickDetector") then old:Destroy() end end
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = CLICK_DIST
		-- Cursor attribute on the folder: "hand" (Roblox's pointing-hand default), "arrow" (no change), or an asset id
		local cur = folder:GetAttribute("Cursor") or "hand"
		folder:SetAttribute("Cursor", cur)
		if cur == "arrow" then cd.CursorIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
		elseif cur ~= "hand" and cur ~= "" then cd.CursorIcon = cur end
		cd.Parent = mesh
		cd.MouseClick:Connect(function(player) onFound(player, model, id, mesh) end)
	end
	if FIND_BY == "touch" or FIND_BY == "both" then
		local debounce = {}
		mesh.Touched:Connect(function(hit)
			local char = hit.Parent
			local player = char and Players:GetPlayerFromCharacter(char)
			if not player then return end
			if debounce[player] and os.clock() - debounce[player] < 1 then return end
			debounce[player] = os.clock()
			onFound(player, model, id, mesh)
		end)
	end
end
'''

ANIM = r'''
-- SquirrelAnim (client): idle bones + reveal effect. Runs on the client because Bone.Transform must be set there.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
''' + COMMON + r'''
local ev = ReplicatedStorage:WaitForChild("SquirrelFound", 30)
local sync = ReplicatedStorage:WaitForChild("SquirrelSync", 30)
local rng = Random.new()
local BLENDER_HEIGHT = 2.4
local ORDER = {"Root", "Chest", "Neck", "Head", "Tail1", "Tail2"}

local squirrels = {}     -- model -> state
local ensureHud, updateCounter, addBadge, fillBadge, ensureBadges, openCard, closeCard, nameTag, faceCamera, makeViewport, circleWindow, openAlbum, closeAlbum   -- defined below
local CIRCLE = 46            -- portrait diameter inside a 62 px tile
local foundIds = {}        -- every id this player has found, on any map (from the server)
local function addSquirrel(model)
	if squirrels[model] then return end
	local mesh
	for _, p in ipairs(model:GetDescendants()) do if isSquirrelMesh(p) then mesh = p break end end
	if not mesh then return end
	local bones = {}
	for _, b in ipairs(mesh:GetDescendants()) do if b:IsA("Bone") then bones[b.Name] = b end end
	-- squirrel axes in the mesh's own frame: forward = root -> head, up = world up
	local fwdL = Vector3.new(0, 0, -1)
	if bones.Root and bones.Head then
		local f = bones.Head.WorldPosition - bones.Root.WorldPosition
		f = Vector3.new(f.X, 0, f.Z)
		if f.Magnitude > 0.05 then fwdL = mesh.CFrame:VectorToObjectSpace(f.Unit) end
	end
	local upL = mesh.CFrame:VectorToObjectSpace(Vector3.yAxis)
	local st = {
		mesh = mesh, bones = bones, fwdL = fwdL, upL = upL, leftL = upL:Cross(fwdL),
		t = rng:NextNumber(0, 10), lookYaw = 0, lookTarget = 0, lookTimer = rng:NextNumber(1, 4), tilt = 0, tiltTarget = 0,
		flick = 0, flickTimer = rng:NextNumber(4, 10), hop = 0, hopTimer = rng:NextNumber(8, 20),
		found = false, revealT = -1, want = {},
	}
	squirrels[model] = st
end
local tracked = 0
local applyInitial      -- defined below
local function scan()
	local added = false
	for _, model in ipairs(CollectionService:GetTagged("Squirrel")) do
		if not squirrels[model] then addSquirrel(model); if squirrels[model] then added = true end end
	end
	if added then
		local n = 0
		for _ in pairs(squirrels) do n += 1 end
		tracked = n
		print("SquirrelAnim: tracking " .. n .. " squirrels")
		if applyInitial then task.defer(applyInitial) end
	end
end
-- tags can replicate after this script starts and the added-signal does not always fire for them, so keep looking
CollectionService:GetInstanceAddedSignal("Squirrel"):Connect(function() scan() end)
CollectionService:GetInstanceRemovedSignal("Squirrel"):Connect(function(model) squirrels[model] = nil end)
task.spawn(function()
	while true do scan(); task.wait(tracked == 0 and 0.5 or 3) end
end)

local function byId(id)
	for model, st in pairs(squirrels) do if model:GetAttribute("SquirrelId") == id then return model, st end end
end

-- start gray for everything this player has not found yet (per-player mode); shared mode already has the right texture
applyInitial = function()
	local list = sync and sync:InvokeServer() or {}
	local foundSet = {}
	for _, id in ipairs(list) do foundSet[id] = true; foundIds[id] = true end
	local perPlayer = script.Parent:GetAttribute("PerPlayer") ~= false
	for model, st in pairs(squirrels) do
		local id = model:GetAttribute("SquirrelId")
		local gray, color = st.mesh:GetAttribute("GrayTexture"), st.mesh:GetAttribute("ColorTexture")
		if foundSet[id] then st.found = true; if color then setTex(st.mesh, color) end
		elseif perPlayer and gray then setTex(st.mesh, gray) end
	end
	ensureHud(); ensureBadges(); updateCounter()
end
scan()

-- floating name tag: rises out of the squirrel with sparkles, holds, then fades
local TweenService = game:GetService("TweenService")
local Registry = require(script.Parent:WaitForChild("SquirrelRegistry"))
local regById, regOrder = {}, {}
for i, e in ipairs(Registry.squirrels) do regById[e.id] = e; regOrder[e.id] = i end
local function idOf(model) return model:GetAttribute("SquirrelId") or (model.Name:lower():gsub("_color$", "")) end
local function prettyName(model)
	local dn = model:GetAttribute("DisplayName")
	if dn and dn ~= "" then return dn end
	local e = regById[idOf(model)]
	if e then return e.name end
	local n = model.Name:gsub("_color$", ""):gsub("_gray$", ""):gsub("_", " ")
	n = n:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end)
	return n
end
-- ---- HUD: counter + a round face badge for every squirrel this player has found ----
local Players = game:GetService("Players")
local hud, grid, counter
local badges = {}
-- theme (Shannon's mock-up, Sep 17): navy panel in a dark rim with a neon cyan edge, tiles like pressed buttons, gold and
-- cyan ringed portraits with an acorn tag, dim "?" tiles for squirrels not found yet, a glossy yellow pill button
local RGB = Color3.fromRGB
local NAVY, NAVY_DEEP, RIM = RGB(24, 52, 112), RGB(13, 32, 82), RGB(8, 18, 48)
local SLOT, SLOT_LO, SLOT_EDGE = RGB(34, 68, 136), RGB(22, 48, 104), RGB(10, 24, 62)
local CYAN, CYAN_TEXT, CYAN_DIM = RGB(72, 236, 255), RGB(222, 248, 255), RGB(96, 196, 230)
local GOLD, GOLD_LIGHT, GOLD_DARK = RGB(255, 202, 62), RGB(255, 236, 150), RGB(190, 128, 22)
local TEAL, TEAL_EDGE = RGB(46, 178, 203), RGB(94, 226, 246)      -- the button lettering and its rim (sampled from the mock-up)
local BUTTON_GRADIENT = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(255, 226, 96)), ColorSequenceKeypoint.new(0.3, RGB(251, 203, 38)), ColorSequenceKeypoint.new(0.7, RGB(238, 174, 22)), ColorSequenceKeypoint.new(1, RGB(212, 142, 10))})
local BTN_H = 38
local CREAM = RGB(255, 248, 225)
local PANEL = SLOT                                  -- mask tint: hides the square corners of each portrait, so it matches the tile
local TILE, COLS, HUD_W = 62, 5, 358
local PORTRAIT_ZOOM, PORTRAIT_DOWN = 1.15, 0.05    -- the coin shows head, shoulders and paws, not just the face
local hudHolder
local FONT = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold)   -- clean rounded bold, like the mock-up
local FONT_BUTTON = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Heavy)
local FONT_TEXT = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold)
local TEXTURE = "rbxasset://textures/particles/smoke_main.dds"
local function maskId() return script.Parent:GetAttribute("MaskImage") or "rbxassetid://77268792392056" end
local function corner(parent, r) local c = Instance.new("UICorner"); c.CornerRadius = r; c.Parent = parent; return c end
local function stroke(parent, color, th, tr) local st = Instance.new("UIStroke"); st.Color = color; st.Thickness = th; st.Transparency = tr or 0; st.Parent = parent; return st end
local function gradient(parent, top, bottom, rot) local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(top, bottom); g.Rotation = rot or 90; g.Parent = parent; return g end
-- a faint cloudy texture over a surface (the built-in smoke tile) so panels and tiles read as material, not flat colour
local function texture(parent, z, tileSize, tr, radius, color)
	local t = Instance.new("ImageLabel"); t.Name = "Texture"; t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
	t.Image = TEXTURE; t.ScaleType = Enum.ScaleType.Tile; t.TileSize = UDim2.fromOffset(tileSize, tileSize); t.ImageTransparency = tr
	t.ImageColor3 = color or RGB(150, 205, 255); t.ZIndex = z; t.Parent = parent
	corner(t, radius)
	return t
end
-- panel: dark rim with a soft outer glow, the neon line, a navy face with a vertical sheen and texture.
-- Returns the face (content goes in it) and the rim (position and size go on it).
local function neonPanel(parent, z, radius)
	local rim = Instance.new("Frame"); rim.Name = "Rim"; rim.BackgroundColor3 = RIM; rim.ZIndex = z; rim.Parent = parent
	corner(rim, UDim.new(0, radius + 5)); stroke(rim, CYAN, 6, 0.8)
	local rp = Instance.new("UIPadding"); rp.PaddingTop = UDim.new(0, 5); rp.PaddingBottom = UDim.new(0, 5); rp.PaddingLeft = UDim.new(0, 5); rp.PaddingRight = UDim.new(0, 5); rp.Parent = rim
	local face = Instance.new("Frame"); face.Name = "Face"; face.Size = UDim2.fromScale(1, 1); face.BackgroundColor3 = NAVY; face.ZIndex = z + 1; face.Parent = rim
	corner(face, UDim.new(0, radius)); stroke(face, CYAN, 3, 0.05)
	gradient(face, RGB(32, 70, 142), NAVY_DEEP)
	texture(face, z + 1, 180, 0.9, UDim.new(0, radius))
	local sheen = Instance.new("Frame"); sheen.Name = "Sheen"; sheen.Size = UDim2.new(1, -10, 0, 70); sheen.Position = UDim2.fromOffset(5, 5)
	sheen.BackgroundColor3 = RGB(255, 255, 255); sheen.BackgroundTransparency = 0.94; sheen.ZIndex = z + 1; sheen.Parent = face
	corner(sheen, UDim.new(0, radius - 3)); gradient(sheen, RGB(255, 255, 255), RGB(24, 52, 112))
	return face, rim
end
-- a pressed tile a portrait sits in (flat colour on purpose: the portrait mask is tinted to match it)
local function tile(parent, size, z)
	local t = Instance.new("Frame"); t.Name = "Tile"; t.Size = UDim2.fromOffset(size, size); t.BackgroundColor3 = SLOT; t.ZIndex = z; t.Parent = parent
	corner(t, UDim.new(0, 12)); stroke(t, SLOT_EDGE, 2, 0.1)
	texture(t, z, 90, 0.93, UDim.new(0, 12))
	return t
end
-- a little acorn hanging off the bottom of a ring
local function acorn(parent, w, z)
	local a = Instance.new("Frame"); a.Name = "Acorn"; a.Size = UDim2.fromOffset(w, math.floor(w * 1.2)); a.AnchorPoint = Vector2.new(0.5, 0)
	a.Position = UDim2.new(0.5, 0, 1, -math.floor(w * 0.6)); a.BackgroundTransparency = 1; a.ZIndex = z; a.Parent = parent
	local nut = Instance.new("Frame"); nut.Size = UDim2.new(0.78, 0, 0.7, 0); nut.AnchorPoint = Vector2.new(0.5, 1); nut.Position = UDim2.new(0.5, 0, 1, 0)
	nut.BackgroundColor3 = RGB(206, 136, 62); nut.ZIndex = z; nut.Parent = a
	corner(nut, UDim.new(0.5, 0)); stroke(nut, RGB(92, 52, 18), 1, 0.15); gradient(nut, RGB(230, 164, 86), RGB(160, 96, 36))
	local cap = Instance.new("Frame"); cap.Size = UDim2.new(1, 0, 0.42, 0); cap.Position = UDim2.new(0, 0, 0.14, 0)
	cap.BackgroundColor3 = RGB(126, 76, 34); cap.ZIndex = z + 1; cap.Parent = a
	corner(cap, UDim.new(0.5, 0)); stroke(cap, RGB(70, 40, 14), 1, 0.15); gradient(cap, RGB(156, 100, 48), RGB(96, 56, 22))
	local stem = Instance.new("Frame"); stem.Size = UDim2.new(0.16, 0, 0.22, 0); stem.AnchorPoint = Vector2.new(0.5, 0); stem.Position = UDim2.new(0.5, 0, 0, 0)
	stem.BackgroundColor3 = RGB(88, 52, 20); stem.ZIndex = z; stem.Parent = a
	corner(stem, UDim.new(0.5, 0))
	return a
end
-- the chunky yellow pill button: saturated gold shaded like a tube (lemon highlight on top, amber below), a thick bright
-- cyan rim with a soft glow outside it, and big rounded teal lettering with a dark-teal edge and a shadow so it stands
-- off the button. The background stays white so the gradient shows its own colours (BackgroundColor3 multiplies it);
-- the lettering sits ABOVE the gloss strip so it stays crisp.
-- a glowing neon line on the edge of a rounded object: a bright core plus halo bands fading outward and inward.
-- UIStroke draws outward from its frame's edge, so inset frames put their bands inside the object.
local function neonEdge(target, z)
	-- concentric rings: each frame is expanded so its stroke starts where the previous one ends
	local function ring(expand, th, tr, col)
		local f = Instance.new("Frame"); f.Name = "Glow"; f.Size = UDim2.new(1, 2 * expand, 1, 2 * expand); f.Position = UDim2.fromOffset(-expand, -expand)
		f.BackgroundTransparency = 1; f.ZIndex = z; f.Parent = target
		corner(f, UDim.new(1, 0)); stroke(f, col, th, tr)
	end
	stroke(target, RGB(8, 30, 56), 1.5, 0.15)                     -- dark hairline between the yellow and the line
	ring(1.5, 2.5, 0, RGB(120, 238, 255))                         -- the teal line; no glow (Shannon: the line is enough)
end
local function pillButton(parent, text, height, textSize, z)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, height); b.BackgroundColor3 = RGB(255, 255, 255); b.Text = ""
	b.AutoButtonColor = false; b.ZIndex = z; b.Parent = parent
	corner(b, UDim.new(1, 0))
	local g = Instance.new("UIGradient"); g.Color = BUTTON_GRADIENT; g.Rotation = 90; g.Parent = b
	neonEdge(b, z)
	local gloss = Instance.new("Frame"); gloss.Size = UDim2.new(1, -26, 0.3, 0); gloss.Position = UDim2.new(0, 13, 0, 4); gloss.BackgroundColor3 = RGB(255, 250, 215)
	gloss.BackgroundTransparency = 0.78; gloss.ZIndex = z + 1; gloss.Parent = b
	corner(gloss, UDim.new(1, 0))
	-- molded-plastic lettering: the glyph face is shaded light teal (top) to deeper teal (bottom), and its outline is
	-- shaded the same way, pale along the top edges and dark along the bottom edges, so every letter reads as a lit,
	-- rounded solid. Underneath, a soft amber shadow (the yellow going darker) seats it on the button.
	local function glyphs(dx, dy, color, tr, zz)
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.Position = UDim2.fromOffset(dx, dy); l.BackgroundTransparency = 1
		l.Text = text; l.FontFace = FONT_BUTTON; l.TextSize = textSize; l.TextColor3 = color; l.TextTransparency = tr; l.ZIndex = zz; l.Parent = b
		return l
	end
	-- extruded lettering (Shannon's crop: the letters have squared-off side walls under the face, like pieces cut from
	-- a slab and set on the button). Copies of the text step down in the side colour to build the wall, a warm contact
	-- shadow pools under the wall, and the flat face goes on top with a hairline edge that is lit on top.
	local shade = glyphs(0, 5, RGB(190, 124, 20), 0.72, z + 2)
	local ss = Instance.new("UIStroke"); ss.Color = RGB(190, 124, 20); ss.Thickness = 1.5; ss.Transparency = 0.82; ss.LineJoinMode = Enum.LineJoinMode.Round; ss.Parent = shade
	local wall = {{1, 3, RGB(40, 148, 184)}, {1, 2, RGB(48, 160, 196)}, {0, 1, RGB(56, 172, 206)}}
	for i, w in ipairs(wall) do
		local side = glyphs(w[1], w[2], w[3], 0, z + 2 + i)
		local ws = Instance.new("UIStroke"); ws.Color = w[3]; ws.Thickness = 0.8; ws.LineJoinMode = Enum.LineJoinMode.Miter; ws.Parent = side
	end
	local label = glyphs(0, 0, RGB(255, 255, 255), 0, z + 6)
	local tg = Instance.new("UIGradient"); tg.Rotation = 90
	tg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(140, 232, 248)), ColorSequenceKeypoint.new(0.5, RGB(86, 206, 230)), ColorSequenceKeypoint.new(1, RGB(70, 196, 222))})
	tg.Parent = label
	local ls = Instance.new("UIStroke"); ls.Color = RGB(255, 255, 255); ls.Thickness = 1; ls.Transparency = 0.1; ls.LineJoinMode = Enum.LineJoinMode.Miter; ls.Parent = label
	local lg = Instance.new("UIGradient"); lg.Rotation = 90                     -- the face's squared edge: lit on top, side colour below
	lg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(220, 252, 255)), ColorSequenceKeypoint.new(0.5, RGB(70, 182, 214)), ColorSequenceKeypoint.new(1, RGB(44, 150, 186))})
	lg.Parent = ls
	b.MouseEnter:Connect(function() TweenService:Create(gloss, TweenInfo.new(0.12), {BackgroundTransparency = 0.6}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(gloss, TweenInfo.new(0.12), {BackgroundTransparency = 0.78}):Play() end)
	return b
end
-- a round yellow button with an x, for closing the album and the card
local function closeButton(parent, z, onClick)
	local close = Instance.new("TextButton"); close.Size = UDim2.fromOffset(34, 34); close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10); close.BackgroundColor3 = RGB(255, 255, 255); close.Text = "x"; close.AutoButtonColor = false
	close.FontFace = FONT; close.TextSize = 20; close.TextColor3 = TEAL; close.ZIndex = z; close.Parent = parent
	corner(close, UDim.new(1, 0)); stroke(close, TEAL_EDGE, 2, 0.05)
	local g = Instance.new("UIGradient"); g.Color = BUTTON_GRADIENT; g.Rotation = 90; g.Parent = close
	close.MouseEnter:Connect(function() close.BackgroundColor3 = RGB(255, 255, 235) end)
	close.MouseLeave:Connect(function() close.BackgroundColor3 = RGB(255, 255, 255) end)
	close.MouseButton1Click:Connect(onClick)
	return close
end
ensureHud = function()
	if hud then return end
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	hud = Instance.new("ScreenGui"); hud.Name = "SquirrelHUD"; hud.ResetOnSpawn = false; hud.IgnoreGuiInset = true
	hud.DisplayOrder = 5; hud.Parent = pg
	-- sizes are set by hand in updateCounter (no AutomaticSize: the texture and sheen layers would feed back into it)
	hudHolder = Instance.new("Frame"); hudHolder.Name = "Panel"; hudHolder.AnchorPoint = Vector2.new(1, 0); hudHolder.Position = UDim2.new(1, -10, 0, 8)
	hudHolder.Size = UDim2.fromOffset(HUD_W, 200); hudHolder.BackgroundTransparency = 1; hudHolder.Parent = hud
	local face, rim = neonPanel(hudHolder, 1, 16)
	rim.Size = UDim2.fromScale(1, 1)
	local content = Instance.new("Frame"); content.Name = "Content"; content.Size = UDim2.fromScale(1, 1); content.BackgroundTransparency = 1; content.ZIndex = 3; content.Parent = face
	local ppad = Instance.new("UIPadding"); ppad.PaddingTop = UDim.new(0, 8); ppad.PaddingBottom = UDim.new(0, 10)
	ppad.PaddingLeft = UDim.new(0, 10); ppad.PaddingRight = UDim.new(0, 10); ppad.Parent = content
	local list = Instance.new("UIListLayout"); list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.Padding = UDim.new(0, 8); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = content
	counter = Instance.new("TextLabel"); counter.Name = "Counter"; counter.Size = UDim2.new(1, 0, 0, 22); counter.BackgroundTransparency = 1; counter.TextWrapped = true
	counter.FontFace = FONT; counter.TextScaled = true; counter.TextColor3 = CYAN_TEXT; counter.TextXAlignment = Enum.TextXAlignment.Center; counter.Text = ""
	counter.ZIndex = 3; counter.LayoutOrder = 1; counter.Parent = content
	local ctc = Instance.new("UITextSizeConstraint"); ctc.MaxTextSize = 16; ctc.MinTextSize = 10; ctc.Parent = counter   -- one line shrinks to fit the panel
	stroke(counter, RGB(4, 14, 40), 1.5, 0.35).LineJoinMode = Enum.LineJoinMode.Round
	grid = Instance.new("Frame"); grid.Name = "Badges"; grid.Size = UDim2.new(1, 0, 0, TILE)
	grid.BackgroundTransparency = 1; grid.LayoutOrder = 2; grid.ZIndex = 3; grid.Parent = content
	local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(TILE, TILE); gl.CellPadding = UDim2.fromOffset(4, 4)
	gl.FillDirection = Enum.FillDirection.Horizontal; gl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gl.StartCorner = Enum.StartCorner.TopLeft; gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
	local albumBtn = pillButton(content, "Open Album", BTN_H, 24, 3); albumBtn.LayoutOrder = 3
	albumBtn.MouseButton1Click:Connect(function() if album then closeAlbum() else openAlbum() end end)
end
updateCounter = function()
	if not counter then return end
	local n = 0
	for _, st in pairs(squirrels) do if st.found then n += 1 end end
	-- which map is the player standing in? (workspace.Zones holds one Part per map with a MapId attribute)
	local mapId = script.Parent:GetAttribute("MapId") or "forest"
	local zones = workspace:FindFirstChild("Zones")
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if zones and root then
		for _, z in ipairs(zones:GetChildren()) do
			if z:IsA("BasePart") and z:GetAttribute("MapId") then
				local rel = z.CFrame:PointToObjectSpace(root.Position)
				if math.abs(rel.X) <= z.Size.X / 2 and math.abs(rel.Z) <= z.Size.Z / 2 then mapId = z:GetAttribute("MapId") break end
			end
		end
	end
	local hereFound, hereTotal, all = 0, 0, 0
	for _, e in ipairs(Registry.squirrels) do
		if e.map == mapId then hereTotal += 1; if foundIds[e.id] then hereFound += 1 end end
	end
	for _ in pairs(foundIds) do all += 1 end
	local mapName = mapId
	for _, m in ipairs(Registry.maps) do if m.id == mapId then mapName = m.name end end
	local counts = string.format("%d / %d      All maps  %d / %d", hereFound, hereTotal, all, script.Parent:GetAttribute("AllTotal") or #Registry.squirrels)
	-- long map names get their own (wrapping) line so the counts are never pushed out of the panel
	if (utf8.len(mapName) or #mapName) > 28 then
		counter.Text = mapName .. string.char(10) .. counts
	else
		counter.Text = mapName .. "  " .. counts
	end
	-- the badge panel shows only the squirrels of the map the player is standing in
	local visible = 0
	for model, b in pairs(badges) do
		local e = regById[idOf(model)]
		b.cell.Visible = (e == nil) or (e.map == mapId)
		if b.cell.Visible then visible += 1 end
	end
	local rows = math.max(1, math.ceil(visible / COLS))
	local lines = select(2, counter.Text:gsub("\n", "")) + 1
	counter.Size = UDim2.new(1, 0, 0, 22 * lines)
	grid.Size = UDim2.new(1, 0, 0, rows * (TILE + 4) - 4)
	if hudHolder then hudHolder.Size = UDim2.fromOffset(HUD_W, 10 + 8 + 22 * lines + 8 + rows * (TILE + 4) - 4 + 8 + BTN_H + 10) end
end
-- ---- the card: full squirrel turning slowly, name, and a bio ----
local card, cardConn, cardInputs
closeCard = function()
	if cardConn then cardConn:Disconnect(); cardConn = nil end
	if cardInputs then for _, c in ipairs(cardInputs) do c:Disconnect() end; cardInputs = nil end
	if card then card:Destroy(); card = nil end
end
openCard = function(model, st)
	closeCard(); ensureHud()
	local mesh = st.mesh
	card = Instance.new("Frame"); card.Name = "Card"; card.Size = UDim2.fromScale(1, 1); card.BackgroundColor3 = Color3.new(0, 0, 0)
	card.BackgroundTransparency = 0.45; card.ZIndex = 20; card.Parent = hud
	local backdrop = Instance.new("TextButton"); backdrop.Size = UDim2.fromScale(1, 1); backdrop.BackgroundTransparency = 1; backdrop.Text = ""
	backdrop.ZIndex = 20; backdrop.Parent = card; backdrop.MouseButton1Click:Connect(closeCard)
	local panel, prim = neonPanel(card, 21, 22)
	prim.AnchorPoint = Vector2.new(0.5, 0.5); prim.Position = UDim2.fromScale(0.5, 0.5); prim.Size = UDim2.fromOffset(432, 566)
	local big = tile(panel, 326, 22); big.AnchorPoint = Vector2.new(0.5, 0); big.Position = UDim2.new(0.5, 0, 0, 16)
	local ring = circleWindow(big, 288, 22, true)
	ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.new(0.5, 0, 0.5, -6)
	acorn(ring, 44, 31)
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(150, 150, 165); vp.LightColor = Color3.fromRGB(255, 252, 245); vp.LightDirection = Vector3.new(-0.5, -1, -0.4)
	vp.ZIndex = 24; vp.Parent = ring
	local copy = mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	local color = mesh:GetAttribute("ColorTexture"); if color then setTex(copy, color) end
	copy.Parent = vp
	local cam = Instance.new("Camera"); cam.FieldOfView = 30; cam.Parent = vp; vp.CurrentCamera = cam
	local centre = mesh.Position
	local dist = mesh.Size.Magnitude * 1.3         -- close: fills the circle for a sharper render, the mask crops the spill that the whole squirrel, tail included, stays inside the circle
	local fwd = mesh.CFrame:VectorToWorldSpace(st.fwdL)
	local ang0 = math.atan2(fwd.X, fwd.Z)
	-- turntable: spins slowly on its own; click and drag on the squirrel to turn it yourself
	local UIS = game:GetService("UserInputService")
	local ang, elev = ang0, 0.22
	local dragging, lastPos, idle = false, nil, 0
	vp.Active = true
	vp.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; lastPos = input.Position; idle = 0
		end
	end)
	local c1 = UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - lastPos; lastPos = input.Position
			ang -= d.X * 0.012
			elev = math.clamp(elev + d.Y * 0.006, -0.5, 0.9)
		end
	end)
	local c2 = UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	cardInputs = {c1, c2}
	cardConn = RunService.RenderStepped:Connect(function(dt)
		if not dragging then
			idle += dt
			if idle > 1.5 then ang += dt * 0.5 end          -- resume the slow spin a moment after you let go
		end
		local off = Vector3.new(math.sin(ang), 0, math.cos(ang)) * dist + Vector3.new(0, dist * elev, 0)
		cam.CFrame = CFrame.lookAt(centre + off, centre)
	end)
	local hint = Instance.new("TextLabel"); hint.Size = UDim2.new(1, 0, 0, 16); hint.Position = UDim2.new(0, 0, 0, 350)
	hint.BackgroundTransparency = 1; hint.Text = "drag to spin"; hint.TextSize = 12
	hint.FontFace = FONT_TEXT; hint.TextColor3 = CYAN_DIM
	hint.ZIndex = 22; hint.Parent = panel
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -40, 0, 40); title.Position = UDim2.new(0, 20, 0, 368)
	title.BackgroundTransparency = 1; title.Text = prettyName(model); title.TextScaled = true
	title.FontFace = FONT; title.TextColor3 = GOLD_LIGHT
	title.ZIndex = 22; title.Parent = panel
	local tc = Instance.new("UITextSizeConstraint"); tc.MaxTextSize = 28; tc.Parent = title
	local bio = Instance.new("TextLabel"); bio.Size = UDim2.new(1, -44, 0, 120); bio.Position = UDim2.new(0, 22, 0, 414)
	bio.BackgroundTransparency = 1; bio.Text = model:GetAttribute("Bio") or ""; bio.TextWrapped = true; bio.TextScaled = true
	bio.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.SemiBold); bio.TextColor3 = CYAN_TEXT
	bio.TextYAlignment = Enum.TextYAlignment.Top; bio.ZIndex = 22; bio.Parent = panel
	local bc = Instance.new("UITextSizeConstraint"); bc.MaxTextSize = 17; bc.MinTextSize = 11; bc.Parent = bio
	closeButton(panel, 23, closeCard)
	local sc = Instance.new("UIScale"); sc.Scale = 0.7; sc.Parent = prim
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

-- ---- the album: every squirrel on every map, opened from the "Album" button ----
local album
closeAlbum = function() if album then album:Destroy(); album = nil end end
openAlbum = function()
	closeAlbum(); ensureHud()
	album = Instance.new("Frame"); album.Name = "Album"; album.Size = UDim2.fromScale(1, 1); album.BackgroundColor3 = Color3.new(0, 0, 0)
	album.BackgroundTransparency = 0.45; album.ZIndex = 30; album.Parent = hud
	local backdrop = Instance.new("TextButton"); backdrop.Size = UDim2.fromScale(1, 1); backdrop.BackgroundTransparency = 1; backdrop.Text = ""
	backdrop.ZIndex = 30; backdrop.Parent = album; backdrop.MouseButton1Click:Connect(closeAlbum)
	local panel, rim = neonPanel(album, 31, 22)
	rim.AnchorPoint = Vector2.new(0.5, 0.5); rim.Position = UDim2.fromScale(0.5, 0.5); rim.Size = UDim2.new(0, 600, 0.82, 0)
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, -80, 0, 44); title.Position = UDim2.new(0, 24, 0, 12)
	title.BackgroundTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left; title.TextSize = 28
	title.FontFace = FONT; title.TextColor3 = CYAN_TEXT
	local all, allTotal = 0, script.Parent:GetAttribute("AllTotal") or #Registry.squirrels
	for _ in pairs(foundIds) do all += 1 end
	title.Text = string.format("Squirrel Album   %d / %d", all, allTotal); title.ZIndex = 33; title.Parent = panel
	stroke(title, RGB(4, 14, 40), 1.5, 0.35).LineJoinMode = Enum.LineJoinMode.Round
	closeButton(panel, 34, closeAlbum)
	local scroll = Instance.new("ScrollingFrame"); scroll.Position = UDim2.new(0, 18, 0, 64); scroll.Size = UDim2.new(1, -36, 1, -80)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 6; scroll.ScrollBarImageColor3 = CYAN; scroll.ZIndex = 33
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(); scroll.Parent = panel
	local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 12); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = scroll
	-- squirrels present on this map, by id, for faces and cards
	local here = {}
	for model, st in pairs(squirrels) do here[idOf(model)] = {model = model, st = st} end
	for mi, map in ipairs(Registry.maps) do
		local mapFound, mapTotal = 0, 0
		for _, e in ipairs(Registry.squirrels) do if e.map == map.id then mapTotal += 1; if foundIds[e.id] then mapFound += 1 end end end
		local section = Instance.new("Frame"); section.Size = UDim2.new(1, 0, 0, 0); section.AutomaticSize = Enum.AutomaticSize.Y
		section.BackgroundTransparency = 1; section.LayoutOrder = mi; section.ZIndex = 33; section.Parent = scroll
		local sl = Instance.new("UIListLayout"); sl.SortOrder = Enum.SortOrder.LayoutOrder; sl.Padding = UDim.new(0, 6); sl.Parent = section
		local head = Instance.new("TextLabel"); head.Size = UDim2.new(1, 0, 0, 24); head.BackgroundTransparency = 1
		head.AutomaticSize = Enum.AutomaticSize.Y; head.TextWrapped = true; head.LayoutOrder = 1
		head.TextXAlignment = Enum.TextXAlignment.Left; head.TextSize = 18; head.ZIndex = 33
		head.FontFace = FONT; head.TextColor3 = CYAN_TEXT
		head.Text = string.format("%s   %d / %d", map.name, mapFound, mapTotal); head.Parent = section
		stroke(head, RGB(4, 14, 40), 1.5, 0.35).LineJoinMode = Enum.LineJoinMode.Round
		local grid = Instance.new("Frame"); grid.LayoutOrder = 2; grid.Size = UDim2.new(1, 0, 0, 0)
		grid.AutomaticSize = Enum.AutomaticSize.Y; grid.BackgroundTransparency = 1; grid.ZIndex = 33; grid.Parent = section
		local gl = Instance.new("UIGridLayout"); gl.CellSize = UDim2.fromOffset(TILE + 6, TILE + 24); gl.CellPadding = UDim2.fromOffset(4, 6)
		gl.SortOrder = Enum.SortOrder.LayoutOrder; gl.Parent = grid
		local order = 0
		for _, e in ipairs(Registry.squirrels) do
			if e.map == map.id then
				order += 1
				local cell = Instance.new("Frame"); cell.BackgroundTransparency = 1; cell.LayoutOrder = order; cell.ZIndex = 33; cell.Parent = grid
				local isFound = foundIds[e.id] == true
				local t = tile(cell, TILE, 34); t.AnchorPoint = Vector2.new(0.5, 0); t.Position = UDim2.new(0.5, 0, 0, 0)
				local box = circleWindow(t, CIRCLE, 35, isFound)
				box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.5, -2)
				if isFound then acorn(box, 15, 44) end
				local h = here[e.id]
				if isFound and h then
					makeViewport(box, h.st, faceCamera(h.st))
				else
					local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1
					q.Text = isFound and e.name:sub(1, 1) or "?"; q.TextSize = isFound and 26 or 30
					q.FontFace = FONT; q.TextColor3 = isFound and CYAN_TEXT or CYAN_DIM; q.TextTransparency = isFound and 0 or 0.15; q.ZIndex = 43; q.Parent = box
				end
				local name = Instance.new("TextLabel"); name.Size = UDim2.new(1, 0, 0, 20); name.Position = UDim2.new(0, 0, 0, TILE + 3)
				name.BackgroundTransparency = 1; name.Text = isFound and e.name or ""; name.TextWrapped = true; name.TextScaled = true
				name.FontFace = FONT_TEXT; name.TextColor3 = CYAN_TEXT; name.ZIndex = 34; name.Parent = cell
				local nc = Instance.new("UITextSizeConstraint"); nc.MaxTextSize = 10; nc.MinTextSize = 7; nc.Parent = name
				if isFound and h then
					local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
					btn.ZIndex = 45; btn.Parent = cell
					btn.MouseButton1Click:Connect(function() closeAlbum(); openCard(h.model, h.st) end)
				end
			end
		end
	end
	local sc = Instance.new("UIScale"); sc.Scale = 0.85; sc.Parent = rim
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end

local badgeOrder = 0
-- per-squirrel framing tweaks (fractions of body height); a model's FaceDist / FaceUp / FaceCamUp attributes override
local FACE = setmetatable({}, {__index = function(_, name)
	for _, e in ipairs(Registry.squirrels) do if e.name == name and e.face then return e.face end end
	return nil
end})
faceCamera = function(st)
	-- portrait crop: head and shoulders fill the circle, the rest is hidden by the mask
	local mesh, model = st.mesh, st.mesh:FindFirstAncestorOfClass("Model")
	local H = mesh.Size.Y
	local fwd = mesh.CFrame:VectorToWorldSpace(st.fwdL)
	local left = Vector3.yAxis:Cross(fwd)
	local tw = (model and FACE[model:GetAttribute("DisplayName") or ""]) or {}
	local dist = ((model and model:GetAttribute("FaceDist")) or tw.dist or 1.35) * PORTRAIT_ZOOM
	local up = (model and model:GetAttribute("FaceUp")) or tw.up or 0
	local camUp = (model and model:GetAttribute("FaceCamUp")) or tw.camUp or 0.05
	local side = (model and model:GetAttribute("FaceSide")) or tw.side or 0
	local bottom = mesh.Position - Vector3.new(0, H / 2, 0)
	local centre = bottom + Vector3.new(0, (0.70 + up - PORTRAIT_DOWN) * H, 0) + fwd * (0.30 * H)
	-- centre sideways on where the head actually is (some squirrels lean or turn a little)
	if st.bones.Head then
		local d = st.bones.Head.WorldPosition - centre
		centre = centre + left * d:Dot(left)
	end
	centre = centre + left * (side * H)   -- per-squirrel sideways nudge (turned heads, big side tails)
	local cam = Instance.new("Camera"); cam.FieldOfView = 24
	cam.CFrame = CFrame.lookAt(centre + fwd * (dist * H) + Vector3.new(0, camUp * H, 0), centre)
	return cam
end
makeViewport = function(parent, st, cam)
	local vp = Instance.new("ViewportFrame"); vp.Size = UDim2.fromScale(1, 1); vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 190, 200); vp.LightColor = Color3.fromRGB(255, 250, 240); vp.LightDirection = Vector3.new(-0.4, -1, -0.6)
	vp.ZIndex = parent.ZIndex + 2; vp.Parent = parent
	local copy = st.mesh:Clone()
	for _, c in ipairs(copy:GetChildren()) do if not c:IsA("Bone") then c:Destroy() end end
	local color = st.mesh:GetAttribute("ColorTexture"); if color then setTex(copy, color) end
	copy.Parent = vp
	cam.Parent = vp; vp.CurrentCamera = cam
	return vp
end
-- the coin: a portrait window that sits proud of its tile. Layers, bottom up: drop shadow, dark disc, the 3D render
-- (makeViewport puts it at z + 2), the mask (transparent circle tinted like the tile), a soft cyan glow, the cyan ring,
-- the gold bevel (a gradient-lit stroke, light on top, dark amber below), a thin highlight on the inner lip.
-- Squirrels not found yet get a plain dim ring instead.
circleWindow = function(parent, size, z, found)
	local box = Instance.new("Frame"); box.Size = UDim2.fromOffset(size, size); box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.new(0.5, 0, 0, 0); box.BackgroundTransparency = 1; box.ZIndex = z; box.Parent = parent
	local function ringFrame(inset, zz)
		local f = Instance.new("Frame"); f.Size = UDim2.new(1, -2 * inset, 1, -2 * inset); f.Position = UDim2.fromOffset(inset, inset)
		f.BackgroundTransparency = 1; f.ZIndex = zz; f.Parent = box
		corner(f, UDim.new(1, 0))
		return f
	end
	if found then
		local shadow = ringFrame(-1, z); shadow.Name = "Shadow"; shadow.Position = UDim2.fromOffset(-1, 3)
		shadow.BackgroundColor3 = RGB(0, 0, 0); shadow.BackgroundTransparency = 0.5
	end
	local disc = Instance.new("Frame"); disc.Name = "Disc"; disc.Size = UDim2.fromScale(1, 1); disc.BackgroundColor3 = found and RGB(28, 58, 120) or SLOT_LO; disc.ZIndex = z + 1; disc.Parent = box
	corner(disc, UDim.new(1, 0))
	if found then gradient(disc, RGB(38, 78, 152), RGB(12, 30, 74)) end
	local mask = Instance.new("ImageLabel"); mask.Name = "Mask"; mask.Size = UDim2.fromScale(1, 1); mask.BackgroundTransparency = 1
	mask.Image = maskId(); mask.ImageColor3 = PANEL; mask.ScaleType = Enum.ScaleType.Fit; mask.ZIndex = z + 3; mask.Parent = box
	if found then
		stroke(ringFrame(3, z + 4), CYAN, 6, 0.78)                                  -- soft glow
		stroke(ringFrame(4, z + 5), CYAN, 2, 0.05)                                  -- the cyan ring
		stroke(ringFrame(-1, z + 5), RGB(90, 56, 8), 1.5, 0.35)                     -- dark edge under the bevel
		local bevel = stroke(ringFrame(0, z + 6), GOLD, 4)
		local gg = Instance.new("UIGradient"); gg.Rotation = 90
		gg.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RGB(255, 244, 190)), ColorSequenceKeypoint.new(0.35, RGB(252, 206, 70)), ColorSequenceKeypoint.new(1, RGB(160, 100, 16))})
		gg.Parent = bevel
		stroke(ringFrame(2, z + 7), RGB(255, 252, 230), 1, 0.55)                    -- highlight on the inner lip
	else
		stroke(ringFrame(1, z + 5), CYAN_DIM, 2, 0.45)
	end
	return box, disc, mask
end
addBadge = function(model, st)
	ensureHud()
	if badges[model] then return badges[model] end
	badgeOrder += 1
	local cell = Instance.new("Frame"); cell.Name = model.Name; cell.BackgroundTransparency = 1; cell.LayoutOrder = badgeOrder; cell.ZIndex = 3; cell.Parent = grid
	local t = tile(cell, TILE, 3)
	local box = circleWindow(t, CIRCLE, 4, false)
	box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.5, -2)
	local q = Instance.new("TextLabel"); q.Size = UDim2.fromScale(1, 1); q.BackgroundTransparency = 1; q.Text = "?"
	q.FontFace = FONT; q.TextSize = 30; q.TextColor3 = CYAN_DIM; q.TextTransparency = 0.15; q.ZIndex = 12; q.Parent = box
	local b = {cell = cell, tile = t, box = box, filled = false}
	local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1; btn.Text = ""
	btn.ZIndex = 16; btn.Parent = cell
	btn.MouseButton1Click:Connect(function() if b.filled then openCard(model, st) end end)
	btn.MouseEnter:Connect(function() if b.filled then TweenService:Create(b.box, TweenInfo.new(0.15), {Position = UDim2.new(0.5, 0, 0.5, -4)}):Play() end end)
	btn.MouseLeave:Connect(function() if b.filled then TweenService:Create(b.box, TweenInfo.new(0.15), {Position = UDim2.new(0.5, 0, 0.5, -2)}):Play() end end)
	badges[model] = b
	updateCounter()
	return b
end
fillBadge = function(model, st)
	local b = addBadge(model, st)
	if b.filled then return end
	b.filled = true
	b.box:Destroy()                                   -- the "?" window goes; a proper coin takes its place
	local box = circleWindow(b.tile, CIRCLE, 4, true)
	box.AnchorPoint = Vector2.new(0.5, 0.5); box.Position = UDim2.new(0.5, 0, 0.5, -2)
	b.box = box
	makeViewport(box, st, faceCamera(st))             -- z 6: over the disc (5), under the mask (7) and the rings (8 to 11)
	acorn(box, 15, 13)
	local scale = Instance.new("UIScale"); scale.Scale = 0.4; scale.Parent = b.cell
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	updateCounter()
end
ensureBadges = function()
	local list = {}
	for model, st in pairs(squirrels) do table.insert(list, {model = model, st = st}) end
	table.sort(list, function(a, b) return (regOrder[idOf(a.model)] or 999) < (regOrder[idOf(b.model)] or 999) end)
	for _, e in ipairs(list) do addBadge(e.model, e.st); if e.st.found then fillBadge(e.model, e.st) end end
end

nameTag = function(model, mesh)
	local folder = script.Parent
	local T = folder:GetAttribute("NameTagSeconds") or 3.2        -- seconds from appear to gone
	local RISE = 3.5
	local top = mesh.Position + Vector3.new(0, mesh.Size.Y * 0.5 + 0.5, 0)
	local anchor = Instance.new("Part"); anchor.Name = "NameTagAnchor"; anchor.Anchored = true; anchor.CanCollide = false
	anchor.CanQuery = false; anchor.CanTouch = false; anchor.Transparency = 1; anchor.Size = Vector3.new(3, 1.2, 3)
	anchor.Position = top; anchor.Parent = workspace
	local W, H = 120, 52
	local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(W, H); gui.AlwaysOnTop = true
	gui.MaxDistance = 150; gui.LightInfluence = 0; gui.Parent = anchor
	local function makeLabel(z)
		local l = Instance.new("TextLabel"); l.Size = UDim2.fromScale(1, 1); l.BackgroundTransparency = 1
		l.Text = prettyName(model); l.FontFace = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.Bold)
		l.TextWrapped = true; l.TextScaled = true; l.ZIndex = z; l.TextTransparency = 1; l.Parent = gui
		local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = 13; c.MinTextSize = 8; c.Parent = l
		return l
	end
	local shadow = makeLabel(1)
	shadow.Position = UDim2.new(0, 2, 0, 3); shadow.TextColor3 = Color3.fromRGB(0, 0, 0)
	local ss = Instance.new("UIStroke"); ss.Thickness = 2; ss.Color = Color3.fromRGB(0, 0, 0); ss.Transparency = 1; ss.Parent = shadow
	local label = makeLabel(2)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	local stroke = Instance.new("UIStroke"); stroke.Thickness = 1.5; stroke.Color = Color3.fromRGB(0, 0, 0); stroke.LineJoinMode = Enum.LineJoinMode.Round; stroke.Transparency = 1; stroke.Parent = label
	-- sparkles: spawn on a sphere around the words and fly outward, big enough to read from a distance
	local function emitter(color, size, rate, life, speed)
		local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = color
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, size), NumberSequenceKeypoint.new(1, 0)})
		pe.Transparency = NumberSequence.new(0); pe.Lifetime = life; pe.Speed = speed
		pe.Shape = Enum.ParticleEmitterShape.Sphere; pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		pe.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward; pe.SpreadAngle = Vector2.new(25, 25)
		pe.Rate = rate; pe.LightEmission = 1; pe.LightInfluence = 0; pe.Brightness = 2
		pe.Rotation = NumberRange.new(0, 360); pe.RotSpeed = NumberRange.new(-150, 150); pe.Drag = 2
		pe.Acceleration = Vector3.new(0, 1.5, 0); pe.ZOffset = 0.5; pe.Parent = anchor
		return pe
	end
	local gold = emitter(ColorSequence.new(Color3.fromRGB(255, 230, 150), Color3.fromRGB(255, 200, 90)), 0.9, 30, NumberRange.new(0.9, 1.6), NumberRange.new(2, 5))
	local white = emitter(ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 240, 255)), 0.6, 22, NumberRange.new(0.7, 1.3), NumberRange.new(1.5, 4))
	gold:Emit(60); white:Emit(40)
	-- straight up, fade in fast, fade out as it climbs
	local FADE_FROM = 0.25
	local t = 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		local k = math.clamp(t / T, 0, 1)
		local ease = 1 - (1 - k) ^ 2
		anchor.Position = top + Vector3.new(0, RISE * ease, 0)
		local vis = math.clamp(1 - t / 0.3, 0, 1)                   -- fade in over 0.3 s
		if k > FADE_FROM then vis = math.max(vis, (k - FADE_FROM) / (1 - FADE_FROM)) end
		label.TextTransparency = vis; stroke.Transparency = vis
		shadow.TextTransparency = 0.55 + 0.45 * vis; ss.Transparency = 0.55 + 0.45 * vis
		if k > 0.55 then gold.Enabled = false; white.Enabled = false end
		if k >= 1 then conn:Disconnect(); task.delay(1.5, function() anchor:Destroy() end) end
	end)
end

local function reveal(model, st)
	local mesh = st.mesh
	local color = mesh:GetAttribute("ColorTexture")
	st.found = true; st.revealT = 0
	task.delay(0.6, function() fillBadge(model, st) end)
	-- sparkle burst in rainbow colours
	local att = Instance.new("Attachment"); att.Name = "RevealSparkle"; att.Parent = mesh
	att.Position = mesh.CFrame:PointToObjectSpace(mesh.Position + Vector3.new(0, mesh.Size.Y * 0.2, 0))
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 190, 60)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120, 230, 90)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(80, 170, 255)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(150, 90, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 220))})
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new(0.1); pe.Lifetime = NumberRange.new(0.6, 1.1); pe.Speed = NumberRange.new(4, 8)
	pe.SpreadAngle = Vector2.new(180, 180); pe.Rate = 0; pe.LightEmission = 0.8; pe.Parent = att
	pe:Emit(40)
	-- FoundSound attribute on the folder: any sound id; default is Roblox's built-in ta-da fanfare
	local snd = Instance.new("Sound"); snd.SoundId = script.Parent:GetAttribute("FoundSound") or "rbxassetid://1845415163"
	snd.Volume = 0.9; snd.PlaybackSpeed = 1; snd.RollOffMaxDistance = 60; snd.Parent = mesh; snd:Play()
	task.delay(0.15, function() if color then setTex(mesh, color) end end)
	task.delay(4, function() att:Destroy(); snd:Destroy() end)
	nameTag(model, mesh)
end
if ev then
	ev.OnClientEvent:Connect(function(id)
		foundIds[id] = true
		local model, st = byId(id)
		if model and not st.found then reveal(model, st) end
		updateCounter()
	end)
end

-- bone posing in squirrel-space axes (same trick as the pup)
local function pose(st, name, pitch, yaw, roll, offF, offU, offL)
	local w = st.want[name]
	if not w then w = {0, 0, 0, 0, 0, 0}; st.want[name] = w end
	w[1] += pitch or 0; w[2] += yaw or 0; w[3] += roll or 0; w[4] += offF or 0; w[5] += offU or 0; w[6] += offL or 0
end
local function apply(st, fwdW, upW, leftW, scale)
	for _, name in ipairs(ORDER) do
		local b = st.bones[name]
		if b then
			local w = st.want[name]
			if not w then b.Transform = CFrame.identity
			else
				local parent = b.Parent
				local pw = (parent:IsA("Bone") and parent.TransformedWorldCFrame) or st.mesh.CFrame
				local R = (pw * b.CFrame).Rotation
				local lLeft, lUp, lFwd = R:VectorToObjectSpace(leftW), R:VectorToObjectSpace(upW), R:VectorToObjectSpace(fwdW)
				local off = R:VectorToObjectSpace((fwdW * w[4] + upW * w[5] + leftW * w[6]) * scale)
				b.Transform = CFrame.new(off) * CFrame.fromAxisAngle(lUp, math.rad(w[2])) * CFrame.fromAxisAngle(lLeft, math.rad(w[1])) * CFrame.fromAxisAngle(lFwd, math.rad(w[3]))
			end
		end
	end
end

task.spawn(function() while true do task.wait(2) if counter then updateCounter() end end end)
local cam = workspace.CurrentCamera
RunService.Heartbeat:Connect(function(dt)
	for model, st in pairs(squirrels) do
		local mesh = st.mesh
		if not mesh.Parent then squirrels[model] = nil continue end
		-- skip the maths for squirrels far from the camera
		if cam and (cam.CFrame.Position - mesh.Position).Magnitude > 180 then continue end
		st.t += dt
		local t = st.t
		local scale = mesh.Size.Y / BLENDER_HEIGHT
		local fwdW, upW, leftW = mesh.CFrame:VectorToWorldSpace(st.fwdL), mesh.CFrame:VectorToWorldSpace(st.upL), mesh.CFrame:VectorToWorldSpace(st.leftL)
		table.clear(st.want)
		local calm = st.found and 1 or 0.6          -- gray ones are a little sleepier
		-- breathing
		local breathe = math.sin(t * 1.6) * 0.5 + 0.5
		pose(st, "Chest", -1.5 * breathe * calm, 0, 0, 0, 0.012 * breathe, 0)
		pose(st, "Root", 0, 0, 0, 0, 0.008 * math.sin(t * 1.6), 0)
		-- head: look around, tilt when curious
		st.lookTimer -= dt
		if st.lookTimer <= 0 then
			st.lookTarget = rng:NextNumber(-22, 22); st.lookTimer = rng:NextNumber(2, 5)
			st.tiltTarget = (rng:NextNumber() < 0.35) and rng:NextNumber(-12, 12) or 0
		end
		st.lookYaw += (st.lookTarget - st.lookYaw) * math.min(1, dt * 4)
		st.tilt += (st.tiltTarget - st.tilt) * math.min(1, dt * 3)
		pose(st, "Neck", 0, st.lookYaw * 0.35, 0)
		pose(st, "Head", math.sin(t * 0.9) * 1.5, st.lookYaw * 0.65, st.tilt)
		-- tail: slow sway with a lag down the tail, plus a quick flick now and then
		st.flickTimer -= dt
		if st.flickTimer <= 0 then st.flick = 1; st.flickTimer = rng:NextNumber(4, 11) end
		st.flick = math.max(0, st.flick - dt * 2.2)
		local sway1 = math.sin(t * 1.4) * 5 * calm
		local sway2 = math.sin(t * 1.4 - 0.9) * 8 * calm
		local fl = math.sin(st.flick * math.pi) * 18
		pose(st, "Tail1", sway1 * 0.4 + fl * 0.6, sway1, 0)
		pose(st, "Tail2", sway2 * 0.5 + fl, sway2, 0)
		-- an occasional little hop (found squirrels only) and the reveal hop
		st.hopTimer -= dt
		if st.hopTimer <= 0 then if st.found then st.hop = 1 end; st.hopTimer = rng:NextNumber(10, 25) end
		st.hop = math.max(0, st.hop - dt * 3)
		local hopK = math.sin(st.hop * math.pi)
		if st.revealT >= 0 then
			st.revealT += dt
			local k = math.min(st.revealT / 0.9, 1)
			hopK = math.max(hopK, math.sin(k * math.pi) * 1.6)
			if k >= 1 then st.revealT = -1 end
		end
		if hopK > 0 then
			pose(st, "Root", 0, 0, 0, 0, 0.28 * hopK, 0)
			pose(st, "Chest", -6 * hopK, 0, 0)
			pose(st, "Tail1", 12 * hopK, 0, 0); pose(st, "Tail2", 10 * hopK, 0, 0)
		end
		apply(st, fwdW, upW, leftW, scale)
	end
end)
print("SquirrelAnim running")
'''

REGISTRY = r'''
-- SquirrelRegistry: the one list of every squirrel in the game. Both the server and the HUD read this.
-- id      stable key used for saving finds (the model in the world is named "<id>_color" / "<id>_gray")
-- map     which map the squirrel lives on (see maps below)
-- name    what the tag, badge and card show
-- bio     the card text
-- face    optional badge framing tweaks: dist (camera distance, default 1.35), up (aim height, default 0), camUp (camera height, default 0.05)
-- Add new squirrels here; nothing else needs editing.
return {
	maps = {
		{id = "forest",  name = "Squirrelpalooza Forest"},
		{id = "village", name = "Mademoiselle Wagner's Cours de français et écureuils"},
	},
	squirrels = {
		{id = "detective_squirrel",    map = "forest", name = "Mr. Holmes Squirrel",   face = {dist = 1.7, up = -0.02},
		 bio = "Solves mysteries nobody asked him to solve. Currently investigating the Case of the Missing Acorn. He ate it."},
		{id = "rainy_day_squirrel",    map = "forest", name = "Rainy Day Squirrel",    face = {dist = 1.6, up = -0.09, camUp = -0.24},
		 bio = "Ready for weather at all times, even indoors. Has never once been caught without her umbrella. Or her spare umbrella."},
		{id = "squirrel_buccaneer",    map = "forest", name = "Buccaneer Squirrel",
		 bio = "Sailed the seven puddles in search of buried acorns. Has a treasure map, but keeps reading it upside down."},
		{id = "squirrel_scientist",    map = "forest", name = "El Scientifico",
		 bio = "Holds three degrees in Acorn Physics and one in Explosions. Every experiment ends with 'well, THAT was interesting.'"},
		{id = "surfing_squirrel",      map = "forest", name = "Surfer Dude Squirrel",
		 bio = "Rides the gnarliest waves in the forest, which are mostly puddles. Says 'dude' more than any squirrel should."},
		{id = "super_squirrel",        map = "forest", name = "Nacho Libre Squirrel",  face = {dist = 1.75, up = -0.04},
		 bio = "Masked defender of the forest and its snacks. Weakness: nachos. Also cheese. Also anything with cheese on it."},
		{id = "gordo_squirrel",        map = "forest", name = "Gordo Squirrel",
		 bio = "Gordo has never met an acorn he didn't like. Or two. Or the whole tree. Hobbies include napping, snacking, and napping after snacking."},
		{id = "fairy_squirrel",        map = "forest", name = "Fairy Squirrel",        face = {dist = 1.5, up = -0.02},
		 bio = "Sprinkles glitter wherever she goes, mostly by accident. Grants wishes on Tuesdays, but only small ones, like finding a really good acorn."},
		{id = "ski_squirrel",          map = "forest", name = "Ski-a-roo Squirrel",
		 bio = "Skis all year round, snow or no snow. Has yet to make it down a hill without hugging a tree."},
		{id = "ballerina_squirrel",    map = "forest", name = "Ballerina Squirrel",
		 bio = "Practices pirouettes on tree branches, to the great alarm of the birds. The tutu is very serious business."},
		{id = "baking_betty_squirrel", map = "forest", name = "Baking Betty Squirrel",
		 bio = "Bakes forty cupcakes a day and eats thirty-nine of them for quality control. Her frosting is legendary. So is her sugar rush."},
		{id = "mailman_squirrel",      map = "village", name = "Mailman Squirrel",  face = {dist = 1.69, up = -0.015, side = -0.002},
		 bio = "Neither rain, nor snow, nor a very long nap can keep him from his rounds. Has delivered every letter in town, and read most of them."},
		{id = "philosopher_squirrel",  map = "village", name = "Philosopher Squirrel",  face = {dist = 1.53, up = -0.064, side = 0.003},
		 bio = "Spends his days at the café wondering whether a squirrel nobody ever finds was really hiding at all. Has been on the same cup of coffee since Tuesday."},
		{id = "waiter_squirrel",       map = "village", name = "French Waiter Squirrel",  face = {dist = 1.35, up = -0.031, side = 0.002},
		 bio = "Carries his tray with one paw at all times, even while napping. Will bring your café au lait eventually, and sigh very dramatically while doing it."},
		{id = "mime_squirrel",         map = "village", name = "Marcel the Mime Squirrel",  face = {dist = 1.55, up = -0.007, side = 0.063},
		 bio = "Has been trapped inside an invisible box since 1987. Refuses to say how he got in. Refuses to say anything at all, actually."},
		{id = "cyclist_squirrel",      map = "village", name = "Cyclist Squirrel",  face = {dist = 1.30, up = -0.024, side = 0.029},
		 bio = "Has been training for the Tour de France for years. Owns the helmet, the gloves and the very tight shorts. Still working on the part where he actually rides the bike."},
		{id = "glam_squirrel",         map = "village", name = "Glam Squirrel",  face = {dist = 1.41, up = -0.020, side = -0.002},
		 bio = "Never leaves home without her pearls and sunglasses, even to pick up a croissant. Treats every sidewalk like a runway, and every sidewalk agrees."},
		{id = "bird_feeder_squirrel",  map = "village", name = "Bird Feeder Squirrel",  face = {dist = 1.40, up = -0.144, side = 0.091},
		 bio = "Shows up at the fountain every morning with a pocketful of breadcrumbs, rain or shine. The pigeons started a fan club. Then they started a union."},
		{id = "firefighter_squirrel",  map = "village", name = "Firefighter Squirrel",  face = {dist = 1.56, up = -0.023, side = -0.018},
		 bio = "Has rescued nine cats from trees, which is very brave for a squirrel. Slides down the fire pole even when there is no fire. Especially when there is no fire."},
		{id = "tourist_squirrel",      map = "village", name = "Tourist Squirrel",  face = {dist = 1.35, up = -0.020, side = -0.024},
		 bio = "Took four thousand photos of the same bakery and loves every one of them. Asks for directions to the Eiffel Tower every morning, which is tricky, because it is not in this town."},
		{id = "painter_squirrel",      map = "village", name = "French Painter Squirrel",  face = {dist = 1.48, up = -0.007, side = -0.004},
		 bio = "Has painted the town fountain three hundred times and calls every one a masterpiece. Somehow wears more paint than he has ever put on a canvas."},
		{id = "florist_squirrel",      map = "village", name = "Florist Squirrel",  face = {dist = 1.46, up = 0.002, side = -0.035},
		 bio = "Talks to every flower in the shop and swears the tulips talk back. Has sneezed through nine springs in a row and would not trade her job for anything."},
		{id = "spy_squirrel",          map = "village", name = "International Spy Squirrel",  face = {dist = 1.30, up = -0.048, side = -0.096},
		 bio = "Has a secret code name, a secret hideout and a secret handshake. Keeps forgetting all three, which he insists is part of the cover."},
	},
}
'''

def module_item(name, source, ref):
    return f'''
  <Item class="ModuleScript" referent="{ref}">
    <Properties>
      <string name="Name">{name}</string>
      <ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>
    </Properties>
  </Item>'''

def script_item(name, source, run_context, ref):
    return f'''
  <Item class="Script" referent="{ref}">
    <Properties>
      <string name="Name">{name}</string>
      <token name="RunContext">{run_context}</token>
      <bool name="Enabled">true</bool>
      <ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>
    </Properties>
  </Item>'''

xml = f'''<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Item class="Folder" referent="RBX0">
    <Properties><string name="Name">SquirrelScripts</string></Properties>{module_item("SquirrelRegistry", REGISTRY, "RBX3")}{script_item("SquirrelSetup", SETUP, 1, "RBX1")}{script_item("SquirrelAnim", ANIM, 2, "RBX2")}
  </Item>
</roblox>
'''
m.parseString(xml)
OUT.write_text(xml, encoding="utf-8")
print("wrote", OUT)
