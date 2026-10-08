-- falls_rapids_patch v1: CHANGES THE PLACE (edits the 30 Rapids beams and the Foam emitters in workspace.SouthGorge.Falls).
-- Her rapids reference (00:00): dark teal water with white foam in PATCHES and streaks, not a solid white sheet. The three
-- flat foam chains get the new patchy foam texture (italy/falls/falls2_foam.png, ~40% coverage, transparent between) so
-- the dark water shows between the foam; same studs-per-second as before; the flat foam puffs thin out (Rate 32 -> 18).
-- The texture id is read from the Import 3D carrier (workspace.falls2_foam_carrier.Falls2Foam) and the carrier is removed.
local F = workspace.SouthGorge.Falls
local TEX = "%FOAM%"
local car = workspace:FindFirstChild("falls2_foam_carrier")
if car then
	local q = car:FindFirstChild("Falls2Foam", true)
	if q and q:IsA("MeshPart") and q.TextureID ~= "" then TEX = q.TextureID end
	car:Destroy()
end
assert(TEX:find("rbxassetid://"), "foam texture id missing: import italy/falls/falls2_foam_carrier.obj first")
local SPEED = {Rapids1 = 0.22 * 26 / 24, Rapids2 = 0.32 * 26 / 24, Rapids3 = 0.45 * 26 / 24}   -- keep studs/s with TextureLength 24
local nb = 0
for _, b in ipairs(F:GetDescendants()) do
	if b:IsA("Beam") and b.Name:match("^Rapids%d_%d+$") then
		local layer = b.Name:match("^(Rapids%d)")
		b.Texture = TEX; b.TextureMode = Enum.TextureMode.Wrap; b.TextureLength = 24; b.TextureSpeed = SPEED[layer] or 0.3
		nb += 1
	end
end
local ne = 0
for _, p in ipairs(F:GetChildren()) do
	if p:IsA("BasePart") and p.Name:match("^Foam_%d+$") then
		local e = p:FindFirstChildOfClass("ParticleEmitter"); if e then e.Rate = 18; ne += 1 end
	end
end
print(string.format("QQ RP1 rapids: %d beams textured with %s (TextureLength 24), %d foam boxes thinned to rate 18", nb, TEX, ne))
print("QQ RP1 DONE")
