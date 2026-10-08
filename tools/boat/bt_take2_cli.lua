-- bt_take2 v1 (PLAY, CLIENT, test only): the prompt is not "shown" unless the camera sees the moored boat, so for the test
-- the line-of-sight rule is switched off on this client only, then the hold is simulated. Reports the seat.
local prompt = workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt
prompt.RequiresLineOfSight = false
prompt.MaxActivationDistance = 30
task.wait(0.5)
prompt:InputHoldBegin()
task.wait(0.7)
prompt:InputHoldEnd()
task.wait(1.5)
local plr = game.Players.LocalPlayer
local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
warn(string.format("QQ BTK2 seat=%s boat=%s at %s", tostring(hum and hum.SeatPart and hum.SeatPart.Name), tostring(workspace.Boat:FindFirstChild("Boat_" .. plr.UserId) ~= nil), hrp and tostring(hrp.Position) or "?"))
