-- m12 (Shannon approved; bow ring at the spot she circled, plate flat on the flared side) small bow ring + round turn and two half hitches; both mooring ropes thinner (0.08) and matching;
-- stern cleat unchanged. Rebuilds River.BoatPreview.Fittings and the MooringRope parts only.
local M = workspace.River.BoatPreview
local mp = M:FindFirstChildWhichIsA("MeshPart", true)
local C0 = mp.CFrame
local METAL = Color3.fromRGB(72, 74, 80)
local ROPE = Color3.fromRGB(214, 190, 140)
local RW = 0.08                                             -- rope thickness, both lines
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
local function seg(a, b, w)
	return part(M, "MooringRope", Vector3.new((b - a).Magnitude + (w or RW) * 0.6, w or RW, w or RW), CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0), ROPE, Enum.Material.Fabric, Enum.PartType.Cylinder)
end
local function blob(p, d) return part(M, "MooringRope", Vector3.new(d, d, d), CFrame.new(p), ROPE, Enum.Material.Fabric, Enum.PartType.Ball) end
local function rope(a, b, sag)
	local mid = (a + b) / 2 - Vector3.new(0, sag, 0)
	local q1, q3 = a:Lerp(mid, 0.5) - Vector3.new(0, sag * 0.25, 0), mid:Lerp(b, 0.5) - Vector3.new(0, sag * 0.25, 0)
	seg(a, q1); seg(q1, mid); seg(mid, q3); seg(q3, b)
end
-- a smooth coil of rope round an axis (short overlapping rope pieces on a circle), optionally tilted like a real wrap
local function coil(centre, axis, radius, n, d, tilt)
	local u = axis.Unit
	local e1 = u:Cross(Vector3.yAxis); if e1.Magnitude < 0.1 then e1 = u:Cross(Vector3.xAxis) end
	e1 = e1.Unit; local e2 = u:Cross(e1)
	if tilt then local r = CFrame.fromAxisAngle(e1, tilt); u = r * u; e2 = r * e2 end
	local L = 2 * math.pi * radius / n * 1.25
	for i = 0, n - 1 do
		local a = (i + 0.5) / n * math.pi * 2
		local pos = centre + (e1 * math.cos(a) + e2 * math.sin(a)) * radius
		local tan = -e1 * math.sin(a) + e2 * math.cos(a)
		part(M, "MooringRope", Vector3.new(L + d * 0.3, d, d), CFrame.lookAt(pos, pos + tan) * CFrame.Angles(0, math.rad(90), 0), ROPE, Enum.Material.Fabric, Enum.PartType.Cylinder)
	end
end
-- bow: on the hull SIDE near the bow post, at the spot Shannon circled
local RR, TUBE, N = 0.075, 0.03, 16
-- Shannon circled the spot on a screenshot of the side-on view aimed at the m9 plate (camera 2.2 studs out along the m9
-- normal, FOV 12, ~1040 px per stud): the circle's centre is 525 px right and 75 px down from that plate's centre.
-- Cast a ray from that same camera through that screen point onto the hull and put the plate there, flat on the planking.
local SIDE9 = C0 * Vector3.new(0.81, 0.54, -3.4)
local n9 = (C0 - C0.Position) * Vector3.new(0.65, 0, -0.76).Unit
local camPos = SIDE9 + n9 * 2.2
local view = CFrame.lookAt(camPos, SIDE9)
local target = SIDE9 + view.RightVector * (525 / 1040) - Vector3.yAxis * (75 / 1040)
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {mp}
local hit = workspace:Raycast(camPos, (target - camPos).Unit * 5, rp)
local SIDE, n
if hit then
	SIDE = hit.Position
	n = hit.Normal                                               -- full normal: the plate lies flat on the flared side
	print(("QQ M11 hit %.3f %.3f %.3f normal %.2f %.2f %.2f"):format(SIDE.X, SIDE.Y, SIDE.Z, hit.Normal.X, hit.Normal.Y, hit.Normal.Z))
else
	-- no hit: put it in the camera's plane at the target, facing the camera
	SIDE = target; n = n9
	warn("QQ M11 no hit - placed in the view plane")
end
local upv = (Vector3.yAxis - n * Vector3.yAxis:Dot(n)).Unit
local R0 = CFrame.fromMatrix(Vector3.zero, n, upv)               -- x = out of the planking, y = up along the planking
local function at(out) return CFrame.new(SIDE + n * out) * R0 end
part(F, "BowPlate", Vector3.new(0.035, 0.13, 0.13), at(0.0175), METAL, Enum.Material.Metal)   -- top edge = top of the side
part(F, "BowEye", Vector3.new(0.05, 0.045, 0.045), at(0.055), METAL, Enum.Material.Metal)
local ringC = at(0.035 + 0.02 + RR) * CFrame.new(0, -0.03, 0)   -- hangs from the plate
for i = 0, N - 1 do
	local a = (i + 0.5) / N * math.pi * 2
	local pos = ringC * Vector3.new(math.cos(a) * RR, math.sin(a) * RR, 0)
	local tan = (ringC - ringC.Position) * Vector3.new(-math.sin(a), math.cos(a), 0)
	part(F, "BowRing", Vector3.new(2 * math.pi * RR / N * 1.35, TUBE, TUBE), CFrame.lookAt(pos, pos + tan) * CFrame.Angles(0, math.rad(90), 0), METAL, Enum.Material.Metal, Enum.PartType.Cylinder)
end
-- stern cleat, as before
local cl = C0 * CFrame.new(1.48, 0.552, 2.72)
part(F, "CleatBase", Vector3.new(0.12, 0.08, 0.22), cl * CFrame.new(0, 0.04, 0), METAL, Enum.Material.Metal)
part(F, "CleatBar", Vector3.new(0.1, 0.06, 0.5), cl * CFrame.new(0, 0.11, 0), METAL, Enum.Material.Metal)

-- BOW LINE: jetty post -> round turn on the bottom of the ring -> two half hitches round its own standing part -> tail
local POSTX, RINGY = 160.3 - 0.28, 0.6 + 0.5
local post = Vector3.new(POSTX, RINGY, -167.65)
local P = ringC * Vector3.new(0, -RR, 0)                          -- bottom of the ring
local xa = (ringC - ringC.Position) * Vector3.xAxis              -- the ring's tangent at its bottom
-- the rope leaves the knot OUTWARD, clear of the bow, then runs back to the post outside the rim
-- (a straight line from the ring to the post cut through the rim: Shannon's close-up)
local Q = C0 * Vector3.new(2.1, 0.3, -3.0)                      -- curve control point, out beside the bow
local u = (Q - P).Unit
local S = P + u * 0.11
local prev = S
for i = 1, 14 do                                                 -- one smooth curve (quadratic Bezier) S -> post
	local t = i / 14
	local q = S * (1 - t) ^ 2 + Q * 2 * t * (1 - t) + post * t * t
	seg(prev, q); prev = q
end
-- round turn: two snug wraps round the ring's metal at its bottom
coil(P - xa * 0.028, xa, TUBE / 2 + RW * 0.45, 12, RW * 0.9, math.rad(12))
coil(P + xa * 0.028, xa, TUBE / 2 + RW * 0.45, 12, RW * 0.9, math.rad(12))
-- the working end comes back down beside the standing part and ties two half hitches round it
local H1, H2 = P + u * 0.2, P + u * 0.33
local side = u:Cross(Vector3.yAxis).Unit
seg(P + side * 0.06, H1 + side * 0.05, RW * 0.9)
coil(H1, u, RW * 0.8, 12, RW * 0.85, math.rad(22))
seg(H1 - side * 0.05, H2 + side * 0.05, RW * 0.9)
coil(H2, u, RW * 0.8, 12, RW * 0.85, math.rad(22))
-- a short loose tail
local T0 = H2 - side * 0.06
seg(T0, T0 + (u * 0.06 - Vector3.yAxis * 0.16 - side * 0.04), RW * 0.85)

-- STERN LINE: same rope, to the cleat, with two figure-of-eight turns
rope(Vector3.new(POSTX, RINGY, -162.55), cl * Vector3.new(0.05, 0.12, -0.12), 0.15)
seg(cl * Vector3.new(0.07, 0.15, -0.2), cl * Vector3.new(-0.07, 0.15, 0.2), RW * 0.9)
seg(cl * Vector3.new(-0.07, 0.16, -0.2), cl * Vector3.new(0.07, 0.16, 0.2), RW * 0.9)

M:SetAttribute("Built", "m9 2026-09-30 ring on the side")
local cam = workspace.CurrentCamera
cam.FieldOfView = 20
cam.FieldOfView = 12; cam.CFrame = view                      -- the very view she circled on
print("QQ DONE m12 ring " .. tostring(ringC.Position))
