-- (wall1, Oct 22 2026) two more rows under the rugs, through DecorServer:
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
refreshMore()
