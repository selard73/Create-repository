-- falls_lipray1 v1 (EDIT, temporary): from the parked going-over camera, raycasts through the stray sheet's spot on screen
-- (viewport points around 455,172) and names what the rays hit; then shows the sill face in its original colour for 2.5 s
-- (SouthCliff_L01 / _Lo carry OrigColor from the wet tint) and puts the wet tint back.
local cam = workspace.CurrentCamera
local rp = RaycastParams.new(); rp.IgnoreWater = false
for _, pt in ipairs({{455, 172}, {435, 160}, {475, 160}, {435, 190}, {475, 190}, {455, 210}}) do
	local ray = cam:ViewportPointToRay(pt[1], pt[2])
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 200, rp)
	if hit then
		print(string.format("QQ LR (%d,%d) -> %s material %s at (%.1f,%.1f,%.1f)", pt[1], pt[2], hit.Instance:GetFullName(), hit.Material.Name, hit.Position.X, hit.Position.Y, hit.Position.Z))
	else
		print(string.format("QQ LR (%d,%d) -> nothing", pt[1], pt[2]))
	end
end
local SG = workspace.SouthGorge
local faces = {}
for _, d in ipairs(SG:GetDescendants()) do
	if d:IsA("BasePart") and d:GetAttribute("OrigColor") ~= nil then faces[#faces + 1] = d end
end
print("QQ LR wet-tinted faces: " .. #faces)
local saved = {}
for _, f in ipairs(faces) do saved[f] = f.Color; local oc = f:GetAttribute("OrigColor"); if typeof(oc) == "Color3" then f.Color = oc end; print("QQ LR original colour on " .. f.Name) end
task.wait(2.5)
for f, c in pairs(saved) do f.Color = c end
print("QQ LR wet tint back")
