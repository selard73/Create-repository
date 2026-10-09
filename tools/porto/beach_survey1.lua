-- porto/beach_survey1 (job 31): READ-ONLY, EDIT mode. Shannon: "more shells scattered on both of the beaches, not just the
-- one beach by Bella". Finds every patch of dry Sand terrain in Porto Nocciola (x 0..620, z -1260..-530, 6-stud grid,
-- cells above the water line) and prints the biggest patches as boxes for the sea glass spawner. Output lines "QQ BEACH".
local STEP, X0, X1, Z0, Z1 = 6, 0, 620, -1260, -530
local params = RaycastParams.new(); params.IgnoreWater = false
local nx, nz = math.floor((X1 - X0) / STEP) + 1, math.floor((Z1 - Z0) / STEP) + 1
local sand = {}            -- [ix][iz] = y
local n = 0
for ix = 0, nx - 1 do
	sand[ix] = {}
	for iz = 0, nz - 1 do
		local x, z = X0 + ix * STEP, Z0 + iz * STEP
		local hit = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -300, 0), params)
		if hit and hit.Instance == workspace.Terrain and hit.Material == Enum.Material.Sand and hit.Normal.Y > 0.7 then
			sand[ix][iz] = hit.Position.Y; n += 1
		end
	end
	if ix % 20 == 0 then task.wait() end
end
print(string.format("QQ BEACH %d dry sand cells of %d sampled", n, nx * nz))
local seen, patches = {}, {}
for ix = 0, nx - 1 do for iz = 0, nz - 1 do
	if sand[ix][iz] and not (seen[ix] and seen[ix][iz]) then
		local stack, cells = {{ix, iz}}, {}
		seen[ix] = seen[ix] or {}; seen[ix][iz] = true
		while #stack > 0 do
			local c = table.remove(stack); table.insert(cells, c)
			for _, d in ipairs({{1, 0}, {-1, 0}, {0, 1}, {0, -1}}) do
				local jx, jz = c[1] + d[1], c[2] + d[2]
				if sand[jx] and sand[jx][jz] and not (seen[jx] and seen[jx][jz]) then seen[jx] = seen[jx] or {}; seen[jx][jz] = true; table.insert(stack, {jx, jz}) end
			end
		end
		local lo, hi, ylo, yhi = Vector2.new(1e9, 1e9), Vector2.new(-1e9, -1e9), 1e9, -1e9
		for _, c in ipairs(cells) do
			local x, z, y = X0 + c[1] * STEP, Z0 + c[2] * STEP, sand[c[1]][c[2]]
			lo = Vector2.new(math.min(lo.X, x), math.min(lo.Y, z)); hi = Vector2.new(math.max(hi.X, x), math.max(hi.Y, z))
			ylo, yhi = math.min(ylo, y), math.max(yhi, y)
		end
		table.insert(patches, {n = #cells, lo = lo, hi = hi, ylo = ylo, yhi = yhi})
	end
end end
table.sort(patches, function(a, b) return a.n > b.n end)
for i = 1, math.min(8, #patches) do
	local p = patches[i]
	-- what stands nearby, to name the beach
	local near = {}
	local centre = Vector3.new((p.lo.X + p.hi.X) / 2, p.yhi, (p.lo.Y + p.hi.Y) / 2)
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and m.Name:lower():find("squirrel") and (m:GetPivot().Position - centre).Magnitude < 60 then table.insert(near, m.Name) end
		if #near >= 4 then break end
	end
	print(string.format("QQ BEACH %d: %d cells (~%d sq studs) x %.0f..%.0f z %.0f..%.0f y %.1f..%.1f | near: %s", i, p.n, p.n * STEP * STEP, p.lo.X, p.hi.X, p.lo.Y, p.hi.Y, p.ylo, p.yhi, table.concat(near, ", ")))
end
