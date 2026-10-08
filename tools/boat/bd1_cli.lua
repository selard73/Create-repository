-- bd1 (PLAY, CLIENT, read-only): what is the driven boat doing?
local plr = game.Players.LocalPlayer
local seat = plr.Character.Humanoid.SeatPart
local hull = seat.Parent.Hull
for i = 1, 6 do
	warn(("QQ BD1 pos %.1f %.2f %.1f | lv %s | vel %s | thr %.1f | own %s"):format(hull.Position.X, hull.Position.Y, hull.Position.Z, tostring(hull.Move.VectorVelocity), tostring(hull.AssemblyLinearVelocity), seat.ThrottleFloat, tostring(hull.ReceiveAge)))
	task.wait(0.3)
end
local parts = workspace:GetPartsInPart(hull)
for _, p in ipairs(parts) do warn("QQ BD1 touching " .. p:GetFullName()) end
