-- VRWindowClient (workspace.VRWindow, RunContext Client): in a VR headset, the game's pop-ups (the squirrels' speech,
-- Bella's panel, the Passport, the race clock, toasts, the Daily card, banners...) are shown on ONE floating window off to
-- the RIGHT of the way the body faces, so they are seen whether Roblox's own VR control panel is open or shut (Shannon,
-- Oct 9 2026: "anything that pops up on the screen should show whether you have the control open or shut; off to the
-- side, on your right, so if you face forward you see it out of the corner of your eye and if you turn your head you see
-- it fully"). How: a client-side part floats to the right; a SurfaceGui in PlayerGui adorned to it is a canvas the size of
-- the real screen; the children of each adopted ScreenGui are moved onto it (the game's scripts keep their references,
-- so buttons and updates work; the VR pointer clicks them). Roblox collapses the whole PlayerGui when its panel is shut
-- (its core script turns user-GUI rendering off), while SurfaceGuis in the world stay. HUD-and-shop screens that other
-- scripts look up by name stay where they are (SKIP below). Does nothing outside VR.
-- Attributes on the folder: Yaw (38 degrees to the right of the body's facing), Distance (3.0 studs = 0.9 m), Width
-- (2.2 studs), Follow (2.5, how quickly it catches up), Drop (0.15, below eye level), Off (true disables it).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local F = script.Parent
local player = Players.LocalPlayer
if not (UIS.VREnabled or VRService.VREnabled) then return end
if F:GetAttribute("Off") == true then print("VRWindow: off by attribute") return end
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local pg = player:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

-- ---------- the window ----------
-- a local part (never replicated) in the workspace: a part under the camera dies with the camera when it is swapped
local part = Instance.new("Part"); part.Name = "VRWindowPart"; part.Anchored = true; part.CanCollide = false; part.CanTouch = false
part.CanQuery = true                 -- the SurfaceGui's buttons take input only through a queryable adornee
part.Transparency = 1; part.CastShadow = false; part.Size = Vector3.new(2.2, 1.24, 0.05)
part.CFrame = (cam and cam.CFrame or CFrame.new()) * CFrame.new(1.5, -0.2, -3)
part.Parent = workspace
local gui = Instance.new("SurfaceGui"); gui.Name = "VRWindow"; gui.Adornee = part; gui.Face = Enum.NormalId.Front   -- Front = -Z, the side lookAt turns to the head
gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize; gui.AlwaysOnTop = true; gui.LightInfluence = 0; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.ClipsDescendants = true; gui.Parent = pg
local function fit()
	if not cam then return end
	local v = cam.ViewportSize
	if v.X < 2 or v.Y < 2 then v = Vector2.new(1280, 720) end
	gui.CanvasSize = v
	local w = num("Width", 2.2)
	part.Size = Vector3.new(w, w * v.Y / v.X, 0.05)
end
fit()
local vs = cam and cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	cam = workspace.CurrentCamera
	if vs then vs:Disconnect(); vs = nil end
	if cam then vs = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit); fit() end
end)

-- where it sits: to the right of the way the body faces, eased, never hard-locked to the head
local current
local function headCF()
	if not cam then return CFrame.new() end
	local ok, cf = pcall(function() return cam:GetRenderCFrame() end)   -- the camera with the headset's pose applied
	return ok and cf or cam.CFrame
end
local function bodyForward(head)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local v = root and root.CFrame.LookVector or head.LookVector
	v = Vector3.new(v.X, 0, v.Z)
	if v.Magnitude < 0.05 then v = Vector3.new(0, 0, -1) end
	return v.Unit
end
RunService.RenderStepped:Connect(function(dt)
	if not cam then return end
	local head = headCF()
	local fwd = bodyForward(head)
	local yaw = math.rad(-num("Yaw", 38))                       -- degrees to the right of the body's facing
	local dir = (CFrame.new(Vector3.zero, fwd) * CFrame.Angles(0, yaw, 0)).LookVector
	local pos = head.Position + dir * num("Distance", 3.0) - Vector3.new(0, num("Drop", 0.15), 0)
	local target = CFrame.lookAt(pos, head.Position)
	if not current then current = target
	else current = current:Lerp(target, 1 - math.exp(-dt * num("Follow", 2.5))) end
	part.CFrame = current
end)

-- ---------- adopting the pop-ups ----------
-- Screens that other scripts reach into by name stay on Roblox's panel (moving their children would break the purse
-- button, the squirrel panel, the badge medal, the portrait viewer, the shops); a screen can also opt out with the
-- attribute VRWindowSkip = true.
local SKIP = {VRWindow = true, HudBar = true, SquirrelHUD = true, HintGui = true, HonourBar = true, ShopPanel = true, BadgeCase = true, BadgeButton = true,
	PortraitViewer = true, HatShopGui = true, DressShopGui = true, HatShopFade = true, DressShopFade = true, PostOffice = true, BookReader = true,
	PromptTouch = true, BinocularMask = true, CameraGui = true}
local containers = {}          -- [ScreenGui] = {box, conns}
local function adopt(sg)
	if not sg:IsA("ScreenGui") or SKIP[sg.Name] or sg:GetAttribute("VRWindowSkip") == true or containers[sg] then return end
	local box = Instance.new("Frame"); box.Name = sg.Name; box.BackgroundTransparency = 1; box.BorderSizePixel = 0
	box.ZIndex = 1000 + (sg.DisplayOrder or 0); box.Visible = sg.Enabled
	if sg.IgnoreGuiInset then box.Size = UDim2.fromScale(1, 1)
	else local i = GuiService:GetGuiInset(); box.Position = UDim2.fromOffset(0, i.Y); box.Size = UDim2.new(1, 0, 1, -i.Y) end   -- the top-bar inset it was laid out under
	box.Parent = gui
	local function take(c) if c:IsA("GuiObject") or c:IsA("UIBase") then c.Parent = box end end
	for _, c in ipairs(sg:GetChildren()) do take(c) end
	local conns = {}
	table.insert(conns, sg.ChildAdded:Connect(take))
	table.insert(conns, sg:GetPropertyChangedSignal("Enabled"):Connect(function() box.Visible = sg.Enabled end))
	table.insert(conns, sg:GetPropertyChangedSignal("DisplayOrder"):Connect(function() box.ZIndex = 1000 + (sg.DisplayOrder or 0) end))
	table.insert(conns, sg.AncestryChanged:Connect(function()
		if not sg:IsDescendantOf(pg) then
			for _, k in ipairs(conns) do k:Disconnect() end
			box:Destroy(); containers[sg] = nil
		end
	end))
	containers[sg] = {box = box, conns = conns}
end
for _, sg in ipairs(pg:GetChildren()) do adopt(sg) end
pg.ChildAdded:Connect(function(sg) task.defer(adopt, sg) end)
local n = 0; for _ in pairs(containers) do n += 1 end
print(string.format("VRWindow: on (%d screens adopted, canvas %.0fx%.0f)", n, gui.CanvasSize.X, gui.CanvasSize.Y))
