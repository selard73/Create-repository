-- falls_rocks2_fix v1: CHANGES THE PLACE (completes the approved rocks v2): the forest-kit templates are kept invisible, and the
-- clones inherited that, so every RapidsRocks part becomes fully visible (Transparency 0). Reports what it found first.
local M = workspace.SouthGorge:FindFirstChild("RapidsRocks")
assert(M, "RapidsRocks missing")
local before, n = {}, 0
for _, p in ipairs(M:GetChildren()) do
	if p:IsA("BasePart") then
		before[#before + 1] = string.format("%s tr %.2f", p.Name, p.Transparency)
		p.Transparency = 0; p.LocalTransparencyModifier = 0
		n += 1
	end
end
local t = workspace.ForestKit.rock_big.Rock1
print(string.format("QQ RF1 fixed %d rocks; template rock_big.Rock1 transparency %.2f parent %s; before: %s", n, t.Transparency, t.Parent:GetFullName(), table.concat(before, ", ", 1, math.min(6, #before))))
print("QQ RF1 DONE")
