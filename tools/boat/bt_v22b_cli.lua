-- bt_v22b v1 (PLAY, CLIENT, test only): frames of the Sky Diving Squirrel's new bubble: the character steps beside him,
-- the camera is parked looking at him from the front-left, the Talk prompt is held, the three lines play (11 s), then
-- the camera is given back.
local plr = game.Players.LocalPlayer
local ch = plr.Character
local sq = workspace:WaitForChild("parachute_squirrel_color", 5)
local mesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
if not mesh then warn("QQ V22B no squirrel"); return end
local hum = ch:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
ch:PivotTo(CFrame.lookAt(mesh.Position + Vector3.new(3.5, 1.5, 5), mesh.Position))
task.wait(1.0)
local cam = workspace.CurrentCamera
cam.CameraType = Enum.CameraType.Scriptable
cam.CFrame = CFrame.lookAt(mesh.Position + Vector3.new(-5, 1.0, 9), mesh.Position + Vector3.new(1.5, 1.6, 0))
local sp = mesh:FindFirstChild("ChutePrompt")
if not sp then warn("QQ V22B no ChutePrompt"); cam.CameraType = Enum.CameraType.Custom; return end
sp.MaxActivationDistance = 30
sp:InputHoldBegin(); task.wait(0.5); sp:InputHoldEnd()
warn(string.format("QQ V22B squirrel at %s, camera parked; HasChute=%s", tostring(mesh.Position), tostring(plr:GetAttribute("HasChute"))))
task.wait(11.5)
cam.CameraType = Enum.CameraType.Custom
warn("QQ V22B camera back")
