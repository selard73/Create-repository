-- bt_full2 v1 (PLAY, CLIENT, test only): a look at the river drift from above the jetty (2.5 s), then the whole end-game path
-- (squirrel, jetty, boat to the brink; then hold W), and during the descent a close camera on the rider for 3 s plus a
-- print of the hip and knee joints (are they bent?).
local plr = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local function char() return plr.Character end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local cam = workspace.CurrentCamera
-- 0. the river from above the jetty
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame = CFrame.lookAt(Vector3.new(150, 14, -196), Vector3.new(152, -1, -214))
task.wait(2.5)
cam.CameraType = Enum.CameraType.Custom
-- 1. the squirrel
local sq = workspace:WaitForChild("parachute_squirrel_color", 5)
local mesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
if not mesh then warn("QQ BF2 no squirrel"); return end
local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
char():PivotTo(CFrame.lookAt(mesh.Position + Vector3.new(0, 1.5, 5), mesh.Position))
task.wait(1.2)
local sp = mesh:FindFirstChild("ChutePrompt")
if not sp then warn("QQ BF2 no ChutePrompt"); return end
sp.MaxActivationDistance = 30
sp:InputHoldBegin(); task.wait(0.5); sp:InputHoldEnd()
task.wait(1.5)
-- a close look at the pack: the camera 4 studs behind the character, a little above
local hrp = char():FindFirstChild("HumanoidRootPart")
if hrp then
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.lookAt(hrp.Position + hrp.CFrame.LookVector * -4.5 + Vector3.new(0, 1.2, 0), hrp.Position + Vector3.new(0, 0.6, 0))
	task.wait(2.0)
	cam.CameraType = Enum.CameraType.Custom
end
warn(string.format("QQ BF2 squirrel: pack=%s HasChute=%s", tostring(char():FindFirstChild("ChutePack") ~= nil), tostring(plr:GetAttribute("HasChute"))))
-- 2. the jetty
h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.GettingUp) end
char():PivotTo(CFrame.lookAt(Vector3.new(161.6, 3.6, -165.5), Vector3.new(157.6, 3.6, -165.5)))
task.wait(1.0)
local prompt = workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt
prompt.RequiresLineOfSight = false; prompt.MaxActivationDistance = 30
task.wait(0.5)
prompt:InputHoldBegin(); task.wait(0.7); prompt:InputHoldEnd()
task.wait(1.5)
local m = workspace.Boat:FindFirstChild("Boat_" .. plr.UserId)
warn(string.format("QQ BF2 jetty: boat=%s", tostring(m ~= nil)))
if not m then return end
-- 3. the brink, and the watcher for the descent
task.wait(0.5)
local hull = m.PrimaryPart
m:PivotTo(CFrame.new(184.3, hull.Position.Y, -534.0))
task.wait(0.3)
warn(string.format("QQ BF2 boat at (%.1f, %.1f, %.1f) - hold W now", hull.Position.X, hull.Position.Y, hull.Position.Z))
task.spawn(function()
	local c = char()
	local chute = c:WaitForChild("Parachute", 20)
	if not chute then warn("QQ BF2 no parachute appeared"); return end
	task.wait(0.6)
	local function ang(partName, motorName)
		local p = c:FindFirstChild(partName); local mo = p and p:FindFirstChild(motorName)
		if not mo then return "?" end
		local x = select(1, mo.C0:ToEulerAnglesXYZ())
		return string.format("%.0f deg%s", math.deg(x), mo:GetAttribute("ChuteC0") ~= nil and " (bent)" or "")
	end
	warn(string.format("QQ BF2 rider joints: LeftHip %s, LeftKnee %s, LeftShoulder %s", ang("LeftUpperLeg", "LeftHip"), ang("LeftLowerLeg", "LeftKnee"), ang("LeftUpperArm", "LeftShoulder")))
	local root = c:FindFirstChild("HumanoidRootPart")
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not root.Parent or os.clock() - t0 > 3 then conn:Disconnect(); return end
		cam.CFrame = CFrame.lookAt(root.Position + Vector3.new(-5, 0.5, 4), root.Position + Vector3.new(0, 1.5, 0))
	end)
end)
