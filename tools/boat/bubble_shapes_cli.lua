-- bubble_shapes v1 (PLAY, CLIENT, test only): three shapes of the squirrel bubble over the Sky Diving Squirrel, labelled
-- A / B / C, cream, BuilderSans Medium 16, for Shannon to pick on screen. A = rounded box (corner 14, the first one she
-- approved), B = a true oval (a circle image stretched, with a brown rim), C = a box rounded halfway (corner 24).
-- Nothing is installed. Camera parked 90 s.
local plr = game.Players.LocalPlayer
local sq = workspace:WaitForChild("parachute_squirrel_color", 5)
local mesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
if not mesh then warn("QQ BSHAPE no squirrel"); return end
local ch = plr.Character
local hum = ch and ch:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
ch:PivotTo(CFrame.lookAt(mesh.Position + Vector3.new(4, 1.5, 6), mesh.Position))
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
local camCF = CFrame.lookAt(mesh.Position + Vector3.new(-4, 5.0, 12), mesh.Position + Vector3.new(1.5, 5.6, 0))
cam.CFrame = camCF
local PAPER, INK, TEXT_INK = Color3.fromRGB(255, 250, 240), Color3.fromRGB(120, 80, 46), Color3.fromRGB(64, 42, 22)
local FACE = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
local CIRCLE = "rbxassetid://3570695787"
local function gui(W, H, yoff)
	local bg = Instance.new("BillboardGui"); bg.Name = "ShapeTest"; bg.Size = UDim2.fromOffset(W, H)
	bg.StudsOffset = Vector3.new(0, 0.8 + yoff, 0); bg.ExtentsOffset = Vector3.new(0.9, 1.0, 0)
	bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.MaxDistance = 80; bg.Adornee = mesh
	game:GetService("Debris"):AddItem(bg, 90)
	return bg
end
local function label(parent, text, insetX)
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -2 * insetX, 1, -10); l.Position = UDim2.fromOffset(insetX, 5); l.BackgroundTransparency = 1
	l.FontFace = FACE; l.TextSize = 16; l.TextWrapped = true; l.TextColor3 = TEXT_INK; l.Text = text; l.ZIndex = 4; l.Parent = parent
end
local function tail(bg, x)
	local t = Instance.new("Frame"); t.AnchorPoint = Vector2.new(0.5, 0.5); t.Position = UDim2.new(x, 0, 1, -3); t.Size = UDim2.fromOffset(13, 13)
	t.Rotation = 45; t.BackgroundColor3 = PAPER; t.BorderSizePixel = 0; t.ZIndex = 1; t.Parent = bg
	local ts = Instance.new("UIStroke"); ts.Color = INK; ts.Thickness = 1.5; ts.Parent = t
	local cover = Instance.new("Frame"); cover.Position = UDim2.new(x, -8, 1, -12); cover.Size = UDim2.fromOffset(16, 11)
	cover.BackgroundColor3 = PAPER; cover.BorderSizePixel = 0; cover.ZIndex = 3; cover.Parent = bg
end
local function box(text, yoff, radius, insetX)
	local bg = gui(250, 60, yoff)
	local f = Instance.new("Frame"); f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = PAPER; f.BorderSizePixel = 0; f.ZIndex = 2; f.Parent = bg
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, radius); c.Parent = f
	local st = Instance.new("UIStroke"); st.Color = INK; st.Thickness = 1.5; st.Parent = f
	tail(bg, 0.16)
	label(f, text, insetX)
	bg.Parent = plr:WaitForChild("PlayerGui")
end
local function oval(text, yoff)
	local bg = gui(270, 74, yoff)
	local rim = Instance.new("ImageLabel"); rim.Size = UDim2.new(1, 4, 1, 4); rim.Position = UDim2.fromOffset(-2, -2); rim.BackgroundTransparency = 1
	rim.Image = CIRCLE; rim.ImageColor3 = INK; rim.ScaleType = Enum.ScaleType.Stretch; rim.ZIndex = 1; rim.Parent = bg
	local paper = Instance.new("ImageLabel"); paper.Size = UDim2.fromScale(1, 1); paper.BackgroundTransparency = 1
	paper.Image = CIRCLE; paper.ImageColor3 = PAPER; paper.ScaleType = Enum.ScaleType.Stretch; paper.ZIndex = 2; paper.Parent = bg
	local t = Instance.new("Frame"); t.AnchorPoint = Vector2.new(0.5, 0.5); t.Position = UDim2.new(0.2, 0, 1, -8); t.Size = UDim2.fromOffset(13, 13)
	t.Rotation = 45; t.BackgroundColor3 = PAPER; t.BorderSizePixel = 0; t.ZIndex = 1; t.Parent = bg
	local ts = Instance.new("UIStroke"); ts.Color = INK; ts.Thickness = 1.5; ts.Parent = t
	label(bg, text, 26)
	bg.Parent = plr:WaitForChild("PlayerGui")
end
local line = "I packed it myself, so it will probably open."
box("A   " .. line, 5.8, 14, 8)
oval("B   " .. line, 2.9)
box("C   " .. line, 0, 24, 14)
warn("QQ BSHAPE A = box r14 / B = oval / C = box r24, cream, BuilderSans Medium 16, shown for 90 s")
for i = 1, 90 do cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = camCF; task.wait(1) end
cam.CameraType = Enum.CameraType.Custom
warn("QQ BSHAPE camera back")
