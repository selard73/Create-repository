-- j1 build the boat jetty: workspace.River.Jetty (deck along the Rue quay wall, south of the bridge). Rebuilds only its own folder.
local River = workspace.River
local old = River:FindFirstChild("Jetty"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "Jetty"; F:SetAttribute("Built", "j1 2026-09-30"); F.Parent = River
local PLANK, BEAM, ROPE = Color3.fromRGB(160, 120, 85), Color3.fromRGB(130, 100, 75), Color3.fromRGB(214, 190, 140)
local rng = Random.new(7)
local function part(name, size, cf, color, shape, collide)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color
	p.Material = Enum.Material.SmoothPlastic; p.Anchored = true; p.CanCollide = collide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	p.Parent = F; return p
end
local X0, X1 = 160.1, 163.6          -- deck across (x 163.65 = kerb face)
local Z0, Z1 = -146.0, -168.0        -- deck along
local TOP = 0.6                      -- kerb top is 0.775: a small step down onto the boards
local PT = 0.22
-- planks
local n = 0
local z = Z0
while z - 0.92 >= Z1 - 0.01 do
	n += 1
	local c = PLANK:Lerp(rng:NextNumber() < 0.5 and Color3.fromRGB(150, 110, 76) or Color3.fromRGB(172, 132, 94), rng:NextNumber() * 0.6)
	local dx = rng:NextNumber(-0.06, 0.06)
	part("Plank", Vector3.new(X1 - X0 - 0.05, PT, 0.9), CFrame.new((X0 + X1) / 2 + dx, TOP - PT / 2, z - 0.46), c)
	z -= 1.0
end
-- stringers under the planks
local SB = TOP - PT
for _, x in ipairs({160.55, 162.0, 163.3}) do
	part("Stringer", Vector3.new(0.4, 0.45, Z0 - Z1), CFrame.new(x, SB - 0.225, (Z0 + Z1) / 2), BEAM)
end
-- posts: raycast each one to the river bed (terrain, ignoring water) and bury it 0.6
local rp = RaycastParams.new(); rp.IgnoreWater = true; rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {workspace.Terrain}
local report = {}
local function post(x, zz, topY, name)
	local r = workspace:Raycast(Vector3.new(x, 0, zz), Vector3.new(0, -30, 0), rp)
	local bed = r and r.Position.Y or -6
	local bot = bed - 0.6
	local h = topY - bot
	local p = part(name, Vector3.new(h, 0.55, 0.55), CFrame.new(x, (topY + bot) / 2, zz) * CFrame.Angles(0, 0, math.rad(90)), BEAM, Enum.PartType.Cylinder)
	table.insert(report, ("%s %.1f,%.1f bed %.2f"):format(name, x, zz, bed))
	return p
end
local POSTZ = {-146.35, -151.75, -157.15, -162.55, -167.65}
for i, zz in ipairs(POSTZ) do
	local tall = post(160.3, zz, TOP + 0.85, "PostOuter")                  -- stands 0.85 above the boards: mooring posts
	local cap = part("PostCap", Vector3.new(0.12, 0.62, 0.62), CFrame.new(160.3, TOP + 0.85 + 0.06, zz) * CFrame.Angles(0, 0, math.rad(90)), PLANK, Enum.PartType.Cylinder)
	post(163.3, zz, SB - 0.45, "PostInner")                                 -- under the boards, against the wall
	part("Bearer", Vector3.new(X1 - 160.3 + 0.2, 0.35, 0.4), CFrame.new((160.3 + X1) / 2, SB - 0.45 - 0.175, zz), BEAM)
	if i == 2 or i == 4 then                                                -- rope rings on two mooring posts
		part("Rope", Vector3.new(0.14, 0.66, 0.66), CFrame.new(160.3, TOP + 0.45, zz) * CFrame.Angles(0, 0, math.rad(90)), ROPE, Enum.PartType.Cylinder)
		part("Rope", Vector3.new(0.14, 0.66, 0.66), CFrame.new(160.3, TOP + 0.62, zz) * CFrame.Angles(0, 0, math.rad(90)), ROPE, Enum.PartType.Cylinder)
	end
end
-- a small sign at the south end, facing the street (+x)
local SX, SZ = 162.6, -167.3
part("SignPost", Vector3.new(0.3, 2.3, 0.3), CFrame.new(SX, TOP + 1.15, SZ), BEAM)
local board = part("SignBoard", Vector3.new(0.18, 1.0, 2.2), CFrame.new(SX + 0.24, TOP + 1.95, SZ), Color3.fromRGB(244, 232, 204))
local frame = part("SignFrame", Vector3.new(0.14, 1.16, 2.36), CFrame.new(SX + 0.17, TOP + 1.95, SZ), BEAM)
local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Right; sg.CanvasSize = Vector2.new(440, 200); sg.LightInfluence = 1; sg.Parent = board
local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Font = Enum.Font.FredokaOne
t.Text = "BATEAUX"; t.TextScaled = true; t.TextColor3 = Color3.fromRGB(62, 40, 26); t.Parent = sg
local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 30); pad.PaddingRight = UDim.new(0, 30); pad.PaddingTop = UDim.new(0, 36); pad.PaddingBottom = UDim.new(0, 36); pad.Parent = t
-- sign sits on the deck: its post bottom is the deck top
print("QQ JETTY planks " .. n .. " parts " .. #F:GetChildren())
for _, s in ipairs(report) do print("QQ POST " .. s) end
-- first look: from the forest bank, low
local cam = workspace.CurrentCamera
cam.FieldOfView = 50
cam.CFrame = CFrame.lookAt(Vector3.new(146, 4.5, -170), Vector3.new(161.5, 0.2, -156))
print("QQ DONE j1")
