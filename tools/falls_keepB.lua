-- falls_keepB v1: CHANGES THE PLACE: settles the A/B on B. The switched-off fall part of the old Falls model (its Crest, Body,
-- Sheet2, Ribbon1-4, MistBank, MistBank2, PlugE/W beams with their attachments, and the Spray, Mist, Plume, Splash, FoamRing
-- parts) is moved to ServerStorage.GorgeBackup.FallsA_fallpart (not deleted); the rapids stay in Falls. FallsB stays as the
-- fall. Also: B's lower part widens from 31.6 to 35 studs over the drop (Width1 of Back/Strands/Wisps) so the fall spreads
-- a little and meets the rock where the cliff face recedes below the corners (her 23:52 trace); the top stays corner to corner.
local G = workspace.SouthGorge
local SS = game:GetService("ServerStorage")
local GB = SS:FindFirstChild("GorgeBackup") or Instance.new("Folder", SS); GB.Name = "GorgeBackup"
local store = GB:FindFirstChild("FallsA_fallpart") or Instance.new("Folder", GB); store.Name = "FallsA_fallpart"
local A = G.Falls
local A_BEAMS = {Crest = 1, Body = 1, Sheet2 = 1, Ribbon1 = 1, Ribbon2 = 1, Ribbon3 = 1, Ribbon4 = 1, MistBank = 1, MistBank2 = 1, PlugE = 1, PlugW = 1}
local A_PARTS = {Spray = 1, Mist = 1, Plume = 1, Splash = 1, FoamRing = 1}
local moved = 0
for _, d in ipairs(A:GetDescendants()) do
	if d:IsA("Beam") and A_BEAMS[d.Name] then
		local a0, a1 = d.Attachment0, d.Attachment1
		d.Parent = store; moved += 1
		if a0 then a0.Parent = store end
		if a1 then a1.Parent = store end
	end
end
for _, c in ipairs(A:GetChildren()) do
	if c:IsA("BasePart") and A_PARTS[c.Name] then c.Parent = store; moved += 1 end
end
local B = G.FallsB
local widened = {}
for _, n in ipairs({"Back", "Strands1", "Strands2", "Wisps"}) do
	local b = B.Rig:FindFirstChild(n)
	if b then b.Width1 = (n == "Strands2") and 33.2 or 35; widened[#widened + 1] = string.format("%s %g->%g", n, b.Width0, b.Width1) end
end
for _, d in ipairs(B:GetDescendants()) do if d:IsA("Beam") or d:IsA("ParticleEmitter") then d.Enabled = true end end
local left = 0
for _, d in ipairs(A:GetDescendants()) do if d:IsA("Beam") then left += 1 end end
print(string.format("QQ KB1 moved %d of A's fall items to %s; Falls keeps %d rapids beams; B widened at the bottom: %s", moved, store:GetFullName(), left, table.concat(widened, ", ")))
print("QQ KB1 DONE")
