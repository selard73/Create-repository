-- falls_probe4: READ-ONLY. What rocks/boulders exist in the place to clone for the rapids' head?
local hits = {}
local function look(root, label)
	if not root then return end
	for _, d in ipairs(root:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Model")) and (d.Name:lower():find("boulder") or d.Name:lower():find("rock") or d.Name:lower():find("stone")) then
			local key = label .. ":" .. d.Name .. "[" .. d.ClassName .. "]"
			if not hits[key] then
				local size = d:IsA("BasePart") and tostring(d.Size) or (d:IsA("Model") and tostring(select(2, d:GetBoundingBox())) or "?")
				local mat = d:IsA("BasePart") and (d.Material.Name .. " " .. tostring(d.Color) .. (d:IsA("MeshPart") and (" mesh " .. d.MeshId) or "")) or ""
				hits[key] = string.format("%s size %s %s", key, size, mat)
			end
		end
	end
end
look(workspace:FindFirstChild("SandstoneClimb"), "SandstoneClimb")
look(workspace:FindFirstChild("DomaineKit"), "DomaineKit")
look(workspace:FindFirstChild("ForestKit"), "ForestKit")
look(workspace:FindFirstChild("Domaine"), "Domaine")
look(workspace:FindFirstChild("Village") and workspace.Village:FindFirstChild("Props"), "Village.Props")
look(game:GetService("ServerStorage"), "ServerStorage")
local out = {}
for _, v in pairs(hits) do out[#out + 1] = v end
table.sort(out)
print("QQ FP4 rock-like things (" .. #out .. "): " .. table.concat(out, " | "))
-- the hidden riverside props south of the wall: what are they made of?
local rs = workspace.Village and workspace.Village:FindFirstChild("Props") and workspace.Village.Props:FindFirstChild("riverside")
if rs then
	local parts = {}
	for _, p in ipairs(rs:GetDescendants()) do if p:IsA("BasePart") then parts[#parts + 1] = string.format("%s %s %s", p.Name, p.ClassName, tostring(p.Size)) end end
	print("QQ FP4 riverside model example parts (" .. #parts .. "): " .. table.concat(parts, "; ", 1, math.min(6, #parts)))
end
print("QQ FP4 DONE")
