-- falls_probe1: READ-ONLY. The texture id the importer gave our falls texture (carried in by the tiny quad
-- falls_carrier.obj), plus whether a Falls folder already exists.
local m = workspace:FindFirstChild("falls_carrier")
if not m then print("QQ FP1 no falls_carrier model in the workspace") return end
for _, d in ipairs(m:GetDescendants()) do
	if d:IsA("MeshPart") then
		print(string.format("QQ FP1 carrier %s size %s TextureID '%s' MeshId '%s'", d.Name, tostring(d.Size), d.TextureID, d.MeshId))
	end
end
print("QQ FP1 Falls folder exists:", tostring(workspace.SouthGorge:FindFirstChild("Falls") ~= nil))
print("QQ FP1 DONE")
