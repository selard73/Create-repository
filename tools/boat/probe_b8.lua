-- b8 READ-ONLY: which place is this tab?
print("QQ B8 place", game.PlaceId, "jetty", workspace.River:FindFirstChild("Jetty") ~= nil, "boat", workspace:FindFirstChild("Boat") and workspace.Boat:GetAttribute("Built"), "running", game:GetService("RunService"):IsRunning())
