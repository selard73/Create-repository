-- p3 (Shannon approved) moor the still boat at the sign end, bow DOWNSTREAM (-z), with two sagging ropes to the last two posts
local M = workspace.River.BoatPreview
local mp = M:FindFirstChildWhichIsA("MeshPart", true)
local KEEL = -1.45
local CX, CZ = 157.6, -166.5                     -- boat spans z -162.5 (motor) .. -170.5 (bow), bow just past the deck end (-168)
mp.CFrame = CFrame.new(CX, KEEL + mp.Size.Y / 2, CZ)   -- identity = bow toward -z (checked on the first placement)
for _, c in ipairs(M:GetChildren()) do if c.Name == "MooringRope" then c:Destroy() end end
local ROPE = Color3.fromRGB(214, 190, 140)
local function seg(a, b)
	local p = Instance.new("Part"); p.Name = "MooringRope"; p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new((b - a).Magnitude, 0.11, 0.11); p.Color = ROPE; p.Material = Enum.Material.Fabric
	p.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CastShadow = false; p.Parent = M
end
local function rope(a, b, sag)
	local mid = (a + b) / 2 - Vector3.new(0, sag, 0)
	local q1, q3 = a:Lerp(mid, 0.5) - Vector3.new(0, sag * 0.25, 0), mid:Lerp(b, 0.5) - Vector3.new(0, sag * 0.25, 0)
	seg(a, q1); seg(q1, mid); seg(mid, q3); seg(q3, b)
end
local POSTX, RINGY = 160.3 - 0.28, 0.6 + 0.5
rope(Vector3.new(158.55, 0.55, -169.8), Vector3.new(POSTX, RINGY, -167.65), 0.3)   -- bow line to the last post (by the sign)
rope(Vector3.new(159.3, 0.45, -163.2), Vector3.new(POSTX, RINGY, -162.55), 0.15)   -- stern line to the next post
-- the last post gets rope rings like its neighbours
local J = workspace.River.Jetty
for _, y in ipairs({0.6 + 0.45, 0.6 + 0.62}) do
	local found = false
	for _, c in ipairs(J:GetChildren()) do if c.Name == "Rope" and math.abs(c.Position.Z + 167.65) < 0.05 and math.abs(c.Position.Y - y) < 0.05 then found = true end end
	if not found then
		local r = Instance.new("Part"); r.Name = "Rope"; r.Shape = Enum.PartType.Cylinder; r.Size = Vector3.new(0.14, 0.66, 0.66)
		r.CFrame = CFrame.new(160.3, y, -167.65) * CFrame.Angles(0, 0, math.rad(90)); r.Color = ROPE; r.Material = Enum.Material.SmoothPlastic
		r.Anchored = true; r.Parent = J
	end
end
M:SetAttribute("Built", "p3 2026-09-30 moored bow downstream")
local cam = workspace.CurrentCamera
cam.FieldOfView = 45
cam.CFrame = CFrame.lookAt(Vector3.new(150, 3.5, -176), Vector3.new(158.5, 0.2, -165))
print("QQ DONE p3")
