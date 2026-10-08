-- m14 (Shannon approved; bow as m12; stern: horn cleat + snug cleat hitch) small bow ring + round turn and two half hitches; both mooring ropes thinner (0.08) and matching;
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
-- stern: a horn cleat on the flat top of the side rim, a little forward of the corner (Blender: flat top x 1.47..1.84,
-- top 0.53 above the mesh centre at z 2.1..2.3), lengthwise along the rim (which angles in slightly toward the stern)
local KT = Vector3.new(-0.175, 0, 1).Unit
local K = C0 * CFrame.fromMatrix(Vector3.new(1.66, 0.53, 2.2), Vector3.yAxis:Cross(KT).Unit * -1, Vector3.yAxis)
-- K: x = across the rim (outboard), y = up, z = along the rim toward the stern
local function kp(name, size, off, shape, rot)
	return part(F, name, size, K * CFrame.new(off) * (rot or CFrame.new()), METAL, Enum.Material.Metal, shape)
end
local ALONG = CFrame.Angles(0, math.rad(90), 0)                 -- turns a cylinder's axis (x) to run along z
kp("CleatFoot", Vector3.new(0.09, 0.07, 0.07), Vector3.new(0, 0.035, -0.09))
kp("CleatFoot", Vector3.new(0.09, 0.07, 0.07), Vector3.new(0, 0.035, 0.09))
kp("CleatBar", Vector3.new(0.3, 0.065, 0.065), Vector3.new(0, 0.095, 0), Enum.PartType.Cylinder, ALONG)
kp("CleatHorn", Vector3.new(0.16, 0.05, 0.05), Vector3.new(0, 0.1, -0.21), Enum.PartType.Cylinder, ALONG)
kp("CleatHorn", Vector3.new(0.16, 0.05, 0.05), Vector3.new(0, 0.1, 0.21), Enum.PartType.Cylinder, ALONG)
kp("CleatTip", Vector3.new(0.055, 0.055, 0.055), Vector3.new(0, 0.1, -0.29), Enum.PartType.Ball)
kp("CleatTip", Vector3.new(0.055, 0.055, 0.055), Vector3.new(0, 0.1, 0.29), Enum.PartType.Ball)
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

-- STERN LINE: same rope, ending in a cleat hitch - a turn round the base under both horns, a figure-of-eight over the
-- top, a locking turn on the bow-side horn, and the tail lying forward along the rim
local function curve(a, c, b, n, w)                              -- smooth rope along a quadratic curve a -> b (control c)
	local prev = a
	for i = 1, n do
		local t = i / n
		local q = a * (1 - t) ^ 2 + c * 2 * t * (1 - t) + b * t * t
		seg(prev, q, w); prev = q
	end
end
local W2 = 0.06
local function kk(x, y, z) return K * Vector3.new(x, y, z) end
local entry = kk(0.058, 0.045, 0.27)                               -- comes in low at the stern-side end
local post2 = Vector3.new(POSTX, RINGY, -162.55)
curve(post2, (post2 + entry) / 2 + Vector3.new(0, -0.22, 0), entry, 10)
-- turn round the base: an oval under the horns
local prevT
for i = 0, 16 do
	local a = i / 16 * math.pi * 2
	local q = kk(math.cos(a) * 0.058, 0.04, math.sin(a) * 0.265)
	if prevT then seg(prevT, q, W2) end
	prevT = q
end
-- figure-of-eight: two rope crossings arching over the bar
curve(kk(-0.055, 0.07, -0.24), kk(0, 0.16, 0), kk(0.055, 0.07, 0.24), 8, W2)
curve(kk(0.055, 0.075, -0.24), kk(0, 0.165, 0), kk(-0.055, 0.075, 0.24), 8, W2)
-- locking turn round the bow-side horn
coil(kk(0, 0.1, -0.22), (K - K.Position) * Vector3.zAxis, 0.05, 12, W2, math.rad(18))
-- tail: lies forward along the rim top, then its end droops over the inside edge
local t0 = kk(-0.05, 0.035, -0.27)
curve(t0, kk(-0.09, 0.03, -0.45), kk(-0.12, 0.03, -0.62), 5, W2)
curve(kk(-0.12, 0.03, -0.62), kk(-0.2, 0.02, -0.7), kk(-0.24, -0.08, -0.74), 3, W2)
M:SetAttribute("Built", "m9 2026-09-30 ring on the side")
local cam = workspace.CurrentCamera
cam.FieldOfView = 20
cam.FieldOfView = 28; cam.CFrame = CFrame.lookAt(K.Position + Vector3.new(1.3, 1.25, -1.1), K.Position + Vector3.new(0, 0.05, 0.05))
print("QQ DONE m14 ring " .. tostring(ringC.Position))
