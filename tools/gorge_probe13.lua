-- gorge_probe13: READ-ONLY. The white slabs seen in the sky from the harbour: every visible BasePart (or any part
-- carrying a Decal/Texture/SurfaceGui) higher than y 60 anywhere between x -400..600 and z -800..150, grouped by
-- top-level model, with one example position and size each.
local groups = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and not d:IsDescendantOf(workspace.SouthGorge) and d.Position.Y > 60 then
		local p = d.Position
		if p.X > -400 and p.X < 600 and p.Z > -800 and p.Z < 150 then
			local shows = d.Transparency < 1
			if not shows then
				for _, c in ipairs(d:GetChildren()) do
					if c:IsA("Decal") or c:IsA("Texture") or c:IsA("SurfaceGui") or c:IsA("BillboardGui") then shows = true end
				end
			end
			if shows then
				local top = d
				while top.Parent and top.Parent ~= workspace do top = top.Parent end
				local key = top:GetFullName()
				local g = groups[key] or {n = 0, ex = ""}
				g.n += 1
				if g.ex == "" then g.ex = string.format("%s at (%.0f,%.0f,%.0f) size %s tr %.2f", d.Name, p.X, p.Y, p.Z, tostring(d.Size), d.Transparency) end
				groups[key] = g
			end
		end
	end
end
local out = {}
for k, g in pairs(groups) do out[#out + 1] = string.format("%s x%d e.g. %s", k, g.n, g.ex) end
table.sort(out)
print("QQ P13 visible parts above y 60 (" .. #out .. " groups): " .. (#out > 0 and table.concat(out, " | ") or "none"))
print("QQ P13 DONE")
