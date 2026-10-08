-- bt_jetty_take v1 (PLAY, CLIENT, test only): teleports this client's character to the jetty (the client owns the
-- character, so this sticks even when swimming), then holds the jetty prompt programmatically to take the boat.
local plr = game.Players.LocalPlayer
local ch = plr.Character
local hum = ch and ch:FindFirstChildOfClass("Humanoid")
if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
ch:PivotTo(CFrame.lookAt(Vector3.new(161.6, 3.6, -165.5), Vector3.new(157.6, 3.6, -165.5)))
task.wait(1.0)
local prompt = workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt
prompt.RequiresLineOfSight = false
prompt.MaxActivationDistance = 30
task.wait(0.5)
prompt:InputHoldBegin()
task.wait(0.7)
prompt:InputHoldEnd()
task.wait(1.5)
hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
warn(string.format("QQ BJT seat=%s boat=%s at %s", tostring(hum and hum.SeatPart and hum.SeatPart.Name), tostring(workspace.Boat:FindFirstChild("Boat_" .. plr.UserId) ~= nil), hrp and tostring(hrp.Position) or "?"))
