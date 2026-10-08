-- bt1 (PLAY, SERVER): put the test player on the jetty next to the moored boat (no finds yet -> locked)
local plr = game.Players:GetPlayers()[1]
local ch = plr.Character or plr.CharacterAdded:Wait()
ch:PivotTo(CFrame.lookAt(Vector3.new(161.6, 3.6, -165.5), Vector3.new(157.6, 3.6, -165.5)))
task.wait(0.5)
warn("QQ BT1 on jetty", tostring(ch.HumanoidRootPart.Position), "found", plr:GetAttribute("Found_forest"), plr:GetAttribute("Found_village"), plr:GetAttribute("Found_domaine"))
