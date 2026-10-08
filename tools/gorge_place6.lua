-- gorge_place6: CHANGES THE PLACE (small): the rock faces are single-sided surfaces, so from inside the gorge one can
-- look past a corner THROUGH the back of the cliff arm's first stretch into the hollow behind it (a dark terrain wall
-- showed at the east corner in the boat's-eye capture). Rendering both sides of the pieces that meet at the corners
-- closes that: the walls' last two chunks each side, the arms' first chunks and the sill face.
local names = {"SouthRock_W08", "SouthRock_W09", "SouthRock_E08", "SouthRock_E09",
	"SouthCliff_W01", "SouthCliff_W01_Lo", "SouthCliff_E01", "SouthCliff_E01_Lo", "SouthCliff_L01", "SouthCliff_L01_Lo"}
local fR = workspace.SouthGorge.Rock
local n, miss = 0, {}
for _, nm in ipairs(names) do
	local p = fR:FindFirstChild(nm)
	if p and p:IsA("MeshPart") then p.DoubleSided = true; n += 1 else miss[#miss + 1] = nm end
end
print(string.format("QQ P6 DoubleSided on %d pieces; missing: %s", n, #miss > 0 and table.concat(miss, ", ") or "none"))
print("QQ P6 DONE")
