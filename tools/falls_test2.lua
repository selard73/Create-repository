-- falls_test2: TEMPORARY (the next falls_water2 run rebuilds everything). Why do flat beams not show from above?
-- (1) all Rapids* beams -> FaceCamera = true. (2) TestFlatA: a plain white flat beam (our flat frame) 30 studs over
-- the plateau east of the gorge, in the overhead camera's view. (3) TestFlatB: same place, frame rotated so the
-- attachment's Y points up (width vertical: a standing ribbon), as a control. (4) TestFlatC: flat frame but with
-- the attachments' Y along the SEGMENT direction instead (if beams use the Z axis for width, this one lies flat).
local F = workspace.SouthGorge.Falls
local n = 0
for _, b in ipairs(F:GetDescendants()) do
	if b:IsA("Beam") and b.Name:sub(1, 6) == "Rapids" then b.FaceCamera = true; n += 1 end
end
local T = Instance.new("Part"); T.Name = "FallsTestRig"; T.Size = Vector3.new(1, 1, 1); T.CFrame = CFrame.new(240, 30, -550)
T.Anchored = true; T.CanCollide = false; T.CanQuery = false; T.Transparency = 1; T.Parent = F
local function mk(name, p0, p1, X, Y, col)
	local a0 = Instance.new("Attachment"); a0.Parent = T; a0.WorldCFrame = CFrame.fromMatrix(p0, X, Y)
	local a1 = Instance.new("Attachment"); a1.Parent = T; a1.WorldCFrame = CFrame.fromMatrix(p1, X, Y)
	local b = Instance.new("Beam"); b.Name = name; b.Attachment0 = a0; b.Attachment1 = a1; b.Width0 = 12; b.Width1 = 12
	b.Texture = ""; b.Transparency = NumberSequence.new(0); b.Color = ColorSequence.new(col); b.LightEmission = 1; b.LightInfluence = 0
	b.FaceCamera = false; b.Segments = 1; b.Parent = T
end
mk("TestFlatA", Vector3.new(230, 30, -560), Vector3.new(230, 30, -540), Vector3.new(0, 1, 0), Vector3.new(1, 0, 0), Color3.fromRGB(255, 40, 40))     -- red: our flat frame
mk("TestFlatB", Vector3.new(250, 30, -560), Vector3.new(250, 30, -540), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0), Color3.fromRGB(40, 255, 40))     -- green: Y up (standing ribbon)
mk("TestFlatC", Vector3.new(270, 30, -560), Vector3.new(270, 30, -540), Vector3.new(1, 0, 0), Vector3.new(0, 0, -1), Color3.fromRGB(40, 80, 255))   -- blue: Y along the segment
print(string.format("QQ FT2 rapids FaceCamera on %d beams; test beams red (flat frame) green (Y up) blue (Y along segment) at x 230/250/270, y 30, z -560..-540", n))
print("QQ FT2 DONE")
