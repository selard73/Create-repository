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
