-- landfix1_fidelity.lua (Oct 22 2026): the close-fitting collision shapes for landfix1's big meshes, in its own call.
-- PreciseConvexDecomposition follows the mountains' concave flanks and the cliffs' faces, so you stand ON them (a Hull would
-- leave you walking on air above the slopes). The boulders keep Default. Old fidelity kept in LandFix1WasFidelity. "QQ LANDFIX1F".
local sculpt = workspace.JapanMap.BlenderScenery["Sculpted terrain"]
local out = {}
for _, name in ipairs({"JP_Volcano_Sculpted", "JP_Fuji_Sculpted", "JP_Island_Cliffs_West", "JP_Island_Cliffs_North", "JP_Island_Cliffs_South", "JP_Waterfall_Rockface"}) do
	local p = sculpt[name]
	if p:GetAttribute("LandFix1WasFidelity") == nil then p:SetAttribute("LandFix1WasFidelity", p.CollisionFidelity.Name) end
	p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
	table.insert(out, "QQ LANDFIX1F " .. name .. ": " .. p.CollisionFidelity.Name)
	task.wait()
end
return table.concat(out, "\n")
