-- m1 (Shannon approved) mooring fittings: a metal ring on the bow post + a cleat on the stern corner rim (model
-- River.BoatPreview.Fittings, copied onto driven boats by BoatServer), and the two ropes re-aimed to end on them
local M = workspace.River.BoatPreview
local mp = M:FindFirstChildWhichIsA("MeshPart", true)
local C0 = mp.CFrame                                   -- identity rotation; local offsets measured in Blender (x flipped)
local METAL = Color3.fromRGB(72, 74, 80)
local ROPE = Color3.fromRGB(214, 190, 140)
local old = M:FindFirstChild("Fittings"); if old then old:Destroy() end
for _, c in ipairs(M:GetChildren()) do if c.Name == "MooringRope" then c:Destroy() end end
local F = Instance.new("Model"); F.Name = "Fittings"; F.Parent = M
local function part(parent, name, size, cf, color, mat, shape)
	local p = Instance.new("Part"); p.Name = name; p.Size = size; p.CFrame = cf; p.Color = color; p.Material = mat
	if shape then p.Shape = shape end
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth; p.Parent = parent
	return p
end
-- bow: plate on the post's jetty-side face (local x +0.507), ring standing out from it
local ringC = C0 * CFrame.new(0.507 + 0.19, 0.64, -3.78)
part(F, "BowPlate", Vector3.new(0.05, 0.22, 0.22), C0 * CFrame.new(0.507 + 0.025, 0.64, -3.78), METAL, Enum.Material.Metal)
part(F, "BowEye", Vector3.new(0.12, 0.07, 0.07), C0 * CFrame.new(0.507 + 0.08, 0.64, -3.78), METAL, Enum.Material.Metal)
local RR, N = 0.12, 10
for i = 0, N - 1 do
	local a = (i + 0.5) / N * math.pi * 2
	local pos = ringC * Vector3.new(math.cos(a) * RR, math.sin(a) * RR, 0)
	local tan = (ringC - ringC.Position) * Vector3.new(-math.sin(a), math.cos(a), 0)
	part(F, "BowRing", Vector3.new(2 * math.pi * RR / N * 1.15, 0.045, 0.045), CFrame.lookAt(pos, pos + tan) * CFrame.Angles(0, math.rad(90), 0), METAL, Enum.Material.Metal, Enum.PartType.Cylinder)
end
-- stern corner: a horn cleat on top of the rim (rim top 0.552 above the mesh centre), running along the boat
local cl = C0 * CFrame.new(1.48, 0.552, 2.72)
part(F, "CleatBase", Vector3.new(0.12, 0.08, 0.22), cl * CFrame.new(0, 0.04, 0), METAL, Enum.Material.Metal)
part(F, "CleatBar", Vector3.new(0.1, 0.06, 0.5), cl * CFrame.new(0, 0.11, 0), METAL, Enum.Material.Metal)
-- ropes
local function seg(a, b, w)
	local p = part(M, "MooringRope", Vector3.new((b - a).Magnitude, w or 0.11, w or 0.11), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), ROPE, Enum.Material.Fabric, Enum.PartType.Cylinder)
	return p
end
local function rope(a, b, sag)
	local mid = (a + b) / 2 - Vector3.new(0, sag, 0)
	local q1, q3 = a:Lerp(mid, 0.5) - Vector3.new(0, sag * 0.25, 0), mid:Lerp(b, 0.5) - Vector3.new(0, sag * 0.25, 0)
	seg(a, q1); seg(q1, mid); seg(mid, q3); seg(q3, b)
end
local POSTX, RINGY = 160.3 - 0.28, 0.6 + 0.5
local ringLow = ringC * Vector3.new(0, -RR, 0)               -- through the bottom of the ring
rope(Vector3.new(POSTX, RINGY, -167.65), ringLow, 0.3)
local loopTop = ringC * Vector3.new(0.05, RR + 0.02, 0)      -- the end loops up through the ring and hangs down
seg(ringLow, loopTop, 0.09); seg(loopTop, ringC * Vector3.new(0.12, -RR - 0.12, 0.03), 0.09)
local barTop = cl * Vector3.new(0, 0.16, 0)
rope(Vector3.new(POSTX, RINGY, -162.55), cl * Vector3.new(0.05, 0.12, -0.12), 0.15)
-- two figure-of-eight turns over the cleat bar
seg(cl * Vector3.new(0.07, 0.15, -0.2), cl * Vector3.new(-0.07, 0.15, 0.2), 0.08)
seg(cl * Vector3.new(-0.07, 0.16, -0.2), cl * Vector3.new(0.07, 0.16, 0.2), 0.08)
M:SetAttribute("Built", "m1 2026-09-30 ring + cleat")
local cam = workspace.CurrentCamera
cam.FieldOfView = 35
cam.CFrame = CFrame.lookAt(Vector3.new(163.5, 3.2, -173), Vector3.new(158.4, 0.5, -169.6))
print("QQ DONE m1 ring " .. tostring(ringC.Position) .. " cleat " .. tostring(cl.Position))
