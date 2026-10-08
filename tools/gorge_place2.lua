-- gorge_place2: CHANGES THE PLACE (finishing step 3): the gorge's rock and aqueduct pieces get the same material as the
-- Sandstone Climb's rock (Plastic; SmoothPlastic read shiny). Only workspace.SouthGorge is touched.
local n = 0
for _, p in ipairs(workspace.SouthGorge:GetDescendants()) do
	if p:IsA("MeshPart") then p.Material = Enum.Material.Plastic; n += 1 end
end
print("QQ P2 material Plastic on", n, "pieces")
