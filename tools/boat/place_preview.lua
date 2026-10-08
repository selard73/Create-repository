-- p1 still boat preview beside the jetty (Shannon approved) + a temporary scale dummy (deleted after the pictures)
local src = workspace:FindFirstChild("boat_army")
local R = workspace.River
local M = R:FindFirstChild("BoatPreview")
if src then
	if M then M:Destroy() end
	src.Name = "BoatPreview"; src.Parent = R; M = src
end
local mp = M:FindFirstChildWhichIsA("MeshPart", true)
print("QQ MESH " .. mp:GetFullName() .. " size " .. tostring(mp.Size) .. " tex " .. mp.TextureID .. " rot " .. tostring(mp.CFrame - mp.Position))
-- the long axis becomes world z; bow faces upstream (+z) since the current runs south
local s = mp.Size
local L, W, H = math.max(s.X, s.Z), math.min(s.X, s.Z), s.Y
local longIsX = s.X > s.Z
local sc = 8 / L
mp.Size = Vector3.new(s.X * sc, s.Y * sc, s.Z * sc)
mp.Anchored = true; mp.CanCollide = true
local FLIP = 0                         -- set to 180 if the motor ends up at the north end
local rot = CFrame.Angles(0, math.rad((longIsX and 90 or 0) + FLIP), 0)
local KEEL = -0.9 - 0.55               -- 0.55 draft under WaterY
local h = mp.Size.Y
mp.CFrame = CFrame.new(157.6, KEEL + h / 2, -157) * rot
M:SetAttribute("Built", "p1 2026-09-30 still preview")
print(("QQ PLACED size %.2f %.2f %.2f"):format(mp.Size.X, mp.Size.Y, mp.Size.Z))
-- temporary scale dummy on the deck
local old = workspace:FindFirstChild("ScaleDummy_temp"); if old then old:Destroy() end
local ok, dummy = pcall(function()
	return game:GetService("Players"):CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
end)
if ok and dummy then
	dummy.Name = "ScaleDummy_temp"; dummy.Parent = workspace
	for _, p in ipairs(dummy:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = true end end
	local _, ds = dummy:GetBoundingBox()
	dummy:PivotTo(CFrame.new(161.9, 0.6 + ds.Y / 2, -155) * CFrame.Angles(0, math.rad(90), 0))
	print(("QQ DUMMY height %.2f"):format(ds.Y))
else
	print("QQ DUMMY failed " .. tostring(dummy))
end
local cam = workspace.CurrentCamera
cam.FieldOfView = 50
cam.CFrame = CFrame.lookAt(Vector3.new(146, 4.5, -168), Vector3.new(159, 0.3, -157))
print("QQ DONE p1")
