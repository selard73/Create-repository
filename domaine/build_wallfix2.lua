-- WallFix2: close the wall-to-pillar joints for real.
-- The first attempt measured bounding boxes and closed the gap by that, which was not enough: these are MeshParts and
-- the stone inside them does not fill the box, so a box that touches the pillar can still leave daylight. This one
-- measures the VISIBLE faces with raycasts - out from the wall's middle to the pillar's face, and back from beyond the
-- wall's end to the wall's face - and stretches the section by the difference, plus a little overlap so there is no seam.
-- Run in edit mode: require(workspace.WallFix2.PatchModule)()  (packed by village/make_patch.py)
return function()
	local P = workspace.Domaine.Props
	local OVERLAP = 0.25                                          -- push the wall a touch into the pillar
	local MAXGAP = 6

	local function partsOf(m)
		local t = {}
		for _, p in ipairs(m:GetDescendants()) do if p:IsA("BasePart") then table.insert(t, p) end end
		return t
	end
	local function boxOf(m)
		local mn, mx
		for _, p in ipairs(partsOf(m)) do
			for sx = -1, 1, 2 do for sz = -1, 1, 2 do
				local v = (p.CFrame * CFrame.new(p.Size.X / 2 * sx, 0, p.Size.Z / 2 * sz)).Position
				mn = mn and Vector2.new(math.min(mn.X, v.X), math.min(mn.Y, v.Z)) or Vector2.new(v.X, v.Z)
				mx = mx and Vector2.new(math.max(mx.X, v.X), math.max(mx.Y, v.Z)) or Vector2.new(v.X, v.Z)
			end end
		end
		return mn, mx
	end

	local walls, pillars = {}, {}
	for _, c in ipairs(P:GetChildren()) do
		local n = c.Name
		if n:sub(1, 12) == "stone_pillar" then
			local mn, mx = boxOf(c)
			if mn then table.insert(pillars, {m = c, mn = mn, mx = mx, parts = partsOf(c)}) end
		elseif n:sub(1, 10) == "stone_wall" then
			local mn, mx = boxOf(c)
			if mn then
				local w, d = mx.X - mn.X, mx.Y - mn.Y
				table.insert(walls, {m = c, mn = mn, mx = mx, axis = w >= d and "x" or "z", parts = partsOf(c)})
			end
		end
	end

	-- the height to measure at: mid-way up the wall, where both wall and pillar are solid stone
	local function midY(parts)
		local lo, hi = math.huge, -math.huge
		for _, p in ipairs(parts) do
			lo = math.min(lo, p.Position.Y - p.Size.Y / 2)
			hi = math.max(hi, p.Position.Y + p.Size.Y / 2)
		end
		return lo + (hi - lo) * 0.45
	end

	local fixed, report = 0, {}
	for _, pl in ipairs(pillars) do
		local pcx, pcz = (pl.mn.X + pl.mx.X) / 2, (pl.mn.Y + pl.mx.Y) / 2
		for _, w in ipairs(walls) do
			local along = w.axis == "x" and Vector3.new(1, 0, 0) or Vector3.new(0, 0, 1)
			local wcx, wcz = (w.mn.X + w.mx.X) / 2, (w.mn.Y + w.mx.Y) / 2
			local across = w.axis == "x" and math.abs(wcz - pcz) or math.abs(wcx - pcx)
			local toward = w.axis == "x" and (pcx - wcx) or (pcz - wcz)
			local half = w.axis == "x" and (w.mx.X - w.mn.X) / 2 or (w.mx.Y - w.mn.Y) / 2
			if across < 3.5 and math.abs(toward) > half - 1 and math.abs(toward) < half + MAXGAP + 6 then
				local dir = toward > 0 and 1 or -1
				local y = midY(w.parts)
				local origin = Vector3.new(wcx, y, wcz)
				local rpP = RaycastParams.new(); rpP.FilterType = Enum.RaycastFilterType.Include; rpP.FilterDescendantsInstances = pl.parts
				local hitP = workspace:Raycast(origin, along * dir * (half + MAXGAP + 8), rpP)
				local rpW = RaycastParams.new(); rpW.FilterType = Enum.RaycastFilterType.Include; rpW.FilterDescendantsInstances = w.parts
				local outside = origin + along * dir * (half + MAXGAP + 8)
				local hitW = workspace:Raycast(outside, along * -dir * (half + MAXGAP + 8), rpW)
				if hitP and hitW then
					local dP = (hitP.Position - origin).Magnitude       -- to the pillar's face
					local dW = (hitW.Position - origin).Magnitude       -- to the wall's own end face
					local gap = dP - dW
					if gap > 0.03 and gap <= MAXGAP then
						local g = gap + OVERLAP
						for _, p in ipairs(w.parts) do
							if w.axis == "x" then
								p.Size += Vector3.new(g, 0, 0); p.CFrame = p.CFrame + Vector3.new(g / 2 * dir, 0, 0)
							else
								p.Size += Vector3.new(0, 0, g); p.CFrame = p.CFrame + Vector3.new(0, 0, g / 2 * dir)
							end
						end
						fixed += 1
						table.insert(report, string.format("%.0f,%.0f by %.2f", pcx, pcz, g))
					end
				end
			end
		end
	end
	print(string.format("WallFix2: %d wall ends pushed into their pillars (%s)", fixed, #report > 0 and table.concat(report, ", ") or "nothing left open"))
end
