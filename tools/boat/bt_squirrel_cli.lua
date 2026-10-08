-- bt_squirrel v1 (PLAY, CLIENT, test only): teleports this client's character next to the Sky Diving Squirrel and holds his
-- Talk prompt programmatically, then reports the pack and the HasChute flag as the client sees them.
local plr = game.Players.LocalPlayer
local ch = plr.Character
local sq = workspace:WaitForChild("parachute_squirrel_color", 5)
local mesh = sq and sq:FindFirstChildWhichIsA("MeshPart", true)
if not mesh then warn("QQ BSQ no squirrel"); return end
local hum = ch:FindFirstChildOfClass("Humanoid"); if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
local at = mesh.Position + Vector3.new(0, 1.5, 5)
ch:PivotTo(CFrame.lookAt(at, mesh.Position))
task.wait(1.2)
local sp = mesh:FindFirstChild("ChutePrompt")
if not sp then warn("QQ BSQ no ChutePrompt on the squirrel"); return end
sp.MaxActivationDistance = 30
sp:InputHoldBegin(); task.wait(0.5); sp:InputHoldEnd()
task.wait(2)
warn(string.format("QQ BSQ prompt '%s' / '%s'; pack=%s HasChute=%s", sp.ObjectText, sp.ActionText, tostring(ch:FindFirstChild("ChutePack") ~= nil), tostring(plr:GetAttribute("HasChute"))))
