-- bubble_fonts v4 (white vs cream, face A) (PLAY, CLIENT, test only): three copies of the squirrel bubble over the Sky Diving Squirrel in three
-- plainer text faces, labelled A / B / C, so Shannon can pick one on screen. Nothing is installed. Camera parked 90 s.
local plr = game.Players.LocalPlayer
local sq = workspace:WaitForChild("parachute_squirrel_color", 5)
local mesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
if not mesh then warn("QQ BFONT no squirrel"); return end
local ch = plr.Character
local hum = ch and ch:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
ch:PivotTo(CFrame.lookAt(mesh.Position + Vector3.new(4, 1.5, 6), mesh.Position))
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame = CFrame.lookAt(mesh.Position + Vector3.new(-4, 5.0, 12), mesh.Position + Vector3.new(1.5, 5.6, 0))
local PAPER, INK, TEXT_INK = Color3.fromRGB(255, 250, 240), Color3.fromRGB(120, 80, 46), Color3.fromRGB(64, 42, 22)
local function bubble(text, font, size, yoff, paper)
	local PAPER = paper or PAPER
	local W = 250
	local rows = math.max(1, math.ceil(#text * 8.5 / (W - 24)))
	local H = 20 + 20 * rows
	local bg = Instance.new("BillboardGui"); bg.Name = "FontTest"; bg.Size = UDim2.fromOffset(W, H)
	bg.StudsOffset = Vector3.new(0, 0.8 + yoff, 0); bg.ExtentsOffset = Vector3.new(0.9, 1.0, 0)
	bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.MaxDistance = 80; bg.Adornee = mesh
	local f = Instance.new("Frame"); f.Size = UDim2.fromScale(1, 1); f.BackgroundColor3 = PAPER; f.BorderSizePixel = 0; f.ZIndex = 2; f.Parent = bg
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 14); c.Parent = f
	local st = Instance.new("UIStroke"); st.Color = INK; st.Thickness = 1.5; st.Parent = f
	local tail = Instance.new("Frame"); tail.AnchorPoint = Vector2.new(0.5, 0.5); tail.Position = UDim2.new(0.16, 0, 1, -3); tail.Size = UDim2.fromOffset(13, 13)
	tail.Rotation = 45; tail.BackgroundColor3 = PAPER; tail.BorderSizePixel = 0; tail.ZIndex = 1; tail.Parent = bg
	local ts = Instance.new("UIStroke"); ts.Color = INK; ts.Thickness = 1.5; ts.Parent = tail
	local cover = Instance.new("Frame"); cover.Position = UDim2.new(0.16, -8, 1, -12); cover.Size = UDim2.fromOffset(16, 11)
	cover.BackgroundColor3 = PAPER; cover.BorderSizePixel = 0; cover.ZIndex = 3; cover.Parent = bg
	local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, -16, 1, -10); l.Position = UDim2.fromOffset(8, 5); l.BackgroundTransparency = 1
	l.FontFace = font; l.TextSize = size; l.TextWrapped = true; l.TextColor3 = TEXT_INK; l.Text = text; l.ZIndex = 4; l.Parent = f
	bg.Parent = plr:WaitForChild("PlayerGui")
	game:GetService("Debris"):AddItem(bg, 90)
end
local line = "I packed it myself, so it will probably open."
local A = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
bubble("WHITE   " .. line, A, 16, 3.0, Color3.fromRGB(255, 255, 255))
bubble("CREAM   " .. line, A, 16, 0, Color3.fromRGB(255, 250, 240))
warn("QQ BFONT white (top) vs cream (bottom), BuilderSans Medium 16, shown for 90 s")
local camCF = cam.CFrame
for i = 1, 90 do cam.CameraType = Enum.CameraType.Scriptable; cam.CFrame = camCF; task.wait(1) end
cam.CameraType = Enum.CameraType.Custom
warn("QQ BFONT camera back")
