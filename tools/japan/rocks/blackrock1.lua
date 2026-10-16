-- blackrock1.lua (job 125): the BLACK BOULDERS in Japan (Shannon's picture: huge black faceted rocks over the stream). The same cause as
-- the black JP_Canal_Rocks strips and the "little black stones" sheet: parts in Rock with the MaterialVariant "JM_PhotographicRock",
-- whose texture does not load, so Roblox draws them black. 1. DIAGNOSES: lists the variant's texture ids in MaterialService and every
-- part in JapanMap that wears it (by parent, with sizes); 2. FIXES (only when FIX = true): drops the variant on those parts and gives
-- them plain Rock in a warm stone grey (the kit rocks' grey), the old variant / material / colour kept as attributes (BlackRockOld*)
-- so it reverses. Play-test PREVIEW with FIX = true first; Studio EDIT on her word. Output "QQ BLACKROCK1".
local FIX = false                                                          -- SUPERSEDED (runner 7): the black is baked-in dark VERTEX COLOURS in the meshes, not the variant - diagnostics only; the fix is rebuild_dark_meshes.py + ApplyMesh
local VARIANT = "JM_PhotographicRock"
local STONE = Color3.new(0.58, 0.57, 0.55)
local J = workspace:FindFirstChild("JapanMap")
if not J then print("QQ BLACKROCK1 ABORT: workspace.JapanMap missing") return end
local MS = game:GetService("MaterialService")
local mv = MS:FindFirstChild(VARIANT, true)
if mv and mv:IsA("MaterialVariant") then
	print(string.format("QQ BLACKROCK1 variant %s: BaseMaterial %s, ColorMap '%s', NormalMap '%s', RoughnessMap '%s', MetalnessMap '%s', StudsPerTile %.1f",
		VARIANT, tostring(mv.BaseMaterial), mv.ColorMap, mv.NormalMap, mv.RoughnessMap, mv.MetalnessMap, mv.StudsPerTile))
else
	print("QQ BLACKROCK1 variant " .. VARIANT .. " is NOT in MaterialService (a part naming a missing variant draws its base material, so a black one has a texture that fails to load)")
end
local byParent, n, fixed = {}, 0, 0
for _, d in ipairs(J:GetDescendants()) do
	if d:IsA("BasePart") and d.MaterialVariant == VARIANT then
		n += 1
		local key = d.Parent:GetFullName()
		byParent[key] = byParent[key] or {count = 0, biggest = 0, example = d.Name}
		byParent[key].count += 1
		local s = d.Size.X * d.Size.Y * d.Size.Z
		if s > byParent[key].biggest then byParent[key].biggest = s; byParent[key].example = string.format("%s %.0fx%.0fx%.0f at (%.0f, %.0f, %.0f)", d.Name, d.Size.X, d.Size.Y, d.Size.Z, d.Position.X, d.Position.Y, d.Position.Z) end
		if FIX then
			if d:GetAttribute("BlackRockOldVariant") == nil then
				d:SetAttribute("BlackRockOldVariant", d.MaterialVariant); d:SetAttribute("BlackRockOldMaterial", d.Material.Name); d:SetAttribute("BlackRockOldColor", d.Color)
			end
			d.MaterialVariant = ""; d.Material = Enum.Material.Rock; d.Color = STONE; fixed += 1
		end
	end
end
for key, v in pairs(byParent) do print(string.format("QQ BLACKROCK1 %s: %d parts, biggest %s", key, v.count, v.example)) end
print(string.format("QQ BLACKROCK1 DONE: %d parts wear %s in JapanMap; %s", n, VARIANT, FIX and (fixed .. " set to plain Rock in stone grey (old variant/material/colour kept as attributes)") or "nothing changed (FIX = false)"))
