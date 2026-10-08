-- gorge_probe12: READ-ONLY. What are the white boxes floating in the sky above the ridge (seen from the harbour)?
-- Lists every visible BasePart in the air over the ridge and the plain: x -300..500, y 30..200, z -720..-500,
-- that is not terrain, not in SouthGorge, grouped by its top-level model.
local groups = {}
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("BasePart") and d.Transparency < 1 and not d:IsDescendantOf(workspace.SouthGorge) then
		local p = d.Position
		if p.X > -300 and p.X < 500 and p.Y > 30 and p.Y < 200 and p.Z < -500 and p.Z > -720 then
			local top = d
			while top.Parent and top.Parent ~= workspace do top = top.Parent end
			local key = top:GetFullName() .. " / " .. d.Name .. " [" .. d.ClassName .. "]"
			local g = groups[key] or {n = 0, ex = ""}
			g.n += 1
			if g.ex == "" then g.ex = string.format("(%.0f,%.0f,%.0f) size %s color %s tr %.2f anch %s", p.X, p.Y, p.Z, tostring(d.Size), tostring(d.Color), d.Transparency, tostring(d.Anchored)) end
			groups[key] = g
		end
	end
end
local out = {}
for k, g in pairs(groups) do out[#out + 1] = string.format("%s x%d %s", k, g.n, g.ex) end
table.sort(out)
print("QQ P12 visible parts in the air over the ridge/plain (" .. #out .. " groups): " .. (#out > 0 and table.concat(out, " | ") or "none"))
print("QQ P12 DONE")
