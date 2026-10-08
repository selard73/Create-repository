-- gorge_base1: CHANGES THE PLACE: cuts the Baseplate (UnionOperation 2048 x 16 x 2048, top at y 0) away SOUTH of
-- z -546.5 (one stud north of the gorge's corners at -547.5, so the plate's new edge hides behind the cliff pieces)
-- so Italy's ground can sit about 50 studs below it. Nothing is lost: a clone of the plate goes to
-- ServerStorage.GorgeBackup.Baseplate_before_cut first, and the original itself is parked in that folder afterwards
-- (renamed), not destroyed. The cut result takes the plate's name, parent, material, colour, texture child, attributes,
-- lock and fidelities, so the eight scripts that find it by name keep working. If SubtractAsync fails, nothing changes.
local ZCUT = -546.5
local SS = game:GetService("ServerStorage")
local bp = workspace:FindFirstChild("Baseplate")
assert(bp and bp:IsA("UnionOperation"), "workspace.Baseplate union not found")
local bk = SS:FindFirstChild("GorgeBackup") or Instance.new("Folder"); bk.Name = "GorgeBackup"; bk.Parent = SS
if not bk:FindFirstChild("Baseplate_before_cut") then
	local c = bp:Clone(); c.Name = "Baseplate_before_cut"; c.Parent = bk
end
local box = Instance.new("Part")
box.Size = Vector3.new(2400, 60, ZCUT - (-1200))                  -- everything from z -1200 up to the cut line
box.CFrame = CFrame.new(0, -8, (ZCUT + (-1200)) / 2)
box.Anchored = true; box.CanCollide = false; box.Transparency = 1; box.Name = "SouthCutBox"; box.Parent = workspace
local t0 = os.clock()
local ok, res = pcall(function()
	return bp:SubtractAsync({box}, Enum.CollisionFidelity.PreciseConvexDecomposition, Enum.RenderFidelity.Precise)
end)
box:Destroy()
if not ok or not res then print("QQ B1 FAILED (nothing changed): " .. tostring(res)); return end
res.Name = "Baseplate"
res.Anchored = true
res.Material = bp.Material; res.Color = bp.Color; res.UsePartColor = bp.UsePartColor
res.Transparency = bp.Transparency; res.Reflectance = bp.Reflectance; res.CastShadow = bp.CastShadow
res.CanCollide = bp.CanCollide; res.CanQuery = bp.CanQuery; res.CanTouch = bp.CanTouch
res.CollisionGroup = bp.CollisionGroup
for _, c in ipairs(bp:GetChildren()) do c:Clone().Parent = res end
for k, v in pairs(bp:GetAttributes()) do res:SetAttribute(k, v) end
res:SetAttribute("SouthCut", string.format("cut away south of z %.1f on Sep 30 2026 (the falls); original in ServerStorage.GorgeBackup", ZCUT))
res.Parent = workspace
res.Locked = bp.Locked
local oldTris = bp.TriangleCount
bp.Name = "Baseplate_original_pre_cut"; bp.Parent = bk
print(string.format("QQ B1 cut done in %.1fs: new Baseplate size %s pos %s tris %d (was %d), children %d, attrs RiverChannel=%s LagoonHole=%s; original parked as ServerStorage.GorgeBackup.Baseplate_original_pre_cut, clone kept as Baseplate_before_cut",
	os.clock() - t0, tostring(res.Size), tostring(res.Position), res.TriangleCount, oldTris, #res:GetChildren(), tostring(res:GetAttribute("RiverChannel")), tostring(res:GetAttribute("LagoonHole"))))
-- sanity: is the plate really gone south of the line and still there north of it?
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = {res}
for _, p in ipairs({{183.8, -600}, {600, -553}, {-900, -700}, {900, -1000}, {600, -540}, {183.8, -300}, {0, 0}, {-900, 500}}) do
	local r = workspace:Raycast(Vector3.new(p[1], 50, p[2]), Vector3.new(0, -120, 0), rp)
	print(string.format("QQ B1 plate under (%.0f, %.0f): %s", p[1], p[2], r and ("yes, top y " .. string.format("%.2f", r.Position.Y)) or "no"))
end
print("QQ B1 DONE")
