-- bt_full3 v3 (PLAY, CLIENT, test only): the whole end-game path (squirrel, jetty, boat to the brink; then hold W) with no
-- camera changes before the handover (they stopped the prompt from firing), and during the descent a close cinematic shot
-- (CineOffset attribute) plus a print of the hip and knee joints (are they bent?).
local plr = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local function char() return plr.Character end
local function hum() local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end
local cam = workspace.CurrentCamera
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
task.wait(2)
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
plr:SetAttribute("CineOffset", Vector3.new(-7, 2, 5))                   -- a close shot of the rider for this test (client-side attribute)
warn(string.format("QQ BF2 boat at (%.1f, %.1f, %.1f) - hold W now", hull.Position.X, hull.Position.Y, hull.Position.Z))
task.spawn(function()
	local c = char()
	local chute = c:WaitForChild("Parachute", 20)
	if not chute then warn("QQ BF2 no parachute appeared"); return end
	task.wait(0.6)
	local function ang(partName, attName)
		local p = c:FindFirstChild(partName); local a = p and p:FindFirstChild(attName)
		if not a then return "?" end
		local x = select(1, a.CFrame:ToEulerAnglesXYZ())
		return string.format("%.0f deg%s", math.deg(x), a:GetAttribute("ChuteCF") ~= nil and " (bent)" or "")
	end
	warn(string.format("QQ BF2 rider joints: LeftHip %s, LeftKnee %s, LeftShoulder %s", ang("LowerTorso", "LeftHipRigAttachment"), ang("LeftUpperLeg", "LeftKneeRigAttachment"), ang("UpperTorso", "LeftShoulderRigAttachment")))
end)
