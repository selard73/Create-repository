-- run_cliffcam.lua v3 (EDIT mode): the camera stops at the Sandstone Climb's rock (Shannon, Sep 27: "when I turn the wrong
-- way, I can see through the mountain"). v1 of the morning runner made the rock solid in its own collision group, but
-- Roblox's camera only looks for things in the Default group, so it still went through. Now: the rock goes back to how it
-- was (not solid; the climb's invisible boxes are what you stand on), keeping a precise shape, and a small client script
-- (CliffCamera) brings the camera forward to just in front of the rock whenever the rock is between you and the camera.
if game:GetService("RunService"):IsRunning() then warn("QQ ABORT - Play mode") return end
local PS = game:GetService("PhysicsService")
local F = workspace:FindFirstChild("SandstoneClimb")
local cliff = F and F:FindFirstChild("Cliff")
if not cliff then warn("QQ CLIFFCAM no cliff - nothing changed") return end
local n = 0
for _, p in ipairs(cliff:GetDescendants()) do
	if p:IsA("MeshPart") then
		p.CanCollide = false; p.CanQuery = true; p.CanTouch = false; p.CollisionGroup = "Default"
		n += 1
	end
end
local users = 0
for _, p in ipairs(workspace:GetDescendants()) do if p:IsA("BasePart") and p.CollisionGroup == "CliffView" then users += 1 end end
if users == 0 and PS:IsCollisionGroupRegistered("CliffView") then PS:UnregisterCollisionGroup("CliffView") end
local old = F:FindFirstChild("CliffCamera"); if old then old:Destroy() end
local s = Instance.new("Script"); s.Name = "CliffCamera"; s.RunContext = Enum.RunContext.Client
s.Source = [==[
-- CliffCamera: the camera stops at the Sandstone Climb's rock instead of going through it (Sep 27, Shannon: "when I turn
-- the wrong way, I can see through the mountain"). Roblox's own camera only stops at solid parts, and the rock you see is
-- not solid (the climb's invisible boxes are what you stand on) - so, near the cliff, just after the camera moves each
-- frame, a ray from the camera's focus out to the camera: if the rock is in the way, the camera comes forward to just in
-- front of it. Only the camera changes, and only on this screen.
local RunService = game:GetService("RunService")
local F = script.Parent
local cliff = F:WaitForChild("Cliff")
-- the whole Cliff model (its pieces may still be streaming in when this starts; the invisible boxes in it cannot be hit)
local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Include; params.FilterDescendantsInstances = {cliff}
RunService:BindToRenderStep("CliffCamera", Enum.RenderPriority.Camera.Value + 1, function()
	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType ~= Enum.CameraType.Custom then return end
	local focus = cam.Focus.Position
	local pos = cam.CFrame.Position
	local d = pos - focus
	if d.Magnitude < 0.6 then return end                     -- (first person)
	local hit = workspace:Raycast(focus, d, params)
	if hit then
		local keep = math.max(0.4, (hit.Position - focus).Magnitude - 0.5)
		cam.CFrame = CFrame.new(focus + d.Unit * keep) * (cam.CFrame - pos)
	end
end)
]==]
s.Parent = F
local f, e = loadstring(s.Source)
warn(string.format("QQ CLIFFCAM v3 done - %d rock pieces back to not solid (group Default), CliffView group %s, CliffCamera %s",
	n, PS:IsCollisionGroupRegistered("CliffView") and "still registered" or "removed", f and "compiles" or ("COMPILE ERROR " .. tostring(e))))
