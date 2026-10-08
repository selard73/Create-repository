-- bt1b (PLAY, SERVER): 30 finds in THIS PLAY COPY ONLY (Rue open, boat still locked), then stand on the jetty
local plr = game.Players:GetPlayers()[1]
plr:SetAttribute("Found_forest", 15); plr:SetAttribute("Found_village", 15)
task.wait(1.5)
local ch = plr.Character
ch:PivotTo(CFrame.lookAt(Vector3.new(161.6, 3.6, -165.5), Vector3.new(157.6, 3.6, -165.5)))
task.wait(1)
warn("QQ BT1b", tostring(ch.HumanoidRootPart.Position))
