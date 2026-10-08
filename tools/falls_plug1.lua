-- falls_plug1 v1: CHANGES THE PLACE (scenery only): ONE small plain beam added to the existing workspace.SouthGorge.Falls
-- (first-round look kept as is). Her 23:26 screenshot: a teal sliver at the top of the EAST corner seen from the foot. Measured
-- (falls_probe7): at the brink row the terrain water reaches x 203.5, 2.2 studs past the east corner (201.29), and the crest beam
-- ends at 203.4, so from below the water's end face peeks out. This beam sits just past the crest's east end (x 199.8..204.8 at
-- the top, narrowing to 3.5 wide), same colours and fade as the crest, curling over the sill the same way, so it reads as the
-- crest continuing into the rock. Re-running replaces it.
local F = workspace.SouthGorge.Falls
local rig = F.Rig
local crest = rig:FindFirstChild("Crest"); assert(crest, "Crest beam missing")
local ZC, WATER_Y = -547.5, -0.9
for _, n in ipairs({"PlugE", "PlugETop", "PlugEBot"}) do local o = rig:FindFirstChild(n); if o then o:Destroy() end end
local function att(name, pos)
	local a = Instance.new("Attachment"); a.Name = name; a.Parent = rig
	a.WorldCFrame = CFrame.fromMatrix(pos, Vector3.new(0, 0, -1), Vector3.new(1, 0, 0))
	return a
end
local b = Instance.new("Beam"); b.Name = "PlugE"
b.Attachment0 = att("PlugETop", Vector3.new(202.3, WATER_Y - 0.05, ZC + 0.3))
b.Attachment1 = att("PlugEBot", Vector3.new(202.3, WATER_Y - 9.0, ZC - 2.8))
b.Width0 = 5; b.Width1 = 3.5; b.CurveSize0 = crest.CurveSize0; b.CurveSize1 = 0
b.Texture = ""; b.Color = crest.Color; b.Transparency = crest.Transparency
b.LightEmission = crest.LightEmission; b.LightInfluence = crest.LightInfluence; b.Brightness = 1
b.Segments = 8; b.ZOffset = crest.ZOffset + 0.05; b.FaceCamera = false
b.Parent = rig
print(string.format("QQ PL1 PlugE added: x %.1f..%.1f at the top, curve %.1f, crest spans %.1f..%.1f", 202.3 - 2.5, 202.3 + 2.5, b.CurveSize0, crest.Attachment0.WorldPosition.X - crest.Width0 / 2, crest.Attachment0.WorldPosition.X + crest.Width0 / 2))
print("QQ PL1 DONE")
