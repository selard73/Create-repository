-- falls_fix1 v1: CHANGES THE PLACE (scenery only, no scripts): her note 1, "the sides at the cliff edge look weird".
-- The lip's water beams in workspace.SouthGorge.Falls (Crest, Body, Sheet, Sheet2) were exactly river-width (29-33),
-- so their ends stopped at the walls and the river's teal cut-off face showed beside them. Now: widths 36 centred
-- between the two corners (x 169.46 / 201.29 -> 185.37) so each end tucks ~2 studs into the rock; the green roll's
-- top starts AT the water surface (y -0.95; it stood 0.35 above). Nothing else changes; re-running is harmless.
local F = workspace.SouthGorge.Falls
local rig = F.Rig
local XMID = (169.4583 + 201.2856) / 2
local WATER_Y, ZC, SEA_Y = -0.9, -547.5, -52.9
local widths = {Crest = {36, 36}, Body = {36, 37}, Sheet = {35, 36}, Sheet2 = {33, 36}}
local atts = {
	TopC = {XMID, WATER_Y - 0.05, ZC + 0.3}, BottomC = {XMID, WATER_Y - 9.0, ZC - 2.8},
	TopB = {XMID, WATER_Y - 2.6, ZC - 1.6}, BottomB = {XMID, SEA_Y - 1.0, ZC - 6.5},
	Top = {XMID, WATER_Y - 2.0, ZC - 1.4}, Bottom = {XMID, SEA_Y - 1.5, ZC - 7.0},
	Top2 = {XMID, WATER_Y - 1.5, ZC - 1.5}, Bottom2 = {XMID, SEA_Y - 1.5, ZC - 5.5},
}
local out = {}
for name, w in pairs(widths) do
	local b = rig:FindFirstChild(name)
	if b and b:IsA("Beam") then b.Width0 = w[1]; b.Width1 = w[2]; out[#out + 1] = string.format("%s %g/%g", name, b.Width0, b.Width1)
	else out[#out + 1] = name .. " MISSING" end
end
for name, p in pairs(atts) do
	local a = rig:FindFirstChild(name)
	if a and a:IsA("Attachment") then
		a.WorldCFrame = CFrame.fromMatrix(Vector3.new(p[1], p[2], p[3]), Vector3.new(0, 0, -1), Vector3.new(1, 0, 0))
	else out[#out + 1] = name .. " MISSING" end
end
table.sort(out)
local tc = rig.TopC.WorldPosition
print(string.format("QQ FX1 widths: %s; TopC now (%.2f, %.2f, %.2f); Crest spans x %.2f..%.2f (corners 169.46 / 201.29)",
	table.concat(out, ", "), tc.X, tc.Y, tc.Z, XMID - 18, XMID + 18))
print("QQ FX1 DONE")
