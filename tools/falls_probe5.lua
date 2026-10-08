-- falls_probe5 v1: READ-ONLY. One line per rock-like thing in the place (falls_probe4 printed one long line and the log cut it).
local n = 0
local function look(root, label)
	if not root then return end
	local seen = {}
	for _, d in ipairs(root:GetDescendants()) do
		local nm = d.Name:lower()
		if (d:IsA("BasePart") or d:IsA("Model")) and (nm:find("boulder") or nm:find("rock") or nm:find("stone") or nm:find("pebble")) then
			local key = d.Name .. "[" .. d.ClassName .. "]"
			if not seen[key] then
				seen[key] = true; n += 1
				local size = d:IsA("BasePart") and d.Size or (d:IsA("Model") and select(2, d:GetBoundingBox())) or Vector3.zero
				local pos = d:IsA("BasePart") and d.Position or (d:IsA("Model") and d:GetBoundingBox().Position) or Vector3.zero
				local extra = ""
				if d:IsA("BasePart") then extra = d.Material.Name .. " rgb " .. tostring(d.Color) .. (d:IsA("MeshPart") and (" mesh " .. d.MeshId .. " tex " .. tostring(d.TextureID)) or "") end
				local full = d:GetFullName()
				print(string.format("QQ FP5 %s | %s | size %.1f %.1f %.1f | at %.0f %.0f %.0f | %s", label, full, size.X, size.Y, size.Z, pos.X, pos.Y, pos.Z, extra))
			end
		end
	end
end
look(workspace:FindFirstChild("SandstoneClimb"), "SandstoneClimb")
look(workspace:FindFirstChild("DomaineKit"), "DomaineKit")
look(workspace:FindFirstChild("ForestKit"), "ForestKit")
look(workspace:FindFirstChild("Domaine"), "Domaine")
look(workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Props"), "Village.Props")
look(workspace:FindFirstChild("River"), "River")
look(game:GetService("ServerStorage"), "ServerStorage")
print("QQ FP5 total " .. n)
print("QQ FP5 DONE")
