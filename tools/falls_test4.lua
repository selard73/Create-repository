-- falls_test4: TEMPORARY. Do flat foam PARTICLES show over the water from above (the flat beams do not)?
-- Rapids beams back to ZOffset 0.1-0.3; every Foam_* emitter boosted (Rate 60, Size 3->6, more opaque).
local F = workspace.SouthGorge.Falls
local nb, ne = 0, 0
for _, d in ipairs(F:GetDescendants()) do
	if d:IsA("Beam") and d.Name:sub(1, 6) == "Rapids" then d.ZOffset = 0.2; nb += 1
	elseif d:IsA("ParticleEmitter") and d.Parent.Name:sub(1, 4) == "Foam" then
		d.Rate = 60; d.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(0.5, 6), NumberSequenceKeypoint.new(1, 3)})
		d.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(0.7, 0.5), NumberSequenceKeypoint.new(1, 1)})
		d.LightEmission = 0.6; d.LightInfluence = 0.1
		ne += 1
	end
end
print(string.format("QQ FT4 %d rapids beams zoffset reset; %d foam emitters boosted", nb, ne))
print("QQ FT4 DONE")
