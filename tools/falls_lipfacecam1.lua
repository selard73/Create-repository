-- falls_lipfacecam1 v1 (EDIT): the LipStrands beam at the brink was FaceCamera, so from the side (the going-over camera) it
-- swung out of the fall's plane and read as an angled extra sheet, leaving the pale LipPlate uncovered on the west (her
-- report, Oct 1 2026). Now: LipStrands stays in the fall's plane (FaceCamera off, same attachments), the LipPlate is tinted
-- like the water instead of pale cream, and the Strands3 test beam is removed. Undo: FaceCamera true, plate colour below.
local F = workspace.SouthGorge.FallsB
local lip = F:FindFirstChild("LipStrands", true)
local plate = F:FindFirstChild("LipPlate")
if lip then lip.FaceCamera = false end
if plate then
	if plate:GetAttribute("OrigColor") == nil then plate:SetAttribute("OrigColor", plate.Color) end
	print("QQ LF plate colour was " .. tostring(plate.Color))
	plate.Color = Color3.fromRGB(212, 236, 240)
end
for _, n in ipairs({"Strands3", "S3a", "S3b"}) do local o = F:FindFirstChild(n, true); if o then o:Destroy() end end
print(string.format("QQ LF LipStrands FaceCamera=%s; plate now %s; Strands3 removed", lip and tostring(lip.FaceCamera) or "?", plate and tostring(plate.Color) or "?"))
