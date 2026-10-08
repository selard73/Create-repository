-- falls_lipplate v1: CHANGES THE PLACE (FallsB only). The teal band under the lip is the river's end face, and transparent
-- geometry (ordinary or camera-facing beams) cannot hide it: terrain water composites over them. Opaque geometry can: a thin
-- pale plate (a Part) just south of the water face, the notch's width, from the surface down 9 studs, writes depth and the
-- water behind it is gone. The fall's body and the camera-facing strand layer move in front of the plate; the two ordinary
-- strand layers still curl over the brink (they are behind the plate for the first studs, then in front). The plain
-- LipCover beam is removed (the plate does its job). Re-running replaces the plate.
local B = workspace.SouthGorge.FallsB
local rig = B.Rig
local ZC, WATER_Y = -547.5, -0.9
local XL = (169.4583 + 201.2856) / 2
local old = B:FindFirstChild("LipPlate"); if old then old:Destroy() end
local p = Instance.new("Part"); p.Name = "LipPlate"
p.Size = Vector3.new(31.5, 9.0, 0.3)
p.CFrame = CFrame.new(XL, WATER_Y - 4.6, ZC - 1.4)
p.Color = Color3.fromRGB(206, 230, 236); p.Material = Enum.Material.SmoothPlastic; p.Transparency = 0
p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
p.Parent = B
local function setatt(name, pos)
	local a = rig:FindFirstChild(name)
	if a then a.WorldCFrame = CFrame.fromMatrix(pos, (name:sub(1, 3) == "Lip") and Vector3.new(0, -1, 0) or Vector3.new(0, 0, -1), Vector3.new(1, 0, 0)) end
end
setatt("TopK", Vector3.new(XL, WATER_Y - 0.2, ZC - 2.0))
local back = rig:FindFirstChild("Back"); if back then back.CurveSize0 = 1.2 end
for _, n in ipairs({"LipCover", "LipCoverTop", "LipCoverBot"}) do local o = rig:FindFirstChild(n); if o then o:Destroy() end end
setatt("LipStrandsTop", Vector3.new(XL, WATER_Y - 0.5, ZC - 2.0))
setatt("LipStrandsBot", Vector3.new(XL, WATER_Y - 11.0, ZC - 3.4))
print(string.format("QQ LP1 plate %.1fx%.1fx%.1f at z %.2f..%.2f; Back top z %.1f c0 %.1f; LipStrands top z %.1f", p.Size.X, p.Size.Y, p.Size.Z, p.Position.Z + 0.15, p.Position.Z - 0.15, rig.TopK.WorldPosition.Z, back and back.CurveSize0 or 0, rig.LipStrandsTop.WorldPosition.Z))
print("QQ LP1 DONE")
