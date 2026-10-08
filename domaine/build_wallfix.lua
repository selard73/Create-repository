-- WallFix: the estate's stone walls were laid as fixed 12-stud sections, so wherever a run met a gate pillar - or
-- another run - it stopped a stud or three short and left a slot you could see daylight through. This walks every
-- wall line, finds the short ends, and stretches the last section until it meets what it should be meeting.
-- A section is stretched, never scaled: each of its parts grows along the run and shifts half that, so the coping
-- stays the same thickness and height it always was.
-- Run in edit mode: require(workspace.WallFix.PatchModule)()  (packed by village/make_patch.py)
return function()
	local P = workspace.Domaine.Props
	local MAXGAP = 6                                              -- anything wider than this is a doorway, leave it

	local function extentOf(m)                                    -- world x/z box of a model
		local mn, mx
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				for sx = -1, 1, 2 do for sz = -1, 1, 2 do
					local v = (p.CFrame * CFrame.new(p.Size.X / 2 * sx, 0, p.Size.Z / 2 * sz)).Position
					mn = mn and Vector2.new(math.min(mn.X, v.X), math.min(mn.Y, v.Z)) or Vector2.new(v.X, v.Z)
					mx = mx and Vector2.new(math.max(mx.X, v.X), math.max(mx.Y, v.Z)) or Vector2.new(v.X, v.Z)
				end end
			end
		end
		return mn, mx
	end

	local walls, pillars = {}, {}
	for _, c in ipairs(P:GetChildren()) do
		local n = c.Name
		if n:sub(1, 12) == "stone_pillar" then
			local mn, mx = extentOf(c)
			if mn then table.insert(pillars, {mn = mn, mx = mx}) end
		elseif n:sub(1, 10) == "stone_wall" then
			local mn, mx = extentOf(c)
			if mn then
				local w, d = mx.X - mn.X, mx.Y - mn.Y
				table.insert(walls, {m = c, mn = mn, mx = mx, axis = w >= d and "x" or "z"})
			end
		end
	end

	-- stretch one section's far end by `g` studs; dir is +1 to grow toward +axis
	local function stretch(w, g, dir)
		for _, p in ipairs(w.m:GetDescendants()) do
			if p:IsA("BasePart") then
				if w.axis == "x" then
					p.Size += Vector3.new(g, 0, 0)
					p.CFrame = p.CFrame + Vector3.new(g / 2 * dir, 0, 0)
				else
					p.Size += Vector3.new(0, 0, g)
					p.CFrame = p.CFrame + Vector3.new(0, 0, g / 2 * dir)
				end
			end
		end
		if w.axis == "x" then
			if dir > 0 then w.mx = Vector2.new(w.mx.X + g, w.mx.Y) else w.mn = Vector2.new(w.mn.X - g, w.mn.Y) end
		else
			if dir > 0 then w.mx = Vector2.new(w.mx.X, w.mx.Y + g) else w.mn = Vector2.new(w.mn.X, w.mn.Y - g) end
		end
	end

	-- ---------------------------------------------------------------- 1. up to the gate pillars ----
	local toPillars = 0
	for _, pl in ipairs(pillars) do
		local pcx, pcz = (pl.mn.X + pl.mx.X) / 2, (pl.mn.Y + pl.mx.Y) / 2
		for _, w in ipairs(walls) do
			local lo, hi, plo, phi, across, pacross
			if w.axis == "x" then lo, hi, across = w.mn.X, w.mx.X, (w.mn.Y + w.mx.Y) / 2
				plo, phi, pacross = pl.mn.X, pl.mx.X, pcz
			else lo, hi, across = w.mn.Y, w.mx.Y, (w.mn.X + w.mx.X) / 2
				plo, phi, pacross = pl.mn.Y, pl.mx.Y, pcx end
			if math.abs(across - pacross) < 3.5 then
				local g = plo - hi                                -- pillar sits past the far end
				if g > 0.12 and g <= MAXGAP then stretch(w, g, 1); toPillars += 1
				else
					g = lo - phi                                  -- pillar sits before the near end
					if g > 0.12 and g <= MAXGAP then stretch(w, g, -1); toPillars += 1 end
				end
			end
		end
	end

	-- ---------------------------------------------------------------- 2. and to each other ----
	local lines = {}
	for _, w in ipairs(walls) do
		local across = w.axis == "x" and (w.mn.Y + w.mx.Y) / 2 or (w.mn.X + w.mx.X) / 2
		local key = w.axis .. math.floor(across / 3 + 0.5)
		lines[key] = lines[key] or {}
		table.insert(lines[key], w)
	end
	local joined = 0
	for _, list in pairs(lines) do
		table.sort(list, function(a, b)
			if a.axis == "x" then return a.mn.X < b.mn.X end
			return a.mn.Y < b.mn.Y
		end)
		for i = 1, #list - 1 do
			local a, b = list[i], list[i + 1]
			local g = (a.axis == "x") and (b.mn.X - a.mx.X) or (b.mn.Y - a.mx.Y)
			if g > 0.12 and g <= MAXGAP then stretch(a, g, 1); joined += 1 end
		end
	end
	print(string.format("WallFix: %d sections stretched to their gate pillars, %d joined to the next section (%d walls, %d pillars)",
		toPillars, joined, #walls, #pillars))
end
