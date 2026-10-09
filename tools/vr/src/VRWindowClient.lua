-- VRWindowClient (workspace.VRWindow, RunContext Client): in a VR headset, everything the game puts on the flat screen
-- (the squirrels' speech, Bella's panel, the Passport, the race clock, toasts, the Daily card...) is shown on ONE floating
-- window that follows the player's head gently, so it is seen whether Roblox's own VR control panel is open or shut
-- (Shannon, Oct 9 2026: "anything that pops up on the screen should show whether you have the control open or shut, and
-- the one shouldn't cover up the other"). How: a client-side part floats in front of the head; a SurfaceGui in PlayerGui
-- adorned to it is a canvas the size of the real screen; every ScreenGui's children are moved onto it (the game's scripts
-- keep their references, so buttons and updates work; the VR pointer clicks them). Roblox's panel then carries only
-- Roblox's own menus. Does nothing outside VR. Attributes on the folder: Distance (2.4 studs), Width (1.9 studs),
-- Follow (4, how quickly it catches up), Drop (0.12, how far below eye level), Off (true disables it).
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VRService = game:GetService("VRService")
local RunService = game:GetService("RunService")
local F = script.Parent
local player = Players.LocalPlayer
if not (UIS.VREnabled or VRService.VREnabled) then return end
if F:GetAttribute("Off") == true then print("VRWindow: off by attribute") return end
local function num(name, d) local v = F:GetAttribute(name) return type(v) == "number" and v or d end
local pg = player:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

-- ---------- the window ----------
local part = Instance.new("Part"); part.Name = "VRWindowPart"; part.Anchored = true; part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
part.Transparency = 1; part.CastShadow = false; part.Size = Vector3.new(1.9, 1.1, 0.05); part.Parent = cam
local gui = Instance.new("SurfaceGui"); gui.Name = "VRWindow"; gui.Adornee = part; gui.Face = Enum.NormalId.Back
gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize; gui.AlwaysOnTop = true; gui.LightInfluence = 0; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.ClipsDescendants = false; gui.Parent = pg
local function fit()
	local v = cam.ViewportSize
	if v.X < 2 or v.Y < 2 then v = Vector2.new(1280, 720) end
	gui.CanvasSize = v
	local w = num("Width", 1.9)
	part.Size = Vector3.new(w, w * v.Y / v.X, 0.05)
end
fit()
cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() cam = workspace.CurrentCamera; part.Parent = cam; fit() end)

-- lazy follow: eased toward a spot in front of the head, never hard-locked to it
local current
local function headCF()
	local ok, h = pcall(function() return VRService:GetUserCFrame(Enum.UserCFrame.Head) end)
	if ok and h then
		local hs = cam.HeadScale or 1
		return cam.CFrame * CFrame.new(h.Position * hs) * (h - h.Position)
	end
	return cam.CFrame
end
RunService.RenderStepped:Connect(function(dt)
	local head = headCF()
	local look = head.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.05 then flat = Vector3.new(0, 0, -1) else flat = flat.Unit end
	-- the window sits ahead of the head, level, a little below eye height; it tips to follow a strong up/down look
	local pitch = math.clamp(math.asin(look.Y), math.rad(-35), math.rad(30))
	local dir = (CFrame.new(Vector3.zero, flat) * CFrame.Angles(pitch * 0.6, 0, 0)).LookVector
	local pos = head.Position + dir * num("Distance", 2.4) - Vector3.new(0, num("Drop", 0.12), 0)
	local target = CFrame.lookAt(pos, head.Position)
	if not current then current = target
	else
		local k = 1 - math.exp(-dt * num("Follow", 4))
		current = current:Lerp(target, k)
	end
	part.CFrame = current
end)

-- ---------- adopting the flat screen ----------
local containers = {}          -- [ScreenGui] = Frame
local SKIP = {VRWindow = true}
local function adopt(sg)
	if not sg:IsA("ScreenGui") or SKIP[sg.Name] or containers[sg] then return end
	local box = Instance.new("Frame"); box.Name = sg.Name; box.BackgroundTransparency = 1; box.BorderSizePixel = 0
	box.Size = UDim2.fromScale(1, 1); box.ZIndex = 1000 + (sg.DisplayOrder or 0); box.Visible = sg.Enabled; box.Parent = gui
	containers[sg] = box
	local function take(c)
		if c:IsA("GuiObject") or c:IsA("UIBase") then c.Parent = box end
	end
	for _, c in ipairs(sg:GetChildren()) do take(c) end
	sg.ChildAdded:Connect(take)
	sg:GetPropertyChangedSignal("Enabled"):Connect(function() box.Visible = sg.Enabled end)
	sg:GetPropertyChangedSignal("DisplayOrder"):Connect(function() box.ZIndex = 1000 + (sg.DisplayOrder or 0) end)
	sg.AncestryChanged:Connect(function()
		if not sg:IsDescendantOf(pg) then box:Destroy(); containers[sg] = nil end
	end)
end
for _, sg in ipairs(pg:GetChildren()) do adopt(sg) end
pg.ChildAdded:Connect(function(sg) task.defer(adopt, sg) end)
-- (a ScreenGui that arrives empty and fills later is covered by ChildAdded; one that scripts rebuild after a respawn too)
print(string.format("VRWindow: on (%d screens adopted, canvas %dx%d)", (function() local n = 0 for _ in pairs(containers) do n += 1 end return n end)(), gui.CanvasSize.X, gui.CanvasSize.Y))
