-- FlushToGround: sits every forest prop properly on the grass.
-- The catch these kit props spring is that they are MeshParts whose mesh does NOT fill its box: a fallen log's Wood
-- part is 3.3 studs tall but the log inside it is thinner and sits high in the box, so grounding by the bounding box
-- (or by the pivot, which is worse) leaves the log you can see hovering over its own shadow. The only honest measure
-- is a raycast: from under the ground, straight up, until it hits the prop. That is its real underside.
-- Run in edit mode: require(workspace.Flush.PatchModule)()  (packed by village/make_patch.py)
return function(opts)
	opts = opts or {}
	local SINK = opts.sink or 0.06                                -- how far the underside beds into the grass
	local folders = {}
	for _, n in ipairs(opts.folders or {"Forest"}) do
		local f = workspace:FindFirstChild(n)
		if f then table.insert(folders, f) end
	end

	local ground = {workspace.Terrain}
	local bp = workspace:FindFirstChild("Baseplate"); if bp then table.insert(ground, bp) end
	local rpG = RaycastParams.new(); rpG.FilterType = Enum.RaycastFilterType.Include; rpG.FilterDescendantsInstances = ground

	local moved, checked, worst, worstName = 0, 0, 0, "-"
	for _, F in ipairs(folders) do
		for _, m in ipairs(F:GetChildren()) do
			if m:IsA("Model") and m.Name ~= "HidingSpots" then
				local parts = {}
				local mn, mx
				for _, p in ipairs(m:GetDescendants()) do
					if p:IsA("BasePart") and p.Transparency < 0.95 then
						table.insert(parts, p)
						for sx = -1, 1, 2 do for sz = -1, 1, 2 do
							local v = (p.CFrame * CFrame.new(p.Size.X / 2 * sx, 0, p.Size.Z / 2 * sz)).Position
							mn = mn and Vector2.new(math.min(mn.X, v.X), math.min(mn.Y, v.Z)) or Vector2.new(v.X, v.Z)
							mx = mx and Vector2.new(math.max(mx.X, v.X), math.max(mx.Y, v.Z)) or Vector2.new(v.X, v.Z)
						end end
					end
				end
				if #parts > 0 and mn then
					local rpM = RaycastParams.new(); rpM.FilterType = Enum.RaycastFilterType.Include; rpM.FilterDescendantsInstances = parts
					local gap = math.huge
					-- sample each PART over its own footprint, so a thin trunk inside a wide canopy is never missed
					for _, p in ipairs(parts) do
						for a = -0.34, 0.35, 0.34 do
							for b = -0.34, 0.35, 0.34 do
								local v = (p.CFrame * CFrame.new(p.Size.X * a, 0, p.Size.Z * b)).Position
								local g = workspace:Raycast(Vector3.new(v.X, 200, v.Z), Vector3.new(0, -320, 0), rpG)
								if g then
									local u = workspace:Raycast(Vector3.new(v.X, g.Position.Y - 40, v.Z), Vector3.new(0, 120, 0), rpM)
									if u then gap = math.min(gap, u.Position.Y - g.Position.Y) end
								end
							end
						end
					end
					if gap < 1e6 then
						checked += 1
						local drop = gap + SINK
						if math.abs(drop) > 0.04 then
							m:PivotTo(m:GetPivot() - Vector3.new(0, drop, 0))
							moved += 1
							if math.abs(drop) > math.abs(worst) then worst, worstName = drop, m.Name end
						end
					end
				end
			end
		end
	end
	print(string.format("FlushToGround: %d props measured by raycast, %d moved (largest correction %.2f on %s)",
		checked, moved, worst, worstName))
end
