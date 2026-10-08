-- bt2 v1 (PLAY, SERVER, test only): gives the test player the squirrel counts (15/14/15 = 44) so the village gate and the
-- boat lock let them through in this saves-off session, and puts them on the jetty facing the moored boat.
local plr = game.Players:GetPlayers()[1]
plr:SetAttribute("Found_forest", 15); plr:SetAttribute("Found_village", 14); plr:SetAttribute("Found_domaine", 15)
local ch = plr.Character or plr.CharacterAdded:Wait()
ch:PivotTo(CFrame.lookAt(Vector3.new(161.6, 3.6, -165.5), Vector3.new(157.6, 3.6, -165.5)))
task.wait(0.8)
warn(string.format("QQ BT2 %s at %s found %d/%d/%d", plr.Name, tostring(ch.HumanoidRootPart.Position), plr:GetAttribute("Found_forest"), plr:GetAttribute("Found_village"), plr:GetAttribute("Found_domaine")))
