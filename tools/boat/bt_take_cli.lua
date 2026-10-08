-- bt_take v1 (PLAY, CLIENT, test only): holds the jetty prompt programmatically (the same as pressing E for 0.5 s) so the
-- server gives this player the boat. Then reports the seat.
local prompt = workspace.River.BoatPreview.Boat.PromptSpot.BoatPrompt
prompt:InputHoldBegin()
task.wait(0.6)
prompt:InputHoldEnd()
task.wait(1.2)
local plr = game.Players.LocalPlayer
local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
warn(string.format("QQ BTK prompt %s enabled=%s; seat=%s; boat=%s", prompt.ObjectText, tostring(prompt.Enabled), tostring(hum and hum.SeatPart and hum.SeatPart.Name), tostring(workspace.Boat:FindFirstChild("Boat_" .. plr.UserId) ~= nil)))
