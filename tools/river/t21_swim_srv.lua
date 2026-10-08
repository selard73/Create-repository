-- v23 (PLAY, SERVER): open the gates for the test player, then drop them into the river north of the bridge
local plr = game.Players:GetPlayers()[1]
plr:SetAttribute("Found_forest", 15)
plr:SetAttribute("Found_village", 15)
task.wait(1.5)
local ch = plr.Character
ch:PivotTo(CFrame.new(156, 1, -80) * CFrame.Angles(0, math.rad(90), 0))
task.wait(0.5)
warn("QQ T23 dropped", string.format("%.1f,%.1f,%.1f", ch.HumanoidRootPart.Position.X, ch.HumanoidRootPart.Position.Y, ch.HumanoidRootPart.Position.Z))
