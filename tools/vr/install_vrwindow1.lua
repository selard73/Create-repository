-- vr/install_vrwindow1 (job 40): EDIT mode, re-runnable. The VR window: in a headset the flat-screen UI moves onto one
-- floating window that follows the head, visible with Roblox's control panel open or shut. Output lines "QQ VRW".
if game:GetService("RunService"):IsRunning() then warn("QQ VRW ABORT - Play mode") return end
local old = workspace:FindFirstChild("VRWindow"); if old then old:Destroy() end
local F = Instance.new("Folder"); F.Name = "VRWindow"
F:SetAttribute("Yaw", 38); F:SetAttribute("Distance", 2.4); F:SetAttribute("Width", 1.9); F:SetAttribute("Follow", 4); F:SetAttribute("Drop", 0.12); F:SetAttribute("Off", false)
local c = Instance.new("Script"); c.Name = "VRWindowClient"; c.RunContext = Enum.RunContext.Client; c.Source = [===[
-- VRWindowClient (workspace.VRWindow, RunContext Client): in a VR headset, everything the game puts on the flat screen
-- (the squirrels' speech, Bella's panel, the Passport, the race clock, toasts, the Daily card...) is shown on ONE floating
-- window that follows the player's head gently, so it is seen whether Roblox's own VR control panel is open or shut
-- (Shannon, Oct 9 2026: "anything that pops up on the screen should show whether you have the control open or shut, and
-- the one shouldn't cover up the other"). How: a client-side part floats in front of the head; a SurfaceGui in PlayerGui
-- adorned to it is a canvas the size of the real screen; every ScreenGui's children are moved onto it (the game's scripts
-- keep their references, so buttons and updates work; the VR pointer clicks them). Roblox's panel then carries only
-- Roblox's own menus. Does nothing outside VR. Attributes on the folder: Yaw (38 degrees to the right of the body's facing), Distance (2.4 studs),
-- Width (1.9 studs), Follow (4, how quickly it catches up), Drop (0.12, how far below eye level), Off (true disables it).
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

-- where it sits: off to the RIGHT of the way the body faces (Shannon: "off to the side, on your right, so if you face
-- forward you see it out of the corner of your eye, and if you turn your head you see it fully"), eased, never hard-locked
local current
local function headCF()
	local ok, h = pcall(function() return VRService:GetUserCFrame(Enum.UserCFrame.Head) end)
	if ok and h then
		local hs = cam.HeadScale or 1
		return cam.CFrame * CFrame.new(h.Position * hs) * (h - h.Position)
	end
	return cam.CFrame
end
local function bodyForward(head)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local v = root and root.CFrame.LookVector or head.LookVector
	v = Vector3.new(v.X, 0, v.Z)
	if v.Magnitude < 0.05 then v = Vector3.new(0, 0, -1) end
	return v.Unit
end
RunService.RenderStepped:Connect(function(dt)
	local head = headCF()
	local fwd = bodyForward(head)
	local yaw = math.rad(-num("Yaw", 38))                       -- degrees to the right of the body's facing
	local dir = (CFrame.new(Vector3.zero, fwd) * CFrame.Angles(0, yaw, 0)).LookVector
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
]===]; c.Parent = F
local f, err = loadstring(c.Source); if not f then warn("QQ VRW ABORT - VRWindowClient does not compile: " .. tostring(err)); F:Destroy(); return end
F.Parent = workspace
print(string.format("QQ VRW DONE: workspace.VRWindow with VRWindowClient (%d chars); Yaw 38, Distance 2.4, Width 1.9, Follow 4, Drop 0.12", #c.Source))
