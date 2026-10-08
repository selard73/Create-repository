-- v66 undo the v65 stretch on the gate LEAF uprights (only the two Posts should reach the ground)
local gate
for _, d in ipairs(workspace:GetDescendants()) do if d.Name == "VillageGate" and d.Parent and d.Parent.Name == "Gates" then gate = d break end end
local undo = {[-119.9] = 0.55, [-114.3] = 0.75, [-125.5] = 0.66}
local n = 0
for _, p in ipairs(gate:GetDescendants()) do
	if p:IsA("BasePart") and p.Name == "Upright" then
		for z, ext in pairs(undo) do
			if math.abs(p.Position.Z - z) < 0.06 and math.abs(p.Position.X - 137.6) < 0.1 then
				p.Size = p.Size - Vector3.new(0, ext, 0)
				p.CFrame = p.CFrame + Vector3.new(0, ext / 2, 0)
				n += 1
			end
		end
	end
end
print("QQ uprights restored", n)
