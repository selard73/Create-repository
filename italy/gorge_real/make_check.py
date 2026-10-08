"""make_check.py - writes tools/gorge_check1.lua (READ-ONLY): grass heights beside each rim and horizontal rays from
the river's centre that report any terrain standing where the rock faces will be, from gorge_shape.py."""
import numpy as np, gorge_shape as G
zs = np.arange(G.Z_START - 2, G.Z_END + 8, -4.0)
rows = []
for z in zs:
    cx = float(G.centre_x(z))
    for s in (-1, 1):
        rows.append("{%.1f,%.2f,%d,%.2f,%.2f}" % (z, cx, s, G.rim_d(z, s), float(G.top_at(z, s))))
lua = r'''-- gorge_check1: READ-ONLY. The grass beside each rim and any terrain standing where the rock faces will be.
local S = {%s}
local tp = RaycastParams.new(); tp.FilterType = Enum.RaycastFilterType.Include; tp.FilterDescendantsInstances = {workspace.Terrain}; tp.IgnoreWater = true
local out, pk = {}, {}
for _, r in ipairs(S) do
	local z, cx, s, rim, T = r[1], r[2], r[3], r[4], r[5]
	local hs = {}
	for _, dd in ipairs({1.5, 2.5, 4.0, 6.0}) do
		local hit = workspace:Raycast(Vector3.new(cx + s * (rim + dd), 200, z), Vector3.new(0, -400, 0), tp)
		hs[#hs + 1] = hit and string.format("%%.2f", hit.Position.Y) or "-"
	end
	out[#out + 1] = string.format("%%.0f:%%d:%%.1f:%%s", z, s, T, table.concat(hs, "/"))
	for _, y in ipairs({0.6, 2.0, 0.3 * T, 0.6 * T, T - 2.5}) do
		if y > 0 and y < T then
			local hit = workspace:Raycast(Vector3.new(cx, y, z), Vector3.new(s * (rim + 1.0), 0, 0), tp)
			if hit then pk[#pk + 1] = string.format("%%.0f:%%d:%%.1f:%%.2f", z, s, y, math.abs(hit.Position.X - cx)) end
		end
	end
	if #out == 24 then print("QQ C1 RIM " .. table.concat(out, " ")); out = {} end
	if #pk >= 24 then print("QQ C1 HIT " .. table.concat(pk, " ")); pk = {} end
end
if #out > 0 then print("QQ C1 RIM " .. table.concat(out, " ")) end
if #pk > 0 then print("QQ C1 HIT " .. table.concat(pk, " ")) end
print("QQ C1 DONE")
''' % ",".join(rows)
open(r"C:\Users\slard\roblox-props\tools\gorge_check1.lua", "w", encoding="utf-8", newline="\n").write(lua)
print("ok", len(rows))
