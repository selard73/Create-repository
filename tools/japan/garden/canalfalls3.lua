-- canalfalls3.lua (cloud, Oct 16 2026): the canal's waterfall stones rebuilt. Shannon, with a picture of r2 from the lawn: "that is a
-- problem that needs to be fixed" - r2's rocks were round pale balloons bulging over the lawn and the side walls, and WallS1's coping
-- poked out through them. The kit Model "canal_falls3" (gen_falls3.py) keeps r2's water (the same cleft, chute, ribbon, foam and beam
-- points) with ANGULAR stones: the water-fall stone with a straight lip, two guardian stones, stones up the chute to a lintel the water
-- comes out from under, a lower rise on the lawn (bases in the ground), stones that swallow WallS1 / WallS4's cut ends and stop at x
-- +-10, a hidden core where WallS2 / S3 stood, two stone tones. This script:
--  * moves JapanMap.MomijiGarden's CanalFalls2 (and any earlier CanalFalls3) to ServerStorage.HudBackup.Falls3Replaced
--    (WallS2 / WallS3 are already in HudBackup.Falls2Replaced - left there)
--  * places canal_falls3 by bounding box (the import may turn it half round: detected by the foam, which lies on the canal side)
--  * dresses it (stones SmoothPlastic in two greys, solid; the water a faint Glass; foam white) and adds r2's moving water: two
--    scrolling Beams (chute, drop) and the mist + spray at the foot
-- Re-runnable. Output "QQ FALLS3".
local CX, FACE_Z = 6101, -219.2          -- the canal's centre line and the south end wall's water face
local SS = game:GetService("ServerStorage")
local KIT = SS:FindFirstChild("JapanGardenKit")
local G = workspace:FindFirstChild("JapanMap") and workspace.JapanMap:FindFirstChild("MomijiGarden")
if not (KIT and G) then print("QQ FALLS3 ABORT: ServerStorage.JapanGardenKit or JapanMap.MomijiGarden missing") return end
local SRC = KIT:FindFirstChild("canal_falls3")
if not SRC then print("QQ FALLS3 ABORT: the kit has no Model 'canal_falls3' - import japan_kit11_falls3_bridge_end.fbx") return end
local BB = {min = Vector3.new(-11.229, -4.6, -18.257), max = Vector3.new(11.235, 8.3, 4.125)}   -- out_falls3/pieces.json (Roblox axes)
local FOAM_Z = (0.971 + 4.125) / 2                                                                  -- the foam's centre, canal side (+z)
local P = {top = Vector3.new(0, 6.72, -10.0), lip = Vector3.new(0, 3.42, 0.5), foot = Vector3.new(0, 1.35, 1.4), mist = Vector3.new(0, 1.6, 2.2)}
local ROCK_COL = {Fall_Rock = Color3.new(0.50, 0.49, 0.46), Fall_Rock2 = Color3.new(0.43, 0.42, 0.40)}   -- both lighter than the lanterns (0.40)
local hb = SS:FindFirstChild("HudBackup") or Instance.new("Folder"); hb.Name = "HudBackup"; hb.Parent = SS
local bak = hb:FindFirstChild("Falls3Replaced") or Instance.new("Folder"); bak.Name = "Falls3Replaced"; bak.Parent = hb
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("before falls3") end)
-- the stones' collision is set on the kit (CollisionFidelity can't be set in a play test - there the clone keeps the kit's)
for _, p in ipairs(SRC:GetDescendants()) do
	if p:IsA("MeshPart") and ROCK_COL[p.Name:gsub("%.%d+$", "")] then
		pcall(function() p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end)
	end
end
local moved = {}
for _, d in ipairs(G:GetDescendants()) do
	if d:IsA("Model") and (d.Name == "CanalFalls2" or d.Name == "CanalFalls3") and d.Parent and not d:IsDescendantOf(bak) then
		d:SetAttribute("Falls3WasIn", d.Parent:GetFullName()); table.insert(moved, d.Name)
	end
end
for _, d in ipairs(G:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("Falls3WasIn") and not d:IsDescendantOf(bak) then d.Parent = bak end end
local m = SRC:Clone(); m.Name = "CanalFalls3"
local cf = m:GetBoundingBox()
local foam = m:FindFirstChild("Fall_Foam", true)
local centreLocal = (BB.min + BB.max) / 2
local flipped = foam and ((foam.Position.Z - cf.Position.Z) * (FOAM_Z - centreLocal.Z) < 0) or false
local R = flipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
m.WorldPivot = CFrame.new(cf.Position - R:VectorToWorldSpace(centreLocal)) * R
local TARGET = CFrame.new(CX, 0, FACE_Z)
m:PivotTo(TARGET)
local rock, nstone = nil, 0
for _, p in ipairs(m:GetDescendants()) do
	if p:IsA("BasePart") then
		local key = p.Name:gsub("%.%d+$", "")
		p.Anchored = true; p.CanTouch = false
		if ROCK_COL[key] then
			rock = rock or p; nstone += 1
			p.Material = Enum.Material.SmoothPlastic; p.Color = ROCK_COL[key]; p.CanCollide = true; p.CanQuery = true; p.CastShadow = true
		elseif key == "Fall_Water" then
			p.Material = Enum.Material.Glass; p.Color = Color3.new(0.72, 0.88, 0.97); p.Transparency = 0.55; p.CanCollide = false; p.CanQuery = false; p.CastShadow = false
			pcall(function() p.DoubleSided = true end)
		elseif key == "Fall_Foam" then
			p.Material = Enum.Material.SmoothPlastic; p.Color = Color3.new(0.95, 0.98, 1.0); p.Transparency = 0.15; p.CanCollide = false; p.CanQuery = false; p.CastShadow = false
		end
	end
end
-- the moving water (as r2): attachments with Axis across the canal (-x) and SecondaryAxis back up the flow
local function att(name, posLocal, flowLocal)
	local a = Instance.new("Attachment"); a.Name = name
	local pos = TARGET:PointToWorldSpace(posLocal)
	local back = -TARGET:VectorToWorldSpace(flowLocal).Unit
	local across = Vector3.new(-1, 0, 0)
	a.WorldCFrame = CFrame.fromMatrix(pos, across, back)
	a.Parent = rock
	return a
end
local function seq(a, b) return NumberSequence.new({NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b)}) end
local function beam(name, a0, a1, w0, w1, speed)
	local b = Instance.new("Beam"); b.Name = name; b.Attachment0 = a0; b.Attachment1 = a1
	b.Texture = "rbxasset://textures/particles/smoke_main.dds"; b.TextureMode = Enum.TextureMode.Wrap; b.TextureLength = 3; b.TextureSpeed = speed
	b.Width0 = w0; b.Width1 = w1; b.FaceCamera = false; b.Segments = 12; b.LightEmission = 0.15; b.LightInfluence = 0.8
	b.Color = ColorSequence.new(Color3.new(0.92, 0.97, 1)); b.Transparency = seq(0.45, 0.55)
	b.Parent = rock
	return b
end
local nb, np = 0, 0
if rock then
	local chuteDir, dropDir = P.lip - P.top, P.foot - P.lip
	local a0 = att("FallsTop", P.top, chuteDir); local a1 = att("FallsLip", P.lip, chuteDir)
	local a2 = att("FallsLip2", P.lip, dropDir); local a3 = att("FallsFoot", P.foot, dropDir)
	beam("ChuteBeam", a0, a1, 2.8, 3.2, 1.6); beam("DropBeam", a2, a3, 3.2, 3.8, 2.2); nb = 2
	local am = Instance.new("Attachment"); am.Name = "FallsMist"; am.WorldCFrame = CFrame.new(TARGET:PointToWorldSpace(P.mist)) * CFrame.Angles(math.rad(90), 0, 0); am.Parent = rock
	local mist = Instance.new("ParticleEmitter"); mist.Name = "Mist"; mist.Texture = "rbxasset://textures/particles/smoke_main.dds"; mist.Rate = 24
	mist.Lifetime = NumberRange.new(1, 1.8); mist.Speed = NumberRange.new(1.5, 3.5); mist.Size = seq(1.4, 3.8); mist.Transparency = seq(0.65, 1)
	mist.LightEmission = 0.1; mist.Acceleration = Vector3.new(0, -0.8, 0); mist.SpreadAngle = Vector2.new(70, 70); mist.Parent = am
	local spray = Instance.new("ParticleEmitter"); spray.Name = "Spray"; spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"; spray.Rate = 40
	spray.Lifetime = NumberRange.new(0.5, 0.9); spray.Speed = NumberRange.new(4, 7); spray.Size = seq(0.35, 0.1); spray.Transparency = seq(0.2, 1)
	spray.LightEmission = 0.3; spray.Acceleration = Vector3.new(0, -14, 0); spray.SpreadAngle = Vector2.new(35, 35); spray.Parent = am
	np = 2
end
m.Parent = G
pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("after falls3") end)
local fcf, fs = m:GetBoundingBox()
print(string.format("QQ FALLS3 replaced (-> HudBackup.Falls3Replaced): %s", #moved > 0 and table.concat(moved, ", ") or "nothing"))
print(string.format("QQ FALLS3 DONE: CanalFalls3 %s at (%.1f, %.1f, %.1f) %.1f x %.1f x %.1f, x %.1f..%.1f, z %.1f..%.1f; %d stone meshes, %d beams, %d emitters",
	flipped and "(turned back)" or "(as imported)", fcf.X, fcf.Y, fcf.Z, fs.X, fs.Y, fs.Z, fcf.X - fs.X / 2, fcf.X + fs.X / 2, fcf.Z - fs.Z / 2, fcf.Z + fs.Z / 2, nstone, nb, np))
