-- camera/vraim_patch: EDIT mode. VR aim for the camera (Oct 9 2026, Shannon: "you can't really aim the shot with the
-- golden circle"). Patches workspace.PhotoGame.CameraClient.Source with exact string finds: the aim is now the tracked
-- controller (gold beam + ring), the ring fills in when a wanted sight is in the shot, two tuning attrs on PhotoGame
-- (VRAimPitch degrees, VRAimHand "Left"). Desktop / phone untouched. Original -> ServerStorage.HudBackup.CameraClient_v3_pre_vraim.
-- Refuses to run unless the Source is the Oct 8 v3 text (56602 chars) and every find hits exactly once. Output: "QQ VRA".
if game:GetService("RunService"):IsRunning() then warn("QQ VRA ABORT - Play mode") return end
local G = workspace:FindFirstChild("PhotoGame")
local S = G and G:FindFirstChild("CameraClient")
if not (S and S:IsA("LuaSourceContainer")) then warn("QQ VRA ABORT - workspace.PhotoGame.CameraClient not found") return end
local src = S.Source
if #src ~= 56602 then warn("QQ VRA ABORT - CameraClient.Source is " .. #src .. " chars, expected 56602 (already patched, or not the Oct 8 v3)") return end
local PAIRS = {
	{[==[
VR: aim with the camera in your hand (gold ring); the photo
-- floats in front of you.]==],
	[==[
VR: point your controller (a gold beam and ring show where;
-- the ring fills in while a postcard sight is in the shot) and pull the trigger; the photo floats in front of you.]==]},
	{[==[
local function shotCF()
	local cam = workspace.CurrentCamera
	if vr() then
		local h = heldHandle()
		if h then return CFrame.lookAt(h.Position, h.Position + h.CFrame.LookVector) end
		return cam:GetRenderCFrame()
	end
	return cam.CFrame
end]==],
	[==[
-- VR aim (Oct 9, Shannon: "you can't really aim the shot with the golden circle"): the avatar's hand follows its walking
-- animation, not the player, so the held camera pointed wherever the arm swung. The aim is now the controller itself
-- (its tracked CFrame, in world space), with the wrist's roll removed so photos come out level. Attr VRAimPitch
-- (degrees) tips it: 0 = straight along the controller, negative = down, for a resting grip. Attr VRAimHand "Left" uses
-- the left controller and its trigger. No tracked controller = the headset's view.
local function vrHandCF()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local want = G:GetAttribute("VRAimHand") == "Left" and Enum.UserCFrame.LeftHand or Enum.UserCFrame.RightHand
	local other = want == Enum.UserCFrame.LeftHand and Enum.UserCFrame.RightHand or Enum.UserCFrame.LeftHand
	local hand = VRService:GetUserCFrameEnabled(want) and want or (VRService:GetUserCFrameEnabled(other) and other or nil)
	if not hand then return nil end
	local u = VRService:GetUserCFrame(hand)
	local world = cam.CFrame * (u.Rotation + u.Position * cam.HeadScale) * CFrame.Angles(math.rad(num("VRAimPitch", 0)), 0, 0)
	local look = world.LookVector
	return CFrame.lookAt(world.Position, world.Position + look, math.abs(look.Y) > 0.99 and Vector3.zAxis or Vector3.yAxis)
end
local function shotCF()
	local cam = workspace.CurrentCamera
	if vr() then return vrHandCF() or cam:GetRenderCFrame() end
	return cam.CFrame
end]==]},
	{[==[
toast(vr() and "Pull the trigger to take a photo" or touch and "Tap to raise the camera" or "Click to raise the camera", 2.5)]==],
	[==[
toast(vr() and "Aim with the controller. When the ring fills in, pull the trigger." or touch and "Tap to raise the camera" or "Click to raise the camera", vr() and 4 or 2.5)]==]},
	{[==[
-- in VR: a gold ring where the camera in your hand is pointing
local aimAtt = Instance.new("Attachment"); aimAtt.Name = "CameraAimPoint"; aimAtt.Parent = workspace.Terrain
local aim = Instance.new("BillboardGui"); aim.Name = "CameraAim"; aim.Size = UDim2.fromOffset(36, 36); aim.AlwaysOnTop = true; aim.LightInfluence = 0
aim.Adornee = aimAtt; aim.Enabled = false; aim.Parent = pg
local ring = Instance.new("Frame"); ring.Size = UDim2.fromScale(1, 1); ring.BackgroundTransparency = 1; ring.Parent = aim; corner(ring, 18); stroke(ring, GOLD, 3)
RunService.RenderStepped:Connect(function()
	if raised then hideHeld(true) end
	local on = holding and vr()
	aim.Enabled = on
	if on then
		local cf = shotCF()
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {player.Character}
		local hit = workspace:Raycast(cf.Position, cf.LookVector * 80, params)
		aimAtt.WorldPosition = hit and hit.Position or (cf.Position + cf.LookVector * 40)
	end
end)]==],
	[==[
-- in VR: a gold beam from your controller to a gold ring where it points (Oct 9: the ring used to hang off the avatar's
-- hand, which swings with the walking animation, so it could not be aimed). The ring fills in, grows and turns cream
-- while a postcard shot would be accepted right now (the shutter's own test: all of a wanted sight in the cone, in range,
-- in clear view, at the right moment), so you know when to pull the trigger.
local aimAtt = Instance.new("Attachment"); aimAtt.Name = "CameraAimPoint"; aimAtt.Parent = workspace.Terrain
local handAtt = Instance.new("Attachment"); handAtt.Name = "CameraAimHand"; handAtt.Parent = workspace.Terrain
local beam = Instance.new("Beam"); beam.Name = "CameraAimBeam"; beam.Attachment0 = handAtt; beam.Attachment1 = aimAtt
beam.Color = ColorSequence.new(GOLD); beam.Transparency = NumberSequence.new(0.35); beam.Width0 = 0.03; beam.Width1 = 0.3
beam.FaceCamera = true; beam.LightEmission = 0.6; beam.LightInfluence = 0; beam.Enabled = false; beam.Parent = workspace.Terrain
local aim = Instance.new("BillboardGui"); aim.Name = "CameraAim"; aim.Size = UDim2.fromOffset(36, 36); aim.AlwaysOnTop = true; aim.LightInfluence = 0
aim.ResetOnSpawn = false; aim.Adornee = aimAtt; aim.Enabled = false; aim.Parent = pg
local ring = Instance.new("Frame"); ring.Size = UDim2.fromScale(1, 1); ring.BackgroundTransparency = 1; ring.BackgroundColor3 = GOLD; ring.Parent = aim
local ringCorner = Instance.new("UICorner"); ringCorner.CornerRadius = UDim.new(0.5, 0); ringCorner.Parent = ring
local ringStroke = stroke(ring, GOLD, 3)
local aimLocked, aimCheckAt = false, 0
local function setRing(locked)
	aim.Size = locked and UDim2.fromOffset(50, 50) or UDim2.fromOffset(36, 36)
	ring.BackgroundTransparency = locked and 0.5 or 1
	ringStroke.Thickness = locked and 5 or 3
	ringStroke.Color = locked and CREAM or GOLD
end
local aimParams = RaycastParams.new(); aimParams.FilterType = Enum.RaycastFilterType.Exclude
local function aimHit(cf)   -- where the controller points; invisible parts (boundary walls, prompt spots) are looked through
	local ex = {player.Character}
	local origin, left = cf.Position, 80
	for _ = 1, 5 do
		aimParams.FilterDescendantsInstances = ex
		local hit = workspace:Raycast(origin, cf.LookVector * left, aimParams)
		if not hit then return nil end
		if hit.Instance == workspace.Terrain or hit.Instance.Transparency < 1 then return hit.Position end
		table.insert(ex, hit.Instance)
		left -= (hit.Position - origin).Magnitude; origin = hit.Position
		if left <= 0 then return nil end
	end
	return nil
end
RunService.RenderStepped:Connect(function()
	if raised then hideHeld(true) end
	local on = holding and vr()
	aim.Enabled = on
	if on then
		local cf = shotCF()
		handAtt.WorldPosition = cf.Position
		aimAtt.WorldPosition = aimHit(cf) or (cf.Position + cf.LookVector * 40)
		beam.Enabled = vrHandCF() ~= nil
		if os.clock() - aimCheckAt > 0.05 then
			aimCheckAt = os.clock()
			local ok, s = pcall(evaluate, cf)
			local locked = ok and s ~= nil and (player:GetAttribute("Item_photo_" .. s.id) or 0) < 1
			if locked ~= aimLocked then aimLocked = locked; setRing(locked) end
		end
	else
		beam.Enabled = false
		if aimLocked then aimLocked = false; setRing(false) end
	end
end)
-- VRAimHand "Left": the left trigger takes the photo too (Tool.Activated only listens to the right one)
UIS.InputBegan:Connect(function(input, gp)
	if gp or not (holding and vr()) then return end
	if input.KeyCode == Enum.KeyCode.ButtonL2 and G:GetAttribute("VRAimHand") == "Left" then shoot() end
end)]==]},
	{[==[
vrSign.AlwaysOnTop = true; vrSign.LightInfluence = 0; vrSign.Parent = pg]==],
	[==[
vrSign.AlwaysOnTop = true; vrSign.LightInfluence = 0; vrSign.ResetOnSpawn = false; vrSign.Parent = pg]==]},
	{[==[
m.MaxDistance = 3000; m.Enabled = false; m.Parent = pg]==],
	[==[
m.MaxDistance = 3000; m.Enabled = false; m.ResetOnSpawn = false; m.Parent = pg]==]},
}
for i, p in ipairs(PAIRS) do
	local a, b = src:find(p[1], 1, true)
	if not a then warn("QQ VRA ABORT - find " .. i .. " not found; nothing changed") return end
	if src:find(p[1], b + 1, true) then warn("QQ VRA ABORT - find " .. i .. " matches more than once; nothing changed") return end
end
local out = src
for i, p in ipairs(PAIRS) do
	local a, b = out:find(p[1], 1, true)
	out = out:sub(1, a - 1) .. p[2] .. out:sub(b + 1)
end
local f, err = loadstring(out)
if not f then warn("QQ VRA ABORT - patched source does not compile: " .. tostring(err) .. "; nothing changed") return end
local SS = game:GetService("ServerStorage")
local hb = SS:FindFirstChild("HudBackup")
if not hb then hb = Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS end
if not hb:FindFirstChild("CameraClient_v3_pre_vraim") then
	local bk = S:Clone(); bk.Name = "CameraClient_v3_pre_vraim"
	pcall(function() bk.Enabled = false end)
	bk.Parent = hb
end
S.Source = out
print(string.format("QQ VRA DONE: CameraClient patched, %d -> %d chars, %d finds, backup ServerStorage.HudBackup.CameraClient_v3_pre_vraim", #src, #out, #PAIRS))
