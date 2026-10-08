-- v22 (PLAY, CLIENT): watch the swimmer for 8 s (position + state), camera beside them
local plr = game.Players.LocalPlayer
local root = plr.Character.HumanoidRootPart
local hum = plr.Character.Humanoid
local cam = workspace.CurrentCamera
local z0 = root.Position.Z
for i = 1, 8 do
	warn(string.format("QQ T22 t%d pos %.1f,%.2f,%.1f state %s dz %.1f drift %d", i, root.Position.X, root.Position.Y, root.Position.Z, hum:GetState().Name, root.Position.Z - z0, #workspace.RiverDrift:GetChildren()))
	task.wait(1)
end
