-- tt_near_probe v1: READ-ONLY. Everything (any BasePart, CanQuery or not) within 13 studs of each dais centre, except the dais,
-- its spawn, the terrain and my travel board: what a signpost could clash with (the forest race start line, for one).
local centres = {forest = Vector3.new(3, 1, 1), village = Vector3.new(196, 1, -36), domaine = Vector3.new(438, 4, -36), porto = Vector3.new(232, -48, -580)}
local found = {}
for id in pairs(centres) do found[id] = {} end
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d ~= workspace.Terrain then
		local m = d:FindFirstAncestorOfClass("Model")
		local top = d
		while top.Parent and top.Parent ~= workspace do top = top.Parent end
		local tn = top.Name
		if not (tn:sub(1, 9) == "SpawnDais" or tn:sub(1, 6) == "Spawn_" or tn == "Travel") then
			for id, c in pairs(centres) do
				local dx, dz = d.Position.X - c.X, d.Position.Z - c.Z
				local r = math.sqrt(dx * dx + dz * dz) - math.max(d.Size.X, d.Size.Z) / 2
				if r < 13 and math.abs(d.Position.Y - c.Y) < 12 then
					found[id][#found[id] + 1] = string.format("%s/%s (%.1f,%.1f,%.1f) size %.1fx%.1fx%.1f ang %.0f q=%s", tn, d.Name, d.Position.X, d.Position.Y, d.Position.Z, d.Size.X, d.Size.Y, d.Size.Z, math.deg(select(2, d.CFrame:ToEulerAnglesYXZ())), tostring(d.CanQuery))
				end
			end
		end
	end
end
for id, list in pairs(found) do
	print(string.format("QQ NP %s: %d parts within 13 studs", id, #list))
	table.sort(list)
	for i, s in ipairs(list) do if i <= 40 then print("QQ NP  " .. id .. " " .. s) end end
	if #list > 40 then print("QQ NP  " .. id .. " ... " .. (#list - 40) .. " more") end
end
print("QQ NP DONE")