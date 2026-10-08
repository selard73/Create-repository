-- falls_topfix v1: CHANGES THE PLACE (edits workspace.SouthGorge.FallsB only). Her 00:06 screenshot: the plain teal roll at the
-- lip reads as a flat band from below. So: the Crest beam goes (disabled, kept), and the strand layers and the body start AT
-- the water surface on the brink line and curl over the sill themselves (CurveSize0 3.2, like the roll did), so the top of the
-- fall is the strands' own ragged textured edge, white like Skogafoss, with no flat plane. Spray stays. Re-running is harmless.
local B = workspace.SouthGorge.FallsB
local rig = B.Rig
local ZC, WATER_Y = -547.5, -0.9
local XL = (169.4583 + 201.2856) / 2
local crest = rig:FindFirstChild("Crest"); if crest then crest.Enabled = false end
local function top(attName, x, dy, dz)
	local a = rig:FindFirstChild(attName)
	if a then a.WorldCFrame = CFrame.fromMatrix(Vector3.new(x, WATER_Y + dy, ZC + dz), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)) end
end
top("TopK", XL, -0.1, 0.3); top("TopS1", XL, -0.05, 0.3); top("TopS2", XL + 0.9, -0.15, 0.1); top("TopW", XL, 0.0, 0.4)
local out = {}
for name, c0 in pairs({Back = 3.2, Strands1 = 3.2, Strands2 = 3.0, Wisps = 3.4}) do
	local b = rig:FindFirstChild(name)
	if b then b.CurveSize0 = c0; out[#out + 1] = string.format("%s c0 %.1f top y %.2f", name, b.CurveSize0, b.Attachment0.WorldPosition.Y) end
end
-- the body's top takes a hint of the river's teal so the brink still reads as water turning over, without a flat band
local back = rig:FindFirstChild("Back")
if back then
	back.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 212, 215)), ColorSequenceKeypoint.new(0.12, Color3.fromRGB(176, 214, 224)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(182, 216, 228)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 228, 236))})
end
table.sort(out)
print("QQ TF1 crest off; " .. table.concat(out, "; "))
print("QQ TF1 DONE")
