-- falls_plug2 v1: CHANGES THE PLACE (scenery only): edits the existing workspace.SouthGorge.Falls (first-round look kept).
-- The teal sliver at the top of the east corner (her 23:26 screenshot) is NOT the terrain water: it is the crest beam's own
-- dark-teal top (y -0.95..-2) showing beyond the corner, where the white body (which starts at y -2.6) does not cover it.
-- So: the teal crest goes back to 32 wide (ends AT the corners, x 169.4..201.4), and two plain white-mint plugs (4 wide,
-- y -0.95 down to -9, curling like the crest) cover the water's end face beyond each corner instead: the roll reads teal
-- across the river with white foam against each wall. PlugE from falls_plug1 is replaced. Re-running is harmless.
local F = workspace.SouthGorge.Falls
local rig = F.Rig
local crest = rig:FindFirstChild("Crest"); assert(crest, "Crest beam missing")
local ZC, WATER_Y = -547.5, -0.9
local XMID = (169.4583 + 201.2856) / 2
crest.Width0 = 32; crest.Width1 = 32
for _, n in ipairs({"PlugE", "PlugETop", "PlugEBot", "PlugW", "PlugWTop", "PlugWBot"}) do local o = rig:FindFirstChild(n); if o then o:Destroy() end end
local function att(name, pos)
	local a = Instance.new("Attachment"); a.Name = name; a.Parent = rig
	a.WorldCFrame = CFrame.fromMatrix(pos, Vector3.new(0, 0, -1), Vector3.new(1, 0, 0))
	return a
end
local WHITE = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(226, 246, 250)), ColorSequenceKeypoint.new(1, Color3.fromRGB(242, 250, 255))})
local out = {}
for _, side in ipairs({{name = "PlugE", x = 202.9}, {name = "PlugW", x = 167.5}}) do
	local b = Instance.new("Beam"); b.Name = side.name
	b.Attachment0 = att(side.name .. "Top", Vector3.new(side.x, WATER_Y - 0.05, ZC + 0.3))
	b.Attachment1 = att(side.name .. "Bot", Vector3.new(side.x, WATER_Y - 9.0, ZC - 2.8))
	b.Width0 = 4; b.Width1 = 3; b.CurveSize0 = crest.CurveSize0; b.CurveSize1 = 0
	b.Texture = ""; b.Color = WHITE; b.Transparency = crest.Transparency
	b.LightEmission = crest.LightEmission; b.LightInfluence = crest.LightInfluence; b.Brightness = 1
	b.Segments = 8; b.ZOffset = crest.ZOffset + 0.05; b.FaceCamera = false
	b.Parent = rig
	out[#out + 1] = string.format("%s x %.1f..%.1f", side.name, side.x - 2, side.x + 2)
end
local cx = crest.Attachment0.WorldPosition.X
print(string.format("QQ PL2 crest now %g wide: x %.1f..%.1f (corners 169.46 / 201.29); plugs %s", crest.Width0, cx - crest.Width0 / 2, cx + crest.Width0 / 2, table.concat(out, ", ")))
print("QQ PL2 DONE")
