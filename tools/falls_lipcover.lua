-- falls_lipcover v1: CHANGES THE PLACE (FallsB only). The thin teal band under the lip survives every geometry fix because
-- terrain water is composited AFTER ordinary (non camera-facing) beams and paints over them regardless of depth (same rule
-- that hid the flat foam beams from above). Camera-facing beams and particles draw after the water. So the lip region gets
-- two FaceCamera beams, vertical sheets that always face the viewer: a plain pale cover that knocks the teal down and a
-- strand-textured layer over it so the lip stays white water, not a panel. From above they are seen edge-on and the
-- ordinary strands carry the view. Re-running replaces them.
local B = workspace.SouthGorge.FallsB
local rig = B.Rig
local ZC, WATER_Y = -547.5, -0.9
local XL = (169.4583 + 201.2856) / 2
local TEX = rig.Strands1.Texture
for _, n in ipairs({"LipCover", "LipStrands", "LipCoverTop", "LipCoverBot", "LipStrandsTop", "LipStrandsBot"}) do local o = rig:FindFirstChild(n); if o then o:Destroy() end end
local function att(name, pos)
	local a = Instance.new("Attachment"); a.Name = name; a.Parent = rig
	a.WorldCFrame = CFrame.fromMatrix(pos, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0))   -- axis straight down: FaceCamera turns the sheet about it
	return a
end
local function seq(pts) local k = {} for _, p in ipairs(pts) do k[#k + 1] = NumberSequenceKeypoint.new(p[1], p[2]) end return NumberSequence.new(k) end
local function mk(name, tex, tlen, speed, tr, glow, zoff)
	local b = Instance.new("Beam"); b.Name = name
	b.Attachment0 = att(name .. "Top", Vector3.new(XL, WATER_Y - 0.5, ZC - 0.8))
	b.Attachment1 = att(name .. "Bot", Vector3.new(XL, WATER_Y - 11.0, ZC - 2.6))
	b.Width0 = 31.4; b.Width1 = 31.6; b.FaceCamera = true; b.Segments = 6
	b.Texture = tex; b.TextureMode = Enum.TextureMode.Wrap; b.TextureLength = tlen; b.TextureSpeed = speed
	b.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 234, 238)), ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 248, 252))})
	b.Transparency = seq(tr); b.LightEmission = glow; b.LightInfluence = 0.5; b.ZOffset = zoff
	b.Parent = rig; return b
end
mk("LipCover", "", 10, 0, {{0, 0.18}, {0.6, 0.22}, {1, 1}}, 0.3, 0.2)
mk("LipStrands", TEX, 44, 1.1, {{0, 0.2}, {0.7, 0.12}, {1, 1}}, 0.5, 0.4)
print(string.format("QQ LC1 lip covers added (FaceCamera): %s; strands tex %s", tostring(rig.LipCover.FaceCamera), TEX))
print("QQ LC1 DONE")
